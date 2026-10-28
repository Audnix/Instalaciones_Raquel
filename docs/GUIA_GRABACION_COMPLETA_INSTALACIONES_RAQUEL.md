# Guía de grabación y narración — Instalaciones Raquel

> Actualización según la pauta docente: los doce videos de esta guía se usan como capítulos o tomas de trabajo, no como doce entregas obligatorias. La pauta compartida pide dos videos principales de hasta una hora y un resumen de hasta cinco minutos por cada uno. Consulta PLAN_ENTREGA_SEGUN_PAUTA_DOCENTE.md para organizar el Video 1 y preparar la división modular del Video 2.

Recorrido del sistema, desde el acceso hasta el cierre. Preparado con los nombres y controles de la versión revisada del proyecto. Esta guía organiza una demostración; no certifica que cada recorrido visual haya sido ejecutado con tu sesión.

## 1. Antes de grabar

1. Abre la aplicación con el procedimiento habitual y entra en http://localhost:5173. El servidor y SQL Server deben estar activos.
2. Inicia sesión fuera de la grabación. No grabes contraseñas, códigos de recuperación ni información privada de trabajadores o clientes.
3. Recarga con Ctrl + F5. Espera a que termine la consulta de SQL; no empieces con avisos de desconexión.
4. Usa una cuenta autorizada. Los módulos del guardado global requieren superadministración; revisar o aprobar operaciones exige los permisos correspondientes.
5. Entra en Base de datos → SQL y migraciones. Ejecuta Verificar SQL y Revisar operaciones. Conserva la evidencia de la consulta.
6. En la revisión anterior se encontraron una sesión de Caja del 21/10 abierta y tres planillas con diferencias históricas de pagos. Comprueba si siguen pendientes. No los cierres ni ajustes solo para que desaparezca el aviso.
7. Para grabar altas, compras, ventas y pagos simulados, utiliza una copia de práctica autorizada, separada de los datos operativos. No habilites scripts de demostración ni reconstruyas la base real para preparar el video.
8. Si únicamente tienes la base real, graba consultas y formularios sin confirmar operaciones ficticias. Explica que el registro final requiere un hecho real y su respaldo. No necesitas inventar movimientos para mostrar el sistema.
9. Prepara una carpeta para videos y comprobantes. Graba en horizontal, preferiblemente 1920 × 1080, con zoom de navegador de 100 % o el que mantenga legibles las tablas.
10. Haz una prueba de voz de diez segundos. Desactiva notificaciones ajenas al sistema y deja el cursor visible.

**Regla durante toda la grabación:** ejecutar una acción, esperar a que termine «Guardando cambios…», comprobar el resultado y después cambiar de pantalla. Una tabla visible o un formulario cerrado no sustituyen la confirmación del servidor.

## 2. Caso conductor para la copia de práctica

Usa el prefijo DEMO-REC-01 para reconocer los registros de esta grabación. No vuelvas a crear esos registros si repites una toma: busca el registro ya guardado.

| Dato | Ejemplo de práctica |
|---|---|
| Cliente | DEMO Cliente Grabación |
| Proveedor | DEMO Proveedor Grabación |
| Producto | Código DEMO-MARCO; nombre Marco de práctica |
| Unidad | Pieza |
| Precio de venta | C$700 por unidad |
| Cantidad recibida | 10 unidades |
| Costo de compra | C$400 por unidad |
| Total de compra | C$4,000 |
| Cantidad vendida | 2 unidades |
| Stock después de facturar | 8 unidades, si no existen otros movimientos de ese producto |
| Total de factura | T: copia exactamente el importe que calcule la pantalla |
| Proyecto / orden | DEMO-REC-01 |
| Saldo inicial contado de práctica | C$1,000, solo en la copia de práctica |
| Trabajadores | Dos personas de práctica con salarios distintos, identificadas claramente como DEMO |
| Primer abono | P1: un importe positivo menor que el pendiente aprobado del trabajador seleccionado |
| Segundo abono | P2: el importe elegido para la siguiente entrega, sin superar el pendiente actualizado |

