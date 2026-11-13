import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { baseRequest, client, makeApp, makeTech, register, seedCategories } from './helpers.js';

describe('flujo feliz end-to-end', () => {
  let h: Awaited<ReturnType<typeof makeApp>>;
  before(async () => {
    h = await makeApp();
    seedCategories(h.ctx);
  });
  after(async () => h.close());

  it('registro -> necesidad -> oferta -> pago mock -> trabajo -> reseña -> puntos y ganancias', async () => {
    const { app } = h;
    const cli = await register(app, 'Cliente Test', 'cliente@test.com');
    const tech = await makeTech(app, 'Técnico Test', 'tec@test.com', -34.61, -58.4);
    const tech2 = await makeTech(app, 'Técnico Barato', 'tec2@test.com', -34.65, -58.45);

    // errores uniformes
    const bad = await client(app).post('/auth/login', { email: 'cliente@test.com', password: 'mala' });
    assert.equal(bad.status, 401);
    assert.equal(bad.body.error.code, 'INVALID_CREDENTIALS');
    assert.equal((await client(app).get('/me')).status, 401);

    // /me
    const me = await tech.api.get('/me');
    assert.equal(me.body.user.isTechnician, true);
    assert.equal(me.body.techProfile.level, 'bronce');
    assert.equal(me.body.techProfile.points, 0);

    // necesidad
    const rq = await cli.api.post('/requests', baseRequest);
    assert.equal(rq.status, 201);
    const requestId = rq.body.request.id;

    // el tecnico la ve cerca
    const nearby = await tech.api.get('/requests/nearby?lat=-34.61&lng=-58.4&radiusKm=10');
    assert.equal(nearby.body.items.length, 1);
    assert.ok(nearby.body.items[0].distanceKm > 0);

    // ofertas
    const o1 = await tech.api.post(`/requests/${requestId}/offers`, { price: 100000, etaMinutes: 30, durationMinutes: 60, message: 'Voy' });
    assert.equal(o1.status, 201);
    const dup = await tech.api.post(`/requests/${requestId}/offers`, { price: 90000, etaMinutes: 30, durationMinutes: 60, message: '' });
    assert.equal(dup.status, 409);
    await tech2.api.post(`/requests/${requestId}/offers`, { price: 120000, etaMinutes: 90, durationMinutes: 60, message: 'También' });

    const detail = await cli.api.get(`/requests/${requestId}`);
    assert.equal(detail.body.request.offers.length, 2);
    assert.equal(detail.body.request.offersCount, 2);
    const first = detail.body.request.offers[0];
    assert.ok(first.score >= 0 && first.score <= 100);
    assert.ok(first.tech.name);
    assert.equal(first.badge, 'best');

    // un tecnico no puede aceptar ofertas
    assert.equal((await tech.api.post(`/offers/${o1.body.offer.id}/accept`)).status, 403);

    // aceptar
    const acc = await cli.api.post(`/offers/${o1.body.offer.id}/accept`);
    assert.equal(acc.status, 201);
    const job = acc.body.job;
    assert.equal(job.status, 'pending_payment');
    assert.equal(job.price, 100000);
    assert.equal(job.commission, 5000);
    assert.equal(job.techNet, 95000);

    // no se puede arrancar sin pagar
    const early = await tech.api.post(`/jobs/${job.id}/status`, { status: 'on_the_way' });
    assert.equal(early.status, 409);

    // pagar (mock)
    const pay = await cli.api.post(`/jobs/${job.id}/pay`);
    assert.equal(pay.status, 201);
    assert.match(pay.body.checkoutUrl, /\/pay\/mock\//);
    const page = await app.inject({ method: 'GET', url: `/pay/mock/${pay.body.payment.id}` });
    assert.equal(page.statusCode, 200);
    assert.match(page.body, /Aprobar pago/);
    assert.match(page.body, /2F5BFF/i);

    const hook = await app.inject({ method: 'POST', url: '/api/v1/payments/webhook/mock', payload: { paymentId: pay.body.payment.id, status: 'approved' } });
    assert.equal(hook.statusCode, 200);
    let j = (await cli.api.get(`/jobs/${job.id}`)).body.job;
    assert.equal(j.status, 'paid');
    assert.equal(j.paymentStatus, 'held');
    assert.equal(j.payment.status, 'approved');

    // pendiente en ganancias del tecnico
    let earn = (await tech.api.get('/me/earnings')).body;
    assert.equal(earn.pendingNet, 95000);
    assert.equal(earn.totalNet, 0);

    // estados
    for (const st of ['on_the_way', 'in_progress', 'done']) {
      const r = await tech.api.post(`/jobs/${job.id}/status`, { status: st });
      assert.equal(r.status, 200, st);
      assert.equal(r.body.job.status, st);
    }
    const done = await cli.api.post(`/jobs/${job.id}/status`, { status: 'completed' });
    assert.equal(done.status, 200);
    assert.equal(done.body.job.paymentStatus, 'released');

    // chat
    const m = await cli.api.post(`/jobs/${job.id}/messages`, { text: 'Gracias!' });
    assert.equal(m.status, 201);
    assert.equal((await tech.api.get(`/jobs/${job.id}/messages`)).body.items.length, 1);

    // reseña 5 estrellas -> +20 trabajo +5 en horario +20 reseña = 45
    const rev = await cli.api.post(`/jobs/${job.id}/review`, { rating: 5, comment: 'Excelente' });
    assert.equal(rev.status, 201);
    assert.equal((await cli.api.post(`/jobs/${job.id}/review`, { rating: 5, comment: '' })).status, 409);
    const prof = (await tech.api.get('/me')).body.techProfile;
    assert.equal(prof.points, 45);
    assert.equal(prof.jobsDone, 1);
    assert.equal(prof.ratingAvg, 5);
    assert.equal(prof.ratingCount, 1);
    assert.equal(prof.level, 'bronce');

    // ganancias
    earn = (await tech.api.get('/me/earnings')).body;
    assert.equal(earn.totalNet, 95000);
    assert.equal(earn.pendingNet, 0);
    assert.equal(earn.commissionPaid, 5000);
    assert.equal(earn.jobs.length, 1);

    // notificaciones generadas
    const types = (await tech.api.get('/notifications')).body.items.map((n: any) => n.type);
    for (const t of ['offer.accepted', 'payment.approved', 'job.status', 'review.new', 'message.new']) assert.ok(types.includes(t), `falta ${t}`);
    const cn = (await cli.api.get('/notifications')).body.items.map((n: any) => n.type);
    assert.ok(cn.includes('offer.new') && cn.includes('payment.approved'));
    assert.equal((await cli.api.post('/notifications/read-all')).body.ok, true);
    assert.equal((await cli.api.get('/notifications')).body.unreadCount, 0);

    // perfil publico
    const pub = await client(app).get(`/techs/${tech.user.id}`);
    assert.equal(pub.body.reviews.length, 1);
    assert.equal(pub.body.tech.points, 45);
  });

  it('servicios publicados: listado cercano, reserva y comision', async () => {
    const { app } = h;
    const tech = await makeTech(app, 'Pub Tech', 'pub@test.com', -34.6, -58.38);
    const l = await tech.api.post('/listings', { categoryId: 'c_pc-notebooks', title: 'Formateo', description: 'x', price: 30000, priceType: 'fixed', durationMinutes: 60 });
    assert.equal(l.status, 201);
    const list = await client(app).get('/listings?lat=-34.6037&lng=-58.3816&radiusKm=20');
    const mine = list.body.items.find((i: any) => i.id === l.body.listing.id);
    assert.ok(mine);
    assert.ok(mine.distanceKm < 3);
    assert.equal(mine.etaMinutes, Math.round(10 + mine.distanceKm * 3));
    const far = await client(app).get('/listings?lat=-31.4&lng=-64.18&radiusKm=20');
    assert.equal(far.body.items.length, 0);

    const cli = await register(app, 'Reservador', 'reserva@test.com');
    const b = await cli.api.post(`/listings/${l.body.listing.id}/book`, { address: 'Corrientes 1234', lat: -34.6037, lng: -58.3816 });
    assert.equal(b.status, 201);
    assert.equal(b.body.job.commission, 1500);
    assert.equal(b.body.job.techNet, 28500);
  });
});
