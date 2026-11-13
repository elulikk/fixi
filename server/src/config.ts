import path from 'node:path';

export interface Config {
  port: number;
  host: string;
  jwtSecret: string;
  dbPath: string;
  uploadsDir: string;
  adminDir: string;
  publicBaseUrl: string;
  paymentProvider: 'mock' | 'mercadopago';
  commissionPercent: number;
  mpAccessToken: string;
  mpClientId: string;
  mpClientSecret: string;
  mpWebhookSecret: string;
  mpSandbox: boolean;
  mpAuthUrl: string;
  version: string;
}

const root = path.resolve(import.meta.dirname, '..');

export function loadConfig(over: Partial<Config> = {}): Config {
  const e = process.env;
  return {
    port: Number(e.PORT ?? 4000),
    host: e.HOST ?? '0.0.0.0',
    jwtSecret: e.JWT_SECRET || 'fixi-dev-secret-cambiar-en-produccion',
    dbPath: path.resolve(root, e.DB_PATH || './data/fixi.db'),
    uploadsDir: path.resolve(root, 'uploads'),
    adminDir: path.resolve(root, '..', 'admin'),
    publicBaseUrl: (e.PUBLIC_BASE_URL ?? '').replace(/\/+$/, ''),
    paymentProvider: e.PAYMENT_PROVIDER === 'mercadopago' ? 'mercadopago' : 'mock',
    commissionPercent: e.COMMISSION_PERCENT ? Number(e.COMMISSION_PERCENT) : 5,
    mpAccessToken: e.MP_ACCESS_TOKEN ?? '',
    mpClientId: e.MP_CLIENT_ID ?? '',
    mpClientSecret: e.MP_CLIENT_SECRET ?? '',
    mpWebhookSecret: e.MP_WEBHOOK_SECRET ?? '',
    mpSandbox: e.MP_SANDBOX === 'true',
    mpAuthUrl: (e.MP_AUTH_URL ?? 'https://auth.mercadopago.com.ar').replace(/\/+$/, ''),
    version: '1.0.0',
    ...over,
  };
}
