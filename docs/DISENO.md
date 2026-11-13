# Fixi — Sistema de diseño

Guía corta y accionable para app (Flutter), panel web y material gráfico. Los tokens de abajo son la fuente de verdad; el panel (`admin/css/styles.css`) los implementa como variables CSS.

## 1. Principios de marca y voz

**Fixi es el vecino que sabe de todo y te lo explica sin vueltas.** Cercano, claro, confiable.

1. **Claridad antes que decoración.** Cada pantalla responde: ¿dónde estoy?, ¿qué puedo hacer?, ¿qué pasó?
2. **Comparar sin esfuerzo.** Precio, reputación, cercanía y tiempo siempre visibles y en el mismo lugar.
3. **Confianza visible.** Verificación, nivel, reseñas y pago protegido se muestran, no se prometen.
4. **Poco ruido.** Una acción primaria por pantalla, mucho aire, color con intención.
5. **Respeto por el tiempo.** Nada bloquea sin motivo: esqueletos, borradores, deshacer.

**Voz:** español rioplatense, voseo ("elegí", "contanos", "revisá"), frases cortas, sin tecnicismos ni culpa al usuario. Tuteo y "usted" no se usan. Sin signos de exclamación en errores. Máximo un emoji por mensaje, solo en celebraciones.

| Situación | Evitar | Usar |
|---|---|---|
| Vacío (sin ofertas) | "No hay datos" | "Todavía no llegaron ofertas. Los técnicos cercanos ya fueron avisados; suele tardar unos minutos." |
| Vacío (sin trabajos) | "Lista vacía" | "Acá vas a ver tus trabajos. ¿Qué necesitás arreglar hoy?" |
| Error de red | "Error 500" | "No pudimos conectar. Revisá tu internet y probá de nuevo." |
| Error de formulario | "Campo inválido" | "Ingresá un email válido, por ejemplo nombre@correo.com." |
| Error de pago | "Pago rechazado" | "El pago no se completó y no te cobramos nada. Probá con otro medio." |
| Confirmación | "Operación exitosa" | "Listo, el técnico ya sabe que va a ir." |
| Acción destructiva | "¿Está seguro?" | "¿Cancelar el trabajo? Si ya pagaste, te devolvemos el dinero." |
| Deshacer | — | "Oferta retirada. Deshacer" |
| Celebración | — | "¡Trabajo terminado! Contale al técnico cómo te fue." |

## 2. Color

### Tokens base (marca)
| Token | Hex | Uso |
|---|---|---|
| `primary` | `#2F5BFF` | Acción primaria, enlaces, foco |
| `accent` | `#C6F432` | Resaltes, "Mejor opción", detalles; **siempre con texto tinta encima** |
| `success` | `#16B364` | Completado, verificado |
| `warning` | `#FFB020` | Pendiente, atención |
| `error` | `#F04438` | Errores, disputas, destructivo |
| `ink` | `#0E1320` | Texto principal claro, fondo de superficies oscuras elevadas |

### Tema claro
| Token | Hex | Contraste / nota |
|---|---|---|
| `bg` | `#F6F7FB` | Fondo de app |
| `surface` | `#FFFFFF` | Tarjetas |
| `surface-2` | `#EEF0F7` | Campos, hover, zebra |
| `border` | `#E1E4EF` | Divisores (decorativo) |
| `text` | `#0E1320` | 17.5:1 sobre `bg` |
| `text-muted` | `#5A6278` | 5.6:1 sobre `surface` (AA) |
| `primary` | `#2F5BFF` | 5.2:1 con texto blanco (AA) |
| `primary-soft` | `#E6ECFF` | Fondo de chips/seleccionados; texto `#1B3FD6` (7:1) |
| `success-text` | `#0B7A45` | 5.4:1 sobre blanco; fondo `#E3F6EC` |
| `warning-text` | `#8A5A00` | 5.9:1 sobre blanco; fondo `#FFF3D9` |
| `error-text` | `#C4261B` | 5.7:1 sobre blanco; fondo `#FDE8E6` |

