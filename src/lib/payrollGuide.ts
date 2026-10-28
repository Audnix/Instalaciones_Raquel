type GuideInput = {
  status: string; calculationCurrent: boolean; workers: number;
  blocking: number; historyReady: boolean; totalsConsistent: boolean; paymentTotalsConsistent?: boolean; pending: number;
};
export const payrollPaymentSteps = ['Preparar trabajadores', 'Calcular', 'Revisar', 'Aprobar', 'Validar caja o banco', 'Registrar abono', 'Conciliar', 'Cerrar'];
export function payrollPaymentGuide(input: GuideInput) {
  const { status, calculationCurrent, workers, blocking, historyReady, totalsConsistent, pending } = input;
  if (['conciliada', 'cerrada'].includes(status)) {
    if (!historyReady || !totalsConsistent || input.paymentTotalsConsistent === false || pending > 0.009) return { step: 6, action: 'historial', label: 'Revisar inconsistencia', message: 'El estado avanzado no coincide con el respaldo de pagos. Revisa documentos antes de corregir o pagar.' };
    return { step: status === 'cerrada' ? 8 : 7, action: status === 'cerrada' ? 'historial' : 'aprobaciones', label: status === 'cerrada' ? 'Ver historial' : 'Revisar cierre', message: status === 'cerrada' ? 'Proceso cerrado. Conserva sus comprobantes.' : 'Pagos conciliados. Revisa los requisitos del cierre.' };
  }
  if (workers < 1) return { step: 0, action: 'trabajadores', label: 'Preparar trabajadores', message: 'Incluye a los trabajadores y revisa salarios, tiempo reconocido y novedades del período.' };
  if (!calculationCurrent) {
    if (['aprobada', 'pago_registrado'].includes(status)) return { step: 1, action: 'validaciones', label: 'Revisar cálculo invalidado', message: 'La aprobación ya no tiene un cálculo vigente. Requiere revisión autorizada; no se paga ni se recalcula por encima de una aprobación.' };
    return { step: 1, action: 'calcular', label: 'Calcular ahora', message: 'Calcula en el servidor. Se comprobarán reglas del período, deducciones y neto de cada persona.' };
  }
  if (blocking > 0) return { step: 2, action: 'validaciones', label: 'Resolver validaciones', message: 'Revisa los errores bloqueantes antes de continuar.' };
  if (!totalsConsistent) return { step: 2, action: 'diferencias', label: 'Revisar diferencias de cálculo', message: 'Los importes de cabecera y detalle no coinciden. Consulta la diferencia concreta antes de corregir o pagar.' };
  if (input.paymentTotalsConsistent === false) return { step: 4, action: 'diferencias', label: 'Revisar respaldo de pagos', message: 'El acumulado histórico no coincide con los recibos confirmados. Requiere comprobantes y revisión documental.' };
  if (status === 'calculada' || status === 'borrador') return { step: 2, action: 'revisar', label: 'Revisar cálculo', message: 'Comprueba las explicaciones individuales y los totales; después registra la revisión.' };
  if (status === 'revisada') return { step: 3, action: 'aprobaciones', label: 'Ir a aprobación', message: 'La persona autorizada debe aprobar. Quien preparó o calculó no puede autoaprobar su cálculo.' };
  if (!historyReady) return { step: 4, action: 'actualizar', label: 'Verificar pagos', message: 'Actualiza el historial antes de calcular el pendiente individual.' };
  if (pending <= 0.009) return { step: 6, action: 'aprobaciones', label: 'Revisar conciliación', message: 'El neto está cubierto. Contrasta los comprobantes con caja o banco antes de conciliar.' };
  return { step: 4, action: 'abono', label: status === 'pago_registrado' ? 'Registrar siguiente abono' : 'Preparar pago individual', message: 'Elige trabajador, importe, medio, fecha y referencia. El servidor comprobará pendiente, sesión abierta, moneda y fondos antes de confirmar.' };
}
