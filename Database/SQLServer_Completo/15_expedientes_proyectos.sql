/* 15 - Estados independientes y escrituras transaccionales para proyectos. */
USE [Instalaciones Raquel];
GO

IF OBJECT_ID(N'dbo.Projects', N'U') IS NULL
    THROW 50420, 'Falta dbo.Projects; ejecuta primero 04_produccion_proyectos.sql.', 1;
IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
    THROW 50421, 'Falta dbo.AppUsers; ejecuta primero los scripts de gobierno.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50422, 'Falta dbo.AuditEvents; ejecuta primero los scripts de gobierno.', 1;
GO

IF COL_LENGTH(N'dbo.Projects', N'AuthorizationStatus') IS NULL
    ALTER TABLE dbo.Projects ADD AuthorizationStatus NVARCHAR(30) NULL;
IF COL_LENGTH(N'dbo.Projects', N'OperationalStage') IS NULL
    ALTER TABLE dbo.Projects ADD OperationalStage NVARCHAR(30) NULL;
IF COL_LENGTH(N'dbo.Projects', N'CollectionStatus') IS NULL
    ALTER TABLE dbo.Projects ADD CollectionStatus NVARCHAR(30) NULL;
GO

UPDATE dbo.Projects
SET AuthorizationStatus = COALESCE(AuthorizationStatus, N'no_verificado'),
    OperationalStage = COALESCE(OperationalStage, N'no_verificado'),
    CollectionStatus = COALESCE(CollectionStatus, N'no_verificado')
