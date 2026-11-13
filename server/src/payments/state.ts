import { createHmac, timingSafeEqual } from 'node:crypto';

/** State firmado para el OAuth de vinculacion (userId + vencimiento de 15 min). */
export function signState(secret: string, userId: string): string {
  const payload = Buffer.from(JSON.stringify({ u: userId, e: Date.now() + 15 * 60_000 })).toString('base64url');
  const sig = createHmac('sha256', secret).update(payload).digest('base64url');
  return `${payload}.${sig}`;
}

export function verifyState(secret: string, state: string): string | null {
  const [payload, sig] = String(state ?? '').split('.');
  if (!payload || !sig) return null;
  const expected = createHmac('sha256', secret).update(payload).digest('base64url');
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !timingSafeEqual(a, b)) return null;
  try {
    const { u, e } = JSON.parse(Buffer.from(payload, 'base64url').toString());
    return e > Date.now() ? u : null;
  } catch {
    return null;
  }
}
