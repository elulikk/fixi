# 02 - Propuesta para técnicos

> Fecha: 13/11/2026. Hechos con fuente llevan URL. **[ESTIMACIÓN]** = criterio mío. Lo que no pude verificar está dicho explícitamente en la sección 3.

## 1. Propuesta de valor (lo que le decís al técnico)

**En una frase:** "Pedidos de gente de tu zona, con el cobro asegurado dentro de la app, sin pagar nada hasta que cobrás, y con tu reputación acumulándose a tu nombre."

| Lo que el técnico quiere | Lo que Fixi le da |
|---|---|
| Más trabajo sin gastar en publicidad | Pedidos publicados cerca suyo; él elige a cuáles ofertar. No paga por aparecer ni por "leads". |
| Cobrar seguro y rápido | Pago dentro de la app con Mercado Pago; sin discutir "te pago mañana". (Ver doc 03 sobre plazos y qué se retiene.) |
| Fijar su precio y su tiempo | Él pone precio, hora de llegada y duración en cada oferta, y publica servicios con precio. No hay tarifa impuesta. |
| Reputación portable | Reseñas, puntos y nivel (bronce, plata, oro, platino) que ve el cliente al comparar. |
| Orden y herramientas | Chat por trabajo, ubicación en camino, historial de ganancias (`GET /me/earnings`). |
| Libertad | Sin exclusividad, sin horarios, sin cupos mínimos (importante para sostener la independencia; ver doc 04). |

