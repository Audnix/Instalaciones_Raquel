/* ======================================================================================
   INSTALACIONES RAQUEL - VERIFICACIÓN DE TALENTO HUMANO Y NÓMINA EN SQL SERVER
   Base de Datos: [Instalaciones Raquel]
   Normativa: Código del Trabajo de Nicaragua (Ley 185), Ley de Concertación Tributaria (Ley 822),
              Ley de Seguridad Social (Decreto 974 / Reformas INSS) y Ley General de Higiene
              y Seguridad del Trabajo (Ley 618).
   ====================================================================================== */

USE [Instalaciones Raquel];
GO

SET NOCOUNT ON;

PRINT N'======================================================================================';
PRINT N'   COMPROBACIÓN INTEGRAL DEL MÓDULO DE TALENTO HUMANO Y NÓMINA';
PRINT N'   Fecha y Hora de Verificación: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
PRINT N'======================================================================================';
PRINT N'';

-- 1. RESUMEN GLOBAL DE REGISTROS DE PERSONAL Y PLANILLA
PRINT N'>>> 1. RESUMEN CUANTITATIVO DE ENTIDADES PRINCIPALES:';
SELECT
    (SELECT COUNT(*) FROM dbo.Employees) AS TotalColaboradores,
    (SELECT COUNT(*) FROM dbo.Employees WHERE EmploymentStatus = N'activo') AS ColaboradoresActivos,
    (SELECT COUNT(*) FROM dbo.Employees WHERE EmploymentStatus = N'baja') AS ColaboradoresDeBaja,
    (SELECT COUNT(*) FROM dbo.HrContracts) AS TotalContratosLaborales,
    (SELECT COUNT(*) FROM dbo.HrRequests) AS TotalSolicitudesRegistradas,
    (SELECT COUNT(*) FROM dbo.HrAttendanceRecords) AS RegistrosAsistencia,
    (SELECT COUNT(*) FROM dbo.HrSafetyEquipment) AS EquiposSeguridadEPP,
    (SELECT COUNT(*) FROM dbo.HrEquipmentDeliveries) AS EntregasEPPRegistradas,
    (SELECT COUNT(*) FROM dbo.HrComplianceObligations) AS ObligacionesCumplimiento,
    (SELECT COUNT(*) FROM dbo.PayrollRulesCatalog) AS ReglasNormativasNomina,
    (SELECT COUNT(*) FROM dbo.PayrollRuns) AS PlanillasGeneradas,
    (SELECT COUNT(*) FROM dbo.PayrollRunItems) AS DesglosesIndividualesNomina,
    (SELECT COUNT(*) FROM dbo.PayrollNovelties) AS NovedadesNomina,
    (SELECT COUNT(*) FROM dbo.PayrollInstitutionalObligations) AS ObligacionesInstitucionales;

-- 2. DETALLE DE EXPEDIENTES DE COLABORADORES ACTIVOS
PRINT N'';
PRINT N'>>> 2. EXPEDIENTE DE COLABORADORES ACTIVOS Y VINCULACIÓN CON SESIONES ERP:';
SELECT 
    e.EmployeeId,
    e.Name AS NombreColaborador,
    e.Position AS Cargo,
    e.Area AS AreaDepartamento,
    CONVERT(VARCHAR(10), e.HireDate, 120) AS FechaIngreso,
    e.EmploymentStatus AS EstadoLaboral,
    e.Salary AS SalarioMensualCordobas,
    ISNULL(u.Name, N'(Sin usuario vinculado)') AS UsuarioERP,
    ISNULL(u.Email, N'N/A') AS CorreoSesion,
    ISNULL(u.Hierarchy, N'N/A') AS JerarquiaAcceso
FROM dbo.Employees e
LEFT JOIN dbo.AppUsers u ON u.AppUserId = e.AppUserId
ORDER BY e.EmploymentStatus ASC, e.Name ASC;

-- 3. CONTRATOS LABORALES REGISTRADOS Y SU VIGENCIA
PRINT N'';
PRINT N'>>> 3. CONTRATOS LABORALES REGISTRADOS (CONFORME CÓDIGO DEL TRABAJO):';
SELECT 
    c.ContractNumber AS NumeroContrato,
    e.Name AS NombreColaborador,
    c.ContractType AS ModalidadContrato,
    c.Position AS PuestoContratado,
    c.WorkSchedule AS JornadaLaboral,
    CONVERT(VARCHAR(10), c.StartDate, 120) AS FechaInicio,
    ISNULL(CONVERT(VARCHAR(10), c.EndDate, 120), N'Indefinido') AS FechaFin,
    c.Status AS EstadoContrato
FROM dbo.HrContracts c
JOIN dbo.Employees e ON e.EmployeeId = c.EmployeeId
ORDER BY c.StartDate DESC;

-- 4. BANDEJA DE SOLICITUDES DE PERSONAL (VACACIONES, PERMISOS, CONSULTAS)
PRINT N'';
PRINT N'>>> 4. BANDEJA DE SOLICITUDES DE PERSONAL Y RESOLUCIÓN ADMINISTRATIVA:';
SELECT 
    r.HrRequestId,
    e.Name AS ColaboradorSolicitante,
    r.Category AS Categoria,
    CONVERT(VARCHAR(10), r.StartDate, 120) AS FechaDesde,
    CONVERT(VARCHAR(10), r.EndDate, 120) AS FechaHasta,
    r.Status AS EstadoSolicitud,
    r.Details AS MotivoOExplicacion,
    ISNULL(r.Resolution, N'(Pendiente de resolución)') AS ResolucionAdministrativa,
    CONVERT(VARCHAR(19), r.CreatedAt, 120) AS FechaEnvio
