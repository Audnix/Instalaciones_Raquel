# Guion para leer y grabar — Video 1: Instalaciones Raquel

Preparado a partir de las dos capturas de la pauta y de las guías del repositorio. Este documento cubre el Video 1 y su resumen. No requiere crear diapositivas para empezar: la presentación inicial puede mostrarse en una portada o lámina y luego continuar en la aplicación.

## Cómo usar el guion

Lee solamente los párrafos bajo **LEER**. Las indicaciones bajo **PANTALLA** y **PAUSA** son para quien maneja el sistema y no se leen. Sustituye los campos entre corchetes antes de grabar. La presentación menciona los nombres de los integrantes y omite los carnés, según la indicación del equipo.

Habla despacio, aproximadamente entre 105 y 120 palabras por minuto. Termina una frase, haz la acción y espera a que la pantalla responda. Deja dos segundos entre ideas y de tres a cinco segundos al mostrar un resultado. Puedes grabar la voz por bloques y dejar silencio para colocar las tomas del sistema durante la edición. No fuerces un clic para que coincida con una frase si todavía está cargando.

La distribución propuesta suma 57 minutos, incluyendo manipulación y esperas, y deja tres minutos de margen. Es una distribución para ensayar, no la duración del texto leído por sí solo. El límite de la pauta es una hora. El resumen independiente debe durar como máximo cinco minutos.

Antes de empezar: abre la aplicación, comprueba que cargue y selecciona los registros del recorrido. Para guardar operaciones ficticias, utiliza una copia de práctica identificada. Si vas a mostrar datos operativos, consulta registros existentes y presenta los formularios sin confirmar movimientos ficticios. Este guion no constituye una verificación visual de la sesión actual.

## 1. Portada y presentación — 3 minutos

**PANTALLA:** mostrar la portada con universidad, área de conocimiento, asignatura, grupo, título, integrantes y docente. Mantenerla visible durante toda la presentación.

**LEER**

Buenos días. Somos el grupo de trabajo número [número], de la Universidad Nacional de Ingeniería, del Área de Conocimiento de Tecnología de la Información y Comunicación.

Presentamos nuestro proyecto de la asignatura Ingeniería de Software I, titulado Sistema de Gestión Administrativa para Instalaciones Raquel.

Nuestro equipo está integrado por Jhonny Josue Garcias Blas, Raquel Audry Calero Rayo y Jose Yariel Angulo Gago. Pertenecemos al grupo académico [grupo]. Nuestro docente es el máster Juan Francisco Gómez Flores.

En este video explicaremos el problema que aborda el proyecto, el propósito del prototipo, los tipos de usuarios y los requerimientos del software. Después mostraremos, paso a paso, cómo se organizan las operaciones dentro de la aplicación.

Seguiremos un mismo ejemplo para observar la relación entre proveedores, compras, inventario, ventas, producción y cobros. También presentaremos la gestión del personal, la nómina y las consultas administrativas disponibles.

Durante la demostración dejaremos unos segundos entre cada acción para que se puedan observar los campos, los resultados y los mensajes del sistema.

**PAUSA:** dejar tres segundos antes de cambiar a la lámina del problema.

## 2. Planteamiento del problema — 3 minutos

**PANTALLA:** lámina con cuatro ideas: información dispersa, control de materiales, seguimiento de operaciones y consulta de resultados. Si el diagnóstico del equipo documenta hechos específicos de la empresa, incorporarlos aquí.

**LEER**

El problema que aborda nuestro proyecto es la necesidad de organizar y relacionar la información administrativa de Instalaciones Raquel.

Cuando una empresa maneja por separado sus materiales, compras, ventas, trabajos y pagos, resulta más difícil seguir una operación completa. Por ejemplo, conocer una venta no permite saber, por sí solo, si se entregó el trabajo o si el cliente ya pagó.

Por esa razón, el sistema busca facilitar el registro, la consulta y el seguimiento de las operaciones. La propuesta permite identificar los documentos relacionados, revisar las existencias y distinguir las actividades comerciales de los movimientos de dinero.

El objetivo de esta demostración es explicar cómo el prototipo apoya ese control. Mostraremos las funciones disponibles y señalaremos las verificaciones que necesita cada operación.

**PAUSA:** señalar cada idea de la lámina sin añadir hechos de la empresa que el equipo no haya documentado.

## 3. Presentación del prototipo — 3 minutos