Costo para el técnico, **dicho sin vueltas**: Fixi retiene **5%** del precio del trabajo; además Mercado Pago cobra su propio costo de procesamiento al vendedor (el técnico), que depende del plazo de acreditación: según la página oficial de ayuda, 6,29% + IVA al instante, 4,39% + IVA a 10 días, 3,39% + IVA a 18 días, 1,49% + IVA a 35 días (https://www.mercadopago.com.ar/ayuda/26748 y https://www.mercadopago.com.ar/herramientas-para-vender/check-out; los resultados indican que la tabla de ayuda tiene más de un año, así que **hay que confirmar los valores vigentes en la cuenta**). La documentación de split indica que "La comisión de Mercado Pago se descuenta de los fondos recibidos por el vendedor" y luego se aplica la del marketplace sobre el saldo restante (https://www.mercadopago.com.ar/developers/es/docs/split-payments/split-1-1/integration-configuration/integrate-marketplace). Ejemplo en el doc 03.

## 2. Por qué sería honesto decirles eso

La mayor causa de fuga en marketplaces es que el técnico se sienta engañado por los costos. Si le mostrás desde el día 1 "de $55.000 te quedan $49.329 con acreditación a 10 días" (cálculo del doc 03), baja la desconfianza. Mostrá un **simulador de ganancia neta** en la pantalla de oferta (el servidor ya conoce `price`, `commission` y `techNet`; falta sumar el costo de MP).

## 3. Competidores y alternativas reales en Argentina

Importante: acá solo pongo lo que pude **verificar con una fuente**. Mucho de lo que se sabe de estos jugadores es viejo o viene de notas periodísticas, no de sus términos vigentes. Si una comisión no pude verificarla, lo digo.

| Alternativa | Qué es | Qué pude verificar | Qué NO pude verificar |
|---|---|---|---|
| **Servidos.ar** | Marketplace argentino de servicios para el hogar (plomeros, electricistas, pintores, gasistas, etc.). El cliente publica y recibe presupuestos. | Su propio sitio dice: "Hoy no cobramos comisión por trabajo, ni al cliente ni al profesional"; el cliente le paga directo al profesional; ingresos por cuenta Pro opcional, publicidad y afiliados; dice verificar DNI y matrículas de gas y electricidad; opera sobre todo en CABA/GBA y ciudades principales. https://servidos.ar/ (afirmaciones propias de la empresa, sin auditar) | Volumen real, cantidad de profesionales, si mantendrá el 0% (el sitio dice que es la política "hoy"). |
| **IguanaFix** | Plataforma argentina de reparaciones del hogar; fue la más conocida. | Notas periodísticas indican que dejó de atender a clientes individuales y se enfocó en empresas (B2B): https://www.iproup.com/innovacion/4602-matias-recchia-mercado-libre-emprendimiento-No-mas-plomero-a-domicilio-IguanaFix-se-focaliza-en-clientes-corporativos y https://www.cronista.com/apertura/empresas/cambio-de-foco-iguanafix-deja-a-clientes-individuales-y-va-por-los-corporativos (las notas no tienen fecha visible en los resultados; verificar). Una nota antigua dice que los profesionales pagaban suscripción mensual y además había comisión por lo contratado. | Porcentajes de comisión y vigencia actual. |
| **Zolvers** | Plataforma de servicio doméstico y mantenimiento; con "ZolversPagos" para registrar la relación laboral y pagar sueldos. | Existe como empresa argentina (SRL en CABA) y se orienta a servicio doméstico y profesionales de mantenimiento (https://www.cbinsights.com/company/zolvers, https://www.endeavor.org.ar/tag/zolvers). | Comisión actual, si compite en técnicos a domicilio, términos vigentes. |
| **Workana** | Plataforma de freelancers (diseño, software, etc.). **No aplica a oficios de domicilio**, la dejo como referencia de tarifa de plataforma. | Fuentes secundarias citan una comisión escalonada para el freelancer de 20% hasta USD 300 por cliente, 10% entre 300 y 3.000, 5% por encima (https://www.coderhouse.com/en/coderlibrary/workana-upwork-fiverr-plataforma-freelance-desde-argentina); otra fuente de 2026 cita 10% (o USD 5 mínimo) para el freelancer. **Las fuentes se contradicen**: ver https://help.workana.com/hc/es/articles/360040846094--Cu%C3%A1nto-cuesta-usar-Workana | Valor vigente. |
| **FixUP!** | Startup argentina de reparación de tecnología (retiro a domicilio y centros de servicio). Competidor directo en el rubro tecnología. | Existe; descripto por prensa (https://www.cronista.com/infotechnology/it-business/que-es-fixup-la-solucion-argentina-para-reparar-tecnologia-sin-gastar-de-mas). Modelo distinto: ellos prestan el servicio, no es un marketplace de independientes. | Cobertura y precios actuales. |
| **Mercado Libre (sección Servicios)** | Listado de servicios dentro de Mercado Libre. | Vi que existe un listado de "servicios/reparaciones e instalaciones" en el portal (resultados de búsqueda) y que Mercado Libre lanzó instalación de neumáticos en talleres. | Si hay un producto de servicios técnicos a domicilio masivo, y cuál es su comisión. **No la pude verificar.** |
| **GetNinjas / Home Solution** | Los mencionaste. | No encontré información verificable y vigente para Argentina de estas marcas en las búsquedas que hice. | Todo. |
| **Grupos de WhatsApp / Facebook / boca a boca / Instagram** | El canal dominante real. | Es mi observación del mercado informal, no tiene fuente. | Tamaño. |
| **Cartelería, "Mercado Libre Servicios", páginas amarillas, Google Maps** | Canales de exposición del técnico. | - | - |

### Lectura estratégica (mi análisis, **[ESTIMACIÓN]**)

- **Servidos.ar es el rival más directo que encontré**, con 0% de comisión hoy. Si competís por precio vas a perder. Competí por **cobro asegurado, comparación de ofertas con tiempo de llegada y reputación verificable**, que es justo lo que Fixi tiene y ellos (dicen) no manejan: pago en la app.
- Pagar 5% más costo de MP solo se justifica si **el técnico recibe trabajo que no conseguiría solo** y si **cobra seguro**. Apuntá el discurso a eso, no a "somos más baratos".
- El hueco histórico que dejó IguanaFix para particulares (si se confirma su salida) es una oportunidad, pero también una advertencia: la logística de marketplace B2C de oficios fue difícil de sostener para un equipo con capital.

## 4. Incentivos de lanzamiento

Diseño propuesto (**[ESTIMACIÓN]**; ajustalo a tu margen real; cada incentivo tiene un costo en ingresos que está en la columna final).

| Incentivo | Regla | Costo para Fixi |
|---|---|---|
| **Comisión 0% por 90 días o 20 trabajos (lo que ocurra primero)** a los técnicos fundadores | El técnico paga solo el costo de MP. Se cuenta desde el primer trabajo completado. | Ingreso resignado: 5% de ~20 trabajos x $55.000 = $55.000 por técnico (para 50 técnicos: $2,75M, **teórico**, solo si todos llegan a 20 trabajos) |
| **Insignia "Fundador"** | Visible en el perfil y en `TechCard`. Se entrega a los primeros 50 técnicos verificados. Es permanente. | Casi cero. |
| **Bono por referidos al técnico** | $10.000 (valor de ejemplo) cuando el técnico referido **completa 3 trabajos**; y 0% de comisión sobre el primer trabajo del referido. Tope 5 referidos por técnico. | $10.000 por referido que funciona. |
| **Bono por referidos al cliente** | Crédito de $5.000 para ambos cuando el referido completa su primer trabajo. | $10.000 por referido. |
| **Niveles y puntos** | Ya definidos en la arquitectura: bronce (0+), plata (200+), oro (600+), platino (1500+); +20 por trabajo, +10 x (estrellas-3), +5 llegada a tiempo. | Casi cero. |
| **Comisión escalonada por nivel (propuesta)** | Bronce 5%, Plata 4,5%, Oro 4%, Platino 3,5%. Para que el nivel valga plata (y que cuidar la reputación en Fixi compense). | Hasta 1,5 puntos de comisión en los mejores. |
| **Comisión reducida en clientes recurrentes (propuesta clave contra la fuga)** | Primer trabajo con un cliente: 5%. Segundo: 3%. Tercero y siguientes: 2%. Siempre dentro de la app. | Reduce ingreso por trabajo, pero **evita perder 100% del trabajo repetido por fuera.** |
| **Prioridad de visibilidad** | Los técnicos activos y bien reseñados aparecen primero en listados/ofertas (ya implícito en el score). | Cero. |
| **Seguro de accidentes personales grupal (a evaluar)** | Cobertura básica opcional para técnicos activos. Ver doc 04: sección seguros. | A cotizar; **no verificado**. |
| **Kit de bienvenida** | Sticker con QR para el casco/camioneta, remera o tarjetas personales con su perfil Fixi. | $3.000-$6.000 por técnico **[ESTIMACIÓN]** |

**Cuidado legal:** un incentivo atado a exclusividad o a horas mínimas debilita la independencia (doc 04). Los bonos deben ser por **resultados** (trabajos completados, reseñas), no por **disponibilidad o cumplimiento de horario**.

## 5. Cómo evitar la desintermediación (arreglar por afuera)

El riesgo: el técnico hace el primer trabajo por Fixi, le deja el WhatsApp al cliente y el siguiente trabajo lo hace por fuera, sin comisión. Y en el peor caso, intenta cobrar el primero en efectivo. Cómo se maneja sin depender solo de castigar:

### 5.1 Incentivos (el 80% del trabajo)

1. **Que quedarse en la app le convenga más que irse.**
   - Cobro asegurado: en la app no hay "te transfiero el viernes".
   - Comisión que **baja** con la recurrencia (arriba: 5% -> 3% -> 2%): a partir del tercer trabajo, irse ahorra solo 2%, y se pierde la protección y la reputación.
   - Los puntos y las reseñas solo suman con trabajos completados en la app; son su "currículum".
2. **Valor agregado después del primer trabajo**: garantía de Fixi del trabajo (por ejemplo, 30 días con intervención de Fixi si hay problema); historial y facturas guardadas; recordatorios automáticos de service ("hace 11 meses limpiaste este aire") que el técnico puede ofrecer con un toque.
3. **Herramientas de "mis clientes"**: lista de clientes recurrentes, agenda, cobros con link. Si la app le sirve como CRM gratis, no necesita salirse.
4. **Beneficios por nivel** (menos comisión, prioridad, seguro) para no perder el nivel.
5. **Prueba social**: el técnico top del mes aparece en la home y las redes de Fixi (con su permiso).

### 5.2 Diseño del producto (fricción razonable, sin invadir)

- Chat dentro de la app; **no mostrar el teléfono** hasta que el trabajo esté pagado (y aun así, usar número enmascarado si lo integrás luego). El cliente igual verá al técnico en la puerta; acá no se trata de impedir que se conozcan, sino de que no se saltee el primer cobro.
- Detección de patrones de contacto en el chat (teléfonos, "WhatsApp", "pasame tu número") y **alerta suave** ("Recordá que el cobro protegido solo vale dentro de Fixi"), no bloqueo duro.
- El pago por la app **desbloquea** la garantía, la reseña y los puntos.

### 5.3 Reglas y consecuencias (el 20% restante)

- Cláusula en el contrato (doc 06): prohibido aceptar o solicitar pagos por fuera por trabajos originados en Fixi **durante el trabajo y por 12 meses con el mismo cliente** (a validar con abogado; ver advertencia sobre cláusulas excesivas en doc 04).
- Escala de consecuencias: aviso -> pérdida de insignia/nivel -> suspensión temporal -> baja. Siempre con **derecho a explicación** previa.
- **No prohibas al cliente contratar a quien quiera**: una cláusula que le impida al consumidor contratar por afuera es riesgosa legalmente (cláusulas abusivas, doc 04). La restricción va al técnico por contrato, no al consumidor.
- "Pago de rescate" opcional: si un cliente y un técnico quieren seguir por fuera, ofrecer una **tarifa de liberación** transparente (por ejemplo, equivalente a 3 meses de comisión estimada). Es opcional y mejor que perder el vínculo; **validar con abogado**.

## 6. Guiones de acercamiento

### 6.1 Mensaje de WhatsApp en frío (para un técnico que no te conoce)

> Hola [Nombre], ¿cómo andás? Te escribo porque vi que trabajás de [rubro] en [barrio]. Soy [tu nombre], estoy lanzando **Fixi**, una app para que los vecinos de [barrio] publiquen lo que necesitan y técnicos como vos les manden una oferta con su precio y hora de llegada. Vos elegís a qué pedidos ofertar, ponés tu precio y cobrás por la app con Mercado Pago.
> Estoy sumando a los primeros 50 técnicos de la zona: **0% de comisión por tus primeros 20 trabajos** y la insignia de "Fundador". Si te copa, te cuento en 5 minutos por acá o por llamada. ¿Te sirve?

Variante para grupos de Facebook/WhatsApp (con permiso del admin):

> Hola gente. Estoy armando una app para conectar técnicos con vecinos de [zona]. No cobramos nada para anotarse y los primeros 50 técnicos no pagan comisión durante sus primeros 20 trabajos. Si querés sumarte, te mando el link por privado.

### 6.2 Speech presencial de 30 segundos (en el mostrador de la ferretería o a un técnico en persona)

> "Buenas, soy [Nombre]. Estoy armando una app para que la gente de [barrio] publique lo que necesita (una pérdida, un corte de luz, un aire que no enfría) y los técnicos de la zona le mandan una oferta con precio y hora. Vos elegís los pedidos que querés, ponés tu precio y cobrás por la app. Estoy sumando a los primeros 50: no pagás comisión en tus primeros 20 trabajos. ¿Te dejo mi tarjeta con el código para que te anotes cuando tengas un minuto?"

### 6.3 Respuestas a objeciones típicas

| Objeción | Respuesta sugerida |
|---|---|
| "Yo ya tengo clientes, no necesito nada." | "Genial, justamente por eso: te llegan pedidos extra en los huecos de la semana y vos elegís. Y si ya tenés tus clientes, la app te sirve para cobrarles ordenado." |
| "No me gusta que me cobren comisión." | "Entendible. Los primeros 20 trabajos no pagás comisión. Después es 5%, y baja si el cliente repite o subís de nivel. Pensalo como lo que gastarías en publicidad, pero solo pagás cuando cobrás." |
| "Mercado Pago me cobra un montón." | "Es verdad: depende del plazo en que lo retires (por ejemplo, cobrando a 10 días el costo ronda 4,39% + IVA según Mercado Pago; confirmalo en tu cuenta). Te mostramos la ganancia neta antes de ofertar para que nunca te sorprenda." |
| "Prefiero cobrar en efectivo." | "En la app el cobro es seguro: no hay clientes que 'después te pagan'. Y las reseñas quedan a tu nombre. El efectivo lo podés seguir recibiendo en tus clientes de siempre." |
| "No tengo monotributo / no facturo." | "Si querés trabajar con plataforma, te conviene regularizarte; Mercado Pago ya informa los cobros a ARCA. Te ayudo con una guía de cómo hacerlo. (Los técnicos son responsables de su propia situación fiscal; ver contrato.)" |
| "No sé usar apps." | "Es fácil: una vez que te anotás, te llegan notificaciones y solo tocás 'ofertar'. Hago el alta con vos en 10 minutos." |
| "¿Y si el cliente no me paga?" | "Con el pago en la app el cliente ya pagó antes o al terminar; vos no perseguís a nadie." (Ajustá esta frase según el modelo final de pago del doc 03: **no la uses si el modelo permite que el cliente no pague**.) |
| "¿Y si el cliente se queja y me bajan el dinero?" | "Hay un proceso de disputa. Si hacés bien el trabajo y lo documentás con fotos y chat, la ventaja es tuya. El detalle está en el contrato." |
| "Me van a mandar a lugares lejos." | "No: vos definís tu radio en el perfil y elegís a qué pedidos ofertar." |
| "No quiero que me controlen." | "No hay horarios ni cupos. Vos ofertás cuando quieras." (Importante para independencia.) |

## 7. Alta y verificación de técnicos

### 7.1 Principio

Verificar mucho al principio es lo que sostiene la confianza del cliente, que es el único activo de Fixi. Pero cada paso extra baja la conversión. Propuesta por **niveles de verificación** que se reflejan en la insignia `verified` del `TechProfile`:

| Nivel | Qué se pide | Qué puede hacer |
|---|---|---|
| **0 - Registrado** | Email, teléfono verificado por SMS/WhatsApp, selfie | Ver pedidos, no ofertar |
| **1 - Identidad verificada** | Foto del DNI (frente y dorso) + selfie con el DNI; CUIT/CUIL; constancia de monotributo (si corresponde) | Ofertar en rubros no regulados |
| **2 - Antecedentes** | Certificado de antecedentes penales (Registro Nacional de Reincidencia; trámite online del Ministerio de Justicia; **costo y vigencia no verificados**) con vencimiento anual | Ofertar en cualquier rubro de entrada a domicilio |
| **3 - Matrícula / habilitación** | Matrícula vigente en rubros regulados (gas, electricidad según jurisdicción) + seguro si lo exige el ente | Ofertar en rubros regulados |
| **4 - Referencias** (opcional) | 2 referencias o 2 clientes verificables; fotos de trabajos previos | Insignia "Verificado Plus" |

### 7.2 Matrículas: qué sé y qué no

- **Gas**: las fuentes que encontré coinciden en que no se puede tocar una instalación de gas sin matrícula, pero **difieren en quién la otorga**: una guía comercial dice que la otorga cada distribuidora y habilita en su área de concesión, vence cada 31 de marzo y exige seguro de accidentes personales y responsabilidad civil; otra dice que se rige por la normativa NAG 200 del ENARGAS (https://servidos.ar/blog/habilitaciones-matriculas-oficios-buenos-aires, fuente comercial, **no oficial**). Además, **ENARGAS publicó la Resolución 468/2026**, que **deroga el régimen de matrículas de "Instalador de Sistemas de Combustión" (Res. I/902/2009)** y lo vuelve optativo, **sin tocar** (según el texto que pude leer) la matrícula general de gasista (https://www.argentina.gob.ar/normativa/nacional/norma-425486/texto). **Conclusión: confirmá con la distribuidora de tu zona (Metrogas, Naturgy, etc.) y con ENARGAS qué matrícula se exige hoy y cómo se verifica antes de habilitar gasistas.** Hasta confirmarlo, no actives gasistas.
- **Electricidad**: según una guía comercial, en CABA hace falta matrícula de la AGC para instalaciones eléctricas (https://servidos.ar/blog/habilitaciones-matriculas-oficios-buenos-aires; **no verifiqué fuente oficial**). Las exigencias varían por provincia y municipio. **Confirmá con el organismo local** antes de definir qué rubro de electricidad exigís matriculado (instalaciones fijas vs. reparaciones menores).
- **Aire acondicionado**: no verifiqué si hay matrícula obligatoria; en la práctica, algunas instalaciones con gas refrigerante requieren habilitación según la jurisdicción. Consultar.
- **Cerrajería y otros**: sin requisito nacional que haya verificado; la verificación es de identidad y antecedentes.

### 7.3 Proceso operativo (para vos, fundador individual)

1. Formulario de alta en la app (ya existe `PUT /me/tech-profile`) + subida de documentos al panel admin (`PATCH /admin/users/:id` verifica técnico).
2. Revisión manual en 24 a 48 horas (vos). Dejá un checklist por técnico.
3. Entrevista corta por videollamada (5 minutos) los primeros 50 técnicos.
4. Una verificación ligera en redes/Google Maps (reseñas del técnico, antecedentes públicos).
5. Renovación anual de antecedentes y de matrícula; recordatorios automáticos.
6. **Protección de datos**: los documentos del técnico son datos personales; guardalos cifrados y con acceso restringido (ver doc 07 y doc 04).

## 8. Qué le pedimos a cambio (resumen para el contrato, ver doc 06)

- Datos verdaderos y actualizados; documentación vigente.
- Cobrar **solo dentro de la plataforma** los trabajos originados en Fixi.
- Cumplir normas de seguridad y matrícula del rubro; garantizar su trabajo.
- Ser puntual en la llegada prometida; si no llega, avisar.
- Tener su propio seguro de responsabilidad civil recomendado (obligatorio en rubros de riesgo; ver doc 04).
- Pagar sus impuestos y facturar al cliente.

## Fuentes

- https://www.mercadopago.com.ar/ayuda/26748
- https://www.mercadopago.com.ar/herramientas-para-vender/check-out
- https://www.mercadopago.com.ar/developers/es/docs/split-payments/split-1-1/integration-configuration/integrate-marketplace
- https://servidos.ar/
- https://servidos.ar/blog/habilitaciones-matriculas-oficios-buenos-aires
- https://www.argentina.gob.ar/normativa/nacional/norma-425486/texto
- https://www.iproup.com/innovacion/4602-matias-recchia-mercado-libre-emprendimiento-No-mas-plomero-a-domicilio-IguanaFix-se-focaliza-en-clientes-corporativos
- https://www.cronista.com/apertura/empresas/cambio-de-foco-iguanafix-deja-a-clientes-individuales-y-va-por-los-corporativos
- https://www.cbinsights.com/company/zolvers
- https://www.endeavor.org.ar/tag/zolvers
- https://www.coderhouse.com/en/coderlibrary/workana-upwork-fiverr-plataforma-freelance-desde-argentina
- https://help.workana.com/hc/es/articles/360040846094--Cu%C3%A1nto-cuesta-usar-Workana
- https://www.cronista.com/infotechnology/it-business/que-es-fixup-la-solucion-argentina-para-reparar-tecnologia-sin-gastar-de-mas
