# Guía para pagar a un trabajador

Entra en **Nómina → Pagos por trabajador** y selecciona el período correcto. El bloque **Guía para pagar a un trabajador** identifica el paso actual y ofrece la siguiente acción. No cambies de planilla para eludir un bloqueo: revisa su causa.

1. **Preparar trabajadores.** Comprueba quiénes pertenecen al período, salario, jornada, tiempo reconocido y novedades. Las personas pueden tener salarios y netos diferentes. No se reparte automáticamente una suma igual a todos.
2. **Calcular.** Pulsa **Calcular ahora**. El servidor calcula con las reglas verificadas del período. Si faltan reglas o datos, corrige lo indicado en Validaciones. Un cálculo viejo o desactualizado no autoriza pagos.
3. **Revisar.** Consulta las explicaciones por trabajador, deducciones, netos y totales. Registra la revisión solo después de comprobarlos.
4. **Aprobar.** La persona autorizada aprueba en Aprobaciones. Se conserva la separación de responsables; no se aprueba automáticamente al calcular.
5. **Preparar el abono.** Pulsa **Pagar a este trabajador** en su fila o **Elegir trabajador y preparar pago**. También puedes seleccionarlo en el formulario visible. El sistema propone el pendiente individual verificado: puedes conservarlo para completar el saldo o reducirlo para un abono. Completa el medio, fecha y referencia. Debe existir una sesión de Caja para efectivo o de Banco para los medios bancarios, en córdobas y para la fecha correspondiente. Apertura y fondos se gestionan en Caja/Bancos; la guía no inventa un saldo ni abre cuentas por sí sola.
6. **Validar y registrar.** Pulsa **Validar requisitos** para consultar el resultado por condición. Al confirmar se ejecuta esa comprobación nuevamente y el procedimiento SQL valida bajo bloqueo antes de guardar. Se comprueban aprobación, cálculo vigente, coherencia de importes, errores bloqueantes, distribución de pagos previos, trabajador, pendiente individual, sesión, moneda y fondos. Los importes no pueden superar lo pendiente. La consulta previa no reserva fondos ni prueba la ejecución de una transferencia bancaria externa.
7. **Comprobar resultado.** Después de la confirmación conserva el identificador y revisa el historial, el movimiento y el nuevo pendiente. Puedes registrar otro abono más adelante. No vuelvas a descontar deducciones del neto. Un reintento conserva la clave de la operación; si la respuesta es incierta, no inventes una referencia nueva para repetir el mismo pago. Generar una colilla tampoco equivale a confirmar un pago.
8. **Conciliar y cerrar.** Contrasta los pagos con sus comprobantes y Caja/Banco. La conciliación y el cierre requieren sus permisos y la cobertura del neto correspondiente. Un estado histórico inconsistente requiere revisión documental; no se borra ni se fuerza el cierre.

## Planilla revisada: por qué no permite aprobar

Si aparece «Separación de funciones requerida», quien inició sesión preparó o calculó esa misma planilla. La migración 31 exige otra persona incluso para superadministradores. No se corrige devolviendo la planilla a borrador ni creando otra cuenta con la misma identidad.

1. Conserva el período seleccionado y verifica sus importes.
2. Otra persona autorizada debe iniciar sesión con su propia cuenta: superadministrador o administrador de Finanzas o Contabilidad.
3. Esa persona abre el mismo período y pulsa **Aprobar planilla revisada**.
4. En **Pagos por trabajador**, actualiza la consulta. Usa **Elegir trabajador y preparar pago**, el selector del formulario o **Pagar a este trabajador** en la lista.
5. El importe se propone desde el pendiente verificado de esa persona. Puedes reducirlo para registrar un abono. Completa medio, fecha y referencia real, valida y confirma.

El botón para preparar un pago permanece visible antes de la aprobación; la confirmación solo se habilita cuando se cumplen los requisitos. Una referencia de transferencia o un comprobante debe corresponder al desembolso real.

## Qué se automatizó y qué se validó

La interfaz deriva el paso siguiente del estado, vigencia, trabajadores, validaciones e historial. El formulario tiene comprobación previa de solo lectura en POST /api/payroll/runs/:id/payment-check. Al confirmar se vuelve a comprobar y se usa el procedimiento transaccional de pago existente. La respuesta debe contener un identificador de pago; se distingue la confirmación del pago de la recarga posterior del historial. El formulario permite desplazamiento en pantallas pequeñas.

Las aprobaciones, la entrega real de efectivo y la confirmación bancaria externa siguen requiriendo acciones de responsables autorizados. La API no envía dinero al banco.

Comprobación de esta actualización: 17 pruebas de aprobación, permisos, abonos y flujo aprobadas, junto con la comprobación de TypeScript. No se ejecutó un pago real ni se alteró el estado de la planilla desde esta tarea.
