/**
 * Score "Mejor opcion" (0-100): 35*precio + 30*reputacion + 20*cercania + 15*tiempo.
 * Se normaliza dentro del conjunto devuelto (min-max). Reputacion bayesiana (prior 4.0, peso 5).
 */
export interface ScoreInput {
  key: string;
  price: number;
  distanceKm: number | null;
  etaMinutes: number | null;
  ratingAvg: number;
  ratingCount: number;
}
export type Badge = 'best' | 'cheapest' | 'closest' | 'fastest' | 'top_rated';
export interface ScoreResult {
  score: number;
  badge: Badge | null;
  badges: Badge[];
}

export const PRIOR_RATING = 4.0;
export const PRIOR_WEIGHT = 5;

export function bayesRating(avg: number, count: number): number {
  return (avg * count + PRIOR_RATING * PRIOR_WEIGHT) / (count + PRIOR_WEIGHT);
}

/** 1 = mejor, 0 = peor. Si no hay variacion o faltan datos, devuelve neutro/1. */
function normalize(values: (number | null)[], lowerIsBetter: boolean): number[] {
  const nums = values.filter((v): v is number => v !== null);
  if (nums.length === 0) return values.map(() => 1);
  const min = Math.min(...nums);
  const max = Math.max(...nums);
  return values.map((v) => {
    if (v === null) return 0.5;
    if (max === min) return 1;
    const x = (v - min) / (max - min);
    return lowerIsBetter ? 1 - x : x;
  });
}

export function scoreItems(items: ScoreInput[]): Map<string, ScoreResult> {
  const out = new Map<string, ScoreResult>();
  if (items.length === 0) return out;
  const nPrice = normalize(items.map((i) => i.price), true);
  const nDist = normalize(items.map((i) => i.distanceKm), true);
  const nEta = normalize(items.map((i) => i.etaMinutes), true);
  const rep = items.map((i) => bayesRating(i.ratingAvg, i.ratingCount));
  const nRep = rep.map((r) => r / 5);

  const scores = items.map((_, i) =>
    Math.round(100 * (0.35 * nPrice[i] + 0.3 * nRep[i] + 0.2 * nDist[i] + 0.15 * nEta[i]) * 10) / 10,
  );
  items.forEach((it, i) => out.set(it.key, { score: scores[i], badge: null, badges: [] }));
  if (items.length < 2) return out;

  const mark = (badge: Badge, idx: number) => {
    const r = out.get(items[idx].key)!;
    r.badges.push(badge);
  };
  const argBest = (vals: (number | null)[], lower: boolean): number | -1 => {
    let best = -1;
    let bestV = 0;
    vals.forEach((v, i) => {
      if (v === null) return;
      if (best === -1 || (lower ? v < bestV : v > bestV)) {
        best = i;
        bestV = v;
      }
    });
    if (best === -1) return -1;
    const allEqual = vals.every((v) => v === bestV);
    return allEqual ? -1 : best;
  };
  const bi = argBest(scores, false);
  mark('best', bi === -1 ? 0 : bi);
  const c = argBest(items.map((i) => i.price), true);
  if (c !== -1) mark('cheapest', c);
  const d = argBest(items.map((i) => i.distanceKm), true);
  if (d !== -1) mark('closest', d);
  const f = argBest(items.map((i) => i.etaMinutes), true);
  if (f !== -1) mark('fastest', f);
  const t = argBest(rep, false);
  if (t !== -1) mark('top_rated', t);

  for (const r of out.values()) r.badge = r.badges[0] ?? null;
  return out;
}

export type SortKey = 'best' | 'price' | 'distance' | 'eta' | 'rating';

export function sortItems<T extends { score: number; price: number; distanceKm: number | null; etaMinutes: number | null; tech: { ratingAvg: number; ratingCount: number } }>(
  items: T[],
  sort: SortKey,
): T[] {
  const nullLast = (a: number | null, b: number | null) => (a ?? Infinity) - (b ?? Infinity);
  const arr = [...items];
  switch (sort) {
    case 'price':
      return arr.sort((a, b) => a.price - b.price || b.score - a.score);
    case 'distance':
      return arr.sort((a, b) => nullLast(a.distanceKm, b.distanceKm) || b.score - a.score);
    case 'eta':
      return arr.sort((a, b) => nullLast(a.etaMinutes, b.etaMinutes) || b.score - a.score);
    case 'rating':
      return arr.sort(
        (a, b) =>
          bayesRating(b.tech.ratingAvg, b.tech.ratingCount) - bayesRating(a.tech.ratingAvg, a.tech.ratingCount) || b.score - a.score,
      );
    default:
      return arr.sort((a, b) => b.score - a.score);
  }
}
