/* 31: reglas por periodo y devengo separado. DESPUES de 30.
   No cambia tasas del catalogo, no certifica su validez legal ni repara historicos.
   La revision de las reglas sigue siendo responsabilidad del personal autorizado.
   Aplica solamente procedimientos para futuras operaciones. */
USE [Instalaciones Raquel];
GO
SET QUOTED_IDENTIFIER ON;
GO
IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'dbo.PayrollRulesCatalog') AND name=N'UQ_PayrollRulesCatalog_Code')
 ALTER TABLE dbo.PayrollRulesCatalog DROP CONSTRAINT UQ_PayrollRulesCatalog_Code;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.PayrollRulesCatalog') AND name=N'UQ_PayrollRulesCatalog_CodeDate')
 CREATE UNIQUE INDEX UQ_PayrollRulesCatalog_CodeDate ON dbo.PayrollRulesCatalog(RuleCode,EffectiveFrom);
GO
IF NOT EXISTS(SELECT 1 FROM dbo.ChartOfAccounts WHERE AccountName=N'Otras deducciones por pagar')
 INSERT dbo.ChartOfAccounts(AccountName,AccountType) VALUES(N'Otras deducciones por pagar',N'pasivo');
GO
IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.PayrollInstitutionalObligations') AND name=N'DueDate' AND is_nullable=0)
 ALTER TABLE dbo.PayrollInstitutionalObligations ALTER COLUMN DueDate DATE NULL;