FROM dbo.HrRequests r
JOIN dbo.Employees e ON e.EmployeeId = r.EmployeeId
ORDER BY r.CreatedAt DESC;

-- 5. REGLAS NORMATIVAS Y DEDUCCIONES OFICIALES DE NICARAGUA
PRINT N'';
PRINT N'>>> 5. CATÁLOGO DE REGLAS NORMATIVAS Y DEDUCCIONES OFICIALES (INSS, DGI, INATEC):';
SELECT 
    RuleCode AS CodigoRegla,
    RuleName AS DescripcionRegla,
    ParameterJson AS ParametrosJSON,
    LawReference AS BaseLegalOficial,
    CASE WHEN IsVerified = 1 THEN N'VERIFICADA Y VIGENTE' ELSE N'PENDIENTE REVISIÓN' END AS EstadoLegal
FROM dbo.PayrollRulesCatalog
ORDER BY RuleCode ASC;

-- 6. HISTORIAL DE PLANILLAS Y CONTROL PRESUPUESTARIO
PRINT N'';
PRINT N'>>> 6. CONTROL Y EJECUCIÓN DE PLANILLAS QUINCENALES:';
SELECT 
    pr.PayrollRunId AS CodigoPlanilla,
    pr.Period AS Periodo,
    pr.PeriodType AS Modalidad,
    pr.Status AS EstadoPlanilla,
    (SELECT COUNT(*) FROM dbo.PayrollRunItems pri WHERE pri.PayrollRunId = pr.PayrollRunId) AS ColaboradoresIncluidos,
    pr.Gross AS TotalDevengado,
    pr.InssLaboral AS RetencionINSS_Laboral,
    pr.IncomeTax AS RetencionIR_DGI,
    pr.Net AS NetoAPagarColaboradores,
    pr.InssPatronal AS AporteINSS_Patronal,
    pr.Inatec AS AporteINATEC_Patronal,
    pr.EmployerCost AS CostoTotalEmpresa,
    CONVERT(VARCHAR(10), pr.StartDate, 120) AS FechaInicio,
    CONVERT(VARCHAR(10), pr.EndDate, 120) AS FechaCorte,
    CONVERT(VARCHAR(10), pr.PaymentDate, 120) AS FechaPago
FROM dbo.PayrollRuns pr
ORDER BY pr.StartDate DESC;

-- 7. DETALLE DE NÓMINA POR COLABORADOR EN LA ÚLTIMA PLANILLA
PRINT N'';
PRINT N'>>> 7. DESGLOSE INDIVIDUAL DE DEDUCCIONES Y NETO (ÚLTIMA PLANILLA CALCULADA):';
SELECT TOP 10
    pi.PayrollRunId AS CodigoPlanilla,
    e.Name AS Colaborador,
    pi.PositionSnapshot AS Cargo,
    pi.BaseSalaryMonthly AS SalarioBaseMensual,
    pi.Gross AS TotalDevengadoQuincena,
    pi.OvertimeAmount AS HorasExtrasDevengadas,
    pi.InssLaboral AS INSS_Laboral_7Pct,
    pi.IncomeTax AS IR_Retencion_DGI,
    pi.TotalDeductions AS TotalDeducciones,
    pi.Net AS NetoRecibido,
    pi.PaymentStatus AS EstadoPago
FROM dbo.PayrollRunItems pi
JOIN dbo.Employees e ON e.EmployeeId = pi.EmployeeId
ORDER BY pi.Gross DESC;

-- 8. OBLIGACIONES INSTITUCIONALES (DGI, INSS, INATEC)
PRINT N'';
PRINT N'>>> 8. OBLIGACIONES CON INSTITUCIONES DEL ESTADO GENERADAS POR NÓMINA:';
SELECT 
    pio.ObligationId,
    pio.EntityName AS EntidadBeneficiaria,
    pio.PeriodLabel AS PeriodoFiscal,
    pio.BaseAmount AS BaseImponible,
    pio.PayableAmount AS MontoPorPagar,
    CONVERT(VARCHAR(10), pio.DueDate, 120) AS FechaLimitePago,
    pio.Status AS EstadoObligacion
FROM dbo.PayrollInstitutionalObligations pio
ORDER BY pio.DueDate ASC;

-- 9. MATRIZ DE CUMPLIMIENTO LEGAL LABORAL (MITRAB / INSS / HIGIENE Y SEGURIDAD)
PRINT N'';
PRINT N'>>> 9. MATRIZ DE CUMPLIMIENTO LABORAL Y DE HIGIENE INDUSTRIAL (LEY 185 / LEY 618):';
SELECT 
    Topic AS MateriaLaboral,
    LawName AS LeyMarco,
    ArticleRef AS ArticuloReglamentario,
    ResponsibilityArea AS AreaResponsable,
    ComplianceStatus AS EstadoCumplimiento,
    ResponsibleName AS ResponsableVerificacion,
    CONVERT(VARCHAR(10), LastReviewDate, 120) AS UltimaRevision
FROM dbo.HrComplianceObligations
ORDER BY LastReviewDate DESC;

PRINT N'';
PRINT N'======================================================================================';
PRINT N'   VERIFICACIÓN DE TALENTO HUMANO Y NÓMINA COMPLETADA SATISFACTORIAMENTE';
PRINT N'======================================================================================';
GO
