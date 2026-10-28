# Revisión y automatización general

## Alcance implementado

Se revisó el código común de los módulos operativos y sus recorridos de persistencia: ventas/proformas, compras, inventario, finanzas, contabilidad, producción, proyectos, clientes, catálogo, reportes y auditoría. Se conservaron los servicios con permisos propios de Talento Humano, Nómina, Caja/Bancos, proveedores y usuarios. No se ampliaron permisos ni se automatizaron desembolsos, conteos físicos o aprobaciones.

### Guardado y navegación

- El guardado global usa una cola serial. No cancela una escritura en curso al producir otro cambio; el siguiente guardado usa la revisión confirmada del anterior.
- Ante conflicto, rechazo o respuesta incierta, detiene la cola y conserva el estado local para revisión. No adopta otra revisión para reenviar a ciegas.
- Los módulos muestran estado de consulta/guardado y pausan nuevas operaciones mientras se guarda o no existe confirmación SQL. Permiten descargar la copia local y volver a consultar con advertencia antes de sustituir cambios pendientes.
- Se avisa al intentar cerrar la página con cambios pendientes. El cambio de sesión detiene la cola antigua y se comprueba la cuenta antes de enviar.
- Se eliminaron las semillas de producción del almacén del navegador. Una lista vacía de SQL permanece vacía; no se repone por tener menos filas que una demostración. Las contraseñas se excluyen de caché y exportaciones de estado.
- Las selecciones de productos se actualizan cuando llega la consulta; la navegación remonta el espacio de cada módulo. Los flujos documentales visibles usan documentos guardados, no identificadores de ejemplo.

### Integración operativa

- Emitir factura o convertir una proforma crea cuenta por cobrar; no inventa efectivo ni ingreso de tesorería. El cobro se confirma desde Caja/Bancos. No se reclasificaron ventas históricas.
- La asignación PEPS agrega cantidades de líneas repetidas, usa el costo del lote y conserva los objetos originales; rechaza stock insuficiente y cantidades inválidas.
- Una compra recibida agrega lotes, kardex y su asiento en el mismo estado; una orden sin recepción no agrega inventario ni pagos.
- El cierre de comprobación informa descuadres sin generar asientos artificiales para compensarlos.
- El servidor valida cambios de documentos, importes, productos, existencias, movimientos, asientos, producción, proyectos y terceros. Exige todas las colecciones del snapshot. Los cambios de lotes deben coincidir con su kardex y no se permite reescribir o eliminar el historial de inventario.
- Los errores históricos sin cambios se pueden consultar en el informe; no se inventan ajustes para borrarlos. Los controles del navegador se complementan con validación dentro de la transacción SQL bajo bloqueo y revisión.

## Corrección SQL aplicada

La prueba real del guardado descubrió que usp_SaveErpState intentaba borrar proveedores referenciados por SupplierDirectory. Se creó y verificó un respaldo COPY_ONLY/CHECKSUM antes de aplicar 34_preservar_proveedores_guardado_global.sql. Esta migración conserva proveedores confirmados y recompila únicamente el procedimiento con ANSI_NULLS y QUOTED_IDENTIFIER activados. No ejecuta el snapshot ni cambia registros operativos.

Se actualizó el catálogo y el paquete de instalación: 39 fuentes, 26 scripts de estructura y 69 tablas declaradas. El paquete completo continúa siendo exclusivo para bases nuevas; no debe ejecutarse sobre la instalación real.

## Control general disponible

Base de datos → SQL y migraciones → Control general de operaciones consulta al abrirse y bajo demanda. Revisa las 19 colecciones del estado guardado, fechas de sesiones y acumulados de nómina contra recibos confirmados. No confunde las cantidades del snapshot con los totales de tablas de los módulos independientes. Es de solo lectura y requiere superadministración.

Comandos reproducibles:

- npm test: pruebas de regresión.
- npm run check:system: pruebas y compilación.
- npm run audit:operations: auditoría de solo lectura de la base configurada, con informe JSON.

## Verificación

- 58 pruebas aprobadas: tests_general_2026-10-25.txt.
- TypeScript y compilación de producción: build_general_2026-10-25.txt.
- Guardado completo y una factura de prueba con stock/kardex/asiento, sin cobro artificial, ejecutados dentro de una transacción exterior revertida. Se verificó que versión, hash del snapshot y conteos quedaran intactos: 22 empleados, 9 movimientos, 0 pagos, 3 ventas y 10 lotes. Evidencia: general_snapshot_rollback_2026-10-25.txt.
- DBCC CHECKCONSTRAINTS no devolvió violaciones; cero claves foráneas deshabilitadas y ambas opciones del procedimiento activadas. Evidencia: general_constraints_2026-10-25.txt. La primera comprobación agotó 30 segundos; se completó al repetirla con mayor plazo después de compilar.
- API y SQL respondieron 200 por localhost:5173; las rutas de estado y control de operaciones respondieron 401 sin sesión. No se fabricó una sesión ni se usaron credenciales ajenas.

## Hallazgos que requieren intervención

El estado guardado no produjo hallazgos en las reglas del nuevo auditor. La instancia sí conserva una sesión de Caja del 21/10 abierta y tres planillas cuyo acumulado difiere de sus recibos confirmados. Se muestran para arqueo/revisión documental; no se cerró caja ni se alteraron pagos automáticamente.

La prueba cubre código común, reglas, transacciones y restricciones. No se realizó un recorrido visual autenticado por cada pantalla ni se certificó vigencia legal/fiscal. No se afirma ausencia de todo fallo futuro. Los perfiles inferiores mantienen los límites del guardado global y deben usar los servicios específicos autorizados.
