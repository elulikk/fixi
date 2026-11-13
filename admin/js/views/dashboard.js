import { api, items } from '../api.js';
import { esc, icon, num, money, compactMoney, pageHead, skeletonCards, errorState, emptyState, pill, ago, statusLabel, dash } from '../ui.js';
import { areaChart } from '../charts.js';

const METRICS = {
  gmv: { label: 'Volumen (GMV)', format: money, axisFormat: compactMoney, color: 'var(--primary)' },
  commission: { label: 'Comisión', format: money, axisFormat: compactMoney, color: 'var(--success)' },
  jobs: { label: 'Trabajos', format: (n) => num(n), axisFormat: (n) => num(Math.round(n)), color: '#7A5AF8' },
};
const STATUS_ORDER = ['pending_payment', 'paid', 'on_the_way', 'in_progress', 'done', 'completed', 'disputed', 'cancelled'];

const sum = (arr, k) => arr.reduce((a, d) => a + (Number(d?.[k]) || 0), 0);

export default async function dashboard(root, { signal, refresh }) {
  root.innerHTML = pageHead('Resumen', 'Cómo viene Fixi hoy.', `<button class="btn" data-reload>${icon('refresh')} Actualizar</button>`) + skeletonCards(4)
    + '<div class="card"><span class="skel" style="width:30%;height:20px"></span><span class="skel" style="height:220px;margin-top:16px"></span></div>';
  root.querySelector('[data-reload]').onclick = refresh;

  let stats, recentJobs = [];
  try {
    stats = await api('/admin/stats', { signal });
    if (!Array.isArray(stats?.recent) && !Array.isArray(stats?.activity)) {
      try { recentJobs = items(await api('/admin/jobs?limit=8', { signal })); } catch (e) { if (e.name === 'AbortError') throw e; }
    }
  } catch (e) {
    if (e.name === 'AbortError') return;
    root.innerHTML = pageHead('Resumen', '') + `<div class="card">${errorState(e)}</div>`;
    root.querySelector('[data-retry]').onclick = refresh;
    return;
  }
  stats = stats || {};
  const by = stats.jobsByStatus || {};
  const daily = (Array.isArray(stats.daily) ? stats.daily : Array.isArray(stats.series) ? stats.series : []).map((d) => ({ date: d.date, gmv: Number(d.gmv) || 0, commission: Number(d.commission) || 0, jobs: Number(d.jobs) || 0 }));
  const totalJobs = Object.values(by).reduce((a, n) => a + (Number(n) || 0), 0);
  const gmv = stats.gmv ?? (daily.length ? sum(daily, 'gmv') : undefined);
  const commission = stats.commission ?? stats.commissionEarned ?? (daily.length ? sum(daily, 'commission') : undefined);
  const active = ['paid', 'on_the_way', 'in_progress', 'done'].reduce((a, s) => a + (Number(by[s]) || 0), 0);

  const kpi = (ic, label, value, cls = '', sub = '') => `<div class="card kpi ${cls}"><div class="ico">${icon(ic)}</div><div class="v">${value}</div><div class="l">${esc(label)}${sub ? ` · ${sub}` : ''}</div></div>`;
  const activity = (stats.recent || stats.activity || []).slice(0, 8);
  const feed = activity.length
    ? activity.map((a) => ({ title: a.title || a.message || a.type || 'Actividad', sub: a.subtitle || a.detail || '', at: a.createdAt || a.at, status: a.status }))
    : recentJobs.map((j) => ({ title: j.title || 'Trabajo', sub: `${money(j.price)} · ${statusLabel(j.status)}`, at: j.createdAt, status: j.status }));

  const maxStatus = Math.max(1, ...STATUS_ORDER.map((s) => Number(by[s]) || 0));
  const extra = Object.keys(by).filter((s) => !STATUS_ORDER.includes(s));

  root.innerHTML = pageHead('Resumen', 'Cómo viene Fixi hoy.', `<button class="btn" data-reload>${icon('refresh')} Actualizar</button>`)
    + `<div class="grid kpis">
      ${kpi('users', 'Usuarios', num(stats.users))}
      ${kpi('wrench', 'Técnicos', num(stats.technicians))}
      ${kpi('jobs', 'Trabajos', num(totalJobs || undefined), '', `${num(active)} activos`)}
      ${kpi('chart', 'Volumen (GMV)', money(gmv), 'green')}
      ${kpi('coin', 'Comisión ganada', money(commission), 'lime')}
    </div>
    <div class="grid two">
      <section class="card" aria-labelledby="ch-t">
        <div class="card-head"><h2 id="ch-t">Últimos 30 días</h2>
          <div class="chips" role="group" aria-label="Métrica">${Object.entries(METRICS).map(([k, m], i) => `<button class="chip" data-m="${k}" aria-pressed="${i === 0}">${esc(m.label)}</button>`).join('')}</div></div>
        <div id="chart">${daily.length ? '' : emptyState('Todavía no hay movimientos', 'Cuando se contraten trabajos vas a ver la evolución diaria acá.', 'chart')}</div>
      </section>
      <section class="card" aria-labelledby="st-t">
        <div class="card-head"><h2 id="st-t">Trabajos por estado</h2></div>
        ${totalJobs || extra.length ? `<div class="bars">${[...STATUS_ORDER, ...extra].filter((s) => by[s] !== undefined || STATUS_ORDER.includes(s)).map((s) => `<div class="bar-row"><span>${esc(statusLabel(s))}</span><div class="track"><div class="fill" style="width:${((Number(by[s]) || 0) / maxStatus) * 100}%;${s === 'disputed' ? 'background:var(--error)' : s === 'completed' ? 'background:var(--success)' : s === 'cancelled' ? 'background:var(--muted)' : ''}"></div></div><b class="num right">${num(by[s] ?? 0)}</b></div>`).join('')}</div>` : emptyState('Sin trabajos todavía', 'Los estados van a aparecer a medida que los clientes contraten.', 'jobs')}
      </section>
    </div>
    <section class="card" style="margin-top:16px" aria-labelledby="ac-t">
      <div class="card-head"><h2 id="ac-t">Actividad reciente</h2><a class="btn sm" href="#/jobs">Ver trabajos</a></div>
      ${feed.length ? `<ul class="feed">${feed.map((f) => `<li><div class="fi">${icon('jobs')}</div><div class="t"><b>${esc(f.title)}</b><span class="muted small">${esc(f.sub || dash)}</span></div>${f.status ? pill(f.status) : ''}<span class="muted small" style="white-space:nowrap">${esc(ago(f.at))}</span></li>`).join('')}</ul>` : emptyState('Nada por ahora', 'Acá vas a ver los últimos trabajos y movimientos.', 'inbox')}
    </section>`;
  root.querySelector('[data-reload]').onclick = refresh;

  const chartEl = root.querySelector('#chart');
  if (daily.length) {
    let stop;
    const paint = (k) => { stop?.(); const m = METRICS[k]; stop = areaChart(chartEl, daily.map((d) => ({ date: d.date, value: d[k] })), m); };
    paint('gmv');
    root.querySelectorAll('[data-m]').forEach((b) => (b.onclick = () => {
      root.querySelectorAll('[data-m]').forEach((x) => x.setAttribute('aria-pressed', x === b));
      paint(b.dataset.m);
    }));
  } else root.querySelector('.chips').hidden = true;
}
