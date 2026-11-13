# 01 - Plan de lanzamiento (go-to-market con presupuesto mínimo)

> Documento de estrategia. Fecha de redacción: 13/11/2026. Los hechos con fuente llevan URL; todo lo marcado **[ESTIMACIÓN]** es criterio mío (no un dato verificado) y hay que validarlo con la realidad del primer mes. Los montos en ARS se desactualizan rápido por inflación: recalculá antes de gastar.

## 1. Idea central en una página

1. Un marketplace de dos lados muere por falta de liquidez, no por falta de funciones. La app ya está (`docs/ARQUITECTURA.md`); lo que falta es **gente real de los dos lados en un mismo lugar**.
2. **Empezá por la oferta (técnicos)**, pero con un compromiso: no reclutes más técnicos de los que podés alimentar con trabajo. Un técnico que se registra y no recibe pedidos en 2 semanas no vuelve nunca más.
3. **Lanzá hiperlocal**: 1 a 2 barrios contiguos y 2 a 3 rubros ancla. Cuando 3 de cada 4 pedidos reciben al menos una oferta en menos de 30 minutos, recién ahí abrís otra zona o rubro.
4. Para el primer mes vas a **ser el "concierge"** del servicio: vos mismo, por WhatsApp, te asegurás de que cada pedido tenga ofertas. Es manual y no escala, pero te enseña todo lo que la app todavía no sabe.
5. Todo el crecimiento inicial es gratis o casi: grupos barriales, administradores de consorcio, ferreterías, referidos y volantes con QR.

## 2. Por qué empezar por la oferta

| Argumento | Detalle |
|---|---|
| El cliente se va rápido si no hay ofertas | Quien publica una necesidad y no recibe respuesta en minutos prueba otra cosa (WhatsApp, Mercado Libre, un conocido). La primera experiencia define la recompra. |
| Los técnicos son un grupo chico y reclutable | En un barrio hay decenas, no miles. Se los puede conocer cara a cara (ferreterías, casas de repuestos). |
| Los técnicos ya compran herramientas de reputación | Un perfil con reseñas verificadas y puntos es un activo propio; eso es un gancho real. |
| El riesgo | Si juntás 50 técnicos y 5 clientes, los técnicos se frustran. Por eso: reclutamiento **escalonado** y compromiso de trabajo (ver sección 5). |

Regla práctica **[ESTIMACIÓN]**: en la zona ancla, apuntá a una relación de 1 técnico activo cada 4 a 6 clientes potenciales por mes (cada técnico necesita 8 a 15 trabajos por mes por plataforma para que la app le importe).

## 3. Elección de zona y rubros ancla

### 3.1 Criterios para elegir zona (1 a 2 barrios contiguos)

- **Densidad de departamentos y consorcios** (muchos pedidos chicos y recurrentes en poco espacio).
- Poder adquisitivo medio o medio-alto (aceptan pagar por app y valoran comparar ofertas).
- Donde ya vivís o conocés gente: la confianza y el boca a boca son tu único presupuesto.
- Buena conectividad de transporte para que los técnicos lleguen rápido (el tiempo de llegada es parte del score).
- El seed de la app usa CABA/GBA con centro en el Obelisco; es coherente empezar por ahí. **Tu zona real la decidís vos** (ver preguntas abiertas en el README).

Ejemplos de tipo de zona **[ESTIMACIÓN]**: Caballito / Almagro / Villa Crespo / Palermo en CABA; o un partido del GBA con alta densidad de PH y casas (Vicente López, San Martín, Lanús, Quilmes) si conocés mejor esa zona. Elegí por tu red de contactos, no por teoría.

### 3.2 Rubros ancla (2 a 3)

