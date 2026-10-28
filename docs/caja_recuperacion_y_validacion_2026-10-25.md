# Caja: sesión anterior y confirmación de movimientos

Diagnóstico SQL de solo lectura: fecha operativa 2026-10-25; única sesión abierta, cuenta caja, fecha 2026-10-21; 9 movimientos. La regla existente exige que el movimiento corresponda a la fecha de sesión. No se cambió la fecha de esa sesión ni se cerró automáticamente.

## Cambios

- La API devuelve la fecha operativa de SQL Server, zona Centroamérica, junto con las sesiones.
- Caja y Bancos comprueban esa fecha antes de habilitar movimientos. Una sesión anterior muestra el motivo y un acceso al arqueo y cierre.
- Apertura y arqueo exigen un valor contado explícito; un campo vacío no se transforma en cero. Se aceptan cero y hasta dos decimales.
- Cada movimiento envía el identificador de sesión observado; el servidor vuelve a validarlo bajo bloqueo. Las claves de reintento se mantienen tras un error en el formulario.
- Caja y Bancos tienen componentes independientes para evitar conservar formularios, claves y resúmenes de la cuenta anterior al navegar.
- Se refrescan las consultas al recuperar red o foco, sin hacerlo durante una operación pendiente. No se automatizan pagos, conteos ni aprobaciones.
- Errores HTTP sin JSON, límite de consultas y falta de confirmación SQL tienen mensajes específicos en lugar del mensaje genérico. No se muestra éxito ante un rechazo.

## Evidencia

47 pruebas locales aprobadas, incluidas tres nuevas para fecha de sesión, conteo explícito y respuestas HTTP sin JSON. TypeScript y producción compilados: build_cash_recovery_2026-10-25.txt.

La primera prueba reversible del banco agotó el tiempo SQL después de comprobar apertura y reintento. Revirtió correctamente y conservó 1 sesión, 9 movimientos y 0 pagos. La repetición instrumentada completó apertura, entrada 500, salida 200, saldo 1300, reintentos sin duplicación, rechazo de importe modificado y exceso de saldo, cierre, sugerencia y reapertura. Se revirtió toda la transacción y se conservaron esos conteos. Evidencia: bank_workflow_trace_2026-10-25.txt.

La prueba específica de la sesión antigua rechazó el movimiento con código 50612 e indicación de arqueo y cierre; no creó movimientos. Evidencia: stale_cash_rollback_2026-10-25.txt.

Estas verificaciones cubren reglas y transacciones de Caja/Bancos y las pruebas existentes de otros módulos. No constituyen una certificación de todos los recorridos visuales del ERP. No se realizó una operación real ni un recorrido de navegador autenticado.

## Paso operativo pendiente

El responsable debe contar el efectivo real y registrar el arqueo de la sesión del 21/10, explicar cualquier diferencia y cerrar. Después debe abrir la sesión del día con su saldo contado y registrar la operación real. El saldo final sugerido es una ayuda y no sustituye el conteo físico. No se debe registrar el mismo cobro desde varios módulos.
