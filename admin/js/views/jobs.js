import { api, items } from '../api.js';
import { esc, icon, pageHead, skeletonRows, emptyState, errorState, pill, money, dateTime, dateFull, num, dash, toast, confirmDialog, modal, debounce, tone, $ } from '../ui.js';

const PAGE = 25;
const STEPS = [['paid', 'Pagado', 'paidAt'], ['on_the_way', 'En camino', null], ['in_progress', 'En trabajo', 'startedAt'], ['done', 'Terminado', null], ['completed', 'Confirmado', 'completedAt']];
const ORDER = ['pending_payment', 'paid', 'on_the_way', 'in_progress', 'done', 'completed'];
const FILTERS = [['all', 'Todos'], ['disputed', 'En disputa'], ['pending_payment', 'Pago pendiente'], ['paid', 'Pagados'], ['on_the_way', 'En camino'], ['in_progress', 'En trabajo'], ['done', 'Terminados'], ['completed', 'Completados'], ['cancelled', 'Cancelados']];

const clientName = (j) => j.clientName ?? j.client?.name;
const techName = (j) => j.techName ?? j.tech?.name;

function timeline(j) {
  const idx = ORDER.indexOf(j.status);
  const steps = STEPS.map(([s, label, at]) => {
    const i = ORDER.indexOf(s);
    const cls = idx > i || (j.status === 'completed' && s === 'completed') ? 'done' : idx === i ? 'now' : 'todo';
    return `<li class="${cls}"><span class="dot">${cls === 'done' ? icon('check') : ''}</span><div><b>${label}</b>${at && j[at] ? `<div class="muted small">${esc(dateTime(j[at]))}</div>` : ''}</div></li>`;
  });
  if (j.status === 'cancelled') steps.push('<li class="bad"><span class="dot">' + icon('x') + '</span><div><b>Cancelado</b></div></li>');
  if (j.status === 'disputed') steps.push('<li class="bad"><span class="dot">' + icon('alert') + '</span><div><b>En disputa</b><div class="muted small">Esperando tu resolución</div></div></li>');
  return `<ol class="timeline">${steps.join('')}</ol>`;
}

