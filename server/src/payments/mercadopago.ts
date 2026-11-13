import { createHmac, timingSafeEqual } from 'node:crypto';
import type { Config } from '../config.js';
import type { Db, Row } from '../db.js';
import { AppError } from '../util.js';
import { signState, verifyState } from './state.js';
import type { CheckoutInput, PaymentProvider, WebhookEvent, WebhookInput } from './types.js';

const API = 'https://api.mercadopago.com';

/**
 * Mercado Pago - Checkout Pro en modo MARKETPLACE (split de pagos).
 *
 * Flujo completo:
 *  1. El tecnico vincula su cuenta: GET /payments/connect/url devuelve la URL de autorizacion OAuth
 *     (auth.mercadopago.com.ar/authorization?client_id=...&state=...&redirect_uri=...).
 *     Mercado Pago redirige a /payments/connect/callback?code=...&state=...; ahi cambiamos el `code`
 *     por access_token / refresh_token / user_id del tecnico y los guardamos en tech_profiles.
 *  2. Al pagar, creamos una *preferencia* con el access_token DEL TECNICO y `marketplace_fee` = comision de Fixi.
 *     Asi Mercado Pago acredita la comision en la cuenta de Fixi (la de la aplicacion) y el resto al tecnico.
 *     `external_reference` = id de nuestro Payment y `notification_url` apunta a nuestro webhook.
 *  3. Mercado Pago avisa al webhook; consultamos GET /v1/payments/:id con el token del tecnico y
 *     actualizamos el estado segun `status` (approved / rejected / cancelled / refunded...).
 *
 * Requiere: MP_CLIENT_ID, MP_CLIENT_SECRET (OAuth), MP_WEBHOOK_SECRET (firma, recomendado) y
 * una PUBLIC_BASE_URL accesible desde internet (HTTPS) para que lleguen los webhooks.
 * Nota: sin credenciales reales este codigo no se pudo probar contra la API de Mercado Pago.
 */
export class MercadoPagoProvider implements PaymentProvider {
  readonly name = 'mercadopago' as const;
  constructor(private db: Db, private cfg: Config) {}

  private async mp(path: string, token: string, init: { method?: string; body?: unknown } = {}) {
    const res = await fetch(`${API}${path}`, {
      method: init.method ?? (init.body ? 'POST' : 'GET'),
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: init.body ? JSON.stringify(init.body) : undefined,
    });
    const text = await res.text();
    let json: any = {};
    try {
      json = text ? JSON.parse(text) : {};
    } catch {
      /* respuesta no JSON */
    }
    if (!res.ok) {
      throw new AppError(502, 'MP_ERROR', `Mercado Pago respondió ${res.status}: ${json?.message ?? text.slice(0, 120)}`);
    }
    return json;
  }

  /** Devuelve un access_token vigente del tecnico, renovandolo con el refresh_token si vencio. */
  private async techToken(tech: Row): Promise<string> {
    if (!tech.mp_access_token) {
      throw new AppError(409, 'TECH_NOT_CONNECTED', 'El técnico todavía no vinculó su cuenta de Mercado Pago.');
    }
    const exp = tech.mp_expires_at ? Date.parse(tech.mp_expires_at) : Infinity;
    if (exp - Date.now() > 5 * 60_000 || !tech.mp_refresh_token) return tech.mp_access_token;
    const t = await this.mp('/oauth/token', this.cfg.mpAccessToken, {
      body: {
        client_id: this.cfg.mpClientId,
        client_secret: this.cfg.mpClientSecret,
        grant_type: 'refresh_token',
        refresh_token: tech.mp_refresh_token,
      },
    });
    this.db.run(
      'UPDATE tech_profiles SET mp_access_token = ?, mp_refresh_token = ?, mp_expires_at = ? WHERE user_id = ?',
      t.access_token,
      t.refresh_token ?? tech.mp_refresh_token,
      new Date(Date.now() + (t.expires_in ?? 15552000) * 1000).toISOString(),
      tech.user_id,
    );
    return t.access_token;
  }

  async createCheckout({ payment, job, tech, baseUrl }: CheckoutInput) {
    const token = await this.techToken(tech);
    const pref = await this.mp('/checkout/preferences', token, {
      body: {
        items: [
          { id: job.id, title: String(job.title).slice(0, 250), description: 'Servicio técnico a domicilio - Fixi', quantity: 1, currency_id: 'ARS', unit_price: payment.amount },
        ],
        // Comision de Fixi: Mercado Pago la acredita en la cuenta de la aplicacion.
        marketplace_fee: payment.commission,
        external_reference: payment.id,
        notification_url: `${baseUrl}/api/v1/payments/webhook/mercadopago?paymentId=${payment.id}`,
        back_urls: {
          success: `${baseUrl}/pay/return?status=approved`,
          pending: `${baseUrl}/pay/return?status=pending`,
          failure: `${baseUrl}/pay/return?status=failure`,
        },
        auto_return: 'approved',
        statement_descriptor: 'FIXI',
        metadata: { jobId: job.id, paymentId: payment.id },
      },
    });
    const url = this.cfg.mpSandbox ? pref.sandbox_init_point : pref.init_point;
    return { checkoutUrl: url ?? pref.init_point, providerRef: String(pref.id ?? '') || null };
  }