**PANTALLA:** pasar a Inicio o Dashboard con la sesión abierta. Mostrar el menú despacio. No leer cifras que cambien sin comprobarlas.

**LEER**

Ahora nos encontramos en la pantalla principal de Instalaciones Raquel. Desde este punto podemos acceder a las áreas del sistema según los permisos de la cuenta.

El menú organiza las funciones de producción, proveedores, compras, inventario, ventas, finanzas, contabilidad, recursos humanos, mercadotecnia y consultas de resultados. Algunas funciones aparecen agrupadas dentro de un área principal.

La pantalla de inicio ofrece una vista general de los registros disponibles. Para interpretar una cifra debemos considerar su período y su origen. El total de ventas, por ejemplo, no representa automáticamente el efectivo disponible ni la utilidad de la empresa.

A continuación explicaremos quién puede utilizar estas funciones y qué condiciones debe cumplir el sistema.

**PAUSA:** recorrer el menú durante diez segundos y volver al inicio.

## 4. Jerarquía y permisos de usuarios — 4 minutos

**PANTALLA:** abrir Usuarios y roles. Mostrar perfiles y permisos sin modificarlos. Los cuatro niveles siguientes corresponden a la pauta: contrastarlos con los nombres y permisos que muestre la aplicación.

**LEER**

La pauta organiza los usuarios en cuatro niveles: superadministrador, administrador, usuario estándar y usuario restringido o invitado.

El superadministrador corresponde al nivel de control general del sistema. El administrador gestiona las funciones y los accesos que se le asignan dentro de su ámbito. El usuario estándar realiza las tareas permitidas de su trabajo diario. El usuario restringido dispone de acceso limitado, principalmente de consulta, según su configuración.

En la aplicación revisamos los permisos concretos de cada cuenta. No basta con el nombre del perfil: también debemos verificar el área autorizada y las acciones permitidas.

Consultar información, registrar una operación y aprobar un pago son acciones diferentes. Esta separación permite asignar responsabilidades y limitar el acceso a información que no corresponde a cada usuario.

**PAUSA:** mostrar una cuenta y sus permisos. Dejar cinco segundos para observarlos.

## 5. Requerimientos del software — 7 minutos

**PANTALLA:** mostrar una lámina con los siete grupos indicados en la pauta. Puede abrirse también ERS · Requerimientos. La guía existente identifica cinco filtros en esa pantalla; no buscar siete pestañas para explicar los siete grupos.

**LEER**

Los requerimientos describen lo que necesita el software y las condiciones bajo las cuales debe funcionar. Presentaremos los siete grupos solicitados en la pauta.

Primero, los requerimientos funcionales. Describen las acciones del sistema. Un ejemplo es registrar una recepción de compra y reflejar la entrada de materiales en inventario. Otro ejemplo es consultar una factura y preparar su cobro.

Segundo, los requerimientos no funcionales. Describen condiciones de calidad, como el control de acceso, la conservación de los datos y la presentación de mensajes ante un error. Para afirmar un tiempo de respuesta concreto sería necesario medirlo.

Tercero, los requerimientos del dominio. Expresan reglas propias del negocio. En este recorrido distinguimos una factura de su cobro y una recepción de compra del pago al proveedor. También revisamos la salida de materiales mediante el método de primeras entradas, primeras salidas, conocido como PEPS.

Cuarto, los requerimientos del usuario. Explican lo que cada persona necesita hacer. El responsable de inventario necesita consultar existencias y movimientos. El responsable financiero necesita revisar cobros, pagos y saldos. El área de recursos humanos necesita consultar expedientes y preparar información laboral.

Quinto, los requerimientos del sistema. Describen los componentes y servicios necesarios. El proyecto utiliza una aplicación web, un servidor de servicios y una base de datos SQL Server. Las operaciones deben validar sus datos y confirmar el resultado del guardado.

Sexto, las especificaciones en lenguaje estructurado. Permiten expresar una regla mediante condiciones y pasos claros. Por ejemplo: si la sesión de caja corresponde al día y el importe del cobro es válido para la factura, entonces se permite continuar con la confirmación. En caso contrario, se informa qué condición debe revisarse. Para una salida también se comprueban los fondos disponibles.

Séptimo, las especificaciones de la interfaz. Describen cómo interactúa la persona con la aplicación: campos, listas, botones, mensajes y resultados. En un pago individual, por ejemplo, debemos identificar al trabajador, revisar su pendiente, introducir el importe y observar la confirmación de la operación.

