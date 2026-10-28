# Revisión funcional adicional — 21 de octubre de 2026

Esta entrega es parcial. No certifica los 21 apartados completos ni sustituye las correcciones previas. No se reconstruyó la base, no se ejecutaron semillas, no se cambiaron cuentas ni contraseñas y no se repararon históricos.

## Hallazgos verificados y correcciones de esta revisión

1. `erpStore.tsx` reaccionaba a HTTP 409/428 consultando solamente la revisión nueva y reenviando el snapshot antiguo. Así podía superar el control de concurrencia y reemplazar cambios ajenos. Se eliminó ese reintento. Ahora conserva los datos locales, detiene el guardado y muestra un conflicto que exige comparar los cambios. No hay combinación automática de operaciones financieras. Cargar el snapshot tampoco dispara por sí solo un guardado automático: se registra como base sincronizada y se espera un cambio local.
2. `state.js` leía la revisión del resultado en otra consulta después del guardado. Podía devolver la revisión de otro escritor. `stateSnapshot.js` ahora abre una transacción exterior, bloquea la fila o rango con UPDLOCK/HOLDLOCK, exige la revisión original, ejecuta el procedimiento, lee la revisión propia y confirma. Los fallos revierten la operación. Una respuesta sin confirmación y revisión válidas se considera incierta en el navegador.
3. El snapshot completo estaba disponible para cualquier sesión y su escritura para administradores de cualquier área. Se restringieron ambos accesos a superadministración, conforme al alcance global de los datos y al diseño documentado en Database/SQLServer_Completo/README.md. Se exige cambiar la contraseña temporal antes de escribir. Esto limita deliberadamente el acceso al endpoint global; los servicios específicos mantienen sus políticas existentes. Falta sustituir el snapshot para módulos que aún dependen de él.
4. `payPayroll` habilitaba un pago local justamente cuando SQL dejaba de estar conectado. Calculaba desde reglas del navegador y creaba nómina, salida, asiento y movimiento financiero sin aprobación del servidor. Se retiró esa vía de escritura; el pago se dirige a Nómina → Pagos. La vista heredada se identifica como simulación y ya no ofrece el botón de pagar sin conexión. `addCash` tampoco permite crear un movimiento financiero local. No se eliminaron datos locales anteriores.
5. La compilación detectó dos declaraciones idénticas de `canRegister` en Caja. Se conservó una sola.

## Estado actual de SQL Server

Evidencia reproducible: `server/scripts/audit-integrity-readonly.mjs`, consulta `docs/30_auditoria_integridad_solo_lectura.sql`, resultado `docs/auditoria_integridad_actual.json` (fecha UTC dentro del archivo).

- 6 planillas, 114 detalles, 0 recibos PayrollPayments, 6 movimientos y 0 sesiones de caja al consultar.
- El marcador de migración 30 existe. El trigger visible `tr_PayrollCashMoveIntegrity` está habilitado. La mera presencia del marcador no certifica todo el procedimiento ni su comportamiento concurrente.
- El marcador de migración 31 no existe. La cuenta conectada tiene `CREATE PROCEDURE = 0`. No se intentó reconstruir ni ampliar sus privilegios.
- Cuatro planillas requieren revisión documental. Tres tienen diferencias entre deducciones de cabecera y detalle; cuatro tienen estados avanzados sin respaldo completo en PayrollPayments. El reporte contiene identificadores e importes. Ausencia de recibos en esta tabla no demuestra por sí sola ausencia de pagos bancarios históricos.
- Las consultas de pagos sin salida, claves repetidas, movimientos de nómina sin recibo y asientos con débitos distintos a créditos devolvieron cero filas. Esto solo cubre esos predicados, no prueba corrección contable general ni inexistencia de otros duplicados.

## Matriz de responsabilidad y trazabilidad

