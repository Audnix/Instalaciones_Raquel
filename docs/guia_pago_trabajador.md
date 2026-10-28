# Guía para pagar a un trabajador

Entra en **Nómina → Pagos por trabajador** y selecciona el período correcto. El bloque **Guía para pagar a un trabajador** identifica el paso actual y ofrece la siguiente acción. No cambies de planilla para eludir un bloqueo: revisa su causa.

1. **Preparar trabajadores.** Comprueba quiénes pertenecen al período, salario, jornada, tiempo reconocido y novedades. Las personas pueden tener salarios y netos diferentes. No se reparte automáticamente una suma igual a todos.
2. **Calcular.** Pulsa **Calcular ahora**. El servidor calcula con las reglas verificadas del período. Si faltan reglas o datos, corrige lo indicado en Validaciones. Un cálculo viejo o desactualizado no autoriza pagos.
3. **Revisar.** Consulta las explicaciones por trabajador, deducciones, netos y totales. Registra la revisión solo después de comprobarlos.
4. **Aprobar.** La persona autorizada aprueba en Aprobaciones. Se conserva la separación de responsables; no se aprueba automáticamente al calcular.
5. **Preparar el abono.** Abre **Registrar abono** en la fila de la persona. Escribe el importe a pagar ahora, el medio, fecha y referencia. Debe existir una sesión de Caja para efectivo o de Banco para los medios bancarios, en córdobas y para la fecha correspondiente. Apertura y fondos se gestionan en Caja/Bancos; la guía no inventa un saldo ni abre cuentas por sí sola.
6. **Validar y registrar.** Pulsa **Validar requisitos** para consultar el resultado por condición. Al confirmar se ejecuta esa comprobación nuevamente y el procedimiento SQL valida bajo bloqueo antes de guardar. Se comprueban aprobación, cálculo vigente, coherencia de importes, errores bloqueantes, distribución de pagos previos, trabajador, pendiente individual, sesión, moneda y fondos. Los importes no pueden superar lo pendiente. La consulta previa no reserva fondos ni prueba la ejecución de una transferencia bancaria externa.
7. **Comprobar resultado.** Después de la confirmación conserva el identificador y revisa el historial, el movimiento y el nuevo pendiente. Puedes registrar otro abono más adelante. No vuelvas a descontar deducciones del neto. Un reintento conserva la clave de la operación; si la respuesta es incierta, no inventes una referencia nueva para repetir el mismo pago. Generar una colilla tampoco equivale a confirmar un pago.
8. **Conciliar y cerrar.** Contrasta los pagos con sus comprobantes y Caja/Banco. La conciliación y el cierre requieren sus permisos y la cobertura del neto correspondiente. Un estado histórico inconsistente requiere revisión documental; no se borra ni se fuerza el cierre.

## Situación de la captura

La planilla está en borrador con cálculo desactualizado, después de regularizar un acumulado que el usuario confirmó como no pagado. El siguiente paso es **Calcular ahora**, seguido de revisión y aprobación. No corresponde registrar el pago ni cerrar todavía.

## Qué se automatizó y qué se validó

La interfaz deriva el paso siguiente del estado, vigencia, trabajadores, validaciones e historial. El formulario tiene comprobación previa de solo lectura en POST /api/payroll/runs/:id/payment-check. Al confirmar se vuelve a comprobar y se usa el procedimiento transaccional de pago existente. La respuesta debe contener un identificador de pago; se distingue la confirmación del pago de la recarga posterior del historial. El formulario permite desplazamiento en pantallas pequeñas.

Las aprobaciones, la entrega real de efectivo y la confirmación bancaria externa siguen requiriendo acciones de responsables autorizados. La API no envía dinero al banco.

Validación de esta entrega: 38 pruebas locales aprobadas; prueba de solo lectura contra SQL Server sobre la planilla actual: trabajador, sesión, moneda y fondos disponibles, pero aprobación/cálculo/totales aún no habilitados. Resultado ready=false, cero recibos creados. Es la respuesta esperada; no se presenta como un pago realizado. No se ejecutó un pago real ni un recorrido visual autenticado completo.
