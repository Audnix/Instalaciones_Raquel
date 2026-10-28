-- =============================================================================
-- EMPRESA: INSTALACIONES RAQUEL S.A.
-- SISTEMA: ERP INTEGRAL DE ALUMNIO Y VIDRIO
-- MÓDULO:  TALENTO HUMANO Y NÓMINA (MEJORAS OPERATIVAS E INTERACTIVIDAD)
-- SCRIPT:  25_mejoras_gestion_talento_humano_y_nomina.sql
-- OBJETIVO: Procedimientos específicos para incluir/retirar trabajadores en planillas,
--           gestionar novedades, registrar pagos con evidencia y registrar
--           capacitaciones y acciones correctivas de seguridad (Ley 618).
-- =============================================================================

USE [Instalaciones Raquel];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1. PROCEDIMIENTO: INCLUIR TRABAJADOR EN PLANILLA (EN ESTADO BORRADOR)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AddWorkerToPayrollRun
    @PayrollRunId   NVARCHAR(100),
    @EmployeeId     NVARCHAR(100),
    @ActorId        NVARCHAR(100),
    @ActorName      NVARCHAR(240),
    @Reason         NVARCHAR(500) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunStatus NVARCHAR(30);
    DECLARE @PeriodType NVARCHAR(30);
    DECLARE @StartDate DATE;

    SELECT @RunStatus = Status, @PeriodType = PeriodType, @StartDate = StartDate
    FROM dbo.PayrollRuns
    WHERE PayrollRunId = @PayrollRunId;

    IF @RunStatus IS NULL
        THROW 50520, 'La planilla especificada no existe.', 1;

    IF @RunStatus <> N'borrador'
        THROW 50521, 'Solo se pueden agregar colaboradores a una planilla en estado Borrador.', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId
    )
        THROW 50522, 'El colaborador ya se encuentra incluido en esta planilla.', 1;

    DECLARE @EmpName NVARCHAR(240), @Position NVARCHAR(200), @Area NVARCHAR(120), @Salary DECIMAL(19,4);
    SELECT @EmpName = Name, @Position = Position, @Area = Area, @Salary = Salary
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;

    IF @EmpName IS NULL
        THROW 50523, 'El expediente de colaborador no existe en Talento Humano.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.PayrollRunItems (
            PayrollRunId, EmployeeId, PayrollItemId, PositionSnapshot, AreaSnapshot,
            BaseSalaryMonthly, PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary,
            OvertimeHours, OvertimeAmount, BonusesAmount, CommissionsAmount,
            VacationDisfruteAmount, OtherTaxableIncome, Gross,
            InssBase, InssLaboral, IrBase, IncomeTax, OtherDeductions, TotalDeductions, Net,
            InssPatronal, Inatec, Aguinaldo, VacacionesProv, IndemnizacionProv, EmployerCost,
            PaymentStatus, PaymentMethod, ReceiptStatus
        )
        VALUES (
            @PayrollRunId,
            @EmployeeId,
            @PayrollRunId + N'-' + @EmployeeId,
            @Position,
            @Area,
            @Salary,
            CASE WHEN @PeriodType = N'quincenal' THEN 15.0 ELSE 30.0 END,
            CASE WHEN @PeriodType = N'quincenal' THEN 120.0 ELSE 240.0 END,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            0, 0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            N'pendiente', N'transferencia_bancaria', N'no_generado'
        );

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType,
            PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'trabajador_incluido',
            @RunStatus, @RunStatus,
            N'Colaborador ' + @EmpName + N' (' + @EmployeeId + N') incluido en planilla. ' + COALESCE(@Reason, N'')
        );

        COMMIT TRANSACTION;

        SELECT PayrollItemId AS id, EmployeeId AS employeeId, @EmpName AS employeeName,
               PositionSnapshot AS position, AreaSnapshot AS area, Gross AS grossIncome, Net AS netPay
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
-- 2. PROCEDIMIENTO: RETIRAR TRABAJADOR DE PLANILLA (EN ESTADO BORRADOR)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_RemoveWorkerFromPayrollRun
    @PayrollRunId   NVARCHAR(100),
    @EmployeeId     NVARCHAR(100),
    @ActorId        NVARCHAR(100),
    @ActorName      NVARCHAR(240),
    @Reason         NVARCHAR(500) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunStatus NVARCHAR(30);
    SELECT @RunStatus = Status
    FROM dbo.PayrollRuns
    WHERE PayrollRunId = @PayrollRunId;

    IF @RunStatus IS NULL
        THROW 50524, 'La planilla especificada no existe.', 1;

    IF @RunStatus <> N'borrador'
        THROW 50525, 'Solo se pueden retirar colaboradores de una planilla en estado Borrador.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId
    )
        THROW 50526, 'El colaborador no forma parte de esta planilla.', 1;

    DECLARE @EmpName NVARCHAR(240);
    SELECT @EmpName = Name FROM dbo.Employees WHERE EmployeeId = @EmployeeId;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType,
            PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'trabajador_retirado',
            @RunStatus, @RunStatus,
            N'Colaborador ' + COALESCE(@EmpName, @EmployeeId) + N' retirado de la nómina. Motivo: ' + COALESCE(@Reason, N'Ajuste administrativo')
        );

        COMMIT TRANSACTION;

        SELECT @EmployeeId AS removedEmployeeId, @PayrollRunId AS payrollRunId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
