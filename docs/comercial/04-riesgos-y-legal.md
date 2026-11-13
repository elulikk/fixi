# 04 - Riesgos y marco legal

> **Esto no es asesoramiento legal.** Es un mapa de riesgos para que llegues a la reunión con un abogado sabiendo qué preguntar. Fecha: 13/11/2026. Hechos con fuente llevan URL; **[ESTIMACIÓN]** es criterio mío; **[NO VERIFICADO]** = no pude confirmarlo; **[ABOGADO]** = requiere profesional matriculado. Los artículos de leyes que cito "de memoria" están marcados porque **no los re-verifiqué en esta sesión**.

## 1. Lo más urgente (antes de gastar un peso en marketing)

1. **El nombre "Fixi" tiene riesgo** (sección 10). Hacé la búsqueda en INPI y TMView ahora.
2. **Retención de pagos**: la promesa "el técnico cobra cuando confirmás" no está respaldada por lo que pude leer de Mercado Pago (doc 03).
3. **Responsabilidad personal ilimitada** si operás como monotributista y hay un daño grave (inundación, incendio, accidente de gas). Evaluá una SAS + seguro antes de rubros riesgosos.
4. **Servidor en una PC**: riesgo técnico y legal para datos personales (sección 6).
5. **Rubros gas y cerrajería**: dejarlos para una segunda fase con controles reforzados.

## 2. Matriz de riesgos

Escala: probabilidad (P) y impacto (I) de 1 a 5, **[ESTIMACIÓN]**. "Severidad" = P x I.

| # | Riesgo | P | I | Sev. | Mitigación principal |
|---|---|---|---|---|---|
| R1 | Daño a bienes o personas por mal trabajo (inundación, cortocircuito, incendio) | 3 | 5 | 15 | Rubros riesgosos con matrícula; seguro RC del técnico (exigido en rubros de riesgo); seguro RC de plataforma; T&C y contrato claros; garantía y proceso de reclamo; fotos antes/después. |
| R2 | Accidente de gas / intoxicación | 2 | 5 | 10 | **No habilitar gas** hasta confirmar régimen de matrícula y seguro; exigir matrícula verificada con la distribuidora. |
| R3 | Seguridad personal al entrar a domicilios (agresión, robo, abuso) | 2 | 5 | 10 | Verificación de identidad y antecedentes; selfie al llegar; compartir ubicación en tiempo real (ya existe `POST /jobs/:id/location`); botón de emergencia; reseñas; suspensión inmediata ante denuncias; cliente identificado (celular verificado). |
| R4 | Robo por técnico / suplantación (otra persona se presenta en vez del verificado) | 2 | 4 | 8 | Foto de perfil visible, código de 4 dígitos que el cliente le da al técnico al llegar, rechazo de reemplazos. |
| R5 | Relación de dependencia laboral encubierta (reclamo de técnicos o inspección) | 3 | 4 | 12 | Estructura de independencia (sección 4); contrato; factura obligatoria; no exclusividad; sin horarios; revisión por abogado laboralista. |
| R6 | Responsabilidad solidaria de Fixi frente al consumidor (Ley 24.240) | 4 | 4 | 16 | No presentarse como prestador; T&C claros; cuidar el "rol activo" (cobro, selección, garantía) porque la jurisprudencia lo usa para atribuir responsabilidad (sección 5); seguro; fondo de garantía. |
| R7 | Incumplimiento de defensa del consumidor (botón de arrepentimiento, información, trato digno) | 3 | 3 | 9 | Botón visible; información clara de precio y comisión; canal de reclamos; T&C sin cláusulas abusivas. |
| R8 | Protección de datos personales (sin inscripción, fuga de DNI y geolocalización) | 3 | 4 | 12 | Inscribir en AAIP; cifrado; accesos; política de privacidad; hosting seguro; plan ante incidentes. |
| R9 | Desintermediación (pérdida de comisión) | 5 | 3 | 15 | Incentivos (doc 02); comisión escalonada; contrato; detección. |
| R10 | Fraude de clientes (pedidos falsos, contracargos con tarjeta robada) | 3 | 3 | 9 | Verificación de teléfono; límites a cuentas nuevas; revisión manual de montos altos. |
| R11 | Fraude de técnicos (cobra y no va, sobreprecio, trabajo innecesario, "te rompo algo para arreglarlo") | 3 | 4 | 12 | Verificación; pago final al terminar (modelo A, doc 03); precios fijos en oferta; presupuesto adicional aprobado por el cliente en la app. |
| R12 | Reseñas falsas o extorsivas | 3 | 3 | 9 | Reseña solo con trabajo `completed` y pago confirmado (ya en arquitectura); detección de cuentas cruzadas; moderación; derecho a réplica. |
| R13 | Contracargos y saldo negativo del técnico | 3 | 3 | 9 | Ver doc 03; contrato; límites de monto para técnicos nuevos. |
| R14 | Riesgo regulatorio de pagos (custodia de fondos de terceros) | 2 | 5 | 10 | **No custodiar fondos** (modelo split). [ABOGADO] |
| R15 | Riesgo impositivo (ingresos no declarados, IVA, IIBB) | 3 | 4 | 12 | Contador desde el día 1 (doc 03). |
| R16 | Conflicto de marca ("Fixi") | 3 | 3 | 9 | Búsqueda y registro tempranos; considerar nombres alternativos (sección 10). |
| R17 | Dependencia de Mercado Pago (cambios de condiciones, bloqueo de cuenta) | 3 | 4 | 12 | Ser claro con la documentación; plan B con otro PSP (doc 03); no concentrar todo en una cuenta personal. |
| R18 | Caída del servidor en una sola PC | 4 | 3 | 12 | Migrar a un VPS; copias de seguridad diarias; monitoreo. |
| R19 | Incidente reputacional viral (un caso grave en redes) | 2 | 5 | 10 | Verificación; protocolo de crisis; respuesta rápida; seguro. |
| R20 | Conflictos entre cliente y técnico sin solución (cobro de materiales, garantías) | 5 | 2 | 10 | Disputas con reglas claras, evidencia (fotos/chat), tiempos de respuesta publicados. |

