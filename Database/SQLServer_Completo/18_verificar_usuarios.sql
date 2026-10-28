/* ============================================================================
   18 — CONSULTA Y VERIFICACIÓN DE USUARIOS E INVITACIONES EN SQL SERVER
   Base de datos: [Instalaciones Raquel]
   Instancia: Laptop-Jhonny\MSSQLSERVER2025
   ============================================================================ */

-- NOTA IMPORTANTE: El nombre de la base de datos contiene un espacio ("Instalaciones Raquel"),
-- por lo que en T-SQL SIEMPRE debe escribirse entre corchetes: USE [Instalaciones Raquel];
USE [Instalaciones Raquel];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================================================';
PRINT '1. RESUMEN GENERAL DE CUENTAS EN LA BASE DE DATOS';
PRINT '============================================================================';

SELECT 
    COUNT(*)                                                          AS [Total_Usuarios],
    SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END)                     AS [Usuarios_Activos],
    SUM(CASE WHEN PasswordHash IS NOT NULL THEN 1 ELSE 0 END)          AS [Con_Contrasena_Definida],
    SUM(CASE WHEN PasswordHash IS NULL THEN 1 ELSE 0 END)              AS [Pendientes_De_Activacion],
    SUM(CASE WHEN LockedUntil IS NOT NULL AND LockedUntil > SYSUTCDATETIME() THEN 1 ELSE 0 END) AS [Bloqueados_Temporalmente]
FROM dbo.AppUsers;
GO

PRINT '============================================================================';
PRINT '2. DETALLE DE USUARIOS, JERARQUÍAS Y ESTADO DE INVITACIÓN';
PRINT '============================================================================';

SELECT 
    u.AppUserId                                             AS [ID_Usuario],
    u.Name                                                  AS [Nombre_Colaborador],
    u.Email                                                 AS [Correo_Electronico],
    u.Hierarchy                                             AS [Jerarquia_Rol],
    CASE 
        WHEN u.IsActive = 1 THEN N'Activo' 
        ELSE N'Suspendido' 
    END                                                     AS [Estado_Cuenta],
    CASE 
        WHEN u.PasswordHash IS NOT NULL THEN N'Sí (Listo para ingresar)' 
        ELSE N'No (Requiere invitación o clave directa)' 
    END                                                     AS [Tiene_Contrasena],
    u.FailedLoginCount                                      AS [Intentos_Fallidos],
    u.LockedUntil                                           AS [Bloqueado_Hasta],
    i.InvitationId                                          AS [ID_Invitacion],
    i.TokenPrefix                                           AS [Prefijo_Token_8char],
    i.DeliveryMethod                                        AS [Metodo_Entrega],
    i.DeliveryStatus                                        AS [Estado_Invitacion],
    i.CreatedAt                                             AS [Invitacion_Generada_El],
    i.ExpiresAt                                             AS [Invitacion_Vence_El],
    i.UsedAt                                                AS [Invitacion_Aceptada_El]
FROM dbo.AppUsers AS u
LEFT JOIN dbo.AppUserInvitations AS i 
    ON u.AppUserId = i.AppUserId
ORDER BY u.Name ASC;
GO

PRINT '============================================================================';
PRINT '3. ÁREAS OPERATIVAS ASIGNADAS A CADA USUARIO';
PRINT '============================================================================';

SELECT 
    u.Name                  AS [Colaborador],
    u.Email                 AS [Correo],
    u.Hierarchy             AS [Jerarquia],
    STRING_AGG(a.Area, N', ') AS [Areas_Autorizadas]
FROM dbo.AppUsers AS u
LEFT JOIN dbo.AppUserAreas AS a 
    ON u.AppUserId = a.AppUserId
GROUP BY u.Name, u.Email, u.Hierarchy
ORDER BY u.Name ASC;
GO

PRINT '============================================================================';
PRINT '4. BITÁCORA DE AUDITORÍA RECIENTE (ÚLTIMOS EVENTOS DE SEGURIDAD)';
PRINT '============================================================================';

SELECT TOP 20
    OccurredAt              AS [Fecha_Hora],
    UserName                AS [Usuario],
    Action                  AS [Accion_Realizada],
    Module                  AS [Modulo],
    Detail                  AS [Detalle],
    Severity                AS [Severidad]
FROM dbo.AuditEvents
ORDER BY OccurredAt DESC;
GO
