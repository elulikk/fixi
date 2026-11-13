# Fixi - Resumen ejecutivo comercial y legal

> Fecha: 13/11/2026. Investigación hecha por búsqueda web; **no es asesoramiento legal ni contable**. Todo lo que se apoya en una fuente la lleva en el documento correspondiente; lo que no pude verificar está marcado. Los borradores 05, 06 y 07 **no fueron revisados por un abogado**.

## Los 3 hallazgos que condicionan todo

1. **"Fixi" es un nombre flojo.** Encontré varias apps con el mismo nombre o casi igual en el mismo rubro (una de servicios del hogar en la tienda de México, otra de reparaciones en Google Play, Fixii, Fixer, FixUP!, y un sitio `fixi.com.ar` ya activo). No pude consultar el INPI, así que no sé si hay una marca registrada en Argentina: **buscalo vos antes de invertir** (doc 04, sección 10).
2. **La "retención de pagos" no está documentada por Mercado Pago.** La documentación pública del split 1:1 explica `marketplace_fee`, OAuth y reembolsos, pero **no dice que se pueda retener el dinero hasta que el cliente confirme**. Además, el costo de MP lo paga el técnico (de 1,49% a 6,29% + IVA según plazo) y la propia página dice que el split solo admite "dinero en cuenta" (ambiguo). Hay que preguntarle a MP antes de prometer nada (doc 03).
3. **Con 5% el negocio necesita volumen.** Con un ticket de $55.000 (supuesto), Fixi gana ~$2.750 por trabajo: ~125 trabajos/mes cubren costos operativos mínimos y ~750/mes un ingreso personal razonable (doc 03).

## Las 10 decisiones y acciones, en orden

1. **Resolver el nombre.** Buscar en INPI y TMView; si hay conflicto, cambiar el nombre antes de seguir. Después, registrar en clases 35 y 42 (mínimo). Ver [04](04-riesgos-y-legal.md) sección 10.
2. **Definir cómo se cobra.** Escribirle a Mercado Pago con las 7 preguntas del doc 03; mientras tanto, **pasar el MVP a "pago al finalizar el trabajo"** (opción A) para no prometer una retención que no podés cumplir. Ver [03](03-pagos-comisiones-e-impuestos.md).
3. **Estructura fiscal y legal con un contador.** Monotributo para validar y SAS antes de escalar o de abrir rubros riesgosos; preguntar si la factura de la comisión lleva IVA y qué cuenta como ingreso. Ver [03](03-pagos-comisiones-e-impuestos.md) secciones 8 y 9.
4. **Abogado para revisar** T&C, contrato de técnicos y política de privacidad antes del primer usuario real, con foco laboral (independencia) y de consumo (responsabilidad solidaria). Ver [05](05-terminos-y-condiciones-borrador.md), [06](06-contrato-tecnicos-borrador.md), [07](07-politica-de-privacidad-borrador.md).
5. **Elegir 1-2 barrios y 3 rubros ancla** (propuesta: electricista, plomero, aire acondicionado; dejar gas y cerrajería para después). Ver [01](01-plan-de-lanzamiento.md) secciones 3 y 7.
6. **Empezar por la oferta**: 15 técnicos fundadores en 2 semanas (ferreterías, grupos, referidos), llegar a 50 en 90 días; vos hacés de "concierge" para que ningún pedido quede sin ofertas. Ver [01](01-plan-de-lanzamiento.md) y [02](02-propuesta-para-tecnicos.md).
7. **Verificar a los técnicos por niveles** (DNI, CUIT, antecedentes, matrícula) y no activar gasistas hasta confirmar el régimen de matrícula vigente (hay cambios de ENARGAS en 2026). Ver [02](02-propuesta-para-tecnicos.md) sección 7 y [04](04-riesgos-y-legal.md) sección 7.
8. **Seguros y seguridad**: cotizar RC de plataforma y exigir RC a los técnicos de rubros de riesgo; sumar código de llegada, selfie y compartir ubicación. Ver [04](04-riesgos-y-legal.md) secciones 2 y 8.
9. **Datos personales e infraestructura**: inscribir la base en la AAIP y **sacar el servidor de una PC** (hosting con backups) antes de guardar DNI, antecedentes y ubicación. Ver [04](04-riesgos-y-legal.md) sección 6 y [07](07-politica-de-privacidad-borrador.md).
10. **Medir y expandir solo con umbrales**: liquidez de oferta ≥ 80%, primera oferta ≤ 20 min, recompra ≥ 20% a 30 días, fuga < 10%, disputas ≤ 3%. Competí contra Servidos.ar (0% de comisión hoy, según su sitio) con cobro asegurado y comparación de ofertas, no con precio. Ver [01](01-plan-de-lanzamiento.md) secciones 9 y 10 y [02](02-propuesta-para-tecnicos.md) sección 3.

