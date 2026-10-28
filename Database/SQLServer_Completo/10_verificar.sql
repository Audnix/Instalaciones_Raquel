/* 10 — Verificación: tablas, FKs, vistas, procedimiento y conteos */
USE [Instalaciones Raquel];
GO

SELECT t.name AS Tabla, SUM(p.rows) AS FilasAprox
FROM sys.tables AS t
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
GROUP BY t.name
ORDER BY t.name;

SELECT fk.name AS Relacion,
       OBJECT_NAME(fk.parent_object_id) AS TablaHija,
       OBJECT_NAME(fk.referenced_object_id) AS TablaPadre
FROM sys.foreign_keys AS fk
ORDER BY TablaPadre, TablaHija;

SELECT name AS Vista FROM sys.views WHERE schema_id = SCHEMA_ID(N'dbo') ORDER BY name;

SELECT OBJECT_ID(N'dbo.usp_SaveErpState', N'P') AS ProcedimientoGuardado,
       OBJECT_ID(N'dbo.usp_UpsertSupplier', N'P') AS ProcedimientoProveedor,
       OBJECT_ID(N'dbo.usp_CreateAppPasswordReset', N'P') AS CrearCodigoRecuperacion,
       OBJECT_ID(N'dbo.usp_CompleteAppPasswordReset', N'P') AS CompletarRecuperacion,
       OBJECT_ID(N'dbo.usp_CreateProject', N'P') AS CrearProyecto,
       OBJECT_ID(N'dbo.usp_UpdateProjectWorkflow', N'P') AS ActualizarFlujoProyecto,
       OBJECT_ID(N'dbo.ProjectEvents', N'U') AS EventosProyecto,
       COL_LENGTH(N'dbo.ProjectEvents', N'ActorName') AS ActorEnEventoProyecto,
       OBJECT_ID(N'dbo.usp_CreateHrRequest', N'P') AS CrearSolicitudHr,
       OBJECT_ID(N'dbo.usp_GetHrRequests', N'P') AS ConsultarSolicitudesHr,
       OBJECT_ID(N'dbo.usp_GetHrRequestEvents', N'P') AS ConsultarEventosSolicitudHr,
       OBJECT_ID(N'dbo.usp_UpdateHrRequestStatus', N'P') AS ActualizarSolicitudHr,
       OBJECT_ID(N'dbo.usp_CreateHrEmployee', N'P') AS CrearExpedientePersonal,
       OBJECT_ID(N'dbo.usp_UpdateHrEmployee', N'P') AS ActualizarExpedientePersonal,
       OBJECT_ID(N'dbo.usp_TerminateHrEmployee', N'P') AS BajaLaboralHr,
       OBJECT_ID(N'dbo.usp_GetHrEmployeeDetail', N'P') AS DetalleExpedienteHr,
       OBJECT_ID(N'dbo.usp_GetHrEmployeeJobHistory', N'P') AS ConsultarHistorialLaboral,
       OBJECT_ID(N'dbo.usp_GetHrMyEmployee', N'P') AS ConsultarExpedientePropio,
       OBJECT_ID(N'dbo.usp_GetHrEmployeeDirectory', N'P') AS ConsultarDirectorioHr,
       OBJECT_ID(N'dbo.usp_GetHrEmployeeIdForUser', N'P') AS ResolverEmpleadoHr,
       OBJECT_ID(N'dbo.usp_GetHrDashboardMetrics', N'P') AS MetricasDashboardHr,
       OBJECT_ID(N'dbo.HrRequests', N'U') AS SolicitudesHr,
       OBJECT_ID(N'dbo.HrRequestEvents', N'U') AS EventosSolicitudHr,
       OBJECT_ID(N'dbo.EmployeeJobHistory', N'U') AS HistorialLaboral,
       OBJECT_ID(N'dbo.vw_HrEmployeeDirectory', N'V') AS DirectorioHr,
       COL_LENGTH(N'dbo.Employees', N'EmploymentStatus') AS EstadoLaboral,
       OBJECT_ID(N'dbo.HrContracts', N'U') AS ContratosHr,
       OBJECT_ID(N'dbo.HrAttendanceRecords', N'U') AS AsistenciaHr,
       OBJECT_ID(N'dbo.HrSafetyEquipment', N'U') AS EquiposSeguridadHr,
       OBJECT_ID(N'dbo.HrSafetyIncidents', N'U') AS IncidentesSeguridadHr,
       OBJECT_ID(N'dbo.HrCorrectiveActions', N'U') AS AccionesCorrectivasHr,
       OBJECT_ID(N'dbo.HrComplianceObligations', N'U') AS CumplimientoHr,
       OBJECT_ID(N'dbo.HrRightsArticles', N'U') AS DerechosOrientacionHr,
       OBJECT_ID(N'dbo.PayrollRulesCatalog', N'U') AS ReglasNomina,
       OBJECT_ID(N'dbo.PayrollRuns', N'U') AS CabeceraNomina,
       OBJECT_ID(N'dbo.PayrollRunItems', N'U') AS DetalleNomina,
       OBJECT_ID(N'dbo.PayrollNovelties', N'U') AS NovedadesNomina,
       OBJECT_ID(N'dbo.PayrollValidations', N'U') AS ValidacionesNomina,
       OBJECT_ID(N'dbo.PayrollPayments', N'U') AS PagosNomina,
       OBJECT_ID(N'dbo.PayrollInstitutionalObligations', N'U') AS ObligacionesNomina,
       OBJECT_ID(N'dbo.PayrollReceiptTickets', N'U') AS ReclamosColillaNomina,
       OBJECT_ID(N'dbo.usp_GetPayrollRuns', N'P') AS ConsultarPlanillasNomina,
       OBJECT_ID(N'dbo.usp_CreatePayrollDraft', N'P') AS CrearBorradorNomina,
       OBJECT_ID(N'dbo.usp_CalculatePayroll', N'P') AS CalcularPlanillaNomina,
       OBJECT_ID(N'dbo.usp_TransitionPayrollStatus', N'P') AS TransicionEstadoNomina,
       OBJECT_ID(N'dbo.usp_GetPayrollRunItems', N'P') AS DetalleTrabajadoresNomina,
       OBJECT_ID(N'dbo.usp_GetPayrollEmployeeReceipt', N'P') AS ComprobanteColillaNomina,
       OBJECT_ID(N'dbo.AppPasswordResetCodes', N'U') AS TablaCodigosRecuperacion,
       COL_LENGTH(N'dbo.Projects', N'AuthorizationStatus') AS EstadoAutorizacionProyecto,
       COL_LENGTH(N'dbo.Projects', N'OperationalStage') AS EtapaOperativaProyecto,
       COL_LENGTH(N'dbo.Projects', N'CollectionStatus') AS EstadoCobroProyecto,
       (SELECT COUNT(*) FROM dbo.AppUsers) AS Usuarios,
       (SELECT COUNT(*) FROM dbo.Projects) AS Proyectos,
       (SELECT COUNT(*) FROM dbo.Products) AS Productos,
       (SELECT COUNT(*) FROM dbo.Parties) AS Terceros,
       (SELECT COUNT(*) FROM dbo.Parties WHERE PartyType = N'proveedor') AS Proveedores,
       (SELECT COUNT(*) FROM dbo.HrContracts) AS ContratosRegistrados,
       (SELECT COUNT(*) FROM dbo.HrSafetyEquipment) AS EquiposSeguridad,
       (SELECT COUNT(*) FROM dbo.HrComplianceObligations) AS ObligacionesCumplimiento,
       (SELECT COUNT(*) FROM dbo.HrRightsArticles) AS ArticulosDerechos,
       (SELECT COUNT(*) FROM dbo.ErpState) AS Snapshot;

