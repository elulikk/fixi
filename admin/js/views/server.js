import { health, API_BASE, ORIGIN } from '../api.js';
import { esc, icon, pageHead, copyText, toast, dash, $ } from '../ui.js';

const isLocal = (h) => ['localhost', '127.0.0.1', '[::1]', '::1'].includes(h);

export default async function server(root, { signal, refresh }) {
  const port = location.port || (location.protocol === 'https:' ? '443' : '80');
  const saved = (() => { try { return localStorage.getItem('fixi_lan_ip') || ''; } catch { return ''; } })();
  root.innerHTML = pageHead('Servidor', 'Estado de la API y datos para conectar la app.', `<button class="btn" data-reload>${icon('refresh')} Probar de nuevo</button>`)
    + `<div class="grid two">
      <section class="card" aria-labelledby="h-t"><div class="card-head"><h2 id="h-t">Estado</h2></div><div data-status><span class="skel" style="width:60%"></span><span class="skel" style="width:40%;margin-top:12px"></span></div></section>
      <section class="card" aria-labelledby="c-t"><div class="card-head"><h2 id="c-t">Conectar la app</h2></div>
        <p class="muted">En el celular, abrí Fixi, tocá <b>Configurar servidor</b> y pegá esta dirección. El celular tiene que estar en el mismo WiFi que esta PC.</p>
        ${isLocal(location.hostname) ? `<div class="field" style="margin:14px 0"><label for="ip">IP de esta PC en la red</label><input id="ip" class="input" inputmode="decimal" placeholder="Ej: 192.168.0.15" value="${esc(saved)}"><span class="hint">Estás viendo el panel como "localhost", que el celular no entiende. Para saber tu IP ejecutá <kbd>ipconfig</kbd> y buscá "Dirección IPv4".</span></div>` : ''}
        <div class="urlbox" style="margin-top:14px"><code data-url aria-live="polite"></code><button class="btn" data-copy>${icon('copy')} Copiar</button></div>
        <ol class="steps small muted" style="margin-top:14px"><li>Conectá el celular al mismo WiFi.</li><li>Si no conecta, permití el puerto ${esc(port)} en el Firewall de Windows.</li><li>Probá abrir la dirección en el navegador del celular: tiene que mostrar "ok".</li></ol>
      </section></div>`;
  $('[data-reload]', root).onclick = refresh;

  const urlEl = $('[data-url]', root), ipEl = $('#ip', root);
  const mk = () => {
    if (ipEl) { const ip = ipEl.value.trim(); return ip ? `${location.protocol}//${ip}:${port}` : `${location.protocol}//<IP-de-tu-PC>:${port}`; }
    return ORIGIN;
  };
  const paint = () => { urlEl.textContent = mk(); };
  paint();
  ipEl?.addEventListener('input', () => { try { localStorage.setItem('fixi_lan_ip', ipEl.value.trim()); } catch {} paint(); });
  $('[data-copy]', root).onclick = () => { if (urlEl.textContent.includes('<')) { toast('Completá primero la IP de tu PC.', { type: 'error' }); ipEl?.focus(); } else copyText(urlEl.textContent); };

  const box = $('[data-status]', root);
  try {
    const h = await health();
    const lan = h.lanUrls || h.addresses || h.lan;
    box.innerHTML = `<div class="status-row"><span class="dotl ok"></span><div><b>Servidor en línea</b><div class="muted small">Respondió en ${h.ms} ms</div></div></div>
      <div class="status-row"><span class="muted">Versión</span><b style="margin-left:auto">${esc(h.version || dash)}</b></div>
      <div class="status-row"><span class="muted">Respuesta de /health</span><b style="margin-left:auto">${h.ok === true ? 'ok' : h.ok === false ? 'con fallas' : dash}</b></div>
      <div class="status-row"><span class="muted">API</span><code style="margin-left:auto">${esc(API_BASE)}</code></div>
      <div class="status-row"><span class="muted">Origen</span><code style="margin-left:auto">${esc(ORIGIN)}</code></div>`;
    if (Array.isArray(lan) && lan.length && ipEl === null) urlEl.textContent = lan[0];
    else if (Array.isArray(lan) && lan.length && !ipEl.value) { ipEl.value = String(lan[0]).replace(/^https?:\/\//, '').replace(/:\d+$/, ''); paint(); }
  } catch (e) {
    if (e.name === 'AbortError') return;
    box.innerHTML = `<div class="status-row"><span class="dotl ko"></span><div><b>Sin respuesta</b><div class="muted small">${esc(e.message)}</div></div></div><p class="muted small">Revisá que el servidor esté corriendo (<kbd>npm run dev</kbd> en <code>server/</code>).</p>`;
  }
}
