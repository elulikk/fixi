// Utilidades de UI: formato es-AR, íconos, toasts, diálogos, estados.
export const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
export const $ = (sel, root = document) => root.querySelector(sel);
export const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

const has = (v) => v !== undefined && v !== null && v !== '' && !(typeof v === 'number' && Number.isNaN(v));
export const dash = '—';

const nf = new Intl.NumberFormat('es-AR');
export const num = (v) => (has(v) && !isNaN(Number(v)) ? nf.format(Number(v)) : dash);
export const money = (v) => (has(v) && !isNaN(Number(v)) ? '$ ' + nf.format(Math.round(Number(v))) : dash);
export const compactMoney = (v) => {
  v = Number(v);
  if (isNaN(v)) return dash;
  if (Math.abs(v) >= 1e6) return '$ ' + (v / 1e6).toFixed(1).replace('.', ',') + ' M';
  if (Math.abs(v) >= 1e4) return '$ ' + Math.round(v / 1e3) + ' mil';
  return '$ ' + nf.format(Math.round(v));
};

const dtf = new Intl.DateTimeFormat('es-AR', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
const dtfFull = new Intl.DateTimeFormat('es-AR', { dateStyle: 'medium', timeStyle: 'short' });
const dayf = new Intl.DateTimeFormat('es-AR', { day: 'numeric', month: 'short' });
const validDate = (v) => { const d = new Date(v); return has(v) && !isNaN(d) ? d : null; };
export const dateTime = (v) => { const d = validDate(v); return d ? dtf.format(d).replace('.', '') : dash; };
export const dateFull = (v) => { const d = validDate(v); return d ? dtfFull.format(d) : dash; };
export const dayLabel = (v) => { const d = validDate(v); return d ? dayf.format(d).replace('.', '') : dash; };
export function ago(v) {
  const d = validDate(v); if (!d) return dash;
  const s = Math.round((Date.now() - d) / 1000);
  if (s < 45) return 'recién';
  if (s < 3600) return `hace ${Math.round(s / 60)} min`;
  if (s < 86400) return `hace ${Math.round(s / 3600)} h`;
  if (s < 86400 * 30) return `hace ${Math.round(s / 86400)} d`;
  return dateTime(v);
}
export const initials = (n) => String(n || '?').trim().split(/\s+/).slice(0, 2).map((w) => w[0]).join('').toUpperCase() || '?';
export const debounce = (fn, ms = 160) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };

// Íconos de trazo (inline, sin dependencias).
const P = {
  dash: '<rect x="3" y="3" width="7" height="9" rx="2"/><rect x="14" y="3" width="7" height="5" rx="2"/><rect x="14" y="12" width="7" height="9" rx="2"/><rect x="3" y="16" width="7" height="5" rx="2"/>',
  users: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.6-3.6 3.2-5.5 6.5-5.5s5.9 1.9 6.5 5.5"/><path d="M16 4.6a3.5 3.5 0 0 1 0 6.8M18 14.8c2 .6 3.2 2.3 3.5 5.2"/>',
  jobs: '<path d="M14.7 6.3a4 4 0 0 0 5 5L10 21a2.1 2.1 0 0 1-3-3l9.7-9.7"/><path d="M14.7 6.3 17 4l3 3-2.3 2.3"/>',
  pay: '<rect x="2.5" y="5" width="19" height="14" rx="3"/><path d="M2.5 10h19M6.5 15h3"/>',
  tag: '<path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9z"/><circle cx="8" cy="8" r="1.2"/>',
  server: '<rect x="3" y="4" width="18" height="7" rx="2"/><rect x="3" y="13" width="18" height="7" rx="2"/><path d="M7 7.5h.01M7 16.5h.01"/>',
  search: '<circle cx="11" cy="11" r="6.5"/><path d="m20 20-3.5-3.5"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
  moon: '<path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/>',
  menu: '<path d="M4 6h16M4 12h16M4 18h16"/>',
  out: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  edit: '<path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16z"/>',
  trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
  check: '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
  x: '<path d="M6 6l12 12M18 6 6 18"/>',
  copy: '<rect x="8" y="8" width="12" height="12" rx="2.5"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>',
  refresh: '<path d="M20 11a8 8 0 0 0-14.5-3.5L4 9M4 4v5h5M4 13a8 8 0 0 0 14.5 3.5L20 15M20 20v-5h-5"/>',
  shield: '<path d="M12 3 4.5 6v5.5c0 4.6 3.1 8.2 7.5 9.5 4.4-1.3 7.5-4.9 7.5-9.5V6z"/><path d="m9 12 2.2 2.2L15 10"/>',
  ban: '<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>',
  alert: '<path d="M12 3 2 20h20z"/><path d="M12 10v4.5M12 17.5v.01"/>',
  phone: '<rect x="7" y="2.5" width="10" height="19" rx="2.5"/><path d="M11 18.5h2"/>',
  coin: '<circle cx="12" cy="12" r="9"/><path d="M14.5 9.2c-.5-.8-1.4-1.2-2.5-1.2-1.5 0-2.5.8-2.5 1.9 0 2.6 5 1.2 5 4 0 1.1-1.100 2-2.500 2-1.200 0-2.100-.5-2.600-1.300M12 6.500V8M12 16v1.500"/>',
  chart: '<path d="M4 20V4M4 20h16M8 16v-4M12 16V8M16 16v-6"/>',
  wrench: '<path d="M14.7 6.3a4 4 0 0 0 5 5L10 21a2.1 2.1 0 0 1-3-3l9.7-9.7"/>',
  inbox: '<path d="M3 13h5l1.500 3h5L16 13h5M5 5h14l2 8v6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-6z"/>',
  link: '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.700-5.700l-1 1M14 10a4 4 0 0 0-5.700 0l-3 3a4 4 0 0 0 5.700 5.700l1-1"/>',
  eye: '<path d="M2 12s3.500-7 10-7 10 7 10 7-3.500 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  help: '<circle cx="12" cy="12" r="9"/><path d="M9.500 9.500a2.500 2.500 0 1 1 3.500 2.300c-.7.400-1 .900-1 1.700M12 17v.01"/>',
};
export const icon = (n, cls = '') => `<svg class="ic ${cls}" viewBox="0 0 24 24" aria-hidden="true">${P[n] || ''}</svg>`;
export const matIcon = (name) => `<span class="mi" aria-hidden="true">${esc(name || 'build')}</span>`;

