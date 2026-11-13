// Gráfico de área/línea en SVG a mano, responsive y con tooltip.
import { esc, dayLabel } from './ui.js';

const NS = 'http://www.w3.org/2000/svg';

function niceMax(v) {
  if (v <= 0) return 1;
  const p = Math.pow(10, Math.floor(Math.log10(v)));
  const n = v / p;
  return (n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10) * p;
}

/**
 * @param {HTMLElement} el contenedor
 * @param {{date:string,value:number}[]} points
 * @param {{format:(n:number)=>string, axisFormat?:(n:number)=>string, label:string, color?:string, height?:number}} o
 */
export function areaChart(el, points, o) {
  const color = o.color || 'var(--primary)';
  const height = o.height || 260;
  el.classList.add('chart');
  let ro;
  const draw = () => {
    const W = Math.max(280, el.clientWidth);
    const m = { t: 12, r: 12, b: 26, l: 52 };
    const iw = W - m.l - m.r, ih = height - m.t - m.b;
    const max = niceMax(Math.max(0, ...points.map((p) => p.value)));
    const n = points.length;
    const x = (i) => m.l + (n <= 1 ? iw / 2 : (i / (n - 1)) * iw);
    const y = (v) => m.t + ih - (v / max) * ih;
    const ticks = [0, 1, 2, 3, 4].map((i) => (max / 4) * i);
    const line = points.map((p, i) => `${i ? 'L' : 'M'}${x(i).toFixed(1)},${y(p.value).toFixed(1)}`).join(' ');
    const area = n ? `${line} L${x(n - 1).toFixed(1)},${m.t + ih} L${x(0).toFixed(1)},${m.t + ih} Z` : '';
    const gid = 'g' + Math.random().toString(36).slice(2, 7);
    const labelEvery = Math.max(1, Math.ceil(n / Math.max(2, Math.floor(iw / 70))));
    el.innerHTML = `<svg viewBox="0 0 ${W} ${height}" role="img" aria-label="${esc(o.label)}: gráfico de ${n} días">
      <defs><linearGradient id="${gid}" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="${color}" stop-opacity=".28"/><stop offset="1" stop-color="${color}" stop-opacity="0"/></linearGradient></defs>
      ${ticks.map((t) => `<line class="grid-l" x1="${m.l}" x2="${W - m.r}" y1="${y(t)}" y2="${y(t)}"/><text x="${m.l - 8}" y="${y(t) + 4}" text-anchor="end">${esc((o.axisFormat || o.format)(t))}</text>`).join('')}
      ${points.map((p, i) => (i % labelEvery === 0 ? `<text x="${x(i)}" y="${height - 6}" text-anchor="middle">${esc(dayLabel(p.date))}</text>` : '')).join('')}
      ${n ? `<path d="${area}" fill="url(#${gid})"/><path d="${line}" fill="none" stroke="${color}" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>` : ''}
      <line class="cursor" y1="${m.t}" y2="${m.t + ih}" stroke="${color}" stroke-dasharray="3 4" opacity="0"/>
      <circle class="dot" r="5" fill="var(--surface)" stroke="${color}" stroke-width="2.5" opacity="0"/>
      <rect class="hit" x="${m.l}" y="${m.t}" width="${iw}" height="${ih}" fill="transparent" tabindex="0"/>
    </svg><div class="tip" role="status"></div>`;
    const svg = el.querySelector('svg'), tip = el.querySelector('.tip'), cur = svg.querySelector('.cursor'), dot = svg.querySelector('.dot'), hit = svg.querySelector('.hit');
    let idx = n - 1;
    const show = (i) => {
      if (!n) return;
      idx = Math.max(0, Math.min(n - 1, i));
      const p = points[idx], px = x(idx), py = y(p.value);
      cur.setAttribute('x1', px); cur.setAttribute('x2', px); cur.setAttribute('opacity', 1);
      dot.setAttribute('cx', px); dot.setAttribute('cy', py); dot.setAttribute('opacity', 1);
      tip.innerHTML = `<b>${esc(o.format(p.value))}</b>${esc(dayLabel(p.date))}`;
      const scale = el.clientWidth / W;
      tip.style.left = Math.min(Math.max(px * scale, 50), el.clientWidth - 50) + 'px';
      tip.style.top = py * scale + 'px';
      tip.style.opacity = 1;
    };
    const hide = () => { cur.setAttribute('opacity', 0); dot.setAttribute('opacity', 0); tip.style.opacity = 0; };
    hit.addEventListener('pointermove', (e) => {
      const r = svg.getBoundingClientRect();
      const px = ((e.clientX - r.left) / r.width) * W;
      show(Math.round(((px - m.l) / iw) * (n - 1)));
    });
    hit.addEventListener('pointerleave', hide);
    hit.addEventListener('blur', hide);
    hit.addEventListener('focus', () => show(idx));
    hit.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft') { show(idx - 1); e.preventDefault(); }
      if (e.key === 'ArrowRight') { show(idx + 1); e.preventDefault(); }
    });
  };
  draw();
  let lastW = el.clientWidth;
  ro = new ResizeObserver(() => { if (Math.abs(el.clientWidth - lastW) > 4) { lastW = el.clientWidth; draw(); } });
  ro.observe(el);
  return () => ro.disconnect();
}

export const NS_SVG = NS;