| Rubro | A favor | En contra | Veredicto |
|---|---|---|---|
| Electricista | Pedido muy frecuente, urgencia, ticket medio | Hay normativa de matrícula según la jurisdicción (ver doc 04) | **Ancla**, con verificación |
| Plomero | Altísima urgencia (pérdidas), recurrente, mucha informalidad | Trabajos de duración incierta, disputas sobre materiales | **Ancla** |
| Aire acondicionado (service, carga, instalación) | **Estacionalidad**: el lanzamiento cae en pleno verano (nov-feb); ticket alto, ya se cotiza | Requiere técnicos con herramientas específicas; picos de demanda saturan a los técnicos | **Ancla estacional** |
| PC / notebooks / WiFi | Bajo riesgo físico, ticket medio, buen contenido para Instagram/TikTok | Compite con locales de reparación; mucho se resuelve remoto | **Ancla opcional** (si tenés técnicos de confianza) |
| Gasista | Alto ticket | Matrícula obligatoria y responsabilidad por seguridad; riesgo mayor | **Dejar para la fase 2**, solo matriculados verificados |
| Cerrajero | Urgencia y frecuencia | Rubro con historial de estafas y de entrada a domicilios ajenos; requiere control fuerte de identidad del cliente | **Dejar para después** (ver doc 04) |
| Electrodomésticos (heladeras, lavarropas) | Ticket alto, técnicos especializados | Repuestos y visitas de diagnóstico complican el precio cerrado | Fase 2 |

Recomendación: **Electricista + Plomero + Aire acondicionado** para los primeros 90 días. Son los que más se pueden vender a un consorcio y más se pagan.

## 4. Primeros 50 técnicos

Meta: **50 técnicos activos** en la zona ancla a los 90 días. "Activo" = tiene perfil verificado, categoría y radio cargados y respondió al menos una necesidad en los últimos 14 días. **[ESTIMACIÓN]**: para llegar a 50 activos vas a tener que contactar a unos 250 a 400 (tasa realista de conversión de contacto frío a alta activa, 12 a 20%).

### 4.1 Canales de reclutamiento (ordenados por rendimiento esperado)

1. **Ferreterías y casas de electricidad/sanitarios/refrigeración de la zona.** Es donde los técnicos compran todos los días. Hablá con el dueño o el mostrador, pedí dejar un cartel/QR en el mostrador y un flyer en la bolsa. El dueño es además una fuente de referidos ("¿a quién le recomendás para…?"). Llevá el material impreso y un caramelo: invitá a que él mismo se sume como "referente".
2. **Casas de repuestos de aire acondicionado y electrodomésticos** y distribuidores de materiales eléctricos.
3. **Grupos de Facebook y WhatsApp de oficios** ("electricistas de zona norte", "plomeros y gasistas de CABA", grupos de herreros, etc.). Reglas: leé las normas del grupo, no spamees; pedí permiso al administrador y ofrecé algo concreto ("Armo una app para que los técnicos de [barrio] reciban pedidos sin pagar nada los primeros meses, ¿puedo contarles?").
4. **Grupos de vecinos de barrio** buscando "alguien de confianza para...": podés ofrecerte a conectar al vecino con técnicos de la app (te sirve de lado cliente y lado oferta).
5. **Referidos entre técnicos** (bono; ver doc 02).
6. **Cursos y escuelas técnicas** (CFP, escuelas de oficios): alumnos avanzados y egresados recientes necesitan clientes.
7. **Sindicatos o cámaras de pequeñas empresas del oficio**: lento, pero da legitimidad **[ESTIMACIÓN]**.
8. **Mercado Libre / Marketplace / Instagram de técnicos independientes** que ya publican servicios: contacto directo por mensaje (ver guion en doc 02).

### 4.2 Embudo y reglas

- Semanas 1-2: **15 técnicos "fundadores"** (los de máxima confianza, que conocés o recomendados). Con ellos probás todo.
- Semanas 3-6: crecer hasta 35, **solo si** el tiempo hasta la primera oferta en los pedidos sigue bajo (ver métricas).
- Semanas 7-12: llegar a 50 y empezar a **rechazar o poner en lista de espera** técnicos de rubros saturados.
- **Compromiso con ellos**: decile a cada técnico la verdad: "Estoy arrancando; te prometo X pedidos por semana en tu rubro/zona, y en el peor caso te los traigo yo". Esto lo vas a poder cumplir si vos mismo activás la demanda (sección 6).

## 5. Primeros 200 clientes

Meta: **200 clientes que completaron al menos un trabajo** (no registrados: que pagaron y confirmaron). **[ESTIMACIÓN]**: si 1 de cada 3 pedidos publicados llega a trabajo completado y 1 de cada 3 registros publica un pedido, necesitás unos 1.800 registros o contactos cualificados para llegar a 200. Ajustá con datos reales; es probable que los primeros 200 salgan más de **contacto directo** (consorcios, grupos, referidos) que de publicidad pagada.

### 5.1 Canales concretos para clientes

