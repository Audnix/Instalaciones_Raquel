/* ==============================================================================
   18 — GOBIERNO DE ACCESOS, INVITACIONES SEGURAS Y REVOCACIÓN DE SESIONES
   Instalaciones Raquel — Control Seguro de Usuarios (Superadmin / Admin de Área)
   ============================================================================== */

USE [Instalaciones Raquel];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
    THROW 50400, 'Falta dbo.AppUsers; ejecuta primero los scripts base.', 1;
IF OBJECT_ID(N'dbo.AppUserAreas', N'U') IS NULL
    THROW 50405, 'Falta dbo.AppUserAreas; ejecuta primero los scripts base.', 1;
IF OBJECT_ID(N'dbo.AppUserSessions', N'U') IS NULL
    THROW 50406, 'Falta dbo.AppUserSessions; ejecuta primero 13_autenticacion_y_sesiones.sql.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50407, 'Falta dbo.AuditEvents; ejecuta primero los scripts base.', 1;
GO

/* =========================================================
   1. TABLA DE INVITACIONES INDIVIDUALES Y DE UN SOLO USO
   ========================================================= */
IF OBJECT_ID(N'dbo.AppUserInvitations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AppUserInvitations
    (
        InvitationId        UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AppUserInvitations PRIMARY KEY,
        AppUserId           NVARCHAR(100)    NOT NULL CONSTRAINT FK_AppUserInvitations_Users FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE CASCADE,
        TokenHash           CHAR(64)         NOT NULL,
        TokenPrefix         NVARCHAR(12)     NOT NULL,
        CreatedAt           DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_AppUserInvitations_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ExpiresAt           DATETIMEOFFSET(3) NOT NULL,
        CreatedByAppUserId  NVARCHAR(100)    NULL CONSTRAINT FK_AppUserInvitations_CreatedBy FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
        DeliveryMethod      NVARCHAR(40)     NOT NULL CONSTRAINT DF_AppUserInvitations_Method DEFAULT (N'manual_authorized_delivery'),
        DeliveryStatus      NVARCHAR(40)     NOT NULL CONSTRAINT DF_AppUserInvitations_Status DEFAULT (N'pending'),
        DeliveryNotes       NVARCHAR(500)    NULL,
        UsedAt              DATETIMEOFFSET(3) NULL,
        RevokedAt           DATETIMEOFFSET(3) NULL
    );

    CREATE INDEX IX_AppUserInvitations_TokenHash ON dbo.AppUserInvitations(TokenHash)
        INCLUDE (AppUserId, ExpiresAt, UsedAt, RevokedAt);
    CREATE INDEX IX_AppUserInvitations_User_Created ON dbo.AppUserInvitations(AppUserId, CreatedAt DESC);
END;
GO

/* =========================================================
   2. PROCEDIMIENTO: LISTAR USUARIOS CON ESTADO DE INVITACIÓN
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_ListAppUsersWithStatus
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ActorHierarchy NVARCHAR(50);
    SELECT @ActorHierarchy = Hierarchy FROM dbo.AppUsers WHERE AppUserId = @ActorId AND IsActive = 1;

    IF @ActorHierarchy IS NULL
        THROW 50450, 'Sesión no autorizada para consultar usuarios.', 1;

    SELECT 
        u.AppUserId,
        u.Name,
        u.Email,
        u.Hierarchy,
        u.IsActive,
        u.MustChangePassword,
        u.FailedLoginCount,
        u.LockedUntil,
        CASE WHEN u.PasswordHash IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS HasPasswordSet,
        (
            SELECT a.Area AS area
            FROM dbo.AppUserAreas AS a
            WHERE a.AppUserId = u.AppUserId
            FOR JSON PATH
        ) AS AreasJson,
        (
            SELECT TOP (1) 
                inv.InvitationId,
                inv.TokenPrefix,
                inv.CreatedAt,
                inv.ExpiresAt,
                inv.DeliveryMethod,
                inv.DeliveryStatus,
                inv.DeliveryNotes,
                CASE 
                    WHEN inv.UsedAt IS NOT NULL THEN N'usada'
                    WHEN inv.RevokedAt IS NOT NULL THEN N'revocada'
                    WHEN inv.ExpiresAt <= SYSUTCDATETIME() THEN N'vencida'
                    ELSE N'activa'
                END AS State
            FROM dbo.AppUserInvitations inv
            WHERE inv.AppUserId = u.AppUserId
            ORDER BY inv.CreatedAt DESC
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS LatestInvitationJson,
        (
            SELECT COUNT(*)
            FROM dbo.AppUserSessions s
            WHERE s.AppUserId = u.AppUserId AND s.RevokedAt IS NULL AND s.ExpiresAt > SYSUTCDATETIME()
        ) AS ActiveSessionsCount
    FROM dbo.AppUsers u
    ORDER BY u.Name;
END;
GO

/* =========================================================
   3. PROCEDIMIENTO: CREAR USUARIO Y GENERAR INVITACIÓN SEGURA
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_CreateUserWithInvitation
    @ActorId            NVARCHAR(100),
    @Name               NVARCHAR(200),
    @Email              NVARCHAR(320),
    @Hierarchy          NVARCHAR(50),
    @AreasJson          NVARCHAR(MAX),
    @DeliveryMethod     NVARCHAR(40),
    @DeliveryStatus     NVARCHAR(40),
    @DeliveryNotes      NVARCHAR(500),
    @TokenHash          CHAR(64),
    @TokenPrefix        NVARCHAR(12),
    @ExpiresAt          DATETIMEOFFSET(3)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ActorHierarchy NVARCHAR(50);
    DECLARE @ActorName NVARCHAR(200);

    SELECT @ActorHierarchy = Hierarchy, @ActorName = Name
    FROM dbo.AppUsers
    WHERE AppUserId = @ActorId AND IsActive = 1;

    IF @ActorHierarchy IS NULL
        THROW 50451, 'Actor no autenticado.', 1;

    -- Validar privilegios: un administrador no puede crear superadmins ni administradores superiores
    IF @ActorHierarchy = N'administrador' AND @Hierarchy IN (N'superadmin', N'administrador')
        THROW 50452, 'Un administrador de área solo puede crear usuarios estándar o invitados dentro de su área.', 1;

    IF @ActorHierarchy NOT IN (N'superadmin', N'administrador')
        THROW 50453, 'No tienes permisos para crear cuentas de usuario.', 1;

    IF NULLIF(LTRIM(RTRIM(@Email)), N'') IS NULL OR @Email NOT LIKE N'%@%.%'
        THROW 50454, 'Correo electrónico no válido.', 1;

    IF NULLIF(LTRIM(RTRIM(@Name)), N'') IS NULL
        THROW 50455, 'El nombre completo es requerido.', 1;

    BEGIN TRANSACTION;

    DECLARE @TargetUserId NVARCHAR(100);
    SELECT @TargetUserId = AppUserId FROM dbo.AppUsers WHERE LOWER(Email) = LOWER(@Email);

    IF @TargetUserId IS NULL
    BEGIN
        SET @TargetUserId = CONCAT(N'u-', LOWER(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N'')));
        INSERT INTO dbo.AppUsers (AppUserId, Name, Email, Hierarchy, IsActive, MustChangePassword, FailedLoginCount)
        VALUES (@TargetUserId, @Name, LOWER(@Email), @Hierarchy, 1, 1, 0);
    END
    ELSE
    BEGIN
        UPDATE dbo.AppUsers
        SET Name = @Name, Hierarchy = @Hierarchy, IsActive = 1, MustChangePassword = 1
        WHERE AppUserId = @TargetUserId;
    END;

    -- Sincronizar Áreas
    DELETE FROM dbo.AppUserAreas WHERE AppUserId = @TargetUserId;
    IF @AreasJson IS NOT NULL AND ISJSON(@AreasJson) = 1
    BEGIN
        INSERT INTO dbo.AppUserAreas (AppUserId, Area)
        SELECT DISTINCT @TargetUserId, [value]
        FROM OPENJSON(@AreasJson);
    END;

    -- Invalidar invitaciones anteriores no usadas
    UPDATE dbo.AppUserInvitations
    SET RevokedAt = SYSUTCDATETIME()
    WHERE AppUserId = @TargetUserId AND UsedAt IS NULL AND RevokedAt IS NULL;

    -- Insertar nueva invitación
    DECLARE @InvitationId UNIQUEIDENTIFIER = NEWID();
    INSERT INTO dbo.AppUserInvitations (
        InvitationId, AppUserId, TokenHash, TokenPrefix, ExpiresAt,
        CreatedByAppUserId, DeliveryMethod, DeliveryStatus, DeliveryNotes
    )
    VALUES (
        @InvitationId, @TargetUserId, @TokenHash, @TokenPrefix, @ExpiresAt,
        @ActorId, @DeliveryMethod, @DeliveryStatus, @DeliveryNotes
    );

    -- Registrar auditoría sellada
    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    VALUES (
        CONVERT(NVARCHAR(36), NEWID()),
        TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        @ActorName,
        @ActorId,
        N'crear invitación',
        N'usuarios',
        CONCAT(N'Invitación creada para ', @Name, N' (', @Email, N') con rol ', @Hierarchy, N'. Entrega: ', @DeliveryMethod),
        N'info'
    );

    COMMIT TRANSACTION;

    SELECT @TargetUserId AS AppUserId, @InvitationId AS InvitationId;
END;
GO

/* =========================================================
   4. PROCEDIMIENTO: REENVIAR / REGENERAR INVITACIÓN
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_ResendUserInvitation
    @ActorId            NVARCHAR(100),
    @AppUserId          NVARCHAR(100),
    @DeliveryMethod     NVARCHAR(40),
    @DeliveryStatus     NVARCHAR(40),
    @DeliveryNotes      NVARCHAR(500),
    @TokenHash          CHAR(64),
    @TokenPrefix        NVARCHAR(12),
    @ExpiresAt          DATETIMEOFFSET(3)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ActorHierarchy NVARCHAR(50);
    DECLARE @ActorName NVARCHAR(200);

    SELECT @ActorHierarchy = Hierarchy, @ActorName = Name
    FROM dbo.AppUsers
    WHERE AppUserId = @ActorId AND IsActive = 1;

    IF @ActorHierarchy NOT IN (N'superadmin', N'administrador')
        THROW 50456, 'No tienes permisos para reenviar invitaciones.', 1;

    DECLARE @TargetName NVARCHAR(200);
    DECLARE @TargetEmail NVARCHAR(320);
    SELECT @TargetName = Name, @TargetEmail = Email FROM dbo.AppUsers WHERE AppUserId = @AppUserId;

    IF @TargetName IS NULL
        THROW 50457, 'El usuario destino no existe.', 1;

    BEGIN TRANSACTION;

    -- Invalidar invitaciones anteriores
    UPDATE dbo.AppUserInvitations
    SET RevokedAt = SYSUTCDATETIME()
    WHERE AppUserId = @AppUserId AND UsedAt IS NULL AND RevokedAt IS NULL;

    DECLARE @InvitationId UNIQUEIDENTIFIER = NEWID();
    INSERT INTO dbo.AppUserInvitations (
        InvitationId, AppUserId, TokenHash, TokenPrefix, ExpiresAt,
        CreatedByAppUserId, DeliveryMethod, DeliveryStatus, DeliveryNotes
    )
    VALUES (
        @InvitationId, @AppUserId, @TokenHash, @TokenPrefix, @ExpiresAt,
        @ActorId, @DeliveryMethod, @DeliveryStatus, @DeliveryNotes
    );

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    VALUES (
        CONVERT(NVARCHAR(36), NEWID()),
        TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        @ActorName,
        @ActorId,
        N'reenviar invitación',
        N'usuarios',
        CONCAT(N'Nueva invitación emitida para ', @TargetName, N' (', @TargetEmail, N'). Entrega: ', @DeliveryMethod),
        N'info'
    );

    COMMIT TRANSACTION;

    SELECT @InvitationId AS InvitationId;
END;
GO

/* =========================================================
   5. PROCEDIMIENTO: VALIDAR TOKEN DE INVITACIÓN
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_ValidateInvitationToken
    @TokenHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        inv.InvitationId,
        inv.AppUserId,
        inv.ExpiresAt,
        u.Name,
        u.Email,
        u.Hierarchy,
        u.IsActive,
        (
            SELECT a.Area AS area
            FROM dbo.AppUserAreas AS a
            WHERE a.AppUserId = u.AppUserId
            FOR JSON PATH
        ) AS AreasJson
    FROM dbo.AppUserInvitations inv
    JOIN dbo.AppUsers u ON u.AppUserId = inv.AppUserId
    WHERE inv.TokenHash = @TokenHash
      AND inv.UsedAt IS NULL
      AND inv.RevokedAt IS NULL
      AND inv.ExpiresAt > SYSUTCDATETIME()
      AND u.IsActive = 1;
END;
GO

/* =========================================================
   6. PROCEDIMIENTO: ACEPTAR INVITACIÓN Y ESTABLECER CONTRASEÑA
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_AcceptUserInvitation
    @TokenHash      CHAR(64),
    @PasswordHash   NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @InvitationId UNIQUEIDENTIFIER;
    DECLARE @AppUserId NVARCHAR(100);
    DECLARE @UserName NVARCHAR(200);
    DECLARE @Email NVARCHAR(320);

    BEGIN TRANSACTION;

    SELECT TOP (1)
        @InvitationId = inv.InvitationId,
        @AppUserId = inv.AppUserId,
        @UserName = u.Name,
        @Email = u.Email
    FROM dbo.AppUserInvitations inv WITH (UPDLOCK, HOLDLOCK)
    JOIN dbo.AppUsers u ON u.AppUserId = inv.AppUserId
    WHERE inv.TokenHash = @TokenHash
      AND inv.UsedAt IS NULL
      AND inv.RevokedAt IS NULL
      AND inv.ExpiresAt > SYSUTCDATETIME()
      AND u.IsActive = 1;

    IF @InvitationId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50458, 'La invitación no existe, ya fue utilizada o ha expirado.', 1;
    END;

    -- Actualizar contraseña del usuario mediante hash seguro bcrypt
    UPDATE dbo.AppUsers
    SET PasswordHash = @PasswordHash,
        MustChangePassword = 0,
        FailedLoginCount = 0,
        LockedUntil = NULL,
        IsActive = 1
    WHERE AppUserId = @AppUserId;

    -- Marcar invitación como consumida de un solo uso
    UPDATE dbo.AppUserInvitations
    SET UsedAt = SYSUTCDATETIME()
    WHERE InvitationId = @InvitationId;

    -- Revocar sesiones previas por seguridad
    UPDATE dbo.AppUserSessions
    SET RevokedAt = SYSUTCDATETIME()
    WHERE AppUserId = @AppUserId AND RevokedAt IS NULL;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    VALUES (
        CONVERT(NVARCHAR(36), NEWID()),
        TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        @UserName,
        @AppUserId,
        N'activación de cuenta',
        N'usuarios',
        CONCAT(N'El usuario ', @UserName, N' (', @Email, N') estableció su contraseña mediante invitación segura.'),
        N'info'
    );

    COMMIT TRANSACTION;

    SELECT @AppUserId AS AppUserId, @UserName AS Name, @Email AS Email;
END;
GO

/* =========================================================
   7. PROCEDIMIENTO: ACTIVAR/DESACTIVAR USUARIO Y REVOCAR SESIONES
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SetAppUserStatus
    @ActorId    NVARCHAR(100),
    @AppUserId  NVARCHAR(100),
    @IsActive   BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ActorHierarchy NVARCHAR(50);
    DECLARE @ActorName NVARCHAR(200);

    SELECT @ActorHierarchy = Hierarchy, @ActorName = Name
    FROM dbo.AppUsers
    WHERE AppUserId = @ActorId AND IsActive = 1;

    IF @ActorHierarchy NOT IN (N'superadmin', N'administrador')
        THROW 50459, 'No tienes permisos para modificar el estado de usuarios.', 1;

    IF @AppUserId = @ActorId AND @IsActive = 0
        THROW 50460, 'No puedes desactivar tu propia cuenta activa.', 1;

    DECLARE @TargetName NVARCHAR(200);
    DECLARE @TargetHierarchy NVARCHAR(50);
    SELECT @TargetName = Name, @TargetHierarchy = Hierarchy FROM dbo.AppUsers WHERE AppUserId = @AppUserId;

    IF @ActorHierarchy = N'administrador' AND @TargetHierarchy IN (N'superadmin', N'administrador')
        THROW 50461, 'Un administrador de área no puede suspender a otro administrador o superadministrador.', 1;

    BEGIN TRANSACTION;

    UPDATE dbo.AppUsers
    SET IsActive = @IsActive
    WHERE AppUserId = @AppUserId;

    -- Si se desactiva, revocar de inmediato todas las sesiones abiertas
    IF @IsActive = 0
    BEGIN
        UPDATE dbo.AppUserSessions
        SET RevokedAt = SYSUTCDATETIME()
        WHERE AppUserId = @AppUserId AND RevokedAt IS NULL;
    END;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    VALUES (
        CONVERT(NVARCHAR(36), NEWID()),
        TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        @ActorName,
        @ActorId,
        CASE WHEN @IsActive = 1 THEN N'activar usuario' ELSE N'desactivar usuario' END,
        N'usuarios',
        CONCAT(N'Usuario ', @TargetName, CASE WHEN @IsActive = 1 THEN N' reactivado.' ELSE N' desactivado y sesiones revocadas.' END),
        N'warn'
    );

    COMMIT TRANSACTION;
END;
GO

/* =========================================================
   8. PROCEDIMIENTO: REVOCAR TODAS LAS SESIONES DE UN USUARIO
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_RevokeAllUserSessions
    @ActorId    NVARCHAR(100),
    @AppUserId  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ActorName NVARCHAR(200);
    SELECT @ActorName = Name FROM dbo.AppUsers WHERE AppUserId = @ActorId AND IsActive = 1;

    UPDATE dbo.AppUserSessions
    SET RevokedAt = SYSUTCDATETIME()
    WHERE AppUserId = @AppUserId AND RevokedAt IS NULL;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    VALUES (
        CONVERT(NVARCHAR(36), NEWID()),
        TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        @ActorName,
        @ActorId,
        N'revocación masiva de sesiones',
        N'usuarios',
        CONCAT(N'Todas las sesiones activas del usuario ', @AppUserId, N' fueron revocadas.'),
        N'warn'
    );
END;
GO

/* =========================================================
   9. ASIGNACIÓN DE PERMISOS AL LOGIN DE LA APLICACIÓN
   ========================================================= */
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_ListAppUsersWithStatus TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateUserWithInvitation TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ResendUserInvitation TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ValidateInvitationToken TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_AcceptUserInvitation TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_SetAppUserStatus TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RevokeAllUserSessions TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.AppUserInvitations TO [raquel_erp_app];
END;
GO

SELECT N'18 - Módulo de Invitaciones y Gobierno Seguro instalado exitosamente.' AS Resultado;
GO
