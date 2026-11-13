import type { FastifyInstance } from 'fastify';
import bcrypt from 'bcryptjs';
import fs from 'node:fs';
import path from 'node:path';
import { z } from 'zod';
import type { Guards } from '../guards.js';
import { baseUrl, type Ctx } from '../services.js';
import {
  categoryJson, listingJson, notificationJson, publicUser, reviewJson, techCard, techProfileJson, userJson,
} from '../serialize.js';
import { AppError, badRequest, conflict, newId, notFound, nowIso, parse } from '../util.js';

export function issueToken(app: FastifyInstance, user: { id: string; role: string }) {
  return app.jwt.sign({ sub: user.id, role: user.role }, { expiresIn: '30d' });
}

export default function coreRoutes(app: FastifyInstance, ctx: Ctx, g: Guards) {
  const { db } = ctx;

  app.get('/health', async () => ({ ok: true, version: ctx.cfg.version }));

  // ---------- Auth ----------
  const registerSchema = z.object({
    name: z.string().trim().min(2).max(80),
    email: z.string().trim().toLowerCase().email().max(120),
    password: z.string().min(6).max(100),
    phone: z.string().trim().max(40).optional(),
  });
  app.post('/auth/register', async (req, reply) => {
    const b = parse(registerSchema, req.body);
    if (db.get('SELECT 1 FROM users WHERE email = ?', b.email)) {
      throw conflict('Ya existe una cuenta con ese email.', 'EMAIL_TAKEN');
    }
    const id = newId();
    db.run(
      `INSERT INTO users (id, name, email, phone, avatar_url, role, is_technician, password_hash, created_at)
       VALUES (?,?,?,?,?, 'user', 0, ?, ?)`,
      id, b.name, b.email, b.phone ?? null, `https://i.pravatar.cc/300?u=${id}`, bcrypt.hashSync(b.password, 10), nowIso(),
    );
    const user = db.get('SELECT * FROM users WHERE id = ?', id)!;
    reply.code(201);
    return { token: issueToken(app, user as any), user: userJson(user) };
  });

  app.post('/auth/login', async (req) => {
    const b = parse(z.object({ email: z.string().trim().toLowerCase(), password: z.string() }), req.body);
    const user = db.get('SELECT * FROM users WHERE email = ?', b.email);
    if (!user || !bcrypt.compareSync(b.password, user.password_hash)) {
      throw new AppError(401, 'INVALID_CREDENTIALS', 'Email o contraseña incorrectos.');
    }
    if (user.suspended) throw new AppError(403, 'ACCOUNT_SUSPENDED', 'Tu cuenta está suspendida. Escribinos a soporte.');
    return { token: issueToken(app, user as any), user: userJson(user) };
  });

  // ---------- Perfil ----------
  const meResponse = (id: string) => {
    const user = db.get('SELECT * FROM users WHERE id = ?', id)!;
    const prof = db.get('SELECT * FROM tech_profiles WHERE user_id = ?', id);
    return { user: userJson(user), ...(prof ? { techProfile: techProfileJson(prof) } : {}) };
  };

  app.get('/me', { preHandler: g.auth }, async (req) => meResponse(req.me.id));

  app.patch('/me', { preHandler: g.auth }, async (req) => {
    const b = parse(
      z.object({
        name: z.string().trim().min(2).max(80).optional(),
        phone: z.string().trim().max(40).nullable().optional(),
        avatarUrl: z.string().max(500).nullable().optional(),
        lat: z.number().min(-90).max(90).optional(),
        lng: z.number().min(-180).max(180).optional(),
        address: z.string().trim().max(200).nullable().optional(),
      }),
      req.body,
    );
    const m = req.me;
    db.run(
      'UPDATE users SET name = ?, phone = ?, avatar_url = ?, lat = ?, lng = ?, address = ? WHERE id = ?',
      b.name ?? m.name,
      b.phone === undefined ? m.phone : b.phone,
      b.avatarUrl === undefined ? m.avatar_url : b.avatarUrl,
      b.lat ?? m.lat,
      b.lng ?? m.lng,
      b.address === undefined ? m.address : b.address,
      m.id,
    );
    return meResponse(m.id);
  });

  app.put('/me/tech-profile', { preHandler: g.auth }, async (req) => {
    const b = parse(
      z.object({
        bio: z.string().trim().max(1000).default(''),
        categoryIds: z.array(z.string()).min(1).max(12),
        radiusKm: z.number().min(1).max(100).default(10),
        available: z.boolean().default(true),
      }),
      req.body,
    );
    const ids = [...new Set(b.categoryIds)];
    for (const c of ids) if (!db.get('SELECT 1 FROM categories WHERE id = ?', c)) throw badRequest('Una de las categorías no existe.', 'INVALID_CATEGORY');
    db.tx(() => {
      if (db.get('SELECT 1 FROM tech_profiles WHERE user_id = ?', req.me.id)) {
        db.run('UPDATE tech_profiles SET bio = ?, category_ids = ?, radius_km = ?, available = ? WHERE user_id = ?',
          b.bio, JSON.stringify(ids), b.radiusKm, b.available, req.me.id);
      } else {
        db.run('INSERT INTO tech_profiles (user_id, bio, category_ids, radius_km, available) VALUES (?,?,?,?,?)',
          req.me.id, b.bio, JSON.stringify(ids), b.radiusKm, b.available);
      }
      db.run('UPDATE users SET is_technician = 1 WHERE id = ?', req.me.id);
    });
    return meResponse(req.me.id);
  });

  app.get('/techs/:userId', async (req) => {
    const { userId } = req.params as { userId: string };
    const card = techCard(db, userId);
    const prof = db.get('SELECT * FROM tech_profiles WHERE user_id = ?', userId);
    if (!card || !prof) throw notFound('No encontramos a ese técnico.', 'TECH_NOT_FOUND');
    const listings = db.all('SELECT * FROM listings WHERE tech_id = ? AND active = 1 ORDER BY created_at DESC', userId).map(listingJson);
    const reviews = db
      .all(
        `SELECT r.*, u.name AS from_name, u.avatar_url AS from_avatar FROM reviews r JOIN users u ON u.id = r.from_user_id
         WHERE r.to_user_id = ? ORDER BY r.created_at DESC LIMIT 50`,
        userId,
      )
      .map((r) => ({ ...reviewJson(r), from: { id: r.from_user_id, name: r.from_name, avatarUrl: r.from_avatar ?? null } }));
    return { tech: card, profile: techProfileJson(prof), listings, reviews };
  });

  // ---------- Catalogo ----------
  app.get('/categories', async () => ({
    items: db.all('SELECT * FROM categories ORDER BY sort_order, name').map(categoryJson),
  }));

  // ---------- Notificaciones ----------
  app.get('/notifications', { preHandler: g.auth }, async (req) => {
    const rows = db.all('SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 100', req.me.id);
    return { items: rows.map(notificationJson), unreadCount: rows.filter((r) => !r.read).length };
  });
  app.post('/notifications/read-all', { preHandler: g.auth }, async (req) => {
    db.run('UPDATE notifications SET read = 1 WHERE user_id = ?', req.me.id);
    return { ok: true };
  });

  // ---------- Subida de fotos (agregado al contrato) ----------
  const EXT: Record<string, string> = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp', 'image/heic': '.heic', 'image/gif': '.gif' };
  app.post('/uploads', { preHandler: g.auth }, async (req) => {
    const file = await (req as any).file();
    if (!file) throw badRequest('Adjuntá una imagen.', 'NO_FILE');
    const ext = EXT[file.mimetype];
    if (!ext) throw badRequest('Solo se aceptan imágenes JPG, PNG, WEBP o HEIC.', 'INVALID_FILE');
    const name = `${newId()}${ext}`;
    fs.mkdirSync(ctx.cfg.uploadsDir, { recursive: true });
    const buf = await file.toBuffer();
    if (file.file.truncated) throw badRequest('La imagen es demasiado grande (máx. 8 MB).', 'FILE_TOO_LARGE');
    fs.writeFileSync(path.join(ctx.cfg.uploadsDir, name), buf);
    return { url: `${baseUrl(ctx, req)}/uploads/${name}` };
  });

  void publicUser;
}
