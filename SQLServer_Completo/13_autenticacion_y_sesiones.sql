/* 13 - Credenciales, bloqueo de intentos y sesiones revocables para la API. */
USE [Instalaciones Raquel];
GO

IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
    THROW 50400, 'Falta dbo.AppUsers; ejecuta primero los scripts base y 08_semilla.sql.', 1;
IF OBJECT_ID(N'dbo.AppUserAreas', N'U') IS NULL
    THROW 50405, 'Falta dbo.AppUserAreas; ejecuta primero los scripts base.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50406, 'Falta dbo.AuditEvents; ejecuta primero los scripts base.', 1;
GO

IF COL_LENGTH(N'dbo.AppUsers', N'PasswordHash') IS NULL
    ALTER TABLE dbo.AppUsers ADD PasswordHash NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.AppUsers', N'FailedLoginCount') IS NULL
    ALTER TABLE dbo.AppUsers ADD FailedLoginCount INT NOT NULL
        CONSTRAINT DF_AppUsers_FailedLoginCount DEFAULT (0) WITH VALUES;
IF COL_LENGTH(N'dbo.AppUsers', N'LockedUntil') IS NULL
    ALTER TABLE dbo.AppUsers ADD LockedUntil DATETIME2(3) NULL;
IF COL_LENGTH(N'dbo.AppUsers', N'MustChangePassword') IS NULL
    ALTER TABLE dbo.AppUsers ADD MustChangePassword BIT NOT NULL
        CONSTRAINT DF_AppUsers_MustChangePassword DEFAULT (1) WITH VALUES;
GO

