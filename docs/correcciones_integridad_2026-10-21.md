# Caja y pagos de nómina: revisión del 21 de octubre de 2026

> Actualización posterior: la migración 30 ya aparece presente en la base; 31 y 32 siguen pendientes. Ver `continuacion_caja_nomina_2026-10-21.md` para el estado más reciente.

## Resultado y despliegue pendiente

Se corrigieron el resumen de Caja, la coordinación de pagos, la distribución por trabajador y la verificación de permisos. La migración **30_pagos_individuales_atomicos.sql está preparada, NO instalada**. La conexión de la aplicación tiene lectura/escritura pero no permisos para crear o modificar procedimientos. La conexión administrativa de Windows tampoco estuvo disponible. No se cambiaron contraseñas ni permisos de SQL.

Para habilitar el nuevo pago, un administrador de la base debe revisar y ejecutar, con respaldo previo, `Database/SQLServer_Completo/30_pagos_individuales_atomicos.sql` sobre la instalación existente que ya contiene las migraciones 26–29. Después hay que reiniciar la API y actualizar el navegador. No usar reinstalación, reconstrucción ni semilla para esto.

La API exige el marcador de la migración y devuelve un mensaje explícito si falta: no continúa usando silenciosamente el procedimiento antiguo.

## Causas verificadas en los archivos

- El último procedimiento de pago definido por los scripts 26–29 es el de la migración 28. La 29 anuncia mejoras del pago en su comentario, pero no redefine ese procedimiento.
- El procedimiento 28 utiliza `cash-nom-<planilla>` para todos los pagos. Actualiza importe, cuenta y fecha de ese mismo movimiento; un pago en Banco puede trasladar un egreso anterior de Caja.
- Comprueba el pendiente general antes de abrir la transacción y no limita el neto individual. El bloqueo de lectura no permanece hasta confirmar los efectos.
- La repetición de una clave devuelve un recibo sin contrastar el contenido de la solicitud.
- La pantalla descuenta solo recibos con EmployeeId individual. Un pago general no disminuye lo pendiente de cada trabajador.
- El resumen sumaba cada apertura al saldo anterior. Dos aperturas con el mismo dinero volvían a contarlo. El filtro final por fecha podía excluir movimientos con hora.
- La autenticación continuaba con los privilegios del token si fallaba la consulta de sesión a SQL. Tampoco trasladaba MustChangePassword a las restricciones de escritura.

## Cambios

- Migración 30: transacción que incluye validaciones, recibo, distribución, movimiento, asiento y actualización de pendientes. Bloqueo por planilla y por clave de operación. Se conserva cada pago y su cuenta; no se vuelven a descontar deducciones del neto.
- Distribución explícita por trabajador: el pago general se asigna al pendiente en orden estable de identificador. La distribución queda registrada y se consulta desde la pantalla.
- Reintento con igual clave y contenido: mismo recibo. Clave con otro contenido: conflicto. Referencia repetida para el mismo beneficiario, fecha, medio y planilla: rechazo.
- Los históricos sin distribución verificada bloquean pagos nuevos de esa planilla; no se les inventa una asignación.
- El asiento del pago cancela Sueldos por pagar contra Caja/Banco. No vuelve a registrar el gasto salarial. Esto no sustituye la revisión pendiente del asiento original de devengo.
- Protección en SQL contra modificar o borrar aisladamente movimientos que respaldan pagos confirmados. El reverso coordinado completo queda pendiente; no se ofrece una anulación que desordene el recibo.
- Caja: resumen con diferencias de apertura, fechas locales completas y orden consistente para el saldo anterior. “Base del período” explica el saldo anterior y el ajuste por aperturas.
- Nómina: historial de pagos no cargado bloquea el envío; se limpian datos al cambiar de planilla. Se calculan pendientes individuales incluyendo distribuciones generales. Se evita una afirmación de cumplimiento legal basada solo en una lista vacía.
- La sesión vigente determina rol y áreas. Una falla al verificarla responde 503; una sesión revocada o ajena responde 401. Registrar pagos requiere superadministrador o administrador de Finanzas/Contabilidad; preparar nómina no concede automáticamente permiso para pagar.