1. **Administradores de consorcios y edificios.** Un administrador gestiona 10 a 100 edificios y llama a técnicos todo el tiempo. Ofrecé: "Te consigo 3 ofertas comparables en menos de 1 hora para cualquier reparación del edificio". Una sola alianza con un administrador puede valer decenas de trabajos. Dejale el QR en los pasillos de los edificios (con su permiso).
2. **Grupos de WhatsApp y Facebook barriales** ("Vecinos de Caballito", "Compro y vendo Palermo"). Publicá casos reales: "Hoy un vecino de Villa Crespo recibió 4 ofertas para cambiar una llave térmica en 12 minutos". Con permiso del admin, y sin spamear.
3. **Referidos entre clientes**: crédito o descuento en el próximo trabajo. Condición: se activa recién cuando el referido **completa** un trabajo.
4. **Volanteo con QR** en zonas de alta densidad (portería, buzones con permiso, locales amigos: ferreterías, kioscos, peluquerías, gimnasios). El QR lleva a una página con la descarga y un código de barrio.
5. **Google Business Profile** de Fixi (ficha gratuita con categoría de servicios) y fichas por zona; pedí reseñas a los primeros clientes. Es gratis y capta la búsqueda "plomero cerca de mí".
6. **Instagram / TikTok**: contenido corto y útil (3 señales de que tu instalación eléctrica es peligrosa, qué hacer ante una pérdida, cuánto sale un service de aire en tu barrio con precios reales de ofertas). Mostrá técnicos reales (con permiso) y **precios reales**. Presupuesto cero: grabá con el celular.
7. **Alianzas con inmobiliarias** y administradoras de alquiler temporal (cambios de inquilino, arreglos entre contratos). Muchas hacen decenas de arreglos mensuales.
8. **Comercios del barrio** con QR en mostrador (ferreterías, supermercados chinos, kioscos) a cambio de listarlos como "comercio amigo".

### 5.2 La promesa de marca para el cliente

"Publicás qué necesitás y recibís ofertas de técnicos verificados de tu barrio, con precio y hora de llegada; pagás en la app y el técnico cobra recién cuando confirmás." (La última parte depende de la decisión sobre retención de pagos; ver doc 03. No la prometas en publicidad hasta tener claro cómo se cumple.)

## 6. Lado cliente: cómo evitar el "pedido sin ofertas"

- **Modo concierge**: durante los primeros 60 días, cada pedido publicado lo mirás vos. Si pasaron 10 minutos sin ofertas, mensaje directo a 3 técnicos del rubro y zona.
- **Garantía de respuesta**: "Si en 30 minutos no tenés una oferta, te escribimos nosotros". Es una promesa que podés cumplir manualmente.
- **Pedidos de práctica**: pedí a amigos y familiares publicar necesidades reales (no falsas) para que los técnicos reciban actividad real en la semana 1-2.

## 7. Calendario de 90 días, semana a semana

Supuesto de inicio: lunes 23/11/2026 (Semana 1). Fin: 21/2/2027. **[ESTIMACIÓN]**: en CABA enero baja la demanda de algunos rubros por vacaciones y sube la de aire acondicionado; no te asustes por la caída de pedidos de algunos rubros.

| Semana | Foco | Acciones concretas | Meta de la semana |
|---|---|---|---|
| 1 (23/11) | **Decisiones previas** | Cerrar nombre y marca (doc 04); decidir modelo de pago con MP (doc 03); alta de monotributo/SAS con contador; zona y rubros; armar landing y QR; grabar 3 videos cortos | Decisiones tomadas |
| 2 (30/11) | **Fundadores** | Hablar con 40 técnicos conocidos/recomendados; recorrer 10 ferreterías; alta de 15 técnicos verificados (DNI, matrícula, antecedentes) | 15 técnicos verificados |
| 3 (7/12) | **Beta cerrada** | 20 pedidos "semilla" de amigos/familia/vecinos con técnicos reales. Vos monitoreás cada uno. Corregís bugs. | 20 trabajos completados |
| 4 (14/12) | **Primer ciclo completo** | Pagos reales (con MP en producción), reseñas, soporte por WhatsApp; entrevistar a 10 clientes y 10 técnicos | 20 trabajos más; NPS cualitativo |
| 5 (21/12) | **Aperturas barriales** | Primer grupo vecinal (publicación aprobada); primer administrador de consorcio; 1 inmobiliaria | 10 pedidos orgánicos |
| 6 (28/12) | **Fiestas** | Baja natural; foco en contenido y reclutar técnicos de aire acondicionado | +8 técnicos |
| 7 (4/1) | **Volanteo QR** | Primera tirada de 500 volantes en portería/locales; Google Business con las primeras reseñas | 25 pedidos publicados/sem. |
| 8 (11/1) | **Referidos** | Activar bonos de referido (técnico y cliente) | 10% de pedidos vía referido |
| 9 (18/1) | **Segundo rubro fuerte** | Campaña "service de aire antes de que llegue el pico" con precios reales | 30 pedidos/sem. |
| 10 (25/1) | **Consorcios** | 3 administradores activos; propuesta de "cuenta de edificio" | 40 pedidos/sem. |
| 11 (1/2) | **Retención** | Pedir recompra; recordatorio de service anual; mensajes a técnicos inactivos | Recompra a 30 días > 20% |
| 12 (8/2) | **Medición profunda** | Calcular todas las métricas de la sección 9; revisar fuga fuera de la app | Informe de métricas |
| 13 (15/2) | **Decisión de expansión** | Si se cumplen los umbrales: abrir barrio/rubro; si no: segunda iteración de la zona | Decisión go/no-go |