| Operación | Permiso vigente o requerido | Documento origen | Movimiento | Asiento | Saldo | Prueba y situación |
|---|---|---|---|---|---|---|
| Apertura | Finanzas estándar o administración autorizada | Sesión de caja | Apertura identificada | Revisar contrapartida según origen del fondo | Base separada de ventas | `cash.js` → `cashTransaction.js` → `usp_AbrirCaja` → CashSessions/CashMoves; recorrido HTTP pendiente |
| Entrada/salida | Finanzas estándar o administración autorizada | Referencia del movimiento | CashMoves con OperationKey | Validar clasificación y documento | Caja anterior + entrada − salida | `usp_RegistrarMovimientoCaja`; consulta de resumen SQL pasó con datos sintéticos |
| Arqueo/cierre | Supervisión de Finanzas/Contabilidad | Sesión y conteo | Diferencias sujetas a revisión | No descontar trabajador automáticamente | Esperado frente a contado | Procedimientos de caja existentes; recorrido completo no ejecutado aquí |
| Calcular nómina | Administración RRHH/Finanzas/Contabilidad | Planilla y novedades | Ningún pago | Devengo posterior a aprobación | Bruto − deducciones laborales | `PayrollWorkspace` → POST calculate → `usp_CalculatePayroll` → PayrollRuns/PayrollRunItems/validaciones; falta migración 31 |
| Revisar/aprobar | Administración autorizada y separación SQL | Versión calculada | No confirma desembolso | Devengo separado en migración 31 | Neto aprobado y pasivos | POST transition → `usp_TransitionPayrollStatus`; prueba SQL agotó tiempo |
| Pagar nómina | Superadmin o administrador Finanzas/Contabilidad | Planilla aprobada y trabajador/distribución | PayrollPayments/Allocations y CashMoves | Cancelar sueldos por pagar, no repetir gasto | Neto aprobado − pagos confirmados | POST payments → `usp_RegisterPayrollPayment`; migración 30 visible; concurrencia HTTP y dos sesiones pendientes |
| Venta/consumo PEPS | Ventas; falta control servidor por acción | Venta o conversión de proforma | Kardex/lotes y cobro generados por store | El store usa Caja/Ventas sin distinguir crédito | Solo control local de existencias | `addSale`/`convertProforma` → PUT state → `usp_SaveErpState`; falta servicio de negocio y pruebas simultáneas |
| Compra/recepción/pago parcial | Compras y Finanzas separados, pendiente de implementación integral | Orden, recepción, factura, obligación | El modelo y store heredados no prueban el ciclo completo | Falta separar reconocimiento y pago | Pendiente documental | `addPurchase` → snapshot; no validado como flujo integral |
| Guardado global | Solo superadministración, contraseña definitiva | Snapshot y revisión original | No constituye documento de negocio | Sigue siendo ruta heredada | No usar como libro financiero | GET/PUT state → `saveStateSnapshot` → `usp_SaveErpState` → ErpState y tablas sincronizadas; 6 pruebas locales nuevas |
| Reversos y reparación | Autorización específica, respaldo y revisión documental | Operación válida y evidencia de duplicación | Movimientos vinculados | Reverso o ajuste autorizado | Conciliar todos los efectos | Sin correcciones operativas en esta entrega |

La matriz diferencia lo existente de lo requerido. No atribuye a botones ni a rutas sin montar un flujo de producción demostrado. La ruta histórica `routes/erp.js` no se monta en el servidor actual y no se usó como evidencia de una API activa.

## Validación realizada en esta revisión

