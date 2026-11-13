import type { Config } from '../config.js';
import type { Db } from '../db.js';
import { AppError } from '../util.js';
import { signState, verifyState } from './state.js';
import type { CheckoutInput, PaymentProvider, WebhookEvent, WebhookInput } from './types.js';

/**
 * Proveedor simulado para desarrollo y demo.
 * El checkout es una pagina del propio server (GET /pay/mock/:paymentId) cuyos botones llaman
 * a POST /api/v1/payments/webhook/mock con { paymentId, status: "approved" | "rejected" }.
 */
export class MockProvider implements PaymentProvider {
  readonly name = 'mock' as const;
  constructor(private db: Db, private cfg: Config) {}

  async createCheckout({ payment, baseUrl }: CheckoutInput) {
    return { checkoutUrl: `${baseUrl}/pay/mock/${payment.id}`, providerRef: `MOCK-${payment.id.slice(0, 8)}` };
  }

  async parseWebhook({ body }: WebhookInput): Promise<WebhookEvent | null> {
    const paymentId = body?.paymentId;
    if (!paymentId) return null;
    const status = body?.status === 'approved' ? 'approved' : body?.status === 'rejected' ? 'failed' : null;
    return status ? { paymentId, status } : null;
  }

  connectUrl(userId: string, baseUrl: string) {
    return `${baseUrl}/api/v1/payments/connect/callback?mock=1&state=${encodeURIComponent(signState(this.cfg.jwtSecret, userId))}`;
  }

  async handleConnectCallback(query: Record<string, any>) {
    const userId = verifyState(this.cfg.jwtSecret, query.state);
    if (!userId) throw new AppError(400, 'INVALID_STATE', 'El enlace de vinculación venció. Probá de nuevo desde la app.');
    this.db.run(
      `UPDATE tech_profiles SET payments_connected = 1, mp_user_id = ?, mp_access_token = NULL, mp_refresh_token = NULL WHERE user_id = ?`,
      `MOCK-${userId.slice(0, 8)}`,
      userId,
    );
    return { userId };
  }

  async refund() {
    /* No hay dinero real que devolver. */
  }
}
