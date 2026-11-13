# Fixi — Arquitectura y contrato de API

Fixi es un marketplace de servicio técnico a domicilio (estilo "Uber de técnicos") para Argentina.
Los clientes publican **necesidades**, los técnicos envían **ofertas** (precio, tiempo de llegada, duración)
y también publican **servicios** con precio. El cliente compara por precio, reputación (puntos), cercanía y
tiempo, elige, paga dentro de la app y Fixi retiene **5% de comisión** que se descuenta al técnico.

Este documento es la **fuente de verdad** entre servidor, app y panel. Si algo cambia, se cambia acá primero.

## Componentes

| Carpeta    | Qué es                                   | Stack |
|------------|------------------------------------------|-------|
| `server/`  | API REST + WebSocket, corre en una PC    | Node 24, TypeScript, Fastify, SQLite, Zod, JWT |
| `app/`     | App Android (APK) para clientes y técnicos | Flutter 3.19 / Dart 3.3, Riverpod, go_router, dio |
| `admin/`   | Panel web de administración (lo sirve el server en `/admin`) | HTML/CSS/JS sin build |
| `docs/`    | Arquitectura, diseño, material comercial y legal | Markdown |

- Servidor: `http://<ip-pc>:4000`. API bajo `/api/v1`. WebSocket en `/ws?token=<jwt>`.
- Base de datos: un archivo SQLite (`server/data/fixi.db`), sin instalar nada extra.
- Sin Docker. Todo arranca con `npm install && npm run dev` en `server/`.

## Convenciones

- JSON, camelCase. Fechas ISO-8601 UTC. IDs string (uuid/nanoid).
- Dinero: **enteros en pesos argentinos (ARS)**, sin decimales. `commission = round(price * 0.05)`, `techNet = price - commission`.
  El porcentaje sale de la variable `COMMISSION_PERCENT` (default 5).
- Auth: `Authorization: Bearer <jwt>`. Login devuelve `{ token, user }`.
- Errores: HTTP 4xx/5xx con `{ "error": { "code": "STRING_CODE", "message": "texto en español para mostrar" } }`.
- Listas: `{ "items": [...] }`.
- Distancias en km (haversine), tiempos en minutos.
- Idioma de toda la UI y mensajes: español rioplatense (vos).

## Modelo de datos

**User** `{ id, name, email, phone, avatarUrl, role: "user"|"admin", isTechnician, lat, lng, address, createdAt }`
Una sola cuenta puede actuar como cliente y como técnico (`isTechnician` se activa al crear el perfil técnico).

**TechProfile** `{ userId, bio, categoryIds[], radiusKm, available, verified, ratingAvg, ratingCount, jobsDone, points, level, paymentsConnected }`
- `level`: `"bronce"` (0+ pts), `"plata"` (200+), `"oro"` (600+), `"platino"` (1500+).
- Puntos: +20 por trabajo completado, +10 × (estrellas − 3) por reseña (5★ = +20, 1★ = −20), +5 si llegó dentro del ETA prometido.

**Category** `{ id, slug, name, icon, group }` — administrables. `icon` = nombre de Material Symbol. Grupos semilla:
Tecnología (PC y notebooks, Celulares y tablets, Redes y WiFi, Consolas, Impresoras), Electrodomésticos (Heladeras,
Lavarropas, Aire acondicionado, TV y audio, Cocinas y hornos), Hogar (Electricista, Plomero, Gasista, Cerrajero, Pintor, Albañil), Otros.

**Request** (necesidad del cliente) `{ id, clientId, categoryId, title, description, photos[], lat, lng, address, budgetMax?, urgency: "now"|"today"|"scheduled", scheduledAt?, status: "open"|"assigned"|"closed"|"cancelled", offersCount, createdAt }`

**Offer** (oferta de un técnico a una necesidad) `{ id, requestId, techId, price, etaMinutes, durationMinutes, message, status: "pending"|"accepted"|"rejected"|"withdrawn", createdAt }`
En respuestas al cliente viene enriquecida: `tech: TechCard`, `distanceKm`, `score`.

**TechCard** `{ userId, name, avatarUrl, ratingAvg, ratingCount, jobsDone, points, level, verified, distanceKm? }`

**Listing** (servicio publicado por un técnico) `{ id, techId, categoryId, title, description, price, priceType: "fixed"|"from"|"hourly", durationMinutes, active, createdAt }` + `tech: TechCard`, `distanceKm`, `etaMinutes` (estimado: 10 + distanceKm × 3), `score`.