- `node --test server/tests/*.test.mjs`: **22 pruebas aprobadas**. Incluye 6 nuevas de snapshot: revisión bajo transacción, conflicto sin escribir, revisión obligatoria, reversión por fallo, estado eliminado y permisos globales/contraseña. Se usan dobles de SQL; no demuestran concurrencia física de SQL Server.
- `npm run build`: **correcto** tras retirar la declaración duplicada. Vite advierte tamaños de algunos paquetes; no bloquea la compilación.
- `node server/scripts/verify-cash-summary-readonly.mjs`: **3 escenarios SQL aprobados**, solo consultas sobre valores sintéticos. 1000 + 500 − 200 = 1300; reapertura y salida posteriores = 1200; período combinado sin sumar dos veces la apertura.
- Auditoría SQL: ejecutada y guardada. Se repitió después del timeout: se conservaron los mismos conteos y los cuatro hallazgos. No aplicó reparaciones.
- `node server/scripts/verify-payroll31-rollback.mjs`: **no aprobado**; terminó con ETIMEOUT, límite de solicitud 15000 ms, sin emitir escenarios PASS en esta ejecución. El script solicita rollback en finally y cierra la conexión. No se interpreta como validación del cálculo ni como despliegue de la migración.
- No se realizaron recorridos de navegador autenticado, comprobaciones después de reiniciar, dos usuarios simultáneos, respuesta bancaria externa, pérdida de respuesta ni los ciclos completos de proveedor y ventas. No se adjuntan capturas que simulen evidencia.

## Migraciones, datos y trabajo pendiente

Los cambios nuevos de esta revisión no requieren una migración adicional. Para habilitar el cálculo/devengo corregido preparado previamente se necesita revisar y aplicar **31_reglas_periodo_y_devengo_nomina.sql** con una cuenta autorizada y respaldo previo. La versión 30 ya es visible; no se propone reinstalarla a ciegas ni usar db:install/db:rebuild como actualización. Verificar marcadores, definiciones, permisos y pruebas después del despliegue. No se verificó vigencia normativa externa; no se cambiaron tasas ni se certificó cumplimiento legal.

El procedimiento de snapshot en los archivos de migración todavía elimina/reinserta varias tablas heredadas y protege ciertos efectos solo por OperationKey. La corrección de concurrencia no transforma ese procedimiento en servicios de negocio ni certifica protección completa de históricos. Ventas, inventario y compras requieren esa sustitución y un modelo de obligaciones/pagos/documentos antes de aprobar el sistema integral.

También siguen pendientes cuentas bancarias individuales y fondos en tránsito, múltiples cajas/monedas con conversiones documentadas, reversos coordinados, catálogo/períodos contables, pagos parciales de proveedor y la matriz detallada de autorización por transición y alcance.

Para los cuatro cortes, `src/data/requirements.ts`, `src/data/umlSchema.ts`, `docs/estado-y-trazabilidad.md` y `docs/mapa-evidencia.md` son las referencias existentes. Esta matriz aporta la relación implementación/prueba; falta contrastar cada requisito y UML con los recorridos completos. No se marca ningún corte como aceptado solo por compilar.

La reparación histórica debe partir del JSON de inconsistencias, documentos y referencias bancarias. Requiere respaldo verificado, decisión sobre la operación válida y reversos/ajustes con auditoría. No borrar por similitud de importe o fecha, ni convertir estados antiguos en pagos ficticios.

## Corrección a partir de capturas: Caja y estados de consulta

- La consulta real de GET /api/cash/movements usaba `v.Salida AS exit`. SQL Server rechazaba el alias reservado y la pantalla entraba en modo local. Se delimitó como `[exit]`, conservando el campo de respuesta. La consulta se comparte ahora entre API y prueba SQL; no basta probar solamente el resumen.
- `verify-cash-movements-readonly.mjs`: cuatro consultas reales aprobadas, Caja y Banco con/sin período. Sin escrituras. Resultados: Caja 2/2 filas; Banco 4/1 filas.
- Caja distingue consulta no confirmada de desconexión y permite pulsar Actualizar después de un error; antes el botón quedaba deshabilitado cuando más se necesitaba.
- El indicador superior explica la sincronización global, no el estado de todas las consultas del sistema. RRHH confirma únicamente su propia carga y deja de mostrar verde ante errores. Consultar datos tampoco se presenta como prueba de que se guardó una operación.
- El proveedor global se montaba antes del inicio de sesión y no volvía a consultar al entrar. La sesión ahora notifica sus cambios y la carga global se repite al iniciar, cambiar de cuenta o cerrar sesión. Se conserva la restricción de superadministración; no se amplían permisos.
- Suite local actual: 26 pruebas aprobadas, incluida la notificación de inicio/cambio/cierre con estado de sesión ya actualizado. Compilación Vite aprobada. No se ejecutó una sesión visual autenticada ni se reinició un proceso de API ajeno. Para un proceso sin watch, reiniciar la API para cargar la consulta corregida y actualizar la página.

