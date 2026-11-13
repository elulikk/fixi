import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { baseRequest, makeApp, makeTech, register, seedCategories } from './helpers.js';

describe('transiciones de estado y permisos', () => {
  let h: Awaited<ReturnType<typeof makeApp>>;
  before(async () => {
    h = await makeApp();
    seedCategories(h.ctx);
  });
  after(async () => h.close());

  async function paidJob() {
    const cli = await register(h.app, 'Cliente', `c${Math.random()}@t.com`);
    const tech = await makeTech(h.app, 'Tecnico', `t${Math.random()}@t.com`);
    const stranger = await register(h.app, 'Extraño', `x${Math.random()}@t.com`);
    const rq = await cli.api.post('/requests', baseRequest);
    const o = await tech.api.post(`/requests/${rq.body.request.id}/offers`, { price: 50000, etaMinutes: 20, durationMinutes: 45, message: '' });
    const job = (await cli.api.post(`/offers/${o.body.offer.id}/accept`)).body.job;
    const pay = await cli.api.post(`/jobs/${job.id}/pay`);
    await h.app.inject({ method: 'POST', url: '/api/v1/payments/webhook/mock', payload: { paymentId: pay.body.payment.id, status: 'approved' } });
    return { cli, tech, stranger, job, pay };
  }

  it('solo el tecnico avanza paid -> on_the_way -> in_progress -> done; solo el cliente confirma', async () => {
    const { cli, tech, stranger, job } = await paidJob();
    const st = (api: any, status: string) => api.post(`/jobs/${job.id}/status`, { status });

    assert.equal((await st(cli.api, 'on_the_way')).status, 403); // cliente no puede
    assert.equal((await st(stranger.api, 'on_the_way')).status, 403); // ajeno
    assert.equal((await st(tech.api, 'done')).status, 409); // salto de estado
    assert.equal((await st(tech.api, 'on_the_way')).status, 200);
    assert.equal((await st(tech.api, 'in_progress')).status, 200);
    assert.equal((await st(tech.api, 'completed')).status, 403); // tecnico no confirma
    assert.equal((await st(cli.api, 'cancelled')).status, 409); // ya no se cancela en curso
    assert.equal((await st(tech.api, 'done')).status, 200);
    assert.equal((await st(cli.api, 'completed')).status, 200);
    assert.equal((await st(cli.api, 'completed')).status, 409);
    assert.equal((await st(tech.api, 'bogus' as any)).status, 400);
    // la reseña de un ajeno no se acepta
    assert.equal((await stranger.api.post(`/jobs/${job.id}/review`, { rating: 5, comment: '' })).status, 403);
  });

  it('cancelar antes de in_progress reembolsa; disputar desde in_progress y resolver como admin', async () => {
    const a = await paidJob();
    const c = await a.cli.api.post(`/jobs/${a.job.id}/status`, { status: 'cancelled' });
    assert.equal(c.status, 200);
    assert.equal(c.body.job.status, 'cancelled');
    assert.equal(c.body.job.paymentStatus, 'refunded');

    const b = await paidJob();
    assert.equal((await b.cli.api.post(`/jobs/${b.job.id}/status`, { status: 'disputed' })).status, 409); // aun en paid
    await b.tech.api.post(`/jobs/${b.job.id}/status`, { status: 'on_the_way' });
    await b.tech.api.post(`/jobs/${b.job.id}/status`, { status: 'in_progress' });
    const d = await b.cli.api.post(`/jobs/${b.job.id}/status`, { status: 'disputed' });
    assert.equal(d.status, 200);

    // resolver: solo admin
    h.ctx.db.run("INSERT INTO users (id, name, email, role, password_hash, created_at) VALUES ('adm','Admin','adm@t.com','admin','x', ?)", new Date().toISOString());
    const token = h.app.jwt.sign({ sub: 'adm', role: 'admin' });
    const inj = (url: string, payload: any, tk: string) =>
      h.app.inject({ method: 'POST', url: `/api/v1${url}`, payload, headers: { authorization: `Bearer ${tk}` } });
    assert.equal((await inj(`/admin/jobs/${b.job.id}/resolve`, { outcome: 'release' }, b.cli.token)).statusCode, 403);
    const res = await inj(`/admin/jobs/${b.job.id}/resolve`, { outcome: 'refund' }, token);
    assert.equal(res.statusCode, 200);
    assert.equal(res.json().job.status, 'cancelled');
    assert.equal(res.json().job.paymentStatus, 'refunded');
  });

  it('el pago rechazado deja el trabajo pendiente y no deja iniciar', async () => {
    const cli = await register(h.app, 'C2', `c${Math.random()}@t.com`);
    const tech = await makeTech(h.app, 'T2', `t${Math.random()}@t.com`);
    const rq = await cli.api.post('/requests', baseRequest);
    const o = await tech.api.post(`/requests/${rq.body.request.id}/offers`, { price: 10000, etaMinutes: 20, durationMinutes: 45, message: '' });
    const job = (await cli.api.post(`/offers/${o.body.offer.id}/accept`)).body.job;
    const pay = await cli.api.post(`/jobs/${job.id}/pay`);
    await h.app.inject({ method: 'POST', url: '/api/v1/payments/webhook/mock', payload: { paymentId: pay.body.payment.id, status: 'rejected' } });
    const j = (await cli.api.get(`/jobs/${job.id}`)).body.job;
    assert.equal(j.status, 'pending_payment');
    assert.equal(j.payment.status, 'failed');
    // y se puede reintentar
    assert.equal((await cli.api.post(`/jobs/${job.id}/pay`)).status, 201);
  });

  it('un cliente no puede ofertar ni un tecnico ver necesidades ajenas cerradas', async () => {
    const cli = await register(h.app, 'C3', `c${Math.random()}@t.com`);
    const rq = await cli.api.post('/requests', baseRequest);
    assert.equal((await cli.api.post(`/requests/${rq.body.request.id}/offers`, { price: 1000, etaMinutes: 5, durationMinutes: 5, message: '' })).status, 403);
    const cancel = await cli.api.post(`/requests/${rq.body.request.id}/cancel`);
    assert.equal(cancel.body.request.status, 'cancelled');
  });
});
