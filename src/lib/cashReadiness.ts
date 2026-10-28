export function cashSessionBlock(sessionDate: string | undefined, businessDate: string | null): string | null {
  if (!sessionDate) return 'Abre una sesión con el saldo inicial contado antes de registrar movimientos.';
  if (!businessDate) return 'Actualiza la consulta para confirmar la fecha operativa del servidor.';
  if (sessionDate.slice(0, 10) !== businessDate) return `La sesión abierta es del ${sessionDate.slice(0, 10)} y hoy es ${businessDate}. Realiza el arqueo y cierre de esa sesión; después abre la del día con el saldo contado.`;
  return null;
}

export function explicitCashCount(value: string): number | null {
  if (!value.trim()) return null;
  const amount = Number(value);
  return Number.isFinite(amount) && amount >= 0 && Math.abs(amount * 100 - Math.round(amount * 100)) < 0.000001 ? amount : null;
}
