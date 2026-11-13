import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Row } from '../db.js';
import type { Guards } from '../guards.js';
import { scoreItems, sortItems, type SortKey } from '../score.js';
import { emitJob, notify, type Ctx } from '../services.js';
import { jobJson, listingJson, offerJson, requestJson, techCard, userJson } from '../serialize.js';
import {
  badRequest, commissionOf, conflict, etaFromDistance, forbidden, haversineKm, newId, notFound, nowIso, parse, round1,
} from '../util.js';

const numQ = z.preprocess((v) => (v === '' || v == null ? undefined : Number(v)), z.number().finite().optional());
const sortQ = z.enum(['best', 'price', 'distance', 'eta', 'rating']).default('best');
const money = (n: number) => '$' + n.toLocaleString('es-AR');

export default function marketplaceRoutes(app: FastifyInstance, ctx: Ctx, g: Guards) {
  const { db, cfg, hub } = ctx;

  const userCoords = (id: string) => {
    const u = db.get('SELECT lat, lng FROM users WHERE id = ?', id);
    return u && u.lat != null && u.lng != null ? { lat: u.lat as number, lng: u.lng as number } : null;
  };
  const dist = (a: { lat: number; lng: number } | null, lat?: number | null, lng?: number | null) =>
    a && lat != null && lng != null ? haversineKm(a.lat, a.lng, lat, lng) : null;

  /** Ofertas de una necesidad enriquecidas con tech, distancia, score y badges. */
  function enrichOffers(offers: Row[], request: Row, sort: SortKey) {
    const base = offers.map((o) => {
      const d = dist(userCoords(o.tech_id), request.lat, request.lng);
      const tech = techCard(db, o.tech_id, d)!;
      return { o, d, tech };
    });
    const scores = scoreItems(
      base.map(({ o, d, tech }) => ({
        key: o.id, price: o.price, distanceKm: d, etaMinutes: o.eta_minutes, ratingAvg: tech.ratingAvg, ratingCount: tech.ratingCount,
      })),
    );
    const items = base.map(({ o, d, tech }) => {
      const s = scores.get(o.id)!;
      return { ...offerJson(o), tech, distanceKm: d === null ? null : round1(d), score: s.score, badge: s.badge, badges: s.badges };
    });
    return sortItems(items, sort);
  }

  // ---------- Necesidades ----------
  const requestSchema = z.object({
    categoryId: z.string(),
    title: z.string().trim().min(3).max(120),
    description: z.string().trim().max(2000).default(''),
    photos: z.array(z.string().max(500)).max(8).default([]),
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180),
    address: z.string().trim().max(200).default(''),
    budgetMax: z.number().int().positive().nullable().optional(),
    urgency: z.enum(['now', 'today', 'scheduled']).default('today'),
    scheduledAt: z.string().datetime().nullable().optional(),
  });

  app.post('/requests', { preHandler: g.auth }, async (req, reply) => {
    const b = parse(requestSchema, req.body);
    if (!db.get('SELECT 1 FROM categories WHERE id = ?', b.categoryId)) throw badRequest('La categoría no existe.', 'INVALID_CATEGORY');
    const id = newId();
    db.run(
      `INSERT INTO requests (id, client_id, category_id, title, description, photos, lat, lng, address, budget_max, urgency, scheduled_at, status, offers_count, created_at)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?, 'open', 0, ?)`,
      id, req.me.id, b.categoryId, b.title, b.description, JSON.stringify(b.photos), b.lat, b.lng, b.address,
      b.budgetMax ?? null, b.urgency, b.scheduledAt ?? null, nowIso(),
    );
    const row = db.get('SELECT * FROM requests WHERE id = ?', id)!;
    // Avisar a tecnicos disponibles dentro de su radio y categoria.
    const techs = db.all(
      `SELECT u.id, u.lat, u.lng, p.radius_km, p.category_ids FROM users u JOIN tech_profiles p ON p.user_id = u.id
       WHERE p.available = 1 AND u.suspended = 0 AND u.id != ? AND u.lat IS NOT NULL AND u.lng IS NOT NULL`,
      req.me.id,
    );
    for (const t of techs) {
      if (!(JSON.parse(t.category_ids) as string[]).includes(b.categoryId)) continue;
      const d = haversineKm(t.lat, t.lng, b.lat, b.lng);
      if (d > t.radius_km) continue;
      const payload = { ...requestJson(row), distanceKm: round1(d) };
      hub.send(t.id, 'request.new', payload);
      notify(ctx, t.id, 'request.new', 'Nueva necesidad cerca tuyo', `${b.title} · a ${round1(d)} km`, { requestId: id });
    }
    reply.code(201);
    return { request: requestJson(row) };
  });

  app.get('/requests/mine', { preHandler: g.auth }, async (req) => ({
    items: db.all('SELECT * FROM requests WHERE client_id = ? ORDER BY created_at DESC', req.me.id).map(requestJson),
  }));

  app.get('/requests/nearby', { preHandler: g.tech }, async (req) => {
    const q = parse(z.object({ lat: numQ, lng: numQ, radiusKm: numQ, categoryId: z.string().optional() }), req.query);
    const mine = userCoords(req.me.id);
    const lat = q.lat ?? mine?.lat;
    const lng = q.lng ?? mine?.lng;
    const radius = q.radiusKm ?? 20;
    const rows = db.all(
      `SELECT * FROM requests WHERE status = 'open' AND client_id != ? ${q.categoryId ? 'AND category_id = ?' : ''} ORDER BY created_at DESC`,
      ...(q.categoryId ? [req.me.id, q.categoryId] : [req.me.id]),
    );
    const items = rows
      .map((r) => {
        const d = lat != null && lng != null ? haversineKm(lat, lng, r.lat, r.lng) : null;
        const my = db.get("SELECT id, status FROM offers WHERE request_id = ? AND tech_id = ? AND status != 'withdrawn'", r.id, req.me.id);
        return { ...requestJson(r), distanceKm: d === null ? null : round1(d), myOfferId: my?.id ?? null };
      })
      .filter((r) => r.distanceKm === null || r.distanceKm <= radius)
      .sort((a, b) => (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity));
    return { items };
  });

  app.get('/requests/:id', { preHandler: g.auth }, async (req) => {
    const { id } = req.params as { id: string };
    const { sort } = parse(z.object({ sort: sortQ }), req.query);
    const r = db.get('SELECT * FROM requests WHERE id = ?', id);
    if (!r) throw notFound('No encontramos esa necesidad.', 'REQUEST_NOT_FOUND');
    const client = db.get('SELECT * FROM users WHERE id = ?', r.client_id)!;
    const owner = r.client_id === req.me.id;
    const base = { ...requestJson(r), client: { id: client.id, name: client.name, avatarUrl: client.avatar_url ?? null } };
    if (owner || req.me.role === 'admin') {
      const offers = db.all("SELECT * FROM offers WHERE request_id = ? AND status != 'withdrawn'", id);
      const items = enrichOffers(offers, r, sort);
      const best = [...items].find((o) => o.badges.includes('best'));
      const job = db.get('SELECT * FROM jobs WHERE request_id = ? ORDER BY created_at DESC', id);
      return { request: { ...base, offers: items, bestOfferId: best?.id ?? null, jobId: job?.id ?? null } };
    }
    const my = db.get("SELECT * FROM offers WHERE request_id = ? AND tech_id = ? AND status != 'withdrawn'", id, req.me.id);
    if (r.status !== 'open' && !my) throw forbidden('Esta necesidad ya no está disponible.');
    const d = dist(userCoords(req.me.id), r.lat, r.lng);
    return { request: { ...base, distanceKm: d === null ? null : round1(d), myOffer: my ? offerJson(my) : null } };
  });

  app.post('/requests/:id/cancel', { preHandler: g.auth }, async (req) => {
    const { id } = req.params as { id: string };
    const r = db.get('SELECT * FROM requests WHERE id = ?', id);
    if (!r) throw notFound('No encontramos esa necesidad.', 'REQUEST_NOT_FOUND');
    if (r.client_id !== req.me.id) throw forbidden('Esta necesidad no es tuya.');
    if (r.status !== 'open') throw conflict('Solo se pueden cancelar necesidades abiertas.', 'INVALID_STATE');
    db.tx(() => {
      db.run("UPDATE requests SET status = 'cancelled' WHERE id = ?", id);
      db.run("UPDATE offers SET status = 'rejected' WHERE request_id = ? AND status = 'pending'", id);
    });
    return { request: requestJson(db.get('SELECT * FROM requests WHERE id = ?', id)!) };
  });

  // ---------- Ofertas ----------
  const offerSchema = z.object({
    price: z.number().int().min(1).max(50_000_000),
    etaMinutes: z.number().int().min(1).max(2880),
    durationMinutes: z.number().int().min(1).max(10080),
    message: z.string().trim().max(500).default(''),
  });

  app.post('/requests/:id/offers', { preHandler: g.tech }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const b = parse(offerSchema, req.body);
    const r = db.get('SELECT * FROM requests WHERE id = ?', id);
    if (!r) throw notFound('No encontramos esa necesidad.', 'REQUEST_NOT_FOUND');
    if (r.client_id === req.me.id) throw forbidden('No podés ofertar en tu propia necesidad.');
    if (r.status !== 'open') throw conflict('Esta necesidad ya no recibe ofertas.', 'REQUEST_CLOSED');
    if (db.get("SELECT 1 FROM offers WHERE request_id = ? AND tech_id = ? AND status IN ('pending','accepted')", id, req.me.id)) {
      throw conflict('Ya enviaste una oferta para esta necesidad. Retirala para enviar otra.', 'ALREADY_OFFERED');
    }
    const oid = newId();
    db.tx(() => {
      db.run(
        `INSERT INTO offers (id, request_id, tech_id, price, eta_minutes, duration_minutes, message, status, created_at) VALUES (?,?,?,?,?,?,?, 'pending', ?)`,
        oid, id, req.me.id, b.price, b.etaMinutes, b.durationMinutes, b.message, nowIso(),
      );
      db.run('UPDATE requests SET offers_count = offers_count + 1 WHERE id = ?', id);
    });
    const offer = db.get('SELECT * FROM offers WHERE id = ?', oid)!;
    const payload = enrichOffers([offer], r, 'best')[0];
    hub.send(r.client_id, 'offer.new', payload);
    notify(ctx, r.client_id, 'offer.new', 'Nueva oferta', `${req.me.name} ofertó ${money(b.price)} por "${r.title}".`, { requestId: id, offerId: oid });
    reply.code(201);
    return { offer: offerJson(offer) };
  });

  app.get('/offers/mine', { preHandler: g.tech }, async (req) => {
    const rows = db.all('SELECT * FROM offers WHERE tech_id = ? ORDER BY created_at DESC', req.me.id);
    return {
      items: rows.map((o) => {
        const r = db.get('SELECT * FROM requests WHERE id = ?', o.request_id);
        const job = db.get('SELECT id FROM jobs WHERE offer_id = ?', o.id);
        return { ...offerJson(o), request: r ? requestJson(r) : null, jobId: job?.id ?? null };
      }),
    };
  });

  app.post('/offers/:id/withdraw', { preHandler: g.tech }, async (req) => {
    const { id } = req.params as { id: string };
    const o = db.get('SELECT * FROM offers WHERE id = ?', id);
    if (!o) throw notFound('No encontramos esa oferta.', 'OFFER_NOT_FOUND');
    if (o.tech_id !== req.me.id) throw forbidden('Esta oferta no es tuya.');
    if (o.status !== 'pending') throw conflict('Solo se pueden retirar ofertas pendientes.', 'INVALID_STATE');
    db.tx(() => {
      db.run("UPDATE offers SET status = 'withdrawn' WHERE id = ?", id);
      db.run('UPDATE requests SET offers_count = MAX(0, offers_count - 1) WHERE id = ?', o.request_id);
    });
    return { offer: offerJson(db.get('SELECT * FROM offers WHERE id = ?', id)!) };
  });

  app.post('/offers/:id/accept', { preHandler: g.auth }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const o = db.get('SELECT * FROM offers WHERE id = ?', id);
    if (!o) throw notFound('No encontramos esa oferta.', 'OFFER_NOT_FOUND');
    const r = db.get('SELECT * FROM requests WHERE id = ?', o.request_id)!;
    if (r.client_id !== req.me.id) throw forbidden('Solo quien publicó la necesidad puede aceptar ofertas.');
    if (o.status !== 'pending' || r.status !== 'open') throw conflict('Esta oferta ya no está disponible.', 'OFFER_UNAVAILABLE');
    const jobId = newId();
    const commission = commissionOf(o.price, cfg.commissionPercent);
    const others = db.all("SELECT * FROM offers WHERE request_id = ? AND id != ? AND status = 'pending'", r.id, o.id);
    db.tx(() => {
      db.run("UPDATE offers SET status = 'accepted' WHERE id = ?", o.id);
      db.run("UPDATE offers SET status = 'rejected' WHERE request_id = ? AND id != ? AND status = 'pending'", r.id, o.id);
      db.run("UPDATE requests SET status = 'assigned' WHERE id = ?", r.id);
      db.run(
        `INSERT INTO jobs (id, request_id, offer_id, client_id, tech_id, category_id, title, address, lat, lng, price, commission, tech_net, eta_minutes, status, payment_status, created_at)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?, 'pending_payment', 'pending', ?)`,
        jobId, r.id, o.id, r.client_id, o.tech_id, r.category_id, r.title, r.address, r.lat, r.lng,
        o.price, commission, o.price - commission, o.eta_minutes, nowIso(),
      );
    });
    hub.send(o.tech_id, 'offer.accepted', { ...offerJson({ ...o, status: 'accepted' }), jobId });
    notify(ctx, o.tech_id, 'offer.accepted', '¡Te eligieron!', `${req.me.name} aceptó tu oferta de ${money(o.price)} por "${r.title}". Falta que pague.`, { requestId: r.id, offerId: o.id, jobId });
    for (const x of others) {
      hub.send(x.tech_id, 'offer.rejected', offerJson({ ...x, status: 'rejected' }));
      notify(ctx, x.tech_id, 'offer.rejected', 'Oferta no elegida', `El cliente eligió otra oferta para "${r.title}".`, { requestId: r.id, offerId: x.id });
    }
    emitJob(ctx, jobId);
    reply.code(201);
    return { job: jobJson(db.get('SELECT * FROM jobs WHERE id = ?', jobId)!) };
  });

  // ---------- Servicios publicados ----------
  const listingBase = z.object({
    categoryId: z.string(),
    title: z.string().trim().min(3).max(120),
    description: z.string().trim().max(2000).default(''),
    price: z.number().int().min(1).max(50_000_000),
    priceType: z.enum(['fixed', 'from', 'hourly']).default('fixed'),
    durationMinutes: z.number().int().min(5).max(10080).default(60),
    active: z.boolean().default(true),
  });

  app.get('/listings', async (req) => {
    const q = parse(
      z.object({ lat: numQ, lng: numQ, radiusKm: numQ, categoryId: z.string().optional(), q: z.string().optional(), sort: sortQ }),
      req.query,
    );
    const hasPos = q.lat != null && q.lng != null;
    const radius = q.radiusKm ?? 20;
    const where = ['l.active = 1', 'u.suspended = 0', 'p.available = 1'];
    const params: any[] = [];
    if (q.categoryId) { where.push('l.category_id = ?'); params.push(q.categoryId); }
    if (q.q?.trim()) {
      where.push('(l.title LIKE ? OR l.description LIKE ? OR u.name LIKE ?)');
      const like = `%${q.q.trim()}%`;
      params.push(like, like, like);
    }
    const rows = db.all(
      `SELECT l.*, u.lat AS t_lat, u.lng AS t_lng FROM listings l JOIN users u ON u.id = l.tech_id JOIN tech_profiles p ON p.user_id = u.id
       WHERE ${where.join(' AND ')}`,
      ...params,
    );
    const base = rows
      .map((l) => {
        const d = hasPos && l.t_lat != null ? haversineKm(q.lat!, q.lng!, l.t_lat, l.t_lng) : null;
        return { l, d, tech: techCard(db, l.tech_id, d)! };
      })
      .filter(({ d }) => d === null || d <= radius);
    const scores = scoreItems(
      base.map(({ l, d, tech }) => ({
        key: l.id, price: l.price, distanceKm: d, etaMinutes: d === null ? null : etaFromDistance(d), ratingAvg: tech.ratingAvg, ratingCount: tech.ratingCount,
      })),
    );
    const items = base.map(({ l, d, tech }) => {
      const s = scores.get(l.id)!;
      return {
        ...listingJson(l), tech, distanceKm: d === null ? null : round1(d), etaMinutes: d === null ? null : etaFromDistance(d),
        score: s.score, badge: s.badge, badges: s.badges,
      };
    });
    return { items: sortItems(items, q.sort) };
  });

  app.get('/listings/mine', { preHandler: g.tech }, async (req) => ({
    items: db.all('SELECT * FROM listings WHERE tech_id = ? ORDER BY created_at DESC', req.me.id).map(listingJson),
  }));

  app.post('/listings', { preHandler: g.tech }, async (req, reply) => {
    const b = parse(listingBase, req.body);
    if (!db.get('SELECT 1 FROM categories WHERE id = ?', b.categoryId)) throw badRequest('La categoría no existe.', 'INVALID_CATEGORY');
    const id = newId();
    db.run(
      `INSERT INTO listings (id, tech_id, category_id, title, description, price, price_type, duration_minutes, active, created_at) VALUES (?,?,?,?,?,?,?,?,?,?)`,
      id, req.me.id, b.categoryId, b.title, b.description, b.price, b.priceType, b.durationMinutes, b.active, nowIso(),
    );
    reply.code(201);
    return { listing: listingJson(db.get('SELECT * FROM listings WHERE id = ?', id)!) };
  });

  const ownListing = (id: string, userId: string) => {
    const l = db.get('SELECT * FROM listings WHERE id = ?', id);
    if (!l) throw notFound('No encontramos ese servicio.', 'LISTING_NOT_FOUND');
    if (l.tech_id !== userId) throw forbidden('Este servicio no es tuyo.');
    return l;
  };

  app.patch('/listings/:id', { preHandler: g.tech }, async (req) => {
    const { id } = req.params as { id: string };
    const l = ownListing(id, req.me.id);
    const b = parse(listingBase.partial(), req.body);
    if (b.categoryId && !db.get('SELECT 1 FROM categories WHERE id = ?', b.categoryId)) throw badRequest('La categoría no existe.', 'INVALID_CATEGORY');
    db.run(
      'UPDATE listings SET category_id = ?, title = ?, description = ?, price = ?, price_type = ?, duration_minutes = ?, active = ? WHERE id = ?',
      b.categoryId ?? l.category_id, b.title ?? l.title, b.description ?? l.description, b.price ?? l.price,
      b.priceType ?? l.price_type, b.durationMinutes ?? l.duration_minutes, b.active ?? !!l.active, id,
    );
    return { listing: listingJson(db.get('SELECT * FROM listings WHERE id = ?', id)!) };
  });

  app.delete('/listings/:id', { preHandler: g.tech }, async (req) => {
    const { id } = req.params as { id: string };
    ownListing(id, req.me.id);
    db.run('DELETE FROM listings WHERE id = ?', id);
    return { ok: true };
  });

  app.post('/listings/:id/book', { preHandler: g.auth }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const b = parse(
      z.object({
        address: z.string().trim().min(3).max(200),
        lat: z.number().min(-90).max(90),
        lng: z.number().min(-180).max(180),
        notes: z.string().trim().max(1000).optional(),
        scheduledAt: z.string().datetime().nullable().optional(),
      }),
      req.body,
    );
    const l = db.get('SELECT * FROM listings WHERE id = ?', id);
    if (!l || !l.active) throw notFound('Ese servicio ya no está disponible.', 'LISTING_NOT_FOUND');
    if (l.tech_id === req.me.id) throw forbidden('No podés contratar tu propio servicio.');
    const tc = userCoords(l.tech_id);
    const d = dist(tc, b.lat, b.lng);
    const eta = d === null ? 30 : etaFromDistance(d);
    const commission = commissionOf(l.price, cfg.commissionPercent);
    const jobId = newId();
    db.run(
      `INSERT INTO jobs (id, listing_id, client_id, tech_id, category_id, title, address, lat, lng, price, commission, tech_net, eta_minutes, status, payment_status, notes, scheduled_at, created_at)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?, 'pending_payment', 'pending', ?,?,?)`,
      jobId, l.id, req.me.id, l.tech_id, l.category_id, l.title, b.address, b.lat, b.lng, l.price, commission,
      l.price - commission, eta, b.notes ?? null, b.scheduledAt ?? null, nowIso(),
    );
    notify(ctx, l.tech_id, 'job.new', 'Nueva reserva', `${req.me.name} reservó "${l.title}". Esperando el pago.`, { jobId });
    emitJob(ctx, jobId);
    reply.code(201);
    return { job: jobJson(db.get('SELECT * FROM jobs WHERE id = ?', jobId)!) };
  });

  void userJson;
}