## Pago individual en abonos

Se cambió la entrada principal de Nómina → Pagos para registrar una persona por operación. Ya no precarga el pendiente de toda la planilla ni el neto completo individual: exige escoger trabajador e ingresar el importe. El selector y el envío de esta pantalla requieren un trabajador perteneciente a la planilla. El servicio SQL existente conserva su validación del neto aprobado pendiente, pagos parciales, asignación e idempotencia.

Personal tiene el acceso Pagos / abonos hacia Nómina con el trabajador como contexto. Elegir la planilla sigue siendo necesario; el acceso no aprueba cálculos ni registra dinero automáticamente. La tabla muestra neto, abonos confirmados y pendiente individual; sin historial cargado no presenta cero como confirmación. El formulario muestra el pendiente esperado después del abono y permite completar el saldo en otra operación.

Prueba local añadida: netos distintos (9500 y 7200), abonos intercalados y cancelación del pendiente de uno conservando el del otro. Las cuatro pruebas de payrollPayments pasan. TypeScript aprobado. No se registraron pagos reales durante la corrección.

## Configuración aplicada en Nómina

Nómina abre directamente en Pagos por trabajador y muestra la tabla de neto, abonos y pendiente antes del historial. Para planillas no aprobadas se muestra el estado actual y un acceso a revisión/aprobación; no se confirma dinero automáticamente.

Se diagnosticó el procedimiento de lectura instalado: devolvía employeesCount pero no workersCount, ni varias fechas/costos esperados por la pantalla. Existían detalles; el contador cero era un incumplimiento del contrato API. La API ahora consulta una proyección explícita compartida en server/src/services/payrollReadSql.js, comprobada con SQL real, sin alterar ese procedimiento antiguo ni inventar fechas.

La cuenta de aplicación no tiene CREATE PROCEDURE. En esta revisión se comprobó que la cuenta integrada de Windows sí tiene permisos administrativos. Se creó un respaldo COPY_ONLY con CHECKSUM y se ejecutó RESTORE VERIFYONLY correctamente. Evidencia: backup_before_payroll_configuration.sql y backup_before_payroll_configuration_result.txt. Archivo de respaldo:
C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER2025\MSSQL\Backup\Raquel_before_payroll_0A18799AA98441A1BB65BBA6F94E37A7.bak

Se aplicaron 31_reglas_periodo_y_devengo_nomina.sql y 32_conservar_enlaces_snapshot.sql dentro de una transacción exterior. El primer intento se revirtió por completo: SQL Server almacena el encabezado como CREATE   PROCEDURE y el parche 32 intentó crear un objeto existente. Se corrigió el reconocimiento limitado al encabezado conocido, conservando el cuerpo y rechazando formatos inesperados. El segundo despliegue confirmó los dos marcadores y los mismos conteos de negocio: 6 planillas, 114 detalles, 0 pagos y 9 movimientos. No se recalcularon ni aprobaron planillas ni se registraron pagos. La migración agrega una cuenta contable requerida y ajusta estructura/procedimientos; no es una certificación de vigencia normativa de las reglas cargadas.

El diagnóstico posterior, usando la conexión de aplicación, confirmó los marcadores 30/31/32 y la consulta de cabeceras y detalles. La suite local ejecutada pasó 31 pruebas. No se realizaron pagos reales ni el recorrido visual autenticado. Las diferencias históricas documentadas anteriormente no se repararon mediante estas migraciones.

## Regularización de TEST-DYN-7929 por confirmación de no pago

El usuario confirmó expresamente: “No se pagó”. La consulta de solo lectura encontró la planilla run-mvfbxste-d83c30 en conciliada, neto 171424.85, cabecera pagada 50000, cero recibos confirmados y 21 trabajadores. Tampoco existían asientos, movimientos de caja ni movimientos financieros vinculados. No se dedujo ausencia de pago exclusivamente de la base: se utilizó la confirmación del usuario.

