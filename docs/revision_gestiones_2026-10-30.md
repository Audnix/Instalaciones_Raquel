# Revisión de gestiones — 30 de octubre de 2026

## Comprobado

- API local y conexión a SQL Server: respuestas HTTP 200 en las rutas de salud.
- Consultas de Mis tareas ejecutadas en modo de lectura contra SQL Server, con un actor diagnóstico sin solicitudes personales: 13 resultados y sin error. Esto comprueba las consultas, no sustituye el acceso autenticado desde el navegador.
- Compras recibe también alertas de stock crítico. Finanzas enlaza a su propia área cuando no tiene acceso a contabilidad.
- El filtro de prioridad distingue entre no tener pendientes y no tener coincidencias; los contadores no muestran cero ante una consulta fallida.
- La pantalla descarta respuestas anteriores al cambiar de usuario o desmontarse, y bloquea consultas repetidas mientras carga.
- 86 pruebas automatizadas aprobadas. Incluyen permisos, consulta de tareas, coherencia de ventas/compras con kardex y asientos, preservación de otras áreas y validación de caja/pagos.

## Hallazgos reales para conciliación

La auditoría existente de solo lectura encontró:

- 0 incidencias de validación en el estado operativo guardado. Esta comprobación no cubre todas las relaciones del negocio.
- 1 sesión de caja abierta con fecha anterior al día operativo.
- 3 planillas donde ConfirmedPaymentsTotal difiere de la suma de PayrollPayments confirmados.

No se cerraron sesiones ni se alteraron pagos. Las diferencias requieren contrastar el historial y las referencias antes de resolverlas; no prueban por sí solas un pago duplicado.

El resumen sin datos personales está en verificacion_operativa_2026-10-30.json.

## Recorrido pendiente de validación visual

Usar una copia de prueba de la base para crear registros y evitar documentos operativos ficticios.

1. Crear una cotización con cliente y materiales conocidos; verificar cantidades e importe.
2. Facturarla una sola vez; verificar el vínculo convertedSaleId, salida PEPS, kardex y asiento. Un segundo intento debe rechazarse.
3. Revisar el traslado al taller: hoy la orden de producción se captura por separado y no contiene un vínculo de factura. No considerar automatizado ese paso ni asociar documentos por coincidencia de nombres.
4. Mover la orden por corte, ensamble, instalación y entrega con un usuario autorizado.
5. Confirmar el cobro desde caja con la referencia de venta, sesión del día y cuenta correctas; comprobar saldo e historial. La factura por sí sola no confirma un cobro.
6. En compras, comprobar recepción, lotes, kardex y obligación; no equiparar recepción con pago al proveedor.

## Respaldo y recuperación

Antes de probar cambios sobre copias de datos, generar un respaldo desde SSMS de la base correcta y registrar fecha y ubicación. Restaurarlo con otro nombre en un entorno de prueba y comprobar tablas, acceso y registros conocidos. La existencia de un archivo .bak no demuestra que se pueda restaurar. No se ha creado ni restaurado un respaldo en esta revisión.

## Diagnóstico ampliado

- Las tres planillas con diferencias tienen acumulado distinto de cero y ningún registro en PayrollPayments, confirmado o de otro estado. Esto no permite deducir si el dinero se pagó fuera del sistema; se necesitan comprobantes.
- La sesión pendiente corresponde a banco, del 27 de octubre de 2026, con dos movimientos confirmados.
- El historial de SQL Server registra un respaldo completo copy-only terminado el 25 de octubre de 2026 a las 20:32:07, según la hora almacenada por el servidor. No se ha verificado ni restaurado el archivo.
- El panel de control general ahora identifica cada planilla con diferencia y permite abrirla directamente; también enlaza a banco o caja para revisar sesiones pendientes.
- El diagnóstico se puede repetir con node server/scripts/diagnose-reconciliation-readonly.mjs. Solo ejecuta consultas y actualiza el informe local de diagnóstico.

## Verificación del respaldo: permiso pendiente

Se intentó RESTORE VERIFYONLY sobre el respaldo completo registrado. SQL Server rechazó la operación porque la cuenta de aplicación no tiene CREATE DATABASE en master. No se comprobó la legibilidad del archivo y no se modificaron permisos ni se restauró ninguna base.

El script docs/verificar_respaldo_solo_lectura.sql queda preparado para ejecutarse en SSMS con una cuenta administradora autorizada. No debe concederse ese permiso a la cuenta habitual del ERP para resolver esta comprobación.

## Confirmación de verificación por SSMS

El usuario ejecutó el script con una cuenta autorizada y aportó una captura de Mensajes con «The backup set on file 1 is valid». Se registra VERIFYONLY como aprobado según esa evidencia. El intento anterior con la cuenta de aplicación quedó bloqueado por permisos; no se cambiaron esos permisos. Sigue pendiente restaurar una copia en un entorno separado y comprobar su funcionamiento.

## Evidencia por planilla y preparación de restauración

