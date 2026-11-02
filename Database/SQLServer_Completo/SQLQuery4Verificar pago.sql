USE [Instalaciones Raquel];
GO

SELECT TOP (20)
    p.PaymentDate AS FechaPago,
    p.TransactionReference AS Referencia,
    p.Amount AS MontoPago,
    p.Status AS EstadoPago,
    m.Account AS Cuenta,
    m.MoveType AS TipoMovimiento,
    m.Amount AS MontoMovimiento,
    m.MoveState AS EstadoMovimiento,
    CASE
        WHEN m.CashMoveId IS NOT NULL
         AND m.MoveType = N'salida'
         AND m.MoveState = N'confirmado'
         AND m.Amount = p.Amount
         AND m.PayrollRunId = p.PayrollRunId
        THEN N'OK'
        ELSE N'REVISAR'
    END AS Verificacion
FROM dbo.PayrollPayments AS p
LEFT JOIN dbo.CashMoves AS m
    ON m.CashMoveId = p.CashMoveId
ORDER BY p.ConfirmedAt DESC, p.PaymentId;