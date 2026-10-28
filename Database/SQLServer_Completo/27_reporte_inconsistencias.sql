/* ============================================================================
   27 - REPORTE DE INCONSISTENCIAS (SOLO LECTURA)
   ----------------------------------------------------------------------------
   Este script NO modifica datos, NO borra filas y NO toca periodos cerrados.
   Su objetivo es evidenciar los efectos historicos que quedaron mal antes de la
   migracion 26 (duplicados, cabeceras incoherentes, pagos sin movimiento, etc.)
   para que se decidan y corrijan con respaldo y autorizacion.

   Uso:
     sqlcmd -S 127.0.0.1,51433 -d "Instalaciones Raquel" -E -C -b -f 65001 -i 27_reporte_inconsistencias.sql

   Salida: una fila por hallazgo, agrupada por seccion. Si no hay filas en una
   seccion, esa seccion no aparece (todas las consultas son SELECT).
   ============================================================================ */
USE [Instalaciones Raquel];
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @Hallazgos TABLE (
    Orden       INT           NOT NULL,
    Seccion     NVARCHAR(90)  NOT NULL,
    Severidad   NVARCHAR(10)  NOT NULL,
    Referencia  NVARCHAR(160) NOT NULL,
    Detalle     NVARCHAR(500) NOT NULL,
    Esperado    NVARCHAR(40)  NULL,
    Encontrado  NVARCHAR(40)  NULL
);

