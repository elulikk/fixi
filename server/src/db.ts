import { DatabaseSync } from 'node:sqlite';
import fs from 'node:fs';
import path from 'node:path';

export type Row = Record<string, any>;

/** Envoltorio minimo sobre node:sqlite (sin compilacion nativa). */
export class Db {
  raw: DatabaseSync;
  constructor(file: string) {
    if (file !== ':memory:') fs.mkdirSync(path.dirname(file), { recursive: true });
    this.raw = new DatabaseSync(file);
    this.raw.exec('PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000;');
  }
  private clean(p: any[]) {
    return p.map((v) => (v === undefined ? null : typeof v === 'boolean' ? (v ? 1 : 0) : v));
  }
  all<T = Row>(sql: string, ...params: any[]): T[] {
    return this.raw.prepare(sql).all(...this.clean(params)) as T[];
  }
  get<T = Row>(sql: string, ...params: any[]): T | undefined {
    return this.raw.prepare(sql).get(...this.clean(params)) as T | undefined;
  }
  run(sql: string, ...params: any[]) {
    return this.raw.prepare(sql).run(...this.clean(params));
  }
  tx<T>(fn: () => T): T {
    this.raw.exec('BEGIN');
    try {
      const r = fn();
      this.raw.exec('COMMIT');
      return r;
    } catch (e) {
      this.raw.exec('ROLLBACK');
      throw e;
    }
  }
  close() {
    this.raw.close();
  }
}

/** Migraciones simples e idempotentes. */
export function migrate(db: Db) {
  db.raw.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, phone TEXT, avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'user', is_technician INTEGER NOT NULL DEFAULT 0,
    lat REAL, lng REAL, address TEXT, password_hash TEXT NOT NULL, suspended INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS tech_profiles (
    user_id TEXT PRIMARY KEY REFERENCES users(id), bio TEXT NOT NULL DEFAULT '', category_ids TEXT NOT NULL DEFAULT '[]',
    radius_km REAL NOT NULL DEFAULT 10, available INTEGER NOT NULL DEFAULT 1, verified INTEGER NOT NULL DEFAULT 0,
    rating_avg REAL NOT NULL DEFAULT 0, rating_count INTEGER NOT NULL DEFAULT 0, jobs_done INTEGER NOT NULL DEFAULT 0,
    points INTEGER NOT NULL DEFAULT 0, level TEXT NOT NULL DEFAULT 'bronce', payments_connected INTEGER NOT NULL DEFAULT 0,
    mp_user_id TEXT, mp_access_token TEXT, mp_refresh_token TEXT, mp_expires_at TEXT
  );
  CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY, slug TEXT NOT NULL UNIQUE, name TEXT NOT NULL, icon TEXT NOT NULL, grp TEXT NOT NULL, sort_order INTEGER NOT NULL DEFAULT 0
  );
  CREATE TABLE IF NOT EXISTS requests (
    id TEXT PRIMARY KEY, client_id TEXT NOT NULL REFERENCES users(id), category_id TEXT NOT NULL REFERENCES categories(id),
    title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', photos TEXT NOT NULL DEFAULT '[]',
    lat REAL NOT NULL, lng REAL NOT NULL, address TEXT NOT NULL DEFAULT '', budget_max INTEGER,
    urgency TEXT NOT NULL DEFAULT 'today', scheduled_at TEXT, status TEXT NOT NULL DEFAULT 'open',
    offers_count INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS offers (
    id TEXT PRIMARY KEY, request_id TEXT NOT NULL REFERENCES requests(id), tech_id TEXT NOT NULL REFERENCES users(id),
    price INTEGER NOT NULL, eta_minutes INTEGER NOT NULL, duration_minutes INTEGER NOT NULL, message TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending', created_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS listings (
    id TEXT PRIMARY KEY, tech_id TEXT NOT NULL REFERENCES users(id), category_id TEXT NOT NULL REFERENCES categories(id),
    title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', price INTEGER NOT NULL, price_type TEXT NOT NULL DEFAULT 'fixed',
    duration_minutes INTEGER NOT NULL DEFAULT 60, active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS jobs (
    id TEXT PRIMARY KEY, request_id TEXT, offer_id TEXT, listing_id TEXT,
    client_id TEXT NOT NULL REFERENCES users(id), tech_id TEXT NOT NULL REFERENCES users(id),
    category_id TEXT NOT NULL, title TEXT NOT NULL, address TEXT NOT NULL DEFAULT '', lat REAL, lng REAL,
    price INTEGER NOT NULL, commission INTEGER NOT NULL, tech_net INTEGER NOT NULL, eta_minutes INTEGER NOT NULL DEFAULT 30,
    status TEXT NOT NULL, payment_status TEXT NOT NULL DEFAULT 'pending',
    notes TEXT, scheduled_at TEXT, on_the_way_at TEXT, on_time INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL, paid_at TEXT, started_at TEXT, completed_at TEXT
  );
  CREATE TABLE IF NOT EXISTS payments (
    id TEXT PRIMARY KEY, job_id TEXT NOT NULL REFERENCES jobs(id), provider TEXT NOT NULL, provider_ref TEXT,
    amount INTEGER NOT NULL, commission INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'pending',
    checkout_url TEXT, created_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS reviews (
    id TEXT PRIMARY KEY, job_id TEXT NOT NULL REFERENCES jobs(id), from_user_id TEXT NOT NULL, to_user_id TEXT NOT NULL,
    rating INTEGER NOT NULL, comment TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, UNIQUE(job_id, from_user_id)
  );
  CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY, job_id TEXT NOT NULL REFERENCES jobs(id), from_user_id TEXT NOT NULL, text TEXT NOT NULL, created_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id), type TEXT NOT NULL, title TEXT NOT NULL,
    body TEXT NOT NULL DEFAULT '', data TEXT NOT NULL DEFAULT '{}', read INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_requests_status ON requests(status);
  CREATE INDEX IF NOT EXISTS idx_offers_request ON offers(request_id);
  CREATE INDEX IF NOT EXISTS idx_offers_tech ON offers(tech_id);
  CREATE INDEX IF NOT EXISTS idx_listings_tech ON listings(tech_id);
  CREATE INDEX IF NOT EXISTS idx_jobs_client ON jobs(client_id);
  CREATE INDEX IF NOT EXISTS idx_jobs_tech ON jobs(tech_id);
  CREATE INDEX IF NOT EXISTS idx_messages_job ON messages(job_id);
  CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications(user_id);
  `);
}
