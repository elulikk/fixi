import type { FastifyRequest } from 'fastify';
import type { Config } from './config.js';
import type { Db, Row } from './db.js';
import type { PaymentProvider, WebhookEvent } from './payments/types.js';
import { jobJson, jobWithParties, notificationJson } from './serialize.js';
import type { Hub } from './ws.js';
import { AppError, forbidden, levelFor, newId, nowIso } from './util.js';

export interface Ctx {
  db: Db;
  cfg: Config;
  hub: Hub;
  providers: Record<'mock' | 'mercadopago', PaymentProvider>;
}

export const activeProvider = (ctx: Ctx) => ctx.providers[ctx.cfg.paymentProvider];

/** URL publica del server: env PUBLIC_BASE_URL o deducida del header Host. */
export function baseUrl(ctx: Ctx, req: FastifyRequest): string {
  if (ctx.cfg.publicBaseUrl) return ctx.cfg.publicBaseUrl;
  const proto = (req.headers['x-forwarded-proto'] as string) || req.protocol || 'http';
  return `${proto}://${req.headers.host ?? `localhost:${ctx.cfg.port}`}`;
}

/** Crea una Notification y la emite por WebSocket. */
export function notify(ctx: Ctx, userId: string, type: string, title: string, body: string, data: Record<string, unknown> = {}) {
  const id = newId();
  ctx.db.run(
    'INSERT INTO notifications (id, user_id, type, title, body, data, read, created_at) VALUES (?,?,?,?,?,?,0,?)',
    id, userId, type, title, body, JSON.stringify(data), nowIso(),
  );
  const row = ctx.db.get('SELECT * FROM notifications WHERE id = ?', id)!;
  ctx.hub.send(userId, 'notification.new', notificationJson(row));
}

export function emitJob(ctx: Ctx, jobId: string) {
  const row = ctx.db.get('SELECT * FROM jobs WHERE id = ?', jobId)!;
  const payload = jobWithParties(ctx.db, row);
  ctx.hub.send(row.client_id, 'job.updated', payload);
  ctx.hub.send(row.tech_id, 'job.updated', payload);
  return row;
}

export function adjustTechPoints(db: Db, techId: string, delta: number) {
  const p = db.get('SELECT points FROM tech_profiles WHERE user_id = ?', techId);
  if (!p) return;
  const points = Math.max(0, p.points + delta);
  db.run('UPDATE tech_profiles SET points = ?, level = ? WHERE user_id = ?', points, levelFor(points), techId);
}

const money = (n: number) => '$' + n.toLocaleString('es-AR');

/** Aplica un resultado de pago (webhook). Idempotente. */
export function applyPaymentEvent(ctx: Ctx, ev: WebhookEvent) {
  const { db } = ctx;
  const pay = db.get('SELECT * FROM payments WHERE id = ?', ev.paymentId);
  if (!pay) throw new AppError(404, 'PAYMENT_NOT_FOUND', 'No encontramos ese pago.');
  const job = db.get('SELECT * FROM jobs WHERE id = ?', pay.job_id)!;
  if (ev.providerRef) db.run('UPDATE payments SET provider_ref = ? WHERE id = ?', ev.providerRef, pay.id);

  if (ev.status === 'approved') {
    if (pay.status === 'approved' || pay.status === 'released') return pay;
    db.tx(() => {
      db.run("UPDATE payments SET status = 'approved' WHERE id = ?", pay.id);
      if (job.status === 'pending_payment') {
        db.run("UPDATE jobs SET status = 'paid', payment_status = 'held', paid_at = ? WHERE id = ?", nowIso(), job.id);
      }
    });
    emitJob(ctx, job.id);
    notify(ctx, job.client_id, 'payment.approved', 'Pago aprobado', `Tu pago de ${money(job.price)} fue aprobado. El técnico ya fue avisado.`, { jobId: job.id, paymentId: pay.id });
    notify(ctx, job.tech_id, 'payment.approved', 'Nuevo trabajo pago', `"${job.title}" ya está pago. Tu parte: ${money(job.tech_net)}.`, { jobId: job.id, paymentId: pay.id });
  } else if (ev.status === 'failed') {
    if (pay.status !== 'pending') return pay;
    db.run("UPDATE payments SET status = 'failed' WHERE id = ?", pay.id);
    notify(ctx, job.client_id, 'payment.failed', 'Pago rechazado', 'No pudimos procesar tu pago. Podés intentar de nuevo.', { jobId: job.id, paymentId: pay.id });
  } else if (ev.status === 'refunded') {
    db.tx(() => {
      db.run("UPDATE payments SET status = 'refunded' WHERE id = ?", pay.id);
      db.run("UPDATE jobs SET payment_status = 'refunded' WHERE id = ?", job.id);
    });
    emitJob(ctx, job.id);
  }
  return db.get('SELECT * FROM payments WHERE id = ?', pay.id)!;
}

/** Marca el pago como devuelto (best effort con la pasarela). */
export async function refundJobPayment(ctx: Ctx, job: Row) {
  const { db } = ctx;
  const pay = db.get("SELECT * FROM payments WHERE job_id = ? AND status IN ('approved','released') ORDER BY created_at DESC", job.id);
  if (!pay) return;
  const tech = db.get('SELECT * FROM tech_profiles WHERE user_id = ?', job.tech_id);
  try {
    await ctx.providers[pay.provider as 'mock' | 'mercadopago'].refund(pay, tech ?? {});
  } catch (e) {
    console.error('[refund] no se pudo devolver en la pasarela:', (e as Error).message);
  }
  db.run("UPDATE payments SET status = 'refunded' WHERE id = ?", pay.id);
  db.run("UPDATE jobs SET payment_status = 'refunded' WHERE id = ?", job.id);
}

