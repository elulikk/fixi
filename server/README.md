# Fixi — Servidor (API + WebSocket)

API REST + WebSocket de Fixi, el marketplace de servicio técnico a domicilio. Node 24 + TypeScript + Fastify, base SQLite en un archivo (módulo nativo `node:sqlite`, sin compilar nada), validación con Zod, JWT.

El contrato completo (modelo de datos, endpoints, WS, pagos) está en [`../docs/ARQUITECTURA.md`](../docs/ARQUITECTURA.md).

## Instalar y correr

```bash
cd server
npm install
npm run dev        # desarrollo (tsx watch), escucha en 0.0.0.0:4000
```

Al arrancar crea las tablas si no existen y, **si la base está vacía, corre el seed automáticamente**. Después:

- API: `http://localhost:4000/api/v1`
- Salud: `http://localhost:4000/health` (también en `/api/v1/health`)
- Panel admin: `http://localhost:4000/admin` (sirve la carpeta hermana `../admin`; `/` redirige ahí)
- WebSocket: `ws://localhost:4000/ws?token=<jwt>`
- Fotos subidas: `http://localhost:4000/uploads/<archivo>`

| Script | Qué hace |
|---|---|
| `npm run dev` | Servidor con recarga automática |
| `npm run build` | Compila a `dist/` |
| `npm start` | Corre `dist/index.js` (hace falta `npm run build` antes) |
| `npm run seed` | Siembra la base si está vacía. `npm run seed -- --reset` la borra y la recrea |
| `npm test` | Tests (`node:test`): flujo feliz end-to-end, score, transiciones y permisos |
| `npm run typecheck` | Chequeo de tipos sin emitir |

Requiere Node 24 (usa `node:sqlite`, que imprime un `ExperimentalWarning` inofensivo al arrancar).

## Variables de entorno

Copiá `.env.example` a `.env` (se carga solo al arrancar).

| Variable | Default | Descripción |
|---|---|---|
| `PORT` / `HOST` | `4000` / `0.0.0.0` | Dónde escucha. `0.0.0.0` permite que el celular lo alcance por la red local |
| `JWT_SECRET` | valor de desarrollo | Secreto para firmar los tokens. Cambialo fuera de la demo |
| `DB_PATH` | `./data/fixi.db` | Archivo SQLite |
| `PUBLIC_BASE_URL` | vacío | URL pública del server. Si está vacía se deduce del header `Host` de cada request (ideal para demo en LAN) |
| `PAYMENT_PROVIDER` | `mock` | `mock` o `mercadopago` |
| `COMMISSION_PERCENT` | `5` | Comisión de Fixi. `commission = round(price × %)`, `techNet = price − commission` |
| `MP_ACCESS_TOKEN`, `MP_CLIENT_ID`, `MP_CLIENT_SECRET`, `MP_WEBHOOK_SECRET` | vacío | Credenciales de Mercado Pago |
| `MP_SANDBOX` | `false` | Usar `sandbox_init_point` |
| `MP_AUTH_URL` | `https://auth.mercadopago.com.ar` | Dominio OAuth |

## Credenciales de demo

Contraseña común para **todas** las cuentas del seed: **`fixi1234`**

| Rol | Email | Quién es |
|---|---|---|
| Cliente demo | `cliente@fixi.app` | Martina Gómez (Palermo). Tiene una necesidad abierta con 3 ofertas para comparar, un trabajo en camino y otro en disputa |
| Técnico demo | `tecnico@fixi.app` | Diego Fernández (Almagro), nivel oro, PC/notebooks y redes |
| Admin | `admin@fixi.app` | Panel `/admin` |

Otros clientes: `julian.rios@`, `carolina.benitez@`, `sebastian.acosta@` + `fixi.demo`. Otros técnicos (todos `@fixi.demo`): `lucas.pereyra`, `gustavo.molina` (platino), `romina.salvatierra`, `nicolas.aguirre`, `hernan.cabrera`, `ariel.sosa`, `mariano.quiroga`, `federico.luna` (nuevo, sin disponibilidad), `paula.dominguez`, `cristian.barrios`, `walter.gimenez`.

El seed incluye 17 categorías, 12 técnicos en CABA/GBA alrededor del Obelisco, 29 servicios publicados, 7 necesidades abiertas (varias con 2–3 ofertas), 30 trabajos en todos los estados (últimos 30 días para el panel), reseñas, mensajes y notificaciones. Los avatares son `https://i.pravatar.cc/300?u=<id>`.

