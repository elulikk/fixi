import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import multipart from '@fastify/multipart';
import websocket from '@fastify/websocket';
import fastifyStatic from '@fastify/static';
import fs from 'node:fs';
import { loadConfig, type Config } from './config.js';
import { Db, migrate } from './db.js';
import { makeGuards } from './guards.js';
import { MercadoPagoProvider } from './payments/mercadopago.js';
import { MockProvider } from './payments/mock.js';
import adminRoutes from './routes/admin.js';
import coreRoutes from './routes/core.js';
import jobRoutes from './routes/jobs.js';
import marketplaceRoutes from './routes/marketplace.js';
import paymentRoutes, { paymentPages } from './routes/payments.js';
import { seedDatabase } from './seed.js';
import type { Ctx } from './services.js';
import { AppError } from './util.js';
import { Hub } from './ws.js';

export interface BuildOptions {
  cfg?: Partial<Config>;
  /** Si la base esta vacia, correr el seed (default true). */
  seed?: boolean;
  logger?: boolean;
}

export async function buildApp(opts: BuildOptions = {}): Promise<{ app: FastifyInstance; ctx: Ctx }> {
  const cfg = loadConfig(opts.cfg);
  const db = new Db(cfg.dbPath);
  migrate(db);
  if (opts.seed !== false && (db.get('SELECT COUNT(*) n FROM users') as any).n === 0) {
    seedDatabase(db, cfg);
  }
  const ctx: Ctx = {
    db,
    cfg,
    hub: new Hub(),
    providers: { mock: new MockProvider(db, cfg), mercadopago: new MercadoPagoProvider(db, cfg) },
  };

  const app = Fastify({ logger: opts.logger ? { level: 'info' } : false, trustProxy: true });
  app.addHook('onClose', async () => db.close());

  await app.register(cors, { origin: true, methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'] });
  await app.register(jwt, { secret: cfg.jwtSecret });
  await app.register(multipart, { limits: { fileSize: 8 * 1024 * 1024, files: 1 } });
  await app.register(websocket);

  // ---------- Errores uniformes ----------
  app.setErrorHandler((err: any, req, reply) => {
    if (err instanceof AppError) {
      return reply.code(err.status).send({ error: { code: err.code, message: err.message } });
    }
    const status = err.statusCode && err.statusCode >= 400 && err.statusCode < 500 ? err.statusCode : 500;
    if (status === 500) {
      req.log.error(err);
      return reply.code(500).send({ error: { code: 'INTERNAL_ERROR', message: 'Algo salió mal de nuestro lado. Probá de nuevo en un momento.' } });
    }
    const msg =
      status === 413 ? 'El archivo es demasiado grande (máx. 8 MB).' : status === 415 ? 'Formato de contenido no soportado.' : 'La petición no es válida.';
    return reply.code(status).send({ error: { code: status === 413 ? 'FILE_TOO_LARGE' : 'BAD_REQUEST', message: msg } });
  });
  app.setNotFoundHandler((_req, reply) => {
    reply.code(404).send({ error: { code: 'NOT_FOUND', message: 'No encontramos esa ruta.' } });
  });

  const guards = makeGuards(app, ctx);

  // ---------- WebSocket ----------
  app.get('/ws', { websocket: true }, (socket, req) => {
    const token = (req.query as any)?.token;
    let sub: string | null = null;
    try {
      sub = (app.jwt.verify(String(token)) as any).sub;
    } catch {
      /* token invalido */
    }
    const user = sub ? db.get('SELECT id, suspended FROM users WHERE id = ?', sub) : undefined;
    if (!user || user.suspended) {
      socket.close(4401, 'unauthorized');
      return;
    }
    ctx.hub.add(user.id, socket);
    socket.send(JSON.stringify({ type: 'hello', data: { userId: user.id } }));
    socket.on('message', (raw: Buffer) => {
      if (raw.toString() === 'ping') socket.send(JSON.stringify({ type: 'pong', data: {} }));
    });
  });

  // ---------- API REST ----------
  await app.register(
    async (api) => {
      coreRoutes(api, ctx, guards);
      marketplaceRoutes(api, ctx, guards);
      jobRoutes(api, ctx, guards);
      paymentRoutes(api, ctx, guards);
      adminRoutes(api, ctx, guards);
    },
    { prefix: '/api/v1' },
  );
  paymentPages(app, ctx);
  // /health tambien en la raiz (comodo para curl y chequeos de disponibilidad)
  app.get('/health', async () => ({ ok: true, version: cfg.version }));

  // ---------- Estaticos: /uploads, /admin ----------
  fs.mkdirSync(cfg.uploadsDir, { recursive: true });
  await app.register(fastifyStatic, { root: cfg.uploadsDir, prefix: '/uploads/', decorateReply: false });
  if (fs.existsSync(cfg.adminDir)) {
    await app.register(fastifyStatic, { root: cfg.adminDir, prefix: '/admin/', redirect: true, decorateReply: false });
  } else {
    app.get('/admin', async (_req, reply) =>
      reply.type('text/html; charset=utf-8').send('<h1>Fixi</h1><p>El panel de administración todavía no está disponible (falta la carpeta <code>admin/</code>).</p>'),
    );
  }
  app.get('/', async (_req, reply) => reply.redirect('/admin'));

  return { app, ctx };
}
