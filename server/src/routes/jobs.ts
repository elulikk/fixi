import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Row } from '../db.js';
import type { Guards } from '../guards.js';
import { adjustTechPoints, notify, transitionJob, type Ctx } from '../services.js';
import { jobWithParties, messageJson, paymentJson, reviewJson } from '../serialize.js';
import { conflict, forbidden, newId, notFound, nowIso, parse } from '../util.js';

export default function jobRoutes(app: FastifyInstance, ctx: Ctx, g: Guards) {
  const { db, hub } = ctx;

  /** Devuelve el job si el usuario participa (o es admin). */
  function loadJob(id: string, me: Row, allowAdmin = false): Row {
    const j = db.get('SELECT * FROM jobs WHERE id = ?', id);
    if (!j) throw notFound('No encontramos ese trabajo.', 'JOB_NOT_FOUND');
    const participant = j.client_id === me.id || j.tech_id === me.id;
    if (!participant && !(allowAdmin && me.role === 'admin')) throw forbidden('Este trabajo no es tuyo.');
    return j;
  }

  app.get('/jobs', { preHandler: g.auth }, async (req) => {
    const q = parse(z.object({ role: z.enum(['client', 'tech']).optional(), status: z.string().optional() }), req.query);
    const where: string[] = [];
    const params: any[] = [req.me.id];
    if (q.role === 'client') where.push('client_id = ?');
    else if (q.role === 'tech') where.push('tech_id = ?');
    else {
      where.push('(client_id = ? OR tech_id = ?)');
      params.push(req.me.id);
    }
    if (q.status) {
      const st = q.status.split(',').map((s) => s.trim()).filter(Boolean);
      where.push(`status IN (${st.map(() => '?').join(',')})`);
      params.push(...st);
    }
    const rows = db.all(`SELECT * FROM jobs WHERE ${where.join(' AND ')} ORDER BY created_at DESC`, ...params);
    return { items: rows.map((r) => jobWithParties(db, r)) };
  });

  app.get('/jobs/:id', { preHandler: g.auth }, async (req) => {
    const { id } = req.params as { id: string };
    const j = loadJob(id, req.me, true);
    const pay = db.get('SELECT * FROM payments WHERE job_id = ? ORDER BY created_at DESC', id);
    const mine = db.get('SELECT * FROM reviews WHERE job_id = ? AND from_user_id = ?', id, req.me.id);
    const theirs = db.get('SELECT * FROM reviews WHERE job_id = ? AND to_user_id = ?', id, req.me.id);
    return {
      job: {
        ...jobWithParties(db, j),
        payment: pay ? paymentJson(pay) : null,
        myReview: mine ? reviewJson(mine) : null,
        reviewReceived: theirs ? reviewJson(theirs) : null,
      },
    };
  });

  app.post('/jobs/:id/status', { preHandler: g.auth }, async (req) => {
    const { id } = req.params as { id: string };
    const b = parse(
      z.object({ status: z.enum(['on_the_way', 'in_progress', 'done', 'completed', 'cancelled', 'disputed']) }),
      req.body,
    );
    const row = await transitionJob(ctx, id, req.me.id, b.status);
    return { job: jobWithParties(db, row) };
  });

  // ---------- Chat ----------
  app.get('/jobs/:id/messages', { preHandler: g.auth }, async (req) => {
    const { id } = req.params as { id: string };
    loadJob(id, req.me, true);
    return { items: db.all('SELECT * FROM messages WHERE job_id = ? ORDER BY created_at ASC, rowid ASC', id).map(messageJson) };
  });

  app.post('/jobs/:id/messages', { preHandler: g.auth }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const j = loadJob(id, req.me);
    const b = parse(z.object({ text: z.string().trim().min(1).max(2000) }), req.body);
    const mid = newId();
    db.run('INSERT INTO messages (id, job_id, from_user_id, text, created_at) VALUES (?,?,?,?,?)', mid, id, req.me.id, b.text, nowIso());
    const msg = messageJson(db.get('SELECT * FROM messages WHERE id = ?', mid)!);
    const other = j.client_id === req.me.id ? j.tech_id : j.client_id;
    hub.send(other, 'message.new', msg);
    notify(ctx, other, 'message.new', `Mensaje de ${req.me.name}`, b.text.slice(0, 120), { jobId: id, messageId: mid });
    reply.code(201);
    return { message: msg };
  });

  // ---------- Resenas ----------
  app.post('/jobs/:id/review', { preHandler: g.auth }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const j = loadJob(id, req.me);
    const b = parse(z.object({ rating: z.number().int().min(1).max(5), comment: z.string().trim().max(1000).default('') }), req.body);
    if (j.status !== 'completed') throw conflict('Solo se puede dejar una reseña cuando el trabajo está completado.', 'JOB_NOT_COMPLETED');
    if (db.get('SELECT 1 FROM reviews WHERE job_id = ? AND from_user_id = ?', id, req.me.id)) {
      throw conflict('Ya dejaste tu reseña para este trabajo.', 'ALREADY_REVIEWED');
    }
    const to = j.client_id === req.me.id ? j.tech_id : j.client_id;
    const rid = newId();
    db.tx(() => {
      db.run('INSERT INTO reviews (id, job_id, from_user_id, to_user_id, rating, comment, created_at) VALUES (?,?,?,?,?,?,?)',
        rid, id, req.me.id, to, b.rating, b.comment, nowIso());
      if (to === j.tech_id) {
        // Reputacion del tecnico: promedio incremental + puntos (+10 x (estrellas - 3)).
        const p = db.get('SELECT rating_avg, rating_count FROM tech_profiles WHERE user_id = ?', to)!;
        const count = p.rating_count + 1;
        const avg = Math.round(((p.rating_avg * p.rating_count + b.rating) / count) * 100) / 100;
        db.run('UPDATE tech_profiles SET rating_avg = ?, rating_count = ? WHERE user_id = ?', avg, count, to);
        adjustTechPoints(db, to, 10 * (b.rating - 3));
      }
    });
    const review = reviewJson(db.get('SELECT * FROM reviews WHERE id = ?', rid)!);
    notify(ctx, to, 'review.new', 'Recibiste una reseña', `${req.me.name} te dejó ${b.rating} ${b.rating === 1 ? 'estrella' : 'estrellas'}.`, { jobId: id, reviewId: rid });
    reply.code(201);
    return { review };
  });

  // ---------- Ubicacion en vivo ----------
  app.post('/jobs/:id/location', { preHandler: g.tech }, async (req) => {
    const { id } = req.params as { id: string };
    const j = loadJob(id, req.me);
    if (j.tech_id !== req.me.id) throw forbidden('Solo el técnico del trabajo puede compartir su ubicación.');
    if (j.status !== 'on_the_way') throw conflict('Solo se comparte la ubicación mientras vas en camino.', 'INVALID_STATE');
    const b = parse(z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180) }), req.body);
    hub.send(j.client_id, 'tech.location', { jobId: id, lat: b.lat, lng: b.lng });
    return { ok: true };
  });
}
