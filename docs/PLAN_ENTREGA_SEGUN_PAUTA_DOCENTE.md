# Plan de entrega según la pauta del docente

Basado en las cuatro capturas compartidas por el grupo. El mensaje sobre el lunes 26 de octubre convoca a explicar y ejemplificar las entregas y coordinar los archivos; no especifica en ese mensaje que todos los videos finales deban entregarse ese día.

## 1. Interpretación de las entregas

| Entrega | Contenido visible en la pauta | Límite visible |
|---|---|---|
| Video 1 completo | Presentación, título, problema, prototipo administrativo, módulos, jerarquía de usuarios y siete grupos de requerimientos | Hasta 1 hora |
| Resumen del Video 1 | Síntesis del primer video; subir al canal y compartir dirección web | Hasta 5 minutos |
| Video 2 completo | Unidad III UML-E y Unidad V UWE, con contenidos de cada módulo del prototipo | Hasta 1 hora |
| Resumen del Video 2 | Síntesis del segundo video; subir al canal y compartir dirección web | Hasta 5 minutos |

Son dos videos principales y sus dos resúmenes, según las páginas visibles. Los doce capítulos de la guía de grabación anterior sirven como material para organizar la demostración; no son doce entregas exigidas por el profesor. La pauta tampoco obliga a ocupar toda la hora.

La petición de separar diagramas por módulos proviene de la explicación del estudiante y es coherente con la frase de la pauta «Contenidos de los documentos de cada módulo del prototipo del sistema». Conviene presentar esta organización al docente para confirmar el nivel de detalle, sin atribuirle una cantidad de diagramas que no aparece fijada en las capturas.

## 2. Preparación para la explicación en el aula

Llevar esta propuesta, una captura de cada recorrido principal y los diagramas previos disponibles. No hace falta afirmar que el material anterior está completo.

**Exposición breve propuesta:**

> Nuestro proyecto es el sistema administrativo de Instalaciones Raquel. Para el primer video explicaremos el problema, los requerimientos, los perfiles de usuario y la funcionalidad de los módulos mediante un caso de compra, recepción, venta, cobro y pago individual de nómina. Mostraremos qué información pasa entre módulos y qué operaciones requieren confirmación. Para el segundo video reorganizaremos los diagramas por módulos: casos de uso, clases y objetos; después los relacionaremos con los modelos de UWE. Prepararemos un resumen de hasta cinco minutos para cada video. Queremos confirmar si los diagramas deben ser archivos separados o secciones de un mismo documento y qué agrupación de módulos recomienda.

**Tres puntos para confirmar en clase:**

1. Si los contenidos modulares deben entregarse en un documento con capítulos, en archivos separados o en ambos formatos.
2. Si el docente acepta agrupar Caja/Bancos dentro de Finanzas, Nómina dentro de Recursos Humanos y Costos dentro de Contabilidad, manteniendo sus subdiagramas.
3. Qué formato, nombres de archivo y canales utilizar para los videos completos y los resúmenes. Las capturas mencionan publicar los resúmenes, pero no detallan todos los requisitos técnicos de los archivos.

## 3. Video 1: guion de contenido, máximo una hora

### Apertura

Mostrar una portada legible con:

- Universidad Nacional de Ingeniería.
- Área de Conocimiento: Tecnología de la Información y Comunicación, según la denominación de la pauta.
- Asignatura: Ingeniería de Software I.
- Grupo académico y grupo de trabajo, verificados por el equipo.
- Título del proyecto: Sistema administrativo para Instalaciones Raquel.
- Nombres completos y carnés revisados por cada integrante; no copiar automáticamente datos manuscritos poco legibles.
- Docente: MSc. Juan Francisco Gómez Flores, según la pauta compartida.

### Distribución sugerida: 58 minutos

| Tiempo | Tema | Evidencia |
|---|---|---|
| 00:00–03:00 | Portada, integrantes, objetivo y alcance | Portada y Dashboard |
| 03:00–06:00 | Planteamiento del problema | Explicar dificultades de control, duplicación, existencias, dinero y trazabilidad que el equipo haya documentado |
| 06:00–14:00 | Siete grupos de requerimientos | Matriz con identificación, descripción, módulo y evidencia |
| 14:00–17:00 | Usuarios y permisos | Perfiles, área y límites de aprobación |
| 17:00–22:00 | Datos iniciales | Producto, proveedor y cliente del caso |
| 22:00–28:00 | Compras e Inventario | Recepción, lote, kardex y existencias |
| 28:00–34:00 | Ventas y conexión contable | Proforma, factura, salida de inventario y cuenta por cobrar |
| 34:00–38:00 | Proyectos y Producción | Orden y estados del trabajo; explicar referencias manuales |
| 38:00–44:00 | Finanzas, Caja/Bancos y Contabilidad | Confirmación de cobro, saldo, asientos y consultas disponibles |
| 44:00–51:00 | Recursos Humanos y Nómina | Expediente, período, cálculo, aprobación y un abono individual |
| 51:00–55:00 | Estadística, Reportes y Mercadotecnia | Indicadores disponibles, interpretación y catálogo |
| 55:00–58:00 | Auditoría, pendientes y conclusión | Referencias, control general y límites del prototipo |