Estos requerimientos se relacionan con las pantallas que veremos a continuación. Mostrar una pantalla ayuda a explicar una función, pero su comprobación también requiere revisar el resultado que deja la operación.

**PAUSA:** detenerse entre los siete grupos. Si hay un requisito documentado seleccionado, mostrar su descripción y luego la pantalla que lo ejemplifica. No inventar identificadores de requisitos.

## 6. Datos iniciales: proveedor, producto y cliente — 4 minutos

**PANTALLA — PASO A PASO**

1. Abrir Proveedores. Buscar un proveedor del ejercicio y mostrar su ficha.
2. Abrir Productos desde el menú disponible. Buscar el producto del ejercicio.
3. Mostrar código, nombre, unidad y precio.
4. Abrir Clientes y mostrar el cliente del caso.
5. Si se necesita demostrar un alta, completar un registro claramente identificado en la copia de práctica, guardar una sola vez y buscarlo después de la confirmación.

**LEER**

Comenzamos por los datos que se utilizarán durante el recorrido. Primero identificamos al proveedor que suministra los materiales.

Ahora mostramos el producto. Su ficha permite reconocer el código, la descripción, la unidad y el precio. Crear el producto no significa que ya existan unidades disponibles; las existencias se justifican mediante movimientos de inventario.

Después identificamos al cliente de la operación. Utilizaremos los mismos registros durante la demostración para conservar una referencia común y evitar duplicaciones.

En cada registro revisamos los campos obligatorios antes de guardar. Después esperamos la respuesta y buscamos nuevamente el registro para comprobar que se conserva.

**PAUSA:** cinco segundos en cada ficha.

## 7. Compras e inventario — 5 minutos

**PANTALLA — PASO A PASO**

1. En la copia de práctica, preparar una recepción del producto: 10 unidades a C$400, total C$4,000. Usar un producto exclusivo del ejercicio sin movimientos previos si se van a narrar los saldos del ejemplo.
2. Revisar proveedor, producto, cantidad y costo antes de Recibir compra.
3. Confirmar una sola vez y esperar el resultado.
4. Anotar la referencia generada y abrir Inventario.
5. Buscar el producto y mostrar existencias, lote y kardex. No registrar otra entrada por las mismas unidades.
6. Si se usan documentos existentes, sustituir los importes del ejemplo por los que muestre la pantalla.

**LEER**

En Compras revisamos la recepción de materiales. Para este ejemplo utilizamos diez unidades con un costo de cuatrocientos córdobas cada una. El importe de la compra es de cuatro mil córdobas.

Antes de confirmar comprobamos el proveedor, el producto, la cantidad y el costo. Ahora esperamos la respuesta del sistema.

Pasamos a Inventario para buscar el mismo producto. Aquí revisamos la entrada, el lote y su referencia. El kardex permite seguir los movimientos que explican las existencias.

El método PEPS significa que las salidas utilizan primero los lotes más antiguos. Esto permite dar seguimiento al costo de los materiales utilizados o vendidos.

Esta recepción representa una entrada de materiales y una obligación con el proveedor. El pago de esa obligación corresponde a otra operación.

**PAUSA:** dejar de tres a cinco segundos después de cada cambio de pantalla. Si las existencias no coinciden con el ejemplo, revisar los movimientos antes de narrar un saldo.

## 8. Proforma y factura — 5 minutos

**PANTALLA — PASO A PASO**

1. Abrir Ventas y preparar una proforma del cliente con dos unidades del producto.
2. Mostrar cantidad, precio, descuento, impuesto y total.
3. Guardar y mostrar su referencia.
4. Revisar que la proforma no haya generado una salida de inventario.
5. Convertirla una sola vez a factura con la acción disponible. No emitir además otra factura para la misma venta.
6. Anotar número y total exactos de la factura.
7. Consultar Inventario y mostrar la salida. En el ejemplo aislado de diez unidades, deben quedar ocho.

**LEER**

En Ventas comenzamos con una proforma. Este documento presenta al cliente una propuesta con productos, cantidades y precios.

Revisamos los importes y el total calculado por la aplicación. La proforma no representa todavía una salida de materiales.

Cuando se confirma la operación comercial, utilizamos la opción de conversión a factura. Esperamos la confirmación y revisamos el número del documento.