Se generó y verificó un nuevo respaldo COPY_ONLY antes de corregir (backup_before_unpaid_payroll_repair_result.txt). Se ejecutó docs/repair_unpaid_TEST-DYN-7929.sql con transacción, bloqueos y comprobaciones que abortan si aparecen pagos, asientos, movimientos u obligaciones institucionales con indicios de pago. Se registró el estado anterior completo (cabecera, detalles y obligaciones) en dbo.PayrollIntegrityRepairs, clave unpaid-TEST-DYN-7929-20261021, junto con la razón y ORIGINAL_LOGIN(). También se insertó un evento de historial; no se suplantó una sesión de usuario. Repetir la misma corrección no la aplica dos veces.

La primera ejecución se revirtió: el esquema antiguo tenía PaidAt NOT NULL. Se incorporó, dentro de la misma transacción, la relajación limitada a DATETIMEOFFSET(3) NULL prevista en la migración 29, comprobando el tipo antes de alterar. La ejecución final confirmó: estado borrador, ConfirmedPaymentsTotal=0 y CalculationStale=1. Se invalidaron la revisión, aprobación y conciliación antiguas y las marcas de pago/colilla, conservando el snapshot anterior. Se conservaron importes históricos de cálculo y los 21 trabajadores para que se recalculen mediante el servicio; no se inventó un nuevo neto ni se generó dinero. Las obligaciones institucionales se conservaron.

Verificación posterior de solo lectura: estado borrador, acumulado 0, recibos 0 y trabajadores 21 (docs/payroll_TEST-DYN-7929_readonly.json). El siguiente paso operativo es recalcular, revisar y aprobar con los responsables autorizados; después registrar los abonos individuales. No se omite ese flujo ni se autoriza automáticamente el pago.

La lectura de la API distingue desde ahora recordedPaymentsTotal (acumulado de cabecera) y confirmedPaymentsTotal (suma de recibos confirmados). El pendiente se calcula con recibos y las diferencias se muestran explícitamente, sin borrar automáticamente otras cabeceras históricas. La interfaz bloquea el cierre anticipadamente cuando faltan pagos o hay diferencias. El acceso de pago en cabecera abre el formulario individual, en vez de intentar una mera transición de estado como si fuera un pago.

## Guía y comprobación automática previa al pago

Se agregó docs/guia_pago_trabajador.md y una guía de ocho pasos en Nómina → Pagos por trabajador. La siguiente acción deriva del estado real; cálculo, revisión, aprobación y registro no se confunden en un solo botón. El preparador no recibe permisos adicionales. Para la planilla actual la siguiente acción es calcular; no se recalculó ni aprobó automáticamente en esta entrega.

POST /api/payroll/runs/:id/payment-check usa autenticación, autorización financiera y marcadores de integridad, y ejecuta solo lecturas. Comprueba estado aprobado, cálculo vigente, coherencia de cabecera y detalles, validaciones, asignación de pagos anteriores, trabajador, pendiente, sesión por fecha, moneda y fondos. No reserva saldo; el procedimiento transaccional sigue siendo la validación final bajo concurrencia. Si la clave ya existe, se permite llegar al procedimiento autoritativo para recuperar la misma operación o rechazar contenido diferente. La interfaz no interpreta una consulta previa como pago realizado, limpia la comprobación si cambia el formulario y repite la comprobación antes de enviar el pago.

Pruebas añadidas: progresión de la guía y bloqueo por estados inconsistentes; abono individual; exceso, fondos insuficientes, moneda, sesión y fecha; cálculo desactualizado, sumas falsas, detalles inválidos, falta de distribución, trabajador ajeno y recuperación de clave. La suite ejecutada pasó 38 pruebas. La consulta real de solo lectura devolvió ready=false para la planilla en borrador; no creó recibos. La confirmación del pago requiere identificador y queda visible aunque falle una consulta posterior. No se hicieron pagos reales ni se certificó vigencia normativa externa.