Utilizar la guía GUIA_GRABACION_COMPLETA_INSTALACIONES_RAQUEL.md para ejecutar las acciones de cada tema. Ajustar sus capítulos a este índice académico. No añadir todas las tomas anteriores sin controlar el límite de una hora.

### Los siete grupos de requerimientos

La pauta enumera estos siete contenidos. La pantalla de ERS tiene filtros RF, RNF, RD, RU y RS; los ejemplos de lenguaje estructurado e interfaz deben prepararse además en el documento o en una lámina. No afirmar que existen siete pestañas si la pantalla solo ofrece cinco filtros.

| Grupo solicitado | Qué explicar | Ejemplo para revisar y documentar |
|---|---|---|
| Funcionales | Lo que hace el sistema | Registrar una recepción y reflejar su entrada en inventario |
| No funcionales | Condiciones de calidad | Control de acceso, persistencia y tratamiento de fallos; no prometer tiempos que no se hayan medido |
| Dominio | Reglas del negocio | PEPS, separación de factura y cobro, abonos que no superan el pendiente |
| Usuario | Necesidades de cada perfil | Finanzas consulta saldos; el responsable autorizado confirma o revisa operaciones |
| Sistema | Servicios y dependencias | Aplicación web, API y SQL Server; conexión y validaciones antes de persistir |
| Lenguaje estructurado | Una regla expresada paso a paso | SI la sesión es del día Y el importe es válido Y hay fondos para una salida, ENTONCES permitir confirmar; EN CASO CONTRARIO explicar el bloqueo |
| Interfaz | Entradas, controles y respuesta visual | Selector de trabajador, importe de abono, referencia, botón de confirmación y mensaje del resultado |

Para cada ejemplo: indicar su código existente si está documentado, pantalla donde se comprueba y condición de aceptación. No inventar códigos oficiales del corte anterior.

### Cómo explicar las conexiones

No basta con entrar a cada menú. En cada módulo responder:

1. ¿Quién lo utiliza?
2. ¿Qué información recibe?
3. ¿Qué operación realiza?
4. ¿Qué resultado deja?
5. ¿Qué otro módulo utiliza ese resultado?
6. ¿La conexión está implementada automáticamente, es una referencia manual o está planteada como diseño?

Ejemplo de narración:

> Compras registra la recepción de materiales. Esa recepción incorpora existencias y kardex en Inventario, y su asiento en Contabilidad. Después, Ventas consulta las existencias para facturar. La factura genera una cuenta por cobrar; Caja o Bancos confirma por separado la entrega del dinero. Así distinguimos los documentos comerciales, los materiales y el efectivo.

Segundo ejemplo:

> Recursos Humanos conserva la información laboral. Nómina utiliza los trabajadores y las reglas del período para calcular sus importes. Después de la revisión y aprobación, el pago individual consulta la cuenta seleccionada y sus fondos. Un abono reduce el pendiente del trabajador al que corresponde y deja su comprobante e historial.

### Contenidos que necesitan comprobarse antes de afirmar que están completos

- La pauta pide Balance General, Estado de Resultados y Flujo de Efectivo. Tener asientos, un cuadre o tarjetas de ingresos/egresos no demuestra por sí solo que los tres estados financieros completos estén implementados. Mostrar la pantalla y el documento que realmente existan; registrar las ausencias como pendientes.
- Estadística debe explicar qué datos se usan, el período y cómo se interpreta al menos un resultado; no limitarse a mostrar una gráfica.
- Un código escrito igual en Proyecto y Orden de Producción no prueba una relación automática por clave o un consumo de materiales automático. Distinguir referencia de integración efectiva.
- La pauta menciona DGI.ZIP. No se proporcionó su contenido en esta conversación y no se ha verificado su cobertura. No afirmar cumplimiento completo de ese archivo sin revisarlo.
- Los estados «Validado» del catálogo de requerimientos son etiquetas del proyecto. Deben contrastarse con la evidencia, no tomarse como una certificación independiente.
- Mantener visibles los pendientes históricos de Caja y Nómina que requieran documentos; no manipular saldos para que la demostración termine sin avisos.