/* ---------------------------------------------------------------------------
   1. Cabecera de planilla con deducciones distintas a la suma del detalle
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 1,
       N'1. Planilla: cabecera vs detalle',
       N'ALTA',
       r.Period + N' (' + r.PayrollRunId + N')',
       N'TotalDeductions de la cabecera no coincide con SUM(PayrollRunItems.TotalDeductions). Estado: ' + r.Status,
       CONVERT(NVARCHAR(40), CAST(ISNULL(items.Deducciones, 0) AS DECIMAL(19, 4))),
       CONVERT(NVARCHAR(40), CAST(r.TotalDeductions AS DECIMAL(19, 4)))
FROM dbo.PayrollRuns AS r
OUTER APPLY (
    SELECT SUM(i.TotalDeductions) AS Deducciones
    FROM dbo.PayrollRunItems AS i
    WHERE i.PayrollRunId = r.PayrollRunId
) AS items
WHERE ABS(r.TotalDeductions - ISNULL(items.Deducciones, 0)) > 0.009;

/* ---------------------------------------------------------------------------
   2. Planillas en estado avanzado (pagada/conciliada/cerrada) con deducciones
      en cero pero con detalle: no se corrigen aqui, solo se reportan.
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 2,
       N'2. Planilla cerrada/pagada con deducciones en 0',
       N'ALTA',
       r.Period + N' (' + r.PayrollRunId + N')',
       N'Planilla en estado ' + r.Status + N' con TotalDeductions = 0 pero con deducciones en el detalle. Requiere respaldo y decision antes de corregir.',
       CONVERT(NVARCHAR(40), CAST(ISNULL(items.Deducciones, 0) AS DECIMAL(19, 4))),
       N'0.0000'
FROM dbo.PayrollRuns AS r
OUTER APPLY (
    SELECT SUM(i.TotalDeductions) AS Deducciones
    FROM dbo.PayrollRunItems AS i
    WHERE i.PayrollRunId = r.PayrollRunId
) AS items
WHERE r.Status IN (N'pago_registrado', N'conciliada', N'cerrada')
  AND r.TotalDeductions = 0
  AND ISNULL(items.Deducciones, 0) > 0.009;

/* ---------------------------------------------------------------------------
   3. Neto de la cabecera distinto de Devengado - Deducciones
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 3,
       N'3. Planilla: neto incoherente',
       N'ALTA',
       r.Period + N' (' + r.PayrollRunId + N')',
       N'Net <> Gross - (INSS laboral + IR + otras deducciones). Estado: ' + r.Status,
       CONVERT(NVARCHAR(40), CAST(r.Gross - (r.InssLaboral + r.IncomeTax + r.OtherDeductionsTotal) AS DECIMAL(19, 4))),
       CONVERT(NVARCHAR(40), CAST(r.Net AS DECIMAL(19, 4)))
FROM dbo.PayrollRuns AS r
WHERE ABS(r.Net - (r.Gross - (r.InssLaboral + r.IncomeTax + r.OtherDeductionsTotal))) > 0.009;

/* ---------------------------------------------------------------------------
   4. Total de pagos confirmados en cabecera vs pagos reales
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 4,
       N'4. Planilla: pagos confirmados vs recibos',
       N'ALTA',
       r.Period + N' (' + r.PayrollRunId + N')',
       N'ConfirmedPaymentsTotal no coincide con la suma de PayrollPayments. Estado: ' + r.Status,
       CONVERT(NVARCHAR(40), CAST(ISNULL(p.Pagado, 0) AS DECIMAL(19, 4))),
       CONVERT(NVARCHAR(40), CAST(r.ConfirmedPaymentsTotal AS DECIMAL(19, 4)))
FROM dbo.PayrollRuns AS r
OUTER APPLY (
    SELECT SUM(pay.Amount) AS Pagado
    FROM dbo.PayrollPayments AS pay
    WHERE pay.PayrollRunId = r.PayrollRunId
) AS p
WHERE ABS(r.ConfirmedPaymentsTotal - ISNULL(p.Pagado, 0)) > 0.009;

/* ---------------------------------------------------------------------------
   5. Pagos registrados sin movimiento de caja/banco asociado
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 5,
       N'5. Pago sin movimiento de caja',
       N'ALTA',
       p.PaymentId,
       N'Pago de la planilla ' + p.PayrollRunId + N' sin CashMoveId valido en CashMoves (el egreso no tiene respaldo en tesoreria).',
       N'1 movimiento',
       N'0 movimientos'
FROM dbo.PayrollPayments AS p
WHERE p.CashMoveId IS NULL
   OR NOT EXISTS (SELECT 1 FROM dbo.CashMoves AS c WHERE c.CashMoveId = p.CashMoveId);

/* ---------------------------------------------------------------------------
   6. Movimiento de caja de nomina cuyo importe no coincide con los pagos
      confirmados de esa planilla (posible duplicacion del egreso)
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 6,
       N'6. Movimiento de nomina descuadrado',
       N'ALTA',
       c.CashMoveId,
       N'El movimiento de nomina de la planilla ' + ISNULL(c.PayrollRunId, N'(sin planilla)') + N' no coincide con la suma de pagos confirmados.',
       CONVERT(NVARCHAR(40), CAST(ISNULL(p.Pagado, 0) AS DECIMAL(19, 4))),
       CONVERT(NVARCHAR(40), CAST(c.Amount AS DECIMAL(19, 4)))
FROM dbo.CashMoves AS c
OUTER APPLY (
    SELECT SUM(pay.Amount) AS Pagado
    FROM dbo.PayrollPayments AS pay
    WHERE pay.PayrollRunId = c.PayrollRunId
) AS p
WHERE c.PayrollRunId IS NOT NULL
  AND ISNULL(c.MoveState, N'confirmado') <> N'anulado'
  AND ABS(c.Amount - ISNULL(p.Pagado, 0)) > 0.009;

/* ---------------------------------------------------------------------------
   7. Mas de un movimiento de caja activo para la misma planilla
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 7,
       N'7. Egreso duplicado de nomina',
       N'ALTA',
       c.PayrollRunId,
       N'Existe mas de un movimiento de caja/banco activo para la misma planilla (doble egreso).',
       N'1 movimiento',
       CONVERT(NVARCHAR(40), CAST(COUNT(*) AS NVARCHAR(40)))
FROM dbo.CashMoves AS c
WHERE c.PayrollRunId IS NOT NULL
  AND ISNULL(c.MoveState, N'confirmado') <> N'anulado'
GROUP BY c.PayrollRunId
HAVING COUNT(*) > 1;

/* ---------------------------------------------------------------------------
   8. Asientos contables descuadrados (Debe <> Haber)
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 8,
       N'8. Asiento descuadrado',
       N'ALTA',
       a.AccountingEntryId,
       N'Asiento ' + ISNULL(a.EntryNumber, N'(sin numero)') + N': ' + a.Description,
       CONVERT(NVARCHAR(40), CAST(a.Credit AS DECIMAL(19, 4))),
       CONVERT(NVARCHAR(40), CAST(a.Debit AS DECIMAL(19, 4)))
FROM dbo.AccountingEntries AS a
WHERE ABS(a.Debit - a.Credit) > 0.009
   OR a.Debit <= 0
   OR a.Credit <= 0;

/* ---------------------------------------------------------------------------
   9. Asientos duplicados para la misma referencia (misma referencia, monto y
      fecha): posible doble contabilizacion del mismo hecho economico
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 9,
       N'9. Asiento duplicado',
       N'ALTA',
       a.ReferenceType + N':' + ISNULL(a.ReferenceId, N'(sin id)'),
       N'Varios asientos con la misma referencia, monto y fecha. OperationKey distinto o nulo.',
       N'1 asiento',
       CONVERT(NVARCHAR(40), CAST(COUNT(*) AS NVARCHAR(40)))
FROM dbo.AccountingEntries AS a
WHERE a.ReferenceId IS NOT NULL
GROUP BY a.ReferenceType, a.ReferenceId, a.Debit, a.Credit,
         CAST(a.EntryDate AS DATE)
HAVING COUNT(*) > 1;

/* ---------------------------------------------------------------------------
   10. Movimientos de dinero sin OperationKey (no protegidos por idempotencia)
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 10,
       N'10. Efecto sin OperationKey',
       N'MEDIA',
       c.CashMoveId,
       N'Movimiento de caja historico sin OperationKey: no lo protege la clave de idempotencia (se conserva, no se borra).',
       N'OperationKey',
       N'NULL'
FROM dbo.CashMoves AS c
WHERE c.OperationKey IS NULL;

/* ---------------------------------------------------------------------------
   11. Caja: sesiones cerradas con diferencia sin explicacion o sin revisar
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 11,
       N'11. Arqueo con diferencia sin revisar',
       N'ALTA',
       s.CashSessionId,
       N'Sesion ' + s.Account + N' cerrada con diferencia y ' +
         CASE
           WHEN NULLIF(LTRIM(RTRIM(ISNULL(s.Explanation, N''))), N'') IS NULL THEN N'sin explicacion registrada'
           ELSE N'explicacion registrada'
         END + N'. Revision: ' + ISNULL(s.ReviewStatus, N'(sin estado)'),
       N'0.0000',
       CONVERT(NVARCHAR(40), CAST(s.Difference AS DECIMAL(19, 4)))
FROM dbo.CashSessions AS s
WHERE s.Status = N'cerrada'
  AND ABS(s.Difference) > 0.009
  AND (
        NULLIF(LTRIM(RTRIM(ISNULL(s.Explanation, N''))), N'') IS NULL
        OR ISNULL(s.ReviewStatus, N'pendiente_revision') = N'pendiente_revision'
      );

/* ---------------------------------------------------------------------------
   12. Caja: mas de una sesion abierta para la misma cuenta
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 12,
       N'12. Sesiones de caja simultaneas',
       N'ALTA',
       s.Account,
       N'Existe mas de una sesion abierta para la misma cuenta.',
       N'1 sesion',
       CONVERT(NVARCHAR(40), CAST(COUNT(*) AS NVARCHAR(40)))
FROM dbo.CashSessions AS s
WHERE s.Status = N'abierta'
GROUP BY s.Account
HAVING COUNT(*) > 1;

/* ---------------------------------------------------------------------------
   13. Caja: movimientos con importe <= 0 (deben ser siempre positivos; el
       tipo entrada/salida es lo que determina el efecto)
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 13,
       N'13. Movimiento de caja con importe invalido',
       N'ALTA',
       c.CashMoveId,
       N'Movimiento con importe no positivo. Cuenta: ' + c.Account + N'. Tipo: ' + c.MoveType,
       N'importe > 0',
       CONVERT(NVARCHAR(40), CAST(c.Amount AS DECIMAL(19, 4)))
FROM dbo.CashMoves AS c
WHERE c.Amount <= 0;

/* ---------------------------------------------------------------------------
   13b. Caja: movimientos historicos sin sesion (no atribuibles a un arqueo)
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 14,
       N'13b. Movimiento de caja sin sesion',
       N'MEDIA',
       c.CashMoveId,
       N'Movimiento anterior a las sesiones de caja: no se puede conciliar contra un arqueo. Cuenta: ' + c.Account + N', concepto: ' + c.Concept,
       N'SessionId',
       N'NULL'
FROM dbo.CashMoves AS c
WHERE c.SessionId IS NULL;

/* ---------------------------------------------------------------------------
   14b. Caja: movimientos registrados despues del cierre de su sesion
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 15,
       N'14. Movimiento posterior al cierre',
       N'MEDIA',
       c.CashMoveId,
       N'Movimiento con fecha posterior al cierre de la sesion ' + ISNULL(c.SessionId, N'(sin sesion)') + N'.',
       CONVERT(NVARCHAR(40), CONVERT(NVARCHAR(10), CAST(s.ClosedAt AS DATE), 23)),
       CONVERT(NVARCHAR(40), CONVERT(NVARCHAR(10), CAST(c.MoveDate AS DATE), 23))
FROM dbo.CashMoves AS c
JOIN dbo.CashSessions AS s ON s.CashSessionId = c.SessionId
WHERE s.Status = N'cerrada'
  AND s.ClosedAt IS NOT NULL
  AND c.MoveDate > s.ClosedAt;

/* ---------------------------------------------------------------------------
   15. Nomina: columna TotalDeductions del item desactualizada
       (historico: quedo en 0 aunque INSS/IR si se calcularon)
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 16,
       N'15. Item: TotalDeductions desactualizada',
       N'ALTA',
       i.PayrollRunId + N' / ' + i.EmployeeId,
       N'TotalDeductions del item no coincide con INSS laboral + IR + otras deducciones.',
       CONVERT(NVARCHAR(40), CAST(i.InssLaboral + i.IncomeTax + i.OtherDeductions AS DECIMAL(19, 4))),
       CONVERT(NVARCHAR(40), CAST(i.TotalDeductions AS DECIMAL(19, 4)))
FROM dbo.PayrollRunItems AS i
WHERE ABS(i.TotalDeductions - (i.InssLaboral + i.IncomeTax + i.OtherDeductions)) > 0.009;

/* ---------------------------------------------------------------------------
   15b. Nomina: neto del item no es devengado - deducciones del trabajador
        (los aportes patronales no se descuentan del salario)
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 17,
       N'15b. Item: neto incoherente',
       N'ALTA',
       i.PayrollRunId + N' / ' + i.EmployeeId,
       N'Net del item <> Gross - (INSS laboral + IR + otras deducciones).',
       CONVERT(NVARCHAR(40), CAST(i.Gross - (i.InssLaboral + i.IncomeTax + i.OtherDeductions) AS DECIMAL(19, 4))),
       CONVERT(NVARCHAR(40), CAST(i.Net AS DECIMAL(19, 4)))
FROM dbo.PayrollRunItems AS i
WHERE ABS(i.Net - (i.Gross - (i.InssLaboral + i.IncomeTax + i.OtherDeductions))) > 0.009;

/* ---------------------------------------------------------------------------
   16. Nomina: dias/horas fijos asignados a todos los trabajadores
       (30 dias / 240 horas) en planillas quincenales o por periodos parciales
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 16,
       N'16. Nomina: 30 dias / 240 h fijos',
       N'MEDIA',
       i.PayrollRunId,
       N'Items con PeriodDaysWorked = 30 y PeriodHoursWorked = 240 en una planilla ' + r.PeriodType + N'. Verificar si corresponde al periodo real.',
       N'dias/horas del periodo',
       CONVERT(NVARCHAR(40), CAST(COUNT(*) AS NVARCHAR(40)))
FROM dbo.PayrollRunItems AS i
JOIN dbo.PayrollRuns AS r ON r.PayrollRunId = i.PayrollRunId
WHERE i.PeriodDaysWorked = 30
  AND i.PeriodHoursWorked = 240
  AND r.PeriodType <> N'mensual'
GROUP BY i.PayrollRunId, r.PeriodType
HAVING COUNT(*) > 0;

/* ---------------------------------------------------------------------------
   17. Pagos duplicados: misma planilla, importe, referencia y fecha
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 17,
       N'17. Pago duplicado',
       N'ALTA',
       p.PayrollRunId,
       N'Varios pagos con el mismo importe/referencia/fecha (posible doble clic historico). Referencia: ' + ISNULL(p.TransactionReference, N'(sin referencia)'),
       N'1 pago',
       CONVERT(NVARCHAR(40), CAST(COUNT(*) AS NVARCHAR(40)))
FROM dbo.PayrollPayments AS p
GROUP BY p.PayrollRunId, p.Amount, p.TransactionReference, p.PaymentDate
HAVING COUNT(*) > 1;

/* ---------------------------------------------------------------------------
   18. Planillas con pago registrado pero sin ningun recibo en PayrollPayments
       (el total confirmado quedo escrito a mano)
   --------------------------------------------------------------------------- */
INSERT INTO @Hallazgos (Orden, Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado)
SELECT 18,
       N'18. Planilla pagada sin recibos',
       N'ALTA',
       r.Period + N' (' + r.PayrollRunId + N')',
       N'Planilla en estado ' + r.Status + N' con ConfirmedPaymentsTotal > 0 pero sin filas en PayrollPayments.',
       N'>= 1 pago',
       N'0 pagos'
FROM dbo.PayrollRuns AS r
WHERE r.ConfirmedPaymentsTotal > 0.009
  AND NOT EXISTS (SELECT 1 FROM dbo.PayrollPayments AS p WHERE p.PayrollRunId = r.PayrollRunId);

/* ---------------------------------------------------------------------------
   RESULTADO ORDENADO
   --------------------------------------------------------------------------- */
SELECT Seccion, Severidad, Referencia, Detalle, Esperado, Encontrado
FROM @Hallazgos
ORDER BY Orden, Referencia;

PRINT N'';
PRINT N'Fin del reporte. Ninguna fila fue modificada ni eliminada.';
GO
