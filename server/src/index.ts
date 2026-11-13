import os from 'node:os';
import { buildApp } from './app.js';

try {
  process.loadEnvFile('.env');
} catch {
  /* sin .env: se usan los defaults */
}

const { app, ctx } = await buildApp({ logger: true });
try {
  await app.listen({ port: ctx.cfg.port, host: ctx.cfg.host });
} catch (e) {
  app.log.error(e);
  process.exit(1);
}

const ips = Object.values(os.networkInterfaces())
  .flat()
  .filter((i) => i && i.family === 'IPv4' && !i.internal)
  .map((i) => i!.address);
console.log('\n  Fixi server listo');
console.log(`  Local:  http://localhost:${ctx.cfg.port}`);
for (const ip of ips) console.log(`  Red:    http://${ip}:${ctx.cfg.port}   <- usá esta en el celular`);
console.log(`  Pagos:  ${ctx.cfg.paymentProvider} · comisión ${ctx.cfg.commissionPercent}%\n`);

const stop = async () => {
  await app.close();
  process.exit(0);
};
process.on('SIGINT', stop);
process.on('SIGTERM', stop);
