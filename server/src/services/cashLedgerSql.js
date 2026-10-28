// Orden estable: no usamos el UUID aleatorio para decidir que sucedio primero.
export const CASH_LEDGER_CTE = `WITH Moves AS (
  SELECT m.*, ROW_NUMBER() OVER(PARTITION BY m.Account ORDER BY CONVERT(DATE,m.MoveDate),
    ISNULL(s.OpenedAt,m.CreatedAt),
    CASE WHEN m.DocumentType=N'apertura' THEN 0 ELSE 1 END,
    ISNULL(m.MoveTime,CAST('00:00:00' AS TIME(0))),
    m.CreatedAt,m.CashMoveId) AS LedgerOrder
  FROM dbo.CashMoves m LEFT JOIN dbo.CashSessions s ON s.CashSessionId=m.SessionId WHERE m.MoveState=N'confirmado'
), Blocks AS (
  SELECT *,MAX(CASE WHEN DocumentType=N'apertura' THEN LedgerOrder END)
    OVER(PARTITION BY Account ORDER BY LedgerOrder ROWS UNBOUNDED PRECEDING) AS BlockId FROM Moves
), CashLedger AS (
  SELECT CashMoveId,Account,MoveDate,MoveTime,MoveType,
    CASE WHEN MoveType=N'entrada' THEN Amount ELSE NULL END AS Entrada,
    CASE WHEN MoveType=N'salida' THEN Amount ELSE NULL END AS Salida,
    SUM(CASE WHEN DocumentType=N'apertura' THEN Amount ELSE 0 END) OVER(PARTITION BY Account,BlockId)
    +SUM(CASE WHEN DocumentType=N'apertura' THEN 0 WHEN MoveType=N'entrada' THEN Amount ELSE -Amount END)
      OVER(PARTITION BY Account,BlockId ORDER BY LedgerOrder ROWS UNBOUNDED PRECEDING) AS SaldoAcumulado,
    Concept,Method,DocumentType,DocumentRef,SaleId,PurchaseId,PayrollRunId,SessionId,ResponsibleName,OperationKey,LedgerOrder
  FROM Blocks
)`;

export const CASH_SUMMARY_SQL = `${CASH_LEDGER_CTE}, Ordered AS (
  SELECT v.*,LAG(v.SaldoAcumulado,1,0) OVER(PARTITION BY v.Account ORDER BY v.LedgerOrder) AS PreviousBalance
  FROM CashLedger v WHERE (@Account IS NULL OR v.Account=@Account)
), Effects AS (
  SELECT *,SaldoAcumulado-PreviousBalance AS BalanceChange FROM Ordered
)
SELECT
 ISNULL(SUM(CASE WHEN @FromDate IS NOT NULL AND CONVERT(DATE,MoveDate)<@FromDate THEN BalanceChange ELSE 0 END),0) AS saldoAnterior,
 ISNULL(SUM(CASE WHEN (@FromDate IS NULL OR CONVERT(DATE,MoveDate)>=@FromDate) AND DocumentType=N'apertura' THEN BalanceChange ELSE 0 END),0) AS aperturas,
 ISNULL(SUM(CASE WHEN (@FromDate IS NULL OR CONVERT(DATE,MoveDate)>=@FromDate) AND MoveType=N'entrada' AND ISNULL(DocumentType,N'')<>N'apertura' THEN Entrada ELSE 0 END),0) AS entradas,
 ISNULL(SUM(CASE WHEN (@FromDate IS NULL OR CONVERT(DATE,MoveDate)>=@FromDate) THEN ISNULL(Salida,0) ELSE 0 END),0) AS salidas,
 COUNT(CASE WHEN @FromDate IS NULL OR CONVERT(DATE,MoveDate)>=@FromDate THEN 1 END) AS movimientos
FROM Effects WHERE @ToDate IS NULL OR CONVERT(DATE,MoveDate)<=@ToDate;`;

export const CASH_SUGGESTED_OPENING_SQL = `${CASH_LEDGER_CTE}, Accounts AS (
 SELECT N'caja' AS Account UNION ALL SELECT N'banco'
), Sessions AS (
 SELECT *,ROW_NUMBER() OVER(PARTITION BY Account ORDER BY OpenedAt DESC,CashSessionId DESC) AS rn FROM dbo.CashSessions
), LastBalance AS (
 SELECT *,ROW_NUMBER() OVER(PARTITION BY Account ORDER BY LedgerOrder DESC) AS rn FROM CashLedger
)
SELECT a.Account AS account,
 CASE WHEN s.Status=N'cerrada' THEN s.CountedCash
      WHEN s.Status=N'abierta' THEN s.OpeningBalance+ISNULL((SELECT SUM(CASE WHEN MoveType=N'entrada' THEN Amount ELSE -Amount END)
       FROM dbo.CashMoves WHERE SessionId=s.CashSessionId AND MoveState=N'confirmado' AND ISNULL(DocumentType,N'')<>N'apertura'),0)
      ELSE ISNULL(b.SaldoAcumulado,0) END AS suggestedOpening,
 CASE WHEN s.Status=N'cerrada' THEN N'sesion_cerrada' WHEN s.Status=N'abierta' THEN N'sesion_abierta' ELSE N'sin_sesion' END AS origin,
 s.CashSessionId AS sourceSessionId,s.ClosedAt AS closedAt
FROM Accounts a LEFT JOIN Sessions s ON s.Account=a.Account AND s.rn=1
LEFT JOIN LastBalance b ON b.Account=a.Account AND b.rn=1
WHERE @Account IS NULL OR a.Account=@Account;`;

// Consulta compartida por la API y la prueba SQL de lectura.
export const CASH_MOVEMENTS_SQL = `${CASH_LEDGER_CTE}

      SELECT TOP (@Limit)
             v.CashMoveId AS id,
             v.Account AS account,
             v.MoveDate AS date,
             v.MoveTime AS time,
             v.MoveType AS type,
             v.Entrada AS entry,
             v.Salida AS [exit],
             v.SaldoAcumulado AS balance,
             v.Concept AS concept,
             v.Method AS method,
             v.DocumentType AS documentType,
             v.DocumentRef AS documentRef,
             v.SaleId AS saleId,
             v.PurchaseId AS purchaseId,
             v.PayrollRunId AS payrollRunId,
             v.SessionId AS sessionId,
             v.ResponsibleName AS responsible,
             v.OperationKey AS operationKey
      FROM CashLedger AS v
      WHERE (@Account IS NULL OR v.Account = @Account)
        AND (@FromDate IS NULL OR CONVERT(DATE, v.MoveDate) >= @FromDate)
        AND (@ToDate IS NULL OR CONVERT(DATE, v.MoveDate) <= @ToDate)
      ORDER BY v.Account, v.LedgerOrder DESC;
    `;