## 8. Presupuesto estimado (ARS) por escenarios

**[ESTIMACIÓN]** en pesos de noviembre de 2026. Excepto donde hay fuente, los precios son órdenes de magnitud, no cotizaciones; pedí presupuesto real a imprentas, etc. Siempre sumá el monotributo (o los costos de la sociedad) y la marca; esos dos están acá como línea aparte porque son costos casi seguros.

### 8.1 Costos casi seguros (cualquier escenario)

| Concepto | Monto aproximado | Fuente / nota |
|---|---|---|
| Registro de marca INPI (por clase) | $216.000 + IVA por clase | https://www.iprofesional.com/legales/450840-como-saber-si-una-marca-ya-esta-registrada-en-el-inpi-guia-practica-para-emprendedores (verificar en INPI). Mínimo 2 clases: 35 y 42 (ver doc 04) = $432.000 + IVA. |
| Monotributo mensual (categorías de ejemplo, servicios, escala desde 1/8/2026) | A: $49.527; B: $56.379; C: $66.020 | https://hacecuentas.com/datos-monotributo-2026 (fuente secundaria; confirmar en ARCA) |
| Cuenta de desarrollador de Google Play | USD 25 pago único | Dato de mi conocimiento, no re-verificado en esta sesión. |
| Servidor / hosting estable | $20.000-$60.000 por mes **[ESTIMACIÓN]** | El diseño actual corre en una PC propia: un VPS pequeño o similar es más seguro (ver doc 04, datos personales). |

### 8.2 Tres escenarios para 90 días (sin contar los costos casi seguros)

| Línea | Cero | Bajo | Medio |
|---|---|---|---|
| Impresión de volantes/carteles QR (1.000 a 5.000 u.) | $0 (solo cartelería manuscrita y WhatsApp) | $60.000-$120.000 | $200.000-$350.000 |
| Stickers/imanes con QR para técnicos | $0 | $50.000-$100.000 | $150.000-$250.000 |
| Publicidad paga (Meta / Google, a nivel barrio) | $0 | $150.000-$300.000 | $600.000-$1.200.000 |
| Bonos de referidos y créditos de bienvenida (se pagan solo si se cumple el trabajo) | $0-$80.000 | $200.000-$400.000 | $600.000-$1.000.000 |
| Creatividades (videos, fotos) | $0 (celular) | $0-$100.000 | $200.000-$400.000 |
| Subsidio de "primeros trabajos" (el costo es lo que dejás de ganar por comisión 0%) | no es un gasto, es un costo de oportunidad | idem | idem |
| Eventos / invitaciones a técnicos (cafés, charla en ferretería) | $0-$30.000 | $50.000-$100.000 | $200.000-$300.000 |
| **Total variable aproximado (90 días)** | **$0 a $110.000** | **$510.000 a $1.120.000** | **$1.950.000 a $3.500.000** |
| Resultado esperado **[ESTIMACIÓN]** | 15-35 técnicos, 60-150 clientes completados si hacés todo el trabajo manual vos | 35-50 técnicos, 150-300 clientes | 50+ técnicos, 300-600 clientes, más rápido pero con más riesgo de gastar sin retención |

