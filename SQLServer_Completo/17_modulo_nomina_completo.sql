/* ==============================================================================
   17 — MÓDULO INTEGRAL DE NÓMINA, PRESTACIONES Y CUMPLIMIENTO LABORAL (NICARAGUA)
   Instalaciones Raquel — Aluminio, Vidrio y Fachadas Arquitectónicas
   Fundamento Legal: Ley 185 (Código del Trabajo), Ley 822 (LCT) y Reglamento,
                     Ley de Seguridad Social (INSS), Ley INATEC y Ley 787.
   ============================================================================== */

USE [Instalaciones Raquel];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1. PLAN DE CUENTAS: Asegurar cuentas de nómina y pasivos laborales
-- -----------------------------------------------------------------------------
MERGE dbo.ChartOfAccounts AS target
USING (VALUES
    (N'Nómina', N'gasto'),
    (N'Aporte patronal INSS e INATEC', N'gasto'),
    (N'Gasto prestaciones y provisiones', N'gasto'),
    (N'Sueldos por pagar', N'pasivo'),
    (N'INSS por pagar', N'pasivo'),
    (N'IR por pagar', N'pasivo'),
    (N'INATEC por pagar', N'pasivo'),
    (N'Provisiones laborales por pagar', N'pasivo'),
    (N'Banco', N'activo'),
    (N'Caja', N'activo')
) AS src (AccountName, AccountType)
ON (target.AccountName = src.AccountName)
WHEN MATCHED AND target.AccountType <> src.AccountType THEN
    UPDATE SET target.AccountType = src.AccountType
WHEN NOT MATCHED THEN
    INSERT (AccountName, AccountType) VALUES (src.AccountName, src.AccountType);
GO

-- -----------------------------------------------------------------------------
-- 2. CATÁLOGO DE REGLAS NORMATIVAS Y PARÁMETROS (NICARAGUA)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollRulesCatalog', N'U') IS NULL
CREATE TABLE dbo.PayrollRulesCatalog
(
    RuleId           NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollRulesCatalog PRIMARY KEY,
    RuleCode         NVARCHAR(40)  NOT NULL CONSTRAINT UQ_PayrollRulesCatalog_Code UNIQUE,
    RuleName         NVARCHAR(200) NOT NULL,
    LawReference     NVARCHAR(300) NOT NULL,
    OfficialSource   NVARCHAR(300) NOT NULL,
    EffectiveFrom    DATE          NOT NULL,
    EffectiveTo      DATE          NULL,
    ParameterJson    NVARCHAR(MAX) NOT NULL,
    IsVerified       BIT           NOT NULL CONSTRAINT DF_PayrollRules_IsVerified DEFAULT (1),
    ReviewedBy       NVARCHAR(200) NOT NULL,
    ReviewedAt       DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollRules_ReviewedAt DEFAULT (SYSUTCDATETIME()),
    Status           NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollRules_Status DEFAULT (N'vigente')
);
GO

MERGE dbo.PayrollRulesCatalog AS target
USING (VALUES
    (N'rule-inss-lab', N'INSS_LABORAL', N'Aporte Laboral INSS (7.0%)',
     N'Ley de Seguridad Social, Art. 16 y Decreto Ejecutivo No. 06-2019',
     N'La Gaceta, Diario Oficial No. 22', '2019-02-01', NULL,
     N'{"rate": 0.07, "cap": null, "description": "Deducción del 7% sobre el total devengado sin techo salarial."}',
     1, N'María Contadora', N'vigente'),

    (N'rule-inss-pat', N'INSS_PATRONAL', N'Aporte Patronal INSS (21.5% / 22.5%)',
     N'Ley de Seguridad Social, Decreto Ejecutivo No. 06-2019',
     N'La Gaceta, Diario Oficial No. 22', '2019-02-01', NULL,
     N'{"rate_standard": 0.225, "rate_large": 0.215, "threshold_workers": 50, "rate_used": 0.215, "description": "21.5% para empresas con más de 50 trabajadores, 22.5% hasta 50 trabajadores."}',
     1, N'María Contadora', N'vigente'),

    (N'rule-inatec', N'INATEC_PATRONAL', N'Aporte Patronal INATEC (2.0%)',
     N'Decreto Ley No. 3-91 y Ley Orgánica de INATEC',
     N'La Gaceta, Diario Oficial No. 71', '1991-04-18', NULL,
     N'{"rate": 0.02, "description": "Aporte patronal del 2% sobre nómina para capacitación técnica."}',
     1, N'María Contadora', N'vigente'),

    (N'rule-ir-prog', N'IR_PROGRESIVO', N'Retención IR Salarial Progresiva',
     N'Ley 822 (LCT), Art. 23 y Art. 96 (Tarifa Progresiva)',
     N'La Gaceta No. 241 con reformas vigentes DGI', '2013-01-01', NULL,
     N'{"brackets": [{"from": 0.01, "to": 100000.0, "rate": 0.0, "base": 0.0, "excess": 0.0}, {"from": 100000.01, "to": 200000.0, "rate": 0.15, "base": 0.0, "excess": 100000.0}, {"from": 200000.01, "to": 350000.0, "rate": 0.20, "base": 15000.0, "excess": 200000.0}, {"from": 350000.01, "to": 500000.0, "rate": 0.25, "base": 45000.0, "excess": 350000.0}, {"from": 500000.01, "to": null, "rate": 0.30, "base": 82500.0, "excess": 500000.0}], "exemption_base": "Ingreso gravable anualizado menos INSS laboral anualizado."}',
     1, N'María Contadora', N'vigente'),

    (N'rule-aguinaldo', N'AGUINALDO_PROV', N'Décimo Tercer Mes / Aguinaldo (8.3333%)',
     N'Código del Trabajo (Ley 185), Artículos 93 a 99',
     N'La Gaceta No. 205', '1996-10-30', NULL,
     N'{"rate": 0.083333, "fraction": "1/12", "description": "Un mes de salario ordinario por año de trabajo continuo o proporcional."}',
     1, N'Raquel López', N'vigente'),

    (N'rule-vacaciones', N'VACACIONES_PROV', N'Vacaciones Remuneradas (8.3333%)',
     N'Código del Trabajo (Ley 185), Artículos 76 a 81',
     N'La Gaceta No. 205', '1996-10-30', NULL,
     N'{"rate": 0.083333, "days_per_semester": 15, "description": "15 días continuos de descanso remunerado por cada seis meses de labor continua (2.5 días/mes)."}',
     1, N'Raquel López', N'vigente'),

    (N'rule-antiguedad', N'INDEMNIZACION_PROV', N'Indemnización por Años de Servicio (8.3333%)',
     N'Código del Trabajo (Ley 185), Artículo 45',
     N'La Gaceta No. 205', '1996-10-30', NULL,
     N'{"rate": 0.083333, "rules": "1 mes por cada uno de los primeros 3 años; 20 días por año a partir del 4to año; tope 5 meses.", "description": "Provisión técnica mensual para pasivo laboral por antigüedad."}',
     1, N'Raquel López', N'vigente'),

    (N'rule-horas-extra', N'HORA_EXTRA_RECARGO', N'Horas Extraordinarias (Recargo 100%)',
     N'Código del Trabajo (Ley 185), Artículos 57 y 58',
     N'La Gaceta No. 205', '1996-10-30', NULL,
     N'{"multiplier": 2.0, "max_weekly_hours": 9, "divisor_monthly": 240, "description": "La hora extraordinaria se remunera con el doble del valor de la hora ordinaria."}',
     1, N'Carlos Producción', N'vigente')
) AS src (RuleId, RuleCode, RuleName, LawReference, OfficialSource, EffectiveFrom, EffectiveTo, ParameterJson, IsVerified, ReviewedBy, Status)
ON (target.RuleId = src.RuleId)
WHEN MATCHED THEN
    UPDATE SET target.RuleCode = src.RuleCode, target.RuleName = src.RuleName,
               target.LawReference = src.LawReference, target.OfficialSource = src.OfficialSource,
               target.EffectiveFrom = src.EffectiveFrom, target.ParameterJson = src.ParameterJson,
               target.IsVerified = src.IsVerified, target.ReviewedBy = src.ReviewedBy, target.Status = src.Status
