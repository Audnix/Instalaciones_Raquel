USE [Instalaciones Raquel];
GO
SET NOCOUNT ON;
-- SOLO CONSULTA. No corrige importes ni borra historicos.
SELECT r.PayrollRunId, r.Status, r.TotalDeductions AS HeaderDeductions,
       i.Deductions AS ItemDeductions, r.Net AS HeaderNet, i.Net AS ItemNet,
       r.ConfirmedPaymentsTotal, p.Paid AS ActualConfirmedPayments,
       CASE WHEN r.Status IN(N'pago_registrado',N'conciliada',N'cerrada') AND p.Paid<r.Net
            THEN N'Estado avanzado sin respaldo completo de pagos' ELSE N'Revisar diferencias' END AS Finding
FROM dbo.PayrollRuns r
OUTER APPLY(SELECT SUM(TotalDeductions) AS Deductions,SUM(Net) AS Net FROM dbo.PayrollRunItems WHERE PayrollRunId=r.PayrollRunId) i
OUTER APPLY(SELECT ISNULL(SUM(Amount),0) AS Paid FROM dbo.PayrollPayments WHERE PayrollRunId=r.PayrollRunId AND Status=N'confirmado') p
WHERE ABS(r.TotalDeductions-ISNULL(i.Deductions,0))>0.01 OR ABS(r.Net-ISNULL(i.Net,0))>0.01
   OR ABS(ISNULL(r.ConfirmedPaymentsTotal,0)-p.Paid)>0.01
   OR (r.Status IN(N'pago_registrado',N'conciliada',N'cerrada') AND p.Paid<r.Net);

SELECT p.PaymentId,p.PayrollRunId,p.EmployeeId,p.Amount,p.Status,p.CashMoveId,
       m.Amount AS CashAmount,m.Account,m.MoveState
FROM dbo.PayrollPayments p LEFT JOIN dbo.CashMoves m ON m.CashMoveId=p.CashMoveId
WHERE p.Status=N'confirmado' AND (m.CashMoveId IS NULL OR m.MoveState<>N'confirmado' OR m.Amount<>p.Amount);

SELECT IdempotencyKey,COUNT(*) AS Copies FROM dbo.PayrollPayments
WHERE IdempotencyKey IS NOT NULL GROUP BY IdempotencyKey HAVING COUNT(*)>1;

SELECT PayrollRunId,CashMoveId,Amount,Account,MoveDate
FROM dbo.CashMoves m WHERE m.DocumentType=N'nomina' AND m.MoveState=N'confirmado'
AND NOT EXISTS(SELECT 1 FROM dbo.PayrollPayments p WHERE p.CashMoveId=m.CashMoveId AND p.Status=N'confirmado');

SELECT AccountingEntryId,PayrollRunId,Debit,Credit,DebitAccount,CreditAccount
FROM dbo.AccountingEntries WHERE Debit<>Credit;
GO
