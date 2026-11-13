import { api, items } from '../api.js';
import { esc, icon, pageHead, skeletonRows, skeletonCards, emptyState, errorState, pill, money, dateTime, num, dash, debounce, $ } from '../ui.js';

const FILTERS = [['all', 'Todos'], ['pending', 'Pendientes'], ['approved', 'Aprobados'], ['released', 'Liberados'], ['refunded', 'Reembolsados'], ['failed', 'Fallidos']];
const PAGE = 25;

export default async function payments(root, { signal, refresh }) {
  root.innerHTML = pageHead('Pagos', 'Movimientos, comisiones y estado de cada cobro.') + skeletonCards(3) + skeletonRows(6, 6);
  let list;
  try { list = items(await api('/admin/payments?limit=500', { signal })); }
  catch (e) {
    if (e.name === 'AbortError') return;
    root.innerHTML = pageHead('Pagos', '') + `<div class="card">${errorState(e)}</div>`;
    root.querySelector('[data-retry]').onclick = refresh; return;
  }
  const sum = (arr, k) => arr.reduce((a, p) => a + (Number(p[k]) || 0), 0);
  const ok = list.filter((p) => ['approved', 'released'].includes(p.status));
  const st = { q: '', f: 'all', page: 0 };
  const kpi = (ic, l, v, cls = '') => `<div class="card kpi ${cls}"><div class="ico">${icon(ic)}</div><div class="v">${v}</div><div class="l">${l}</div></div>`;
  root.innerHTML = pageHead('Pagos', `${num(list.length)} pagos registrados.`)
    + `<div class="grid kpis">${kpi('pay', 'Cobrado (aprobado + liberado)', money(sum(ok, 'amount')), 'green')}${kpi('coin', 'Comisión de esos pagos', money(sum(ok, 'commission')), 'lime')}${kpi('refresh', 'Reembolsado', money(sum(list.filter((p) => p.status === 'refunded'), 'amount')))}</div>
    <div class="toolbar"><div class="search">${icon('search')}<input class="input" type="search" data-search placeholder="Buscar por ID, trabajo o referencia  ( / )" aria-label="Buscar pagos"></div><div class="chips" data-chips role="group" aria-label="Filtrar por estado"></div></div><div class="card flush" data-box></div>`;
  const box = $('[data-box]', root), chips = $('[data-chips]', root);
  const sorted = list.slice().sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
  function view() {
    const q = st.q.toLowerCase();
    const rows = sorted.filter((p) => (st.f === 'all' || p.status === st.f) && (!q || [p.id, p.jobId, p.providerRef, p.provider].some((x) => String(x || '').toLowerCase().includes(q))));
    chips.innerHTML = FILTERS.map(([k, l]) => `<button class="chip" data-f="${k}" aria-pressed="${st.f === k}">${l} <span class="n">${k === 'all' ? list.length : list.filter((p) => p.status === k).length}</span></button>`).join('');
    const pages = Math.max(1, Math.ceil(rows.length / PAGE)); st.page = Math.min(st.page, pages - 1);
    const slice = rows.slice(st.page * PAGE, (st.page + 1) * PAGE);
    if (!rows.length) { box.innerHTML = emptyState('No hay pagos para mostrar', list.length ? 'Probá con otro filtro.' : 'Cuando un cliente pague un trabajo, lo vas a ver acá.', 'pay'); return; }
    box.innerHTML = `<div class="table-wrap"><table><thead><tr><th>Pago</th><th>Trabajo</th><th>Proveedor</th><th class="right">Monto</th><th class="right">Comisión</th><th class="right">Neto técnico</th><th>Estado</th><th>Fecha</th></tr></thead><tbody>${slice.map((p) => {
      const net = p.amount != null && p.commission != null ? Number(p.amount) - Number(p.commission) : undefined;
      return `<tr><td><span class="id">${esc(String(p.id || dash).slice(0, 12))}</span></td><td><span class="id">${esc(String(p.jobId || dash).slice(0, 12))}</span>${p.jobTitle ? `<div class="small">${esc(p.jobTitle)}</div>` : ''}</td><td>${esc(p.provider === 'mercadopago' ? 'Mercado Pago' : p.provider === 'mock' ? 'Simulado' : p.provider || dash)}</td><td class="num right"><b>${money(p.amount)}</b></td><td class="num right">${money(p.commission)}</td><td class="num right">${money(net)}</td><td>${pill(p.status)}</td><td class="muted small">${esc(dateTime(p.createdAt))}</td></tr>`;
    }).join('')}</tbody></table></div><div class="pager"><span class="muted small">${st.page * PAGE + 1}–${st.page * PAGE + slice.length} de ${rows.length}</span><div class="actions"><button class="btn sm" data-p="-1" ${st.page === 0 ? 'disabled' : ''}>Anterior</button><button class="btn sm" data-p="1" ${st.page >= pages - 1 ? 'disabled' : ''}>Siguiente</button></div></div>`;
  }
  view();
  root.addEventListener('click', (e) => {
    const c = e.target.closest('[data-f]'); if (c) { st.f = c.dataset.f; st.page = 0; view(); }
    const p = e.target.closest('[data-p]'); if (p) { st.page += Number(p.dataset.p); view(); }
  });
  $('[data-search]', root).addEventListener('input', debounce((e) => { st.q = e.target.value; st.page = 0; view(); }));
}