WHEN NOT MATCHED THEN
    INSERT (RuleId, RuleCode, RuleName, LawReference, OfficialSource, EffectiveFrom, EffectiveTo, ParameterJson, IsVerified, ReviewedBy, Status)
    VALUES (src.RuleId, src.RuleCode, src.RuleName, src.LawReference, src.OfficialSource, src.EffectiveFrom, src.EffectiveTo, src.ParameterJson, src.IsVerified, src.ReviewedBy, src.Status);
GO

-- -----------------------------------------------------------------------------
-- 3. CABECERA DE PLANILLA DE NÓMINA (dbo.PayrollRuns)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollRuns', N'U') IS NOT NULL
BEGIN
    -- Asegurar columnas avanzadas si la tabla fue creada en la versión básica
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PeriodType') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PeriodType NVARCHAR(30) NOT NULL CONSTRAINT DF_PayrollRuns_PeriodType DEFAULT (N'quincenal');
    IF COL_LENGTH(N'dbo.PayrollRuns', N'StartDate') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD StartDate DATE NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'EndDate') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD EndDate DATE NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PaymentDate') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PaymentDate DATE NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'Status') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD Status NVARCHAR(30) NOT NULL CONSTRAINT DF_PayrollRuns_Status DEFAULT (N'borrador');
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CalculationVersion') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CalculationVersion INT NOT NULL CONSTRAINT DF_PayrollRuns_CalcVer DEFAULT (1);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'OtherDeductionsTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD OtherDeductionsTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_OtherDed DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'AguinaldoProvTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD AguinaldoProvTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_AguiProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'VacacionesProvTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD VacacionesProvTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_VacProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'IndemnizacionProvTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD IndemnizacionProvTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_IndemProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ConfirmedPaymentsTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ConfirmedPaymentsTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_ConfPay DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PendingDiscrepancyTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PendingDiscrepancyTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_PendDisc DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PreparedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PreparedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_PrepUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PreparedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PreparedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CalculatedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CalculatedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_CalcUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CalculatedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CalculatedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReviewedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReviewedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_RevUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReviewedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReviewedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReviewNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReviewNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ApprovedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ApprovedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_ApprUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ApprovedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ApprovedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ApprovalNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ApprovalNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PaidByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PaidByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_PaidUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PaymentNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PaymentNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReconciledByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReconciledByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_ReconUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReconciledAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReconciledAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReconciliationNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReconciliationNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ClosedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ClosedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_CloseUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ClosedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ClosedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CloseNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CloseNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'AccountingEntryId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD AccountingEntryId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_AcctEntry FOREIGN KEY REFERENCES dbo.AccountingEntries(AccountingEntryId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CashMoveId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CashMoveId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_CashMove FOREIGN KEY REFERENCES dbo.CashMoves(CashMoveId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'Notes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD Notes NVARCHAR(MAX) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'Revision') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD Revision ROWVERSION NOT NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CreatedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollRuns_CreatedAt DEFAULT (SYSUTCDATETIME());
    IF COL_LENGTH(N'dbo.PayrollRuns', N'UpdatedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD UpdatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollRuns_UpdatedAt DEFAULT (SYSUTCDATETIME());
END;
GO

-- -----------------------------------------------------------------------------
-- 4. DETALLE DE TRABAJADORES EN PLANILLA (dbo.PayrollRunItems)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollRunItems', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PayrollItemId') IS NULL
    BEGIN
        ALTER TABLE dbo.PayrollRunItems ADD PayrollItemId NVARCHAR(100) NULL;
        EXEC(N'UPDATE dbo.PayrollRunItems SET PayrollItemId = PayrollRunId + N''-'' + EmployeeId WHERE PayrollItemId IS NULL;');
        ALTER TABLE dbo.PayrollRunItems ALTER COLUMN PayrollItemId NVARCHAR(100) NOT NULL;
    END;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PositionSnapshot') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PositionSnapshot NVARCHAR(200) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'AreaSnapshot') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD AreaSnapshot NVARCHAR(120) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'BaseSalaryMonthly') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD BaseSalaryMonthly DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_BaseSal DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PeriodDaysWorked') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PeriodDaysWorked DECIMAL(9,2) NOT NULL CONSTRAINT DF_PayrollRunItems_DaysWorked DEFAULT (15);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PeriodHoursWorked') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PeriodHoursWorked DECIMAL(9,2) NOT NULL CONSTRAINT DF_PayrollRunItems_HoursWorked DEFAULT (120);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OrdinarySalary') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OrdinarySalary DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_OrdSal DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OvertimeHours') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OvertimeHours DECIMAL(9,2) NOT NULL CONSTRAINT DF_PayrollRunItems_OtHours DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OvertimeAmount') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OvertimeAmount DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_OtAmt DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'BonusesAmount') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD BonusesAmount DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_Bonuses DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'CommissionsAmount') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD CommissionsAmount DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_Commissions DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'VacationDisfruteAmount') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD VacationDisfruteAmount DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_VacDisfrute DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OtherTaxableIncome') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OtherTaxableIncome DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_OtherInc DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'InssBase') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD InssBase DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_InssBase DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'IrBase') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD IrBase DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_IrBase DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OtherDeductions') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OtherDeductions DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_OtherDed DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'TotalDeductions') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD TotalDeductions DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_TotDed DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'VacacionesProv') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD VacacionesProv DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_VacProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'IndemnizacionProv') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD IndemnizacionProv DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_IndemProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PaymentStatus') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PaymentStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_PayrollRunItems_PayStat DEFAULT (N'pendiente');
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PaymentMethod') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PaymentMethod NVARCHAR(40) NOT NULL CONSTRAINT DF_PayrollRunItems_PayMethod DEFAULT (N'transferencia_bancaria');
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PaymentReference') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PaymentReference NVARCHAR(120) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PaymentConfirmedAt') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PaymentConfirmedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'CalculationExplanationJson') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD CalculationExplanationJson NVARCHAR(MAX) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'HasDiscrepancy') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD HasDiscrepancy BIT NOT NULL CONSTRAINT DF_PayrollRunItems_HasDisc DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'DiscrepancyReason') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD DiscrepancyReason NVARCHAR(500) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'ReceiptStatus') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD ReceiptStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_PayrollRunItems_RcptStat DEFAULT (N'no_generado');
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'Revision') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD Revision ROWVERSION NOT NULL;
END;
GO