WHERE AuthorizationStatus IS NULL OR OperationalStage IS NULL OR CollectionStatus IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Projects_AuthorizationStatus')
    ALTER TABLE dbo.Projects ADD CONSTRAINT CK_Projects_AuthorizationStatus
        CHECK (AuthorizationStatus IN (N'pendiente', N'autorizada', N'rechazada', N'no_verificado'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Projects_OperationalStage')
    ALTER TABLE dbo.Projects ADD CONSTRAINT CK_Projects_OperationalStage
        CHECK (OperationalStage IN (N'medicion', N'fabricacion', N'instalacion', N'entregado', N'no_verificado'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Projects_CollectionStatus')
    ALTER TABLE dbo.Projects ADD CONSTRAINT CK_Projects_CollectionStatus
        CHECK (CollectionStatus IN (N'pendiente', N'anticipo_pendiente', N'parcial', N'pagado', N'vencido', N'no_verificado'));
GO

ALTER TABLE dbo.Projects ALTER COLUMN AuthorizationStatus NVARCHAR(30) NOT NULL;
ALTER TABLE dbo.Projects ALTER COLUMN OperationalStage NVARCHAR(30) NOT NULL;
ALTER TABLE dbo.Projects ALTER COLUMN CollectionStatus NVARCHAR(30) NOT NULL;
ALTER TABLE dbo.Projects ALTER COLUMN Owner NVARCHAR(240) NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Projects') AND name = N'DF_Projects_AuthorizationStatus')
    ALTER TABLE dbo.Projects ADD CONSTRAINT DF_Projects_AuthorizationStatus DEFAULT (N'no_verificado') FOR AuthorizationStatus;
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Projects') AND name = N'DF_Projects_OperationalStage')
    ALTER TABLE dbo.Projects ADD CONSTRAINT DF_Projects_OperationalStage DEFAULT (N'no_verificado') FOR OperationalStage;
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Projects') AND name = N'DF_Projects_CollectionStatus')
    ALTER TABLE dbo.Projects ADD CONSTRAINT DF_Projects_CollectionStatus DEFAULT (N'no_verificado') FOR CollectionStatus;
GO

IF OBJECT_ID(N'dbo.ProjectEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProjectEvents
    (
        ProjectEventId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ProjectEvents PRIMARY KEY,
        ProjectId NVARCHAR(100) NOT NULL,
        MutationId UNIQUEIDENTIFIER NOT NULL,
        AppUserId NVARCHAR(100) NULL,
        ActorName NVARCHAR(240) NOT NULL,
        EventType NVARCHAR(40) NOT NULL,
        Detail NVARCHAR(1000) NOT NULL,
        OccurredAt DATETIME2(3) NOT NULL CONSTRAINT DF_ProjectEvents_OccurredAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_ProjectEvents_Projects FOREIGN KEY (ProjectId) REFERENCES dbo.Projects(ProjectId),
        CONSTRAINT FK_ProjectEvents_AppUsers FOREIGN KEY (AppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT UQ_ProjectEvents_MutationId UNIQUE (MutationId)
    );
END;
GO

IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.ProjectEvents')
          AND name = N'IX_ProjectEvents_ProjectId_OccurredAt'
)
        CREATE INDEX IX_ProjectEvents_ProjectId_OccurredAt
            ON dbo.ProjectEvents(ProjectId, OccurredAt DESC);
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateProject
    @ProjectId NVARCHAR(100),
    @Code NVARCHAR(80),
    @Name NVARCHAR(240),
    @Client NVARCHAR(240),
    @Amount DECIMAL(19,4),
    @Budget DECIMAL(19,4),
    @Owner NVARCHAR(240),
    @AppUserId NVARCHAR(100),
    @ActorName NVARCHAR(240),
    @MutationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @ExistingProjectId NVARCHAR(100);

    BEGIN TRANSACTION;
    SELECT @ExistingProjectId = ProjectId
    FROM dbo.ProjectEvents WITH (UPDLOCK, HOLDLOCK)
    WHERE MutationId = @MutationId;

    IF @ExistingProjectId IS NULL
    BEGIN
        INSERT INTO dbo.Projects (
            ProjectId, Code, Name, Client, Amount, Budget, Progress, ProjectState, Owner,
            AuthorizationStatus, OperationalStage, CollectionStatus
        )
        VALUES (
            @ProjectId, @Code, @Name, @Client, @Amount, @Budget, 0, N'Pendiente', @Owner,
            N'pendiente', N'medicion', N'pendiente'
        );

        INSERT INTO dbo.ProjectEvents (
            ProjectEventId, ProjectId, MutationId, AppUserId, ActorName, EventType, Detail
        )
        VALUES (
            NEWID(), @ProjectId, @MutationId, @AppUserId, @ActorName, N'creado', N'Expediente creado.'
        );

        INSERT INTO dbo.AuditEvents (
            AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
        )
        SELECT
            CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
            LEFT(u.Name, 200), u.AppUserId, N'crear proyecto', N'proyectos',
            CONCAT(N'Proyecto ', @Code, N' creado.'), N'info', @ProjectId
        FROM dbo.AppUsers AS u
        WHERE u.AppUserId = @AppUserId AND u.IsActive = 1;

        SET @ExistingProjectId = @ProjectId;
    END;

    SELECT ProjectId AS id, Code AS code, Name AS name, Client AS client, Amount AS amount,
           Budget AS budget, Progress AS progress, ProjectState AS state, Owner AS owner,
           AuthorizationStatus AS authorizationStatus, OperationalStage AS operationalStage,
           CollectionStatus AS collectionStatus
    FROM dbo.Projects
    WHERE ProjectId = @ExistingProjectId;
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_UpdateProjectWorkflow
    @ProjectId NVARCHAR(100),
    @AuthorizationStatus NVARCHAR(30),
    @OperationalStage NVARCHAR(30),
    @CollectionStatus NVARCHAR(30),
    @Detail NVARCHAR(1000),
    @AppUserId NVARCHAR(100),
    @ActorName NVARCHAR(240),
    @MutationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.ProjectEvents WITH (UPDLOCK, HOLDLOCK) WHERE MutationId = @MutationId)
    BEGIN
        SELECT p.ProjectId AS id, p.Code AS code, p.Name AS name, p.Client AS client,
               p.Amount AS amount, p.Budget AS budget, p.Progress AS progress, p.ProjectState AS state,
               p.Owner AS owner, p.AuthorizationStatus AS authorizationStatus,
               p.OperationalStage AS operationalStage, p.CollectionStatus AS collectionStatus
        FROM dbo.Projects AS p
        JOIN dbo.ProjectEvents AS e ON e.ProjectId = p.ProjectId
        WHERE e.MutationId = @MutationId;
        COMMIT TRANSACTION;
        RETURN;
    END;

    UPDATE dbo.Projects
    SET AuthorizationStatus = @AuthorizationStatus,
        OperationalStage = @OperationalStage,
        CollectionStatus = @CollectionStatus
    WHERE ProjectId = @ProjectId;

    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50423, 'No se encontró el proyecto solicitado.', 1;
    END;

    INSERT INTO dbo.ProjectEvents (
        ProjectEventId, ProjectId, MutationId, AppUserId, ActorName, EventType, Detail
    )
    VALUES (
        NEWID(), @ProjectId, @MutationId, @AppUserId, @ActorName, N'estado actualizado', @Detail
    );

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(u.Name, 200), u.AppUserId, N'actualizar estados de proyecto', N'proyectos',
        @Detail, N'info', @ProjectId
    FROM dbo.AppUsers AS u
    WHERE u.AppUserId = @AppUserId AND u.IsActive = 1;

    SELECT ProjectId AS id, Code AS code, Name AS name, Client AS client, Amount AS amount,
           Budget AS budget, Progress AS progress, ProjectState AS state, Owner AS owner,
           AuthorizationStatus AS authorizationStatus, OperationalStage AS operationalStage,
           CollectionStatus AS collectionStatus
    FROM dbo.Projects
    WHERE ProjectId = @ProjectId;
    COMMIT TRANSACTION;
END;
GO

IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateProject TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_UpdateProjectWorkflow TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.Projects TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.ProjectEvents TO [raquel_erp_app];
END;
GO