El subtotal de la venta de ejemplo es C$1,400. Si no hay descuento y la pantalla aplica 15 % de IVA, el total será C$1,610. Si hay una promoción activa, utiliza el total calculado por el sistema: no narres C$1,610 si la pantalla muestra otra cifra.

**Comprobaciones del caso:** la proforma no consume stock; la factura descuenta dos unidades; recibir una compra no equivale a pagar al proveedor; emitir una factura no equivale a cobrarla. La cuenta de efectivo, después del cobro y antes de otras operaciones, debe mostrar C$1,000 + T. Si luego registras abonos de nómina en efectivo, debe disminuir por los importes efectivamente confirmados.

## 3. Orden de los videos

| Video | Contenido | Duración orientativa |
|---|---|---|
| 01 | Presentación, acceso y Dashboard | 2–3 min |
| 02 | Usuarios, roles y preparación técnica | 3–4 min |
| 03 | Productos, proveedores y clientes | 4–5 min |
| 04 | Compras, recepción e inventario PEPS | 4–5 min |
| 05 | Proforma, factura y costos | 4–5 min |
| 06 | Proyectos y producción | 3–4 min |
| 07 | Caja, cobros y Bancos | 5–6 min |
| 08 | Talento humano y expedientes | 4–5 min |
| 09 | Preparación, cálculo y aprobación de nómina | 4–5 min |
| 10 | Pagos individuales, abonos y comprobantes | 5–6 min |
| 11 | Finanzas, Contabilidad, Mercadotecnia y Reportes | 4–5 min |
| 12 | Arqueo final, auditoría y conclusión | 4–5 min |

Puedes grabar cada archivo por separado y unirlos después. Los tiempos incluyen desplazamientos y esperas; la narración es deliberadamente más corta que la manipulación.

## Video 01 — Presentación y acceso

**Objetivo:** explicar qué se demostrará y mostrar que la consulta está conectada.

**Acciones en pantalla**

1. Empieza en el Dashboard, con la sesión ya iniciada.
2. Muestra el nombre del sistema y el menú lateral.
3. Señala las áreas de Producción, Finanzas, Contabilidad, Mercadotecnia, Compras, Talento Humano y Gobierno.
4. Muestra el indicador de sincronización. Espera si está cargando.
5. Explica que seguirás una operación desde los datos iniciales hasta la revisión final.

**Voz sugerida**

> En este recorrido presentaré el sistema Instalaciones Raquel. Mostraré cómo se organizan sus módulos y cómo se realiza una operación en orden: preparación de datos, compra y recepción de materiales, venta, cobro, gestión de personal y pago de nómina. Al final revisaré los resultados, la auditoría y el cierre de caja. Antes de comenzar compruebo que la sesión esté activa y que los datos se consulten desde SQL Server.

**Evidencia:** toma de cinco segundos del Dashboard y su indicador de conexión. No describas todas las cifras del tablero si no las has contrastado.

## Video 02 — Usuarios, roles y preparación técnica

**Objetivo:** mostrar quién puede consultar, registrar y aprobar.

**Acciones en pantalla**

1. Entra en Usuarios y roles. Muestra una cuenta y sus áreas autorizadas, sin revelar contraseñas.
2. Explica la diferencia entre permisos de consulta, escritura y aprobación. No cambies los permisos reales para la grabación.
3. Abre Base de datos → SQL y migraciones.
4. Pulsa Verificar SQL. Espera el resultado y muestra la cobertura que realmente devuelva.
5. En Control general de operaciones, pulsa Revisar operaciones. Muestra los pendientes encontrados, si existen.
6. Aclara que Descargar estructura SQL descarga un archivo; no actualiza la base ni debe ejecutarse sobre una base existente.
7. Abre brevemente Metodología y modelos y ERS · Requerimientos. Preséntalos como documentación del sistema.

**Voz sugerida**

> El acceso se organiza por jerarquía y área de trabajo. Tener acceso a una pantalla no significa tener autorización para aprobar un pago. En Base de datos verifico la cobertura de la estructura y reviso el control general de operaciones. Esta consulta permite identificar sesiones anteriores y diferencias que requieren respaldo documental. El archivo de estructura corresponde a instalaciones nuevas; no es necesario ejecutarlo para utilizar la base actual. También están disponibles los modelos y los requerimientos que documentan el sistema.