GO
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
    DECLARE @StartDate DATE,@EndDate DATE;
    DECLARE @InssLab DECIMAL(9,6),@InssPat DECIMAL(9,6),@Inatec DECIMAL(9,6),
        @Prov DECIMAL(9,6),@VacProv DECIMAL(9,6),@IndemProv DECIMAL(9,6),@RulesSnapshot NVARCHAR(MAX);
    DECLARE @Rules TABLE(RuleCode NVARCHAR(40),RuleId NVARCHAR(100),ParameterJson NVARCHAR(MAX),EffectiveFrom DATE,EffectiveTo DATE);
    DECLARE @Brackets TABLE(LowerBound DECIMAL(19,2),UpperBound DECIMAL(19,2),Rate DECIMAL(9,6),BaseAmount DECIMAL(19,4),Excess DECIMAL(19,2));
    BEGIN TRY
        BEGIN TRANSACTION;
    SELECT @StartDate=StartDate,@EndDate=EndDate, @CurrentStatus = Status,
           @PeriodType = PeriodType,
           @CalcVer = CalculationVersion,
           @CurrentRev = CONVERT(VARBINARY(8), Revision)
    FROM dbo.PayrollRuns WITH (UPDLOCK, HOLDLOCK)
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50503, 'La planilla solicitada no existe.', 1;

    IF @ExpectedRevision IS NULL OR @CurrentRev <> @ExpectedRevision
        THROW 50504, 'La planilla fue modificada por otro usuario (revision desfasada). Recarga la pantalla.', 1;

    IF @CurrentStatus IN (N'aprobada', N'pago_registrado', N'conciliada', N'cerrada')
        THROW 50505, 'No se puede recalcular una planilla que ya ha sido aprobada, pagada o cerrada.', 1;

    INSERT @Rules SELECT RuleCode,RuleId,ParameterJson,EffectiveFrom,EffectiveTo
    FROM dbo.PayrollRulesCatalog WITH(HOLDLOCK)
    WHERE RuleCode IN(N'INSS_LABORAL',N'INSS_PATRONAL',N'INATEC_PATRONAL',N'IR_PROGRESIVO',N'AGUINALDO_PROV',N'VACACIONES_PROV',N'INDEMNIZACION_PROV')
      AND Status IN(N'vigente',N'historica') AND IsVerified=1 AND EffectiveFrom<=@StartDate AND (EffectiveTo IS NULL OR EffectiveTo>=@EndDate);
    IF (SELECT COUNT(DISTINCT RuleCode) FROM @Rules)<>7 OR EXISTS(SELECT RuleCode FROM @Rules GROUP BY RuleCode HAVING COUNT(*)<>1)
        THROW 50620,'Faltan reglas unicas verificadas que cubran todo el periodo. Revisa vigencias o divide el periodo.',1;
    SELECT @InssLab=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'INSS_LABORAL';
    SELECT @InssPat=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate_used')) FROM @Rules WHERE RuleCode=N'INSS_PATRONAL';
    SELECT @Inatec=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'INATEC_PATRONAL';
    SELECT @Prov=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'AGUINALDO_PROV';
    SELECT @VacProv=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'VACACIONES_PROV';
    SELECT @IndemProv=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'INDEMNIZACION_PROV';
    IF EXISTS(SELECT 1 FROM (VALUES(@InssLab),(@InssPat),(@Inatec),(@Prov),(@VacProv),(@IndemProv)) r(rate) WHERE rate IS NULL OR rate<0 OR rate>1)
        THROW 50620,'Las tasas verificadas estan incompletas o fuera de rango. No se aplican valores por defecto.',1;
    INSERT @Brackets SELECT b.LowerBound,b.UpperBound,b.Rate,b.BaseAmount,b.Excess
    FROM @Rules r CROSS APPLY OPENJSON(r.ParameterJson,'$.brackets') WITH(
        LowerBound DECIMAL(19,2) '$.from',UpperBound DECIMAL(19,2) '$.to',Rate DECIMAL(9,6) '$.rate',
        BaseAmount DECIMAL(19,4) '$.base',Excess DECIMAL(19,2) '$.excess') b WHERE r.RuleCode=N'IR_PROGRESIVO';
    IF NOT EXISTS(SELECT 1 FROM @Brackets) OR EXISTS(SELECT 1 FROM @Brackets WHERE LowerBound IS NULL OR LowerBound<0 OR Rate IS NULL OR Rate<0 OR Rate>1
        OR BaseAmount IS NULL OR BaseAmount<0 OR Excess IS NULL OR Excess<0 OR (UpperBound IS NOT NULL AND UpperBound<LowerBound))
        THROW 50620,'Los tramos del catalogo IR estan incompletos o son invalidos.',1;
    IF (SELECT COUNT(*) FROM @Brackets WHERE UpperBound IS NULL)<>1
        OR (SELECT MIN(LowerBound) FROM @Brackets)>0.01
        OR EXISTS(SELECT 1 FROM (SELECT LowerBound,UpperBound,LAG(UpperBound) OVER(ORDER BY LowerBound) AS PreviousUpper,
            ROW_NUMBER() OVER(ORDER BY LowerBound) AS rn FROM @Brackets) b
            WHERE rn>1 AND (PreviousUpper IS NULL OR LowerBound<>PreviousUpper+0.01))
        THROW 50620,'El catalogo IR tiene tramos superpuestos o sin cobertura.',1;
    SET @RulesSnapshot=(SELECT * FROM @Rules ORDER BY RuleCode FOR JSON PATH);
    SET @PeriodsInYear = CASE
        WHEN @PeriodType = N'quincenal' THEN 24.0
        WHEN @PeriodType = N'catorcenal' THEN 26.0
        ELSE 12.0
    END;

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
            WHERE EmployeeId = i.EmployeeId AND (PayrollRunId = @PayrollRunId OR (PayrollRunId IS NULL AND PeriodDate BETWEEN @StartDate AND @EndDate))
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

        IF EXISTS(SELECT 1 FROM dbo.PayrollRunItems i WHERE i.PayrollRunId=@PayrollRunId AND ROUND((i.Gross-i.InssLaboral)*@PeriodsInYear,2)>0
            AND (SELECT COUNT(*) FROM @Brackets b WHERE ROUND((i.Gross-i.InssLaboral)*@PeriodsInYear,2)>=b.LowerBound
             AND (b.UpperBound IS NULL OR ROUND((i.Gross-i.InssLaboral)*@PeriodsInYear,2)<=b.UpperBound))<>1)
            THROW 50620,'La base anual no tiene exactamente un tramo IR aplicable.',1;
        UPDATE i SET IrBase=i.Gross-i.InssLaboral,
            IncomeTax=CASE WHEN p.AnnualBase<=0 THEN 0 ELSE ROUND((b.BaseAmount+(p.AnnualBase-b.Excess)*b.Rate)/@PeriodsInYear,2) END
        FROM dbo.PayrollRunItems i CROSS APPLY(SELECT ROUND((i.Gross-i.InssLaboral)*@PeriodsInYear,2) AS AnnualBase) p
        OUTER APPLY(SELECT * FROM @Brackets WHERE p.AnnualBase>=LowerBound AND (UpperBound IS NULL OR p.AnnualBase<=UpperBound)) b
        WHERE i.PayrollRunId=@PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET TotalDeductions = ROUND(InssLaboral + IncomeTax + OtherDeductions, 2),
            Net = ROUND(Gross - (InssLaboral + IncomeTax + OtherDeductions), 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET InssPatronal = ROUND(Gross * @InssPat, 2),
            Inatec = ROUND(Gross * @Inatec, 2),
            Aguinaldo = ROUND(Gross * @Prov, 2),
            VacacionesProv = ROUND(Gross * @VacProv, 2),
            IndemnizacionProv = ROUND(Gross * @IndemProv, 2)
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
                N'Tasas del catalogo verificado para el periodo' AS [provisiones_regla],
                i.Aguinaldo AS [provision_aguinaldo],
                i.VacacionesProv AS [provision_vacaciones],
                i.IndemnizacionProv AS [provision_indemnizacion],
                i.EmployerCost AS [costo_total_empresa],
                @InssLab AS [tasa_inss_laboral],
                @InssPat AS [tasa_inss_patronal],
                @Inatec AS [tasa_inatec],
                @StartDate AS [vigencia_inicio],@EndDate AS [vigencia_fin],JSON_QUERY(@RulesSnapshot) AS [reglas_aplicadas]
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

        UPDATE dbo.PayrollRuns SET ReviewedAt=NULL,ReviewedByAppUserId=NULL,ApprovedAt=NULL,ApprovedByAppUserId=NULL
        WHERE PayrollRunId=@PayrollRunId;
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
CREATE OR ALTER PROCEDURE dbo.usp_TransitionPayrollStatus
    @PayrollRunId       NVARCHAR(100),
    @ExpectedRevision   VARBINARY(8),
    @TargetStatus       NVARCHAR(30),
    @Notes              NVARCHAR(1000) = NULL,
    @ActorId            NVARCHAR(100),
    @ActorName          NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(30);
    DECLARE @PreparedBy NVARCHAR(100);
    DECLARE @Period NVARCHAR(40);
    DECLARE @NetTotal DECIMAL(19,4);
    DECLARE @GrossTotal DECIMAL(19,4);
    DECLARE @InssPatronal DECIMAL(19,4);
    DECLARE @Inatec DECIMAL(19,4);
    DECLARE @InssLaboral DECIMAL(19,4);
    DECLARE @IncomeTax DECIMAL(19,4);
    DECLARE @AguinaldoProv DECIMAL(19,4);
    DECLARE @VacacionesProv DECIMAL(19,4);
    DECLARE @IndemnizacionProv DECIMAL(19,4);
    DECLARE @CurrentRev VARBINARY(8);

    BEGIN TRY
        BEGIN TRANSACTION;
    SELECT @CurrentStatus = Status,
           @PreparedBy = PreparedByAppUserId,
           @Period = Period,
           @NetTotal = Net,
           @GrossTotal = Gross,
           @InssPatronal = InssPatronal,
           @Inatec = Inatec,
           @InssLaboral = InssLaboral,
           @IncomeTax = IncomeTax,
           @AguinaldoProv = AguinaldoProvTotal,
           @VacacionesProv = VacacionesProvTotal,
           @IndemnizacionProv = IndemnizacionProvTotal,
           @CurrentRev = CONVERT(VARBINARY(8), Revision)
    FROM dbo.PayrollRuns WITH (UPDLOCK, HOLDLOCK)
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50506, 'La planilla no existe.', 1;

    IF @ExpectedRevision IS NULL OR @CurrentRev <> @ExpectedRevision
        THROW 50507, 'La planilla fue actualizada por otro usuario. Recarga la información.', 1;

    IF @TargetStatus NOT IN(N'borrador',N'calculada',N'revisada',N'aprobada',N'pago_registrado',N'conciliada',N'cerrada')
        THROW 50621,'Estado de destino invalido.',1;
    IF @TargetStatus IN(N'borrador',N'calculada') AND (@CurrentStatus IN(N'aprobada',N'pago_registrado',N'conciliada',N'cerrada')
        OR EXISTS(SELECT 1 FROM dbo.PayrollPayments WHERE PayrollRunId=@PayrollRunId AND Status=N'confirmado'))
        THROW 50621,'Una planilla con devengo aprobado o pagos requiere un reverso o ajuste, no retroceso directo.',1;
    IF @TargetStatus IN(N'revisada',N'aprobada') AND EXISTS(SELECT 1 FROM dbo.PayrollRuns r WHERE PayrollRunId=@PayrollRunId AND
        (ABS(r.Gross-r.TotalDeductions-r.Net)>0.01 OR r.TotalDeductions<>(SELECT ISNULL(SUM(TotalDeductions),0) FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId)))
        THROW 50621,'Los importes de cabecera y detalle no son coherentes.',1;
    -- Validaciones de flujo de transición
    IF @TargetStatus = N'revisada'
    BEGIN
        IF @CurrentStatus <> N'calculada'
            THROW 50508, 'Solo se puede marcar como revisada una planilla en estado calculada.', 1;

        IF EXISTS (SELECT 1 FROM dbo.PayrollValidations WHERE PayrollRunId = @PayrollRunId AND Severity = N'bloqueante' AND IsResolved = 0)
            THROW 50509, 'No se puede avanzar a revisada mientras existan observaciones bloqueantes sin resolver.', 1;
    END
    ELSE IF @TargetStatus = N'aprobada'
    BEGIN
        IF @CurrentStatus <> N'revisada'
            THROW 50510, 'Solo se puede aprobar una planilla previamente revisada.', 1;

        -- Separación de funciones: quien preparó o calculó no debe auto-aprobar
        IF @ActorId = @PreparedBy OR EXISTS(SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId=@PayrollRunId AND CalculatedByAppUserId=@ActorId)
            THROW 50511, 'Separación de funciones requerida: La planilla debe ser aprobada por una persona distinta a quien la preparó.', 1;
    END
    ELSE IF @TargetStatus = N'pago_registrado'
    BEGIN
        IF @CurrentStatus <> N'aprobada'
            THROW 50512, 'Solo se puede registrar pago a una planilla aprobada.', 1;
    END
    ELSE IF @TargetStatus = N'conciliada'
    BEGIN
        IF @CurrentStatus <> N'pago_registrado'
            THROW 50513, 'Solo se puede conciliar una planilla con pagos registrados.', 1;
    END
    ELSE IF @TargetStatus = N'cerrada'
    BEGIN
        IF @CurrentStatus <> N'conciliada'
            THROW 50514, 'Solo se puede cerrar formalmente una planilla debidamente conciliada.', 1;
    END
    ELSE IF @TargetStatus IN (N'borrador', N'calculada') -- Retrocesos autorizados
    BEGIN
        IF @CurrentStatus IN (N'conciliada', N'cerrada')
            THROW 50515, 'Una planilla conciliada o cerrada no puede retroceder. Requiere una planilla complementaria de ajuste.', 1;
        IF NULLIF(LTRIM(RTRIM(@Notes)), N'') IS NULL
            THROW 50516, 'Debes documentar el motivo formal para devolver o retroceder la planilla.', 1;
    END;

        -- ---------------------------------------------------------------------------
        -- 26: bloqueos de integridad del flujo de nomina.
        -- Borrador -> Calculada -> Revisada -> Aprobada -> Pago registrado ->
        -- Conciliada -> Cerrada. El servidor exige calculo confirmado y pago real.
        -- ---------------------------------------------------------------------------
        DECLARE @CalculatedAt DATETIMEOFFSET(3);
        DECLARE @CalcStale BIT;
        DECLARE @ConfirmedTotal DECIMAL(19,4);

        SELECT @CalculatedAt = CalculatedAt,
               @CalcStale = ISNULL(CalculationStale, 0),
               @ConfirmedTotal = (SELECT ISNULL(SUM(Amount),0) FROM dbo.PayrollPayments WHERE PayrollRunId=@PayrollRunId AND Status=N'confirmado')
        FROM dbo.PayrollRuns
        WHERE PayrollRunId = @PayrollRunId;

        IF @TargetStatus IN (N'calculada', N'revisada', N'aprobada') AND @CalculatedAt IS NULL
            THROW 50593, 'La planilla no tiene un calculo confirmado. Ejecute el calculo antes de avanzar de estado.', 1;

        IF @TargetStatus IN (N'revisada', N'aprobada') AND @CalcStale = 1
            THROW 50594, 'El calculo quedo desactualizado por cambios en trabajadores o novedades. Recalcula antes de revisar o aprobar.', 1;

        IF @TargetStatus = N'pago_registrado' AND @ConfirmedTotal <= 0
            THROW 50596, 'No hay pagos confirmados para esta planilla. Registre el pago del neto pendiente antes de marcar el estado.', 1;

        IF @TargetStatus IN (N'conciliada', N'cerrada') AND @ConfirmedTotal <> @NetTotal
            THROW 50597, 'La planilla aun tiene saldo pendiente por pagar; no puede conciliarse ni cerrarse.', 1;

        IF @TargetStatus IN(N'pago_registrado',N'conciliada',N'cerrada') AND EXISTS(SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId=@PayrollRunId AND ISNULL(ConfirmedPaymentsTotal,0)<>@ConfirmedTotal)
            THROW 50621,'El acumulado de pagos no coincide con los recibos confirmados. Requiere conciliacion.',1;
        IF @TargetStatus IN(N'conciliada',N'cerrada') AND (NULLIF(LTRIM(RTRIM(@Notes)),N'') IS NULL
            OR EXISTS(SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId=@PayrollRunId AND ISNULL(PendingDiscrepancyTotal,0)<>0))
            THROW 50621,'Documenta la conciliacion y resuelve las diferencias antes de conciliar o cerrar.',1;
        -- Actualizar campos según la fase
        IF @TargetStatus = N'revisada'
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = N'revisada',
                ReviewedByAppUserId = @ActorId,
                ReviewedAt = SYSUTCDATETIME(),
                ReviewNotes = @Notes,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;
        END
        ELSE IF @TargetStatus = N'aprobada'
        BEGIN
            IF EXISTS(SELECT 1 FROM dbo.AccountingEntries WHERE PayrollRunId=@PayrollRunId)
                OR EXISTS(SELECT 1 FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId=@PayrollRunId)
                THROW 50621,'La planilla ya tiene devengo u obligaciones. Requiere revision de origen, no recontabilizacion automatica.',1;
            -- Generar Asiento Contable Equilibrado de Nómina (Partida Doble)
            DECLARE @EntryId NVARCHAR(100) = N'entry-nom-' + @PayrollRunId;
            DECLARE @EntryNumber NVARCHAR(80) = N'AST-NOM-' + REPLACE(@Period, N' ', N'-');

            -- Verificar si ya existe asiento para actualizar o crear
            IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryId)
            BEGIN
                -- 1. Asiento de Gasto de Nómina vs Pasivos Laborales
                -- Débito: Gasto de Nómina (Devengado)
                -- Crédito: Sueldos por pagar (Neto), INSS por pagar (Laboral), IR por pagar (Laboral)
                DECLARE @OtherDeductions DECIMAL(19,4)=@GrossTotal-@NetTotal-@InssLaboral-@IncomeTax;
                IF @OtherDeductions<0 THROW 50621,'Las deducciones no cuadran con el devengado.',1;
                INSERT dbo.AccountingEntries(AccountingEntryId,EntryNumber,Description,Debit,Credit,DebitAccount,CreditAccount,EntryDate,ReferenceType,ReferenceId,PayrollRunId,OperationKey)
                SELECT @EntryId+suffix,LEFT(@EntryNumber,60)+suffix,N'Devengo separado: '+accountName,amount,amount,N'Nómina',accountName,
                    SYSUTCDATETIME(),N'payroll',@PayrollRunId,@PayrollRunId,N'nomina-devengo:'+@PayrollRunId+suffix
                FROM (VALUES(N'',N'Sueldos por pagar',@NetTotal),(N'-inss',N'INSS por pagar',@InssLaboral),
                    (N'-ir',N'IR por pagar',@IncomeTax),(N'-otros',N'Otras deducciones por pagar',@OtherDeductions)) v(suffix,accountName,amount)
                WHERE amount>0;

                -- 2. Asiento de Cargas Sociales Patronales (INSS Patronal + INATEC)
                DECLARE @EntryPatronalId NVARCHAR(100) = N'entry-pat-' + @PayrollRunId;
                DECLARE @EntryPatronalNum NVARCHAR(80) = N'AST-PAT-' + REPLACE(@Period, N' ', N'-');
                DECLARE @TotalCargasPatronales DECIMAL(19,4) = @InssPatronal + @Inatec;

                IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryPatronalId)
                BEGIN
                    INSERT dbo.AccountingEntries(AccountingEntryId,EntryNumber,Description,Debit,Credit,DebitAccount,CreditAccount,EntryDate,ReferenceType,ReferenceId,PayrollRunId,OperationKey)
                    SELECT @EntryPatronalId+suffix,LEFT(@EntryPatronalNum,60)+suffix,N'Aporte patronal separado: '+accountName,amount,amount,
                        N'Aporte patronal INSS e INATEC',accountName,SYSUTCDATETIME(),N'payroll',@PayrollRunId,@PayrollRunId,N'nomina-devengo:'+@PayrollRunId+N'-pat'+suffix
                    FROM (VALUES(N'',N'INSS por pagar',@InssPatronal),(N'-inatec',N'INATEC por pagar',@Inatec)) v(suffix,accountName,amount)
                    WHERE amount>0;
                END;

                -- 3. Asiento de Provisiones Laborales (Aguinaldo, Vacaciones, Antigüedad)
                DECLARE @EntryProvId NVARCHAR(100) = N'entry-prov-' + @PayrollRunId;
                DECLARE @EntryProvNum NVARCHAR(80) = N'AST-PROV-' + REPLACE(@Period, N' ', N'-');
                DECLARE @TotalProvisiones DECIMAL(19,4) = @AguinaldoProv + @VacacionesProv + @IndemnizacionProv;

                IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryProvId)
                BEGIN
                    INSERT INTO dbo.AccountingEntries (
                        AccountingEntryId, EntryNumber, Description, Debit, Credit,
                        DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId, PayrollRunId
                    )
                    VALUES (
                        @EntryProvId, @EntryProvNum,
                        N'Provisiones de prestaciones de ley (Aguinaldo, Vacaciones, Antigüedad) período ' + @Period,
                        @TotalProvisiones, @TotalProvisiones,
                        N'Gasto prestaciones y provisiones', N'Provisiones laborales por pagar',
                        TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), N'payroll', @PayrollRunId, @PayrollRunId
                    );
                END;
            END;

            UPDATE dbo.PayrollRuns
            SET Status = N'aprobada',
                ApprovedByAppUserId = @ActorId,
                ApprovedAt = SYSUTCDATETIME(),
                ApprovalNotes = @Notes,
                AccountingEntryId = @EntryId,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            -- Habilitar los comprobantes individuales
            UPDATE dbo.PayrollRunItems
            SET ReceiptStatus = N'disponible'
            WHERE PayrollRunId = @PayrollRunId;

            -- Generar seguimiento de obligaciones institucionales (DGI, INSS, INATEC)
            DELETE FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId = @PayrollRunId;

            INSERT INTO dbo.PayrollInstitutionalObligations (
                ObligationId, PayrollRunId, EntityName, PeriodLabel, BaseAmount, PayableAmount, DueDate, Status
            )
            VALUES
                (N'ob-ir-' + @PayrollRunId, @PayrollRunId, N'DGI', @Period, @GrossTotal - @InssLaboral, @IncomeTax, NULL, N'pendiente_vencimiento'),
                (N'ob-inss-' + @PayrollRunId, @PayrollRunId, N'INSS', @Period, @GrossTotal, (@InssLaboral + @InssPatronal), DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente_vencimiento'),
                (N'ob-inatec-' + @PayrollRunId, @PayrollRunId, N'INATEC', @Period, @GrossTotal, @Inatec, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente_vencimiento'),
                (N'ob-prov-' + @PayrollRunId, @PayrollRunId, N'PROVISIONES_PASIVO', @Period, @GrossTotal, (@AguinaldoProv + @VacacionesProv + @IndemnizacionProv), NULL, N'provisionada');
        END
        ELSE IF @TargetStatus = N'pago_registrado'
        BEGIN
            -- 26: la unica salida de dinero la registra usp_RegisterPayrollPayment
            -- (pagos parciales acumulados e idempotentes). La transicion solo marca el
            -- estado a partir de pagos ya confirmados: no crea un segundo gasto ni
            -- sobrescribe el acumulado de pagos.
            DECLARE @CashId NVARCHAR(100) = N'cash-nom-' + @PayrollRunId;

            UPDATE dbo.PayrollRuns
            SET Status = N'pago_registrado',
                PaidByAppUserId = @ActorId,
                PaidAt = CASE WHEN @ConfirmedTotal=@NetTotal THEN TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00') ELSE NULL END,
                PaymentNotes = @Notes,
                CashMoveId = NULL, -- los movimientos se consultan en los recibos individuales
                PendingDiscrepancyTotal = 0,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            UPDATE dbo.PayrollRunItems
            SET PaymentStatus = N'pagado',
                PaymentConfirmedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
            WHERE PayrollRunId = @PayrollRunId
              AND ISNULL(PaymentStatus, N'') <> N'pagado'
              AND @ConfirmedTotal >= @NetTotal;
        END
        ELSE IF @TargetStatus = N'conciliada'
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = N'conciliada',
                ReconciledByAppUserId = @ActorId,
                ReconciledAt = SYSUTCDATETIME(),
                ReconciliationNotes = @Notes,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            UPDATE dbo.PayrollRunItems
            SET PaymentStatus = N'conciliado'
            WHERE PayrollRunId = @PayrollRunId;
        END
        ELSE IF @TargetStatus = N'cerrada'
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = N'cerrada',
                ClosedByAppUserId = @ActorId,
                ClosedAt = SYSUTCDATETIME(),
                CloseNotes = @Notes,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            -- Las obligaciones existentes conservan sus referencias, estados y vencimientos.

        END
        ELSE -- Retroceso a borrador o calculada
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = @TargetStatus,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;
        END;

        -- Registrar Evento de Auditoría
        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName,
            CASE WHEN @TargetStatus = N'revisada' THEN N'revision'
                 WHEN @TargetStatus = N'aprobada' THEN N'aprobacion'
                 WHEN @TargetStatus = N'pago_registrado' THEN N'pago'
                 WHEN @TargetStatus = N'conciliada' THEN N'conciliacion'
                 WHEN @TargetStatus = N'cerrada' THEN N'cierre'
                 ELSE N'devolucion' END,
            @CurrentStatus, @TargetStatus,
            ISNULL(@Notes, N'Transición de estado autorizada en el flujo de nómina.')
        );

        -- 26: identificar los efectos confirmados por el servidor (caja, asientos y
        -- finanzas) para que el snapshot del navegador no los borre ni los reconstruya.
        UPDATE dbo.AccountingEntries
        SET OperationKey = N'nomina:' + AccountingEntryId
        WHERE PayrollRunId = @PayrollRunId AND OperationKey IS NULL;

        UPDATE dbo.CashMoves
        SET OperationKey = N'nomina:' + @PayrollRunId
        WHERE PayrollRunId = @PayrollRunId AND OperationKey IS NULL;

        UPDATE dbo.FinanceMoves
        SET OperationKey = N'nomina:' + FinanceMoveId
        WHERE FinanceMoveId = N'fn-nom-' + @PayrollRunId AND OperationKey IS NULL;
        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.Gross AS grossTotal, r.Net AS netTotal,
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
CREATE OR ALTER PROCEDURE dbo.usp_PayrollAccrualIntegrityVersion AS SELECT 31 AS version;
GO
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
 GRANT EXECUTE ON dbo.usp_CalculatePayroll TO [raquel_erp_app];
 GRANT EXECUTE ON dbo.usp_TransitionPayrollStatus TO [raquel_erp_app];
 GRANT EXECUTE ON dbo.usp_PayrollAccrualIntegrityVersion TO [raquel_erp_app];
END;
GO
