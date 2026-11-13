import type { FastifyInstance, FastifyReply } from 'fastify';
import type { Guards } from '../guards.js';
import { activeProvider, applyPaymentEvent, baseUrl, type Ctx } from '../services.js';
import { jobJson, paymentJson } from '../serialize.js';
import { AppError, conflict, forbidden, newId, notFound, nowIso } from '../util.js';
import { checkoutPage, messagePage } from '../pages.js';

export default function paymentRoutes(app: FastifyInstance, ctx: Ctx, g: Guards) {
  const { db } = ctx;

  // ---------- Iniciar pago ----------
  app.post('/jobs/:id/pay', { preHandler: g.auth }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const job = db.get('SELECT * FROM jobs WHERE id = ?', id);
    if (!job) throw notFound('No encontramos ese trabajo.', 'JOB_NOT_FOUND');
    if (job.client_id !== req.me.id) throw forbidden('Solo el cliente puede pagar este trabajo.');
    if (job.status !== 'pending_payment') throw conflict('Este trabajo no está esperando un pago.', 'INVALID_STATE');

    const provider = activeProvider(ctx);
    const tech = db.get('SELECT * FROM tech_profiles WHERE user_id = ?', job.tech_id)!;
    const existing = db.get(
      "SELECT * FROM payments WHERE job_id = ? AND status = 'pending' AND provider = ? AND checkout_url IS NOT NULL ORDER BY created_at DESC",
      id, provider.name,
    );
    if (existing) return { payment: paymentJson(existing), checkoutUrl: existing.checkout_url };

    const pid = newId();
    db.run(
      `INSERT INTO payments (id, job_id, provider, amount, commission, status, created_at) VALUES (?,?,?,?,?, 'pending', ?)`,
      pid, id, provider.name, job.price, job.commission, nowIso(),
    );
    const payment = db.get('SELECT * FROM payments WHERE id = ?', pid)!;
    try {
      const { checkoutUrl, providerRef } = await provider.createCheckout({ payment, job, tech, baseUrl: baseUrl(ctx, req) });
      db.run('UPDATE payments SET checkout_url = ?, provider_ref = ? WHERE id = ?', checkoutUrl, providerRef, pid);
    } catch (e) {
      db.run("UPDATE payments SET status = 'failed' WHERE id = ?", pid);
      throw e;
    }
    const saved = db.get('SELECT * FROM payments WHERE id = ?', pid)!;
    reply.code(201);
    return { payment: paymentJson(saved), checkoutUrl: saved.checkout_url };
  });

  app.get('/payments/:id', { preHandler: g.auth }, async (req) => {
    const { id } = req.params as { id: string };
    const p = db.get('SELECT * FROM payments WHERE id = ?', id);
    if (!p) throw notFound('No encontramos ese pago.', 'PAYMENT_NOT_FOUND');
    const j = db.get('SELECT * FROM jobs WHERE id = ?', p.job_id)!;
    if (j.client_id !== req.me.id && j.tech_id !== req.me.id && req.me.role !== 'admin') throw forbidden('Este pago no es tuyo.');
    return { payment: paymentJson(p), job: jobJson(j) };
  });

  // ---------- Webhook (publico: lo llama el proveedor / la pagina mock) ----------
  const webhook = async (req: any) => {
    const name = req.params.provider as 'mock' | 'mercadopago';
    const provider = ctx.providers[name];
    if (!provider) throw new AppError(404, 'UNKNOWN_PROVIDER', 'Proveedor de pago desconocido.');
    const ev = await provider.parseWebhook({ body: req.body, query: req.query ?? {}, headers: req.headers, baseUrl: baseUrl(ctx, req) });
    if (!ev) return { ok: true, ignored: true };
    const pay = db.get('SELECT provider FROM payments WHERE id = ?', ev.paymentId);
    if (pay && pay.provider !== name) throw new AppError(400, 'PROVIDER_MISMATCH', 'El pago pertenece a otro proveedor.');
    const updated = applyPaymentEvent(ctx, ev);
    return { ok: true, payment: paymentJson(updated) };
  };
  app.post('/payments/webhook/:provider', webhook);
  app.get('/payments/webhook/:provider', webhook);

  // ---------- Vinculacion de cuenta de cobro del tecnico ----------
  app.get('/payments/connect/url', { preHandler: g.tech }, async (req) => {
    const prof = db.get('SELECT payments_connected FROM tech_profiles WHERE user_id = ?', req.me.id)!;
    return {
      url: activeProvider(ctx).connectUrl(req.me.id, baseUrl(ctx, req)),
      provider: ctx.cfg.paymentProvider,
      connected: !!prof.payments_connected,
    };
  });

  app.get('/payments/connect/callback', async (req, reply: FastifyReply) => {
    reply.type('text/html; charset=utf-8');
    try {
      await activeProvider(ctx).handleConnectCallback(req.query as Record<string, any>, baseUrl(ctx, req));
      return messagePage('ok', 'Cuenta vinculada', 'Ya podés cobrar tus trabajos con Fixi. Volvé a la app.');
    } catch (e) {
      reply.code(e instanceof AppError ? e.status : 500);
      return messagePage('error', 'No pudimos vincular tu cuenta', e instanceof AppError ? e.message : 'Ocurrió un error inesperado. Probá de nuevo.');
    }
  });

  // ---------- Ganancias del tecnico ----------
  app.get('/me/earnings', { preHandler: g.tech }, async (req) => {
    const rows = db.all(
      "SELECT * FROM jobs WHERE tech_id = ? AND payment_status IN ('held','released') ORDER BY COALESCE(completed_at, paid_at, created_at) DESC",
      req.me.id,
    );
    let totalNet = 0, pendingNet = 0, commissionPaid = 0;
    for (const j of rows) {
      if (j.payment_status === 'released') {
        totalNet += j.tech_net;
        commissionPaid += j.commission;
      } else pendingNet += j.tech_net; // retenido hasta que el cliente confirme
    }
    return { totalNet, pendingNet, commissionPaid, jobs: rows.map(jobJson) };
  });
}

/** Paginas HTML publicas del checkout simulado (fuera de /api/v1). */
export function paymentPages(app: FastifyInstance, ctx: Ctx) {
  const { db } = ctx;
  app.get('/pay/mock/:paymentId', async (req, reply) => {
    reply.type('text/html; charset=utf-8');
    const { paymentId } = req.params as { paymentId: string };
    const p = db.get('SELECT * FROM payments WHERE id = ?', paymentId);
    if (!p || p.provider !== 'mock') {
      reply.code(404);
      return messagePage('error', 'Pago no encontrado', 'Este enlace de pago no existe o venció.');
    }
    const job = db.get('SELECT * FROM jobs WHERE id = ?', p.job_id)!;
    const tech = db.get('SELECT name FROM users WHERE id = ?', job.tech_id);
    return checkoutPage({
      paymentId: p.id,
      status: p.status,
      title: job.title,
      techName: tech?.name ?? 'Técnico',
      address: job.address,
      amount: p.amount,
      commission: p.commission,
      techNet: p.amount - p.commission,
    });
  });

  app.get('/pay/return', async (req, reply) => {
    reply.type('text/html; charset=utf-8');
    const status = (req.query as any)?.status;
    if (status === 'approved') return messagePage('ok', 'Pago aprobado', 'Ya podés volver a la app.');
    if (status === 'pending') return messagePage('ok', 'Pago pendiente', 'Estamos esperando la confirmación. Volvé a la app: te avisamos cuando se acredite.');
    return messagePage('error', 'El pago no se completó', 'Podés volver a la app e intentarlo de nuevo.');
  });
}