## Pruebas ejecutadas

- 8 escenarios SQL del cuerpo del nuevo procedimiento: reintento, contenido en conflicto, límite individual, Caja/Banco separados distribución general, saldo insuficiente, referencia duplicada con otra clave y reversión por fallo al insertar. Todos pasaron. Fixtures dentro de transacciones revertidas; se utilizó una tabla temporal para la distribución, sin instalar la migración.
- 3 escenarios SQL de la consulta real del resumen: 1000 + 500 − 200 = 1300; reapertura con 1300 y salida de 100 = 1200; consulta de ambos días sin duplicar la apertura. Incluyen movimiento a las 23:00 con zona −06:00. Solo lectura, todos pasaron.
- 15 pruebas locales: sesión/permisos, distribución de pagos y regresión de proveedores. Todas pasaron.
- TypeScript, sintaxis de rutas y compilación de producción Vite correctos. SQL Server también aceptó los siete lotes de la migración con PARSEONLY, sin instalarlos.

Estas pruebas del cuerpo SQL NO prueban el despliegue, el trigger instalado, dos conexiones simultáneas ni el recorrido completo por navegador autenticado.

Comandos repetibles desde la raíz:

```
node --test server/tests/authIntegrity.test.mjs server/tests/payrollPayments.test.mjs server/tests/supplierDirectory.test.mjs
node server/scripts/verify-payment30-rollback.mjs
node server/scripts/verify-cash-summary-readonly.mjs
node node_modules/typescript/bin/tsc --noEmit --incremental false -p tsconfig.app.json
```

El ensayo reversible de pagos requiere una planilla calculada sin pagos y ninguna sesión de caja abierta. No ejecutarlo simultáneamente con operaciones reales.

## Inconsistencias observadas en SQL (sin reparación automática)

La consulta inicial devolvió seis planillas, cero recibos PayrollPayments y cero sesiones de caja. Cuatro planillas en estado pago_registrado, conciliada o cerrada tenían TotalDeductions de cabecera en cero; dos calculadas sí tenían deducciones. No se interpretan los estados históricos como prueba de pago efectivo.

La auditoría ejecutada devolvió cuatro planillas con diferencias. Al terminar se conservaron 6 planillas, 114 detalles, 6 movimientos, 0 recibos y 0 sesiones. Evidencia: `docs/auditoria_integridad_2026-10-21.json`.

`docs/30_auditoria_integridad_solo_lectura.sql` identifica diferencias entre cabecera/detalle/pagos, pagos sin salida coherente, claves repetidas y movimientos de nómina sin recibo. Debe revisarse con documentos antes de cualquier ajuste.

## Pendientes para cumplir el criterio integral

1. Instalar la migración con un administrador y probar inicio de sesión, cálculo, revisión, aprobación y pago reales; comprobar reintentos simultáneos desde dos conexiones y pérdida de respuesta.
2. Conciliar históricos con documentos. No convertir estados antiguos en recibos ficticios ni borrar registros por importe repetido.
3. Revisar reglas de cálculo por fecha del período y fundamento. La función de la migración 29 elige reglas por fecha actual; su IR sigue codificado en el procedimiento. No se verificó su vigencia legal ni se certificaron las deducciones.
4. Revisar el devengo contable: actualmente acredita el bruto a Sueldos por pagar; falta separar correctamente neto y retenciones en líneas contables. El nuevo asiento de pago no resuelve por sí solo ese pasivo histórico.
5. Sustituir los efectos transaccionales reconstruidos por snapshot. El script 26 aún elimina/reinserta movimientos sin OperationKey. No se reemplazó el procedimiento completo de sincronización sin poder inspeccionar su definición vigente con la cuenta disponible.
6. Completar recorridos de orden/recepción/factura/obligación/pago parcial del proveedor y venta/inventario/cobro. Las pruebas de proveedores ejecutadas validan su servicio y permisos; no certifican esos recorridos integrales.
7. Completar reversos coordinados, conciliación y revisión contable del catálogo de cuentas, monedas y cierres.

No se declara el sistema completo automatizado ni validado.