-- -----------------------------------------------------------------------------
-- 5. NOVEDADES DEL PERÍODO (dbo.PayrollNovelties)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollNovelties', N'U') IS NULL
CREATE TABLE dbo.PayrollNovelties
(
    NoveltyId           NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollNovelties PRIMARY KEY,
    PayrollRunId        NVARCHAR(100) NULL CONSTRAINT FK_PayrollNovelties_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE SET NULL,
    EmployeeId          NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollNovelties_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    NoveltyType         NVARCHAR(40)  NOT NULL,
    Concept             NVARCHAR(240) NOT NULL,
    Amount              DECIMAL(19,4) NOT NULL,
    Hours               DECIMAL(9,2)  NULL,
    LegalJustification  NVARCHAR(500) NULL,
    DocReference        NVARCHAR(300) NULL,
    PeriodDate          DATE          NOT NULL,
    Status              NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollNovelties_Status DEFAULT (N'autorizada'),
    CreatedByAppUserId  NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollNovelties_User FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    AuthorizedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollNovelties_AuthUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    AuthorizedAt        DATETIMEOFFSET(3) NULL,
    CreatedAt           DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollNovelties_CreatedAt DEFAULT (SYSUTCDATETIME()),
    Revision            ROWVERSION NOT NULL
);
GO

