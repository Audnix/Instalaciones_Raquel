# Implementación de pago individual y revisión SQL — 25 de octubre de 2026

## Pantalla de Nómina

La pestaña Pagos por trabajador presenta dos paneles: personal de la planilla con búsqueda y selección, y formulario visible para registrar pago o abono. El mismo formulario se reutiliza en el diálogo para conservar validación e idempotencia. Se muestran salario mensual de referencia, salario reconocido del período, bonos, devengado, INSS laboral, IR, otras deducciones, neto y abonos confirmados. Si el cálculo está desactualizado, los importes no se presentan como un cálculo aprobado.

Se agregó alta de trabajador con nombre, cargo, área, salario mensual y fecha real de ingreso. Usa POST /api/hr/employees y las autorizaciones existentes; registrar personal no crea una cuenta ni confirma un pago. La inclusión posterior en la planilla sigue el servicio correspondiente. No se añadieron campos de contacto ficticios que la API no persiste.

Bonos y deducciones se configuran como novedades antes de aprobar; no se editan descuentos arbitrariamente al pagar ni se copian porcentajes de las imágenes. La explicación muestra bases y resultados reales del servidor y la traza guardada, en lugar de asumir que toda persona tiene una quincena de 15 días o una tasa fija.

El historial presenta fecha, trabajador, período, base del período, bonos, INSS laboral, IR, otras deducciones, neto del cálculo e importe pagado por abono, medio y referencia/movimiento. Para pagos distribuidos se muestra cada asignación, sin sumar otra vez el total del lote. Los conceptos se consultan solo si la versión del pago coincide con la del cálculo; de otro modo se indica ausencia de snapshot. El neto del período no se confunde con cada abono.

Los avisos se limpian al cambiar de planilla. El mensaje del cálculo informa que se guardó con reglas configuradas; no certifica cumplimiento normativo por haber calculado.

## Archivos SQL e instalador

Se catalogaron 38 archivos SQL fuente. El paquete de estructura usa 25 de ellos en un orden explícito y compartido por CLI y API. Se corrigió la dependencia de 07_procedimiento_sincronizacion.sql respecto de las columnas creadas por 17_modulo_nomina_completo.sql. Se retiró la referencia del instalador al archivo inexistente 18_invitaciones_y_gobierno.sql; el archivo real de verificación se mantiene en el catálogo.

Se separaron reconstrucción, acceso/login, diagnósticos y datos opcionales. Las cargas de demostración de Talento Humano requieren activación explícita y no se ejecutan por defecto. El archivo 21 contiene datos de demostración y queda fuera del paquete de estructura; se corrigió una referencia a la columna inexistente Parties.LegalName, conservando legalName en su JSON. Se corrigió la concatenación de marcas BOM internas y se usa UTF-8 con sqlcmd.

npm run db:plan muestra el orden sin ejecutar SQL; npm run db:bundle genera Database/SQLServer_Completo/paquete_estructura_actual.sql. db:install muestra el plan salvo que se solicite --apply. El paquete se detiene si la base ya existe. No incluye cambio de credenciales, importaciones ni reconstrucción. No se ejecutó el paquete sobre la base real.

Base de datos → SQL y migraciones ofrece inspección de solo lectura y descarga para superadministración. Muestra archivos, tablas declaradas, claves y marcadores conocidos. Una conexión con visibilidad parcial no permite afirmar que un objeto esté ausente: la interfaz lo identifica como ausente o no visible. No se exponen contraseñas ni se ejecuta SQL desde la descarga.

## Prueba de instalación y actualización de la instancia

Se ejecutó el paquete completo en bases temporales de nombre Raquel_Schema_Check_20261025_*. Las primeras pruebas localizaron dependencias faltantes, una carga de empleado de ejemplo con usuario inexistente, datos de proveedor incompatibles y una marca de codificación interna. Se corrigieron y se repitió la instalación nueva de principio a fin. La prueba final Raquel_Schema_Check_20261025_99ef80cc terminó correctamente con 69 tablas declaradas cubiertas, 75 tablas totales (incluidos respaldos técnicos), 58 procedimientos y 119 claves foráneas activas, ninguna deshabilitada; cero empleados, planillas, pagos y movimientos operativos.

La base real tenía una de esas 69 tablas ausente: PayrollNoveltyEvents. Se hizo un respaldo COPY_ONLY con CHECKSUM y RESTORE VERIFYONLY, y se aplicó solo 33_eventos_novedades_nomina.sql, que crea esa tabla y los permisos previstos para su auditoría. Resultado final: 69/69 tablas declaradas, 78 tablas totales, 68 procedimientos y 121 claves foráneas activas, ninguna deshabilitada. Se conservaron 22 empleados, 7 planillas, 0 pagos y 9 movimientos de caja. No se modificaron salarios, cuentas, contraseñas ni estados de planilla en esta revisión.

La prueba de protección volvió a ejecutar el paquete contra la base temporal existente y obtuvo el rechazo esperado antes de ejecutar la estructura. Se eliminaron únicamente las bases temporales creadas para estas pruebas; no se eliminó la base real.

Evidencias: schema_check_isolated_result.txt, schema_coverage_readonly.sql, schema_coverage_readonly_result.txt, schema_existing_guard_result.txt, schema_check_cleanup_result.txt, backup_before_migration33_2026-10-25.txt, migration33_result_2026-10-25.txt y database_source_catalog_2026-10-25.json.

## Validación y límites

- 42 pruebas locales aprobadas, incluidas cobertura del catálogo, orden de dependencias, exclusión de operaciones peligrosas, guía de pago, prevalidación, permisos e idempotencia.
- Consulta SQL del nuevo historial ejecutada sobre las 7 planillas, solo lectura. Con cero pagos actuales esto valida compatibilidad de la consulta, no un historial con pagos reales.
- Instalación nueva de estructura y bloqueo de reinstalación probados en SQL Server aislado.
- TypeScript y compilación de producción comprobados.

La cobertura de tablas y la creación del esquema no equivalen a certificar todas las columnas, reglas legales, datos históricos ni los recorridos completos de venta, compra, inventario o nómina. No se realizó un desembolso real ni se fabricaron registros para imitar las imágenes. Las diferencias históricas de otras planillas siguen requiriendo documentos y revisión autorizada.

Las rutas nuevas se comprobaron también sin autenticación: /health respondió 200 y /api/database/status y /api/database/structure.sql respondieron 401. No se usaron credenciales de otra persona ni se fabricó una sesión. La guía distingue diferencias de importes de validaciones del cálculo para evitar enviar al usuario a una lista vacía.

Orden final: 19_directorio_proveedores.sql se aplica después de 26_integridad_caja_nomina_pagos.sql para conservar la protección de proveedores al redefinir el snapshot. Se verificó SupplierProtection=1 en la instalación aislada; evidencia: schema_supplier_protection_result.txt.