-- 3. PROCEDIMIENTO: ELIMINAR / CANCELAR NOVEDAD Y MARCAR CÁLCULO COMO DESACTUALIZADO
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_DeletePayrollNovelty
    @NoveltyId  NVARCHAR(100),
    @ActorId    NVARCHAR(100),
    @ActorName  NVARCHAR(240),
    @Reason     NVARCHAR(500) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunId NVARCHAR(100);
    DECLARE @RunStatus NVARCHAR(30);
    DECLARE @Concept NVARCHAR(240);

    SELECT @RunId = n.PayrollRunId, @Concept = n.Concept, @RunStatus = r.Status
    FROM dbo.PayrollNovelties n
    LEFT JOIN dbo.PayrollRuns r ON r.PayrollRunId = n.PayrollRunId
    WHERE n.NoveltyId = @NoveltyId;

    IF @Concept IS NULL
        THROW 50527, 'La novedad indicada no existe.', 1;

    IF @RunStatus IS NOT NULL AND @RunStatus NOT IN (N'borrador', N'calculada')
        THROW 50528, 'No se pueden cancelar novedades de una planilla revisada o aprobada.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.PayrollNovelties WHERE NoveltyId = @NoveltyId;

        -- Si la planilla estaba calculada, volver a borrador para obligar recálculo transparente
        IF @RunStatus = N'calculada'
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = N'borrador'
            WHERE PayrollRunId = @RunId;

            INSERT INTO dbo.PayrollHistoryEvents (
                PayrollRunId, ActorId, ActorName, EventType,
                PreviousStatus, NewStatus, Description
            )
            VALUES (
                @RunId, @ActorId, @ActorName, N'recalculo_requerido',
                N'calculada', N'borrador',
                N'Cálculo marcado como desactualizado tras eliminar la novedad: ' + @Concept
            );
        END;

        COMMIT TRANSACTION;

        SELECT @NoveltyId AS deletedNoveltyId, @RunId AS payrollRunId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