-- -----------------------------------------------------------------------------
-- 6. VALIDACIONES DE REGLAS DE NÓMINA (dbo.PayrollValidations)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollValidations', N'U') IS NULL
CREATE TABLE dbo.PayrollValidations
(
    ValidationId        NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollValidations PRIMARY KEY,
    PayrollRunId        NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollValidations_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EmployeeId          NVARCHAR(100) NULL CONSTRAINT FK_PayrollValidations_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    Severity            NVARCHAR(20)  NOT NULL CONSTRAINT CK_PayrollValidations_Severity CHECK (Severity IN (N'bloqueante', N'advertencia', N'informativa')),
    RuleCode            NVARCHAR(50)  NOT NULL,
    Message             NVARCHAR(500) NOT NULL,
    TargetTab           NVARCHAR(40)  NOT NULL CONSTRAINT DF_PayrollValidations_Tab DEFAULT (N'trabajadores'),
    IsResolved          BIT           NOT NULL CONSTRAINT DF_PayrollValidations_IsResolved DEFAULT (0),
    ResolvedAt          DATETIMEOFFSET(3) NULL,
    ResolvedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollValidations_User FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    CreatedAt           DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollValidations_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

-- -----------------------------------------------------------------------------
-- 7. DISTRIBUCIÓN DE COSTOS DE NÓMINA A PROYECTOS (dbo.PayrollProjectDistributions)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollProjectDistributions', N'U') IS NULL
CREATE TABLE dbo.PayrollProjectDistributions
(
    DistributionId      NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollProjectDistributions PRIMARY KEY,
    PayrollRunId        NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollProjDist_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EmployeeId          NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollProjDist_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    ProjectId           NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollProjDist_Proj FOREIGN KEY REFERENCES dbo.Projects(ProjectId),
    ProductionOrderId   NVARCHAR(100) NULL CONSTRAINT FK_PayrollProjDist_ProdOrder FOREIGN KEY REFERENCES dbo.ProductionOrders(ProductionOrderId),
    HoursAllocated      DECIMAL(9,2)  NOT NULL DEFAULT (0),
    PercentageAllocated DECIMAL(5,2)  NOT NULL DEFAULT (100.00),
    CostAllocated       DECIMAL(19,4) NOT NULL,
    Notes               NVARCHAR(500) NULL,
    ApprovedByAppUserId NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollProjDist_User FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    CreatedAt           DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollProjDist_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

-- -----------------------------------------------------------------------------
-- 8. REGISTRO DETALLADO DE PAGOS (dbo.PayrollPayments)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollPayments', N'U') IS NULL
CREATE TABLE dbo.PayrollPayments
(
    PaymentId               NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollPayments PRIMARY KEY,
    PayrollRunId            NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollPayments_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EmployeeId              NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollPayments_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    Amount                  DECIMAL(19,4) NOT NULL,
    PaymentMethod           NVARCHAR(40)  NOT NULL CONSTRAINT DF_PayrollPayments_Method DEFAULT (N'transferencia_bancaria'),
    BankName                NVARCHAR(100) NULL,
    AccountLast4            NVARCHAR(10)  NULL,
    TransactionReference    NVARCHAR(120) NULL,
    BatchNumber             NVARCHAR(60)  NULL,
    Status                  NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollPayments_Status DEFAULT (N'preparado'),
    ConfirmedAt             DATETIMEOFFSET(3) NULL,
    ConfirmedByAppUserId    NVARCHAR(100) NULL CONSTRAINT FK_PayrollPayments_ConfUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    ManualConfirmationProof NVARCHAR(300) NULL,
    CashMoveId              NVARCHAR(100) NULL CONSTRAINT FK_PayrollPayments_CashMove FOREIGN KEY REFERENCES dbo.CashMoves(CashMoveId),
    CreatedAt               DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollPayments_CreatedAt DEFAULT (SYSUTCDATETIME()),
    Revision                ROWVERSION NOT NULL
);
GO

-- -----------------------------------------------------------------------------
-- 9. SEGUIMIENTO DE OBLIGACIONES INSTITUCIONALES (dbo.PayrollInstitutionalObligations)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollInstitutionalObligations', N'U') IS NULL
CREATE TABLE dbo.PayrollInstitutionalObligations
(
    ObligationId            NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollInstOblig PRIMARY KEY,
    PayrollRunId            NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollInstOblig_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EntityName              NVARCHAR(50)  NOT NULL, -- DGI_IR, INSS_LABORAL, INSS_PATRONAL, INATEC, PROVISIONES_PASIVO
    PeriodLabel             NVARCHAR(50)  NOT NULL,
    BaseAmount              DECIMAL(19,4) NOT NULL,
    PayableAmount           DECIMAL(19,4) NOT NULL,
    DueDate                 DATE          NOT NULL,
    Status                  NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollInstOblig_Status DEFAULT (N'calculada'),
    DeclarationReference    NVARCHAR(120) NULL,
    PaymentReceiptRef       NVARCHAR(200) NULL,
    PaidAt                  DATETIMEOFFSET(3) NULL,
    PaidByAppUserId         NVARCHAR(100) NULL CONSTRAINT FK_PayrollInstOblig_User FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    Notes                   NVARCHAR(500) NULL,
    CreatedAt               DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollInstOblig_CreatedAt DEFAULT (SYSUTCDATETIME()),
    Revision                ROWVERSION NOT NULL
);
GO

-- -----------------------------------------------------------------------------
-- 10. ATENCIÓN AL TRABAJADOR: RECLAMOS SOBRE COMPROBANTE (dbo.PayrollReceiptTickets)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollReceiptTickets', N'U') IS NULL
CREATE TABLE dbo.PayrollReceiptTickets
(
    TicketId                NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollReceiptTickets PRIMARY KEY,
    PayrollItemId           NVARCHAR(100) NULL,
    PayrollRunId            NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollTickets_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId),
    EmployeeId              NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollTickets_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    TicketNumber            NVARCHAR(60)  NOT NULL CONSTRAINT UQ_PayrollTickets_Num UNIQUE,
    Subject                 NVARCHAR(200) NOT NULL,
    Description             NVARCHAR(1000) NOT NULL,
    Status                  NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollTickets_Status DEFAULT (N'abierto'),
    ResolutionNotes         NVARCHAR(1000) NULL,
    AssignedToAppUserId     NVARCHAR(100) NULL CONSTRAINT FK_PayrollTickets_Assigned FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    ResolvedByAppUserId     NVARCHAR(100) NULL CONSTRAINT FK_PayrollTickets_Resolved FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    CreatedAt               DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollTickets_CreatedAt DEFAULT (SYSUTCDATETIME()),
    ResolvedAt              DATETIMEOFFSET(3) NULL
);
GO

-- -----------------------------------------------------------------------------
-- 11. HISTORIAL Y TRAZABILIDAD DE EVENTOS DE NÓMINA (dbo.PayrollHistoryEvents)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollHistoryEvents', N'U') IS NULL
CREATE TABLE dbo.PayrollHistoryEvents
(
    EventId                 BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PayrollHistoryEvents PRIMARY KEY,
    PayrollRunId            NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollHistory_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    ActorId                 NVARCHAR(100) NOT NULL,
    ActorName               NVARCHAR(240) NOT NULL,
    EventType               NVARCHAR(40)  NOT NULL,
    PreviousStatus          NVARCHAR(30)  NULL,
    NewStatus               NVARCHAR(30)  NOT NULL,
    Description             NVARCHAR(1000) NOT NULL,
    CreatedAt               DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollHistory_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

-- -----------------------------------------------------------------------------
-- 12. PROCEDIMIENTO ALMACENADO: LISTADO DE PLANILLAS (usp_GetPayrollRuns)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollRuns
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.PayrollRunId AS id,
           r.Period AS period,
           r.PeriodType AS periodType,
           r.StartDate AS startDate,
           r.EndDate AS endDate,
           r.PaymentDate AS paymentDate,
           r.Status AS status,
           r.CalculationVersion AS calculationVersion,
           r.Gross AS grossTotal,
           r.InssLaboral AS inssLaboralTotal,
           r.IncomeTax AS incomeTaxTotal,
           r.OtherDeductionsTotal AS otherDeductionsTotal,
           (r.InssLaboral + r.IncomeTax + r.OtherDeductionsTotal) AS totalDeductions,
           r.Net AS netTotal,
           r.InssPatronal AS inssPatronalTotal,
           r.Inatec AS inatecTotal,
           r.AguinaldoProvTotal AS aguinaldoProvTotal,
           r.VacacionesProvTotal AS vacacionesProvTotal,
           r.IndemnizacionProvTotal AS indemnizacionProvTotal,
           r.EmployerCost AS employerCostTotal,
           r.ConfirmedPaymentsTotal AS confirmedPaymentsTotal,
           r.PendingDiscrepancyTotal AS pendingDiscrepancyTotal,
           r.Actor AS preparedByName,
           r.PreparedAt AS preparedAt,
           r.CalculatedAt AS calculatedAt,
           r.ReviewedAt AS reviewedAt,
           r.ApprovedAt AS approvedAt,
           r.PaidAt AS paidAt,
           r.ReconciledAt AS reconciledAt,
           r.ClosedAt AS closedAt,
           (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS workersCount,
           (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'bloqueante' AND IsResolved = 0) AS blockingIssuesCount,
           (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'advertencia' AND IsResolved = 0) AS warningIssuesCount,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision,
           r.UpdatedAt AS updatedAt
    FROM dbo.PayrollRuns r
    ORDER BY r.StartDate DESC, r.CreatedAt DESC;
END;
GO

-- -----------------------------------------------------------------------------
-- 13. PROCEDIMIENTO ALMACENADO: CREAR BORRADOR DE PLANILLA (usp_CreatePayrollDraft)
-- -----------------------------------------------------------------------------
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
        THROW 50501, 'Ya existe una planilla activa para el mismo período.', 1;

    IF @StartDate > @EndDate
        THROW 50502, 'La fecha de inicio no puede ser posterior a la fecha de finalización.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.PayrollRuns (
            PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate,
            PaidAt, Actor, ActorUserId, Status, CalculationVersion,
            Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost,
            OtherDeductionsTotal, AguinaldoProvTotal, VacacionesProvTotal, IndemnizacionProvTotal,
            ConfirmedPaymentsTotal, PendingDiscrepancyTotal,
            PreparedByAppUserId, PreparedAt, Notes
        )
        VALUES (
            @PayrollRunId, @Period, @PeriodType, @StartDate, @EndDate, @PaymentDate,
            TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), @ActorName, @ActorId, N'borrador', 1,
            0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0,
            @ActorId, SYSUTCDATETIME(), @Notes
        );

        -- Poblar automáticamente trabajadores activos de la empresa
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
            CASE WHEN @PeriodType = N'quincenal' THEN 15.0 ELSE 30.0 END,
            CASE WHEN @PeriodType = N'quincenal' THEN 120.0 ELSE 240.0 END,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            0, 0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            N'pendiente', N'transferencia_bancaria', N'no_generado'
        FROM dbo.Employees e
        WHERE e.EmploymentStatus = N'activo'
           OR (e.DismissalDate IS NOT NULL AND e.DismissalDate >= @StartDate);

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'creacion', NULL, N'borrador',
            N'Planilla creada en estado borrador con selección inicial de colaboradores.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.Gross AS grossTotal, r.Net AS netTotal,
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

-- -----------------------------------------------------------------------------
-- 14. PROCEDIMIENTO ALMACENADO: MOTOR DE CÁLCULO DE NÓMINA (usp_CalculatePayroll)
--     Aplica: Ley 185 (H.Extra recargo 100%, Provisiones 8.3333%),
--             Ley de Seguridad Social (INSS Lab 7%, Patronal 21.5%),
--             Ley 822 (IR progresivo anualizado LCT Art. 96), INATEC (2%)
-- -----------------------------------------------------------------------------
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

    SELECT @CurrentStatus = Status,
           @PeriodType = PeriodType,
           @CalcVer = CalculationVersion,
           @CurrentRev = CONVERT(VARBINARY(8), Revision)
    FROM dbo.PayrollRuns WITH (UPDLOCK, HOLDLOCK)
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50503, 'La planilla solicitada no existe.', 1;

    IF @CurrentRev <> @ExpectedRevision
        THROW 50504, 'La planilla fue modificada por otro usuario (revisión desfasada). Recarga la pantalla.', 1;

    IF @CurrentStatus IN (N'aprobada', N'pago_registrado', N'conciliada', N'cerrada')
        THROW 50505, 'No se puede recalcular una planilla que ya ha sido aprobada, pagada o cerrada.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Actualizar conceptos variables desde la tabla de novedades
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
                   SUM(CASE WHEN NoveltyType IN (N'deduccion_prestamo', N'otro_descuento') THEN Amount ELSE 0 END) AS TotalDed
            FROM dbo.PayrollNovelties
            WHERE EmployeeId = i.EmployeeId AND (PayrollRunId = @PayrollRunId OR PayrollRunId IS NULL)
              AND Status = N'autorizada'
        ) AS nov
        WHERE i.PayrollRunId = @PayrollRunId;

        -- 2. Calcular Devengado Bruto por Trabajador
        UPDATE dbo.PayrollRunItems
        SET Gross = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2),
            InssBase = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2)
        WHERE PayrollRunId = @PayrollRunId;

        -- 3. Calcular Deducciones de Ley (INSS Laboral 7.00%)
        UPDATE dbo.PayrollRunItems
        SET InssLaboral = ROUND(InssBase * 0.07, 2)
        WHERE PayrollRunId = @PayrollRunId;

        -- 4. Calcular Impuesto sobre la Renta del Trabajo (IR Laboral - Ley 822 Art. 23 & 96)
        --    Ingreso Anual Proyectado = (Devengado - INSS) * (12 si es mensual, 24 si es quincenal)
        UPDATE i
        SET i.IrBase = p.NetBasePeriod,
            i.IncomeTax = calc.IrPeriod
        FROM dbo.PayrollRunItems i
        CROSS APPLY (
            SELECT
                (i.Gross - i.InssLaboral) AS NetBasePeriod,
                CASE WHEN @PeriodType = N'quincenal'
                     THEN (i.Gross - i.InssLaboral) * 24.0
                     ELSE (i.Gross - i.InssLaboral) * 12.0
                END AS ProjectedAnnual
        ) AS p
        CROSS APPLY (
            SELECT
                CASE
                    -- Tramo 1: C$ 0.01 a C$ 100,000.00 -> Exento (0%)
                    WHEN p.ProjectedAnnual <= 100000.00 THEN 0.00

                    -- Tramo 2: C$ 100,000.01 a C$ 200,000.00 -> 15% sobre el exceso de C$ 100,000
                    WHEN p.ProjectedAnnual <= 200000.00 THEN
                        ROUND(((p.ProjectedAnnual - 100000.00) * 0.15) / CASE WHEN @PeriodType = N'quincenal' THEN 24.0 ELSE 12.0 END, 2)

                    -- Tramo 3: C$ 200,000.01 a C$ 350,000.00 -> C$ 15,000 + 20% sobre el exceso de C$ 200,000
                    WHEN p.ProjectedAnnual <= 350000.00 THEN
                        ROUND((15000.00 + (p.ProjectedAnnual - 200000.00) * 0.20) / CASE WHEN @PeriodType = N'quincenal' THEN 24.0 ELSE 12.0 END, 2)

                    -- Tramo 4: C$ 350,000.01 a C$ 500,000.00 -> C$ 45,000 + 25% sobre el exceso de C$ 350,000
                    WHEN p.ProjectedAnnual <= 500000.00 THEN
                        ROUND((45000.00 + (p.ProjectedAnnual - 350000.00) * 0.25) / CASE WHEN @PeriodType = N'quincenal' THEN 24.0 ELSE 12.0 END, 2)

                    -- Tramo 5: Más de C$ 500,000.00 -> C$ 82,500 + 30% sobre el exceso de C$ 500,000
                    ELSE
                        ROUND((82500.00 + (p.ProjectedAnnual - 500000.00) * 0.30) / CASE WHEN @PeriodType = N'quincenal' THEN 24.0 ELSE 12.0 END, 2)
                END AS IrPeriod
        ) AS calc
        WHERE i.PayrollRunId = @PayrollRunId;

        -- 5. Calcular Neto a Pagar
        UPDATE dbo.PayrollRunItems
        SET TotalDeductions = ROUND(InssLaboral + IncomeTax + OtherDeductions, 2),
            Net = ROUND(Gross - (InssLaboral + IncomeTax + OtherDeductions), 2)
        WHERE PayrollRunId = @PayrollRunId;

        -- 6. Calcular Aportes Patronales (INSS Patronal 21.5%, INATEC 2%) y Provisiones (8.3333% cada una)
        UPDATE dbo.PayrollRunItems
        SET InssPatronal = ROUND(Gross * 0.2150, 2),
            Inatec = ROUND(Gross * 0.0200, 2),
            Aguinaldo = ROUND(Gross * (1.0 / 12.0), 2),
            VacacionesProv = ROUND(Gross * (1.0 / 12.0), 2),
            IndemnizacionProv = ROUND(Gross * (1.0 / 12.0), 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET EmployerCost = ROUND(Gross + InssPatronal + Inatec + Aguinaldo + VacacionesProv + IndemnizacionProv, 2)
        WHERE PayrollRunId = @PayrollRunId;

        -- 7. Generar la explicación pedagógica y transparente para cada trabajador
        UPDATE i
        SET CalculationExplanationJson = (
            SELECT
                i.OrdinarySalary AS [salario_ordinario],
                i.OvertimeAmount AS [horas_extra_monto],
                i.OvertimeHours AS [horas_extra_cantidad],
                i.BonusesAmount AS [bonos],
                i.CommissionsAmount AS [comisiones],
                i.Gross AS [total_devengado],
                N'7.0% sobre devengado (Ley de Seguridad Social)' AS [inss_laboral_regla],
                i.InssLaboral AS [inss_laboral_monto],
                N'Tarifa Progresiva Anual Ley 822 Art. 96 sobre base neta anualizada' AS [ir_laboral_regla],
                i.IrBase AS [ir_base_periodo],
                i.IncomeTax AS [ir_laboral_monto],
                i.OtherDeductions AS [otras_deducciones],
                i.TotalDeductions AS [total_deducciones],
                i.Net AS [salario_neto_a_pagar],
                N'21.5% Aporte Patronal INSS + 2.0% INATEC' AS [aportes_patronales_regla],
                i.InssPatronal AS [inss_patronal],
                i.Inatec AS [inatec],
                N'Ley 185: 1/12 Aguinaldo + 1/12 Vacaciones + 1/12 Antigüedad' AS [provisiones_regla],
                i.Aguinaldo AS [provision_aguinaldo],
                i.VacacionesProv AS [provision_vacaciones],
                i.IndemnizacionProv AS [provision_indemnizacion],
                i.EmployerCost AS [costo_total_empresa]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
        FROM dbo.PayrollRunItems i
        WHERE i.PayrollRunId = @PayrollRunId;

        -- 8. Actualizar Totales en la Cabecera de la Planilla
        UPDATE r
        SET r.Gross = ISNULL(t.GrossTotal, 0),
            r.InssLaboral = ISNULL(t.InssLabTotal, 0),
            r.IncomeTax = ISNULL(t.IrTotal, 0),
            r.OtherDeductionsTotal = ISNULL(t.OtherDedTotal, 0),
            r.Net = ISNULL(t.NetTotal, 0),
            r.InssPatronal = ISNULL(t.InssPatTotal, 0),
            r.Inatec = ISNULL(t.InatecTotal, 0),
            r.AguinaldoProvTotal = ISNULL(t.AguiTotal, 0),
            r.VacacionesProvTotal = ISNULL(t.VacTotal, 0),
            r.IndemnizacionProvTotal = ISNULL(t.IndemTotal, 0),
            r.EmployerCost = ISNULL(t.CostTotal, 0),
            r.CalculationVersion = r.CalculationVersion + 1,
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

        -- 9. Ejecutar reglas de validación automática
        DELETE FROM dbo.PayrollValidations WHERE PayrollRunId = @PayrollRunId;

        -- a) Validación bloqueante: Salario Neto Negativo o Cero
        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_NETO_INVALIDO',
               N'El trabajador tiene un salario neto menor o igual a cero (C$ ' + CAST(Net AS NVARCHAR(30)) + N'). Revisa las deducciones aplicadas.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Net <= 0;

        -- b) Validación bloqueante: Devengado Cero
        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_DEVENGADO_CERO',
               N'El colaborador no registra salario ordinario ni devengado en el período.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Gross <= 0;

        -- c) Advertencia: Horas Extra Superiores a 9 horas semanales (Ley 185 Art. 58)
        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'advertencia', N'VAL_HORAS_EXTRA_LIMITE',
               N'El colaborador acumuló ' + CAST(OvertimeHours AS NVARCHAR(20)) + N' horas extras en el período. Verificar cumplimiento del límite legal de jornada extraordinaria (Ley 185 Art. 58).',
               N'novedades'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND OvertimeHours > 18.0;

        -- d) Informativa: Inclusión de trabajador en condición de baja
        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, i.EmployeeId, N'informativa', N'VAL_TRABAJADOR_BAJA',
               N'Se liquidan remuneraciones pendientes de colaborador con baja registrada (' + ISNULL(e.DismissalReason, N'Término de contrato') + N').',
               N'trabajadores'
        FROM dbo.PayrollRunItems i
        JOIN dbo.Employees e ON e.EmployeeId = i.EmployeeId
        WHERE i.PayrollRunId = @PayrollRunId AND e.EmploymentStatus = N'baja';

        -- 10. Registrar auditoría de cálculo
        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'calculo', @CurrentStatus, N'calculada',
            N'Cálculo de nómina ejecutado exitosamente con versión de cálculo v' + CAST(@CalcVer + 1 AS NVARCHAR(10)) + N'.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.CalculationVersion AS calculationVersion,
               r.Gross AS grossTotal, r.InssLaboral AS inssLaboralTotal,
               r.IncomeTax AS incomeTaxTotal, r.Net AS netTotal,
               r.InssPatronal AS inssPatronalTotal, r.Inatec AS inatecTotal,
               (r.AguinaldoProvTotal + r.VacacionesProvTotal + r.IndemnizacionProvTotal) AS provisionsTotal,
               r.EmployerCost AS companyCostTotal,
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