### Tema oscuro
| Token | Hex | Contraste / nota |
|---|---|---|
| `bg` | `#0B0F1A` | Fondo |
| `surface` | `#131929` | Tarjetas |
| `surface-2` | `#1B2236` | Campos, hover |
| `border` | `#272F47` | Divisores |
| `text` | `#EEF1FA` | 16:1 sobre `bg` |
| `text-muted` | `#9AA3BD` | 7:1 sobre `surface` |
| `primary` | `#6C8CFF` | 5.9:1 sobre `surface` (enlaces, íconos); botones rellenos: `#2F5BFF` con texto blanco (5.2:1) |
| `primary-soft` | `#1C2757` | Texto `#A9BBFF` (8:1) |
| `success-text` | `#4ADE9A` | fondo `#0F2B20` |
| `warning-text` | `#FFC85C` | fondo `#2E2208` |
| `error-text` | `#FF8A80` | fondo `#341513` |

**Reglas:** el lima nunca lleva texto blanco ni va sobre blanco como texto; el estado nunca se comunica solo con color (ícono + texto); texto normal ≥ 4.5:1, texto grande y componentes ≥ 3:1.

## 3. Tipografía

- **Títulos:** Plus Jakarta Sans (700/800). **Texto y UI:** Inter (400/500/600). Fallback `system-ui, -apple-system, Segoe UI, Roboto, sans-serif`.
- Números de dinero y tablas: `font-variant-numeric: tabular-nums`.

| Estilo | Tamaño / interlineado | Peso | Fuente |
|---|---|---|---|
| Display | 32 / 40 | 800 | Jakarta |
| H1 | 24 / 32 | 800 | Jakarta |
| H2 | 20 / 28 | 700 | Jakarta |
| H3 | 16 / 24 | 700 | Jakarta |
| Cuerpo | 15 / 22 (app 16 / 24) | 400 | Inter |
| Cuerpo-s | 13 / 18 | 400 | Inter |
| Etiqueta | 13 / 16, mayúscula inicial | 600 | Inter |
| Overline | 11 / 14, +0.06em | 600 | Inter |

## 4. Espaciado, radios, elevación

- **Grilla de 4 px.** Escala: 4, 8, 12, 16, 20, 24, 32, 48, 64. Padding de tarjeta 16–24; márgenes de pantalla móvil 16.
- **Radios:** chips/campos 12, botones 14, tarjetas 20, hojas/modales 24, píldoras y avatares 999.
- **Elevación (claro):** `e1` 0 1px 2px rgba(14,19,32,.06); `e2` 0 6px 20px rgba(14,19,32,.08); `e3` 0 16px 48px rgba(14,19,32,.16) (modales). En oscuro se reemplaza la sombra por borde `border` + superficie más clara.

## 5. Iconografía

Material Symbols Rounded (peso 400, relleno 0; relleno 1 para estado activo). Tamaños 20 (denso), 24 (estándar), 32 (vacíos). Siempre con etiqueta de texto en navegación; los íconos solos llevan `aria-label` y tooltip. Las categorías guardan el nombre del símbolo en `icon`.

## 6. Movimiento

| Uso | Duración | Curva |
|---|---|---|
| Feedback (press, hover, toggle) | 100–150 ms | `ease-out` |
| Entrada/salida de elementos | 200–240 ms | `cubic-bezier(.2,.8,.2,1)` |
| Hojas y modales | 280–320 ms | `cubic-bezier(.2,.8,.2,1)` |
| Celebraciones | hasta 600 ms | `cubic-bezier(.34,1.56,.64,1)` |

Reglas: se anima opacidad y transform, no layout; respetar `prefers-reduced-motion` (reducir a fundido ≤ 100 ms); nada en loop salvo esqueletos y el pulso de "técnico en camino"; háptica ligera al confirmar, media al pagar.

## 7. Componentes clave

**Tarjeta de oferta comparable.** Avatar + nombre + insignia de nivel + sello verificado; fila de 3 métricas fijas (Precio grande, Llega en X min, Y km) y calificación con cantidad de reseñas. Debajo, mensaje (2 líneas, expandible). Un solo botón primario "Elegir". El precio muestra "Incluye 5% de servicio" en texto pequeño. Las tarjetas en lista conservan el mismo orden de datos para poder escanear en vertical. La de mayor score lleva borde primario y badge "Mejor opción".

