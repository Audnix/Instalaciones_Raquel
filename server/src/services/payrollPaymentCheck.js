import sql from 'mssql';

export function evaluatePaymentCheck({ run, worker, session, blocking = 0 }, data) {
  const pending = Math.round((Number(worker?.net ?? 0) - Number(worker?.paid ?? 0)) * 100) / 100;
  const date = value => value instanceof Date ? value.toISOString().slice(0, 10) : String(value ?? '').slice(0, 10);
  const checks = [
    ['approved', 'Planilla aprobada para pagar', ['aprobada', 'pago_registrado'].includes(run?.status)],
    ['calculation', 'Cálculo confirmado y vigente', Boolean(run?.calculatedAt) && Number(run?.version) > 0 && !run?.stale],
    ['totals', 'Totales de la planilla coherentes', Boolean(run) && Number(run.invalidItems ?? 0) === 0 && Math.abs(Number(run.net) - Number(run.itemNet)) < 0.01
      && Math.abs(Number(run.deductions) - Number(run.itemDeductions)) < 0.01
      && Math.abs(Number(run.gross) - Number(run.deductions) - Number(run.net)) < 0.01
      && Math.abs(Number(run.headerPaid) - Number(run.actualPaid)) < 0.01],
    ['validations', 'Sin validaciones bloqueantes', Number(blocking) === 0],
    ['allocations', 'Pagos anteriores distribuidos por trabajador', Number(run?.unallocatedPayments ?? 0) === 0],
    ['worker', 'Trabajador incluido en la planilla', Boolean(worker)],
    ['pending', 'Importe dentro del pendiente individual', Number.isFinite(data.amount) && data.amount > 0 && data.amount <= pending + 0.000001],
    ['session', 'Sesión de caja o banco abierta para la fecha del pago', Boolean(session) && date(session.date) === data.paymentDate],
    ['currency', 'Cuenta en córdobas', Boolean(session) && ['C$', 'NIO'].includes(session.currency)],
    ['funds', 'Fondos suficientes en la sesión', Boolean(session) && Number(session.available) >= data.amount]
  ].map(([code, label, ok]) => ({ code, label, ok }));
  return { ready: checks.every(check => check.ok), checks, pending, available: session ? Number(session.available) : null };
}

// Solo lectura. El procedimiento de pago vuelve a validar bajo bloqueo.
export async function checkPayrollPayment(pool, runId, data) {
  const account = ['efectivo', 'caja'].includes(data.paymentMethod) ? 'caja' : 'banco';
  const existing = await pool.request().input('Key', sql.UniqueIdentifier, data.mutationId)
    .query('SELECT PaymentId FROM dbo.PayrollPayments WHERE IdempotencyKey=@Key');
  // No impedir recuperar una operación confirmada cuya respuesta se perdió.
  // El POST autoritativo compara el contenido y rechaza la reutilización distinta.
  if (existing.recordset.length) return { ready: true, retryExisting: true, checks: [], account };
  const result = await pool.request().input('Run', sql.NVarChar(100), runId)
    .input('Employee', sql.NVarChar(100), data.employeeId).input('Account', sql.NVarChar(30), account).query(`
    SELECT r.Status AS status,r.CalculatedAt AS calculatedAt,r.CalculationVersion AS version,r.CalculationStale AS stale,
      r.Gross AS gross,r.TotalDeductions AS deductions,r.Net AS net,r.ConfirmedPaymentsTotal AS headerPaid,
      (SELECT ISNULL(SUM(Net),0) FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run) AS itemNet,
      (SELECT ISNULL(SUM(TotalDeductions),0) FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run) AS itemDeductions,
      (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run AND (Net<0 OR ABS(Gross-TotalDeductions-Net)>0.01)) AS invalidItems,
      (SELECT ISNULL(SUM(Amount),0) FROM dbo.PayrollPayments WHERE PayrollRunId=@Run AND Status=N'confirmado') AS actualPaid,
      (SELECT COUNT(*) FROM dbo.PayrollPayments p WHERE p.PayrollRunId=@Run AND p.Status=N'confirmado'
        AND p.Amount<>(SELECT ISNULL(SUM(a.Amount),0) FROM dbo.PayrollPaymentAllocations a WHERE a.PaymentId=p.PaymentId)) AS unallocatedPayments
    FROM dbo.PayrollRuns r WHERE r.PayrollRunId=@Run;
    SELECT i.Net AS net,(SELECT ISNULL(SUM(a.Amount),0) FROM dbo.PayrollPaymentAllocations a
      JOIN dbo.PayrollPayments p ON p.PaymentId=a.PaymentId WHERE p.PayrollRunId=@Run AND p.Status=N'confirmado' AND a.EmployeeId=@Employee) AS paid
    FROM dbo.PayrollRunItems i WHERE i.PayrollRunId=@Run AND i.EmployeeId=@Employee;
    SELECT s.SessionDate AS date,s.Currency AS currency,s.OpeningBalance+
      ISNULL((SELECT SUM(CASE WHEN MoveType=N'entrada' THEN Amount ELSE -Amount END) FROM dbo.CashMoves
        WHERE SessionId=s.CashSessionId AND MoveState=N'confirmado' AND ISNULL(DocumentType,N'')<>N'apertura'),0) AS available
    FROM dbo.CashSessions s WHERE s.Account=@Account AND s.Status=N'abierta';
    SELECT COUNT(*) AS blocking FROM dbo.PayrollValidations WHERE PayrollRunId=@Run AND Severity=N'bloqueante' AND IsResolved=0;
  `);
  return { ...evaluatePaymentCheck({ run: result.recordsets[0][0], worker: result.recordsets[1][0], session: result.recordsets[2][0],
    blocking: result.recordsets[3][0].blocking }, data), account, retryExisting: false };
}
