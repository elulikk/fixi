import { api, items } from '../api.js';
import { esc, icon, pageHead, skeletonRows, emptyState, errorState, tone, initials, dateTime, num, dash, toast, confirmDialog, debounce, modal, ago } from '../ui.js';

const PAGE = 25;
const tp = (u) => u.techProfile || u.tech || {};
const isTech = (u) => !!(u.isTechnician ?? u.techProfile);
const verified = (u) => !!(u.verified ?? tp(u).verified);
const suspended = (u) => !!(u.suspended ?? u.isSuspended ?? u.status === 'suspended');
const level = (u) => u.level ?? tp(u).level;
const LEVEL_TONE = { bronce: 'warning', plata: '', oro: 'warning', platino: 'primary' };
const FILTERS = [['all', 'Todos'], ['client', 'Clientes'], ['tech', 'Técnicos'], ['unverified', 'Sin verificar'], ['suspended', 'Suspendidos']];

export default async function users(root, { signal, refresh }) {
  root.innerHTML = pageHead('Usuarios y técnicos', 'Verificá técnicos y administrá cuentas.') + skeletonRows(8, 5);
  let list;
  try { list = items(await api('/admin/users?limit=500', { signal })); }
  catch (e) {
    if (e.name === 'AbortError') return;
    root.innerHTML = pageHead('Usuarios y técnicos', '') + `<div class="card">${errorState(e)}</div>`;
    root.querySelector('[data-retry]').onclick = refresh; return;
  }
  const st = { q: '', f: sessionStorage.getItem('fixi_uf') || 'all', page: 0, sort: 'createdAt', dir: -1 };
  const match = {
    all: () => true, client: (u) => !isTech(u), tech: isTech,
    unverified: (u) => isTech(u) && !verified(u), suspended,
  };

  root.innerHTML = pageHead('Usuarios y técnicos', `${num(list.length)} cuentas en total.`)
    + `<div class="toolbar"><div class="search">${icon('search')}<input class="input" type="search" data-search placeholder="Buscar por nombre, email o teléfono  ( / )" aria-label="Buscar usuarios"></div><div class="chips" data-chips role="group" aria-label="Filtrar"></div></div>
    <div class="card flush" data-box></div>`;
  const box = root.querySelector('[data-box]');
  const chipsEl = root.querySelector('[data-chips]');

  function view() {
    const q = st.q.toLowerCase();
    let rows = list.filter((u) => match[st.f](u) && (!q || [u.name, u.email, u.phone].some((x) => String(x || '').toLowerCase().includes(q))));
    const key = st.sort;
    rows.sort((a, b) => {
      const va = key === 'name' ? String(a.name || '').toLowerCase() : String(a[key] ?? ''), vb = key === 'name' ? String(b.name || '').toLowerCase() : String(b[key] ?? '');
      return va < vb ? -st.dir : va > vb ? st.dir : 0;
    });
    chipsEl.innerHTML = FILTERS.map(([k, l]) => `<button class="chip" data-f="${k}" aria-pressed="${st.f === k}">${l} <span class="n">${list.filter(match[k]).length}</span></button>`).join('');
    const pages = Math.max(1, Math.ceil(rows.length / PAGE));
    st.page = Math.min(st.page, pages - 1);
    const slice = rows.slice(st.page * PAGE, st.page * PAGE + PAGE);
    if (!rows.length) { box.innerHTML = emptyState('No encontramos cuentas', st.q || st.f !== 'all' ? 'Probá con otra búsqueda o quitá los filtros.' : 'Cuando se registren usuarios, aparecen acá.', 'users'); return; }
    const th = (k, l, sortable = true) => `<th ${sortable ? `class="sortable" data-sort="${k}" aria-sort="${st.sort === k ? (st.dir > 0 ? 'ascending' : 'descending') : 'none'}"` : ''}>${l}${st.sort === k ? (st.dir > 0 ? ' ↑' : ' ↓') : ''}</th>`;
    box.innerHTML = `<div class="table-wrap"><table><thead><tr>${th('name', 'Usuario')}${th('role', 'Tipo', false)}${th('x', 'Reputación', false)}${th('createdAt', 'Alta')}${th('', 'Estado', false)}<th></th></tr></thead><tbody>${slice.map((u) => {
      const t = tp(u), tech = isTech(u);
      return `<tr data-id="${esc(u.id)}"><td class="cell-user"><div class="avatar" aria-hidden="true">${esc(initials(u.name))}</div><div><b>${esc(u.name || dash)}</b><span class="muted small">${esc(u.email || dash)}${u.phone ? ' · ' + esc(u.phone) : ''}</span></div></td>
      <td>${u.role === 'admin' ? tone('Admin', 'primary nodot') : tech ? tone('Técnico', 'nodot primary') : tone('Cliente', 'nodot')}</td>
      <td class="num">${tech ? `${level(u) ? tone(String(level(u)).replace(/^./, (c) => c.toUpperCase()), (LEVEL_TONE[level(u)] || '') + ' nodot') + ' ' : ''}<span class="muted small">${(u.ratingAvg ?? t.ratingAvg) != null ? '★ ' + Number(u.ratingAvg ?? t.ratingAvg).toFixed(1) : ''} ${num(u.jobsDone ?? t.jobsDone) !== dash ? '· ' + num(u.jobsDone ?? t.jobsDone) + ' trabajos' : ''}</span>` : '<span class="muted">' + dash + '</span>'}</td>
      <td class="muted small" title="${esc(u.createdAt || '')}">${esc(dateTime(u.createdAt))}</td>
      <td>${suspended(u) ? tone('Suspendido', 'error') : tech ? (verified(u) ? tone('Verificado', 'success') : tone('Sin verificar', 'warning')) : tone('Activo', 'success')}</td>
      <td><div class="row-actions">${tech && !verified(u) ? `<button class="btn sm" data-act="verify">${icon('shield')} Verificar</button>` : ''}${u.role !== 'admin' ? (suspended(u) ? `<button class="btn sm" data-act="unsuspend">Reactivar</button>` : `<button class="btn sm danger" data-act="suspend">${icon('ban')} Suspender</button>`) : ''}</div></td></tr>`;
    }).join('')}</tbody></table></div>
    <div class="pager"><span class="muted small">${st.page * PAGE + 1}–${st.page * PAGE + slice.length} de ${rows.length}</span><div class="actions"><button class="btn sm" data-p="-1" ${st.page === 0 ? 'disabled' : ''}>Anterior</button><button class="btn sm" data-p="1" ${st.page >= pages - 1 ? 'disabled' : ''}>Siguiente</button></div></div>`;
  }
  view();

  async function patch(u, body, okMsg, undoBody) {
    try {
      const res = await api(`/admin/users/${encodeURIComponent(u.id)}`, { method: 'PATCH', body, signal });
      Object.assign(u, body, (res && (res.user || res)) && typeof (res.user || res) === 'object' && (res.user || res).id ? (res.user || res) : {});
      if ('verified' in body && u.techProfile) u.techProfile.verified = body.verified;
      view();
      toast(okMsg, { type: 'success', action: undoBody ? 'Deshacer' : undefined, onAction: () => patch(u, undoBody, 'Cambio deshecho.'), ms: 6000 });
    } catch (e) { if (e.name !== 'AbortError') toast(e.message, { type: 'error' }); }
  }

  root.addEventListener('click', async (e) => {
    const chip = e.target.closest('[data-f]');
    if (chip) { st.f = chip.dataset.f; st.page = 0; try { sessionStorage.setItem('fixi_uf', st.f); } catch {} view(); return; }
    const s = e.target.closest('[data-sort]');
    if (s) { st.dir = st.sort === s.dataset.sort ? -st.dir : 1; st.sort = s.dataset.sort; view(); return; }
    const p = e.target.closest('[data-p]');
    if (p) { st.page += Number(p.dataset.p); view(); box.scrollIntoView({ block: 'nearest' }); return; }
    const a = e.target.closest('[data-act]');
    if (!a) return;
    const u = list.find((x) => String(x.id) === a.closest('tr').dataset.id);
    if (a.dataset.act === 'verify') patch(u, { verified: true }, `${u.name} ya está verificado.`, { verified: false });
    if (a.dataset.act === 'unsuspend') patch(u, { suspended: false }, `${u.name} puede volver a usar Fixi.`, { suspended: true });
    if (a.dataset.act === 'suspend') {
      const ok = await confirmDialog({ title: `¿Suspender a ${u.name}?`, body: 'No va a poder iniciar sesión ni recibir trabajos hasta que lo reactives. Los trabajos en curso no se cancelan.', confirmText: 'Suspender', danger: true });
      if (ok) patch(u, { suspended: true }, `${u.name} quedó suspendido.`, { suspended: false });
    }
  });
  root.querySelector('[data-search]').addEventListener('input', debounce((e) => { st.q = e.target.value; st.page = 0; view(); }));
}