Ahora volvemos a Inventario para comprobar la salida correspondiente. En nuestro ejemplo, la venta de dos unidades deja ocho disponibles, siempre que no existan otros movimientos del mismo producto.

La factura documenta la venta y permite consultar su saldo pendiente. Para registrar el ingreso del dinero debemos confirmar el cobro por separado.

**PAUSA:** señalar el total real sin anticipar un IVA o descuento distinto del que muestre la aplicación.

## 9. Proyectos y producción — 4 minutos

**PANTALLA — PASO A PASO**

1. Abrir Proyectos y mostrar la obra del ejemplo con su avance.
2. Regresar a la factura. Si está disponible, abrir Preparar orden de taller y seleccionar una línea.
3. Revisar datos propuestos, código, unidad y medidas antes de crear una orden. Si ya existe, abrirla.
4. Mostrar el tablero de Producción y sus etapas: pendiente o backlog, corte, ensamble, instalación y entregado.
5. Avanzar estados únicamente en el ejercicio de práctica. En registros operativos, mostrar su estado real.

**LEER**

En Proyectos podemos identificar la obra y consultar su avance. En Producción observamos el seguimiento del trabajo del taller.

Cuando está disponible, la preparación desde la factura ayuda a trasladar información del cliente y de la línea seleccionada. El responsable debe revisar los datos antes de crear la orden.

El tablero organiza el trabajo en etapas: pendiente, corte, ensamble, instalación y entrega. Cada cambio de estado debe corresponder al trabajo realizado.

La referencia del proyecto y los documentos comerciales facilitan el seguimiento. Para explicar una conexión automática debemos comprobar el vínculo que conserva el sistema; que dos registros compartan un nombre no demuestra por sí solo esa relación.

**PAUSA:** cinco segundos por etapa. Si se simula el avance completo, identificarlo como ejercicio.

## 10. Finanzas: cobro, Caja y Bancos — 5 minutos

**PANTALLA — PASO A PASO**

1. Abrir la factura confirmada y consultar su saldo pendiente.
2. Seleccionar Cobrar en efectivo o banco, según la ruta disponible.
3. Verificar sesión del día, cuenta, importe y referencia de factura.
4. Confirmar una sola vez en la copia de práctica y esperar el resultado.
5. Consultar movimiento, saldo de cuenta y pendiente de la factura.
6. Abrir Bancos para explicar la otra cuenta sin volver a cobrar la misma operación.

**LEER**

Ahora vamos a revisar el cobro de la factura. Primero comprobamos que el documento esté confirmado y que tenga saldo pendiente.

Elegimos el medio de pago y revisamos la cuenta correspondiente. El efectivo se registra en Caja. Los medios bancarios se revisan en Bancos.

Antes de confirmar observamos el importe, la referencia de factura y la sesión del día. Después de guardar verificamos el movimiento y volvemos a consultar el saldo pendiente del documento.

De esta manera podemos distinguir la venta del cobro. También distinguimos el saldo inicial de una sesión de las entradas recibidas durante el día.

El arqueo de caja permite comparar el efectivo contado con el registro. La revisión bancaria necesita el respaldo correspondiente. Registrar un movimiento bancario en esta aplicación no ejecuta por sí mismo una transferencia en un banco.

**PAUSA:** si aparece un bloqueo por fecha, fondos, referencia o permisos, leer el mensaje y revisar la condición. No repetir el cobro para demostrar que se guardó: actualizar la consulta.

## 11. Contabilidad y estados financieros — 3 minutos

**PANTALLA:** abrir Contabilidad. Mostrar los asientos o libros disponibles y su origen. Si existen pantallas de Balance General, Estado de Resultados y Flujo de Efectivo, abrirlas y revisar período y contenido antes de leer la variante correspondiente.

**LEER**

En Contabilidad revisamos la información que permite seguir el efecto económico de las operaciones. Observamos la fecha, el concepto y la referencia del documento de origen.

La pauta solicita estados financieros básicos: Balance General, Estado de Resultados y Flujo de Efectivo. El Balance General presenta activos, pasivos y patrimonio. El Estado de Resultados reúne ingresos, costos y gastos del período. El Flujo de Efectivo explica las entradas y salidas de efectivo.

Para interpretar cada resultado debemos revisar el período y las operaciones que incluye. Una tarjeta del inicio o una diferencia entre ventas y compras no sustituye un estado financiero completo.