-- -----------------------------------------------------------------------------
-- 15. PROCEDIMIENTO ALMACENADO: TRANSICIÓN DE ESTADOS DE NÓMINA (usp_TransitionPayrollStatus)
--     Valida flujo: borrador -> calculada -> revisada -> aprobada -> pago_registrado -> conciliada -> cerrada
-- -----------------------------------------------------------------------------
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

    IF @CurrentRev <> @ExpectedRevision
        THROW 50507, 'La planilla fue actualizada por otro usuario. Recarga la información.', 1;

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
        IF @ActorId = @PreparedBy AND @ActorId <> N'u-super'
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

    BEGIN TRY
        BEGIN TRANSACTION;

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
            -- Generar Asiento Contable Equilibrado de Nómina (Partida Doble)
            DECLARE @EntryId NVARCHAR(100) = N'entry-nom-' + @PayrollRunId;
            DECLARE @EntryNumber NVARCHAR(80) = N'AST-NOM-' + REPLACE(@Period, N' ', N'-');

            -- Verificar si ya existe asiento para actualizar o crear
            IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryId)
            BEGIN
                -- 1. Asiento de Gasto de Nómina vs Pasivos Laborales
                -- Débito: Gasto de Nómina (Devengado)
                -- Crédito: Sueldos por pagar (Neto), INSS por pagar (Laboral), IR por pagar (Laboral)
                DECLARE @TotalPasivosLaborales DECIMAL(19,4) = @NetTotal + @InssLaboral + @IncomeTax;

                INSERT INTO dbo.AccountingEntries (
                    AccountingEntryId, EntryNumber, Description, Debit, Credit,
                    DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId, PayrollRunId
                )
                VALUES (
                    @EntryId, @EntryNumber,
                    N'Reconocimiento de gastos de personal y retenciones de ley período ' + @Period,
                    @GrossTotal, @GrossTotal,
                    N'Nómina', N'Sueldos por pagar',
                    TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), N'payroll', @PayrollRunId, @PayrollRunId
                );

                -- 2. Asiento de Cargas Sociales Patronales (INSS Patronal + INATEC)
                DECLARE @EntryPatronalId NVARCHAR(100) = N'entry-pat-' + @PayrollRunId;
                DECLARE @EntryPatronalNum NVARCHAR(80) = N'AST-PAT-' + REPLACE(@Period, N' ', N'-');
                DECLARE @TotalCargasPatronales DECIMAL(19,4) = @InssPatronal + @Inatec;

                IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryPatronalId)
                BEGIN
                    INSERT INTO dbo.AccountingEntries (
                        AccountingEntryId, EntryNumber, Description, Debit, Credit,
                        DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId, PayrollRunId
                    )
                    VALUES (
                        @EntryPatronalId, @EntryPatronalNum,
                        N'Aportes patronales obligatorios INSS (21.5%) e INATEC (2%) período ' + @Period,
                        @TotalCargasPatronales, @TotalCargasPatronales,
                        N'Aporte patronal INSS e INATEC', N'INSS por pagar',
                        TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), N'payroll', @PayrollRunId, @PayrollRunId
                    );
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
                (N'ob-ir-' + @PayrollRunId, @PayrollRunId, N'DGI', @Period, @GrossTotal - @InssLaboral, @IncomeTax, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente'),
                (N'ob-inss-' + @PayrollRunId, @PayrollRunId, N'INSS', @Period, @GrossTotal, (@InssLaboral + @InssPatronal), DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente'),
                (N'ob-inatec-' + @PayrollRunId, @PayrollRunId, N'INATEC', @Period, @GrossTotal, @Inatec, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente'),
                (N'ob-prov-' + @PayrollRunId, @PayrollRunId, N'PROVISIONES_PASIVO', @Period, @GrossTotal, (@AguinaldoProv + @VacacionesProv + @IndemnizacionProv), DATEADD(DAY, 30, CAST(GETDATE() AS DATE)), N'provisionada');
        END
        ELSE IF @TargetStatus = N'pago_registrado'
        BEGIN
            -- Registrar movimiento de salida en tesorería (Banco)
            DECLARE @CashId NVARCHAR(100) = N'cash-nom-' + @PayrollRunId;
            IF NOT EXISTS (SELECT 1 FROM dbo.CashMoves WHERE CashMoveId = @CashId)
            BEGIN
                INSERT INTO dbo.CashMoves (
                    CashMoveId, Account, CashAccountCode, MoveType, Amount, MoveDate, Concept, PayrollRunId
                )
                VALUES (
                    @CashId, N'banco', N'banco', N'salida', @NetTotal,
                    TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
                    N'Dispersión y pago bancario de nómina de colaboradores período ' + @Period,
                    @PayrollRunId
                );
            END;

            UPDATE dbo.PayrollRuns
            SET Status = N'pago_registrado',
                PaidByAppUserId = @ActorId,
                PaidAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
                PaymentNotes = @Notes,
                CashMoveId = @CashId,
                ConfirmedPaymentsTotal = @NetTotal,
                PendingDiscrepancyTotal = 0,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            UPDATE dbo.PayrollRunItems
            SET PaymentStatus = N'pagado',
                PaymentConfirmedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
            WHERE PayrollRunId = @PayrollRunId;
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

            -- Generar seguimiento de obligaciones institucionales
            DELETE FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId = @PayrollRunId;

            INSERT INTO dbo.PayrollInstitutionalObligations (
                ObligationId, PayrollRunId, EntityName, PeriodLabel, BaseAmount, PayableAmount, DueDate, Status
            )
            VALUES
                (N'ob-ir-' + @PayrollRunId, @PayrollRunId, N'DGI_IR', @Period, @GrossTotal - @InssLaboral, @IncomeTax, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'calculada'),
                (N'ob-inss-lab-' + @PayrollRunId, @PayrollRunId, N'INSS_LABORAL', @Period, @GrossTotal, @InssLaboral, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'calculada'),
                (N'ob-inss-pat-' + @PayrollRunId, @PayrollRunId, N'INSS_PATRONAL', @Period, @GrossTotal, @InssPatronal, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'calculada'),
                (N'ob-inatec-' + @PayrollRunId, @PayrollRunId, N'INATEC', @Period, @GrossTotal, @Inatec, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'calculada'),
                (N'ob-prov-' + @PayrollRunId, @PayrollRunId, N'PROVISIONES_PASIVO', @Period, @GrossTotal, (@AguinaldoProv + @VacacionesProv + @IndemnizacionProv), DATEADD(DAY, 30, CAST(GETDATE() AS DATE)), N'calculada');
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

-- -----------------------------------------------------------------------------
-- 16. PROCEDIMIENTO ALMACENADO: OBTENER DETALLE DE TRABAJADORES (usp_GetPayrollRunItems)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollRunItems
    @PayrollRunId NVARCHAR(100),
    @ActorId      NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT i.PayrollItemId AS id,
           i.EmployeeId AS employeeId,
           e.Name AS employeeName,
           i.PositionSnapshot AS position,
           i.AreaSnapshot AS area,
           i.BaseSalaryMonthly AS baseSalaryMonthly,
           i.PeriodDaysWorked AS daysWorked,
           i.PeriodHoursWorked AS hoursWorked,
           i.OrdinarySalary AS ordinarySalary,
           i.OvertimeHours AS overtimeHours,
           i.OvertimeAmount AS overtimeAmount,
           i.BonusesAmount AS bonusesAmount,
           i.CommissionsAmount AS commissionsAmount,
           i.VacationDisfruteAmount AS vacationDisfruteAmount,
           i.OtherTaxableIncome AS otherTaxableIncome,
           i.Gross AS grossIncome,
           i.InssBase AS inssBase,
           i.InssLaboral AS inssLaboral,
           i.IrBase AS irBase,
           i.IncomeTax AS incomeTax,
           i.OtherDeductions AS otherDeductions,
           i.TotalDeductions AS totalDeductions,
           i.Net AS netPay,
           i.InssPatronal AS inssPatronal,
           i.Inatec AS inatec,
           i.Aguinaldo AS aguinaldoProv,
           i.VacacionesProv AS vacacionesProv,
           i.IndemnizacionProv AS indemnizacionProv,
           i.EmployerCost AS employerCost,
           i.PaymentStatus AS paymentStatus,
           i.PaymentMethod AS paymentMethod,
           i.PaymentReference AS paymentReference,
           i.CalculationExplanationJson AS explanationJson,
           i.ReceiptStatus AS receiptStatus,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), i.Revision), 1) AS revision
    FROM dbo.PayrollRunItems i
    JOIN dbo.Employees e ON e.EmployeeId = i.EmployeeId
    WHERE i.PayrollRunId = @PayrollRunId
    ORDER BY e.Name ASC;