## 3. Responsabilidad por daños o mal trabajo

- **Rol buscado**: Fixi es **intermediario tecnológico**; el servicio lo presta el técnico, que responde por la calidad del trabajo y daños. Eso se escribe en los T&C (doc 05) y en el contrato (doc 06).
- **Problema real**: frente a un consumidor, una cláusula no te libera de responsabilidad si la ley te la atribuye. La **Ley 24.240** (defensa del consumidor) en su **art. 40** establece una responsabilidad solidaria de la cadena de comercialización por daños derivados del vicio o riesgo de la cosa o del servicio (**[NO VERIFICADO]** el texto exacto en esta sesión; el art. 40 es el que la jurisprudencia discute, ver sección 5). Además, el art. 37 considera abusivas las cláusulas que desnaturalicen obligaciones o limiten la responsabilidad por daños (**[NO VERIFICADO]**; mi conocimiento). **Implicancia práctica**: la "limitación de responsabilidad" del borrador es una **defensa razonable pero no blindaje**; no te guíes por ella para no asegurarte.
- **Qué hacer**:
  1. Seguro de **responsabilidad civil de la plataforma** (a nombre de la sociedad) y exigir **RC del técnico** en rubros de riesgo (sección 8).
  2. **Procedimiento de reclamo** documentado: el cliente reporta en la app dentro de X días, con fotos; Fixi media y, si corresponde, activa el seguro.
  3. **Fondo de garantía** modesto (por ejemplo, retener un porcentaje chico de las comisiones o una reserva propia) para casos menores. **[ESTIMACIÓN]**
  4. Guardar evidencia: chat, fotos, ubicación, horario de llegada, consentimiento.
  5. No usar frases como "técnicos garantizados por Fixi" en publicidad si no hay garantía real (publicidad engañosa).