-- 4. PROCEDIMIENTO: REGISTRAR PAGO Y DISPERSIÓN DE PLANILLA (CON EVIDENCIA)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_RegisterPayrollPayment
    @PayrollRunId       NVARCHAR(100),
    @Amount             DECIMAL(19,4),
    @PaymentMethod      NVARCHAR(60),
    @PaymentReference   NVARCHAR(120),
    @PaymentDate        DATE,
    @Notes              NVARCHAR(1000) = NULL,
    @ActorId            NVARCHAR(100),
    @ActorName          NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(30);
    DECLARE @NetTotal DECIMAL(19,4);

    SELECT @CurrentStatus = Status, @NetTotal = Net
    FROM dbo.PayrollRuns
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50529, 'La planilla indicada no existe.', 1;

    IF @CurrentStatus <> N'aprobada' AND @CurrentStatus <> N'pago_registrado'
        THROW 50530, 'Solo se puede registrar pago en planillas que han sido formalmente aprobadas.', 1;

    IF @Amount <= 0
        THROW 50531, 'El monto del pago debe ser mayor a cero.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Actualizar todos los ítems de los trabajadores a 'pagado'
        UPDATE dbo.PayrollRunItems
        SET PaymentStatus = N'pagado',
            PaymentMethod = @PaymentMethod,
            PaymentConfirmedAt = TODATETIMEOFFSET(CONVERT(DATETIME2, @PaymentDate), N'+00:00')
        WHERE PayrollRunId = @PayrollRunId;

        -- Actualizar cabecera de la planilla
        UPDATE dbo.PayrollRuns
        SET Status = N'pago_registrado',
            PaidAt = TODATETIMEOFFSET(CONVERT(DATETIME2, @PaymentDate), N'+00:00'),
            ConfirmedPaymentsTotal = @Amount,
            Notes = COALESCE(Notes, N'') + NCHAR(13) + NCHAR(10) +
                    N'[Dispersión confirmada: Ref. ' + @PaymentReference + N' por C$ ' + CONVERT(NVARCHAR(30), @Amount) +
                    N' vía ' + @PaymentMethod + N' el ' + CONVERT(NVARCHAR(10), @PaymentDate) + N']'
        WHERE PayrollRunId = @PayrollRunId;

        -- Trazabilidad de auditoría
        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType,
            PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'pago_registrado',
            @CurrentStatus, N'pago_registrado',
            N'Dispersión de nómina registrada por C$ ' + CONVERT(NVARCHAR(30), @Amount) +
            N'. Método: ' + @PaymentMethod + N' · Ref: ' + @PaymentReference + N'. ' + COALESCE(@Notes, N'')
        );

        COMMIT TRANSACTION;

        SELECT PayrollRunId AS id, Status AS status, ConfirmedPaymentsTotal AS confirmedPaymentsTotal,
               PaidAt AS paidAt
        FROM dbo.PayrollRuns
        WHERE PayrollRunId = @PayrollRunId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
-- 5. PROCEDIMIENTO: REGISTRAR CAPACITACIÓN DE SEGURIDAD (LEY 618)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_CreateHrTraining
    @Topic          NVARCHAR(200),
    @Instructor     NVARCHAR(200),
    @TrainingDate   DATE,
    @Hours          INT,
    @LegalRef       NVARCHAR(100) = N'Ley 618 Arto. 18',
    @TargetArea     NVARCHAR(100) = N'Taller y Montaje',
    @Status         NVARCHAR(30) = N'completada',
    @ActorId        NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TrainingId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO dbo.HrSafetyTrainings (
        TrainingId, Topic, Instructor, TrainingDate, Hours,
        LegalRef, TargetArea, Status
    )
    OUTPUT inserted.TrainingId AS id, inserted.Topic AS topic, inserted.TrainingDate AS trainingDate, inserted.Status AS status
    VALUES (
        @TrainingId, @Topic, @Instructor, @TrainingDate, @Hours,
        @LegalRef, @TargetArea, @Status
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 6. PROCEDIMIENTO: REGISTRAR ACCIÓN CORRECTIVA DE SEGURIDAD
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_CreateHrCorrectiveAction
    @Description        NVARCHAR(1000),
    @ResponsibleName    NVARCHAR(200),
    @DueDate            DATE,
    @Status             NVARCHAR(30) = N'abierta',
    @ActorId            NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ActionId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO dbo.HrCorrectiveActions (
        ActionId, Description, ResponsibleName, DueDate, Status
    )
    OUTPUT inserted.ActionId AS id, inserted.Description AS description, inserted.DueDate AS dueDate, inserted.Status AS status
    VALUES (
        @ActionId, @Description, @ResponsibleName, @DueDate, @Status
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 7. OTORGAR PERMISOS AL ROL DE APLICACIÓN
-- -----------------------------------------------------------------------------
IF USER_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_AddWorkerToPayrollRun TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RemoveWorkerFromPayrollRun TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_DeletePayrollNovelty TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RegisterPayrollPayment TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateHrTraining TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateHrCorrectiveAction TO [raquel_erp_app];
END;
GO

PRINT 'Migración 25 (Mejoras operativas de Talento Humano y Nómina) ejecutada con éxito.';
GO
