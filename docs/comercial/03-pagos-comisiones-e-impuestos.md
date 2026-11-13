# 03 - Pagos, comisiones e impuestos

> **No es asesoramiento contable ni legal.** Todo lo marcado **[CONTADOR]** o **[ABOGADO]** lo tiene que confirmar un profesional matriculado antes de operar. Hechos con fuente llevan URL; **[ESTIMACIÓN]** es criterio mío; **[NO VERIFICADO]** es algo que busqué y no pude confirmar. Fecha: 13/11/2026.

## 1. Resumen ejecutivo (leer primero)

1. **Mercado Pago ofrece "Split de Pagos 1:1" (marketplace) en Argentina** (https://www.mercadopago.com.ar/developers/en/docs/split-payments/landing). Con Checkout Pro se usa `marketplace_fee` en la preferencia, y con Checkout API `application_fee` (https://www.mercadopago.com.ar/developers/es/docs/split-payments/split-1-1/integration-configuration/integrate-marketplace).
2. **El costo de procesamiento de MP lo paga el técnico (vendedor)**; MP lo descuenta primero y la comisión de Fixi se aplica sobre el saldo restante (misma fuente).
3. **La documentación pública que pude leer NO dice que se pueda retener el dinero hasta que el cliente confirme el trabajo.** No documenta contracargos ni plazos de liberación para split. Es el hueco que `docs/ARQUITECTURA.md` ya marca. **Tenés que preguntarle a Mercado Pago (soporte de developers/ejecutivo comercial) antes de prometer "pago retenido" a cualquiera.** Ver sección 4: hay alternativas que no dependen de eso.
4. La misma página dice que en split 1:1 **"solo se permiten pagos con dinero en cuenta entre cuentas de Mercado Pago. No se aceptan transferencias desde instituciones financieras externas."** No pude determinar si esto limita el uso de tarjetas (el resumen que obtuve es ambiguo). **[NO VERIFICADO]**: confirmá con MP qué medios de pago admite el split en Argentina; si excluye tarjetas, cambia toda la economía de conversión.
5. Con 5% de comisión y un ticket de ~$55.000, Fixi gana ~$2.750 brutos por trabajo; **se necesitan cientos de trabajos por mes** para que sea un ingreso relevante (sección 6).
6. Impuestos: el esquema más simple para empezar es que **solo la comisión sea ingreso de Fixi** (split), no el total del trabajo. Eso hay que confirmarlo con contador, y define si alcanza el monotributo (sección 7).

## 2. Cómo funciona el split de Mercado Pago (lo verificado)

Fuente principal: https://www.mercadopago.com.ar/developers/es/docs/split-payments/split-1-1/integration-configuration/integrate-marketplace

| Tema | Lo que dice la documentación |
|---|---|
| Modelo | Split 1:1: un pago, un vendedor, y se divide entre el vendedor y el marketplace. El reparto es automático. |
| Productos | Se puede integrar **Checkout Pro** o **Checkout API**. |
| OAuth | "Obtén el `access_token` de cada vendedor mediante OAuth." Cada técnico debe **vincular su cuenta de Mercado Pago** (la app ya contempla `GET /payments/connect/url` y `/callback`). |
| Credenciales | En el frontend, la `public_key` de la cuenta integradora (la de Fixi). En el backend, el `access_token` **del vendedor**. |
| Comisión del marketplace | Checkout Pro: parámetro `marketplace_fee` en `/checkout/preferences`. Checkout API: `application_fee` en `/payments`. La documentación en español muestra un valor (monto) como `10`; la página usa a veces la palabra "porcentaje". **[A CONFIRMAR]** si es monto fijo en ARS (lo más probable por los ejemplos): en ese caso el servidor calcula `round(price x 0.05)` como ya está en `ARQUITECTURA.md`. |
| Orden de descuentos | "La comisión de Mercado Pago se descuenta de los fondos recibidos por el vendedor": primero MP, luego la del marketplace sobre el saldo restante. |
| Reembolsos | El importe a devolver se resta de las cuentas del vendedor y del marketplace **proporcionalmente**. En modelos 1:1, "si el vendedor no tiene saldo, el marketplace no puede reembolsar el total": debe devolver su parte y ver cómo devolver el resto "bajo responsabilidad del vendedor". |
| Medios de pago | La página indica "solo dinero en cuenta entre cuentas de Mercado Pago" (ver punto 4 del resumen; **ambiguo**, confirmar). |
| Requisitos previos | La página menciona una sección de "Prerequisites" que no pude leer. **[NO VERIFICADO]** si hay homologación o contacto comercial obligatorio. |
| Contracargos | **No tratados** en las páginas que leí. |
| Liberación / retención | **No tratada.** |

### Qué tiene que hacer el técnico y qué tiene que hacer Fixi

- **Técnico**: tener una cuenta de Mercado Pago (de persona humana con CUIL/CUIT; mejor con monotributo y CBU asociado) y autorizar la app por OAuth. Si no la vincula, no puede cobrar (`paymentsConnected` en `TechProfile`).
- **Fixi**: crear una **aplicación en el panel de developers de MP**, obtener `client_id`/`client_secret`, implementar el flujo OAuth, guardar y **renovar** los tokens de cada técnico (**[NO VERIFICADO]** la duración exacta de los tokens y del refresh token en Argentina; verificalo en la documentación de OAuth, que no apareció en mis búsquedas), configurar el webhook de pagos y validar firma (`MP_WEBHOOK_SECRET`).
- **Cuenta de Fixi**: es la cuenta que recibe las comisiones (`marketplace_fee`). Conviene que sea una cuenta verificada a nombre del titular fiscal de Fixi (monotributo o sociedad), **no personal**.

## 3. Costos de procesamiento de Mercado Pago y quién los absorbe

Por la documentación de split, los absorbe el **vendedor (técnico)**. Valores publicados para Checkout Pro / link de pago (Argentina), según la página oficial de ayuda y de la herramienta:

| Plazo de acreditación | Costo (+ IVA) | Costo efectivo con IVA 21% |
|---|---|---|
| Al instante | 6,29% | 7,61% |
| 10 días | 4,39% | 5,31% |
| 18 días | 3,39% | 4,10% |
| 35 días | 1,49% | 1,80% |

Fuentes: https://www.mercadopago.com.ar/ayuda/26748, https://www.mercadopago.com.ar/herramientas-para-vender/check-out, https://www.mercadopago.com.ar/herramientas-para-vender/link-de-pago. Notas importantes:
- Es costo "+ IVA". Para un monotributista que no es responsable inscripto, ese IVA es un costo (no lo puede computar). **[CONTADOR]**
- Los costos "varían de acuerdo a la provincia en donde esté registrado tu domicilio, el medio de pago que elija tu cliente y el plazo que definas". La página de ayuda parece tener más de un año de antigüedad: **confirmá los valores actuales en una cuenta real o con el simulador de MP**.
- **Cuotas**: ofrecer cuotas suma costo (por ejemplo, 2 cuotas +7,79%, 6 cuotas +18,69% según la página de link de pago). Si ofrecés cuotas sin interés en la app, esos costos salen del técnico. Recomendación: **en el MVP, solo un pago**, y que el técnico vea el costo.
- No hay costo fijo por transacción en el checkout (según la página de la herramienta).
- **[NO VERIFICADO]**: si, en split, el vendedor puede elegir el plazo de liberación (y por ende el costo) o si lo define Fixi o el contrato con MP. Es clave para el flujo de retención (sección 4).

## 4. ¿Se puede retener el dinero hasta confirmar el trabajo?

### Lo que sé

- La documentación de split que leí **no menciona retención configurable**. Otros documentos de MP hablan de `money_release_date` con estados "pending" y "released" (campo de pagos que informa si el dinero ya está disponible para el vendedor), y dicen que los plazos de liberación se relacionan con procesos bancarios y con reclamos o disputas que pueden demorarla (https://mercadopago.com.ar/developers/en/docs/reports/released-money/introduction y el changelog de MP). **Eso no equivale a un "escrow" configurable por el marketplace.**
- Por eso, el esquema de `ARQUITECTURA.md` (pago `held` hasta que el cliente confirma) **no está respaldado por la documentación pública**. Con el split estándar, el dinero se acredita al técnico (con el plazo de liberación elegido) apenas se aprueba el pago.

### Opciones, de más simple a más compleja

| Opción | Cómo funciona | Pros | Contras / riesgos |
|---|---|---|---|
| **A. Pago al finalizar (recomendada para el MVP)** | El cliente acepta oferta -> el técnico va -> marca `done` -> **recién ahí** la app genera el cobro (Checkout Pro con `marketplace_fee`) -> el cliente paga en la puerta -> `completed`. | No se necesita retener nada. El dinero va directo al técnico, Fixi cobra su fee automáticamente. Es el modelo de cobro por cuenta del técnico: **legalmente más liviano para vos**. | El cliente puede no pagar (se mitiga con calificación del cliente, bloqueo de la cuenta y cuenta con medio de pago guardado, a evaluar). Se pierde la promesa "el técnico no cobra hasta que confirmás". El técnico podría pedir efectivo por fuera. |
| **B. Pago anticipado + plazo de liberación largo** | Cobro al aceptar, y se usa el plazo de acreditación de MP (10, 18 o 35 días) como "ventana natural" de reclamos. | Usa la infraestructura de MP. Menor costo si el plazo es largo (1,49% a 35 días). | El técnico cobra tarde (35 días es mucho en un oficio). **[NO VERIFICADO]** que el marketplace pueda fijarlo. No evita que MP liquide al técnico luego de X días aunque haya disputa. |
| **C. Pre-autorización con captura diferida (tarjeta)** | Reserva el monto en la tarjeta y se captura al confirmar. | Es lo más parecido a retención. | **[NO VERIFICADO]** si existe/está habilitado en Argentina con split y por cuánto tiempo (en general las reservas tienen plazos cortos). Preguntar a MP. |
| **D. Fixi cobra el total en su cuenta y le paga al técnico después** (sin split, "custodia") | El cliente paga a Fixi; Fixi transfiere al técnico (menos 5%) al confirmarse. | Control total: retención real, devolución simple. | **Implicancias legales e impositivas grandes [ABOGADO][CONTADOR]**: manejás dinero de terceros (podrías caer en regulación de proveedores de servicios de pago o en riesgos de mandato/administración de fondos; **no pude verificar la normativa**), el total entra a tu cuenta (puede contar como ingreso bruto, base de IIBB, impacto en monotributo), contracargos y devoluciones salen de tu patrimonio, y MP puede considerar el uso como incompatible con sus términos. Por eso `ARQUITECTURA.md` lo marca como hueco. |
| **E. Pago parcial** | Cobrar por la app una "visita/diagnóstico" o señal (10-30%) y el saldo al finalizar. | Reduce no-shows; limita exposición. | Más fricción; el saldo vuelve al problema de A. |

**Mi recomendación [ESTIMACIÓN]:** MVP con **A** (o E), y mientras tanto escribirle a Mercado Pago para saber si **B/C** son posibles. No cambies la promesa comercial hasta tener la respuesta por escrito. Si hacés **D**, no lo hagas sin abogado y contador (ver doc 04).

**Preguntas concretas para MP** (copialas en un ticket/ mail): 
1. ¿Split 1:1 en Argentina permite pagos con tarjeta de crédito/débito o solo dinero en cuenta?
2. ¿Puede el marketplace configurar el plazo de liberación del dinero del vendedor por pago (`money_release_days` o equivalente)?
3. ¿Hay forma de retener/autorizar sin capturar? ¿Por cuánto tiempo?
4. ¿Quién asume los contracargos: el vendedor, el marketplace o ambos? ¿Cómo se debitan si el vendedor no tiene saldo?
5. ¿Hace falta homologación o alta comercial para usar `marketplace_fee`? ¿Hay un tope para la comisión?
6. ¿La comisión es monto o porcentaje? ¿Cómo se informa para fines impositivos (retenciones sobre el fee)?
7. ¿Cuál es la duración de tokens OAuth/refresh? ¿Qué pasa si el técnico revoca el acceso?

## 5. Plazos de acreditación, contracargos y devoluciones

- **Plazos**: los de la tabla de la sección 3 (al instante, 10, 18, 35 días). **[NO VERIFICADO]** cuál se aplica en split y quién lo elige.
- **Reembolsos**: documentados (proporcionales vendedor/marketplace; si el vendedor no tiene saldo, el marketplace no puede devolver todo).
- **Contracargos**: **[NO VERIFICADO]**. En general, cuando el titular de una tarjeta desconoce un cargo, el emisor lo revierte y el monto se debita a quien recibió el dinero; en un split eso involucra al vendedor y posiblemente al marketplace. Definí por contrato (doc 06) que **el técnico responde por los contracargos de sus trabajos** y que Fixi puede compensarlos contra pagos futuros (a validar con abogado).
- **Riesgo de saldo negativo**: si el técnico retira todo y luego hay devolución/contracargo, Fixi puede quedar expuesta. Mitigaciones: acreditación más lenta en técnicos nuevos; límites al monto de trabajos en el nivel bronce; seguro y fondos de garantía; disputas dentro de la app **antes** de que el dinero se libere.

## 6. Alternativas de cobro (distintos de MP split)

No verifiqué en esta investigación capacidades de marketplace ni comisiones de otros proveedores. Lista para consultar, **no como recomendación**:
- **Otros PSP/pasarelas argentinos** (Ualá Bis, Modo, Naranja X, Payway, Getnet, dLocal y similares): preguntales si tienen **split/subcuentas**, retención y términos para marketplaces. **[NO VERIFICADO]**.
- **Transferencias y QR interoperable**: la transferencia entre CBU/CVU no cobra costo al que recibe en general y el QR interoperable lo habilitan las billeteras. Ventajas: costo muy bajo o nulo. Desventajas: **no hay split ni retención automática ni protección**; no hay un "cobro de comisión" automático (tendrías que cobrarle el 5% al técnico en otra operación, lo que aumenta el riesgo de que se ignore). **[NO VERIFICADO]** los costos exactos hoy.
- **Efectivo**: el cliente paga al técnico en mano. Es lo más frecuente en el sector y es **donde se fuga**: Fixi no cobra su 5% salvo por un mecanismo posterior (por ejemplo, el técnico paga la comisión por QR después). No lo recomiendo como base.

## 7. Economía unitaria con ejemplos

**Supuestos [ESTIMACIÓN]** (no verificados, solo para ilustrar; cambiá los números con datos reales):

| Rubro | Ticket de ejemplo |
|---|---|
| Electricista (visita + cambio de llave térmica) | $45.000 |
| Plomero (arreglo de pérdida) | $60.000 |
| Aire acondicionado (service) | $90.000 |
| PC / WiFi | $35.000 |
| **Ticket promedio ponderado (supuesto)** | **$55.000** |

### 7.1 Qué recibe cada parte por un trabajo de $55.000

| Concepto | Acreditación al instante | A 10 días | A 35 días |
|---|---|---|---|
| Costo MP (con IVA) | 7,61% = $4.186 | 5,31% = $2.922 | 1,80% = $992 |
| Comisión Fixi (5%) | $2.750 | $2.750 | $2.750 |
| **Neto del técnico** | **$48.064 (87,4%)** | **$49.329 (89,7%)** | **$51.258 (93,2%)** |
| **Ingreso bruto de Fixi** | $2.750 | $2.750 | $2.750 |

Lectura: el técnico se queda con 87% a 93% del precio. El **costo total de intermediación sentido por el técnico es 7% a 13%** (Fixi + MP), no 5%. Tené esto presente en tu discurso (doc 02).

### 7.2 Resultado de Fixi por trabajo

| Concepto | Monto |
|---|---|
| Ingreso por comisión | $2.750 |
| Ingresos Brutos sobre la comisión (ejemplo 3% a 5%; **alícuota real a confirmar** [CONTADOR]) | $83-$138 |
| IVA sobre la comisión (si sos responsable inscripto: 21%; ver sección 8) | $578 que pasa a ser deuda con ARCA, no ganancia |
| Soporte, disputas y reembolsos (tiempo + pérdidas, **[ESTIMACIÓN]** 3% a 8% de los trabajos) | $100-$250 por trabajo promedio |
| **Contribución aproximada (monotributista, sin IVA)** | **~$2.300 a $2.550** |

### 7.3 Punto de equilibrio

Costos fijos mensuales de ejemplo **[ESTIMACIÓN]**:

| Escenario | Costos fijos / mes | Trabajos / mes para cubrirlos (a ~$2.400 de contribución) |
|---|---|---|
| Mínimo (monotributo cat. A $49.527 + servidor $30.000 + herramientas $20.000) | ~$100.000 | **~42** |
| Operativo (cat. C $66.020 + servidor $50.000 + marketing $100.000 + herramientas $30.000 + contador $60.000) | ~$300.000 | **~125** |
| "Vivir de esto" (ingreso objetivo $1.500.000 + gastos anteriores) | ~$1.800.000 | **~750** |
| Con una persona de soporte part time (+$600.000) | ~$2.400.000 | **~1.000** |

Montos de monotributo: escala vigente desde 1/8/2026 (https://hacecuentas.com/datos-monotributo-2026; fuente secundaria, confirmar en ARCA).

Lectura: con comisión 5% **necesitás volumen alto**. Para $1,5M/mes de ingreso personal hay que mover alrededor de 750 trabajos/mes, o sea ~$41M de GMV (volumen de pagos) por mes. Palancas realistas: (a) tickets más altos (aire, instalaciones); (b) subir la comisión a 8-10% en rubros de ticket alto o con valor de lead; (c) servicios adicionales a técnicos (suscripción Pro, publicidad de proveedores, como hace Servidos.ar según su sitio); (d) cobrar a clientes un fee de servicio. **[ESTIMACIÓN]**.

### 7.4 Cuándo se pasa el tope de monotributo (si solo la comisión es ingreso)

Con $2.750 de comisión por trabajo, Fixi llega al tope anual de la categoría A ($12.009.410) con unos **4.370 trabajos al año (~364/mes)**; al de la C ($24.670.494), ~8.970 al año (~750/mes). Si en vez de la comisión **todo el pago pasa por la cuenta de Fixi** (opción D), ese mismo volumen de $55.000 por trabajo llegaría al tope A con solo ~218 trabajos al año. **Por eso el modelo de pago define el régimen tributario**. **[CONTADOR]**

## 8. Obligaciones impositivas del fundador (checklist para contador)

> Todo lo siguiente son **hipótesis de trabajo** para la reunión con el contador; las únicas cifras verificadas son las del monotributo (fuente secundaria) y lo que dice cada fuente citada.

### 8.1 Forma jurídica y régimen

| Opción | Cuándo conviene | Pendiente |
|---|---|---|
| **Monotributo (persona humana)** | Arranque con ingresos bajos; trámite simple; cuota fija. Cuota mensual de servicios: A $49.527, B $56.379, C $66.020, D $84.613, E $119.811, F $150.784, G $230.313, H $522.707, I $963.748, J $1.167.300, K $1.614.446 (escala desde 1/8/2026; próxima revisión feb 2027). Tope anual de K: $126.610.839; al superarlo se pasa a responsable inscripto. https://hacecuentas.com/datos-monotributo-2026 | **[CONTADOR]**: ¿qué actividad declarar (desarrollo de software, servicios de intermediación, publicidad)? ¿Qué ingresos computan: solo la comisión o el total cobrado? ¿Algún impedimento por manejar dinero de terceros? |
| **Responsable inscripto (persona humana)** | Si superás el tope o necesitás emitir factura A / discriminar IVA con clientes empresas. | IVA 21% sobre la comisión (ver 8.3), declaraciones mensuales, Ganancias anual. |
| **Sociedad (SAS, SRL)** | Cuando haya riesgo de responsabilidad patrimonial (ver doc 04: el monotributista responde con su patrimonio personal), socios, inversión, o MP/seguros lo requieran. | **[ABOGADO]**: costos y tiempos de constitución actuales (no verificados). Con sociedad, el régimen es general (RI), no monotributo. |

Recomendación **[ESTIMACIÓN]**: arrancar con monotributo para validar, pero **constituir una SAS antes de escalar o antes de que haya trabajos de riesgo** (gas, electricidad, cerrajería), y contratar el seguro de responsabilidad civil de la plataforma a nombre de la sociedad.

### 8.2 Facturación de la comisión

- Fixi presta un servicio al técnico (intermediación). Debe **emitir factura electrónica** por la comisión (monotributo: factura C; RI: factura A o B según el receptor). **[CONTADOR]** cómo se factura cuando MP descuenta automáticamente: ¿una factura por trabajo, o mensual por técnico? Un técnico monotributista es consumidor final para el IVA.
- La comisión "5%" que ve el técnico ¿es con o sin IVA? Si Fixi es RI, **el 5% es neto y el técnico paga 6,05%** (5% + 21% de IVA), salvo que definas "5% final". Es decisión comercial y fiscal. **Definilo en los T&C.**

### 8.3 IVA

- Monotributista: no discrimina IVA; no cobra IVA sobre la comisión; **no puede computar el IVA que le cobran sus proveedores** (incluido el IVA del costo de MP).
- Responsable inscripto: IVA débito del 21% sobre la comisión; crédito fiscal por sus compras (hosting, servicios). **[CONTADOR]** si servicios prestados a técnicos/clientes tienen alícuota distinta o exenciones.

### 8.4 Ingresos Brutos (IIBB)

- Impuesto provincial; la inscripción y la alícuota dependen de la jurisdicción donde estés domiciliado y donde presten el servicio, y de la actividad. En CABA y PBA hay regímenes simplificados para monotributistas, y **Convenio Multilateral** si operás en varias jurisdicciones. **[NO VERIFICADO]** alícuotas actuales: no las busqué. **[CONTADOR]**
- Posibles **retenciones/percepciones** sobre acreditaciones bancarias o de billeteras (regímenes de recaudación bancaria como SIRCREB). Cuestión para el contador.

### 8.5 Regímenes de información de plataformas y billeteras

- ARCA tiene un régimen de información a cargo de plataformas y billeteras virtuales (**RG 4614/2019**, actualizado por la **RG ARCA 5804/2025**, con obligaciones aplicables a declaraciones desde mayo de 2026; umbral citado para personas humanas: $50.000.000 mensuales de ingresos, egresos o saldo). Mercado Pago, como proveedor de servicios de pago, es quien informa. Y esa información le aparece al monotributista en el servicio "Nuestra Parte" para que ARCA pueda cruzar con lo facturado. Fuentes: https://blog.aconpy.com/2026/01/29/monotributistas-arca-tiene-la-informacion-sobre-tus-cobros-a-traves-de-plataformas-digitales/ , https://giegestudio.com.ar/plataformas-digitales-billeteras-virtuales-regimen-informacion.html , https://tributum.news/res-gral-5814-2026-arca-entidades-financieras-y-plataformas-digitales-regimen-de-informacion-operaciones-montos-minimos-actualizacion-inflacion-eliminacion/ (la RG 5814/2026 elimina la actualización semestral por IPC de los montos mínimos). **Son fuentes secundarias y con fechas inconsistentes: verificá el texto en el Boletín Oficial.**
- Consecuencia práctica: **tus ingresos y los de cada técnico quedan visibles para ARCA vía MP**. Los técnicos informales se van a sentir expuestos: tené lista una guía de monotributo (doc 02).
- **[NO VERIFICADO]**: si Fixi, como "plataforma", tiene obligaciones propias de información o retención hacia sus usuarios (técnicos) distintas de las de MP. Preguntar al contador. No encontré una norma que lo establezca para marketplaces de servicios del tamaño de Fixi.

### 8.6 Qué factura el técnico

- El **técnico** factura el servicio al cliente (monotributo: factura C; si el cliente es consumidor final, a veces puede emitirse con CUIL/DNI; límites y requisitos los define ARCA). El cliente recibe esa factura; la app puede guardarla en el trabajo (`Job`).
- Fixi **no factura el trabajo del técnico**, solo su comisión, salvo que firmes un mandato expreso de facturación **[ABOGADO][CONTADOR]**. Esto ayuda a sostener que el técnico es independiente (ver doc 04).
- Técnicos informales: **cobrar por la app exige CUIT/CUIL**, porque MP los identifica. Fijalo como requisito de alta.

### 8.7 Ganancias

Monotributo: incluido en la cuota. RI/Sociedad: impuesto a las ganancias anual sobre resultado. **[CONTADOR]**.

### 8.8 Otras cuestiones fiscales

- Si el fundador **cobra el 100% en su cuenta** (opción D), el dinero de terceros no es ganancia, pero el tratamiento de "mandato / cuenta y orden" tiene reglas de facturación y rendición específicas. **[CONTADOR][ABOGADO]**.
- Cuenta bancaria separada para Fixi desde el día 1.
- Percepciones y retenciones por Mercado Pago a vendedores (si existen) afectan al técnico; preguntar a MP. **[NO VERIFICADO]**.

## 9. Lista de "preguntas para el contador" (copiar a la reunión)

1. ¿Monotributo o sociedad para empezar? ¿Qué actividad se declara?
2. En el modelo split, ¿mi ingreso computable es solo la comisión? ¿Y si cambio al modelo D (custodia)?
3. ¿Cómo facturo las comisiones que MP me acredita automáticamente?
4. ¿Mi comisión de 5% debe llevar IVA? ¿Cómo lo muestro en T&C?
5. ¿IIBB: inscripción, alícuota y régimen en mi jurisdicción? ¿Retenciones bancarias?
6. ¿Qué datos informa MP a ARCA sobre mí y sobre los técnicos? ¿Debo informar yo algo?
7. ¿Cómo registro bonos de referidos y créditos de bienvenida (gastos de marketing, descuentos, ¿requieren retención?)?
8. ¿Cómo se registran las devoluciones y contracargos?
9. ¿Qué pasa si superó el tope de monotributo en mitad de un semestre?
10. ¿Costo anual de mantener la estructura elegida (honorarios, bancos, registros)?

## Fuentes

- https://www.mercadopago.com.ar/developers/es/docs/split-payments/split-1-1/integration-configuration/integrate-marketplace
- https://www.mercadopago.com.ar/developers/en/docs/split-payments/landing
- https://www.mercadopago.com.ar/ayuda/26748
- https://www.mercadopago.com.ar/herramientas-para-vender/check-out
- https://www.mercadopago.com.ar/herramientas-para-vender/link-de-pago
- https://mercadopago.com.ar/developers/en/docs/reports/released-money/introduction
- https://hacecuentas.com/datos-monotributo-2026
- https://blog.aconpy.com/2026/01/29/monotributistas-arca-tiene-la-informacion-sobre-tus-cobros-a-traves-de-plataformas-digitales/
- https://giegestudio.com.ar/plataformas-digitales-billeteras-virtuales-regimen-informacion.html
- https://tributum.news/res-gral-5814-2026-arca-entidades-financieras-y-plataformas-digitales-regimen-de-informacion-operaciones-montos-minimos-actualizacion-inflacion-eliminacion/
