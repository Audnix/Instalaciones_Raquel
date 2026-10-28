/* 25 - Operaciones reales de Talento Humano y Nómina (conserva datos existentes) */
USE [Instalaciones Raquel];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH(N'dbo.Employees', N'LaborCondition') IS NULL
    ALTER TABLE dbo.Employees ADD LaborCondition NVARCHAR(40) NOT NULL CONSTRAINT DF_Employees_LaborCondition DEFAULT (N'permanente');
GO

IF COL_LENGTH(N'dbo.PayrollRuns', N'CalculationStale') IS NULL
    ALTER TABLE dbo.PayrollRuns ADD CalculationStale BIT NOT NULL CONSTRAINT DF_PayrollRuns_CalcStale DEFAULT (0);
GO

IF COL_LENGTH(N'dbo.HrContracts', N'ParentContractId') IS NULL
    ALTER TABLE dbo.HrContracts ADD ParentContractId UNIQUEIDENTIFIER NULL;
GO
IF COL_LENGTH(N'dbo.HrContracts', N'VersionNumber') IS NULL
    ALTER TABLE dbo.HrContracts ADD VersionNumber INT NOT NULL CONSTRAINT DF_HrContracts_Version DEFAULT (1);
GO

IF COL_LENGTH(N'dbo.HrAttendanceRecords', N'CorrectionRequestedIn') IS NULL
    ALTER TABLE dbo.HrAttendanceRecords ADD CorrectionRequestedIn TIME(0) NULL;
IF COL_LENGTH(N'dbo.HrAttendanceRecords', N'CorrectionRequestedOut') IS NULL
    ALTER TABLE dbo.HrAttendanceRecords ADD CorrectionRequestedOut TIME(0) NULL;
GO

IF OBJECT_ID(N'dbo.PayrollNoveltyEvents', N'U') IS NULL
CREATE TABLE dbo.PayrollNoveltyEvents
(
    EventId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PayrollNoveltyEvents PRIMARY KEY,
    NoveltyId NVARCHAR(100) NOT NULL,
    ActorId NVARCHAR(100) NOT NULL,
    ActorName NVARCHAR(240) NOT NULL,
    EventType NVARCHAR(40) NOT NULL,
    Detail NVARCHAR(1000) NULL,
    OccurredAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollNoveltyEvents_At DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'))
);
GO