END;
GO

-- -----------------------------------------------------------------------------
-- 17. PROCEDIMIENTO ALMACENADO: COMPROBANTE DE PAGO INDIVIDUAL (usp_GetPayrollEmployeeReceipt)
--     Seguridad estricta: un colaborador solo puede ver su propia colilla
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollEmployeeReceipt
    @PayrollRunId NVARCHAR(100),
    @EmployeeId   NVARCHAR(100),
    @ActorId      NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsManagement BIT = 0;
    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area IN (N'rrhh', N'finanzas', N'contabilidad')
          )))
    )
        SET @IsManagement = 1;

    -- Si no es administrativo, verificar que el empleado esté vinculado a la cuenta del actor
    IF @IsManagement = 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Employees
            WHERE EmployeeId = @EmployeeId AND AppUserId = @ActorId
        )
            THROW 50517, 'No tienes autorización para consultar el comprobante de pago de otro colaborador.', 1;
    END;

    SELECT i.PayrollItemId AS receiptNumber,
           r.Period AS period,
           r.PeriodType AS periodType,
           r.StartDate AS startDate,
           r.EndDate AS endDate,
           r.PaymentDate AS paymentDate,
           r.Status AS runStatus,
           e.EmployeeId AS employeeId,
           e.Name AS employeeName,
           i.PositionSnapshot AS position,
           i.AreaSnapshot AS area,
           e.HireDate AS hireDate,
           i.BaseSalaryMonthly AS baseSalaryMonthly,
           i.PeriodDaysWorked AS daysWorked,
           i.PeriodHoursWorked AS hoursWorked,
           i.OrdinarySalary AS ordinarySalary,
           i.OvertimeHours AS overtimeHours,
           i.OvertimeAmount AS overtimeAmount,
           i.BonusesAmount AS bonusesAmount,
           i.CommissionsAmount AS commissionsAmount,
           i.VacationDisfruteAmount AS vacationDisfruteAmount,
           i.OtherTaxableIncome AS otherTaxableIncome,
           i.Gross AS grossTotal,
           i.InssLaboral AS inssLaboral,
           i.IncomeTax AS incomeTax,
           i.OtherDeductions AS otherDeductions,
           i.TotalDeductions AS totalDeductions,
           i.Net AS netPay,
           i.PaymentStatus AS paymentStatus,
           i.PaymentMethod AS paymentMethod,
           i.PaymentReference AS paymentReference,
           i.PaymentConfirmedAt AS paymentConfirmedAt,
           i.CalculationExplanationJson AS explanationJson,
           N'Instalaciones Raquel S.A. - RUC J0310000123456' AS employerInfo
    FROM dbo.PayrollRunItems i
    JOIN dbo.PayrollRuns r ON r.PayrollRunId = i.PayrollRunId
    JOIN dbo.Employees e ON e.EmployeeId = i.EmployeeId
    WHERE i.PayrollRunId = @PayrollRunId AND i.EmployeeId = @EmployeeId;
