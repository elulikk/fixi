import type { Db, Row } from './db.js';
import { round1 } from './util.js';

const b = (v: any) => !!v;

export const userJson = (r: Row) => ({
  id: r.id,
  name: r.name,
  email: r.email,
  phone: r.phone ?? null,
  avatarUrl: r.avatar_url ?? null,
  role: r.role,
  isTechnician: b(r.is_technician),
  lat: r.lat ?? null,
  lng: r.lng ?? null,
  address: r.address ?? null,
  createdAt: r.created_at,
});

export const publicUser = (r: Row) => ({ id: r.id, name: r.name, avatarUrl: r.avatar_url ?? null, phone: r.phone ?? null });

export const techProfileJson = (r: Row) => ({
  userId: r.user_id,
  bio: r.bio,
  categoryIds: JSON.parse(r.category_ids || '[]') as string[],
  radiusKm: r.radius_km,
  available: b(r.available),
  verified: b(r.verified),
  ratingAvg: r.rating_avg,
  ratingCount: r.rating_count,
  jobsDone: r.jobs_done,
  points: r.points,
  level: r.level,
  paymentsConnected: b(r.payments_connected),
});

export const categoryJson = (r: Row) => ({ id: r.id, slug: r.slug, name: r.name, icon: r.icon, group: r.grp });

export function techCard(db: Db, userId: string, distanceKm?: number | null) {
  const r = db.get(
    `SELECT u.id, u.name, u.avatar_url, p.rating_avg, p.rating_count, p.jobs_done, p.points, p.level, p.verified
     FROM users u JOIN tech_profiles p ON p.user_id = u.id WHERE u.id = ?`,
    userId,
  );
  if (!r) return null;
  const card: Record<string, any> = {
    userId: r.id,
    name: r.name,
    avatarUrl: r.avatar_url ?? null,
    ratingAvg: r.rating_avg,
    ratingCount: r.rating_count,
    jobsDone: r.jobs_done,
    points: r.points,
    level: r.level,
    verified: b(r.verified),
  };
  if (distanceKm !== undefined) card.distanceKm = distanceKm === null ? null : round1(distanceKm);
  return card as {
    userId: string; name: string; avatarUrl: string | null; ratingAvg: number; ratingCount: number;
    jobsDone: number; points: number; level: string; verified: boolean; distanceKm?: number | null;
  };
}

export const requestJson = (r: Row) => ({
  id: r.id,
  clientId: r.client_id,
  categoryId: r.category_id,
  title: r.title,
  description: r.description,
  photos: JSON.parse(r.photos || '[]') as string[],
  lat: r.lat,
  lng: r.lng,
  address: r.address,
  budgetMax: r.budget_max ?? null,
  urgency: r.urgency,
  scheduledAt: r.scheduled_at ?? null,
  status: r.status,
  offersCount: r.offers_count,
  createdAt: r.created_at,
});

export const offerJson = (r: Row) => ({
  id: r.id,
  requestId: r.request_id,
  techId: r.tech_id,
  price: r.price,
  etaMinutes: r.eta_minutes,
  durationMinutes: r.duration_minutes,
  message: r.message,
  status: r.status,
  createdAt: r.created_at,
});

export const listingJson = (r: Row) => ({
  id: r.id,
  techId: r.tech_id,
  categoryId: r.category_id,
  title: r.title,
  description: r.description,
  price: r.price,
  priceType: r.price_type,
  durationMinutes: r.duration_minutes,
  active: b(r.active),
  createdAt: r.created_at,
});

export const jobJson = (r: Row) => ({
  id: r.id,
  requestId: r.request_id ?? null,
  offerId: r.offer_id ?? null,
  listingId: r.listing_id ?? null,
  clientId: r.client_id,
  techId: r.tech_id,
  categoryId: r.category_id,
  title: r.title,
  address: r.address,
  lat: r.lat ?? null,
  lng: r.lng ?? null,
  price: r.price,
  commission: r.commission,
  techNet: r.tech_net,
  etaMinutes: r.eta_minutes,
  status: r.status,
  paymentStatus: r.payment_status,
  notes: r.notes ?? null,
  scheduledAt: r.scheduled_at ?? null,
  createdAt: r.created_at,
  paidAt: r.paid_at ?? null,
  startedAt: r.started_at ?? null,
  completedAt: r.completed_at ?? null,
});

export const paymentJson = (r: Row) => ({
  id: r.id,
  jobId: r.job_id,
  provider: r.provider,
  providerRef: r.provider_ref ?? null,
  amount: r.amount,
  commission: r.commission,
  status: r.status,
  checkoutUrl: r.checkout_url ?? null,
  createdAt: r.created_at,
});

export const reviewJson = (r: Row) => ({
  id: r.id,
  jobId: r.job_id,
  fromUserId: r.from_user_id,
  toUserId: r.to_user_id,
  rating: r.rating,
  comment: r.comment,
  createdAt: r.created_at,
});

export const messageJson = (r: Row) => ({
  id: r.id,
  jobId: r.job_id,
  fromUserId: r.from_user_id,
  text: r.text,
  createdAt: r.created_at,
});

export const notificationJson = (r: Row) => ({
  id: r.id,
  userId: r.user_id,
  type: r.type,
  title: r.title,
  body: r.body,
  data: JSON.parse(r.data || '{}'),
  read: b(r.read),
  createdAt: r.created_at,
});

/** Job con contrapartes (para listas y detalle). */
export function jobWithParties(db: Db, r: Row) {
  const client = db.get('SELECT * FROM users WHERE id = ?', r.client_id);
  return {
    ...jobJson(r),
    client: client ? publicUser(client) : null,
    tech: techCard(db, r.tech_id),
  };
}