// Estados → pill
const STATUS = {
  pending_payment: ['Pago pendiente', 'warning'], paid: ['Pagado', 'primary'], on_the_way: ['En camino', 'primary'],
  in_progress: ['En trabajo', 'primary'], done: ['Terminado', 'success'], completed: ['Completado', 'success'],
  cancelled: ['Cancelado', ''], disputed: ['En disputa', 'error'],
  pending: ['Pendiente', 'warning'], held: ['Retenido', 'primary'], released: ['Liberado', 'success'], refunded: ['Reembolsado', ''],
  approved: ['Aprobado', 'primary'], failed: ['Fallido', 'error'],
  open: ['Abierta', 'primary'], assigned: ['Asignada', 'primary'], closed: ['Cerrada', ''],
};
export const statusLabel = (s) => (STATUS[s] ? STATUS[s][0] : s || dash);
export const pill = (s, label) => { const [l, c] = STATUS[s] || [s || dash, '']; return `<span class="pill ${c}">${esc(label || l)}</span>`; };
export const tone = (text, cls = '') => `<span class="pill ${cls}">${esc(text)}</span>`;

// Toasts (con acción opcional, p. ej. "Deshacer")
export function toast(message, { type = 'info', action, onAction, ms = 5000 } = {}) {
  const host = document.getElementById('toasts');
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.setAttribute('role', type === 'error' ? 'alert' : 'status');
  el.innerHTML = `<span>${esc(message)}</span>`;
  const close = () => el.remove();
  if (action) {
    const b = document.createElement('button');
    b.textContent = action;
    b.onclick = () => { close(); onAction?.(); };
    el.append(b);
  }
  host.append(el);
  setTimeout(close, ms);
  return close;
}

// Diálogos
function openDialog(html, { wide = false } = {}) {
  const d = document.createElement('dialog');
  if (wide) d.className = 'wide';
  d.innerHTML = html;
  document.body.append(d);
  d.addEventListener('close', () => d.remove());
  d.addEventListener('click', (e) => { if (e.target === d) d.close(); });
  d.showModal();
  return d;
}

export function confirmDialog({ title, body, confirmText = 'Confirmar', danger = false }) {
  return new Promise((resolve) => {
    const d = openDialog(`<div class="dlg-body"><h2>${esc(title)}</h2><div class="muted">${body}</div></div>
      <div class="dlg-foot"><button class="btn" data-r="0">Cancelar</button><button class="btn ${danger ? 'danger solid' : 'primary'}" data-r="1">${esc(confirmText)}</button></div>`);
    let result = false;
    d.addEventListener('click', (e) => { const b = e.target.closest('[data-r]'); if (b) { result = b.dataset.r === '1'; d.close(); } });
    d.addEventListener('close', () => resolve(result));
    $('[data-r="0"]', d).focus();
  });
}

// Modal con contenido propio; devuelve el <dialog>.
export function modal(html, opts) { return openDialog(html, opts); }