END;
GO

-- -----------------------------------------------------------------------------
-- 18. PROCEDIMIENTO ALMACENADO: GESTIÓN DE NOVEDADES (usp_UpsertPayrollNovelty)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_UpsertPayrollNovelty
    @NoveltyId          NVARCHAR(100),
    @PayrollRunId       NVARCHAR(100) = NULL,
    @EmployeeId         NVARCHAR(100),
    @NoveltyType        NVARCHAR(40),
    @Concept            NVARCHAR(240),
    @Amount             DECIMAL(19,4),
    @Hours              DECIMAL(9,2) = NULL,
    @LegalJustification NVARCHAR(500) = NULL,
    @DocReference       NVARCHAR(300) = NULL,
    @PeriodDate         DATE,
    @ActorId            NVARCHAR(100)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    IF @Amount <= 0
        THROW 50518, 'El importe de la novedad debe ser mayor que cero.', 1;

    MERGE dbo.PayrollNovelties AS target
    USING (VALUES (@NoveltyId, @PayrollRunId, @EmployeeId, @NoveltyType, @Concept, @Amount, @Hours, @LegalJustification, @DocReference, @PeriodDate, @ActorId))
       AS src (NoveltyId, PayrollRunId, EmployeeId, NoveltyType, Concept, Amount, Hours, LegalJustification, DocReference, PeriodDate, ActorId)
    ON (target.NoveltyId = src.NoveltyId)
    WHEN MATCHED THEN
        UPDATE SET target.PayrollRunId = src.PayrollRunId, target.EmployeeId = src.EmployeeId,
                   target.NoveltyType = src.NoveltyType, target.Concept = src.Concept,
                   target.Amount = src.Amount, target.Hours = src.Hours,
                   target.LegalJustification = src.LegalJustification, target.DocReference = src.DocReference,
                   target.PeriodDate = src.PeriodDate
    WHEN NOT MATCHED THEN
        INSERT (NoveltyId, PayrollRunId, EmployeeId, NoveltyType, Concept, Amount, Hours, LegalJustification, DocReference, PeriodDate, Status, CreatedByAppUserId, AuthorizedByAppUserId, AuthorizedAt)
        VALUES (src.NoveltyId, src.PayrollRunId, src.EmployeeId, src.NoveltyType, src.Concept, src.Amount, src.Hours, src.LegalJustification, src.DocReference, src.PeriodDate, N'autorizada', src.ActorId, src.ActorId, SYSUTCDATETIME());

    SELECT NoveltyId AS id, Concept AS concept, Amount AS amount, Status AS status
    FROM dbo.PayrollNovelties WHERE NoveltyId = @NoveltyId;
