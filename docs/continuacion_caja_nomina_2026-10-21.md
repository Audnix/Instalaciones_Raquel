# Continuación: gestiones de Caja e integridad

## Caja

La gestión de Caja utiliza ahora su propia conexión a la API. Un fallo en el snapshot general no la deja en modo local si sus consultas funcionan. Requiere sesión válida y permisos de Finanzas/Contabilidad según la operación.

Se comprobó con la lógica del servicio y SQL instalado: abrir con 1000, reintentar sin duplicar, ingresar 500, retirar 200 y obtener 1300 por movimiento; rechazar reutilización de clave con otro importe; rechazar salida de 1301; arquear/cerrar con 1300; rechazar movimiento en sesión cerrada y reabrir manteniendo 1300. Todos los fixtures se revirtieron.

Se encontró durante la prueba que dos movimientos en el mismo segundo podían quedar invertidos por su UUID. El libro de la API utiliza sesión, fecha/hora, creación y desempate estable. El servicio serializa operaciones por cuenta dentro de una transacción y conserva orden de creación. Aperturas y movimientos usan fecha/hora de Nicaragua.

Los bancos también vinculan los movimientos nuevos a una sesión abierta. La API comprueba cuenta, fecha, pendiente de sesión, saldo e idempotencia. Se impide registrar un pago de nómina manual desde Caja o anular aisladamente una apertura/pago confirmado.

**Alcance:** apertura, movimientos manuales, saldo, arqueo y cierre están probados con el servicio. Eso no certifica un cobro de factura, pago de proveedor, transferencia entre cuentas ni su contabilización completa. Se deben completar los servicios comerciales vinculados para liquidar documentos automáticamente. Un registro manual no debe tomarse como prueba de que una factura quedó liquidada.

En la comprobación local respondieron la interfaz en `http://localhost:5173/`, la API en el puerto 4000 y su conexión con SQL Server. Las rutas financieras sin sesión responden 401. No se utilizó ni suplantó la sesión de otro usuario para las pruebas.

## Trabajo adicional

- **Compras:** recibir mercancía deja de crear un egreso financiero ficticio en el navegador. Conserva inventario y obligación; el pago es otra operación.
- **Migración 31:** calcula con reglas verificadas que cubren el período; elimina las tasas alternativas silenciosas y el IR codificado; conserva los parámetros usados en la explicación. Permite versiones de reglas por fecha. Separa neto salarial, retenciones y cargas patronales en el devengo. Impide autoaprobación y retroceso directo de planillas ya devengadas. La conciliación utiliza recibos confirmados, no solo una cabecera marcada como pagada.
- Los nuevos vencimientos institucionales quedan pendientes de definir cuando no hay calendario confirmado. Finanzas puede registrar la fecha real y su fuente desde la pantalla; se comprueba revisión y se guarda el responsable en el historial. No se cambia directamente el vencimiento de una obligación pagada.
- **Migración 32:** parche acotado del procedimiento vigente, con respaldo y rechazo si su definición no coincide con el patrón revisado. Preserva enlaces de Caja, Contabilidad y Finanzas con OperationKey. Excluye órdenes no recibidas de la deuda derivada, no cuenta movimientos anulados como pagos y conserva vencimientos existentes. No convierte el snapshot en un sistema completo de comandos transaccionales.

## Activación pendiente en SQL

La última comprobación detectó el marcador de la **migración 30 presente**. Las migraciones **31 y 32 siguen pendientes**. No se atribuye su aplicación a estas pruebas. La cuenta de la aplicación no puede alterar procedimientos. Un administrador debe revisar que la 30 coincida con el archivo actual y aplicar las pendientes en orden. Archivos de `Database/SQLServer_Completo/`:

1. `30_pagos_individuales_atomicos.sql`
2. `31_reglas_periodo_y_devengo_nomina.sql`
3. `32_conservar_enlaces_snapshot.sql`

Se parte de la instalación existente con 26–29. Hacer respaldo previo. No reconstruir la base ni ejecutar semilla. La API mantiene cálculo/aprobación y pagos de nómina pausados cuando faltan los marcadores necesarios. La gestión manual de Caja no necesita estos tres cambios nuevos de esquema.

Después de aplicar: actualizar la API y el navegador, comprobar login y ejecutar el recorrido autenticado de nómina. La validez legal de las reglas del catálogo necesita revisión competente; no se certificaron tasas ni obligaciones legales con estas pruebas técnicas.

## Matriz de comprobación

| Operación | Permiso | Efecto y prueba |
|---|---|---|
| Abrir Caja | Finanzas autorizado | Sesión y apertura únicas; reintento probado y revertido |
| Entrada/salida manual | Finanzas autorizado | Movimiento, saldo y control de fondos; probado y revertido |
| Arquear/cerrar | Superadministrador o administrador financiero | Esperado, contado y diferencia; cierre sin diferencia probado |
| Calcular nómina | Administrador autorizado | Cabecera/detalle y reglas del período; cuerpo SQL 31 probado, no desplegado |
| Aprobar devengo | Persona distinta de quien prepara/calcula | Neto y retenciones separados; cuerpo SQL 31 probado, no desplegado |
| Pagar nómina | Administrador de Finanzas/Contabilidad o superadministrador | Recibo, distribución, movimiento y cancelación de deuda; cuerpo SQL 30 probado, no desplegado |
| Conciliar | Administración autorizada | Rechazo de cabecera sin recibos probado; recorrido positivo completo pendiente |
| Recibir compra | Compras autorizado | Ya no simula egreso; recorrido comercial integral pendiente |

## Evidencia y límites

- Caja: 8 etapas de gestión comprobadas en SQL con el servicio y rollback.
- Resumen de Caja: 3 escenarios de fechas/aperturas sin escrituras.
- Pago: 8 casos SQL reversibles del cuerpo de la migración 30.
- Cálculo/devengo: 9 casos reversibles del cuerpo de la migración 31, con catálogo y obligaciones temporales. Incluyen rechazo de reglas no verificadas/fuera del período y de conciliación sin recibos.
- Parche de sincronización: pruebas de transformación, idempotencia, rechazo de versión diferente y conservación de vencimientos. No es una prueba de despliegue del procedimiento real.
- Pruebas locales de permisos, pagos, proveedores y parche de sincronización.
- Migraciones analizadas con PARSEONLY; no se instalaron mediante ese análisis.

Comandos:

```
node server/scripts/verify-cash-workflow-rollback.mjs
node server/scripts/verify-cash-summary-readonly.mjs
node server/scripts/verify-payment30-rollback.mjs
node server/scripts/verify-payroll31-rollback.mjs
node --test server/tests/authIntegrity.test.mjs server/tests/payrollPayments.test.mjs server/tests/payrollPermissions.test.mjs server/tests/supplierDirectory.test.mjs server/tests/snapshotLinkPatch.test.mjs
```

Los ensayos reversibles requieren fixtures disponibles y ninguna caja operativa abierta. No ejecutarlos mientras otras personas registran operaciones.

La comprobación final dejó constancia de una sesión de Caja abierta y ocho movimientos existentes. No se cerró ni se alteró esa sesión. TypeScript y la compilación de producción terminaron correctamente.

Quedan pendientes: instalación administrativa de 31–32, recorrido autenticado completo y concurrencia real entre dos conexiones, reversos coordinados, reparación histórica con documentos, sustitución integral del snapshot y recorridos completos de ventas/cobros/compras/pagos/PEPS. Las cuatro planillas históricas inconsistentes detectadas no se repararon por suposición. No se declara todo el sistema automatizado.
