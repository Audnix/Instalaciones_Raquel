/* Incremental: ejecutar DESPUES de 29 con una cuenta administradora.
   Conserva historicos. Los pagos antiguos sin distribucion requieren revision;
   no se inventa a que empleados correspondieron. No reinstala ni siembra datos. */
USE [Instalaciones Raquel];
GO
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.PayrollPaymentAllocations', N'U') IS NULL
CREATE TABLE dbo.PayrollPaymentAllocations (
    PaymentId NVARCHAR(100) NOT NULL REFERENCES dbo.PayrollPayments(PaymentId),
    EmployeeId NVARCHAR(100) NOT NULL REFERENCES dbo.Employees(EmployeeId),
    Amount DECIMAL(19,4) NOT NULL CHECK (Amount > 0),
    CONSTRAINT PK_PayrollPaymentAllocations PRIMARY KEY (PaymentId, EmployeeId)
);
GO
CREATE OR ALTER PROCEDURE dbo.usp_RegisterPayrollPayment
    @PayrollRunId NVARCHAR(100), @Amount DECIMAL(19,4),
    @PaymentMethod NVARCHAR(60), @PaymentReference NVARCHAR(120) = NULL,
    @PaymentDate DATE = NULL, @Notes NVARCHAR(1000) = NULL,
    @IdempotencyKey UNIQUEIDENTIFIER = NULL, @EmployeeId NVARCHAR(100) = NULL,
    @ActorId NVARCHAR(100), @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @IdempotencyKey IS NULL OR @PaymentDate IS NULL OR NULLIF(LTRIM(RTRIM(@PaymentReference)),N'') IS NULL
        THROW 50600, 'El pago requiere identificador, fecha y referencia.', 1;
    IF @Amount IS NULL OR @Amount <= 0 OR @Amount <> ROUND(@Amount,2)
        THROW 50600, 'Indica un importe positivo con hasta dos decimales.', 1;
    DECLARE @Method NVARCHAR(30) = CASE LOWER(@PaymentMethod)
        WHEN N'transferencia_bancaria' THEN N'transferencia'
        WHEN N'caja' THEN N'efectivo' ELSE LOWER(@PaymentMethod) END;
    IF @Method NOT IN (N'efectivo',N'transferencia',N'cheque',N'tarjeta',N'otro') OR @Method IS NULL
        THROW 50600, 'Medio de pago no reconocido.', 1;
    DECLARE @Payload NVARCHAR(MAX) = (SELECT @PayrollRunId AS runId, @EmployeeId AS employeeId,
        @Amount AS amount, @Method AS method, @PaymentReference AS reference,
        @PaymentDate AS paymentDate, @Notes AS notes FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES);
    DECLARE @Hash VARBINARY(32) = HASHBYTES('SHA2_256', @Payload);
    DECLARE @Status NVARCHAR(30), @Net DECIMAL(19,4), @Paid DECIMAL(19,4), @Version INT,
        @Stale BIT, @Calculated DATETIMEOFFSET(3), @Session NVARCHAR(100), @SessionDate DATE,
        @Currency NVARCHAR(10), @Lock INT, @Existing NVARCHAR(100);
    DECLARE @Account NVARCHAR(30) = CASE WHEN @Method=N'efectivo' THEN N'caja' ELSE N'banco' END;
    DECLARE @Allocation TABLE (EmployeeId NVARCHAR(100) PRIMARY KEY, Amount DECIMAL(19,4));
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Serializa la misma clave incluso si se intenta usar en otra planilla.
        DECLARE @Resource NVARCHAR(255)=N'payroll-payment:'+CONVERT(NVARCHAR(36),@IdempotencyKey);
        EXEC @Lock=sys.sp_getapplock @Resource=@Resource, @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=10000;
        IF @Lock < 0 THROW 50601, 'Otra solicitud procesa este pago. Reintenta con la misma clave.', 1;
        SELECT @Existing=PaymentId FROM dbo.PayrollPayments WHERE IdempotencyKey=@IdempotencyKey;
        IF @Existing IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.PayrollPayments WHERE PaymentId=@Existing AND (RequestHash IS NULL OR RequestHash<>@Hash))
                THROW 50602, 'El identificador ya fue usado con otros datos. Revisa el pago existente.', 1;
            COMMIT;
            SELECT N'repetida' AS Resultado, PaymentId, PayrollRunId, Amount, CashMoveId
            FROM dbo.PayrollPayments WHERE PaymentId=@Existing;
            RETURN;
        END;
        -- El bloqueo vive hasta confirmar TODOS los efectos, no solo el SELECT.
        SELECT @Status=Status,@Net=Net,@Version=CalculationVersion,@Stale=CalculationStale,@Calculated=CalculatedAt
        FROM dbo.PayrollRuns WITH (UPDLOCK,HOLDLOCK) WHERE PayrollRunId=@PayrollRunId;
        IF @Status IS NULL THROW 50529, 'La planilla no existe.', 1;
        IF @Status NOT IN (N'aprobada',N'pago_registrado') THROW 50530, 'La planilla debe estar aprobada.', 1;
        IF @Calculated IS NULL OR ISNULL(@Version,0)<1 OR @Stale=1
            THROW 50590, 'Se requiere calculo confirmado y vigente antes de pagar.', 1;
        IF EXISTS(SELECT 1 FROM dbo.PayrollValidations WHERE PayrollRunId=@PayrollRunId AND Severity=N'bloqueante' AND IsResolved=0)
            THROW 50603, 'Existen validaciones bloqueantes pendientes.', 1;
        IF NOT EXISTS(SELECT 1 FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId)
            THROW 50603, 'La planilla no tiene trabajadores.', 1;
        IF EXISTS(SELECT 1 FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId AND (Net<0 OR ABS(Gross-TotalDeductions-Net)>0.01))
           OR EXISTS(SELECT 1 FROM dbo.PayrollRuns r WHERE r.PayrollRunId=@PayrollRunId AND
              (ABS(r.Net-(SELECT SUM(Net) FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId))>0.01
               OR ABS(r.TotalDeductions-(SELECT SUM(TotalDeductions) FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId))>0.01))
            THROW 50603, 'Cabecera, deducciones y netos no coinciden. Revisa la planilla antes de pagar.', 1;
        -- Sin inferencias sobre historicos: se exige distribucion explicita.
        IF EXISTS(SELECT 1 FROM dbo.PayrollPayments p WHERE p.PayrollRunId=@PayrollRunId AND p.Status=N'confirmado'
            AND p.Amount<>(SELECT ISNULL(SUM(a.Amount),0) FROM dbo.PayrollPaymentAllocations a WHERE a.PaymentId=p.PaymentId))
            THROW 50604, 'Hay pagos historicos sin distribucion verificada por trabajador. Requieren conciliacion.', 1;
        SELECT @Paid=ISNULL(SUM(Amount),0) FROM dbo.PayrollPayments WHERE PayrollRunId=@PayrollRunId AND Status=N'confirmado';
        IF EXISTS(SELECT 1 FROM dbo.PayrollPayments WHERE PayrollRunId=@PayrollRunId AND Status=N'confirmado'
            AND ISNULL(EmployeeId,N'')=ISNULL(@EmployeeId,N'') AND TransactionReference=@PaymentReference AND PaymentDate=@PaymentDate
            AND CASE LOWER(PaymentMethod) WHEN N'transferencia_bancaria' THEN N'transferencia' WHEN N'caja' THEN N'efectivo' ELSE LOWER(PaymentMethod) END=@Method)
            THROW 50607, 'La referencia ya tiene un pago confirmado para este beneficiario y fecha.', 1;
        IF @Amount>@Net-@Paid THROW 50592, 'El importe supera el pendiente aprobado de la planilla.', 1;
        ;WITH Pending AS (
            SELECT i.EmployeeId, i.Net-ISNULL(p.Amount,0) AS Amount
            FROM dbo.PayrollRunItems i OUTER APPLY (
                SELECT SUM(a.Amount) AS Amount FROM dbo.PayrollPaymentAllocations a JOIN dbo.PayrollPayments p ON p.PaymentId=a.PaymentId
                WHERE p.PayrollRunId=@PayrollRunId AND p.Status=N'confirmado' AND a.EmployeeId=i.EmployeeId
            ) p WHERE i.PayrollRunId=@PayrollRunId AND (@EmployeeId IS NULL OR i.EmployeeId=@EmployeeId)
        ), Ordered AS (
            SELECT *, ISNULL(SUM(Amount) OVER(ORDER BY EmployeeId ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0) AS BeforeAmount
            FROM Pending WHERE Amount>0
        )
        INSERT @Allocation SELECT EmployeeId, CASE WHEN @Amount-BeforeAmount<Amount THEN @Amount-BeforeAmount ELSE Amount END
        FROM Ordered WHERE BeforeAmount<@Amount;
        IF (SELECT ISNULL(SUM(Amount),0) FROM @Allocation)<>@Amount
            THROW 50605, 'El trabajador no pertenece a la planilla o el pago supera su pendiente.', 1;
        DECLARE @CashResource NVARCHAR(255)=N'cash-account:'+@Account;
        EXEC @Lock=sys.sp_getapplock @Resource=@CashResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
        IF @Lock<0 THROW 50601, 'La cuenta esta ocupada. Reintenta el mismo pago.', 1;
        SELECT @Session=CashSessionId,@SessionDate=SessionDate,@Currency=Currency
        FROM dbo.CashSessions WITH (UPDLOCK,HOLDLOCK) WHERE Account=@Account AND Status=N'abierta';
        IF @Session IS NULL OR @SessionDate<>@PaymentDate THROW 50606, 'Abre una sesion de la cuenta para la fecha del pago.', 1;
        IF @Currency NOT IN (N'C$',N'NIO') THROW 50606, 'La moneda de la sesion no coincide con la nomina en cordobas.', 1;
        DECLARE @Available DECIMAL(19,4);
        SELECT @Available=s.OpeningBalance+ISNULL((SELECT SUM(CASE WHEN m.MoveType=N'entrada' THEN m.Amount ELSE -m.Amount END)
            FROM dbo.CashMoves m WHERE m.SessionId=s.CashSessionId AND m.MoveState=N'confirmado'
              AND ISNULL(m.DocumentType,N'')<>N'apertura'),0)
        FROM dbo.CashSessions s WHERE s.CashSessionId=@Session;
        IF @Available<@Amount THROW 50609, 'El saldo confirmado de la sesion no cubre el pago.', 1;
        DECLARE @PaymentId NVARCHAR(100)=N'pay-'+CONVERT(NVARCHAR(36),@IdempotencyKey);
        DECLARE @CashId NVARCHAR(100)=N'cash-'+@PaymentId;
        DECLARE @Operation NVARCHAR(160)=N'pago-nomina:'+CONVERT(NVARCHAR(36),@IdempotencyKey);
        DECLARE @Date DATETIMEOFFSET(3)=TODATETIMEOFFSET(CONVERT(DATETIME2(3),@PaymentDate),N'-06:00');
        INSERT dbo.CashMoves(CashMoveId,Account,MoveType,Amount,MoveDate,MoveTime,Concept,Method,DocumentType,DocumentRef,PayrollRunId,SessionId,
            ResponsibleAppUserId,ResponsibleName,MoveState,OperationKey,CreatedBy)
        VALUES(@CashId,@Account,N'salida',@Amount,@Date,CONVERT(TIME(0),SYSDATETIMEOFFSET()),N'Pago neto de nomina '+@PayrollRunId,
            @Method,N'nomina',@PaymentReference,@PayrollRunId,@Session,@ActorId,@ActorName,N'confirmado',@Operation,@ActorName);
        INSERT dbo.PayrollPayments(PaymentId,PayrollRunId,EmployeeId,Amount,PaymentMethod,TransactionReference,PaymentDate,CashMoveId,Notes,
            ConfirmedAt,ConfirmedByAppUserId,ConfirmedByName,CalculationVersion,Status,IdempotencyKey,OperationKey,RequestHash)
        VALUES(@PaymentId,@PayrollRunId,@EmployeeId,@Amount,@PaymentMethod,@PaymentReference,@PaymentDate,@CashId,@Notes,
            SYSUTCDATETIME(),@ActorId,@ActorName,@Version,N'confirmado',@IdempotencyKey,@Operation,@Hash);
        INSERT dbo.PayrollPaymentAllocations SELECT @PaymentId,EmployeeId,Amount FROM @Allocation;
        -- Cancela deuda salarial; no vuelve a reconocer el gasto devengado.
        INSERT dbo.AccountingEntries(AccountingEntryId,EntryNumber,Description,Debit,Credit,DebitAccount,CreditAccount,
            EntryDate,ReferenceType,ReferenceId,PayrollRunId,CashMoveId,OperationKey)
        VALUES(N'entry-'+@PaymentId,N'PAG-'+CONVERT(NVARCHAR(36),@IdempotencyKey),N'Cancelacion de neto salarial',@Amount,@Amount,
            N'Sueldos por pagar',CASE WHEN @Account=N'caja' THEN N'Caja' ELSE N'Banco' END,@Date,N'payroll',@PaymentId,@PayrollRunId,@CashId,@Operation);
        UPDATE dbo.PayrollRuns SET ConfirmedPaymentsTotal=@Paid+@Amount,UpdatedAt=SYSUTCDATETIME() WHERE PayrollRunId=@PayrollRunId;
        UPDATE i SET PaymentStatus=CASE WHEN p.Paid>=i.Net THEN N'pagado' ELSE N'pago_parcial' END,
            PaymentMethod=@PaymentMethod,PaymentReference=@PaymentReference,
            PaymentConfirmedAt=CASE WHEN p.Paid>=i.Net THEN SYSUTCDATETIME() ELSE NULL END
        FROM dbo.PayrollRunItems i JOIN @Allocation x ON x.EmployeeId=i.EmployeeId
        CROSS APPLY(SELECT SUM(a.Amount) AS Paid FROM dbo.PayrollPaymentAllocations a JOIN dbo.PayrollPayments p ON p.PaymentId=a.PaymentId
            WHERE p.PayrollRunId=@PayrollRunId AND p.Status=N'confirmado' AND a.EmployeeId=i.EmployeeId) p
        WHERE i.PayrollRunId=@PayrollRunId;
        INSERT dbo.PayrollHistoryEvents(PayrollRunId,ActorId,ActorName,EventType,PreviousStatus,NewStatus,Description)
        VALUES(@PayrollRunId,@ActorId,@ActorName,N'pago',@Status,@Status,N'Pago '+@PaymentId+N'; importe '+CONVERT(NVARCHAR(30),@Amount));
        COMMIT;
        SELECT N'confirmada' AS Resultado,@PaymentId AS PaymentId,@PayrollRunId AS PayrollRunId,@Amount AS Amount,
            @CashId AS CashMoveId,@Paid+@Amount AS ConfirmedPaymentsTotal,@Net-@Paid-@Amount AS pendingPayment;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
-- Un egreso de nomina no puede anularse aisladamente y dejar el recibo pagado.
CREATE OR ALTER TRIGGER dbo.tr_PayrollCashMoveIntegrity ON dbo.CashMoves AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d JOIN dbo.PayrollPayments p ON p.CashMoveId=d.CashMoveId AND p.Status=N'confirmado'
        LEFT JOIN inserted i ON i.CashMoveId=d.CashMoveId
        WHERE i.CashMoveId IS NULL OR i.Amount<>d.Amount OR i.Account<>d.Account OR i.MoveDate<>d.MoveDate OR i.MoveState<>d.MoveState)
        THROW 50608, 'El movimiento tiene un pago confirmado. Se requiere un reverso coordinado de nomina.', 1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_PayrollPaymentIntegrityVersion
AS SELECT 30 AS version;
GO
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT SELECT ON dbo.PayrollPaymentAllocations TO [raquel_erp_app];
    GRANT EXECUTE ON dbo.usp_RegisterPayrollPayment TO [raquel_erp_app];
    GRANT EXECUTE ON dbo.usp_PayrollPaymentIntegrityVersion TO [raquel_erp_app];
END;
GO
