/** Paginas HTML del checkout simulado. Mobile-first, marca Fixi (azul #2F5BFF, lima #C6F432). */

const esc = (s: unknown) =>
  String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
const ars = (n: number) => '$ ' + n.toLocaleString('es-AR');

const css = `
:root{--blue:#2F5BFF;--lime:#C6F432;--ink:#0E1320;--bg:#F6F7FB;--ok:#16B364;--err:#F04438;--mut:#6B7280}
*{box-sizing:border-box}
body{margin:0;font-family:Inter,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;background:var(--bg);color:var(--ink);min-height:100vh;display:flex;flex-direction:column}
header{background:var(--blue);color:#fff;padding:22px 20px 56px;display:flex;align-items:center;gap:10px}
.logo{width:36px;height:36px;border-radius:12px;background:var(--lime);color:var(--ink);font-weight:800;display:grid;place-items:center;font-size:20px}
header b{font-size:22px;letter-spacing:-.5px}
header span{margin-left:auto;font-size:12px;opacity:.85;background:rgba(255,255,255,.16);padding:5px 10px;border-radius:99px}
main{flex:1;width:100%;max-width:460px;margin:-36px auto 0;padding:0 16px 28px}
.card{background:#fff;border-radius:24px;padding:22px;box-shadow:0 10px 30px rgba(14,19,32,.08)}
h1{font-size:20px;margin:0 0 4px;letter-spacing:-.3px}
.sub{color:var(--mut);font-size:14px;margin:0 0 18px}
.amount{font-size:38px;font-weight:800;letter-spacing:-1px;margin:6px 0 2px}
.rows{margin:16px 0;border-top:1px dashed #E3E6EF}
.row{display:flex;justify-content:space-between;gap:12px;padding:11px 0;border-bottom:1px dashed #E3E6EF;font-size:14px}
.row span:first-child{color:var(--mut)}.row span:last-child{font-weight:600;text-align:right}
.btn{width:100%;border:0;border-radius:16px;padding:16px;font-size:16px;font-weight:700;cursor:pointer;font-family:inherit;transition:transform .08s}
.btn:active{transform:scale(.98)}.btn[disabled]{opacity:.55}
.ok{background:var(--lime);color:var(--ink)}.no{background:#fff;color:var(--err);border:2px solid #FBD5D2;margin-top:10px}
.note{font-size:12px;color:var(--mut);text-align:center;margin-top:14px;line-height:1.5}
.big{width:72px;height:72px;border-radius:50%;display:grid;place-items:center;margin:8px auto 14px;font-size:38px;color:#fff}
.center{text-align:center}.hide{display:none}
`;

const shell = (title: string, body: string, script = '') => `<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="theme-color" content="#2F5BFF"><title>${esc(title)} · Fixi</title><style>${css}</style></head>
<body><header><div class="logo">F</div><b>Fixi</b><span>Pago seguro</span></header><main>${body}</main>${script ? `<script>${script}</script>` : ''}</body></html>`;

export function messagePage(kind: 'ok' | 'error', title: string, text: string) {
  const color = kind === 'ok' ? 'var(--ok)' : 'var(--err)';
  return shell(
    title,
    `<div class="card center"><div class="big" style="background:${color}">${kind === 'ok' ? '✓' : '!'}</div><h1>${esc(title)}</h1><p class="sub">${esc(text)}</p></div>`,
  );
}

export interface CheckoutView {
  paymentId: string;
  status: string;
  title: string;
  techName: string;
  address: string;
  amount: number;
  commission: number;
  techNet: number;
}

export function checkoutPage(v: CheckoutView) {
  const done = v.status !== 'pending';
  const doneMsg =
    v.status === 'approved' || v.status === 'released'
      ? 'Este pago ya fue aprobado. Ya podés volver a la app.'
      : 'Este pago ya fue procesado (' + v.status + ').';
  const body = `
<div class="card" id="checkout" ${done ? 'style="display:none"' : ''}>
  <h1>Confirmá tu pago</h1>
  <p class="sub">Checkout simulado de demostración. No se cobra dinero real.</p>
  <div class="amount">${ars(v.amount)}</div>
  <div class="sub" style="margin:0">${esc(v.title)}</div>
  <div class="rows">
    <div class="row"><span>Técnico</span><span>${esc(v.techName)}</span></div>
    ${v.address ? `<div class="row"><span>Dirección</span><span>${esc(v.address)}</span></div>` : ''}
    <div class="row"><span>Comisión Fixi</span><span>${ars(v.commission)}</span></div>
    <div class="row"><span>Para el técnico</span><span>${ars(v.techNet)}</span></div>
    <div class="row"><span>N.º de pago</span><span style="font-size:12px">${esc(v.paymentId.slice(0, 8))}</span></div>
  </div>
  <button class="btn ok" id="approve">Aprobar pago</button>
  <button class="btn no" id="reject">Rechazar pago</button>
  <p class="note">El dinero queda retenido por Fixi hasta que confirmes que el trabajo se terminó.</p>
</div>
<div class="card center ${done ? '' : 'hide'}" id="result">
  <div class="big" id="icon" style="background:var(--ok)">✓</div>
  <h1 id="rtitle">${done ? 'Listo' : ''}</h1>
  <p class="sub" id="rtext">${done ? esc(doneMsg) : ''}</p>
</div>`;
  const script = `
var pid=${JSON.stringify(v.paymentId)};
function send(status){
  var a=document.getElementById('approve'),r=document.getElementById('reject');a.disabled=r.disabled=true;
  fetch('/api/v1/payments/webhook/mock',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({paymentId:pid,status:status})})
  .then(function(x){if(!x.ok)throw new Error();return x.json()})
  .then(function(){show(status==='approved')})
  .catch(function(){a.disabled=r.disabled=false;alert('No pudimos procesar el pago. Probá de nuevo.')});
}
function show(ok){
  document.getElementById('checkout').style.display='none';
  var res=document.getElementById('result');res.classList.remove('hide');
  var i=document.getElementById('icon');i.textContent=ok?'✓':'!';i.style.background=ok?'var(--ok)':'var(--err)';
  document.getElementById('rtitle').textContent=ok?'Pago aprobado':'Pago rechazado';
  document.getElementById('rtext').textContent=ok?'Pago aprobado, ya podés volver a la app.':'El pago fue rechazado. Volvé a la app para intentarlo de nuevo.';
}
document.getElementById('approve').onclick=function(){send('approved')};
document.getElementById('reject').onclick=function(){send('rejected')};`;
  return shell('Pagar', body, script);
}