- PL-2026-10-Q1: 14 trabajadores marcados pagados, sin historial de eventos, sin PayrollPayments y sin salidas confirmadas vinculadas. Requiere comprobantes externos o confirmar su origen de carga.
- pr-2026-10-1: 14 trabajadores marcados pagados, sin PayrollPayments ni historial de eventos; tiene una salida confirmada vinculada cuyo importe coincide con el acumulado. No volver a pagar ni poner a cero: falta recuperar o documentar el detalle del pago y su distribución individual.
- run-test-mvfbrouy: 22 trabajadores marcados pagados, siete eventos de historial (dos relacionados con pago/conciliación), sin PayrollPayments ni salidas confirmadas vinculadas. Su nombre parece de prueba, pero no autoriza borrarla.
- La sesión de banco del 27/10 tiene una entrada y una salida confirmadas; la salida está vinculada a nómina. Falta conocer el saldo bancario real al cierre antes de conciliar.

Se preparó docs/restaurar_copia_prueba.sql para SSMS administrador. Crea exclusivamente Instalaciones_Raquel_Prueba_20261030, usa nombres de archivo propios, rechaza destinos existentes y no usa WITH REPLACE. Obtiene los archivos lógicos del respaldo mediante FILELISTONLY y ejecuta CHECKDB en la copia. No se ha ejecutado ni validado en SQL Server porque la cuenta de aplicación carece del permiso de creación. No cambia .env ni el origen utilizado por el ERP.

Referencias de sintaxis: https://learn.microsoft.com/sql/t-sql/statements/restore-statements-filelistonly-transact-sql

## Restauración confirmada por captura de SSMS

La captura aportada por el usuario muestra Instalaciones_Raquel_Prueba_20261030 ONLINE, con 3 ventas, 10 lotes y 7 planillas. Se registra la copia como restaurada. La captura no muestra la pestaña Mensajes; todavía no se confirma que CHECKDB terminara sin errores. Sigue pendiente probar las gestiones en la copia.

## Mensajes de restauración y CHECKDB

La segunda captura de SSMS muestra RESTORE DATABASE successfully processed y el mensaje final del script, sin errores visibles de CHECKDB (ejecutado con NO_INFOMSGS). Se registra la verificación de restauración y CHECKDB según esta evidencia. La prueba funcional de gestiones sobre la copia sigue pendiente.

## Pruebas ejecutadas en la copia restaurada

La cuenta del ERP accede a Instalaciones_Raquel_Prueba_20261030. La conexión de cada prueba verificó DB_NAME() antes de ejecutar cambios y no se modificó .env.

- Banco: apertura idempotente, entrada 500, salida 200, saldo 1300, rechazo de clave con datos distintos, rechazo de sobregiro, arqueo/cierre, saldo sugerido y reapertura: aprobados. Rollback confirmó 1 sesión, 9 movimientos y 0 pagos conservados. Las cantidades indicadas pertenecen a fixtures de prueba.
- Caja antigua: se rechaza un movimiento con instrucción de arqueo y cierre. No se creó ningún movimiento; transacción revertida.
- Guardado y venta: bloqueo por referencia SupplierDirectory/Parties, propio del procedimiento antiguo del respaldo. Rollback verificó conservación de revisión, hash y conteos. La copia necesita el parche existente 34. La cuenta ERP no tiene VIEW DEFINITION ni ALTER: el intento de aplicar el parche se revirtió.

Se preparó docs/actualizar_copia_prueba_parche34.sql para SSMS administrador, con comprobación de la base destino en cada lote. Solo actualiza el procedimiento de la copia; no ejecuta guardados ni altera datos operativos. Pendiente de su ejecución para repetir guardado y ventas.

## Recorrido comercial verificado tras parche 34

El usuario confirmó ejecución correcta del parche en SSMS. La prueba de guardado completo y venta pasó en la copia restaurada. Se añadieron pruebas transaccionales de recepción de compra, proforma convertida, vínculo ConvertedSaleId y orden de producción manual por las cuatro etapas hasta entregado.

Se detectó que la API registraba la referencia textual del cobro pero no su SaleId ni actualizaba AccountsReceivable. Se corrigió cashTransaction mediante saleReceipt: Venta/Cobro requieren una factura confirmada y su referencia exacta; se verifica el saldo con bloqueo sobre la factura, se vincula el movimiento y se actualiza el pendiente en la misma transacción. El reintento no duplica el movimiento, el exceso se rechaza y la anulación repone el saldo. Los ingresos sin factura se registran como Otro; se añadió esta explicación en caja. Los cobros históricos con referencia exacta se cuentan para el límite, sin modificar sus filas.

El recorrido ampliado aprobó el cobro completo, la repetición idempotente, rechazo de referencia inexistente y exceso, anulación y abono parcial. El rollback comprobó hash, revisión y conteos originales de la copia. No se alteraron registros de la base operativa. Son pruebas de servicios y persistencia; la revisión visual del navegador no forma parte de esta comprobación.