**Evidencia:** resultado de la revisión SQL, lista de pendientes y una vista de permisos. Si hay un aviso, explícalo; no lo ocultes como si fuera un resultado correcto.

## Video 03 — Datos iniciales: producto, proveedor y cliente

**Objetivo:** preparar los registros que se reutilizarán durante todo el recorrido.

**Acciones en pantalla**

1. En la copia de práctica, abre Base de datos → Productos y registra el código y nombre del producto de ejemplo, precio C$700 y un mínimo no negativo. Completa los campos obligatorios que muestre el formulario.
2. Espera la confirmación SQL y busca el código DEMO-MARCO. Registrar el producto no añade diez unidades al inventario.
3. En Proveedores pulsa Nuevo proveedor. Completa nombre comercial, categoría, especialidad y los demás campos obligatorios visibles. Usa información ficticia identificada como práctica.
4. Guarda y vuelve a buscarlo. Abre su expediente y muestra las secciones disponibles sin adjuntar documentos reales a un proveedor ficticio.
5. En Clientes registra DEMO Cliente Grabación con los datos de contacto de práctica necesarios.
6. Busca al cliente y comprueba que no se haya creado dos veces.

**Voz sugerida**

> Primero preparo los datos maestros. El producto define el código, su descripción y el precio de venta, pero sus existencias se registran mediante movimientos de inventario. Después identifico al proveedor de los materiales y al cliente de la operación. Utilizar los mismos registros durante el recorrido mantiene la información consistente y evita duplicar nombres o expedientes.

**Evidencia:** producto, proveedor y cliente localizados después de guardar.

## Video 04 — Compra, recepción e inventario

**Objetivo:** demostrar la entrada de materiales y su trazabilidad.

**Acciones en pantalla**

1. En Compras selecciona el producto de práctica e identifica al proveedor. Si el formulario solicita el nombre, utiliza el mismo nombre registrado; no afirmes una vinculación automática por identificador si no se muestra.
2. Introduce cantidad 10 y costo unitario C$400. Comprueba el total C$4,000.
3. Pulsa Recibir compra. Este botón registra una recepción; úsalo únicamente cuando corresponda recibir el material en el escenario de práctica.
4. Espera la confirmación y anota el número de compra generado.
5. Abre Inventario y busca DEMO-MARCO. Comprueba las diez unidades y el costo del lote.
6. Muestra el kardex de entrada y su referencia de recepción.
7. Explica PEPS: las salidas utilizan primero los lotes más antiguos.
8. No registres otra entrada manual por estas mismas diez unidades: duplicaría la recepción.

**Voz sugerida**

> Registro la recepción de diez unidades a un costo de cuatrocientos córdobas cada una. El sistema incorpora las existencias y su movimiento de entrada. En Inventario compruebo el lote y la referencia de la compra. El método PEPS permite seguir el costo de los materiales por antigüedad. Esta recepción genera inventario y una obligación con el proveedor; todavía no representa una salida de dinero.

**Evidencia:** misma compra en el listado y su entrada en inventario. Si solo consultas datos reales, abre una recepción existente en vez de crear una ficticia.

## Video 05 — Proforma, factura y costo de salida

**Objetivo:** distinguir una cotización de una venta y una venta de su cobro.

**Acciones en pantalla**

1. Abre Ventas y selecciona Proforma.
2. Identifica al cliente, el producto y cantidad 2. Revisa precio, descuento, impuesto, total y vigencia.
3. Guarda la proforma y anota su número. Comprueba que el inventario sigue en diez unidades.
4. Vuelve a la proforma y utiliza su acción de conversión a factura, si está habilitada y existe stock.
5. **Elige una sola ruta:** convertir esta proforma o emitir una factura nueva. No hagas ambas para la misma venta.
6. Muestra el número de factura y copia el total exacto como T en tu hoja de grabación.
7. Abre Inventario y verifica ocho unidades. Muestra la salida de dos unidades en kardex y la previsualización PEPS disponible.
8. Abre Costos y explica las cifras que efectivamente presente. El costo del lote y el precio de venta son conceptos distintos.
9. Muestra el documento o QR generado. No lo presentes como certificación fiscal externa.

