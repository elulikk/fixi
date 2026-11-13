import fs from 'node:fs';
import { loadConfig } from './config.js';
import { Db, migrate } from './db.js';
import { seedDatabase } from './seed.js';

try {
  process.loadEnvFile('.env');
} catch {
  /* sin .env */
}

const cfg = loadConfig();
const reset = process.argv.includes('--reset');
if (reset) {
  for (const suffix of ['', '-wal', '-shm']) fs.rmSync(cfg.dbPath + suffix, { force: true });
}
const db = new Db(cfg.dbPath);
migrate(db);
if ((db.get('SELECT COUNT(*) n FROM users') as any).n > 0) {
  console.log('La base ya tiene datos. Usá "npm run seed -- --reset" para recrearla desde cero.');
} else {
  seedDatabase(db, cfg);
  console.log('Seed listo en', cfg.dbPath);
}
db.close();