export default async function jobs(root, { signal, refresh }) {
  root.innerHTML = pageHead('Trabajos', 'Seguimiento de trabajos y resolución de disputas.') + skeletonRows(8, 6);
  let list;
  try { list = items(await api('/admin/jobs?limit=500', { signal })); }
  catch (e) {
    if (e.name === 'AbortError') return;
    root.innerHTML = pageHead('Trabajos', '') + `<div class="card">${errorState(e)}</div>`;
    root.querySelector('[data-retry]').onclick = refresh; return;
  }
  const st = { q: '', f: (location.hash.match(/status=(\w+)/) || [])[1] || 'all', page: 0 };
  root.innerHTML = pageHead('Trabajos', `${num(list.length)} trabajos en total.`)
    + `<div class="toolbar"><div class="search">${icon('search')}<input class="input" type="search" data-search placeholder="Buscar por título, cliente o técnico  ( / )" aria-label="Buscar trabajos"></div><div class="chips" data-chips role="group" aria-label="Filtrar por estado"></div></div><div class="card flush" data-box></div>`;
  const box = $('[data-box]', root), chipsEl = $('[data-chips]', root);
  const sorted = list.slice().sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));

  function view() {
    const q = st.q.toLowerCase();
    const rows = sorted.filter((j) => (st.f === 'all' || j.status === st.f) && (!q || [j.title, j.address, clientName(j), techName(j), j.id].some((x) => String(x || '').toLowerCase().includes(q))));
    chipsEl.innerHTML = FILTERS.map(([k, l]) => `<button class="chip" data-f="${k}" aria-pressed="${st.f === k}">${l} <span class="n">${k === 'all' ? list.length : list.filter((j) => j.status === k).length}</span></button>`).join('');
    const pages = Math.max(1, Math.ceil(rows.length / PAGE));
    st.page = Math.min(st.page, pages - 1);
    const slice = rows.slice(st.page * PAGE, (st.page + 1) * PAGE);
    if (!rows.length) { box.innerHTML = emptyState('No hay trabajos con ese filtro', 'Probá con otro estado o cambiá la búsqueda.', 'jobs'); return; }
    box.innerHTML = `<div class="table-wrap"><table><thead><tr><th>Trabajo</th><th>Cliente</th><th>Técnico</th><th class="right">Precio</th><th>Estado</th><th>Pago</th><th>Creado</th></tr></thead><tbody>${slice.map((j) => `<tr class="click" tabindex="0" data-id="${esc(j.id)}"><td><b>${esc(j.title || dash)}</b><div class="muted small">${esc(j.address || '')}</div></td><td>${esc(clientName(j) || dash)}</td><td>${esc(techName(j) || dash)}</td><td class="num right">${money(j.price)}</td><td>${pill(j.status)}</td><td>${j.paymentStatus ? pill(j.paymentStatus) : dash}</td><td class="muted small">${esc(dateTime(j.createdAt))}</td></tr>`).join('')}</tbody></table></div>
    <div class="pager"><span class="muted small">${st.page * PAGE + 1}–${st.page * PAGE + slice.length} de ${rows.length}</span><div class="actions"><button class="btn sm" data-p="-1" ${st.page === 0 ? 'disabled' : ''}>Anterior</button><button class="btn sm" data-p="1" ${st.page >= pages - 1 ? 'disabled' : ''}>Siguiente</button></div></div>`;
  }
  view();

  function detail(j) {
    const dis = j.status === 'disputed';
    const d = modal(`<div class="dlg-body"><div style="display:flex;justify-content:space-between;gap:12px;align-items:flex-start"><div><h2>${esc(j.title || 'Trabajo')}</h2><span class="id">${esc(j.id)}</span></div>${pill(j.status)}</div>
      ${dis ? `<div class="card" style="background:var(--error-bg);border-color:transparent;color:var(--error-text);display:flex;gap:10px">${icon('alert')}<div><b>Este trabajo está en disputa.</b><div class="small">Decidí si se libera el pago al técnico o se reembolsa al cliente. No se puede deshacer.</div></div></div>` : ''}
      <dl class="dl"><dt>Cliente</dt><dd>${esc(clientName(j) || dash)}</dd><dt>Técnico</dt><dd>${esc(techName(j) || dash)}</dd><dt>Dirección</dt><dd>${esc(j.address || dash)}</dd>
      <dt>Precio</dt><dd class="num"><b>${money(j.price)}</b></dd><dt>Comisión Fixi</dt><dd class="num">${money(j.commission)}</dd><dt>Neto técnico</dt><dd class="num">${money(j.techNet)}</dd>
      <dt>Pago</dt><dd>${j.paymentStatus ? pill(j.paymentStatus) : dash}</dd><dt>Llegada estimada</dt><dd>${j.etaMinutes != null ? esc(j.etaMinutes) + ' min' : dash}</dd><dt>Creado</dt><dd>${esc(dateFull(j.createdAt))}</dd></dl>
      <h3>Línea de tiempo</h3>${timeline(j)}</div>
      <div class="dlg-foot">${dis ? `<button class="btn" data-o="refund">Reembolsar al cliente</button><button class="btn primary" data-o="release">Liberar pago al técnico</button>` : ''}<button class="btn ${dis ? 'ghost' : ''}" data-close>Cerrar</button></div>`, { wide: true });
    d.addEventListener('click', async (e) => {
      if (e.target.closest('[data-close]')) return d.close();
      const b = e.target.closest('[data-o]'); if (!b) return;
      const release = b.dataset.o === 'release';
      const ok = await confirmDialog({
        title: release ? '¿Liberar el pago al técnico?' : '¿Reembolsar al cliente?',
        body: release ? `Se le acreditan <b>${money(j.techNet ?? j.price)}</b> a ${esc(techName(j) || 'el técnico')} y Fixi se queda con ${money(j.commission)} de comisión. El trabajo pasa a Completado. <b>No se puede deshacer.</b>`
          : `Se devuelven <b>${money(j.price)}</b> a ${esc(clientName(j) || 'el cliente')} y el trabajo pasa a Cancelado. Fixi no cobra comisión. <b>No se puede deshacer.</b>`,
        confirmText: release ? 'Sí, liberar pago' : 'Sí, reembolsar', danger: !release,
      });
      if (!ok) return;
      b.disabled = true;
      try {
        const res = await api(`/admin/jobs/${encodeURIComponent(j.id)}/resolve`, { method: 'POST', body: { outcome: release ? 'release' : 'refund' }, signal });
        const nj = res?.job && typeof res.job === 'object' ? res.job : res?.id ? res : null;
        Object.assign(j, nj || (release ? { status: 'completed', paymentStatus: 'released' } : { status: 'cancelled', paymentStatus: 'refunded' }));
        d.close(); view();
        toast(release ? 'Listo, el pago se liberó al técnico.' : 'Listo, el reembolso al cliente está en marcha.', { type: 'success' });
      } catch (err) { b.disabled = false; if (err.name !== 'AbortError') toast(err.message, { type: 'error' }); }
    });
  }

  root.addEventListener('click', (e) => {
    const c = e.target.closest('[data-f]'); if (c) { st.f = c.dataset.f; st.page = 0; view(); return; }
    const p = e.target.closest('[data-p]'); if (p) { st.page += Number(p.dataset.p); view(); return; }
    const r = e.target.closest('tr[data-id]'); if (r) detail(list.find((j) => String(j.id) === r.dataset.id));
  });
  root.addEventListener('keydown', (e) => { if (e.key === 'Enter') { const r = e.target.closest('tr[data-id]'); if (r) detail(list.find((j) => String(j.id) === r.dataset.id)); } });
  $('[data-search]', root).addEventListener('input', debounce((e) => { st.q = e.target.value; st.page = 0; view(); }));
}