**Voz sugerida**

> La proforma presenta una propuesta comercial y no descuenta existencias. Cuando se confirma la venta, convierto la proforma en una factura. Reviso el descuento, el impuesto y el total calculado por la pantalla. Ahora el inventario refleja la salida de dos unidades y conserva ocho. La factura deja una cuenta por cobrar; el ingreso de efectivo se confirma en Caja o Bancos cuando realmente se recibe. No registro dos veces la misma venta.

**Evidencia:** números de proforma y factura, total T, stock anterior y posterior. Comprueba que el documento siga visible después de volver a consultar.

## Video 06 — Proyecto y producción

**Objetivo:** mostrar el seguimiento de una obra y del trabajo en taller.

**Acciones en pantalla**

1. Abre Proyectos. En práctica, registra DEMO-REC-01 con cliente, monto, avance inicial y estado coherentes.
2. Comprueba que el avance esté entre 0 y 100 %.
3. En Producción crea una orden con código DEMO-REC-01, descripción del trabajo, cliente/proyecto, cantidad y unidad.
4. Ubica la orden en backlog.
5. Avanza por corte → ensamble → instalación → entregado. Haz una pausa en cada estado y explica qué representa.
6. En una grabación con datos reales, muestra solo el avance efectivamente realizado. No marques una orden como entregada para completar el video.
7. Explica que la coincidencia del código ayuda al seguimiento; no demuestra por sí sola que exista un enlace automático entre todos los documentos.

**Voz sugerida**

> El módulo de Proyectos permite identificar la obra y su avance. En Producción registro la orden de taller y sigo sus etapas: pendiente, corte, ensamble, instalación y entrega. Cada cambio debe representar trabajo realmente realizado. El tablero permite visualizar las órdenes activas y sus responsables, mientras el código de referencia facilita buscar la operación durante la revisión.

**Evidencia:** proyecto y orden identificados con el mismo caso, y estados mostrados de forma legible.

## Video 07 — Caja, cobro de la factura y Bancos

**Objetivo:** registrar una entrada en la cuenta correcta y explicar su efecto.

**Acciones en pantalla**

1. Abre Caja. Revisa fecha de sesión, responsable y estado.
2. Si existe una sesión anterior, entra al arqueo. El responsable debe introducir el efectivo contado, explicar diferencias y cerrar la sesión antes de abrir la del día. No aceptes un saldo sugerido como prueba del conteo físico.
3. En la copia de práctica abre una sesión del día con C$1,000 de saldo inicial. El saldo inicial es la base, no una venta del día.
4. Pulsa Registrar entrada. Selecciona efectivo, introduce el importe T y un concepto que identifique el cobro de la factura.
5. Selecciona el tipo documental correspondiente y escribe el número de factura como referencia. Revisa antes de pulsar Confirmar movimiento.
6. Espera la confirmación y revisa el movimiento, las entradas y el saldo final. Sin otras operaciones, el saldo será C$1,000 + T.
7. Pulsa Actualizar para demostrar que el movimiento sigue guardado. No vuelvas a enviarlo como una operación nueva para demostrar persistencia.
8. Abre Bancos y muestra sus movimientos y sesiones. Explica que transferencia, cheque y tarjeta afectan Banco; efectivo afecta Caja.
9. No cobres nuevamente en Bancos la factura que ya cobraste en efectivo. Si deseas demostrar la confirmación bancaria, utiliza otra operación de práctica claramente distinta.
10. No registres un pago al proveedor si todavía no se ha efectuado. Una compra y su pago son hechos diferentes.

**Voz sugerida**