**Job** (trabajo contratado) `{ id, requestId?, offerId?, listingId?, clientId, techId, categoryId, title, address, lat, lng, price, commission, techNet, etaMinutes, status, paymentStatus, createdAt, paidAt?, startedAt?, completedAt? }`
- `status`: `"pending_payment"` → `"paid"` → `"on_the_way"` → `"in_progress"` → `"done"` (el técnico marca terminado) → `"completed"` (el cliente confirma; se libera el pago) · además `"cancelled"`, `"disputed"`.
- `paymentStatus`: `"pending"|"held"|"released"|"refunded"`.

**Payment** `{ id, jobId, provider: "mock"|"mercadopago", providerRef, amount, commission, status: "pending"|"approved"|"released"|"refunded"|"failed", checkoutUrl, createdAt }`

**Review** `{ id, jobId, fromUserId, toUserId, rating (1-5), comment, createdAt }` — una por parte por trabajo, solo con job `completed`.

**Message** `{ id, jobId, fromUserId, text, createdAt }` — chat por trabajo.

**Notification** `{ id, userId, type, title, body, data, read, createdAt }`

### Score "Mejor opción"
Para ordenar ofertas y servicios (0–100, mayor es mejor), normalizando dentro del conjunto devuelto:
`score = 35·precio + 30·reputación + 20·cercanía + 15·tiempo`, donde precio = más barato mejor, reputación = `ratingAvg/5` ponderado
por cantidad de reseñas (bayesiano, prior 4.0 con peso 5), cercanía = menor distancia mejor, tiempo = menor ETA mejor.
El de mayor score lleva `badge: "best"`; además se marcan `"cheapest"`, `"closest"`, `"fastest"`, `"top_rated"`.
Parámetro `sort`: `best` (default) | `price` | `distance` | `eta` | `rating`.

## Endpoints (`/api/v1`)

### Auth y perfil
- `POST /auth/register` `{ name, email, password, phone? }` → `{ token, user }`
- `POST /auth/login` `{ email, password }` → `{ token, user }`
- `GET /me` → `{ user, techProfile? }`
- `PATCH /me` `{ name?, phone?, avatarUrl?, lat?, lng?, address? }`
- `PUT /me/tech-profile` `{ bio, categoryIds, radiusKm, available }` → crea/actualiza perfil técnico
- `GET /techs/:userId` → `{ tech: TechCard, profile, listings, reviews }`

### Catálogo
- `GET /categories` → `{ items }`

### Necesidades y ofertas
- `POST /requests` (cliente) · `GET /requests/mine` · `GET /requests/:id` (incluye `offers` enriquecidas si sos el dueño; `?sort=`)
- `POST /requests/:id/cancel`
- `GET /requests/nearby?lat&lng&radiusKm&categoryId?` (técnico: necesidades abiertas cerca, con `distanceKm`)
- `POST /requests/:id/offers` (técnico) `{ price, etaMinutes, durationMinutes, message }`
- `GET /offers/mine` (técnico) · `POST /offers/:id/withdraw`
- `POST /offers/:id/accept` (cliente) → crea Job `pending_payment` → `{ job }`

### Servicios publicados
- `GET /listings?lat&lng&radiusKm&categoryId?&q?&sort?` → cercanos, enriquecidos
- `GET /listings/mine` · `POST /listings` · `PATCH /listings/:id` · `DELETE /listings/:id` (técnico)
- `POST /listings/:id/book` (cliente) `{ address, lat, lng, notes?, scheduledAt? }` → crea Job `pending_payment` → `{ job }`

### Trabajos
- `GET /jobs?role=client|tech&status?` · `GET /jobs/:id` (incluye `client`, `tech: TechCard`, `payment`, `myReview`)
- `POST /jobs/:id/status` `{ status }` — transiciones válidas: técnico `paid→on_the_way→in_progress→done`; cliente `done→completed`; ambos `cancel` antes de `in_progress`; ambos `disputed` desde `in_progress|done`.
- `GET /jobs/:id/messages` · `POST /jobs/:id/messages` `{ text }`
- `POST /jobs/:id/review` `{ rating, comment }`
- `POST /jobs/:id/location` (técnico, en `on_the_way`) `{ lat, lng }` → se reenvía por WS al cliente