Se puede repetir con node server/scripts/verify-commercial-copy-rollback.mjs; el script fija la base de prueba y verifica DB_NAME antes de ejecutar cambios.

También se corrigió la fecha predeterminada de los movimientos: cuando la API no recibe una fecha explícita usa el día operativo de Nicaragua confirmado por SQL Server, en lugar del valor UTC predeterminado del procedimiento. El recorrido comercial comprobó que la fecha del movimiento coincide con la sesión local. Las 90 pruebas unitarias pasaron y la compilación del frontend terminó correctamente; la integración comercial se ejecutó con rollback en la copia.

## Navegación y búsqueda

Se reemplazó el buscador superior sin acción por QuickNavigationSearch. Filtra módulos permitidos y registros disponibles en el estado de la sesión: facturas, cotizaciones, órdenes, productos, compras y clientes. No hace consultas adicionales a la API ni amplía permisos; para cuentas que no tienen estado global disponible la búsqueda de registros puede ser limitada, mientras que los módulos autorizados siguen disponibles.

Se añadieron anclas para facturas y clientes, con desplazamiento y resaltado del registro. Flechas y Enter seleccionan un resultado; Escape y la salida de foco cierran la lista. Las consultas se limpian al cambiar usuario o pantalla y no se guardan en almacenamiento. Tres pruebas específicas verifican acentos, enlaces escapados, permisos, exclusión de nómina/usuarios y límite de resultados.

No se pudo comprobar visualmente: las herramientas de control de Windows y navegador devolvieron “failed to write kernel assets” por una ruta inexistente del entorno. No se automatizó la autenticación ni se modificaron registros operativos.

Validación de la búsqueda: 93 pruebas automatizadas aprobadas y build de producción completado. La comprobación visual sigue pendiente por el error del entorno de control de aplicaciones.

## Acceso desde factura al cobro

Las facturas confirmadas muestran Cobrar en efectivo/Cobrar en banco solo cuando el usuario tiene permiso en el módulo correspondiente. El enlace transporta únicamente el número de factura, sin confiar en importes de la URL.

La nueva consulta GET /api/cash/sale-balance requiere autenticación y permiso de lectura financiera; valida la referencia y calcula el pendiente con los pagos confirmados. El panel permite preparar el formulario con referencia, concepto e importe y actualizar el saldo; no registra movimientos automáticamente. Una factura saldada no ofrece preparar otro cobro, y una sesión no vigente mantiene el formulario bloqueado. Los importes pueden reducirse para abonos y se vuelven a comprobar al confirmar.

La prueba comercial con rollback en la copia confirmó que la consulta coincide con el pendiente antes del pago y después de un abono. Las pruebas unitarias cubren referencia parametrizada y factura inexistente. La revisión visual sigue pendiente por la indisponibilidad de las herramientas de control de aplicaciones.

## Preparación de taller desde factura

Las facturas confirmadas permiten abrir Preparar orden de taller cuando el usuario tiene permiso de escritura en producción. En producción también se puede consultar directamente un número de factura, seleccionar una línea y completar cliente, trabajo, cantidad y código sugerido; se crea únicamente al confirmar Crear Orden. Se revisan manualmente medidas y unidad. El código sugerido contiene una referencia legible a la factura y la línea; no se añadió una relación SQL nueva entre documentos.

La ruta GET /api/module-state/produccion/source conserva requireAuth y authorizeModule. La proyección devuelve solo número de factura, cliente y líneas con descripción y cantidad; excluye importes. Se añadió rechazo de códigos de orden duplicados en el guardado por módulo y validación previa en el formulario. Cantidades fraccionarias admiten cuatro decimales, conforme a la columna SQL.

La prueba comercial en la copia usa el servicio de origen y el generador de borrador antes de guardar y recorrer las etapas de producción; pasó con rollback confirmado. Cuatro pruebas específicas cubren proyección, parámetros, permisos, códigos y cantidades. La validación visual sigue pendiente por el fallo del entorno de control de aplicaciones.

## Confirmación de datos de prueba y mantenimiento

El usuario confirmó expresamente que son de prueba la sesión bancaria y las tres planillas. Se ensayó el mantenimiento con rollback y después se confirmó una transacción acotada en la base configurada. El cierre de banco usa C$4,152.67 como conteo SIMULADO y guarda una explicación que lo distingue de una conciliación real. Se añadieron tres eventos clasificacion_prueba, conservando estados e importes de nómina. No se crearon pagos ni se borraron registros.

La consulta posterior confirmó cero sesiones antiguas abiertas, tres diferencias históricas y las tres clasificadas como prueba. El panel conserva las diferencias con una etiqueta explícita y Caja/Bancos permite consultar la explicación del cierre simulado. Se conserva una captura previa y el resumen de la transacción en los archivos de mantenimiento. La revisión visual sigue pendiente por el fallo del entorno de control de aplicaciones.