> Antes de operar verifico que la sesión corresponda al día. La base del período representa el saldo inicial y se mantiene separada de las entradas por cobros. Ahora registro el cobro de la factura por el importe mostrado en el documento. Después de confirmar, compruebo el movimiento y el nuevo saldo. El medio determina la cuenta: el efectivo corresponde a Caja y los medios bancarios corresponden a Bancos. La misma entrega de dinero no debe registrarse en ambas cuentas.

**Evidencia:** apertura, entrada confirmada y saldo. Registrar una transferencia dentro del sistema no ejecuta un envío de fondos en una entidad bancaria.

## Video 08 — Talento humano y expedientes

**Objetivo:** preparar al personal antes de elaborar una nómina.

**Acciones en pantalla**

1. Entra en Talento humano → Personal.
2. En práctica, registra dos trabajadores identificados como DEMO, con cargos, áreas, fechas de ingreso y salarios distintos y coherentes con el ejercicio. En datos reales utiliza únicamente información validada.
3. Abre Ver expediente y muestra los datos laborales disponibles.
4. Recorre Contratos, Vacaciones y permisos, Asistencia y Seguridad y bienestar.
5. En la copia de práctica puedes mostrar un formulario o un registro del ejercicio. Explica los estados y responsables, sin aprobar solicitudes reales por la grabación.
6. Muestra Mi espacio, Derechos y orientación y Marco legal y cumplimiento como secciones de consulta.
7. Regresa a Personal y comprueba que las dos personas se encuentran activas y disponibles para el período de nómina previsto.

**Voz sugerida**

> La nómina parte de información laboral consistente. En Talento humano reviso el cargo, el área, el salario y la fecha de ingreso de cada persona. El expediente reúne el seguimiento del trabajador. Las secciones de contratos, asistencia, permisos y seguridad aportan contexto a la gestión del personal. Para este ejercicio utilizaré dos trabajadores con remuneraciones distintas, de modo que cada pago conserve su propio cálculo y su saldo pendiente.

**Evidencia:** expedientes de práctica y sus datos, sin mostrar información privada del personal real.

## Video 09 — Crear, calcular, revisar y aprobar la nómina

**Objetivo:** mostrar el flujo previo al pago, sin saltar controles.

**Acciones en pantalla**

1. Abre Nómina → Nueva Planilla.
2. Define nombre del período, frecuencia, fecha inicial, fecha final y fecha prevista de pago. Usa fechas compatibles con la contratación y evita duplicar un período ya registrado.
3. En Trabajadores incluye únicamente a las personas del ejercicio.
4. Revisa salario, días y horas del período. No copies el neto de una persona a otra.
5. En Novedades registra solo los bonos, horas extra o deducciones que correspondan al ejercicio y tengan justificación.
6. Pulsa Calcular Planilla o la acción de cálculo que muestre el estado actual.
7. Abre Resumen y revisa devengado, deducciones, neto y aportes. Abre la explicación individual del cálculo.
8. En Validaciones resuelve los bloqueos. Si hay diferencias, revisa el detalle concreto antes de continuar.
9. Ejecuta Marcar como Revisada y después Aprobar Nómina (Gerencia), con el responsable autorizado.
10. Si tu cuenta no permite una etapa, pausa la grabación y permite que actúe el responsable correspondiente; no cambies permisos para eludirla.

**Voz sugerida**

> Creo una planilla con un período definido e incluyo a sus trabajadores. Reviso el tiempo reconocido y las novedades antes de calcular. El sistema obtiene los importes individuales con las reglas configuradas y permite consultar su explicación. Después reviso las validaciones y los totales. El flujo pasa de borrador a calculada, revisada y aprobada. La aprobación habilita el pago, pero todavía no significa que el dinero haya sido entregado.

**Evidencia:** período y trabajadores correctos, cálculo vigente, validaciones y estado aprobado. No afirmes que el video certifica la vigencia legal de todas las reglas.

## Video 10 — Pagar a una persona, abonar y obtener comprobantes

**Objetivo:** demostrar pagos por trabajador, sin pagar a todos de una sola vez.

**Acciones en pantalla**