## 4. Relación de dependencia laboral encubierta

### 4.1 Marco legal verificado (con fuentes secundarias)

- **Ley 27.802 de Modernización Laboral** (publicada según una fuente el 6/3/2026; otras fuentes hablan del Decreto 137/2026 y de vigencia desde el 1/6/2026: **las fechas no coinciden entre fuentes**, verificá en el Boletín Oficial): establece un régimen de **"prestadores independientes de plataformas tecnológicas"**, pero el título referido tiene como objeto los **servicios privados de movilidad de personas y/o reparto** (por el índice de la ley). **Los técnicos a domicilio probablemente NO están alcanzados por ese régimen específico**, por lo que no cuentan con su "paraguas" (que, por ejemplo, para repartidores y conductores exige seguro de accidentes personales a cargo de la plataforma). Fuentes: https://garciaalonso.com.ar/blog/ley-27802-modernizacion-laboral/ (texto de la ley no oficial), https://elvocero.com.ar/2026/02/13/reforma-laboral-que-cambia-para-repartidores-y-conductores-de-plataformas-digitales/ , https://procesoslegales.ar/articulo-plataformas-laborales.html . **[ABOGADO LABORALISTA]**: confirmar alcance exacto y si se podría extender por analogía.
- La misma norma, según esa fuente, deja el **art. 23 de la LCT** con la presunción de relación laboral, **pero no se aplica** "cuando mediaren contrataciones de obras o de servicios profesionales" siempre que se emitan facturas o recibos y el pago siga los sistemas bancarios o los que determine la reglamentación. Esto es **muy favorable** para el modelo de Fixi (técnico que factura y cobra por banco/MP), pero hay que verificar el texto vigente. También excluye de la LCT a los "trabajadores independientes y sus colaboradores" según el art. 97 de la Ley 27.742 (misma fuente). **[ABOGADO LABORALISTA]**.
- Otra nota cita que la Suprema Corte bonaerense confirmó en abril de 2026 que repartidores de Rappi y PedidosYa eran dependientes bajo el régimen previo (https://www.asistentelaboralargentino.com/guias/trabajo-en-plataformas-apps.html). **Aparece en una sola fuente y no lo verifiqué.** Muestra que la jurisprudencia puede ir en sentido contrario si el vínculo es de dependencia real.

### 4.2 Cómo estructurar Fixi para sostener independencia

Los indicios de dependencia que miran los jueces (subordinación técnica, económica y jurídica; exclusividad; horarios; órdenes; uniforme; fijación de precio por la empresa; sanciones disciplinarias) se evitan así:

| Indicio de dependencia | Cómo lo evita Fixi |
|---|---|
| Fijación de precio | El técnico fija su precio en cada oferta. Fixi no publica tarifas obligatorias. |
| Horarios y disponibilidad | El técnico decide cuándo conectarse; sin turnos, sin mínimo de pedidos. |
| Exclusividad | Puede trabajar para otras plataformas y clientes propios. **La cláusula contra "arreglar por fuera" es solo respecto de trabajos originados en Fixi** y de ningún modo prohíbe otros clientes. |
| Órdenes e instrucciones | Fixi no dirige cómo trabajar, solo requisitos de seguridad, identidad y calidad mínima. |
| Herramientas y riesgo | Herramientas, vehículo, seguro y gastos son del técnico. |
| Facturación | El técnico factura por su cuenta (monotributo/IVA), con CUIT. |
| Pago | Se paga por trabajo (precio de obra/servicio), no por tiempo. |
| Sanciones | Suspensión por **incumplimiento de estándares verificables**, con aviso y descargo; no "disciplina". |
| Uniforme / marca | Insignia opcional; no uniforme obligatorio. |
| Control | Calificaciones de clientes (control "por mercado"), no supervisión. **Atención**: los sistemas de ranking y desactivación fueron considerados indicios por algunos tribunales en otros países; **[NO VERIFICADO]** en Argentina para esta actividad. |
| Capacitación | Opcional y gratuita. |

Y además: contrato escrito de **locación de servicios / prestación independiente** (doc 06); cláusula de que no hay relación laboral; evidencia de que son varios los clientes de cada técnico; **no contratar técnicos como "full time"** ni darles tareas fuera del marketplace (por ejemplo, atender tu soporte).

## 5. Defensa del consumidor y responsabilidad de plataformas

### 5.1 Qué aplica

- **Ley 24.240** (Defensa del Consumidor) y el Código Civil y Comercial (relaciones de consumo, contratos celebrados a distancia). Los clientes de Fixi son consumidores en la mayoría de los casos. Aplican: deber de información clara (precio final, quién presta el servicio, comisión), trato digno, prohibición de cláusulas abusivas, y el Capítulo sobre **prestación de servicios** (arts. 19 a 23, **[NO VERIFICADO]** numeración exacta; incluyen presupuesto por escrito y garantía de reparaciones). **[ABOGADO]**.
- **Derecho de arrepentimiento (revocación)**: para contratos a distancia, la Ley 24.240 (art. 34) y el CCyC (arts. 1110 y ss.) prevén el derecho de revocar dentro de 10 días corridos (**[NO VERIFICADO]** en esta sesión). Hay excepciones para servicios cuya ejecución comenzó con acuerdo del consumidor (**[ABOGADO]** definir cómo aplica a un servicio a domicilio que se ejecuta pocas horas después de la contratación; lo más prudente es **permitir cancelar sin costo antes de que el técnico salga** y definir cargos de cancelación razonables por escrito).
- **Botón de arrepentimiento**: la **Resolución 424/2020** de la Secretaría de Comercio Interior obliga a los proveedores que comercializan a distancia a tener un enlace destacado, de fácil acceso, sin registro ni trámites adicionales para ejercer el derecho. La denominación es estricta ("Botón de Arrepentimiento", según un antecedente administrativo citado). Fuente: https://www.argentina.gob.ar/normativa/nacional/norma-342869/texto . **Debe estar en la app y en la web**. [ABOGADO] ver si aplica a servicios y cómo se articula con el modelo de cancelación.
- **Botón de baja**: la Res. 316/2018 (mi conocimiento, **[NO VERIFICADO]**) exige poder dar de baja servicios contratados por la misma vía. Ofrecer un "eliminar mi cuenta" en la app también cubre la Ley 25.326.
- **Competencia local**: además de la nacional, la **provincia/CABA** tienen sus propias autoridades de aplicación (Dirección General de Defensa del Consumidor, etc.) y sanciones. **[ABOGADO]**.

### 5.2 Jurisprudencia sobre marketplaces (relevamiento parcial, **no es exhaustivo**)

La jurisprudencia **está dividida** en si una plataforma responde solidariamente (art. 40 Ley 24.240) o es un simple intermediario. Criterio dominante: **cuanto más rol activo tenga la plataforma (cobra, organiza la logística, ofrece garantías), más probable es la responsabilidad.** Casos citados por fuentes secundarias:

| Caso (según fuentes) | Tribunal | Criterio | Fuente |
|---|---|---|---|
| **Almirón** | Cámara Nacional de Apelaciones en lo Comercial, Sala B | Condenó a Mercado Libre: **no se limitó a publicar el aviso**; intervino en el cobro (Mercado Pago) y organizó la logística (Mercado Envíos); el programa "Compra Protegida" no la exime de responsabilidad objetiva y solidaria. | https://www.diariojudicial.com/news-102984-mercado-libre-no-fue-solo-intermediario ; https://aldiaargentina.microjuris.com/2026/04/27/fallos-compra-online-fallida-mercado-libre-responde-solidariamente-por-un-tv-defectuoso-vendido-en-su-plataforma-junto-al-vendedor-y-fabricante-por-no-considerarlo-un-simple-intermediario-confir/ |
| **Kosten** | (según reseña doctrinaria) | Mercado Libre fue "mero canal" (hosting pasivo); se rechazó aplicar el art. 40. | https://pagbam.com/articulos/mapa-jurisprudencial-de-la-responsabilidad-de-las-plataformas-de-e-commerce-en-argentina/ |
| **Vergara** | Cámara Comercial, Sala E (según reseña) | No hubo un supuesto que hiciera atribuible a la plataforma responsabilidad solidaria por incumplimiento de otro proveedor. | misma fuente |
| **Squadroni** | Juzgado civil de Choele Choel (Río Negro), según nota periodística | Condena solidaria a plataforma, logística y vendedor en un caso de cancelación de compra. | https://mariovadillo.com.ar/mercado-libre-condenado-compra-cancelada-reclamar-fallo/ (nota periodística; no verificada en el expediente) |

**Advertencias**: son reseñas y notas, no los fallos completos; **no pude confirmar** si hay doctrina de la Corte Suprema que unifique el criterio. Un abogado de consumo tiene que revisarlos antes de basarte en ellos.

**Aplicación a Fixi (mi lectura [ESTIMACIÓN])**: Fixi **cobra** (por MP) y **ordena** (score, badge, comparación) y **cobra comisión por trabajo**: se parece más a la plataforma con rol activo (Almirón) que al "hosting pasivo". **Contá con que un juez podría condenar a Fixi solidariamente por un mal trabajo o por un daño.** Por eso: seguro, verificación, buen proceso de reclamo, y no prometas en la comunicación lo que no controlás.

## 6. Protección de datos personales (Ley 25.326)

- Fixi trata **datos personales** de clientes y técnicos: nombre, teléfono, email, DNI, selfie, domicilio, **ubicación geográfica**, reseñas, historial de trabajos, documentos de matrícula, antecedentes penales (dato sensible para varios criterios: **tratalo con el máximo cuidado**).
- **Registro**: la AAIP establece que las bases de datos personales deben inscribirse en el **Registro Nacional de Bases de Datos Personales**; primero se inscribe el responsable y luego cada base, vía Trámites a Distancia con clave fiscal nivel 2 o superior; la inscripción no vence pero debe actualizarse ante cambios. Fuentes: https://www.argentina.gob.ar/aaip/datospersonales/tramites y https://www.argentina.gob.ar/servicio/inscribir-un-responsable-de-bases-de-datos-personales-privadas . **[ABOGADO]** confirmar si tu base está obligada y qué cambios trae la normativa más reciente (algunos instructivos que vi son de 2018).
- Principios (de memoria; **[NO VERIFICADO]** numeración): consentimiento informado, finalidad, calidad, seguridad, confidencialidad, derechos de acceso, rectificación y supresión; transferencia internacional restringida a países con nivel adecuado de protección (relevante si usás servicios de nube extranjeros, Firebase, Google Maps, etc.).
- **Geolocalización**: ubicación del técnico durante el trabajo y la del cliente (domicilio): informar claramente, **limitar a lo necesario** (solo durante el trabajo en curso), no guardar rutas más tiempo del requerido.
- **Seguridad**: el diseño actual corre el servidor y una base SQLite **en una PC**. Para datos sensibles es débil (cortes, robo, ransomware, sin copias). **Mudá a un servidor controlado** con cifrado, copias de seguridad diarias y acceso restringido antes de lanzar. Ocultá en el panel admin documentos y teléfonos a quien no los necesite.
- **Documentación**: política de privacidad (doc 07), procedimiento para ejercer derechos (mail dedicado), plan de respuesta ante brechas, contratos con proveedores que tocan datos (hosting, Mercado Pago, mapas).

## 7. Trabajos regulados (gas, electricidad, etc.)

- **Gas**: la instalación y reparación de instalaciones de gas exige profesionales matriculados; según fuentes secundarias, la matrícula la otorgan las distribuidoras (Metrogas, Naturgy, etc.) bajo normativa de ENARGAS, vence anualmente y se exige seguro de accidentes personales y de responsabilidad civil (https://servidos.ar/blog/habilitaciones-matriculas-oficios-buenos-aires; fuente comercial). **Cambio reciente verificado**: la **Resolución ENARGAS 468/2026** deroga el régimen de matrículas de "Instalador de Sistemas de Combustión" (Res. I/902/2009) y lo vuelve optativo, y aprueba la NAG-201 (2026) (https://www.argentina.gob.ar/normativa/nacional/norma-425486/texto); **no modifica, según el texto leído, la matrícula de gasista de primera categoría**, pero no leí los anexos. **[ABOGADO/ENARGAS]** confirmá antes de habilitar gas.
- **Electricidad**: la exigencia de matrícula varía por jurisdicción; según una guía comercial, en CABA se pide matrícula de la AGC para instalaciones eléctricas (no verificada en fuente oficial). **[VERIFICAR]** en tu zona.
- **Política de Fixi [ESTIMACIÓN]**: solo técnicos con matrícula vigente en rubros regulados; la app **no permite ofertar** en esas categorías sin matrícula verificada; el contrato exige informar cambios.

## 8. Seguros posibles

**No pude verificar precios ni disponibilidad.** Tipos a cotizar con un productor asesor:

| Seguro | Quién lo toma | Qué cubre | Nota |
|---|---|---|---|
| Responsabilidad civil de la plataforma (RC / "tecnología y servicios") | Fixi (idealmente la sociedad) | Reclamos de terceros por daños relacionados con servicios intermediados | Preguntar si cubre el rol de intermediación y si exige que los técnicos tengan RC |
| RC del técnico (RC profesional / comprensiva) | Técnico | Daños a bienes/personas durante el trabajo | Obligatorio para rubros de riesgo (gas, electricidad, aire); a determinar |
| Accidentes personales (AP) | Técnico o Fixi (grupal) | Lesiones del técnico durante el trabajo | **Importante para evitar reclamos y por la naturaleza física del oficio**. La Ley 27.802 impone seguro de AP a plataformas de movilidad/reparto (no a técnicos a domicilio, **según mi lectura**); igualmente es una buena práctica. |
| ART | Solo si hay empleados | - | **No aplica a monotributistas independientes**; no lo uses con técnicos para no fortalecer una lectura de dependencia. [ABOGADO] |
| Ciber / datos | Fixi | Brecha de datos | Opcional al inicio |

**[ESTIMACIÓN]**: cotizá 3 aseguradoras y un corredor; decidí qué seguros se exigen antes de lanzar rubros de riesgo.

## 9. Fraude y reseñas falsas

- Reseña solo con trabajo `completed` y pago hecho (ya es regla de `ARQUITECTURA.md`).
- Límite de reseñas por dupla cliente-técnico; detección de cuentas con el mismo dispositivo, IP o teléfono.
- Moderación de comentarios injuriosos; derecho de réplica del técnico; canal para denunciar reseñas falsas.
- **Contracargos**: ver doc 03.
- Cuentas nuevas con límites: monto máximo por trabajo, verificación del medio de pago.
- Alertas: técnicos con picos de reseñas 5 estrellas inusuales; clientes con múltiples disputas.

## 10. Marca "Fixi" (INPI)

### 10.1 Qué encontré, sin vueltas

**No pude consultar la base del INPI** (es un buscador dinámico que no puedo operar desde acá). Por lo tanto **no puedo decirte si "Fixi" ya está registrada en Argentina**; tenés que hacer esa búsqueda vos (gratuita) y, idealmente, encargar una **búsqueda arancelada fonética** al INPI, que es la que detecta variantes (Fixy, Fixxi, Fixie, "Fixi" + otra clase). Pasos y costos: https://www.iprofesional.com/legales/450840-como-saber-si-una-marca-ya-esta-registrada-en-el-inpi-guia-practica-para-emprendedores y https://www.argentina.gob.ar/inpi/marcas/registrar-una-marca .

**Pero sí encontré, por búsqueda web, que el nombre está bastante usado en servicios similares**:

| Hallazgo | Qué es | Fuente |
|---|---|---|
| **"Fixi App"** (iOS, tienda de México) | App de **servicios del hogar** (limpieza, plomería, albañilería, fumigación y electricidad), con pago con tarjeta y agenda. Desarrollador: Guillermo Caballero. **Es la misma actividad y casi el mismo nombre.** | https://apps.apple.com/mx/app/fixi-app/id6447027617 |
| **"FIXI" (com.fixi.now)** (Google Play) | App de reserva de reparación y mantenimiento del hogar (aire acondicionado, heladeras, calefones, TV, etc.). La URL que probé directamente dio error 404 al día de hoy, pero apareció en resultados de búsqueda. | https://play.google.com/store/apps/details?id=com.fixi.now&hl=es_MX |
| **"Fixi"** (roadside) | App de asistencia en ruta (combustible, cerrajería de autos, batería, remolque). | https://apps.apple.com/us/app/-/id6474078825 (aparece sin nombre en la búsqueda; verificar) |
| **"Fixi"** (productividad) | App para técnicos de electrodomésticos (códigos de falla, formularios). | https://mwm.ai/apps/fixi/6738955372 |
| **Fixii** (con doble "i") | Plataforma por chat/WhatsApp para coordinar técnicos del hogar, tiene app "Fixii - Servicios a Domicilios". | https://fixii.app/como-funciona |
| **Fixer / Fixio / FixZone** | Otras apps de servicios del hogar con nombres parecidos. | resultados de Google Play / App Store |
| **fixi.com.ar** | Existe un sitio con el nombre "Fixi" (WordPress), con página protegida o con errores de PHP; no pude saber a qué se dedica ni quién es el titular. | https://fixi.com.ar |
| **FixUP!** | Startup argentina de reparación de equipos (tecnología); nombre parecido en el mismo mercado. | https://www.cronista.com/infotechnology/it-business/que-es-fixup-la-solucion-argentina-para-reparar-tecnologia-sin-gastar-de-mas |

### 10.2 Lectura de riesgo [ESTIMACIÓN, no es opinión legal]

- **Registrar la marca en Argentina es territorial.** Las apps de México y de otros países **no bloquean por sí solas** una marca argentina, **salvo que alguien las haya registrado también en Argentina**, o que exista reclamo por uso previo/mala fe. Eso hay que confirmarlo.
- El **riesgo comercial** es alto aunque el legal fuera bajo: nombre muy poco distintivo (diminutivo genérico de "fix"), **varias apps casi homónimas en el mismo rubro**, difícil de posicionar en buscadores y tiendas, y confusión con Fixii/FixUP. Si más adelante querés expandirte a México u otros países, hay un conflicto probable.
- **Veredicto**: si la búsqueda en INPI y TMView muestra una "Fixi" o similar en clases 35, 37, 42 o 9 (ver 10.3), **cambiá el nombre** antes de invertir. Si no la hay, **registrá ya** pero entendé que tu nombre va a ser débil comercialmente.

### 10.3 Qué hacer, en orden

1. **Buscar** en el buscador de marcas del INPI (denominación idéntica y variantes: Fixi, Fixy, Fixie, Fixxi, Fiksi) y en **TMView** (gratuito) por similitud. Anotá titular, clase y estado.
2. **Búsqueda arancelada fonética** del INPI (costo no verificado en esta sesión) si la primera es limpia.
3. Elegir **clases de Niza** (la numeración la conozco de memoria; **verificala**): **35** (intermediación comercial, plataformas de mercado), **42** (software/servicios tecnológicos), **37** (reparación e instalación) y **9** (aplicaciones descargables). El INPI cobra por clase: **$216.000 + IVA por clase** según una guía de 2026 (confirmar en el sitio del INPI); con las 4 clases serían $864.000 + IVA, con 2 clases (35 y 42) $432.000 + IVA. Se solicita por clase específica, no "toda la clase" (https://www.argentina.gob.ar/inpi/marcas/registrar-una-marca).
4. Procedimiento: solicitud online con clave fiscal nivel 2, firma electrónica, pago; publicación en el Boletín de Marcas con **30 días para oposiciones**; vigencia de **10 años**, renovable (ambas fuentes citadas). Plazos informados: de 2 a 6 meses según haya o no oposiciones. **[ABOGADO/AGENTE DE LA PROPIEDAD INDUSTRIAL]** sobre el "uso" para evitar caducidad.
5. **Dominio y redes**: reservá `fixi.com.ar` (ya existe un sitio con ese nombre; ¿de quién es?), handles de Instagram/TikTok. Si el dominio no está disponible, otra señal para cambiar el nombre.
6. **Alternativas** (ideas **sin verificar**, para pasar por la misma búsqueda): "Arreglá", "YaRepara", "Manitas", "Resolví", "Técnico Ya", "Tecnia", "Fixea". Elegí algo **descriptivo + distintivo** y cuyo dominio .com.ar esté libre.

## 11. Lo que tiene que revisar un abogado (lista corta)

1. Borradores 05, 06, 07 completos.
2. Estructura societaria y responsabilidad patrimonial.
3. Independencia laboral de los técnicos (laboralista).
4. Régimen de custodia de fondos y regulación de pagos si cambiás a "Fixi retiene".
5. Marca y búsqueda.
6. Cláusula de no desintermediación (validez).
7. Botón de arrepentimiento y cancelaciones.
8. Registro AAIP y política de datos.
9. Matrículas en gas y electricidad.

## Fuentes

- https://garciaalonso.com.ar/blog/ley-27802-modernizacion-laboral/
- https://elvocero.com.ar/2026/02/13/reforma-laboral-que-cambia-para-repartidores-y-conductores-de-plataformas-digitales/
- https://procesoslegales.ar/articulo-plataformas-laborales.html
- https://www.asistentelaboralargentino.com/guias/trabajo-en-plataformas-apps.html
- https://www.diariojudicial.com/news-102984-mercado-libre-no-fue-solo-intermediario
- https://aldiaargentina.microjuris.com/2026/04/27/fallos-compra-online-fallida-mercado-libre-responde-solidariamente-por-un-tv-defectuoso-vendido-en-su-plataforma-junto-al-vendedor-y-fabricante-por-no-considerarlo-un-simple-intermediario-confir/
- https://pagbam.com/articulos/mapa-jurisprudencial-de-la-responsabilidad-de-las-plataformas-de-e-commerce-en-argentina/
- https://mariovadillo.com.ar/mercado-libre-condenado-compra-cancelada-reclamar-fallo/
- https://www.argentina.gob.ar/normativa/nacional/norma-342869/texto
- https://www.argentina.gob.ar/aaip/datospersonales/tramites
- https://www.argentina.gob.ar/servicio/inscribir-un-responsable-de-bases-de-datos-personales-privadas
- https://www.argentina.gob.ar/normativa/nacional/norma-425486/texto
- https://servidos.ar/blog/habilitaciones-matriculas-oficios-buenos-aires
- https://www.argentina.gob.ar/inpi/marcas/registrar-una-marca
- https://www.iprofesional.com/legales/450840-como-saber-si-una-marca-ya-esta-registrada-en-el-inpi-guia-practica-para-emprendedores
- https://apps.apple.com/mx/app/fixi-app/id6447027617
- https://play.google.com/store/apps/details?id=com.fixi.now&hl=es_MX
- https://fixii.app/como-funciona
- https://fixi.com.ar
