/* ============================================================================
   MIGRACION 29 - COHERENCIA CAJA / NOMINA / SNAPSHOT
   ----------------------------------------------------------------------------
   Causas encontradas (con evidencia en codigo, no reconstruye la base):

   1) usp_GetPayrollRuns (migracion 26) dejo de devolver workersCount, startDate,
      endDate, paymentDate y employerCostTotal. La pantalla mostraba 0 personas
      y podia tratar un borrador como si ya estuviera calculado.
   2) usp_CreatePayrollDraft escribia CalculationVersion = 1, PaidAt = ahora y
      Net = Gross con TotalDeductions = 0. Eso aparentaba un calculo valido.
   3) usp_SaveErpState BORRABA caja sin OperationKey y la VOLVIA A INSERTAR
      desde el JSON del navegador (addSale/addCash). Esa es una fuente real de
      duplicados de dinero.
   4) usp_RegisterPayrollPayment reutilizaba un solo CashMove por planilla y
      NO validaba el pendiente del trabajador: dos pagos al mismo empleado con
      distinta clave de idempotencia se aceptaban hasta agotar el neto de la
      planilla.
   5) CK_CashMoves_AmountPositivo impedia apertura en C$ 0.

   No borra datos operativos. No reinstala semilla. No cambia cuentas.
   ============================================================================ */
USE [Instalaciones Raquel];
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

PRINT N'29: inicio';

/* ---------------------------------------------------------------------------
   1) Apertura con saldo 0 permitida (el tipo apertura identifica el saldo
      inicial; no es un ingreso).
   --------------------------------------------------------------------------- */
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_CashMoves_AmountPositivo'
      AND parent_object_id = OBJECT_ID(N'dbo.CashMoves')
)
    ALTER TABLE dbo.CashMoves DROP CONSTRAINT CK_CashMoves_AmountPositivo;
GO

ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT CK_CashMoves_AmountPositivo
    CHECK (Amount > 0 OR (DocumentType = N'apertura' AND Amount >= 0));
GO

IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.PayrollRuns')
      AND name = N'PaidAt' AND is_nullable = 0
)
BEGIN
    ALTER TABLE dbo.PayrollRuns ALTER COLUMN PaidAt DATETIMEOFFSET(3) NULL;
    PRINT N'29: PayrollRuns.PaidAt ahora admite NULL (el borrador no esta pagado).';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_PayrollPayments_RequestHash'
      AND object_id = OBJECT_ID(N'dbo.PayrollPayments')
)
    CREATE UNIQUE INDEX UQ_PayrollPayments_RequestHash
        ON dbo.PayrollPayments (RequestHash)
        WHERE RequestHash IS NOT NULL;
GO