1. En la planilla aprobada abre Pagos por trabajador.
2. Recorre la Guía para pagar a un trabajador y comprueba que no haya bloqueos.
3. En Registrar pago a trabajador selecciona a la primera persona. Muestra salario del período, bonos, deducciones, neto aprobado, abonos y pendiente.
4. Comprueba sesión, fecha, medio y fondos de Caja/Bancos. El filtro mensual del libro no sustituye el saldo disponible que valida el servidor.
5. En la copia de práctica introduce P1, menor que el pendiente. Escribe una referencia identificable y pulsa Registrar pago de nómina.
6. Muestra el comprobante y el nuevo pendiente: neto aprobado menos abonos confirmados.
7. Selecciona a la segunda persona y demuestra que conserva sus propios importes y que no recibió automáticamente el abono de la primera.
8. Si deseas completar la primera persona, registra P2 usando el pendiente actualizado. Si deseas explicar pagos parciales, deja un pendiente y explica que la planilla debe permanecer abierta para siguientes entregas.
9. En Historial de pagos muestra fecha, persona, método, referencia e importe de cada entrega.
10. En Comprobantes (Colillas) abre el documento disponible. Diferencia la liquidación calculada de una colilla del respaldo de una entrega efectivamente confirmada; no presentes un neto calculado como pagado si aún queda pendiente.
11. Solo cuando el pendiente total esté cubierto y existan respaldos, concilia con caja o extracto bancario. Después procede al cierre definitivo si se cumplen los requisitos. No cierres una planilla que aún tiene saldo pendiente.
12. No registres otra salida manual en Caja por el pago que Nómina ya confirmó: duplicaría el egreso.

**Voz sugerida**

> El pago se realiza por trabajador. Selecciono a una persona y reviso su neto aprobado y su pendiente. En este ejercicio registro un abono parcial. Después de la confirmación, el sistema reduce únicamente el saldo de esa persona y conserva la referencia de la entrega. Al seleccionar otro trabajador aparecen sus propios importes. Los siguientes abonos se realizan sobre el pendiente actualizado. La conciliación y el cierre se completan cuando los pagos están respaldados y no quedan diferencias pendientes.

**Evidencia:** pendiente antes y después, historial y comprobante. En la base real, registra un pago únicamente cuando la entrega exista y esté respaldada. La interfaz no envía transferencias al banco.

## Video 11 — Revisar Finanzas, Contabilidad, Mercadotecnia y Reportes

**Objetivo:** explicar la consulta de resultados sin duplicar registros.

**Acciones en pantalla**

1. En Finanzas muestra ingresos, egresos, resultado y proyecciones. Distingue la clasificación financiera, la facturación y el efectivo disponible: son consultas con propósitos distintos.
2. No registres otro ingreso por la factura o por el cobro solo para que todas las tarjetas muestren el mismo valor. Revisa el origen y el alcance de cada cifra.
3. En Contabilidad localiza los asientos de la compra y la venta por su referencia. Muestra Debe, Haber y el resultado del cuadre.
4. Ejecuta la comprobación de cierre disponible y muestra su mensaje. Un descuadre requiere revisión; no se corrige creando un asiento ficticio.
5. Exporta el libro a Excel, si corresponde a la demostración. Abre brevemente el archivo y revisa que sea legible. No vuelvas a cargar el archivo como otra operación.
6. En Mercadotecnia muestra productos, promociones y el álbum mensual disponible. Si publicas un álbum de práctica, identifica el ejercicio y revisa sus productos antes de confirmar.
7. En Reportes muestra las vistas disponibles y los filtros del período. No narres informes o indicadores que la pantalla no ofrezca.
8. Regresa a Costos si deseas contrastar precio, costo de materiales y margen mostrado. Explica que una proyección no es un pago confirmado.

**Voz sugerida**

> Después de operar reviso los resultados. Finanzas organiza las cifras de gestión y sus proyecciones. Contabilidad permite consultar los asientos, comprobar el equilibrio y exportar los libros. Las referencias ayudan a localizar el origen de cada documento. En Mercadotecnia reviso la información comercial y el catálogo disponible. Finalmente, consulto los reportes del período. Estas vistas se interpretan según su fuente: facturación, clasificación financiera y efectivo no representan exactamente el mismo hecho.