**VARIANTE A — LEER solamente si se muestran los estados completos:**

En estas vistas mostramos los estados disponibles y el período consultado. Revisamos sus cuentas e importes junto con los registros que los respaldan.

**VARIANTE B — LEER si alguno falta o no se ha comprobado:**

En esta demostración mostramos los registros y consultas disponibles. La cobertura de los estados financieros que no podemos presentar completos queda pendiente de verificación y no la consideramos demostrada.

**NOTA PARA EL EQUIPO:** las capturas mencionan DGI.ZIP, pero su contenido no está incluido en los materiales revisados para este guion. No afirmar cumplimiento integral de ese archivo sin contrastarlo.

## 12. Recursos Humanos y Nómina — 6 minutos

**PANTALLA — PASO A PASO**

1. Abrir Talento humano → Personal y el expediente de un trabajador de práctica.
2. Mostrar Contratos, Vacaciones y permisos, Asistencia, Seguridad y bienestar, y Marco legal y cumplimiento según los accesos visibles.
3. Abrir Nómina y una planilla de práctica. Para crearla, seleccionar período, frecuencia, fechas y trabajadores sin duplicar una existente.
4. Revisar datos individuales y novedades justificadas; calcular y mostrar el resumen.
5. Revisar Validaciones, Marcar como Revisada y Aprobar Nómina (Gerencia), cuando corresponda al estado y los permisos.
6. Mostrar Pagos por trabajador, seleccionar una persona y revisar neto, pagos previos y pendiente.
7. En práctica, registrar un abono permitido, esperar la confirmación y consultar comprobante y pendiente actualizado. No copiar a todos el importe de una sola persona.

**LEER**

En Recursos Humanos comenzamos con el expediente del trabajador. Aquí se organiza la información laboral necesaria para el seguimiento del personal.

También encontramos funciones relacionadas con contratos, vacaciones, permisos, asistencia y seguridad. Las secciones de marco legal y cumplimiento sirven para consultar la información incorporada al proyecto; su existencia no sustituye una revisión de cumplimiento.

Ahora pasamos a Nómina. Primero identificamos el período y los trabajadores incluidos. Después revisamos salarios, días, horas y novedades que correspondan al ejercicio.

Una vez realizado el cálculo, revisamos el resumen y las validaciones. La revisión y la aprobación son etapas previas al pago y dependen de los permisos de la cuenta.

En el pago individual seleccionamos al trabajador y comprobamos su pendiente. Un abono debe aplicarse a la persona correcta, por un importe permitido y con su medio y referencia.

Después de confirmar revisamos el comprobante y el saldo actualizado. Calcular o aprobar una nómina no significa que todos sus trabajadores ya hayan recibido el dinero.

**PAUSA:** dejar cinco segundos en el desglose individual y en el comprobante. Si hay diferencias históricas, mostrarlas como pendientes de revisión; no afirmar que quedaron resueltas por seguir este guion.

## 13. Estadística, reportes y mercadotecnia — 3 minutos

**PANTALLA:** abrir un reporte o indicador, mostrar período y fuente; después mostrar Catálogo o Promociones en Mercadotecnia. Usar el nombre real de cada opción visible.

**LEER**

Las consultas e indicadores permiten resumir información para apoyar la revisión administrativa. Antes de interpretar un gráfico identificamos el período y los documentos que utiliza.

Por ejemplo, una gráfica de unidades vendidas permite comparar productos según las ventas registradas. Una proyección representa una estimación y debe distinguirse de un resultado ya ocurrido.

En Mercadotecnia mostramos las herramientas disponibles para organizar el catálogo y la presentación comercial. Si se utiliza una promoción, también debemos comprobar cómo afecta el precio y el total de la venta.

Estas consultas permiten revisar información desde distintas áreas sin perder de vista los documentos que la originan.

**PAUSA:** escoger un único indicador y explicar lo que realmente muestra. No intentar leer todas las cifras.

## 14. Revisión y conclusión — 2 minutos

**PANTALLA:** abrir el control de operaciones o historial y luego regresar al inicio.

**LEER**

Para finalizar revisamos el seguimiento de las operaciones. Las referencias y los historiales permiten localizar documentos, identificar acciones y consultar pendientes.

Durante el recorrido presentamos el problema del proyecto, los perfiles de usuario, los siete grupos de requerimientos y los principales módulos del prototipo.