END;
GO

-- -----------------------------------------------------------------------------
-- 19. PROCEDIMIENTO ALMACENADO: REPORTES Y AGREGACIONES (usp_GetPayrollReports)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollReports
    @ReportType   NVARCHAR(50), -- 'resumen_periodo', 'costos_proyecto', 'obligaciones', 'comparativa'
    @PayrollRunId NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ReportType = N'resumen_periodo'
    BEGIN
        SELECT r.Period AS period, r.StartDate AS startDate, r.EndDate AS endDate,
               COUNT(i.EmployeeId) AS workersCount,
               SUM(i.Gross) AS totalGross,
               SUM(i.InssLaboral) AS totalInssLaboral,
               SUM(i.IncomeTax) AS totalIncomeTax,
               SUM(i.OtherDeductions) AS totalOtherDeductions,
               SUM(i.Net) AS totalNetPay,
               SUM(i.InssPatronal) AS totalInssPatronal,
               SUM(i.Inatec) AS totalInatec,
               SUM(i.Aguinaldo + i.VacacionesProv + i.IndemnizacionProv) AS totalProvisiones,
               SUM(i.EmployerCost) AS totalEmployerCost
        FROM dbo.PayrollRuns r
        LEFT JOIN dbo.PayrollRunItems i ON i.PayrollRunId = r.PayrollRunId
        WHERE (@PayrollRunId IS NULL OR r.PayrollRunId = @PayrollRunId)
        GROUP BY r.PayrollRunId, r.Period, r.StartDate, r.EndDate
        ORDER BY r.StartDate DESC;
    END
    ELSE IF @ReportType = N'por_area'
    BEGIN
        SELECT i.AreaSnapshot AS area,
               COUNT(i.EmployeeId) AS countEmployees,
               SUM(i.Gross) AS totalGross,
               SUM(i.InssLaboral) AS totalInssLaboral,
               SUM(i.IncomeTax) AS totalIncomeTax,
               SUM(i.Net) AS totalNet,
               SUM(i.EmployerCost) AS totalCost
        FROM dbo.PayrollRunItems i
        WHERE (@PayrollRunId IS NULL OR i.PayrollRunId = @PayrollRunId)
        GROUP BY i.AreaSnapshot
        ORDER BY totalCost DESC;
    END
    ELSE IF @ReportType = N'obligaciones'
    BEGIN
        SELECT EntityName AS entity, PeriodLabel AS period, BaseAmount AS base,
               PayableAmount AS payable, DueDate AS dueDate, Status AS status,
               PaymentReceiptRef AS receiptRef
        FROM dbo.PayrollInstitutionalObligations
        WHERE (@PayrollRunId IS NULL OR PayrollRunId = @PayrollRunId)
        ORDER BY DueDate ASC;
    END
    ELSE IF @ReportType = N'costos_proyecto'
    BEGIN
        SELECT p.Code AS projectCode, p.Name AS projectName,
               COUNT(DISTINCT d.EmployeeId) AS employeesAssigned,
               SUM(d.HoursAllocated) AS totalHours,
               SUM(d.CostAllocated) AS totalCostAllocated
        FROM dbo.PayrollProjectDistributions d
        JOIN dbo.Projects p ON p.ProjectId = d.ProjectId
        WHERE (@PayrollRunId IS NULL OR d.PayrollRunId = @PayrollRunId)
        GROUP BY p.Code, p.Name
        ORDER BY totalCostAllocated DESC;
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- 20. PROCEDIMIENTO ALMACENADO: GESTIÓN DE TICKETS DE COLILLAS (usp_CreatePayrollReceiptTicket)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_CreatePayrollReceiptTicket
    @TicketId       NVARCHAR(100),
    @PayrollRunId   NVARCHAR(100),
    @EmployeeId     NVARCHAR(100),
    @Subject        NVARCHAR(200),
    @Description    NVARCHAR(1000),
    @ActorId        NVARCHAR(100)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TicketNumber NVARCHAR(60) = N'TCK-NOM-' + RIGHT(CONVERT(VARCHAR(36), NEWID()), 8);

    INSERT INTO dbo.PayrollReceiptTickets (
        TicketId, PayrollRunId, EmployeeId, TicketNumber, Subject, Description, Status
    )
    VALUES (
        @TicketId, @PayrollRunId, @EmployeeId, @TicketNumber, @Subject, @Description, N'abierto'
    );

    SELECT TicketId AS id, TicketNumber AS ticketNumber, Subject AS subject, Status AS status, CreatedAt AS createdAt
    FROM dbo.PayrollReceiptTickets
    WHERE TicketId = @TicketId;
END;
GO

-- -----------------------------------------------------------------------------
-- 21. PERMISOS DE ACCESO PARA raquel_erp_app
-- -----------------------------------------------------------------------------
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollRulesCatalog TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollRuns TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollRunItems TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollNovelties TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollValidations TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollProjectDistributions TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollPayments TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollInstitutionalObligations TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollReceiptTickets TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollHistoryEvents TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.AccountingEntries TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.CashMoves TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.ChartOfAccounts TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.Employees TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.AppUsers TO [raquel_erp_app];

    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollRuns TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreatePayrollDraft TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CalculatePayroll TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_TransitionPayrollStatus TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollRunItems TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollEmployeeReceipt TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_UpsertPayrollNovelty TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollReports TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreatePayrollReceiptTicket TO [raquel_erp_app];
END;
GO