## Conectar el celular

1. La PC y el celular tienen que estar en la **misma red WiFi**.
2. Averiguá la IP de la PC: al arrancar el server imprime las URLs (`Red: http://192.168.x.x:4000`). También con `ipconfig` en Windows (buscá "Dirección IPv4" del adaptador WiFi) o `ip addr` / `ifconfig` en Linux/Mac.
3. En la app configurá la URL base `http://<ip-de-la-pc>:4000`. Probá abrir `http://<ip>:4000/health` en el navegador del celular.
4. Si no conecta: permití Node.js en el Firewall de Windows para redes privadas (o creá una regla de entrada para el puerto 4000).

El link de pago (`checkoutUrl`) se arma con el mismo host con el que el celular le habló al server, así que abre bien en el navegador del teléfono.

## Pagos

Interfaz `PaymentProvider` (`src/payments/`), elegida por `PAYMENT_PROVIDER`.

### `mock` (default)
`POST /jobs/:id/pay` devuelve un `checkoutUrl` a `GET /pay/mock/:paymentId`: una página HTML mobile-first con la marca Fixi que muestra el detalle y botones **Aprobar / Rechazar**. Los botones llaman a `POST /api/v1/payments/webhook/mock` con `{ paymentId, status: "approved" | "rejected" }` y la página muestra "Pago aprobado, ya podés volver a la app". La vinculación de cuenta del técnico (`/payments/connect/url`) también está simulada.

### `mercadopago` (Checkout Pro, marketplace)
Implementado con `fetch` contra la API REST (sin SDK) en `src/payments/mercadopago.ts`. **No se pudo probar sin credenciales reales**: revisalo con cuentas de prueba antes de salir a producción.

Configuración:

1. Creá una aplicación en <https://www.mercadopago.com.ar/developers/panel> (modelo *Marketplace / Checkout Pro*). De ahí salen `MP_CLIENT_ID`, `MP_CLIENT_SECRET` y el `MP_ACCESS_TOKEN` de la aplicación.
2. En la aplicación, cargá como **Redirect URL** de OAuth: `<PUBLIC_BASE_URL>/api/v1/payments/connect/callback`.
3. En *Webhooks* configurá el evento **Pagos** (la URL de notificación ya va dentro de cada preferencia; igual el secreto sirve para validar la firma) y copiá la clave a `MP_WEBHOOK_SECRET`.
4. `PUBLIC_BASE_URL` tiene que ser **HTTPS y accesible desde internet** (ngrok, Cloudflare Tunnel, un VPS…). En LAN Mercado Pago no puede avisar al webhook.
5. `.env`: `PAYMENT_PROVIDER=mercadopago` y las variables anteriores.

Flujo: el técnico llama a `GET /payments/connect/url` → abre la URL de autorización → Mercado Pago redirige a `/payments/connect/callback?code&state` → el server canjea el `code` y guarda `access_token`, `refresh_token`, `user_id` del técnico (con renovación automática). Al pagar se crea una preferencia con **el token del técnico**, `marketplace_fee = commission`, `external_reference = paymentId` y `notification_url`. El webhook consulta `GET /v1/payments/:id`, valida `x-signature` si hay `MP_WEBHOOK_SECRET` y actualiza el estado.

Limitación conocida (ya señalada en la arquitectura): con el split estándar el dinero llega al técnico al aprobarse el pago, no al confirmarse el trabajo; el estado `held` es lógico en Fixi.

## Puntos y niveles

+20 por trabajo completado, +5 si el técnico llegó dentro del ETA prometido (tiempo entre `on_the_way` e `in_progress` ≤ `etaMinutes`), y +10 × (estrellas − 3) por cada reseña recibida. Nunca baja de 0. Niveles: bronce 0+, plata 200+, oro 600+, platino 1500+. Los datos históricos del seed (rating, trabajos, puntos) están cargados directamente en el perfil.

## Diferencias con el contrato

Todo lo agregado es retrocompatible (solo campos o rutas nuevas):

