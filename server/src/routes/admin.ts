import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Guards } from '../guards.js';
import { emitJob, notify, refundJobPayment, releaseAndScore, type Ctx } from '../services.js';
import { categoryJson, jobWithParties, paymentJson, techProfileJson, userJson } from '../serialize.js';
import { badRequest, conflict, notFound, nowIso, parse } from '../util.js';

const slugify = (s: string) =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');

export default function adminRoutes(app: FastifyInstance, ctx: Ctx, g: Guards) {
  const { db } = ctx;
  const pre = { preHandler: g.admin };

  app.get('/admin/stats', pre, async () => {
    const one = (sql: string, ...p: any[]) => (db.get(sql, ...p) as any) ?? {};
    const users = one('SELECT COUNT(*) n FROM users').n;
    const technicians = one('SELECT COUNT(*) n FROM users WHERE is_technician = 1').n;
    const jobsByStatus: Record<string, number> = {};
    for (const r of db.all('SELECT status, COUNT(*) n FROM jobs GROUP BY status')) jobsByStatus[r.status] = r.n;
    const money = one(
      `SELECT COALESCE(SUM(CASE WHEN payment_status IN ('held','released') THEN price END),0) gmv,
              COALESCE(SUM(CASE WHEN payment_status = 'released' THEN commission END),0) commissionEarned,
              COALESCE(SUM(CASE WHEN payment_status = 'held' THEN commission END),0) commissionPending
       FROM jobs`,
    );
    // Serie diaria de 30 dias (por fecha de pago, o de creacion si no hay).
    const days: string[] = [];
    for (let i = 29; i >= 0; i--) days.push(new Date(Date.now() - i * 86400000).toISOString().slice(0, 10));
    const byDay = new Map(days.map((d) => [d, { date: d, jobs: 0, gmv: 0, commission: 0, newUsers: 0 }]));
    for (const j of db.all("SELECT price, commission, COALESCE(paid_at, created_at) d, payment_status FROM jobs WHERE payment_status IN ('held','released')")) {
      const e = byDay.get(String(j.d).slice(0, 10));
      if (e) { e.jobs++; e.gmv += j.price; e.commission += j.commission; }
    }
    for (const u of db.all('SELECT created_at FROM users')) {
      const e = byDay.get(String(u.created_at).slice(0, 10));
      if (e) e.newUsers++;
    }
    return {
      users,
      technicians,
      clients: users - technicians,
      jobsTotal: Object.values(jobsByStatus).reduce((a, b) => a + b, 0),
      jobsByStatus,
      gmv: money.gmv,
      commissionEarned: money.commissionEarned,
      commissionPending: money.commissionPending,
      openRequests: one("SELECT COUNT(*) n FROM requests WHERE status = 'open'").n,
      disputes: jobsByStatus.disputed ?? 0,
      series: [...byDay.values()],
    };
  });

  app.get('/admin/users', pre, async (req) => {
    const q = parse(z.object({ q: z.string().optional(), role: z.enum(['client', 'tech', 'admin']).optional() }), req.query);
    const where: string[] = [];
    const params: any[] = [];
    if (q.q?.trim()) { where.push('(name LIKE ? OR email LIKE ?)'); params.push(`%${q.q.trim()}%`, `%${q.q.trim()}%`); }
    if (q.role === 'tech') where.push('is_technician = 1');
    if (q.role === 'client') where.push("is_technician = 0 AND role = 'user'");
    if (q.role === 'admin') where.push("role = 'admin'");
    const rows = db.all(`SELECT * FROM users ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY created_at DESC`, ...params);
    return {
      items: rows.map((u) => {
        const p = db.get('SELECT * FROM tech_profiles WHERE user_id = ?', u.id);
        return { ...userJson(u), suspended: !!u.suspended, ...(p ? { techProfile: techProfileJson(p) } : {}) };
      }),
    };
  });

  app.patch('/admin/users/:id', pre, async (req) => {
    const { id } = req.params as { id: string };
    const b = parse(z.object({ verified: z.boolean().optional(), suspended: z.boolean().optional(), name: z.string().trim().min(2).optional() }), req.body);
    const u = db.get('SELECT * FROM users WHERE id = ?', id);
    if (!u) throw notFound('No encontramos a ese usuario.', 'USER_NOT_FOUND');
    if (b.suspended !== undefined) {
      if (u.role === 'admin' && b.suspended) throw badRequest('No se puede suspender a un administrador.');
      db.run('UPDATE users SET suspended = ? WHERE id = ?', b.suspended, id);
    }
    if (b.name) db.run('UPDATE users SET name = ? WHERE id = ?', b.name, id);
    if (b.verified !== undefined) {
      if (!db.get('SELECT 1 FROM tech_profiles WHERE user_id = ?', id)) throw badRequest('Ese usuario no es técnico.', 'NOT_TECHNICIAN');
      db.run('UPDATE tech_profiles SET verified = ? WHERE user_id = ?', b.verified, id);
      if (b.verified) notify(ctx, id, 'tech.verified', '¡Perfil verificado!', 'Fixi verificó tu identidad. Ahora tenés la insignia de técnico verificado.', {});
    }
    const nu = db.get('SELECT * FROM users WHERE id = ?', id)!;
    const p = db.get('SELECT * FROM tech_profiles WHERE user_id = ?', id);
    return { user: { ...userJson(nu), suspended: !!nu.suspended, ...(p ? { techProfile: techProfileJson(p) } : {}) } };
  });

  app.get('/admin/jobs', pre, async (req) => {
    const q = parse(z.object({ status: z.string().optional() }), req.query);
    const st = q.status ? q.status.split(',') : [];
    const rows = db.all(
      `SELECT * FROM jobs ${st.length ? `WHERE status IN (${st.map(() => '?').join(',')})` : ''} ORDER BY created_at DESC LIMIT 500`,
      ...st,
    );
    return { items: rows.map((r) => jobWithParties(db, r)) };
  });

  app.post('/admin/jobs/:id/resolve', pre, async (req) => {
    const { id } = req.params as { id: string };
    const b = parse(z.object({ outcome: z.enum(['release', 'refund']) }), req.body);
    const job = db.get('SELECT * FROM jobs WHERE id = ?', id);
    if (!job) throw notFound('No encontramos ese trabajo.', 'JOB_NOT_FOUND');
    if (job.status !== 'disputed') throw conflict('Solo se pueden resolver trabajos en disputa.', 'INVALID_STATE');
    if (b.outcome === 'release') {
      db.run("UPDATE jobs SET status = 'completed', completed_at = ? WHERE id = ?", nowIso(), id);
      releaseAndScore(ctx, db.get('SELECT * FROM jobs WHERE id = ?', id)!);
    } else {
      db.run("UPDATE jobs SET status = 'cancelled' WHERE id = ?", id);
      await refundJobPayment(ctx, job);
    }
    if (job.request_id) db.run("UPDATE requests SET status = 'closed' WHERE id = ?", job.request_id);
    const row = emitJob(ctx, id);
    const text = b.outcome === 'release' ? 'Fixi resolvió la disputa a favor del técnico: se liberó el pago.' : 'Fixi resolvió la disputa a favor del cliente: se devolvió el pago.';
    for (const uid of [job.client_id, job.tech_id]) notify(ctx, uid, 'job.resolved', 'Disputa resuelta', text, { jobId: id, outcome: b.outcome });
    return { job: jobWithParties(db, row) };
  });

  app.get('/admin/payments', pre, async () => ({
    items: db
      .all(
        `SELECT p.*, j.title AS job_title, j.client_id, j.tech_id, c.name AS client_name, t.name AS tech_name
         FROM payments p JOIN jobs j ON j.id = p.job_id JOIN users c ON c.id = j.client_id JOIN users t ON t.id = j.tech_id
         ORDER BY p.created_at DESC LIMIT 500`,
      )
      .map((r) => ({ ...paymentJson(r), jobTitle: r.job_title, clientName: r.client_name, techName: r.tech_name })),
  }));

  // ---------- Categorias ----------
  const catSchema = z.object({
    name: z.string().trim().min(2).max(60),
    slug: z.string().trim().min(2).max(60).optional(),
    icon: z.string().trim().min(1).max(60).default('build'),
    group: z.string().trim().min(2).max(60),
  });

  app.get('/admin/categories', pre, async () => ({
    items: db.all('SELECT * FROM categories ORDER BY sort_order, name').map(categoryJson),
  }));

  app.post('/admin/categories', pre, async (req, reply) => {
    const b = parse(catSchema, req.body);
    const slug = slugify(b.slug ?? b.name);
    if (db.get('SELECT 1 FROM categories WHERE slug = ?', slug)) throw conflict('Ya existe una categoría con ese nombre.', 'SLUG_TAKEN');
    const max = (db.get('SELECT COALESCE(MAX(sort_order),0) m FROM categories') as any).m;
    db.run('INSERT INTO categories (id, slug, name, icon, grp, sort_order) VALUES (?,?,?,?,?,?)', `c_${slug}`, slug, b.name, b.icon, b.group, max + 1);
    reply.code(201);
    return { category: categoryJson(db.get('SELECT * FROM categories WHERE id = ?', `c_${slug}`)!) };
  });

  app.patch('/admin/categories/:id', pre, async (req) => {
    const { id } = req.params as { id: string };
    const c = db.get('SELECT * FROM categories WHERE id = ?', id);
    if (!c) throw notFound('No encontramos esa categoría.', 'CATEGORY_NOT_FOUND');
    const b = parse(catSchema.partial(), req.body);
    const slug = b.slug ? slugify(b.slug) : c.slug;
    if (slug !== c.slug && db.get('SELECT 1 FROM categories WHERE slug = ?', slug)) throw conflict('Ese slug ya está en uso.', 'SLUG_TAKEN');
    db.run('UPDATE categories SET slug = ?, name = ?, icon = ?, grp = ? WHERE id = ?', slug, b.name ?? c.name, b.icon ?? c.icon, b.group ?? c.grp, id);
    return { category: categoryJson(db.get('SELECT * FROM categories WHERE id = ?', id)!) };
  });

  app.delete('/admin/categories/:id', pre, async (req) => {
    const { id } = req.params as { id: string };
    if (!db.get('SELECT 1 FROM categories WHERE id = ?', id)) throw notFound('No encontramos esa categoría.', 'CATEGORY_NOT_FOUND');
    const used =
      (db.get('SELECT COUNT(*) n FROM requests WHERE category_id = ?', id) as any).n +
      (db.get('SELECT COUNT(*) n FROM listings WHERE category_id = ?', id) as any).n +
      (db.get('SELECT COUNT(*) n FROM jobs WHERE category_id = ?', id) as any).n;
    if (used > 0) throw conflict('La categoría está en uso y no se puede borrar.', 'CATEGORY_IN_USE');
    db.run('DELETE FROM categories WHERE id = ?', id);
    return { ok: true };
  });
}