CREATE OR ALTER VIEW dbo.vw_HrEmployeeDirectory
AS
    SELECT employee.EmployeeId, employee.Name, employee.Position, employee.Area,
           employee.HireDate, employee.EmploymentStatus, employee.AppUserId,
           employee.DismissalDate, employee.DismissalReason, employee.LaborCondition,
           CASE WHEN employee.AppUserId IS NULL THEN NULL ELSE appUser.IsActive END AS AccountActive
    FROM dbo.Employees AS employee
    LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = employee.AppUserId;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateHrEmployee
    @MutationId UNIQUEIDENTIFIER,
    @EmployeeId NVARCHAR(100),
    @Name NVARCHAR(240),
    @Position NVARCHAR(200),
    @Salary DECIMAL(19,4),
    @Area NVARCHAR(120),
    @AppUserId NVARCHAR(100) = NULL,
    @HireDate DATE,
    @LaborCondition NVARCHAR(40) = N'permanente',
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          ))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50434, 'Se requiere autorización de administración de Talento humano.', 1;
    END;

    IF @AppUserId IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers WHERE AppUserId = @AppUserId AND IsActive = 1
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50435, 'La cuenta vinculada no existe o está inactiva.', 1;
    END;

    IF NULLIF(LTRIM(RTRIM(@Name)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Position)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Area)), N'') IS NULL
       OR @Salary IS NULL OR @Salary <= 0
       OR @HireDate IS NULL OR @HireDate > CONVERT(DATE, SYSUTCDATETIME())
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50443, 'Los datos del expediente no son válidos.', 1;
    END;

    IF EXISTS (
        SELECT 1 FROM dbo.Employees
        WHERE LOWER(LTRIM(RTRIM(Name))) = LOWER(LTRIM(RTRIM(@Name)))
          AND HireDate = @HireDate
          AND EmploymentStatus <> N'baja'
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50452, 'Ya existe un expediente activo con el mismo nombre y fecha de ingreso.', 1;
    END;

    DECLARE @ExistingEmployeeId NVARCHAR(100);
    SELECT @ExistingEmployeeId = EmployeeId
    FROM dbo.HrEmployeeCreations WITH (UPDLOCK, HOLDLOCK)
    WHERE MutationId = @MutationId;

    IF @ExistingEmployeeId IS NOT NULL
    BEGIN
        COMMIT TRANSACTION;
        SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
               HireDate AS hireDate, EmploymentStatus AS employmentStatus, LaborCondition AS laborCondition,
               CAST(NULL AS BIT) AS accountActive, CAST(0 AS BIT) AS wasCreated
        FROM dbo.Employees
        WHERE EmployeeId = @ExistingEmployeeId;
        RETURN;
    END;

    INSERT INTO dbo.Employees (
        EmployeeId, Name, Position, Salary, Area, AppUserId, HireDate, IsActive, EmploymentStatus, LaborCondition
    )
    VALUES (
        @EmployeeId, @Name, @Position, @Salary, @Area, @AppUserId, @HireDate, 1, N'activo', ISNULL(@LaborCondition, N'permanente')
    );

    INSERT INTO dbo.EmployeeJobHistory (
        EmployeeJobHistoryId, EmployeeId, Position, Area, Salary, ValidFrom, ChangedByAppUserId
    )
    VALUES (
        NEWID(), @EmployeeId, @Position, @Area, @Salary, @HireDate, @ActorId
    );

    INSERT INTO dbo.HrEmployeeCreations (MutationId, EmployeeId, CreatedByAppUserId)
    VALUES (@MutationId, @EmployeeId, @ActorId);

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(actor.Name, 200), actor.AppUserId, N'crear expediente de personal', N'rrhh',
        CONCAT(N'Expediente ', @EmployeeId, N' creado; el contrato se registra en un paso separado.'), N'info', @EmployeeId
    FROM dbo.AppUsers AS actor
    WHERE actor.AppUserId = @ActorId;

    COMMIT TRANSACTION;
    SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
           HireDate AS hireDate, EmploymentStatus AS employmentStatus, LaborCondition AS laborCondition,
           CAST(NULL AS BIT) AS accountActive, CAST(1 AS BIT) AS wasCreated
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;
END;
GO

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
            Actor, ActorUserId, Status, CalculationVersion, CalculationStale,
            Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost,
            OtherDeductionsTotal, AguinaldoProvTotal, VacacionesProvTotal, IndemnizacionProvTotal,
            ConfirmedPaymentsTotal, PendingDiscrepancyTotal,
            PreparedByAppUserId, PreparedAt, Notes
        )
        VALUES (
            @PayrollRunId, @Period, @PeriodType, @StartDate, @EndDate, @PaymentDate,
            @ActorName, @ActorId, N'borrador', 1, 1,
            0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0,
            @ActorId, SYSUTCDATETIME(), @Notes
        );

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'creacion', NULL, N'borrador',
            N'Planilla creada en borrador. No registra pago. Agregue trabajadores elegibles desde Talento humano.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.Gross AS grossTotal, r.Net AS netTotal,
               CAST(0 AS INT) AS workersCount,
               CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision,
               CAST(1 AS BIT) AS calculationStale
        FROM dbo.PayrollRuns r
        WHERE r.PayrollRunId = @PayrollRunId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollEligibleEmployees
    @PayrollRunId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartDate DATE, @EndDate DATE;
    SELECT @StartDate = StartDate, @EndDate = EndDate
    FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId;

    SELECT e.EmployeeId AS id, e.Name AS name, e.Position AS position, e.Area AS area,
           e.EmploymentStatus AS employmentStatus, e.Salary AS salary,
           e.HireDate AS hireDate, e.DismissalDate AS dismissalDate
    FROM dbo.Employees e
    WHERE NOT EXISTS (
            SELECT 1 FROM dbo.PayrollRunItems i
            WHERE i.PayrollRunId = @PayrollRunId AND i.EmployeeId = e.EmployeeId
        )
      AND e.HireDate <= @EndDate
      AND (
            e.EmploymentStatus IN (N'activo', N'licencia')
            OR (e.DismissalDate IS NOT NULL AND e.DismissalDate >= @StartDate)
          )
    ORDER BY e.Name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AddPayrollRunWorker
    @PayrollRunId NVARCHAR(100),
    @EmployeeId NVARCHAR(100),
    @Reason NVARCHAR(500),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Status NVARCHAR(30), @PeriodType NVARCHAR(30), @StartDate DATE, @EndDate DATE;
    SELECT @Status = Status, @PeriodType = PeriodType, @StartDate = StartDate, @EndDate = EndDate
    FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId;

    IF @Status IS NULL THROW 50503, 'La planilla no existe.', 1;
    IF @Status <> N'borrador' THROW 50521, 'Solo se pueden agregar trabajadores en estado borrador.', 1;
    IF EXISTS (SELECT 1 FROM dbo.PayrollRunItems WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId)
        THROW 50522, 'El trabajador ya está incluido en esta planilla.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.Employees e
        WHERE e.EmployeeId = @EmployeeId
          AND e.HireDate <= @EndDate
          AND (
                e.EmploymentStatus IN (N'activo', N'licencia')
                OR (e.DismissalDate IS NOT NULL AND e.DismissalDate >= @StartDate)
              )
    )
        THROW 50523, 'El trabajador no es elegible para este período.', 1;

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
        @PayrollRunId, e.EmployeeId, @PayrollRunId + N'-' + e.EmployeeId,
        e.Position, e.Area, e.Salary,
        CASE WHEN @PeriodType = N'quincenal' THEN 15.0 ELSE 30.0 END,
        CASE WHEN @PeriodType = N'quincenal' THEN 120.0 ELSE 240.0 END,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        N'pendiente', N'transferencia_bancaria', N'no_generado'
    FROM dbo.Employees e
    WHERE e.EmployeeId = @EmployeeId;

    UPDATE dbo.PayrollRuns SET CalculationStale = 1, UpdatedAt = SYSUTCDATETIME() WHERE PayrollRunId = @PayrollRunId;

    INSERT INTO dbo.PayrollHistoryEvents (
        PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
    )
    VALUES (
        @PayrollRunId, @ActorId, @ActorName, N'inclusion_trabajador', N'borrador', N'borrador',
        CONCAT(N'Se incluyó a ', @EmployeeId, N'. Motivo: ', ISNULL(@Reason, N'sin motivo'))
    );

    SELECT i.PayrollItemId AS id, i.EmployeeId AS employeeId, e.Name AS employeeName
    FROM dbo.PayrollRunItems i
    JOIN dbo.Employees e ON e.EmployeeId = i.EmployeeId
    WHERE i.PayrollRunId = @PayrollRunId AND i.EmployeeId = @EmployeeId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RemovePayrollRunWorker
    @PayrollRunId NVARCHAR(100),
    @EmployeeId NVARCHAR(100),
    @Reason NVARCHAR(500),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId AND Status = N'borrador')
        THROW 50521, 'Solo se pueden retirar trabajadores en estado borrador.', 1;

    DELETE FROM dbo.PayrollRunItems
    WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;

    UPDATE dbo.PayrollRuns SET CalculationStale = 1, UpdatedAt = SYSUTCDATETIME() WHERE PayrollRunId = @PayrollRunId;

    INSERT INTO dbo.PayrollHistoryEvents (
        PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
    )
    VALUES (
        @PayrollRunId, @ActorId, @ActorName, N'retiro_trabajador', N'borrador', N'borrador',
        CONCAT(N'Se retiró a ', @EmployeeId, N'. Motivo: ', ISNULL(@Reason, N'sin motivo'))
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RegisterPayrollPayment
    @PaymentId NVARCHAR(100),
    @PayrollRunId NVARCHAR(100),
    @EmployeeId NVARCHAR(100),
    @Amount DECIMAL(19,4),
    @PaymentMethod NVARCHAR(40),
    @TransactionReference NVARCHAR(120),
    @ManualConfirmationProof NVARCHAR(300) = NULL,
    @Status NVARCHAR(30),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunStatus NVARCHAR(30), @Net DECIMAL(19,4);
    SELECT @RunStatus = Status FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId;
    IF @RunStatus IS NULL THROW 50503, 'La planilla no existe.', 1;
    IF @RunStatus NOT IN (N'aprobada', N'pago_registrado')
        THROW 50524, 'Solo se registran pagos cuando la planilla está aprobada o con pago en curso.', 1;
    IF @Amount <= 0 THROW 50525, 'El importe del pago debe ser mayor que cero.', 1;
    IF NULLIF(LTRIM(RTRIM(@TransactionReference)), N'') IS NULL
        THROW 50526, 'Indica una referencia documental o bancaria del pago.', 1;

    SELECT @Net = Net FROM dbo.PayrollRunItems WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;
    IF @Net IS NULL THROW 50527, 'El trabajador no pertenece a esta planilla.', 1;

    INSERT INTO dbo.PayrollPayments (
        PaymentId, PayrollRunId, EmployeeId, Amount, PaymentMethod, TransactionReference,
        Status, ConfirmedAt, ConfirmedByAppUserId, ManualConfirmationProof
    )
    VALUES (
        @PaymentId, @PayrollRunId, @EmployeeId, @Amount, @PaymentMethod, @TransactionReference,
        @Status,
        CASE WHEN @Status = N'confirmado' THEN TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00') ELSE NULL END,
        @ActorId, @ManualConfirmationProof
    );

    DECLARE @Paid DECIMAL(19,4) = (
        SELECT ISNULL(SUM(Amount), 0) FROM dbo.PayrollPayments
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId AND Status = N'confirmado'
    );

    UPDATE dbo.PayrollRunItems
    SET PaymentStatus = CASE
            WHEN @Status = N'fallido' AND @Paid = 0 THEN N'pendiente'
            WHEN @Paid >= Net THEN N'pagado'
            WHEN @Paid > 0 THEN N'parcial'
            ELSE N'pendiente'
        END,
        PaymentMethod = @PaymentMethod,
        PaymentReference = @TransactionReference,
        PaymentConfirmedAt = CASE WHEN @Paid >= Net THEN TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00') ELSE PaymentConfirmedAt END
    WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;

    UPDATE r
    SET r.ConfirmedPaymentsTotal = x.TotalPaid,
        r.PendingDiscrepancyTotal = CASE WHEN r.Net > x.TotalPaid THEN r.Net - x.TotalPaid ELSE 0 END,
        r.UpdatedAt = SYSUTCDATETIME()
    FROM dbo.PayrollRuns r
    CROSS APPLY (
        SELECT ISNULL(SUM(Amount), 0) AS TotalPaid
        FROM dbo.PayrollPayments p
        WHERE p.PayrollRunId = r.PayrollRunId AND p.Status = N'confirmado'
    ) x
    WHERE r.PayrollRunId = @PayrollRunId;

    INSERT INTO dbo.PayrollHistoryEvents (
        PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
    )
    VALUES (
        @PayrollRunId, @ActorId, @ActorName, N'registro_pago', @RunStatus, @RunStatus,
        CONCAT(N'Pago ', @Status, N' de C$ ', CONVERT(NVARCHAR(40), @Amount), N' para ', @EmployeeId, N'. Ref: ', @TransactionReference)
    );

    SELECT PaymentId AS id, Status AS status, Amount AS amount FROM dbo.PayrollPayments WHERE PaymentId = @PaymentId;
END;
GO

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
           ISNULL(r.CalculationStale, 0) AS calculationStale,
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

IF OBJECT_ID(N'dbo.usp_UpsertPayrollNovelty', N'P') IS NOT NULL
BEGIN
    EXEC(N'
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
            THROW 50518, ''El importe de la novedad debe ser mayor que cero.'', 1;

        IF @PayrollRunId IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId AND Status IN (N''borrador'', N''calculada'')
        )
            THROW 50528, ''La novedad solo se registra o corrige mientras la planilla está en borrador o calculada.'', 1;

        MERGE dbo.PayrollNovelties AS target
        USING (VALUES (@NoveltyId, @PayrollRunId, @EmployeeId, @NoveltyType, @Concept, @Amount, @Hours, @LegalJustification, @DocReference, @PeriodDate, @ActorId))
           AS src (NoveltyId, PayrollRunId, EmployeeId, NoveltyType, Concept, Amount, Hours, LegalJustification, DocReference, PeriodDate, ActorId)
        ON (target.NoveltyId = src.NoveltyId)
        WHEN MATCHED AND target.Status <> N''cancelada'' THEN
            UPDATE SET target.PayrollRunId = src.PayrollRunId, target.EmployeeId = src.EmployeeId,
                       target.NoveltyType = src.NoveltyType, target.Concept = src.Concept,
                       target.Amount = src.Amount, target.Hours = src.Hours,
                       target.LegalJustification = src.LegalJustification, target.DocReference = src.DocReference,
                       target.PeriodDate = src.PeriodDate
        WHEN NOT MATCHED THEN
            INSERT (NoveltyId, PayrollRunId, EmployeeId, NoveltyType, Concept, Amount, Hours, LegalJustification, DocReference, PeriodDate, Status, CreatedByAppUserId, AuthorizedByAppUserId, AuthorizedAt)
            VALUES (src.NoveltyId, src.PayrollRunId, src.EmployeeId, src.NoveltyType, src.Concept, src.Amount, src.Hours, src.LegalJustification, src.DocReference, src.PeriodDate, N''autorizada'', src.ActorId, src.ActorId, SYSUTCDATETIME());

        IF @PayrollRunId IS NOT NULL
            UPDATE dbo.PayrollRuns SET CalculationStale = 1, UpdatedAt = SYSUTCDATETIME() WHERE PayrollRunId = @PayrollRunId;

        INSERT INTO dbo.PayrollNoveltyEvents (NoveltyId, ActorId, ActorName, EventType, Detail)
        SELECT @NoveltyId, @ActorId, ISNULL(u.Name, @ActorId), N''registro'', @Concept
        FROM dbo.AppUsers u WHERE u.AppUserId = @ActorId;

        SELECT NoveltyId AS id, Concept AS concept, Amount AS amount, Status AS status
        FROM dbo.PayrollNovelties WHERE NoveltyId = @NoveltyId;
    END;
    ');
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CancelPayrollNovelty
    @NoveltyId NVARCHAR(100),
    @Reason NVARCHAR(500),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @RunId NVARCHAR(100), @Status NVARCHAR(30);
    SELECT @RunId = PayrollRunId, @Status = Status FROM dbo.PayrollNovelties WHERE NoveltyId = @NoveltyId;
    IF @Status IS NULL THROW 50529, 'La novedad no existe.', 1;
    IF @Status = N'cancelada' THROW 50530, 'La novedad ya está cancelada.', 1;
    IF @RunId IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId = @RunId AND Status IN (N'borrador', N'calculada')
    )
        THROW 50528, 'La novedad no se puede cancelar en el estado actual de la planilla.', 1;

    UPDATE dbo.PayrollNovelties SET Status = N'cancelada' WHERE NoveltyId = @NoveltyId;
    IF @RunId IS NOT NULL
        UPDATE dbo.PayrollRuns SET CalculationStale = 1, UpdatedAt = SYSUTCDATETIME() WHERE PayrollRunId = @RunId;

    INSERT INTO dbo.PayrollNoveltyEvents (NoveltyId, ActorId, ActorName, EventType, Detail)
    VALUES (@NoveltyId, @ActorId, @ActorName, N'cancelacion', @Reason);

    INSERT INTO dbo.PayrollHistoryEvents (PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description)
    SELECT @RunId, @ActorId, @ActorName, N'cancelacion_novedad', Status, Status, CONCAT(N'Se canceló la novedad ', @NoveltyId, N'. ', @Reason)
    FROM dbo.PayrollRuns WHERE PayrollRunId = @RunId;
END;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'raquel_erp_app')
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollEligibleEmployees TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_AddPayrollRunWorker TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RemovePayrollRunWorker TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RegisterPayrollPayment TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CancelPayrollNovelty TO [raquel_erp_app];
    GRANT SELECT, INSERT ON OBJECT::dbo.PayrollNoveltyEvents TO [raquel_erp_app];
END;
GO