- **`POST /api/v1/uploads`** (multipart, un campo `file` de imagen JPG/PNG/WEBP/HEIC, máx. 8 MB, requiere login) → `{ url }` absoluta. Los archivos quedan en `server/uploads/` y se sirven en `/uploads/`.
- **`/health`** responde también en la raíz (`/health`), además de `/api/v1/health`.
- **Respuestas de creación** usan HTTP 201 (`POST /requests`, `/offers`, `/listings`, `/auth/register`, `/jobs/:id/pay`, `/jobs/:id/messages`, `/jobs/:id/review`, `/offers/:id/accept`, `/listings/:id/book`). Formas: `{ request }`, `{ offer }`, `{ listing }`, `{ job }`, `{ message }`, `{ review }`, `{ payment, checkoutUrl }`. `PATCH /listings/:id` → `{ listing }`; `PUT /me/tech-profile` → `{ user, techProfile }` (igual que `/me`); `POST /jobs/:id/status` → `{ job }` (con `client` y `tech`).
- **Badges**: cada oferta/servicio trae `badge` (el principal: `best` si es el mejor, si no el primero de los otros) y `badges[]` (todos los que gana). Con un único elemento no hay badges. Para ofertas/servicios sin distancia (usuario sin ubicación) la cercanía es neutra.
- `GET /requests/:id`: para el dueño incluye `offers` enriquecidas (`tech`, `distanceKm`, `score`, `badge`, `badges`), `bestOfferId` y `jobId`; para un técnico incluye `distanceKm` y `myOffer`. `GET /requests/nearby` agrega `distanceKm` y `myOfferId`. `request.client` = `{ id, name, avatarUrl }`.
- `GET /jobs` y `GET /jobs/:id`: cada job trae `client` `{ id, name, avatarUrl, phone }` y `tech` (TechCard). El detalle suma `payment`, `myReview` y `reviewReceived`. El job tiene además `notes` y `scheduledAt` (reservas de servicios).
- `GET /techs/:userId`: cada reseña trae `from` `{ id, name, avatarUrl }`.
- `GET /notifications` → `{ items, unreadCount }`. `POST /notifications/read-all` → `{ ok: true }`.
- `GET /admin/stats` → `{ users, technicians, clients, jobsTotal, jobsByStatus, gmv, commissionEarned, commissionPending, openRequests, disputes, series: [{ date, jobs, gmv, commission, newUsers }] }` (30 días). GMV = suma de `price` de trabajos con pago `held` o `released`; `commissionEarned` = solo liberados.
- `GET /admin/users` acepta `?q=&role=client|tech|admin`; cada usuario trae `suspended` y `techProfile`. `PATCH /admin/users/:id` acepta `{ verified?, suspended?, name? }`. Los usuarios suspendidos no pueden iniciar sesión ni usar tokens ya emitidos.
- Categorías: `id = "c_<slug>"` (ej. `c_pc-notebooks`).
- `GET /payments/:id` → `{ payment, job }`. `GET /payments/connect/url` → `{ url, provider, connected }`. `GET /payments/connect/callback` devuelve una página HTML.
- Webhook mock: `POST /payments/webhook/mock` con `{ paymentId, status: "approved"|"rejected" }` (sin autenticación, solo existe para el checkout simulado: no usar `PAYMENT_PROVIDER=mock` en producción).
- Cancelar un trabajo pagado (`paid`/`on_the_way`) marca el pago como `refunded`; `POST /admin/jobs/:id/resolve` con `refund` hace lo mismo, con `release` completa el trabajo y suma los puntos.
- WebSocket: además de los tipos del contrato el server envía `hello` al conectar, y responde `pong` a un texto `ping`. Cierra con código `4401` si el token es inválido.
- Eventos `request.new` solo a técnicos disponibles, con ubicación cargada (`PATCH /me`), dentro de su radio y con la categoría.
- Códigos de error principales: `VALIDATION_ERROR` (400), `UNAUTHORIZED` (401), `INVALID_CREDENTIALS` (401), `FORBIDDEN` / `FORBIDDEN_TRANSITION` / `NOT_TECHNICIAN` / `NOT_ADMIN` / `ACCOUNT_SUSPENDED` (403), `*_NOT_FOUND` (404), `INVALID_TRANSITION` / `ALREADY_OFFERED` / `ALREADY_REVIEWED` / `EMAIL_TAKEN` (409).

## Estructura

```
src/
  app.ts            construye la app (plugins, errores, rutas, estáticos, WS)
  index.ts          arranque; seed-cli.ts: npm run seed
  db.ts             envoltorio de node:sqlite + migraciones idempotentes
  services.ts       notificaciones, transiciones de Job, aplicación de pagos
  score.ts          score "Mejor opción" y badges
  payments/         PaymentProvider: mock.ts, mercadopago.ts
  routes/           core, marketplace, jobs, payments, admin
  seed.ts           datos de demo
test/               node:test sobre fastify.inject con base temporal
```
