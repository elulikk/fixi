import { api, items } from '../api.js';
import { esc, icon, matIcon, pageHead, skeletonCards, emptyState, errorState, toast, confirmDialog, formDialog, $, dash } from '../ui.js';

const GROUPS = ['Tecnología', 'Electrodomésticos', 'Hogar', 'Otros'];
const ICONS = ['computer', 'smartphone', 'wifi', 'sports_esports', 'print', 'kitchen', 'local_laundry_service', 'ac_unit', 'tv', 'oven_gen', 'bolt', 'plumbing', 'local_fire_department', 'key', 'format_paint', 'construction', 'build', 'handyman', 'home_repair_service'];
const slugify = (s) => s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

export default async function categories(root, { signal, refresh }) {
  const head = (extra = '') => pageHead('Categorías', 'Los rubros que los clientes pueden pedir y los técnicos ofrecer.', extra);
  root.innerHTML = head() + skeletonCards(4);
  let list;
  try { list = items(await api('/admin/categories', { signal })); }
  catch (e) {
    if (e.name === 'AbortError') return;
    root.innerHTML = head() + `<div class="card">${errorState(e)}</div>`;
    root.querySelector('[data-retry]').onclick = refresh; return;
  }
  const groups = () => [...new Set([...GROUPS, ...list.map((c) => c.group).filter(Boolean)])];

  function view() {
    root.innerHTML = head(`<button class="btn primary" data-new>${icon('plus')} Nueva categoría</button>`);
    if (!list.length) { root.insertAdjacentHTML('beforeend', `<div class="card">${emptyState('Todavía no hay categorías', 'Creá la primera para que los clientes puedan pedir un servicio.', 'tag')}</div>`); return; }
    const by = {};
    list.forEach((c) => (by[c.group || 'Sin grupo'] ||= []).push(c));
    for (const g of Object.keys(by)) {
      root.insertAdjacentHTML('beforeend', `<section class="cat-group"><h3>${esc(g)} <span class="pill nodot">${by[g].length}</span></h3><div class="cat-grid">${by[g].map((c) => `<div class="card cat-card" data-id="${esc(c.id)}"><div class="cat-ico">${matIcon(c.icon)}</div><div class="t"><b>${esc(c.name || dash)}</b><span class="muted small">${esc(c.slug || '')}</span></div><button class="btn sm icon ghost" data-edit aria-label="Editar ${esc(c.name)}" title="Editar">${icon('edit')}</button><button class="btn sm icon ghost" data-del aria-label="Eliminar ${esc(c.name)}" title="Eliminar">${icon('trash')}</button></div>`).join('')}</div></section>`);
    }
  }
  view();

  const fields = (c = {}) => [
    { name: 'name', label: 'Nombre', value: c.name, required: true, placeholder: 'Ej: Aire acondicionado' },
    { name: 'group', label: 'Grupo', value: c.group || GROUPS[0], list: groups(), required: true, hint: 'Elegí uno o escribí uno nuevo.' },
    { name: 'icon', label: 'Ícono', value: c.icon || 'build', list: ICONS, required: true, hint: 'Nombre de <a href="https://fonts.google.com/icons" target="_blank" rel="noopener">Material Symbols</a>, por ejemplo "bolt".' },
  ];
  const clean = (v, c) => ({ name: v.name, group: v.group, icon: v.icon, slug: c?.slug || slugify(v.name) });

  root.addEventListener('click', async (e) => {
    if (e.target.closest('[data-new]')) {
      formDialog({ title: 'Nueva categoría', fields: fields(), submitText: 'Crear', onSubmit: async (v) => {
        const res = await api('/admin/categories', { method: 'POST', body: clean(v), signal });
        list.push(res?.category || (res?.id ? res : { id: 'tmp' + Date.now(), ...clean(v) }));
        view(); toast(`Categoría "${v.name}" creada.`, { type: 'success' });
      } });
      return;
    }
    const card = e.target.closest('[data-id]'); if (!card) return;
    const c = list.find((x) => String(x.id) === card.dataset.id);
    if (e.target.closest('[data-edit]')) {
      formDialog({ title: 'Editar categoría', fields: fields(c), onSubmit: async (v) => {
        const res = await api(`/admin/categories/${encodeURIComponent(c.id)}`, { method: 'PATCH', body: { name: v.name, group: v.group, icon: v.icon }, signal });
        Object.assign(c, v, res?.category || (res?.id ? res : {}));
        view(); toast('Cambios guardados.', { type: 'success' });
      } });
    }
    if (e.target.closest('[data-del]')) {
      const ok = await confirmDialog({ title: `¿Eliminar "${c.name}"?`, body: 'Los clientes dejan de verla al pedir un servicio. Si hay técnicos o trabajos que la usan, el servidor puede rechazar el borrado.', confirmText: 'Eliminar', danger: true });
      if (!ok) return;
      try {
        await api(`/admin/categories/${encodeURIComponent(c.id)}`, { method: 'DELETE', signal });
        list = list.filter((x) => x !== c); view(); toast(`"${c.name}" eliminada.`, { type: 'success' });
      } catch (err) { if (err.name !== 'AbortError') toast(err.message, { type: 'error' }); }
    }
  });
}
