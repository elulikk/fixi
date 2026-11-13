import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { bayesRating, scoreItems, sortItems } from '../src/score.js';
import { haversineKm, levelFor } from '../src/util.js';

const item = (key: string, price: number, distanceKm: number | null, etaMinutes: number, ratingAvg: number, ratingCount: number) => ({
  key, price, distanceKm, etaMinutes, ratingAvg, ratingCount,
});

describe('score Mejor opción', () => {
  it('rating bayesiano (prior 4.0, peso 5)', () => {
    assert.equal(bayesRating(0, 0), 4);
    assert.equal(bayesRating(5, 5), 4.5);
    assert.ok(bayesRating(5, 1) < bayesRating(5, 50));
  });

  it('el mejor conjunto gana 100 y el peor 0 en cada dimensión', () => {
    const r = scoreItems([item('a', 100, 1, 10, 5, 1000), item('b', 200, 10, 60, 5, 1000)]);
    const a = r.get('a')!, b = r.get('b')!;
    // a: 35+ (30*~0.999) +20+15 ~ 100 ; b: 30*~0.999 ~ 30
    assert.ok(a.score > 99 && a.score <= 100);
    assert.ok(b.score > 29 && b.score < 31);
    assert.ok(a.badges.includes('best'));
    assert.ok(a.badges.includes('cheapest') && a.badges.includes('closest') && a.badges.includes('fastest'));
    assert.equal(a.badge, 'best');
    assert.equal(b.badge, null);
  });

  it('pondera 35/30/20/15 y marca badges distintos', () => {
    const r = scoreItems([
      item('barato', 50, 8, 60, 4.0, 5), // mas barato
      item('cerca', 100, 1, 50, 4.0, 5), // mas cerca
      item('rapido', 100, 5, 10, 4.0, 5), // mas rapido
      item('top', 100, 5, 50, 5.0, 200), // mejor reputacion
    ]);
    assert.ok(r.get('barato')!.badges.includes('cheapest'));
    assert.ok(r.get('cerca')!.badges.includes('closest'));
    assert.ok(r.get('rapido')!.badges.includes('fastest'));
    assert.ok(r.get('top')!.badges.includes('top_rated'));
    const bests = [...r.values()].filter((x) => x.badges.includes('best'));
    assert.equal(bests.length, 1);
    // El precio pesa mas que cualquier otra dimension: el barato queda por encima del que solo es rapido.
    assert.ok(r.get('barato')!.score > r.get('rapido')!.score);
  });

  it('un solo elemento no lleva badges; sin distancia no rompe', () => {
    const r = scoreItems([item('x', 100, null, 30, 4.5, 10)]);
    assert.deepEqual(r.get('x')!.badges, []);
    const r2 = scoreItems([item('x', 100, null, 30, 4.5, 10), item('y', 120, null, 40, 4.5, 10)]);
    assert.ok(r2.get('x')!.score > r2.get('y')!.score);
  });

  it('ordena por sort', () => {
    const base = [
      item('a', 300, 1, 40, 5, 100), item('b', 100, 9, 80, 3, 100), item('c', 200, 5, 10, 4, 100),
    ];
    const sc = scoreItems(base);
    const rows = base.map((b) => ({
      id: b.key, price: b.price, distanceKm: b.distanceKm, etaMinutes: b.etaMinutes, score: sc.get(b.key)!.score,
      tech: { ratingAvg: b.ratingAvg, ratingCount: b.ratingCount },
    }));
    const ids = (s: any) => sortItems(rows, s).map((r) => r.id).join('');
    assert.equal(ids('price'), 'bca');
    assert.equal(ids('distance'), 'acb');
    assert.equal(ids('eta'), 'cab');
    assert.equal(ids('rating'), 'acb');
    assert.equal(ids('best').length, 3);
  });
});

describe('utilidades', () => {
  it('haversine Obelisco - Plaza de Mayo ~ 1.5 km', () => {
    const d = haversineKm(-34.6037, -58.3816, -34.6083, -58.3712);
    assert.ok(d > 0.9 && d < 1.5, String(d));
  });
  it('niveles por puntos', () => {
    assert.equal(levelFor(0), 'bronce');
    assert.equal(levelFor(199), 'bronce');
    assert.equal(levelFor(200), 'plata');
    assert.equal(levelFor(600), 'oro');
    assert.equal(levelFor(1500), 'platino');
  });
});
