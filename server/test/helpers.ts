import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';

export async function makeApp(opts: { seed?: boolean } = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'fixi-test-'));
  const { app, ctx } = await buildApp({
    seed: opts.seed ?? false,
    cfg: { dbPath: path.join(dir, 'test.db'), uploadsDir: path.join(dir, 'uploads'), commissionPercent: 5, paymentProvider: 'mock' },
  });
  await app.ready();
  const close = async () => {
    await app.close();
    fs.rmSync(dir, { recursive: true, force: true });
  };
  return { app, ctx, close };
}

export function client(app: FastifyInstance, token?: string) {
  const call = async (method: string, url: string, payload?: unknown) => {
    const res = await app.inject({
      method: method as any,
      url: `/api/v1${url}`,
      payload: payload as any,
      headers: token ? { authorization: `Bearer ${token}` } : {},
    });
    let body: any = null;
    try { body = res.json(); } catch { body = res.body; }
    return { status: res.statusCode, body };
  };
  return {
    get: (u: string) => call('GET', u),
    post: (u: string, p?: unknown) => call('POST', u, p ?? {}),
    put: (u: string, p?: unknown) => call('PUT', u, p),
    patch: (u: string, p?: unknown) => call('PATCH', u, p),
    del: (u: string) => call('DELETE', u),
  };
}

export async function register(app: FastifyInstance, name: string, email: string) {
  const r = await client(app).post('/auth/register', { name, email, password: 'secreto123' });
  if (r.status !== 201) throw new Error('registro falló: ' + JSON.stringify(r.body));
  return { token: r.body.token as string, user: r.body.user, api: client(app, r.body.token) };
}

/** Crea un tecnico con perfil, categoria y ubicacion. */
export async function makeTech(app: FastifyInstance, name: string, email: string, lat = -34.61, lng = -58.4) {
  const t = await register(app, name, email);
  await t.api.patch('/me', { lat, lng });
  const r = await t.api.put('/me/tech-profile', { bio: 'Técnico de prueba', categoryIds: ['c_pc-notebooks'], radiusKm: 20, available: true });
  if (r.status !== 200) throw new Error('perfil falló: ' + JSON.stringify(r.body));
  return t;
}

export const baseRequest = {
  categoryId: 'c_pc-notebooks',
  title: 'Notebook no enciende',
  description: 'No prende',
  lat: -34.6037,
  lng: -58.3816,
  address: 'Obelisco',
  urgency: 'today',
};

/** Siembra solo categorias (sin el seed completo) para tests rapidos. */
export function seedCategories(ctx: { db: any }) {
  ctx.db.run("INSERT INTO categories (id, slug, name, icon, grp, sort_order) VALUES ('c_pc-notebooks','pc-notebooks','PC y notebooks','laptop_mac','Tecnología',0)");
}