IF OBJECT_ID(N'dbo.AppUserSessions', N'U') IS NULL
CREATE TABLE dbo.AppUserSessions
(
    SessionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AppUserSessions PRIMARY KEY,
    AppUserId NVARCHAR(100) NOT NULL,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AppUserSessions_CreatedAt DEFAULT (SYSUTCDATETIME()),
    ExpiresAt DATETIME2(3) NOT NULL,
    RevokedAt DATETIME2(3) NULL,
    CONSTRAINT FK_AppUserSessions_AppUsers FOREIGN KEY (AppUserId)
        REFERENCES dbo.AppUsers(AppUserId)
);
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetAppUserForLogin
    @Email NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.AppUserId, u.Name, u.Email, u.Hierarchy, u.IsActive,
           u.PasswordHash, u.FailedLoginCount, u.LockedUntil, u.MustChangePassword,
           (SELECT a.Area AS area
            FROM dbo.AppUserAreas AS a
            WHERE a.AppUserId = u.AppUserId
            FOR JSON PATH) AS AreasJson
    FROM dbo.AppUsers AS u
    WHERE u.Email = @Email;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RecordFailedAppLogin
    @Email NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @UserId NVARCHAR(100);
    DECLARE @UserName NVARCHAR(200);
    BEGIN TRANSACTION;
    SELECT @UserId = AppUserId, @UserName = Name
    FROM dbo.AppUsers WITH (UPDLOCK, ROWLOCK)
    WHERE Email = @Email AND IsActive = 1;

    IF @UserId IS NOT NULL
    BEGIN
        UPDATE dbo.AppUsers
        SET FailedLoginCount = CASE WHEN FailedLoginCount >= 4 THEN 0 ELSE FailedLoginCount + 1 END,
            LockedUntil = CASE WHEN FailedLoginCount >= 4
                THEN DATEADD(MINUTE, 15, SYSUTCDATETIME()) ELSE LockedUntil END
        WHERE AppUserId = @UserId;

        INSERT INTO dbo.AuditEvents (
            AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
        )
        VALUES (
            CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
            @UserName, @UserId, N'acceso denegado', N'usuarios', N'Intento de autenticación fallido.', N'warn'
        );
    END;
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ResetFailedAppLogin
    @AppUserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.AppUsers
    SET FailedLoginCount = 0, LockedUntil = NULL
    WHERE AppUserId = @AppUserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateAppUserSession
    @SessionId UNIQUEIDENTIFIER,
    @AppUserId NVARCHAR(100),
    @ExpiresAt DATETIME2(3)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @AppUserId AND IsActive = 1 AND PasswordHash IS NOT NULL
            AND (LockedUntil IS NULL OR LockedUntil <= SYSUTCDATETIME())
    )
        THROW 50401, 'No se puede crear una sesión para este usuario.', 1;

    INSERT INTO dbo.AppUserSessions (SessionId, AppUserId, ExpiresAt)
    VALUES (@SessionId, @AppUserId, @ExpiresAt);

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    SELECT CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
           Name, AppUserId, N'inicio de sesión', N'usuarios', N'Sesión autenticada.', N'info'
    FROM dbo.AppUsers
    WHERE AppUserId = @AppUserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetAppUserSession
    @SessionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.AppUserId, u.Name, u.Email, u.Hierarchy, u.IsActive, u.MustChangePassword,
           s.ExpiresAt,
           (SELECT a.Area AS area
            FROM dbo.AppUserAreas AS a
            WHERE a.AppUserId = u.AppUserId
            FOR JSON PATH) AS AreasJson
    FROM dbo.AppUserSessions AS s
    JOIN dbo.AppUsers AS u ON u.AppUserId = s.AppUserId
    WHERE s.SessionId = @SessionId
      AND s.RevokedAt IS NULL
      AND s.ExpiresAt > SYSUTCDATETIME()
      AND u.IsActive = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RevokeAppUserSession
    @SessionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @AppUserId NVARCHAR(100);
    DECLARE @UserName NVARCHAR(200);
    SELECT @AppUserId = u.AppUserId, @UserName = u.Name
    FROM dbo.AppUserSessions AS s
    JOIN dbo.AppUsers AS u ON u.AppUserId = s.AppUserId
    WHERE s.SessionId = @SessionId AND s.RevokedAt IS NULL;

    UPDATE dbo.AppUserSessions
    SET RevokedAt = SYSUTCDATETIME()
    WHERE SessionId = @SessionId AND RevokedAt IS NULL;

    IF @AppUserId IS NOT NULL
        INSERT INTO dbo.AuditEvents (
            AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
        )
        VALUES (
            CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
            @UserName, @AppUserId, N'cierre de sesión', N'usuarios', N'Sesión revocada.', N'info'
        );
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ChangeAppUserPassword
    @AppUserId NVARCHAR(100),
    @SessionId UNIQUEIDENTIFIER,
    @PasswordHash NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    UPDATE dbo.AppUsers
    SET PasswordHash = @PasswordHash,
        MustChangePassword = 0,
        FailedLoginCount = 0,
        LockedUntil = NULL
    WHERE AppUserId = @AppUserId AND IsActive = 1;
    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50402, 'No se pudo actualizar la contraseña del usuario.', 1;
    END;
    UPDATE dbo.AppUserSessions
    SET RevokedAt = SYSUTCDATETIME()
    WHERE AppUserId = @AppUserId AND SessionId <> @SessionId AND RevokedAt IS NULL;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    SELECT CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
           Name, AppUserId, N'cambio de contraseña', N'usuarios', N'Contraseña actualizada.', N'info'
    FROM dbo.AppUsers
    WHERE AppUserId = @AppUserId;
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_BootstrapSuperAdmin
    @Email NVARCHAR(320),
    @PasswordHash NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.AppUsers WITH (UPDLOCK, HOLDLOCK) WHERE PasswordHash IS NOT NULL)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50403, 'La activación inicial ya se completó.', 1;
    END;

    UPDATE dbo.AppUsers
    SET PasswordHash = @PasswordHash,
        MustChangePassword = 1,
        FailedLoginCount = 0,
        LockedUntil = NULL
    WHERE Email = @Email AND Hierarchy = N'superadmin' AND IsActive = 1;
    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50404, 'El correo no corresponde a un superadministrador activo existente.', 1;
    END;
    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    SELECT CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
           Name, AppUserId, N'activación inicial', N'usuarios', N'Credencial temporal activada.', N'critical'
    FROM dbo.AppUsers
    WHERE Email = @Email;
    COMMIT TRANSACTION;
END;
GO

IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_GetAppUserForLogin TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RecordFailedAppLogin TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ResetFailedAppLogin TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateAppUserSession TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetAppUserSession TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RevokeAppUserSession TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ChangeAppUserPassword TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_BootstrapSuperAdmin TO [raquel_erp_app];
END;
GO
