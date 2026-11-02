/* 14 - Códigos de recuperación de contraseña de un solo uso. */
USE [Instalaciones Raquel];
GO

IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
    THROW 50410, 'Falta dbo.AppUsers; ejecuta primero 13_autenticacion_y_sesiones.sql.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50411, 'Falta dbo.AuditEvents; ejecuta primero los scripts base.', 1;
IF OBJECT_ID(N'dbo.AppUserSessions', N'U') IS NULL
    THROW 50413, 'Falta dbo.AppUserSessions; ejecuta primero 13_autenticacion_y_sesiones.sql.', 1;
GO

IF OBJECT_ID(N'dbo.AppPasswordResetCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AppPasswordResetCodes
    (
        CodeId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AppPasswordResetCodes PRIMARY KEY,
        AppUserId NVARCHAR(100) NOT NULL,
        CodeHash CHAR(64) NOT NULL,
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AppPasswordResetCodes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ExpiresAt DATETIME2(3) NOT NULL,
        FailedAttempts TINYINT NOT NULL CONSTRAINT DF_AppPasswordResetCodes_FailedAttempts DEFAULT (0),
        UsedAt DATETIME2(3) NULL,
        CONSTRAINT FK_AppPasswordResetCodes_AppUsers FOREIGN KEY (AppUserId)
            REFERENCES dbo.AppUsers(AppUserId)
    );
    CREATE INDEX IX_AppPasswordResetCodes_AppUserId_CreatedAt
        ON dbo.AppPasswordResetCodes (AppUserId, CreatedAt DESC)
        INCLUDE (ExpiresAt, FailedAttempts, UsedAt);
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateAppPasswordReset
    @Email NVARCHAR(320),
    @CodeHash CHAR(64),
    @ExpiresAt DATETIME2(3)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @AppUserId NVARCHAR(100);
    DECLARE @UserEmail NVARCHAR(320);

    BEGIN TRANSACTION;
    SELECT @AppUserId = AppUserId, @UserEmail = Email
    FROM dbo.AppUsers WITH (UPDLOCK, ROWLOCK)
    WHERE Email = @Email AND IsActive = 1 AND PasswordHash IS NOT NULL;

    IF @AppUserId IS NOT NULL
    BEGIN
        UPDATE dbo.AppPasswordResetCodes
        SET UsedAt = SYSUTCDATETIME()
        WHERE AppUserId = @AppUserId AND UsedAt IS NULL;

        INSERT INTO dbo.AppPasswordResetCodes (CodeId, AppUserId, CodeHash, ExpiresAt)
        VALUES (NEWID(), @AppUserId, @CodeHash, @ExpiresAt);
    END;
    COMMIT TRANSACTION;

    IF @AppUserId IS NOT NULL
        SELECT @UserEmail AS Email;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CompleteAppPasswordReset
    @Email NVARCHAR(320),
    @CodeHash CHAR(64),
    @PasswordHash NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @CodeId UNIQUEIDENTIFIER;
    DECLARE @AppUserId NVARCHAR(100);
    DECLARE @StoredHash CHAR(64);
    DECLARE @UserName NVARCHAR(200);

    BEGIN TRANSACTION;
    SELECT TOP (1)
        @CodeId = c.CodeId,
        @AppUserId = c.AppUserId,
        @StoredHash = c.CodeHash,
        @UserName = u.Name
    FROM dbo.AppPasswordResetCodes AS c WITH (UPDLOCK, ROWLOCK)
    JOIN dbo.AppUsers AS u ON u.AppUserId = c.AppUserId
    WHERE u.Email = @Email
      AND u.IsActive = 1
      AND c.UsedAt IS NULL
      AND c.ExpiresAt > SYSUTCDATETIME()
      AND c.FailedAttempts < 5
    ORDER BY c.CreatedAt DESC;

    IF @CodeId IS NULL
    BEGIN
        COMMIT TRANSACTION;
        SELECT CAST(0 AS BIT) AS Changed;
        RETURN;
    END;

    IF @StoredHash <> @CodeHash
    BEGIN
        UPDATE dbo.AppPasswordResetCodes
        SET FailedAttempts = FailedAttempts + 1
        WHERE CodeId = @CodeId;
        COMMIT TRANSACTION;
        SELECT CAST(0 AS BIT) AS Changed;
        RETURN;
    END;

    UPDATE dbo.AppUsers
    SET PasswordHash = @PasswordHash,
        MustChangePassword = 0,
        FailedLoginCount = 0,
        LockedUntil = NULL
    WHERE AppUserId = @AppUserId AND IsActive = 1;

    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50412, 'No se pudo actualizar la contraseña del usuario.', 1;
    END;

    UPDATE dbo.AppPasswordResetCodes
    SET UsedAt = SYSUTCDATETIME()
    WHERE AppUserId = @AppUserId AND UsedAt IS NULL;

    UPDATE dbo.AppUserSessions
    SET RevokedAt = SYSUTCDATETIME()
    WHERE AppUserId = @AppUserId AND RevokedAt IS NULL;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    VALUES (
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        @UserName, @AppUserId, N'recuperación de contraseña', N'usuarios',
        N'Contraseña restablecida mediante código de correo.', N'warn'
    );

    COMMIT TRANSACTION;
    SELECT CAST(1 AS BIT) AS Changed;
END;
GO

IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateAppPasswordReset TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CompleteAppPasswordReset TO [raquel_erp_app];
END;
GO