  /** Valida x-signature segun https://www.mercadopago.com.ar/developers/es/docs/your-integrations/notifications/webhooks */
  private validSignature(headers: Record<string, any>, dataId: string): boolean {
    if (!this.cfg.mpWebhookSecret) return true; // sin secreto configurado no se puede validar
    const sig = String(headers['x-signature'] ?? '');
    const ts = /ts=([^,]+)/.exec(sig)?.[1];
    const v1 = /v1=([^,]+)/.exec(sig)?.[1];
    if (!ts || !v1) return false;
    const manifest = `id:${String(dataId).toLowerCase()};request-id:${headers['x-request-id'] ?? ''};ts:${ts};`;
    const expected = createHmac('sha256', this.cfg.mpWebhookSecret).update(manifest).digest('hex');
    const a = Buffer.from(v1);
    const b = Buffer.from(expected);
    return a.length === b.length && timingSafeEqual(a, b);
  }

  async parseWebhook({ body, query, headers }: WebhookInput): Promise<WebhookEvent | null> {
    const topic = body?.type ?? query.type ?? query.topic;
    if (topic && topic !== 'payment') return null;
    const mpPaymentId = String(body?.data?.id ?? query['data.id'] ?? query.id ?? '');
    if (!mpPaymentId) return null;
    if (!this.validSignature(headers, mpPaymentId)) throw new AppError(401, 'BAD_SIGNATURE', 'Firma de webhook inválida.');

    // Ubicamos nuestro Payment (viene en la notification_url) para saber con que token consultar.
    let ours: Row | undefined = query.paymentId ? this.db.get('SELECT * FROM payments WHERE id = ?', query.paymentId) : undefined;
    if (!ours && body?.user_id) {
      ours = undefined; // sin paymentId solo podemos intentar con el token de la aplicacion
    }
    let token = this.cfg.mpAccessToken;
    if (ours) {
      const tech = this.db.get(
        'SELECT p.* FROM jobs j JOIN tech_profiles p ON p.user_id = j.tech_id WHERE j.id = ?',
        ours.job_id,
      );
      if (tech?.mp_access_token) token = await this.techToken(tech);
    }
    if (!token) return null;

    const mp = await this.mp(`/v1/payments/${mpPaymentId}`, token);
    const paymentId = String(mp.external_reference ?? ours?.id ?? '');
    if (!paymentId) return null;
    const map: Record<string, WebhookEvent['status']> = {
      approved: 'approved',
      authorized: 'pending',
      pending: 'pending',
      in_process: 'pending',
      in_mediation: 'pending',
      rejected: 'failed',
      cancelled: 'failed',
      refunded: 'refunded',
      charged_back: 'refunded',
    };
    return { paymentId, status: map[mp.status] ?? 'pending', providerRef: mpPaymentId };
  }

  connectUrl(userId: string, baseUrl: string) {
    if (!this.cfg.mpClientId) throw new AppError(503, 'MP_NOT_CONFIGURED', 'Mercado Pago no está configurado en el servidor (falta MP_CLIENT_ID).');
    const redirect = `${this.cfg.publicBaseUrl || baseUrl}/api/v1/payments/connect/callback`;
    const q = new URLSearchParams({
      client_id: this.cfg.mpClientId,
      response_type: 'code',
      platform_id: 'mp',
      state: signState(this.cfg.jwtSecret, userId),
      redirect_uri: redirect,
    });
    return `${this.cfg.mpAuthUrl}/authorization?${q}`;
  }

  async handleConnectCallback(query: Record<string, any>, baseUrl: string) {
    const userId = verifyState(this.cfg.jwtSecret, query.state);
    if (!userId || !query.code) {
      throw new AppError(400, 'INVALID_STATE', 'No pudimos validar la vinculación con Mercado Pago. Probá de nuevo desde la app.');
    }
    const t = await this.mp('/oauth/token', this.cfg.mpAccessToken || 'unused', {
      body: {
        client_id: this.cfg.mpClientId,
        client_secret: this.cfg.mpClientSecret,
        grant_type: 'authorization_code',
        code: query.code,
        redirect_uri: `${this.cfg.publicBaseUrl || baseUrl}/api/v1/payments/connect/callback`,
      },
    });
    this.db.run(
      `UPDATE tech_profiles SET payments_connected = 1, mp_user_id = ?, mp_access_token = ?, mp_refresh_token = ?, mp_expires_at = ? WHERE user_id = ?`,
      String(t.user_id),
      t.access_token,
      t.refresh_token,
      new Date(Date.now() + (t.expires_in ?? 15552000) * 1000).toISOString(),
      userId,
    );
    return { userId };
  }

  async refund(payment: Row, tech: Row) {
    if (!payment.provider_ref || !tech?.mp_access_token) return;
    const token = await this.techToken(tech);
    await this.mp(`/v1/payments/${payment.provider_ref}/refunds`, token, { body: {} });
  }
}
