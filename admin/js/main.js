import { session, login, setUnauthorizedHandler } from './api.js';
import { esc, icon, initials, toast, modal, $, $$ } from './ui.js';

const app = document.getElementById('app');
const ROUTES = [
  { id: 'dashboard', label: 'Resumen', ic: 'dash', key: 'd', load: () => import('./views/dashboard.js') },
  { id: 'users', label: 'Usuarios y técnicos', ic: 'users', key: 'u', load: () => import('./views/users.js') },
  { id: 'jobs', label: 'Trabajos', ic: 'jobs', key: 'j', load: () => import('./views/jobs.js') },
  { id: 'payments', label: 'Pagos', ic: 'pay', key: 'p', load: () => import('./views/payments.js') },
  { id: 'categories', label: 'Categorías', ic: 'tag', key: 'c', load: () => import('./views/categories.js') },
  { id: 'server', label: 'Servidor', ic: 'server', key: 's', load: () => import('./views/server.js') },
];
const MARK = '<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M10 23V9h11v3.4h-6.8v2.5h5.6v3.3h-5.6V23z" fill="#C6F432"/></svg>';

/* Tema */
const prefersDark = () => matchMedia('(prefers-color-scheme: dark)').matches;
const currentTheme = () => document.documentElement.dataset.theme || (prefersDark() ? 'dark' : 'light');
function toggleTheme() {
  const t = currentTheme() === 'dark' ? 'light' : 'dark';
  document.documentElement.dataset.theme = t;
  try { localStorage.setItem('fixi_theme', t); } catch {}
  $$('[data-theme-btn]').forEach(paintThemeBtn);
}
const paintThemeBtn = (b) => { const d = currentTheme() === 'dark'; b.innerHTML = `${icon(d ? 'sun' : 'moon')} ${d ? 'Modo claro' : 'Modo oscuro'} <kbd>t</kbd>`; };

/* Login */
function showLogin(msg = '') {
  document.title = 'Ingresar · Fixi Admin';
  app.innerHTML = `<div class="login"><div class="login-art"><div class="brand"><div class="brand-mark">${MARK}</div><div>Fixi<small>Administración</small></div></div>
    <div><h2>Todo el servicio técnico, <em>bajo control</em>.</h2><p style="margin-top:14px;opacity:.85;max-width:420px">Verificá técnicos, seguí los trabajos y resolvé disputas desde un solo lugar.</p></div><p class="small" style="opacity:.7">Solo para administradores</p></div>
    <main class="login-form" id="main"><form novalidate><div><h1>Ingresá a tu panel</h1><p class="muted" style="margin-top:4px">Usá tu cuenta de administrador.</p></div>
      ${msg ? `<div class="card" role="alert" style="background:var(--warning-bg);color:var(--warning-text);border-color:transparent;padding:12px 16px">${esc(msg)}</div>` : ''}
      <div class="field"><label for="email">Email</label><input class="input" id="email" type="email" autocomplete="username" value="admin@fixi.app" required></div>
      <div class="field"><label for="pw">Contraseña</label><div class="pw"><input class="input" id="pw" type="password" autocomplete="current-password" required><button type="button" class="btn sm ghost" data-show aria-label="Mostrar contraseña" style="min-height:34px">${icon('eye')}</button></div></div>
      <div class="err-text" id="err" role="alert" hidden></div>
      <button class="btn primary" type="submit" style="min-height:46px">Ingresar</button>
      <button type="button" class="btn ghost sm" data-theme-btn></button></form></main></div>`;
  paintThemeBtn($('[data-theme-btn]'));
  $('[data-theme-btn]').onclick = toggleTheme;
  const form = $('form'), pw = $('#pw'), err = $('#err');
  $('[data-show]').onclick = () => { pw.type = pw.type === 'password' ? 'text' : 'password'; };
  $('#email').value ? pw.focus() : $('#email').focus();
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    err.hidden = true;
    const email = $('#email').value.trim(), pass = pw.value;
    if (!email || !pass) { err.textContent = 'Ingresá tu email y tu contraseña.'; err.hidden = false; return; }
    const btn = $('button[type=submit]'); btn.disabled = true; btn.innerHTML = '<span class="spin"></span> Ingresando…';
    try { await login(email, pass); location.hash = '#/dashboard'; showShell(); }
    catch (ex) { err.textContent = ex.code === 'INVALID_CREDENTIALS' || ex.status === 401 ? 'Email o contraseña incorrectos. Revisalos y probá de nuevo.' : ex.message; err.hidden = false; btn.disabled = false; btn.textContent = 'Ingresar'; pw.select(); }
  });
}

function logout(msg) { session.clear(); showLogin(msg); }
setUnauthorizedHandler(() => { if (session.token) { toast('Tu sesión venció. Ingresá de nuevo.', { type: 'error' }); logout('Tu sesión venció. Ingresá de nuevo.'); } });