/** Libera el pago al tecnico y suma estadisticas/puntos. */
export function releaseAndScore(ctx: Ctx, job: Row) {
  const { db } = ctx;
  db.tx(() => {
    db.run("UPDATE payments SET status = 'released' WHERE job_id = ? AND status = 'approved'", job.id);
    db.run("UPDATE jobs SET payment_status = 'released' WHERE id = ?", job.id);
    db.run('UPDATE tech_profiles SET jobs_done = jobs_done + 1 WHERE user_id = ?', job.tech_id);
    adjustTechPoints(db, job.tech_id, 20 + (job.on_time ? 5 : 0));
  });
}

type Target = 'on_the_way' | 'in_progress' | 'done' | 'completed' | 'cancelled' | 'disputed';

/**
 * Transiciones de estado de un Job validadas por rol:
 *  tecnico: paid->on_the_way->in_progress->done · cliente: done->completed
 *  ambos: cancelled (pending_payment|paid|on_the_way) · disputed (in_progress|done)
 */
export async function transitionJob(ctx: Ctx, jobId: string, actorId: string, target: Target) {
  const { db } = ctx;
  const job = db.get('SELECT * FROM jobs WHERE id = ?', jobId);
  if (!job) throw new AppError(404, 'JOB_NOT_FOUND', 'No encontramos ese trabajo.');
  const isClient = job.client_id === actorId;
  const isTech = job.tech_id === actorId;
  if (!isClient && !isTech) throw forbidden('Este trabajo no es tuyo.');

  const wrongState = () => new AppError(409, 'INVALID_TRANSITION', `No se puede pasar de "${job.status}" a "${target}".`);
  const wrongRole = (who: string) => new AppError(403, 'FORBIDDEN_TRANSITION', `Solo ${who} puede hacer este cambio.`);
  const now = nowIso();

  switch (target) {
    case 'on_the_way':
      if (!isTech) throw wrongRole('el técnico');
      if (job.status !== 'paid') throw wrongState();
      db.run("UPDATE jobs SET status = 'on_the_way', on_the_way_at = ? WHERE id = ?", now, job.id);
      break;
    case 'in_progress': {
      if (!isTech) throw wrongRole('el técnico');
      if (job.status !== 'on_the_way') throw wrongState();
      const mins = job.on_the_way_at ? (Date.now() - Date.parse(job.on_the_way_at)) / 60000 : Infinity;
      db.run("UPDATE jobs SET status = 'in_progress', started_at = ?, on_time = ? WHERE id = ?", now, mins <= job.eta_minutes ? 1 : 0, job.id);
      break;
    }
    case 'done':
      if (!isTech) throw wrongRole('el técnico');
      if (job.status !== 'in_progress') throw wrongState();
      db.run("UPDATE jobs SET status = 'done' WHERE id = ?", job.id);
      break;
    case 'completed':
      if (!isClient) throw wrongRole('el cliente');
      if (job.status !== 'done') throw wrongState();
      db.run("UPDATE jobs SET status = 'completed', completed_at = ? WHERE id = ?", now, job.id);
      releaseAndScore(ctx, db.get('SELECT * FROM jobs WHERE id = ?', job.id)!);
      if (job.request_id) db.run("UPDATE requests SET status = 'closed' WHERE id = ?", job.request_id);
      break;
    case 'cancelled':
      if (!['pending_payment', 'paid', 'on_the_way'].includes(job.status)) throw wrongState();
      db.run("UPDATE jobs SET status = 'cancelled' WHERE id = ?", job.id);
      if (job.payment_status === 'held') await refundJobPayment(ctx, job);
      else db.run("UPDATE payments SET status = 'failed' WHERE job_id = ? AND status = 'pending'", job.id);
      if (job.request_id) db.run("UPDATE requests SET status = 'closed' WHERE id = ?", job.request_id);
      break;
    case 'disputed':
      if (!['in_progress', 'done'].includes(job.status)) throw wrongState();
      db.run("UPDATE jobs SET status = 'disputed' WHERE id = ?", job.id);
      break;
    default:
      throw new AppError(400, 'VALIDATION_ERROR', 'Estado inválido.');
  }

  const updated = emitJob(ctx, job.id);
  const other = isClient ? job.tech_id : job.client_id;
  const msgs: Record<Target, [string, string]> = {
    on_the_way: ['El técnico está en camino', `Tu técnico salió hacia ${job.address || 'tu domicilio'}.`],
    in_progress: ['Trabajo en curso', 'El técnico llegó y empezó el trabajo.'],
    done: ['Trabajo terminado', 'El técnico marcó el trabajo como terminado. Confirmalo para liberar el pago.'],
    completed: ['Trabajo confirmado', `El cliente confirmó "${job.title}". Se liberó tu pago de ${money(job.tech_net)}.`],
    cancelled: ['Trabajo cancelado', `Se canceló "${job.title}".`],
    disputed: ['Trabajo en disputa', `Se abrió una disputa por "${job.title}". Fixi va a revisarla.`],
  };
  notify(ctx, other, 'job.status', msgs[target][0], msgs[target][1], { jobId: job.id, status: target });
  if (target === 'disputed') {
    for (const a of db.all("SELECT id FROM users WHERE role = 'admin'")) {
      notify(ctx, a.id, 'job.disputed', 'Nueva disputa', `Trabajo "${job.title}" en disputa.`, { jobId: job.id });
    }
  }
  return updated;
}

export { jobJson };