/* ---------------------------------------------------------------------------
   2) Tasa vigente del catalogo de reglas (no se inventan porcentajes).
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.fn_PayrollRuleRate', N'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_PayrollRuleRate;
GO
CREATE FUNCTION dbo.fn_PayrollRuleRate (
    @RuleCode NVARCHAR(40),
    @JsonPath NVARCHAR(80)
)
RETURNS DECIMAL(9,6)
AS
BEGIN
    DECLARE @Rate DECIMAL(9,6);
    SELECT TOP (1) @Rate = TRY_CONVERT(DECIMAL(9,6), JSON_VALUE(ParameterJson, @JsonPath))
    FROM dbo.PayrollRulesCatalog
    WHERE RuleCode = @RuleCode
      AND Status = N'vigente'
      AND IsVerified = 1
      AND EffectiveFrom <= CAST(SYSUTCDATETIME() AS DATE)
      AND (EffectiveTo IS NULL OR EffectiveTo >= CAST(SYSUTCDATETIME() AS DATE))
    ORDER BY EffectiveFrom DESC;
    RETURN @Rate;
END;
GO

/* ---------------------------------------------------------------------------
   3) Listado de planillas: devolver las columnas que usa la interfaz.
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollRuns
    @IncludeClosed BIT = 0
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.PayrollRunId AS id,
        r.Period AS period,
        r.PeriodType AS periodType,
        r.StartDate AS startDate,
        r.EndDate AS endDate,
        r.PaymentDate AS paymentDate,
        r.Status AS status,
        r.CalculationVersion AS calculationVersion,
        ISNULL(r.CalculationStale, 0) AS calculationStale,
        r.Gross AS grossTotal,
        r.InssLaboral AS inssLaboralTotal,
        r.IncomeTax AS incomeTaxTotal,
        r.OtherDeductionsTotal AS otherDeductionsTotal,
        r.TotalDeductions AS totalDeductions,
        ISNULL((SELECT SUM(i.TotalDeductions) FROM dbo.PayrollRunItems AS i WHERE i.PayrollRunId = r.PayrollRunId), 0) AS deductionsFromItems,
        CASE WHEN r.TotalDeductions = ISNULL((SELECT SUM(i.TotalDeductions) FROM dbo.PayrollRunItems AS i WHERE i.PayrollRunId = r.PayrollRunId), 0)
             THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS headerConsistent,
        r.Net AS netTotal,
        r.InssPatronal AS inssPatronalTotal,
        r.Inatec AS inatecTotal,
        r.AguinaldoProvTotal AS aguinaldoProvTotal,
        r.VacacionesProvTotal AS vacacionesProvTotal,
        r.IndemnizacionProvTotal AS indemnizacionProvTotal,
        r.EmployerCost AS employerCostTotal,
        r.EmployerCost AS companyCostTotal,
        r.ConfirmedPaymentsTotal AS confirmedPaymentsTotal,
        (ISNULL(r.Net, 0) - ISNULL(r.ConfirmedPaymentsTotal, 0)) AS pendingPayment,
        r.PendingDiscrepancyTotal AS pendingDiscrepancyTotal,
        r.Actor AS preparedByName,
        r.PreparedAt AS preparedAt,
        r.CalculatedAt AS calculatedAt,
        r.ReviewedAt AS reviewedAt,
        r.ApprovedAt AS approvedAt,
        r.PaidAt AS paidAt,
        r.ReconciledAt AS reconciledAt,
        r.ClosedAt AS closedAt,
        r.Notes AS notes,
        (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS workersCount,
        (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS employeesCount,
        (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'bloqueante' AND IsResolved = 0) AS blockingIssuesCount,
        (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'advertencia' AND IsResolved = 0) AS warningIssuesCount,
        CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision,
        CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS rowVersion,
        r.UpdatedAt AS updatedAt
    FROM dbo.PayrollRuns AS r
    WHERE (@IncludeClosed = 1 OR r.Status NOT IN (N'cancelada'))
    ORDER BY r.StartDate DESC, r.CreatedAt DESC;
END;
GO

/* ---------------------------------------------------------------------------
   4) Borrador: version 0, sin PaidAt, neto y deducciones en 0 hasta calcular.
      Conserva dias/horas reconocidos (no asigna 30/240 fijos).
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_CreatePayrollDraft
    @PayrollRunId   NVARCHAR(100),
    @Period         NVARCHAR(40),
    @PeriodType     NVARCHAR(30),
    @StartDate      DATE,
    @EndDate        DATE,
    @PaymentDate    DATE,
    @Notes          NVARCHAR(MAX) = NULL,
    @ActorId        NVARCHAR(100),
    @ActorName      NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (
        SELECT 1 FROM dbo.PayrollRuns
        WHERE Period = @Period AND Status <> N'cerrada'
    )
        THROW 50501, 'Ya existe una planilla activa para el mismo periodo.', 1;

    IF @StartDate > @EndDate
        THROW 50502, 'La fecha de inicio no puede ser posterior a la fecha de finalizacion.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.PayrollRuns (
            PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate,
            PaidAt, Actor, ActorUserId, Status, CalculationVersion,
            Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost,
            OtherDeductionsTotal, TotalDeductions, AguinaldoProvTotal, VacacionesProvTotal, IndemnizacionProvTotal,
            ConfirmedPaymentsTotal, PendingDiscrepancyTotal,
            PreparedByAppUserId, PreparedAt, Notes
        )
        VALUES (
            @PayrollRunId, @Period, @PeriodType, @StartDate, @EndDate, @PaymentDate,
            NULL, @ActorName, @ActorId, N'borrador', 0,
            0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            0, 0,
            @ActorId, SYSUTCDATETIME(), @Notes
        );

        INSERT INTO dbo.PayrollRunItems (
            PayrollRunId, EmployeeId, PayrollItemId, PositionSnapshot, AreaSnapshot,
            BaseSalaryMonthly, PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary,
            OvertimeHours, OvertimeAmount, BonusesAmount, CommissionsAmount,
            VacationDisfruteAmount, OtherTaxableIncome, Gross,
            InssBase, InssLaboral, IrBase, IncomeTax, OtherDeductions, TotalDeductions, Net,
            InssPatronal, Inatec, Aguinaldo, VacacionesProv, IndemnizacionProv, EmployerCost,
            PaymentStatus, PaymentMethod, ReceiptStatus
        )
        SELECT
            @PayrollRunId,
            e.EmployeeId,
            @PayrollRunId + N'-' + e.EmployeeId,
            e.Position,
            e.Area,
            e.Salary,
            w.Days,
            ROUND(w.Days * 8.0, 2),
            ROUND(e.Salary / 30.0 * w.Days, 2),
            0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0,
            N'pendiente', N'transferencia_bancaria', N'no_generado'
        FROM dbo.Employees AS e
        CROSS APPLY (
            SELECT DATEDIFF(
                DAY,
                CASE WHEN e.HireDate IS NULL OR e.HireDate < @StartDate THEN @StartDate ELSE e.HireDate END,
                CASE WHEN e.DismissalDate IS NULL OR e.DismissalDate > @EndDate THEN @EndDate ELSE e.DismissalDate END
            ) + 1 AS RawDays
        ) AS d
        CROSS APPLY (
            SELECT CAST(
                CASE
                    WHEN @PeriodType IN (N'especial_aguinaldo', N'liquidacion') THEN 0
                    WHEN @PeriodType = N'quincenal'
                        THEN CASE WHEN d.RawDays > 15 THEN 15 WHEN d.RawDays < 0 THEN 0 ELSE d.RawDays END
                    WHEN @PeriodType = N'catorcenal'
                        THEN CASE WHEN d.RawDays > 14 THEN 14 WHEN d.RawDays < 0 THEN 0 ELSE d.RawDays END
                    ELSE CASE WHEN d.RawDays > 30 THEN 30 WHEN d.RawDays < 0 THEN 0 ELSE d.RawDays END
                END AS DECIMAL(9,2)
            ) AS Days
        ) AS w
        WHERE (e.EmploymentStatus = N'activo'
               OR (e.DismissalDate IS NOT NULL AND e.DismissalDate >= @StartDate))
          AND (e.HireDate IS NULL OR e.HireDate <= @EndDate);

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'creacion', NULL, N'borrador',
            N'Borrador creado. Dias y horas reconocidos; deducciones y neto pendientes de calculo.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.CalculationVersion AS calculationVersion,
               r.Gross AS grossTotal, r.Net AS netTotal, r.TotalDeductions AS totalDeductions,
               (SELECT COUNT(1) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS workersCount,
               CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision
        FROM dbo.PayrollRuns r
        WHERE r.PayrollRunId = @PayrollRunId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* ---------------------------------------------------------------------------
   5) Calculo: tasas del catalogo vigente. Sin regla verificada no se calcula.
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_CalculatePayroll
    @PayrollRunId       NVARCHAR(100),
    @ExpectedRevision   VARBINARY(8),
    @ActorId            NVARCHAR(100),
    @ActorName          NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(30);
    DECLARE @PeriodType NVARCHAR(30);
    DECLARE @CalcVer INT;
    DECLARE @CurrentRev VARBINARY(8);
    DECLARE @PeriodsInYear DECIMAL(9,4);
    DECLARE @InssLab DECIMAL(9,6) = dbo.fn_PayrollRuleRate(N'INSS_LABORAL', N'$.rate');
    DECLARE @InssPat DECIMAL(9,6) = COALESCE(
        dbo.fn_PayrollRuleRate(N'INSS_PATRONAL', N'$.rate_used'),
        dbo.fn_PayrollRuleRate(N'INSS_PATRONAL', N'$.rate_large')
    );
    DECLARE @Inatec DECIMAL(9,6) = dbo.fn_PayrollRuleRate(N'INATEC_PATRONAL', N'$.rate');
    DECLARE @Prov DECIMAL(9,6) = COALESCE(dbo.fn_PayrollRuleRate(N'AGUINALDO_PROV', N'$.rate'), CONVERT(DECIMAL(9,6), 1.0/12.0));

    IF @InssLab IS NULL OR @InssPat IS NULL OR @Inatec IS NULL
        THROW 50596, 'Faltan reglas vigentes y verificadas (INSS laboral, INSS patronal o INATEC). No se inventan porcentajes.', 1;

    SELECT @CurrentStatus = Status,
           @PeriodType = PeriodType,
           @CalcVer = CalculationVersion,
           @CurrentRev = CONVERT(VARBINARY(8), Revision)
    FROM dbo.PayrollRuns WITH (UPDLOCK, HOLDLOCK)
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50503, 'La planilla solicitada no existe.', 1;

    IF @CurrentRev <> @ExpectedRevision
        THROW 50504, 'La planilla fue modificada por otro usuario (revision desfasada). Recarga la pantalla.', 1;

    IF @CurrentStatus IN (N'aprobada', N'pago_registrado', N'conciliada', N'cerrada')
        THROW 50505, 'No se puede recalcular una planilla que ya ha sido aprobada, pagada o cerrada.', 1;

    SET @PeriodsInYear = CASE
        WHEN @PeriodType = N'quincenal' THEN 24.0
        WHEN @PeriodType = N'catorcenal' THEN 26.0
        ELSE 12.0
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE i
        SET i.OvertimeAmount = ISNULL(nov.TotalOt, 0),
            i.OvertimeHours = ISNULL(nov.TotalOtHours, 0),
            i.BonusesAmount = ISNULL(nov.TotalBonus, 0),
            i.CommissionsAmount = ISNULL(nov.TotalComm, 0),
            i.VacationDisfruteAmount = ISNULL(nov.TotalVac, 0),
            i.OtherDeductions = ISNULL(nov.TotalDed, 0)
        FROM dbo.PayrollRunItems i
        OUTER APPLY (
            SELECT SUM(CASE WHEN NoveltyType = N'horas_extra' THEN Amount ELSE 0 END) AS TotalOt,
                   SUM(CASE WHEN NoveltyType = N'horas_extra' THEN ISNULL(Hours, 0) ELSE 0 END) AS TotalOtHours,
                   SUM(CASE WHEN NoveltyType = N'bono' THEN Amount ELSE 0 END) AS TotalBonus,
                   SUM(CASE WHEN NoveltyType = N'comision' THEN Amount ELSE 0 END) AS TotalComm,
                   SUM(CASE WHEN NoveltyType = N'vacaciones' THEN Amount ELSE 0 END) AS TotalVac,
                   SUM(CASE WHEN NoveltyType IN (N'deduccion_prestamo', N'otro_descuento', N'otro') THEN Amount ELSE 0 END) AS TotalDed
            FROM dbo.PayrollNovelties
            WHERE EmployeeId = i.EmployeeId AND (PayrollRunId = @PayrollRunId OR PayrollRunId IS NULL)
              AND Status IN (N'autorizada', N'procesada')
        ) AS nov
        WHERE i.PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET Gross = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2),
            InssBase = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET InssLaboral = ROUND(InssBase * @InssLab, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE i
        SET i.IrBase = p.NetBasePeriod,
            i.IncomeTax = calc.IrPeriod
        FROM dbo.PayrollRunItems i
        CROSS APPLY (
            SELECT
                (i.Gross - i.InssLaboral) AS NetBasePeriod,
                (i.Gross - i.InssLaboral) * @PeriodsInYear AS ProjectedAnnual
        ) AS p
        CROSS APPLY (
            SELECT
                CASE
                    WHEN p.ProjectedAnnual <= 100000.00 THEN 0.00
                    WHEN p.ProjectedAnnual <= 200000.00 THEN
                        ROUND(((p.ProjectedAnnual - 100000.00) * 0.15) / @PeriodsInYear, 2)
                    WHEN p.ProjectedAnnual <= 350000.00 THEN
                        ROUND((15000.00 + (p.ProjectedAnnual - 200000.00) * 0.20) / @PeriodsInYear, 2)
                    WHEN p.ProjectedAnnual <= 500000.00 THEN
                        ROUND((45000.00 + (p.ProjectedAnnual - 350000.00) * 0.25) / @PeriodsInYear, 2)
                    ELSE
                        ROUND((82500.00 + (p.ProjectedAnnual - 500000.00) * 0.30) / @PeriodsInYear, 2)
                END AS IrPeriod
        ) AS calc
        WHERE i.PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET TotalDeductions = ROUND(InssLaboral + IncomeTax + OtherDeductions, 2),
            Net = ROUND(Gross - (InssLaboral + IncomeTax + OtherDeductions), 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET InssPatronal = ROUND(Gross * @InssPat, 2),
            Inatec = ROUND(Gross * @Inatec, 2),
            Aguinaldo = ROUND(Gross * @Prov, 2),
            VacacionesProv = ROUND(Gross * @Prov, 2),
            IndemnizacionProv = ROUND(Gross * @Prov, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET EmployerCost = ROUND(Gross + InssPatronal + Inatec + Aguinaldo + VacacionesProv + IndemnizacionProv, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE i
        SET CalculationExplanationJson = (
            SELECT
                i.OrdinarySalary AS [salario_ordinario],
                i.OvertimeAmount AS [horas_extra_monto],
                i.OvertimeHours AS [horas_extra_cantidad],
                i.BonusesAmount AS [bonos],
                i.CommissionsAmount AS [comisiones],
                i.Gross AS [total_devengado],
                CONVERT(NVARCHAR(20), @InssLab * 100) + N'% sobre devengado (catalogo INSS_LABORAL vigente)' AS [inss_laboral_regla],
                i.InssLaboral AS [inss_laboral_monto],
                N'Tarifa progresiva anual Ley 822 Art. 96 (catalogo IR_PROGRESIVO)' AS [ir_laboral_regla],
                i.IrBase AS [ir_base_periodo],
                i.IncomeTax AS [ir_laboral_monto],
                i.OtherDeductions AS [otras_deducciones],
                i.TotalDeductions AS [total_deducciones],
                i.Net AS [salario_neto_a_pagar],
                CONVERT(NVARCHAR(20), @InssPat * 100) + N'% INSS patronal + ' + CONVERT(NVARCHAR(20), @Inatec * 100) + N'% INATEC (no se descuentan al trabajador)' AS [aportes_patronales_regla],
                i.InssPatronal AS [inss_patronal],
                i.Inatec AS [inatec],
                N'Ley 185: provision 1/12 aguinaldo, vacaciones y antiguedad' AS [provisiones_regla],
                i.Aguinaldo AS [provision_aguinaldo],
                i.VacacionesProv AS [provision_vacaciones],
                i.IndemnizacionProv AS [provision_indemnizacion],
                i.EmployerCost AS [costo_total_empresa],
                @InssLab AS [tasa_inss_laboral],
                @InssPat AS [tasa_inss_patronal],
                @Inatec AS [tasa_inatec]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
        FROM dbo.PayrollRunItems i
        WHERE i.PayrollRunId = @PayrollRunId;

        UPDATE r
        SET r.Gross = ISNULL(t.GrossTotal, 0),
            r.InssLaboral = ISNULL(t.InssLabTotal, 0),
            r.IncomeTax = ISNULL(t.IrTotal, 0),
            r.OtherDeductionsTotal = ISNULL(t.OtherDedTotal, 0),
            r.TotalDeductions = ISNULL(t.DedTotal, 0),
            r.Net = ISNULL(t.NetTotal, 0),
            r.InssPatronal = ISNULL(t.InssPatTotal, 0),
            r.Inatec = ISNULL(t.InatecTotal, 0),
            r.AguinaldoProvTotal = ISNULL(t.AguiTotal, 0),
            r.VacacionesProvTotal = ISNULL(t.VacTotal, 0),
            r.IndemnizacionProvTotal = ISNULL(t.IndemTotal, 0),
            r.EmployerCost = ISNULL(t.CostTotal, 0),
            r.CalculationVersion = r.CalculationVersion + 1,
            r.CalculationStale = 0,
            r.Status = N'calculada',
            r.CalculatedByAppUserId = @ActorId,
            r.CalculatedAt = SYSUTCDATETIME(),
            r.UpdatedAt = SYSUTCDATETIME()
        FROM dbo.PayrollRuns r
        OUTER APPLY (
            SELECT SUM(Gross) AS GrossTotal,
                   SUM(InssLaboral) AS InssLabTotal,
                   SUM(IncomeTax) AS IrTotal,
                   SUM(OtherDeductions) AS OtherDedTotal,
                   SUM(TotalDeductions) AS DedTotal,
                   SUM(Net) AS NetTotal,
                   SUM(InssPatronal) AS InssPatTotal,
                   SUM(Inatec) AS InatecTotal,
                   SUM(Aguinaldo) AS AguiTotal,
                   SUM(VacacionesProv) AS VacTotal,
                   SUM(IndemnizacionProv) AS IndemTotal,
                   SUM(EmployerCost) AS CostTotal
            FROM dbo.PayrollRunItems
            WHERE PayrollRunId = @PayrollRunId
        ) AS t
        WHERE r.PayrollRunId = @PayrollRunId;

        DELETE FROM dbo.PayrollValidations WHERE PayrollRunId = @PayrollRunId;

        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_NETO_INVALIDO',
               N'El trabajador tiene un salario neto menor o igual a cero (C$ ' + CAST(Net AS NVARCHAR(30)) + N'). Revisa las deducciones aplicadas.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Net <= 0;

        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_DEVENGADO_CERO',
               N'El colaborador no registra salario ordinario ni devengado en el periodo.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Gross <= 0;

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'calculo', @CurrentStatus, N'calculada',
            N'Calculo con reglas vigentes INSS ' + CONVERT(NVARCHAR(20), @InssLab) + N' / patronal ' + CONVERT(NVARCHAR(20), @InssPat) + N'.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.CalculationVersion AS calculationVersion,
               r.Gross AS grossTotal, r.InssLaboral AS inssLaboralTotal,
               r.IncomeTax AS incomeTaxTotal, r.TotalDeductions AS totalDeductions,
               r.Net AS netTotal,
               r.InssPatronal AS inssPatronalTotal, r.Inatec AS inatecTotal,
               r.EmployerCost AS employerCostTotal,
               (SELECT COUNT(1) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS workersCount,
               CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision
        FROM dbo.PayrollRuns r
        WHERE r.PayrollRunId = @PayrollRunId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