### Resumen del Video 1: cinco minutos

| Tiempo | Contenido |
|---|---|
| 00:00–00:30 | Proyecto, equipo y problema |
| 00:30–01:00 | Perfiles y organización del sistema |
| 01:00–02:15 | Caso compra → inventario → venta, con referencias visibles |
| 02:15–03:00 | Cobro y efecto en Caja/Bancos |
| 03:00–04:00 | Personal → cálculo de nómina → abono individual |
| 04:00–04:40 | Contabilidad, indicadores y trazabilidad |
| 04:40–05:00 | Alcance demostrado y conclusión |

No intentar leer todo el documento en cinco minutos. El resumen debe seleccionar evidencia del video completo.

## 4. Propuesta de división de diagramas para el Video 2

Esta sección es una organización de trabajo. El desarrollo y la corrección de los diagramas del Corte 3 quedan para la siguiente etapa, como pidió el estudiante. No se sustituyen todavía los archivos originales, que no se encontraron en el proyecto revisado.

### Un mapa general y paquetes por módulos

Conservar un diagrama general pequeño para explicar el sistema. Después elaborar paquetes separados. No repetir todas las entidades y todos los actores en cada dibujo.

| Paquete propuesto | Pantallas o submódulos incluidos | Conexiones que debe explicar |
|---|---|---|
| 01. Usuarios y acceso | Usuarios, roles y sesión | Permisos de todos los módulos |
| 02. Clientes y Ventas | Clientes, proformas y facturas | Inventario, Contabilidad y cobro en Caja/Bancos |
| 03. Proveedores | Directorio y expediente | Compras y referencias de pagos |
| 04. Compras | Registro y recepción | Proveedores, Inventario y Contabilidad |
| 05. Inventario | Productos, lotes y kardex | Compras, Ventas y consulta de costos |
| 06. Producción | Órdenes y etapas del taller | Referencias de proyectos y clientes; separar automatismos de diseño |
| 07. Proyectos | Obras y avance | Cliente y referencia de orden de trabajo |
| 08. Finanzas | Caja, Bancos y proyecciones, con subdiagramas propios | Cobros, pagos, Nómina y referencias contables |
| 09. Contabilidad | Asientos, libros y Costos | Compras, Ventas y fuentes de cifras; distinguir estados financieros pendientes |
| 10. Recursos Humanos | Personal, contratos, permisos, asistencia y seguridad | Nómina; políticas de acceso y cumplimiento |
| 11. Nómina | Períodos, cálculo, aprobación, abonos y comprobantes | Recursos Humanos, Caja/Bancos y obligaciones |
| 12. Mercadotecnia | Catálogo, promociones y álbum | Productos y documentación comercial |
| 13. Estadística y Reportes | Indicadores y consultas | Fuentes de datos, períodos y resultados |
| Transversal. Auditoría y datos | Historiales, persistencia y control | Trazabilidad y validaciones; no duplicar todo el modelo en cada módulo |

Esta agrupación es una propuesta, no una cantidad exigida por la pauta. Si el docente prefiere Nómina dentro de Recursos Humanos, se conserva como capítulo con sus diagramas propios. Lo mismo aplica a Caja y Bancos dentro de Finanzas.

### Qué documentos preparar para cada paquete

La pauta visible pide casos de uso, clases y objetos, y cinco modelos de UWE. Trabajarlos en láminas separadas evita el diagrama único saturado.

| Documento | Pregunta que responde | Contenido mínimo de trabajo |
|---|---|---|
| Casos de uso | ¿Quién realiza qué función? | Actores, límite del módulo y funciones con sus relaciones justificadas |
| Clases | ¿Qué conceptos participan y cómo se relacionan? | Clases del módulo, atributos necesarios, operaciones pertinentes, relaciones y multiplicidades verificadas |
| Objetos | ¿Cómo se ve un ejemplo concreto? | Instancias de las clases anteriores, valores coherentes y enlaces de un mismo caso |
| UWE: lógico-conceptual | ¿Qué información maneja la aplicación en este módulo? | Conceptos de información y relaciones; explicar su correspondencia con clases, sin confundirlo con tablas físicas |
| UWE: navegación | ¿Cómo llega el usuario a cada información o tarea? | Nodos, rutas, menús, índices y accesos permitidos |
| UWE: presentación | ¿Cómo se presenta la interacción? | Pantallas, campos, listas, acciones y mensajes |
| UWE: contenido | ¿Qué contenido contiene y necesita cada vista? | Datos, documentos y agrupaciones que muestra o captura |
| UWE: procesos | ¿Qué pasos, decisiones y resultados tiene la operación? | Flujo principal, validaciones, errores, confirmación y salida |