### Pagos
- `POST /jobs/:id/pay` → `{ payment, checkoutUrl }` (la app abre `checkoutUrl` en el navegador/webview)
- `GET /payments/:id` → `{ payment }`
- `POST /payments/webhook/:provider` — notificación del proveedor
- `GET /pay/mock/:paymentId` — (solo proveedor mock) página HTML de checkout simulado con botones Aprobar/Rechazar
- `GET /me/earnings` (técnico) → `{ totalNet, pendingNet, commissionPaid, jobs: [...] }`
- `GET /payments/connect/url` (técnico) → `{ url }` para vincular su cuenta de Mercado Pago (OAuth) · `GET /payments/connect/callback`

### Notificaciones
- `GET /notifications` · `POST /notifications/read-all`

### Admin (role admin)
- `GET /admin/stats` → usuarios, técnicos, trabajos por estado, volumen (GMV), comisión ganada, serie diaria de 30 días
- `GET /admin/users` · `PATCH /admin/users/:id` (verificar técnico, suspender)
- `GET /admin/jobs` · `POST /admin/jobs/:id/resolve` `{ outcome: "release"|"refund" }` (disputas)
- `GET/POST/PATCH/DELETE /admin/categories`
- `GET /admin/payments`

### Salud
- `GET /health` → `{ ok: true, version }`

## WebSocket `/ws?token=`
Mensajes servidor → cliente: `{ "type": string, "data": object }`
- `offer.new` (al dueño de la necesidad) · `offer.accepted` / `offer.rejected` (al técnico)
- `request.new` (a técnicos disponibles dentro de su radio y categoría)
- `job.updated` (a ambas partes, con el job completo)
- `message.new` (al otro participante)
- `tech.location` `{ jobId, lat, lng }` (al cliente)
- `notification.new`

## Pagos y comisión

Interfaz `PaymentProvider` en el servidor con dos implementaciones, elegida por `PAYMENT_PROVIDER`:

1. **`mock`** (default, desarrollo y demo): genera un `checkoutUrl` a una página del propio servidor que simula aprobar o rechazar.
2. **`mercadopago`**: Checkout Pro en modo **marketplace** (split de pagos). Cada técnico vincula su cuenta de Mercado Pago por OAuth;
   la preferencia de pago se crea con el access token del técnico y `marketplace_fee = commission`, así Mercado Pago acredita
   el 5% en la cuenta de Fixi y el resto al técnico. Webhook `payment` confirma la aprobación. Variables: `MP_ACCESS_TOKEN`,
   `MP_CLIENT_ID`, `MP_CLIENT_SECRET`, `MP_WEBHOOK_SECRET`, `PUBLIC_BASE_URL`.

Flujo: aceptar oferta / reservar servicio → Job `pending_payment` → `POST /jobs/:id/pay` → checkout → webhook aprueba →
Job `paid`, pago `held` → el técnico trabaja → cliente confirma → Job `completed`, pago `released` → reseñas y puntos.

**Pendiente de decisión (hueco conocido):** con el split estándar de Mercado Pago el dinero se acredita al técnico al aprobarse
el pago, no al confirmarse el trabajo. La retención real ("held") requiere liberar el dinero manualmente o un esquema de
custodia, con implicancias legales e impositivas. Ver `docs/comercial/`.

## Datos de demo
El server trae un seed (`npm run seed`) con categorías, un admin, clientes, ~12 técnicos con ubicaciones en CABA/GBA
(centro de referencia: Obelisco, -34.6037, -58.3816), servicios, necesidades, ofertas, trabajos y reseñas.
Las credenciales de demo se documentan en `server/README.md`.

## Identidad visual (resumen; el detalle vive en `docs/DISENO.md`)
- Marca: **Fixi**. Tono cercano, claro, confiable.
- Color primario: azul eléctrico `#2F5BFF`; acento: lima `#C6F432`; éxito `#16B364`; alerta `#FFB020`; error `#F04438`.
- Neutros: tinta `#0E1320`, superficie clara `#F6F7FB`, superficie oscura `#0B0F1A`.
- Tipografía: Plus Jakarta Sans (títulos) + Inter (texto). Radios 16–24, sombras suaves, mucho aire.
- Modo claro y oscuro. Microinteracciones, esqueletos de carga, estados vacíos ilustrados, háptica.