Seguimos la recepción de materiales, su consulta en inventario, la venta, el trabajo de producción y el cobro. También mostramos el expediente del personal, el cálculo de nómina y la revisión de un pago individual.

El propósito del sistema es apoyar una gestión organizada y trazable. Su uso requiere datos correctos, permisos adecuados y la comprobación del resultado de cada operación.

Con esto concluimos la presentación del Video 1 del Sistema de Gestión Administrativa para Instalaciones Raquel. Muchas gracias por su atención.

**PAUSA:** mantener la pantalla final cinco segundos y detener la grabación.

---

## Resumen independiente — objetivo: 4 minutos y 40 segundos

Grabar aparte o editar fragmentos del video completo. Los espacios entre bloques se destinan a mostrar las acciones y resultados. Comprobar la duración después de grabar para no superar los cinco minutos solicitados.

### 00:00–00:35 — Portada

**LEER**

Somos el grupo [número], de la asignatura Ingeniería de Software I de la Universidad Nacional de Ingeniería. Presentamos el Sistema de Gestión Administrativa para Instalaciones Raquel. El proyecto busca organizar la información de materiales, compras, ventas, trabajos y pagos para facilitar su consulta y seguimiento.

### 00:35–01:10 — Inicio, usuarios y requerimientos

**LEER**

El sistema organiza el acceso mediante perfiles y permisos por área. Diferencia las acciones de consulta, registro y aprobación. Su documentación contempla requerimientos funcionales, no funcionales, del dominio, del usuario y del sistema, además de especificaciones en lenguaje estructurado y de interfaz.

### 01:10–02:10 — Compra, inventario y venta

**LEER**

En el recorrido comenzamos con los datos del proveedor, el producto y el cliente. La recepción de compra genera una entrada de materiales que se consulta en Inventario mediante sus lotes y movimientos. Después elaboramos una proforma y la convertimos en factura. La proforma es una propuesta; la factura confirmada registra la venta y su salida de existencias.

### 02:10–02:50 — Producción y cobro

**LEER**

Producción permite seguir el trabajo por etapas, desde la preparación hasta la entrega. En Finanzas revisamos el cobro de la factura, su referencia y el medio de pago. El efectivo corresponde a Caja y los medios bancarios a Bancos. Emitir la factura y recibir el dinero son operaciones diferentes.

### 02:50–03:40 — Recursos Humanos y Nómina

**LEER**

En Recursos Humanos consultamos el expediente y la información laboral. Nómina utiliza los datos del período para calcular los importes individuales. Después de revisar y aprobar, el pago se registra por trabajador. Cada abono requiere comprobar el pendiente, la cuenta y su confirmación. Calcular la planilla no equivale a pagarla.

### 03:40–04:15 — Contabilidad, indicadores y mercadotecnia

**LEER**

Las consultas contables permiten revisar las operaciones y sus referencias. Los indicadores deben interpretarse según su período y sus fuentes. Mercadotecnia reúne las herramientas comerciales disponibles. La cobertura demostrada corresponde a las pantallas y documentos que se muestran en el video completo.

### 04:15–04:40 — Cierre

**LEER**

El proyecto relaciona las áreas administrativas y facilita el seguimiento de las operaciones. Para utilizarlo correctamente debemos registrar datos consistentes, respetar los permisos y comprobar los resultados. Con esto concluimos el resumen del Video 1 de Instalaciones Raquel. Muchas gracias.

---

## Primera toma: por dónde comenzar

1. Completar grupo académico y grupo de trabajo. Los nombres ya están incorporados y no se mencionan carnés.
2. Mostrar la portada y hacer una prueba de voz de diez segundos.
3. Grabar únicamente el bloque 1. Mantener las pausas sin apresurarse.
4. Escucharlo y verificar que nombres y título se entiendan.
5. Grabar el bloque 2; después continuar con el bloque 3 en la aplicación.
6. Grabar cada sección restante por separado. Al unirlas, conservar las esperas necesarias para ver los resultados y comprobar el tiempo total.

Documentos de apoyo del repositorio: GUIA_GRABACION_COMPLETA_INSTALACIONES_RAQUEL.md, PLAN_ENTREGA_SEGUN_PAUTA_DOCENTE.md y guion_video_demo.md. Ante diferencias de nombres de botones, utilizar la interfaz de la versión que se está grabando.
