USE [Instalaciones Raquel];
GO

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
        ELSE N'No (Pendiente)' 
    END                                                     AS [Tiene_Contrasena],
    u.FailedLoginCount                                      AS [Intentos_Fallidos],
    u.LockedUntil                                           AS [Bloqueado_Hasta],
    i.InvitationId                                          AS [ID_Invitacion],
    i.TokenPrefix                                           AS [Prefijo_Token_8char],
    i.DeliveryMethod                                        AS [Metodo_Entrega],
    i.DeliveryStatus                                        AS [Estado_Invitacion],
    i.CreatedAt                                             AS [Invitacion_Generada_El],
    i.ExpiresAt                                             AS [Invitacion_Vence_El],
    i.UsedAt                                                AS [Invitacion_Usada_El]
FROM dbo.AppUsers AS u
LEFT JOIN dbo.AppUserInvitations AS i 
    ON u.AppUserId = i.AppUserId
ORDER BY u.Name ASC;
GO