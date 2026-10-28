export function canManagePayrollMoney(user) {
  return user?.hierarchy === 'superadmin' || (user?.hierarchy === 'administrador'
    && user.areas?.some((area) => ['finanzas','contabilidad'].includes(area))) || false;
}

export function requiresPayrollFinancialPermission(targetStatus) {
  return ['aprobada','pago_registrado','conciliada','cerrada'].includes(targetStatus);
}