/* Shell + router */
let nav = 0, ctl = null;
function showShell() {
  const u = session.user || {};
  app.innerHTML = `<div class="shell"><aside class="sidebar" id="side" aria-label="Navegación"><div class="brand"><div class="brand-mark">${MARK}</div><div>Fixi<small>Administración</small></div></div>
    <nav class="nav">${ROUTES.map((r) => `<a href="#/${r.id}" data-r="${r.id}">${icon(r.ic)}<span>${r.label}</span><kbd>g ${r.key}</kbd></a>`).join('')}</nav>
    <div class="side-foot"><button class="btn ghost" data-theme-btn style="justify-content:flex-start"></button><button class="btn ghost" data-help style="justify-content:flex-start">${icon('help')} Atajos <kbd>?</kbd></button>
    <div class="me"><div class="avatar">${esc(initials(u.name || u.email))}</div><div><b>${esc(u.name || 'Admin')}</b><span class="muted small">${esc(u.email || '')}</span></div><button class="btn sm icon ghost" data-logout aria-label="Cerrar sesión" title="Cerrar sesión" style="margin-left:auto">${icon('out')}</button></div></div></aside>
    <div class="scrim" data-scrim></div>
    <div class="main"><header class="topbar"><button class="btn icon ghost" data-menu aria-label="Abrir menú">${icon('menu')}</button><b style="font-family:var(--f-title)" data-title>Fixi</b></header><main id="main" class="page" tabindex="-1"></main></div></div>`;
  $$('[data-theme-btn]').forEach((b) => { paintThemeBtn(b); b.onclick = toggleTheme; });
  $('[data-logout]').onclick = () => logout();
  $('[data-help]').onclick = showHelp;
  $('[data-menu]').onclick = () => $('.shell').classList.toggle('nav-open');
  $('[data-scrim]').onclick = () => $('.shell').classList.remove('nav-open');
  route();
}

async function route() {
  if (!session.token) return;
  if (!$('.shell')) return showShell();
  const id = (location.hash.match(/^#\/(\w+)/) || [])[1] || 'dashboard';
  const r = ROUTES.find((x) => x.id === id) || ROUTES[0];
  const my = ++nav;
  ctl?.abort(); ctl = new AbortController();
  $$('.nav a').forEach((a) => (a.dataset.r === r.id ? a.setAttribute('aria-current', 'page') : a.removeAttribute('aria-current')));
  $('.shell').classList.remove('nav-open');
  document.title = `${r.label} · Fixi Admin`;
  $('[data-title]').textContent = r.label;
  const old = $('#main');
  const fresh = old.cloneNode(false); // contenedor nuevo: descarta listeners de la vista anterior
  old.replaceWith(fresh);
  fresh.innerHTML = '';
  try {
    const mod = await r.load();
    if (my !== nav) return;
    await mod.default(fresh, { signal: ctl.signal, refresh: route });
  } catch (e) {
    if (e.name === 'AbortError' || my !== nav) return;
    console.error(e);
    fresh.innerHTML = `<div class="card"><div class="state bad"><div class="big">${icon('alert')}</div><h3>Algo salió mal</h3><p>${esc(e.message)}</p><button class="btn" data-retry>Reintentar</button></div></div>`;
    $('[data-retry]', fresh).onclick = route;
  }
}
window.addEventListener('hashchange', route);

/* Atajos */
const SHORTCUTS = [['/', 'Buscar en la página'], ['g + d / u / j / p / c / s', 'Ir a Resumen / Usuarios / Trabajos / Pagos / Categorías / Servidor'], ['t', 'Cambiar tema claro/oscuro'], ['?', 'Ver esta ayuda'], ['Esc', 'Cerrar diálogos y menú']];
function showHelp() {
  const d = modal(`<div class="dlg-body"><h2>Atajos de teclado</h2><dl class="dl" style="grid-template-columns:170px 1fr">${SHORTCUTS.map(([k, v]) => `<dt><kbd>${esc(k)}</kbd></dt><dd>${esc(v)}</dd>`).join('')}</dl></div><div class="dlg-foot"><button class="btn primary" data-c>Entendido</button></div>`);
  $('[data-c]', d).onclick = () => d.close();
}
let g = 0;
document.addEventListener('keydown', (e) => {
  if (!session.token || e.ctrlKey || e.metaKey || e.altKey || document.querySelector('dialog[open]')) return;
  const tag = e.target.tagName;
  if (['INPUT', 'TEXTAREA', 'SELECT'].includes(tag) || e.target.isContentEditable) { if (e.key === 'Escape') e.target.blur(); return; }
  if (e.key === '/') { const s = $('[data-search]'); if (s) { e.preventDefault(); s.focus(); } return; }
  if (e.key === '?') return showHelp();
  if (e.key === 't') return toggleTheme();
  if (e.key === 'Escape') return $('.shell')?.classList.remove('nav-open');
  if (e.key === 'g') { g = Date.now(); return; }
  if (Date.now() - g < 1200) { const r = ROUTES.find((x) => x.key === e.key); if (r) { g = 0; location.hash = '#/' + r.id; } }
});

if (session.token && session.user?.role === 'admin') { if (!location.hash) location.hash = '#/dashboard'; showShell(); }
else showLogin();
