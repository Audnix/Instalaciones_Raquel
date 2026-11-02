type ApprovalRun = { preparedById?: string | null; calculatedById?: string | null };
type ApprovalUser = { id?: string; hierarchy?: string; areas?: string[] } | null;
export function payrollApprovalBlock(run: ApprovalRun | null, user: ApprovalUser): string | null {
  if (!run || !user?.id) return 'Actualiza la planilla y verifica tu sesión antes de aprobar.';
  if (run.preparedById === undefined || run.calculatedById === undefined) return 'Actualiza la conexión para verificar quién preparó y calculó la planilla antes de aprobar.';
  if (run.preparedById === user.id || run.calculatedById === user.id) return 'Esta cuenta preparó o calculó la planilla. Debe aprobarla otra persona: un superadministrador o un administrador de Finanzas o Contabilidad. Esa persona debe iniciar sesión con su propia cuenta y abrir este mismo período.';
  if (user.hierarchy !== 'superadmin' && !(user.hierarchy === 'administrador' && user.areas?.some(area => ['finanzas', 'contabilidad'].includes(area)))) return 'La aprobación requiere un superadministrador o un administrador de Finanzas o Contabilidad distinto de quien preparó o calculó la planilla.';
  return null;
}