**Evidencia:** referencias de compra y venta, comprobación contable y archivo exportado. No agregues asientos manuales para repetir los que ya generó la operación.

## Video 12 — Arqueo final, auditoría y conclusión

**Objetivo:** cerrar el recorrido con comprobaciones y evidencia.

**Acciones en pantalla**

1. Regresa a Caja y revisa el libro del día, sus referencias y el saldo final.
2. Si vas a cerrar una sesión real, cuenta físicamente el efectivo. Si la sesión es de práctica, utiliza el conteo correspondiente al ejercicio.
3. Introduce el importe contado, explica cualquier diferencia y pulsa Arquear y cerrar. No dejes el campo vacío.
4. Muestra el resultado y el estado del arqueo. La revisión posterior corresponde al responsable autorizado.
5. Si utilizaste una sesión bancaria, revisa también su estado y el respaldo del extracto. No sustituyas la conciliación bancaria por un conteo de efectivo.
6. Abre Auditoría y localiza los eventos disponibles para los documentos del ejercicio. No atribuyas a la bitácora local un evento que solo exista en el historial específico de otro módulo.
7. Regresa a Base de datos → SQL y migraciones → Control general de operaciones y vuelve a consultar. Muestra el resultado real, incluidos los pendientes que continúen abiertos.
8. Vuelve al Dashboard y cierra la presentación. Espera a que no haya guardados pendientes antes de cerrar sesión.

**Voz sugerida**

> Para concluir reviso los movimientos del día y comparo el saldo esperado con el importe contado. El arqueo deja documentadas las diferencias y su revisión. Después consulto la auditoría y vuelvo al control general para comprobar los pendientes. Durante el recorrido registré los datos iniciales, recibí materiales, elaboré la documentación comercial y mostré el control de cobros y pagos individuales. El sistema ayuda a mantener orden y trazabilidad; la confirmación del dinero entregado, los conteos y las aprobaciones corresponden a los responsables. Con esto finaliza la demostración de Instalaciones Raquel.

**Evidencia:** estado final de sesión, resultado de revisión y pantalla de cierre. Si queda una nómina parcialmente pagada, dilo expresamente: terminar el video no significa cerrar esa planilla.

## 4. Qué hacer si aparece un bloqueo durante la toma

| Mensaje o situación | Acción correcta | Frase que puedes narrar |
|---|---|---|
| Guardando cambios… | Esperar antes de otra operación. | «Espero la confirmación de SQL antes de continuar». |
| Sesión vencida | Pausar e iniciar sesión fuera de cámara. | «La operación requiere una sesión activa». |
| No se pudo conectar | Comprobar servidor/red y volver a consultar; conservar los datos si hubo una confirmación incierta. | «No consideraré registrado el movimiento hasta verificar su estado». |
| Conflicto de cambios | Descargar la copia pendiente y consultar SQL antes de decidir qué registrar de nuevo. | «Otra sesión modificó la información; reviso antes de sobrescribir». |
| Sesión de Caja de otra fecha | Arqueo real, cierre autorizado y apertura del día. | «El control evita mezclar movimientos de distintas sesiones». |
| Stock insuficiente | Revisar producto, cantidad y recepción real. | «No se confirma una venta sin existencias disponibles». |
| Nómina sin cálculo o aprobación | Completar la guía en su orden. | «La planilla todavía no está habilitada para pagar». |
| Acumulado de pagos sin respaldo | Revisar comprobantes e historial. No ponerlo en cero ni registrar otro pago por intuición. | «La diferencia requiere revisión documental antes de continuar». |
| Fondos insuficientes | Revisar cuenta y saldo confirmado. No inventar una entrada. | «El egreso requiere fondos confirmados en la cuenta seleccionada». |
| Acción sin permiso | Usar al responsable autorizado. | «El sistema separa las funciones de registro y aprobación». |

Puedes incluir un bloqueo explicado como evidencia de control. No necesitas ocultarlo ni simular una solución.

## 5. Cómo grabar la pantalla y luego la voz