// Formulario modal: fields = [{name,label,type,value,required,options,hint,placeholder}]
export function formDialog({ title, fields, submitText = 'Guardar', onSubmit }) {
  const inputs = fields.map((f) => {
    const id = 'f_' + f.name;
    const common = `id="${id}" name="${f.name}" class="input" ${f.required ? 'required' : ''} placeholder="${esc(f.placeholder || '')}"`;
    let control;
    if (f.options) control = `<select ${common}>${f.options.map((o) => `<option value="${esc(o)}" ${o === f.value ? 'selected' : ''}>${esc(o)}</option>`).join('')}</select>`;
    else if (f.list) control = `<input ${common} list="${id}_l" value="${esc(f.value ?? '')}" autocomplete="off"><datalist id="${id}_l">${f.list.map((o) => `<option value="${esc(o)}">`).join('')}</datalist>`;
    else control = `<input ${common} type="${f.type || 'text'}" value="${esc(f.value ?? '')}" autocomplete="off">`;
    return `<div class="field"><label for="${id}">${esc(f.label)}</label>${control}${f.hint ? `<span class="hint">${f.hint}</span>` : ''}<span class="err-text" data-err="${f.name}" hidden></span></div>`;
  }).join('');
  const d = openDialog(`<form method="dialog" novalidate><div class="dlg-body"><h2>${esc(title)}</h2>${inputs}<span class="err-text" data-err="_form" hidden></span></div>
    <div class="dlg-foot"><button type="button" class="btn" data-cancel>Cancelar</button><button class="btn primary" type="submit">${esc(submitText)}</button></div></form>`);
  const form = $('form', d);
  $('[data-cancel]', d).onclick = () => d.close();
  setTimeout(() => form.elements[0]?.focus(), 30);
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    $$('[data-err]', d).forEach((x) => (x.hidden = true));
    const values = {}; let ok = true;
    for (const f of fields) {
      const el = form.elements[f.name]; const v = el.value.trim();
      values[f.name] = v;
      if (f.required && !v) { const er = $(`[data-err="${f.name}"]`, d); er.textContent = 'Completá este campo.'; er.hidden = false; el.setAttribute('aria-invalid', 'true'); ok = false; }
      else el.removeAttribute('aria-invalid');
    }
    if (!ok) return;
    const btn = $('button[type=submit]', d); btn.disabled = true; btn.innerHTML = '<span class="spin"></span>';
    try { await onSubmit(values); d.close(); }
    catch (err) { const er = $('[data-err="_form"]', d); er.textContent = err.message; er.hidden = false; btn.disabled = false; btn.textContent = submitText; }
  });
  return d;
}

// Estados de página
export const skeletonRows = (n = 6, cols = 5) => `<div class="card flush"><div class="table-wrap"><table><tbody>${Array.from({ length: n }, () => `<tr>${Array.from({ length: cols }, (_, i) => `<td><span class="skel" style="width:${i === 0 ? 70 : 40 + ((i * 17) % 40)}%"></span></td>`).join('')}</tr>`).join('')}</tbody></table></div></div>`;
export const skeletonCards = (n = 4) => `<div class="grid kpis">${Array.from({ length: n }, () => '<div class="card"><span class="skel" style="width:36px;height:36px;border-radius:12px"></span><span class="skel" style="width:60%;height:28px;margin-top:12px"></span><span class="skel" style="width:40%;margin-top:8px"></span></div>').join('')}</div>`;
export const emptyState = (title, text, iconName = 'inbox', actionHtml = '') => `<div class="state"><div class="big">${icon(iconName)}</div><h3>${esc(title)}</h3><p>${esc(text)}</p>${actionHtml}</div>`;
export const errorState = (err, retryLabel = 'Reintentar') => `<div class="state bad"><div class="big">${icon('alert')}</div><h3>No pudimos cargar esto</h3><p>${esc(err?.message || 'Probá de nuevo en un momento.')}</p><button class="btn" data-retry>${icon('refresh')} ${esc(retryLabel)}</button></div>`;

export function copyText(text) {
  const done = () => toast('Copiado al portapapeles', { type: 'success', ms: 2200 });
  if (navigator.clipboard?.writeText) navigator.clipboard.writeText(text).then(done, () => fallback());
  else fallback();
  function fallback() { const t = document.createElement('textarea'); t.value = text; document.body.append(t); t.select(); try { document.execCommand('copy'); done(); } catch { toast('No pudimos copiar. Seleccionalo a mano.', { type: 'error' }); } t.remove(); }
}

export function pageHead(title, sub, actionsHtml = '') {
  return `<div class="page-head"><div><h1>${esc(title)}</h1>${sub ? `<p>${esc(sub)}</p>` : ''}</div><div class="actions">${actionsHtml}</div></div>`;
}