SELECT SupplierStatus AS Estado, SupplierCategory AS Categoria, COUNT(*) AS Proveedores
FROM dbo.Parties
WHERE PartyType = N'proveedor'
GROUP BY SupplierStatus, SupplierCategory
ORDER BY SupplierStatus, SupplierCategory;
GO

/* ============================================================================
   10.1 — VERIFICACIÓN DETALLADA DE USUARIOS E INVITACIONES REGISTRADAS
   ============================================================================ */
SELECT 
    u.AppUserId                                             AS [ID_Usuario],
    u.Name                                                  AS [Nombre],
    u.Email                                                 AS [Correo],
    u.Hierarchy                                             AS [Jerarquia],
    u.IsActive                                              AS [Activo],
    CASE 
        WHEN u.PasswordHash IS NOT NULL THEN N'Sí (Activada)' 
        ELSE N'No (Pendiente)' 
    END                                                     AS [Tiene_Contrasena],
    u.FailedLoginCount                                      AS [Intentos_Fallidos],
    u.LockedUntil                                           AS [Bloqueado_Hasta],
    i.InvitationId                                          AS [ID_Invitacion],
    i.TokenPrefix                                           AS [Prefijo_Token_8char],
    i.DeliveryMethod                                        AS [Metodo_Entrega],
    i.DeliveryStatus                                        AS [Estado_Invitacion],
    i.CreatedAt                                             AS [Invitacion_Creada_El],
    i.ExpiresAt                                             AS [Invitacion_Vence_El],
    i.UsedAt                                                AS [Invitacion_Usada_El]
FROM dbo.AppUsers AS u
LEFT JOIN dbo.AppUserInvitations AS i 
    ON u.AppUserId = i.AppUserId
ORDER BY u.Name ASC;
GO