1. Usa tu grabador de pantalla habitual. En Windows puedes utilizar una herramienta que capture el navegador; configura primero una toma corta de prueba.
2. Graba cada video con el mismo tamaño de ventana, zoom y tema visual. Evita mover el navegador durante una toma.
3. Di al inicio de la toma, o anota fuera del video, el número de capítulo. Esto facilita ordenar los archivos.
4. Ejecuta las acciones de cada capítulo y deja dos o tres segundos de pausa en cada resultado importante.
5. No repitas una operación confirmada por haber cometido un error al hablar: conserva la pantalla y vuelve a grabar únicamente la voz.
6. Para narrar después, reproduce la toma a velocidad normal y lee el bloque de voz correspondiente. Haz pausas cuando cambies de módulo o esperes una confirmación.
7. Si lees más rápido que la imagen, deja silencios o recorta desplazamientos. No aceleres los resultados hasta hacerlos ilegibles.
8. Une pantalla y voz en tu editor habitual. Ajusta el volumen para que todos los capítulos se escuchen igual.
9. Añade títulos sencillos: «01 — Presentación», «02 — Roles y control», y así sucesivamente.
10. Exporta una versión final, vuelve a verla completa y comprueba voz, legibilidad y orden.

### Nombres de archivos

- 01_Presentacion.mp4
- 02_Roles_y_control.mp4
- 03_Datos_iniciales.mp4
- 04_Compras_e_inventario.mp4
- 05_Proforma_factura_costos.mp4
- 06_Proyectos_y_produccion.mp4
- 07_Caja_y_bancos.mp4
- 08_Talento_humano.mp4
- 09_Calculo_y_aprobacion_nomina.mp4
- 10_Pagos_individuales.mp4
- 11_Finanzas_contabilidad_reportes.mp4
- 12_Cierre_y_conclusion.mp4
- Instalaciones_Raquel_Demostracion_Completa.mp4

## 6. Versión abreviada para una exposición de unos 20 minutos

| Tramo | Tiempo orientativo | Qué conservar |
|---|---|---|
| Presentación y control | 0:00–2:00 | Acceso, conexión, permisos y revisión general |
| Datos y compra | 2:00–5:00 | Datos ya preparados, recepción de 10 unidades y kardex |
| Venta y producción | 5:00–8:00 | Proforma, una factura, stock 8 y tablero de taller |
| Caja | 8:00–11:00 | Apertura del día, un cobro y saldo |
| Personal y nómina | 11:00–16:00 | Dos trabajadores, cálculo/aprobación y un abono individual |
| Resultados y conclusión | 16:00–20:00 | Historial, comprobante, contabilidad, arqueo y auditoría |

En la edición abreviada recorta tecleo y esperas largas. Conserva las confirmaciones y no alteres el orden lógico de los hechos. Si el pago es parcial, no edites el video de forma que parezca una planilla pagada por completo.

## 7. Lista final antes de entregar los videos

- [ ] Se entiende el objetivo desde la primera toma.
- [ ] Los registros del ejercicio se identifican y no se duplicaron al repetir tomas.
- [ ] Se distingue producto de existencias, proforma de factura y factura de cobro.
- [ ] Los números y referencias de compra, venta y pago coinciden entre las tomas.
- [ ] La recepción no se repitió como entrada manual de inventario.
- [ ] El cobro no se registró simultáneamente en Caja y Bancos.
- [ ] Los abonos afectan únicamente al trabajador seleccionado.
- [ ] El pago de nómina no se repitió como salida manual de Caja.
- [ ] No se cerró una planilla con saldo pendiente ni se inventaron respaldos.
- [ ] Los saldos mostrados corresponden a las operaciones visibles y al período correcto.
- [ ] Las pantallas importantes se leen y la voz explica lo que efectivamente aparece.
- [ ] No aparecen contraseñas ni información privada sin autorización.
- [ ] Se muestran y explican los pendientes reales que no se resolvieron.
- [ ] La conclusión describe lo demostrado, sin prometer ausencia de todo error futuro.
- [ ] El archivo final reproduce correctamente del inicio al fin.
