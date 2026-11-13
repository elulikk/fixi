import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { Row } from './db.js';
import type { Ctx } from './services.js';
import { AppError, forbidden } from './util.js';

declare module 'fastify' {
  interface FastifyRequest {
    me: Row;
  }
}

export interface Guards {
  /** Exige JWT valido y cuenta no suspendida. Deja el usuario en req.me. */
  auth: (req: FastifyRequest) => Promise<void>;
  /** auth + perfil tecnico creado. */
  tech: (req: FastifyRequest) => Promise<void>;
  /** auth + role admin. */
  admin: (req: FastifyRequest) => Promise<void>;
}

export function makeGuards(app: FastifyInstance, ctx: Ctx): Guards {
  app.decorateRequest('me', null as any);
  const auth = async (req: FastifyRequest) => {
    const h = req.headers.authorization;
    if (!h?.startsWith('Bearer ')) throw new AppError(401, 'UNAUTHORIZED', 'Iniciá sesión para continuar.');
    let payload: any;
    try {
      payload = app.jwt.verify(h.slice(7));
    } catch {
      throw new AppError(401, 'UNAUTHORIZED', 'Tu sesión venció. Volvé a iniciar sesión.');
    }
    const me = ctx.db.get('SELECT * FROM users WHERE id = ?', payload.sub);
    if (!me) throw new AppError(401, 'UNAUTHORIZED', 'Tu sesión no es válida. Volvé a iniciar sesión.');
    if (me.suspended) throw new AppError(403, 'ACCOUNT_SUSPENDED', 'Tu cuenta está suspendida. Escribinos a soporte.');
    req.me = me;
  };
  return {
    auth,
    tech: async (req) => {
      await auth(req);
      if (!req.me.is_technician) throw forbidden('Primero tenés que crear tu perfil de técnico.', 'NOT_TECHNICIAN');
    },
    admin: async (req) => {
      await auth(req);
      if (req.me.role !== 'admin') throw forbidden('Solo para administradores.', 'NOT_ADMIN');
    },
  };
}
