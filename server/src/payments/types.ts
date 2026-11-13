import type { Row } from '../db.js';

export interface CheckoutInput {
  /** Fila de payments recien creada (status pending). */
  payment: Row;
  /** Fila de jobs. */
  job: Row;
  /** Fila de users + tech_profiles del tecnico (incluye tokens de MP). */
  tech: Row;
  /** URL publica base del server, sin barra final. */
  baseUrl: string;
}

export interface WebhookInput {
  body: any;
  query: Record<string, any>;
  headers: Record<string, any>;
  baseUrl: string;
}

export interface WebhookEvent {
  paymentId: string;
  status: 'approved' | 'failed' | 'refunded' | 'pending';
  providerRef?: string;
}

/** Contrato que implementa cada pasarela de pago. */
export interface PaymentProvider {
  readonly name: 'mock' | 'mercadopago';
  /** Crea el checkout y devuelve la URL a la que se manda al cliente. */
  createCheckout(input: CheckoutInput): Promise<{ checkoutUrl: string; providerRef: string | null }>;
  /** Interpreta una notificacion entrante. Devuelve null si no es relevante / no es valida. */
  parseWebhook(input: WebhookInput): Promise<WebhookEvent | null>;
  /** URL para que el tecnico vincule su cuenta de cobro. */
  connectUrl(userId: string, baseUrl: string): string;
  /** Procesa el retorno del OAuth. Devuelve el userId vinculado. */
  handleConnectCallback(query: Record<string, any>, baseUrl: string): Promise<{ userId: string }>;
  /** Devuelve el dinero (cancelaciones / resolucion de disputas). Best effort. */
  refund(payment: Row, tech: Row): Promise<void>;
}
