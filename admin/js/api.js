// Cliente de la API de Fixi (mismo origen, bajo /api/v1).
const TOKEN_KEY = 'fixi_admin_token';
const USER_KEY = 'fixi_admin_user';

function safeGet(k) { try { return localStorage.getItem(k); } catch { return null; } }
function safeSet(k, v) { try { v == null ? localStorage.removeItem(k) : localStorage.setItem(k, v); } catch { /* sin storage */ } }

// Se puede apuntar a otro servidor con localStorage.fixi_api_base = 'http://192.168.0.10:4000/api/v1'
export const API_BASE = (safeGet('fixi_api_base') || new URL('../api/v1', location.href).pathname).replace(/\/$/, '');
export const ORIGIN = API_BASE.startsWith('http') ? new URL(API_BASE).origin : location.origin;

export const session = {
  get token() { return safeGet(TOKEN_KEY); },
  get user() { try { return JSON.parse(safeGet(USER_KEY) || 'null'); } catch { return null; } },
  set(token, user) { safeSet(TOKEN_KEY, token); safeSet(USER_KEY, user ? JSON.stringify(user) : null); },
  clear() { safeSet(TOKEN_KEY, null); safeSet(USER_KEY, null); },
};

export class ApiError extends Error {
  constructor(message, { status = 0, code = 'ERROR' } = {}) { super(message); this.status = status; this.code = code; }
}

let onUnauthorized = () => {};
export function setUnauthorizedHandler(fn) { onUnauthorized = fn; }

export async function api(path, { method = 'GET', body, auth = true, signal } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (auth && session.token) headers.Authorization = `Bearer ${session.token}`;
  let res;
  try {
    res = await fetch(API_BASE + path, { method, headers, signal, body: body !== undefined ? JSON.stringify(body) : undefined });
  } catch (e) {
    if (e.name === 'AbortError') throw e;
    throw new ApiError('No pudimos conectar con el servidor. Revisá que esté encendido y probá de nuevo.', { code: 'NETWORK' });
  }
  let data = null;
  const text = await res.text();
  if (text) { try { data = JSON.parse(text); } catch { data = null; } }
  if (!res.ok) {
    const err = new ApiError(data?.error?.message || `El servidor respondió con un error (${res.status}).`, { status: res.status, code: data?.error?.code || 'HTTP_' + res.status });
    if (res.status === 401 && auth) onUnauthorized(err);
    throw err;
  }
  return data;
}

export const items = (d) => (Array.isArray(d) ? d : Array.isArray(d?.items) ? d.items : []);

export async function login(email, password) {
  const d = await api('/auth/login', { method: 'POST', body: { email, password }, auth: false });
  if (!d?.user || d.user.role !== 'admin') {
    throw new ApiError('Esta cuenta no tiene permisos de administración.', { status: 403, code: 'NOT_ADMIN' });
  }
  session.set(d.token, d.user);
  return d.user;
}

// /health: el contrato lo lista dentro de /api/v1; probamos también en la raíz.
export async function health() {
  const t0 = performance.now();
  for (const url of [API_BASE + '/health', ORIGIN + '/health']) {
    try {
      const r = await fetch(url, { headers: { Accept: 'application/json' } });
      if (r.ok) { const d = await r.json().catch(() => ({})); return { ...d, ms: Math.round(performance.now() - t0), url }; }
    } catch { /* probar la siguiente */ }
  }
  throw new ApiError('El servidor no responde en /health.', { code: 'NETWORK' });
}