Seguir la nomenclatura y las convenciones que el docente haya utilizado en la Unidad III y la Unidad V. La pauta agrupa casos de uso con los diagramas estructurales; conservar su índice de entrega y confirmar con el docente la terminología empleada en clase, sin rehacer el índice por una diferencia de clasificación.

No es necesario llenar ocho dibujos con la misma información. Cada modelo tiene una pregunta distinta. Documentar también las fases y etapas de UWE que hayan estudiado; no reemplazarlas por una lista de pantallas.

### Ejemplo de división: Nómina

- Casos de uso: preparar período, incluir trabajadores, calcular, revisar, aprobar, registrar abono, consultar comprobante, conciliar y cerrar; asignar cada función al actor que realmente tenga permiso.
- Clases: planilla, detalle individual, trabajador, novedad, validación, pago, asignación de pago y referencias de sesión/cuenta. Ajustar nombres y multiplicidades al código y SQL reales.
- Objetos: una planilla, dos trabajadores con netos distintos y un abono a uno de ellos. Los valores deben coincidir en todas las láminas.
- Navegación: Nómina → selección de planilla → Trabajadores / Validaciones / Aprobaciones / Pagos por trabajador / Comprobantes / Historial.
- Presentación: selector de persona, desglose individual, importe, medio, referencia, pendiente y acción de confirmar.
- Contenido: período, datos del trabajador, importes, estados, evidencia y fechas. No introducir datos personales reales para ilustrarlo.
- Procesos: validar período y cálculo → revisar → aprobar → comprobar cuenta y fondos → confirmar abono → actualizar pendiente → conciliar y cerrar cuando corresponda.

### Reglas para mantener coherencia entre diagramas

1. Reutilizar el mismo nombre para el mismo concepto y aclarar equivalencias con nombres de código o SQL.
2. Mostrar en cada módulo solo sus elementos relevantes y referencias a servicios externos.
3. No presentar una relación comercial como automatismo implementado si la pantalla solo guarda un texto de referencia.
4. No copiar el diagrama de clases cambiándole el título a «objetos». Los objetos son instancias con valores.
5. Usar un mismo caso de ejemplo en todos los diagramas relacionados y en la demostración del sistema.
6. Etiquetar «Implementado», «Referencia manual» o «Propuesto» cuando sea necesario distinguir el estado real.
7. Vincular requerimiento → caso de uso → clases/proceso → pantalla → evidencia. Si un requerimiento no tiene evidencia, conservarlo como pendiente.
8. Incluir versiones, título del módulo y una leyenda. Evitar conectores que atraviesen todo el dibujo.

### Organización sugerida de archivos

```text
Entrega/
  Video_1/
    Guion_y_requerimientos/
    Evidencias/
    Video_1_Completo.mp4
    Video_1_Resumen.mp4
  Video_2/
    00_Mapa_general/
    01_Usuarios/
    02_Clientes_y_Ventas/
    03_Proveedores/
    04_Compras/
    05_Inventario/
    06_Produccion/
    07_Proyectos/
    08_Finanzas_Caja_Bancos/
    09_Contabilidad_Costos/
    10_Recursos_Humanos/
    11_Nomina/
    12_Mercadotecnia/
    13_Estadistica_Reportes/
    14_Auditoria_transversal/
    Video_2_Completo.mp4
    Video_2_Resumen.mp4
```

Dentro de cada carpeta modular: casos de uso, clases, objetos y modelos UWE separados por nombre. Esta estructura es una propuesta de organización, no archivos ya elaborados.

## 5. Próxima etapa

Primero confirmar la organización en clase y ajustar el Video 1 a la pauta. Para desarrollar el Video 2 con continuidad se necesitan los diagramas o el documento original del Corte 3, las convenciones UWE utilizadas en clase y el contenido de DGI.ZIP si se exige demostrarlo. Con eso se puede corregir módulo por módulo y conservar el trabajo que ya esté bien, en lugar de inventar un modelo desvinculado del proyecto.