## Índice de documentos

| Doc | Contenido |
|---|---|
| [01 - Plan de lanzamiento](01-plan-de-lanzamiento.md) | Go-to-market, zona y rubros, 50 técnicos y 200 clientes, calendario de 90 días, presupuesto, métricas y umbrales |
| [02 - Propuesta para técnicos](02-propuesta-para-tecnicos.md) | Propuesta de valor, competidores, incentivos, antifuga, guiones, verificación |
| [03 - Pagos, comisiones e impuestos](03-pagos-comisiones-e-impuestos.md) | Split de Mercado Pago, retención, costos, economía unitaria, impuestos |
| [04 - Riesgos y legal](04-riesgos-y-legal.md) | Matriz de riesgos, laboral, consumidor, datos, regulados, seguros, marca |
| [05 - T&C (borrador)](05-terminos-y-condiciones-borrador.md) | Términos y condiciones |
| [06 - Contrato técnicos (borrador)](06-contrato-tecnicos-borrador.md) | Contrato de adhesión de técnicos independientes |
| [07 - Privacidad (borrador)](07-politica-de-privacidad-borrador.md) | Política de privacidad |

## Preguntas abiertas para el fundador (solo vos podés decidirlas)

1. ¿En qué ciudad y barrios vivís y conocés gente? (define la zona ancla).
2. ¿Cuántas horas por semana podés dedicar a soporte y a operar de "concierge" en los primeros 90 días? ¿Hay alguien de respaldo?
3. ¿Qué presupuesto real tenés para 90 días: cero, bajo o medio (doc 01 sección 8)?
4. ¿Mantenés el nombre "Fixi" si hay conflicto o preferís cambiar antes de invertir en la marca?
5. ¿Aceptás cambiar a "pago al finalizar" en el MVP si MP no permite retener? ¿O querés custodiar fondos (opción D, con riesgo legal e impositivo)?
6. ¿Monotributo o sociedad (SAS) desde el principio? ¿Estás dispuesto a asumir responsabilidad personal en los primeros meses?
7. ¿La comisión es 5% neto o final (con IVA)? ¿Querés escalonarla por nivel y por recurrencia?
8. ¿Cuánta comisión estás dispuesto a regalar para captar técnicos (0% por 20 trabajos, insignia, bonos)?
9. ¿Qué rubros dejás afuera por riesgo (gas, cerrajería) y hasta cuándo?
10. ¿Cuánto control de identidad del técnico y del cliente es aceptable aunque baje la conversión?
11. ¿Querés exigir seguro de RC a los técnicos desde el día 1 o solo en rubros de riesgo?
12. ¿Vas a distribuir la app solo por APK o también por Google Play (confianza y datos)? 
13. ¿Querés ofrecer cuotas en la app (suman costo al técnico)?
14. ¿Cuál es tu posición ante la cláusula de no desintermediación y su penalidad?

## Qué no pude verificar (resumen)

- Estado del nombre "Fixi" en el INPI (la base no se puede consultar desde mi entorno).
- Retención de fondos, contracargos, medios de pago y requisitos del split de Mercado Pago en Argentina.
- Comisiones vigentes de IguanaFix, Zolvers, Mercado Libre servicios, Home Solution y GetNinjas.
- Alícuotas de Ingresos Brutos, costos de constituir una SAS y de seguros.
- Texto oficial de la Ley 27.802 (alcance a técnicos a domicilio) y de varios artículos de la Ley 24.240, el CCyC y la Ley 25.326 que cito de memoria.
- Régimen vigente de matrícula de gasista y electricista en tu jurisdicción.