Regla de oro: **no pases del escenario cero al bajo hasta que haya retención de clientes** (recompra > 20% a 30 días); pagar por ver gente que no vuelve es el error típico.

## 9. Métricas a seguir

Se calculan semanalmente, por zona y por rubro. Los umbrales son **[ESTIMACIÓN]**; sirven como punto de partida y los vas a ajustar con datos.

| Métrica | Definición | Umbral "va bien" | Umbral de alerta |
|---|---|---|---|
| **Liquidez de oferta** | % de pedidos publicados que reciben ≥ 1 oferta | ≥ 80% | < 60% |
| **Tiempo a primera oferta** (mediana) | Minutos entre `Request.createdAt` y primera `Offer.createdAt` | ≤ 20 min (urgencia "now": ≤ 10 min) | > 45 min |
| **Ofertas por pedido** | Promedio de `offersCount` | 3 a 5 | < 2 |
| **Conversión pedido → trabajo** | % de pedidos que terminan en `Job` pagado | ≥ 35% | < 20% |
| **Conversión trabajo pagado → completado** | % de `Job` que llega a `completed` | ≥ 90% | < 80% |
| **Recompra a 30/60 días** | % de clientes que contratan de nuevo | ≥ 20% a 30 días | < 10% |
| **Actividad de técnicos** | % de técnicos con ≥ 1 oferta en 14 días | ≥ 70% | < 40% |
| **Trabajos por técnico por mes** | Promedio | ≥ 6 a 8 | < 3 |
| **Reseñas promedio** | `ratingAvg` | ≥ 4,5 | < 4,2 |
| **Disputas** | % de trabajos en `disputed` | ≤ 3% | > 8% |
| **Fuga fuera de la plataforma** | Ver abajo | < 10% | > 25% |
| **CAC y payback** | Gasto de adquisición / cliente; ingreso por comisión acumulado | CAC < comisión de 3 trabajos | CAC > comisión de 8 trabajos |

### Cómo medir la fuga (desintermediación)

La fuga es el problema oculto de los marketplaces de servicios. Señales concretas:
- Técnicos con muchas ofertas aceptadas pero pocos `Job` pagados.
- Chats con números de teléfono o frases como "hablame por WhatsApp" (detección simple por regex).
- Clientes que publican de nuevo la misma necesidad con el mismo técnico.
- Encuesta de 1 pregunta al cliente a los 7 días: "¿Volviste a contratar a este técnico por fuera de Fixi?" (anónima).
- Meta: **menos de 10% de trabajos repetidos fuera de la app** a los 90 días. Las contramedidas están en el doc 02.

## 10. Umbrales para expandir

Abrí un **nuevo barrio** o **nuevo rubro** solo cuando, durante **3 semanas seguidas**, en la zona/rubro actual:

1. Liquidez de oferta ≥ 80% y tiempo a primera oferta ≤ 20 min.
2. ≥ 100 pedidos/mes en la zona (≥ 25/semana).
3. Recompra a 30 días ≥ 20% y reseñas ≥ 4,5.
4. Fuga estimada < 10%.
5. Disputas ≤ 3% y 0 incidentes de seguridad graves.
6. Tenés cobertura de soporte (vos o alguien) para el volumen nuevo, con al menos 1 persona de respaldo.
7. Los pagos y los impuestos están resueltos con tu contador (no expandas con deuda fiscal acumulada).

Si no se cumplen: **profundizá** (más técnicos en rubros con ofertas faltantes, mejor onboarding, más referidos) en la misma zona. Expandir con mala liquidez multiplica el problema.

## 11. Qué no sabemos todavía (hay que medir)

- Ticket promedio real por rubro y zona (usé ejemplos del doc 03).
- Cuántos técnicos aceptan pagar por app en vez de cobrar en efectivo.
- Si los clientes prefieren comparar ofertas o elegir el servicio publicado.
- Si hay algún competidor local fuerte en la zona que elijas; el relevamiento de competidores del doc 02 está basado en búsquedas web, no en pruebas de campo.
- La viabilidad del "pago retenido" (doc 03).

## Fuentes citadas en este documento

- https://www.iprofesional.com/legales/450840-como-saber-si-una-marca-ya-esta-registrada-en-el-inpi-guia-practica-para-emprendedores
- https://hacecuentas.com/datos-monotributo-2026
- Marco de la app: `docs/ARQUITECTURA.md`
