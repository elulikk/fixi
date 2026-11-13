import { randomUUID } from 'node:crypto';
import { z, ZodType } from 'zod';

export const newId = () => randomUUID();
export const nowIso = () => new Date().toISOString();

export class AppError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}
export const badRequest = (m: string, code = 'BAD_REQUEST') => new AppError(400, code, m);
export const forbidden = (m = 'No tenés permiso para hacer esto.', code = 'FORBIDDEN') => new AppError(403, code, m);
export const notFound = (m = 'No encontramos lo que buscás.', code = 'NOT_FOUND') => new AppError(404, code, m);
export const conflict = (m: string, code = 'CONFLICT') => new AppError(409, code, m);

/** Distancia haversine en km. */
export function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}
export const round1 = (n: number) => Math.round(n * 10) / 10;
export const round2 = (n: number) => Math.round(n * 100) / 100;

export function parse<T extends ZodType>(schema: T, data: unknown): z.infer<T> {
  const r = schema.safeParse(data ?? {});
  if (!r.success) {
    const i = r.error.issues[0];
    const field = i?.path.join('.') || 'datos';
    throw new AppError(400, 'VALIDATION_ERROR', `Revisá el campo «${field}»: dato faltante o inválido.`);
  }
  return r.data;
}

export const commissionOf = (price: number, pct: number) => Math.round((price * pct) / 100);
export const etaFromDistance = (km: number) => Math.round(10 + km * 3);

export function levelFor(points: number): 'bronce' | 'plata' | 'oro' | 'platino' {
  if (points >= 1500) return 'platino';
  if (points >= 600) return 'oro';
  if (points >= 200) return 'plata';
  return 'bronce';
}