**Badges de comparación** (píldora 24 px, ícono + texto): `Mejor opción` (fondo lima, texto tinta), `Más barato` (success), `Más cercano` (primary-soft), `Más rápido` (warning), `Mejor puntuado` (surface-2 con estrella). Máximo 2 por tarjeta; "Mejor opción" siempre primero.

**Insignias de nivel.** Escudo con estrella, color + nombre (nunca solo color):
| Nivel | Puntos | Color |
|---|---|---|
| Bronce | 0+ | `#B8733A` |
| Plata | 200+ | `#8C97AD` |
| Oro | 600+ | `#E0A100` |
| Platino | 1500+ | gradiente `#7FD4FF → #B79CFF` |
Con barra de progreso hacia el siguiente nivel en el perfil del técnico.

**Timeline de trabajo.** Vertical, 6 pasos: Pagado → En camino → En trabajo → Terminado → Confirmado (+ Cancelado/En disputa como ramas). Paso hecho: círculo success con tilde y hora; actual: círculo primario con pulso; futuro: círculo vacío en `border`. Cada paso lleva texto ("El técnico está en camino · 12 min").

**Estado (pill).** Fondo suave + texto del tono `-text` + punto/ícono. Mapa: `pending_payment`/`pending` → warning, `paid`/`held` → primary, `on_the_way`/`in_progress` → primary, `done` → success, `completed`/`released` → success, `cancelled`/`refunded` → neutro, `disputed`/`failed` → error.

**Esqueleto, vacío, error.** Esqueleto con la forma real del contenido (shimmer 1.4 s). Vacío: ícono grande, título, una línea de ayuda y una acción. Error: qué pasó, qué hacer, botón "Reintentar".

## 8. Reglas de UX y calidad de vida

1. **Una acción primaria por pantalla** (botón relleno). El resto, secundarias o texto.
2. **Esqueletos, no spinners**, para toda carga >300 ms; spinner solo dentro de un botón en proceso.
3. **Deshacer antes que confirmar** para acciones reversibles (snackbar 6 s). **Confirmar** (diálogo con consecuencia explícita) solo para irreversibles: reembolsos, liberar pagos, eliminar.
4. **Borradores autoguardados** en formularios largos (necesidad, oferta, servicio); al volver: "Retomamos donde dejaste".
5. **Teclado y foco:** orden lógico, foco visible (anillo 2 px primario + 2 px de separación), `Esc` cierra, atajos documentados en el panel (`/` buscar, `g` + letra navegar, `t` tema).
6. **Accesibilidad:** contraste AA, objetivos táctiles ≥ 48×48 dp (web ≥ 40 px, con separación de 8), tamaño de texto escalable hasta 200 %, etiquetas para lectores de pantalla, estado nunca solo por color, `aria-live` para toasts.
7. **Validación en línea** al salir del campo, mensaje debajo, sin borrar lo escrito.
8. **Dinero y fechas siempre formateados es-AR:** `$ 12.500`, "hoy 14:30", "hace 5 min".
9. **Offline y reintentos:** mostrar último dato conocido con aviso; reintentar con un toque.
10. **Defaults inteligentes:** ubicación actual, última dirección, orden "Mejor opción".

## 9. Lista de chequeo por pantalla

- [ ] ¿Hay una única acción primaria evidente?
- [ ] ¿Tiene estados de carga (esqueleto), vacío y error con salida?
- [ ] ¿Los textos usan voseo, son cortos y dicen qué hacer?
- [ ] ¿Contraste AA en claro y oscuro (texto, íconos, bordes de campos)?
- [ ] ¿El estado se entiende sin color (ícono/texto)?
- [ ] ¿Objetivos táctiles ≥ 48 dp / 40 px y foco visible?
- [ ] ¿Navegable con teclado / lector de pantalla, con etiquetas?
- [ ] ¿Acciones destructivas con confirmación clara o deshacer?
- [ ] ¿Dinero, fechas y distancias en formato es-AR?
- [ ] ¿Respeta `prefers-reduced-motion` y no anima layout?
- [ ] ¿Se ve bien a 360 px y a 1440 px de ancho?
- [ ] ¿Usa solo tokens (sin colores, radios o sombras sueltos)?
- [ ] ¿Funciona con datos faltantes (valores nulos → "—") y textos largos?
