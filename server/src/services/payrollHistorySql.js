export const PAYROLL_PAYMENTS_SQL = `
 SELECT p.PaymentId AS id,p.PayrollRunId AS payrollRunId,p.EmployeeId AS employeeId,p.Amount AS amount,
 p.PaymentMethod AS paymentMethod,p.TransactionReference AS paymentReference,p.PaymentDate AS paymentDate,
 p.ConfirmedAt AS confirmedAt,p.ConfirmedByName AS confirmedByName,p.Notes AS notes,p.CashMoveId AS cashMoveId,
 p.IdempotencyKey AS idempotencyKey,p.CalculationVersion AS calculationVersion,r.Period AS period,
 (SELECT a.EmployeeId AS employeeId,a.Amount AS amount,
   CASE WHEN p.CalculationVersion=r.CalculationVersion THEN i.OrdinarySalary END AS ordinarySalary,
   CASE WHEN p.CalculationVersion=r.CalculationVersion THEN i.BonusesAmount END AS bonusesAmount,
   CASE WHEN p.CalculationVersion=r.CalculationVersion THEN i.InssLaboral END AS inssLaboral,
   CASE WHEN p.CalculationVersion=r.CalculationVersion THEN i.IncomeTax END AS incomeTax,
   CASE WHEN p.CalculationVersion=r.CalculationVersion THEN i.OtherDeductions END AS otherDeductions,
   CASE WHEN p.CalculationVersion=r.CalculationVersion THEN i.Net END AS netPay
  FROM dbo.PayrollPaymentAllocations a
  LEFT JOIN dbo.PayrollRunItems i ON i.PayrollRunId=p.PayrollRunId AND i.EmployeeId=a.EmployeeId
  WHERE a.PaymentId=p.PaymentId FOR JSON PATH) AS allocationsJson
 FROM dbo.PayrollPayments p JOIN dbo.PayrollRuns r ON r.PayrollRunId=p.PayrollRunId
 WHERE p.PayrollRunId=@PayrollRunId AND p.Status=N'confirmado'
 ORDER BY p.ConfirmedAt DESC,p.PaymentId;`;
