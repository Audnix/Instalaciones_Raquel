/* ======================================================================================
   INSTALACIONES RAQUEL - CARGA INTEGRAL DE REGISTROS DE TALENTO HUMANO Y NÓMINA
   Base de Datos: [Instalaciones Raquel]
   Marco Normativo: Código del Trabajo de Nicaragua (Ley 185),
                    Ley de Concertación Tributaria (Ley 822 / Art. 23 Retención IR),
                    Ley de Seguridad Social (INSS Laboral 7%, Patronal 21.5%, INATEC 2%),
                    Ley General de Higiene y Seguridad del Trabajo (Ley 618).
   ====================================================================================== */

USE [Instalaciones Raquel];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT N'======================================================================================';
PRINT N'   INICIANDO CARGA INTEGRAL DE DATOS REALES: TALENTO HUMANO Y NÓMINA';
PRINT N'======================================================================================';

BEGIN TRANSACTION;

-- --------------------------------------------------------------------------------------
-- 1. LIMPIEZA DE REGISTROS VOLÁTILES DE PRUEBA
-- --------------------------------------------------------------------------------------
PRINT N'1. Depurando registros volátiles de pruebas automáticas previas...';

DELETE FROM dbo.PayrollReceiptTickets WHERE PayrollRunId LIKE 'run-test%';
DELETE FROM dbo.PayrollHistoryEvents WHERE PayrollRunId LIKE 'run-test%';
DELETE FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId LIKE 'run-test%';
DELETE FROM dbo.PayrollNovelties WHERE PayrollRunId LIKE 'run-test%';
DELETE FROM dbo.PayrollRunItems WHERE PayrollRunId LIKE 'run-test%';
UPDATE dbo.PayrollRuns SET AccountingEntryId = NULL, CashMoveId = NULL WHERE PayrollRunId LIKE 'run-test%';
DELETE FROM dbo.AccountingEntries WHERE PayrollRunId LIKE 'run-test%';
DELETE FROM dbo.CashMoves WHERE PayrollRunId LIKE 'run-test%';
DELETE FROM dbo.PayrollRuns WHERE PayrollRunId LIKE 'run-test%';

DELETE FROM dbo.HrRequestEvents WHERE HrRequestId IN (SELECT HrRequestId FROM dbo.HrRequests WHERE Details LIKE '%prueba%');
DELETE FROM dbo.HrRequests WHERE Details LIKE '%prueba%';
DELETE FROM dbo.EmployeeJobHistory WHERE EmployeeId LIKE 'emp-test%';
DELETE FROM dbo.HrContracts WHERE EmployeeId LIKE 'emp-test%';
DELETE FROM dbo.HrAttendanceRecords WHERE EmployeeId LIKE 'emp-test%';
DELETE FROM dbo.HrEquipmentDeliveries WHERE EmployeeId LIKE 'emp-test%';
DELETE FROM dbo.HrEmployeeCreations WHERE EmployeeId LIKE 'emp-test%';
DELETE FROM dbo.Employees WHERE EmployeeId LIKE 'emp-test%';

-- --------------------------------------------------------------------------------------
-- 2. PLANTA LABORAL COMPLETA Y ÉTICA DE INSTALACIONES RAQUEL
-- --------------------------------------------------------------------------------------
PRINT N'2. Registrando plantilla oficial de colaboradores con salarios acordes a la ley...';

-- Tablas temporales de colaboradores
DECLARE @EmpTable TABLE (
    EmployeeId NVARCHAR(100) PRIMARY KEY,
    Name NVARCHAR(240),
    Position NVARCHAR(200),
    Salary DECIMAL(19,4),
    Area NVARCHAR(120),
    AppUserId NVARCHAR(100),
    HireDate DATE,
    EmploymentStatus NVARCHAR(20)
);

INSERT INTO @EmpTable (EmployeeId, Name, Position, Salary, Area, AppUserId, HireDate, EmploymentStatus) VALUES
(N'emp-01', N'Carlos Mendoza', N'Ingeniero de Producción y Diseño', 28000.00, N'produccion', N'u-prod', '2023-08-01', N'activo'),
(N'emp-02', N'Jhonny Garcia', N'Administrador de Operaciones y Ventas', 25000.00, N'administracion', N'u-d526347b40b34400a16d30d83990e3c1', '2023-09-15', N'activo'),
(N'emp-03', N'Francisco Valle', N'Maestro Aluminero y Supervisor de Taller', 19500.00, N'produccion', NULL, '2024-01-10', N'activo'),
(N'emp-04', N'Roberto Toruño', N'Operario de Corte y Troquelado', 14800.00, N'produccion', NULL, '2024-02-01', N'activo'),
(N'emp-05', N'Marlon Calero', N'Operario Especialista en Vidrio y Fachadas', 16000.00, N'produccion', NULL, '2024-02-15', N'activo'),
(N'emp-06', N'Wilmer Jarquín', N'Armador de Ventanería y Estructuras', 13500.00, N'produccion', NULL, '2024-03-01', N'activo'),
(N'emp-07', N'Denis Somarriba', N'Instalador Líder de Altura', 17000.00, N'produccion', NULL, '2024-01-20', N'activo'),
(N'emp-08', N'José Blandón', N'Auxiliar de Instalación y Montaje', 11200.00, N'produccion', NULL, '2024-04-15', N'activo'),
(N'emp-09', N'Kevin Rivas', N'Auxiliar de Taller y Mantenimiento', 10500.00, N'produccion', NULL, '2024-05-01', N'activo'),
(N'emp-10', N'Ana Silva', N'Ejecutiva de Ventas Técnicas y Cotizaciones', 18500.00, N'ventas', N'u-sales', '2024-01-15', N'activo'),
(N'emp-11', N'María Elena Cruz', N'Contadora General', 26000.00, N'contabilidad', N'u-fin', '2023-10-01', N'activo'),
(N'emp-12', N'Luis Morales', N'Encargado de Compras y Bodega', 17500.00, N'compras', N'u-buy', '2024-01-05', N'activo'),
(N'emp-13', N'Patricia Mayorga', N'Asistente de Recursos Humanos y Seguridad', 14500.00, N'rrhh', NULL, '2024-03-10', N'activo'),
(N'emp-14', N'Raquel López', N'Gerente General y Propietaria', 42000.00, N'direccion', N'u-super', '2023-06-01', N'activo');

UPDATE dbo.Employees SET AppUserId = NULL WHERE EmployeeId LIKE 'e%';

MERGE dbo.Employees AS target
USING @EmpTable AS source
ON target.EmployeeId = source.EmployeeId
WHEN MATCHED THEN
    UPDATE SET
        target.Name = source.Name,
        target.Position = source.Position,
        target.Salary = source.Salary,
        target.Area = source.Area,
        target.AppUserId = source.AppUserId,
        target.HireDate = source.HireDate,
        target.EmploymentStatus = source.EmploymentStatus,
        target.IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (EmployeeId, Name, Position, Salary, Area, AppUserId, HireDate, IsActive, EmploymentStatus)
    VALUES (source.EmployeeId, source.Name, source.Position, source.Salary, source.Area, source.AppUserId, source.HireDate, 1, source.EmploymentStatus);

-- --------------------------------------------------------------------------------------
-- 3. CONTRATOS LABORALES FORMALES (LEY 185, ART. 19-34)
-- --------------------------------------------------------------------------------------
PRINT N'3. Creando contratos individuales de trabajo con condiciones específicas...';

DECLARE @ContractsTable TABLE (
    ContractId UNIQUEIDENTIFIER,
    EmployeeId NVARCHAR(100),
    ContractNumber NVARCHAR(60),
    ContractType NVARCHAR(40),
    Position NVARCHAR(200),
    WorkSchedule NVARCHAR(100),
    StartDate DATE,
    EndDate DATE,
    AgreedTerms NVARCHAR(2000),
    Status NVARCHAR(30)
);

INSERT INTO @ContractsTable VALUES
('C1010001-0000-0000-0000-000000000001', N'emp-01', N'CT-RAQ-2023-001', N'indefinido', N'Ingeniero de Producción y Diseño', N'Lunes a Viernes 07:30 a 17:00, Sábados 08:00 a 12:00', '2023-08-01', NULL, N'Contrato por tiempo indeterminado. Responsable de modelado de carpintería de aluminio, despiece y control de taller. Derecho a todas las prestaciones de ley.', N'registrado'),
('C1010001-0000-0000-0000-000000000002', N'emp-02', N'CT-RAQ-2023-002', N'indefinido', N'Administrador de Operaciones y Ventas', N'Lunes a Viernes 08:00 a 17:00, Sábados 08:00 a 12:00', '2023-09-15', NULL, N'Supervisión comercial, proformas, enlace técnico con clientes y seguimiento a cumplimiento contractual.', N'registrado'),
('C1010001-0000-0000-0000-000000000003', N'emp-03', N'CT-RAQ-2024-003', N'indefinido', N'Maestro Aluminero y Supervisor de Taller', N'Lunes a Viernes 07:00 a 16:30, Sábados 07:00 a 11:30', '2024-01-10', NULL, N'Maestro de obra y taller. Control de corte, mecanizado, ensamblaje de perfiles Eurovent y líneas comerciales. Obligación de uso estricto de EPP.', N'registrado'),
('C1010001-0000-0000-0000-000000000004', N'emp-04', N'CT-RAQ-2024-004', N'indefinido', N'Operario de Corte y Troquelado', N'Lunes a Viernes 07:00 a 16:30, Sábados 07:00 a 11:30', '2024-02-01', NULL, N'Operación de tronzadoras de doble cabezal, retestadoras y troqueladoras. Protocolo estricto de seguridad industrial Ley 618.', N'registrado'),
('C1010001-0000-0000-0000-000000000005', N'emp-05', N'CT-RAQ-2024-005', N'indefinido', N'Operario Especialista en Vidrio y Fachadas', N'Lunes a Viernes 07:30 a 17:00, Sábados 08:00 a 12:00', '2024-02-15', NULL, N'Corte manual y asistido de vidrio laminado y monolítico. Instalación con ventosas y sellado estructural de silicona.', N'registrado'),
('C1010001-0000-0000-0000-000000000006', N'emp-06', N'CT-RAQ-2024-006', N'indefinido', N'Armador de Ventanería y Estructuras', N'Lunes a Viernes 07:30 a 17:00, Sábados 08:00 a 12:00', '2024-03-01', NULL, N'Armado de marcos, hojas corredizas, abatibles y muros cortina. Revisión de escuadras y felpas herméticas.', N'registrado'),
('C1010001-0000-0000-0000-000000000007', N'emp-07', N'CT-RAQ-2024-007', N'indefinido', N'Instalador Líder de Altura', N'Lunes a Viernes 07:30 a 17:00, Sábados 08:00 a 12:00', '2024-01-20', NULL, N'Instalación en sitio de fachadas flotantes y ventanería en edificios. Certificación médica obligatoria para trabajo en altura.', N'registrado'),
('C1010001-0000-0000-0000-000000000008', N'emp-08', N'CT-RAQ-2024-008', N'obra_servicio', N'Auxiliar de Instalación y Montaje', N'Lunes a Viernes 07:30 a 17:00, Sábados 08:00 a 12:00', '2024-04-15', '2026-12-31', N'Contrato determinado para proyectos comerciales del ciclo 2024-2026. Apoyo logístico, carga de vidrio y fijación en obra.', N'registrado'),
('C1010001-0000-0000-0000-000000000009', N'emp-09', N'CT-RAQ-2024-009', N'indefinido', N'Auxiliar de Taller y Mantenimiento', N'Lunes a Viernes 07:00 a 16:30, Sábados 07:00 a 11:30', '2024-05-01', NULL, N'Mantenimiento preventivo de maquinaria, orden, limpieza de perfiles y empaque para despacho seguro.', N'registrado'),
('C1010001-0000-0000-0000-000000000010', N'emp-10', N'CT-RAQ-2024-010', N'indefinido', N'Ejecutiva de Ventas Técnicas y Cotizaciones', N'Lunes a Viernes 08:00 a 17:00, Sábados 08:00 a 12:00', '2024-01-15', NULL, N'Atención en sala de ventas, levantamiento en planos, cotizaciones de perfiles y cristales, fidelización de contratistas.', N'registrado'),
('C1010001-0000-0000-0000-000000000011', N'emp-11', N'CT-RAQ-2023-011', N'indefinido', N'Contadora General', N'Lunes a Viernes 08:00 a 17:00, Sábados 08:00 a 12:00', '2023-10-01', NULL, N'Responsable de contabilidad financiera, declaraciones DGI, planillas INSS e INATEC, libros contables y conciliaciones bancarias.', N'registrado'),
('C1010001-0000-0000-0000-000000000012', N'emp-12', N'CT-RAQ-2024-012', N'indefinido', N'Encargado de Compras y Bodega', N'Lunes a Viernes 07:30 a 17:00, Sábados 08:00 a 12:00', '2024-01-05', NULL, N'Gestión con proveedores de aluminio, vidrio y herrajes, control de entradas/salidas en Kardex, inventarios físicos.', N'registrado'),
('C1010001-0000-0000-0000-000000000013', N'emp-13', N'CT-RAQ-2024-013', N'indefinido', N'Asistente de Recursos Humanos y Seguridad', N'Lunes a Viernes 08:00 a 17:00, Sábados 08:00 a 12:00', '2024-03-10', NULL, N'Expedientes de personal, asistencia biométrica, dotación de EPP, constancias laborales y soporte en gestión de talento.', N'registrado'),
('C1010001-0000-0000-0000-000000000014', N'emp-14', N'CT-RAQ-2023-014', N'indefinido', N'Gerente General y Propietaria', N'Tiempo integral y dirección estratégica', '2023-06-01', NULL, N'Dirección general, representación legal, firma autorizada bancaria y fiscal, liderazgo institucional.', N'registrado');

MERGE dbo.HrContracts AS target
USING @ContractsTable AS source
ON target.ContractNumber = source.ContractNumber
WHEN MATCHED THEN
    UPDATE SET
        target.EmployeeId = source.EmployeeId,
        target.ContractType = source.ContractType,
        target.Position = source.Position,
        target.WorkSchedule = source.WorkSchedule,
        target.StartDate = source.StartDate,
        target.EndDate = source.EndDate,
        target.AgreedTerms = source.AgreedTerms,
        target.Status = source.Status
WHEN NOT MATCHED THEN
    INSERT (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, EndDate, AgreedTerms, Status, ReviewedByAppUserId, ReviewedAt)
    VALUES (source.ContractId, source.EmployeeId, source.ContractNumber, source.ContractType, source.Position, source.WorkSchedule, source.StartDate, source.EndDate, source.AgreedTerms, source.Status, N'u-super', TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'));

-- --------------------------------------------------------------------------------------
-- 4. MARCACIONES DE ASISTENCIA Y JORNADA ORDINARIA Y EXTRAORDINARIA
-- --------------------------------------------------------------------------------------
PRINT N'4. Registrando registros de asistencia y horas laboradas quincenales...';

DECLARE @DatesTable TABLE (RecordDate DATE, ShiftName NVARCHAR(60));
INSERT INTO @DatesTable VALUES
('2026-10-01', N'Taller Diurno (8h)'),
('2026-10-02', N'Taller Diurno (8h)'),
('2026-10-03', N'Taller Diurno (8h)'),
('2026-10-05', N'Taller Diurno (8h)'),
('2026-10-06', N'Taller Diurno (8h)'),
('2026-10-07', N'Taller Diurno (8h)'),
('2026-10-08', N'Taller Diurno (8h)'),
('2026-10-09', N'Taller Diurno (8h)'),
('2026-10-10', N'Jornada Sábado (4h)'),
('2026-10-12', N'Taller Diurno (8h)'),
('2026-10-13', N'Taller Diurno (8h)'),
('2026-10-14', N'Taller Diurno (8h)'),
('2026-10-15', N'Taller Diurno (8h)');

-- Insertar asistencia para los empleados clave en cada fecha
INSERT INTO dbo.HrAttendanceRecords (
    AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut,
    ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized,
    IncidentType, IncidentNotes, Status, AuthorizedByAppUserId
)
SELECT 
    NEWID(),
    e.EmployeeId,
    d.RecordDate,
    d.ShiftName,
    CASE WHEN d.ShiftName LIKE N'%Sábado%' THEN '08:00:00' ELSE '07:30:00' END,
    CASE WHEN d.ShiftName LIKE N'%Sábado%' THEN '12:00:00' ELSE '17:00:00' END,
    CASE WHEN d.ShiftName LIKE N'%Sábado%' THEN '07:55:00' ELSE '07:25:00' END,
    CASE 
        WHEN d.ShiftName LIKE N'%Sábado%' THEN '12:05:00'
        WHEN e.EmployeeId IN (N'emp-03', N'emp-04', N'emp-07') AND d.RecordDate IN ('2026-10-07', '2026-10-14') THEN '19:30:00' -- 2.5h extras
        ELSE '17:05:00' 
    END,
    CASE 
        WHEN d.ShiftName LIKE N'%Sábado%' THEN 4.00
        WHEN e.EmployeeId IN (N'emp-03', N'emp-04', N'emp-07') AND d.RecordDate IN ('2026-10-07', '2026-10-14') THEN 10.50
        ELSE 8.00 
    END,
    CASE 
        WHEN d.ShiftName LIKE N'%Sábado%' THEN 4.00
        WHEN e.EmployeeId IN (N'emp-03', N'emp-04', N'emp-07') AND d.RecordDate IN ('2026-10-07', '2026-10-14') THEN 10.50
        ELSE 8.00 
    END,
    CASE 
        WHEN d.ShiftName LIKE N'%Sábado%' THEN 4.00
        WHEN e.EmployeeId IN (N'emp-03', N'emp-04', N'emp-07') AND d.RecordDate IN ('2026-10-07', '2026-10-14') THEN 10.50
        ELSE 8.00 
    END,
    N'ninguna',
    CASE WHEN e.EmployeeId IN (N'emp-03', N'emp-04', N'emp-07') AND d.RecordDate IN ('2026-10-07', '2026-10-14') THEN N'Horas extraordinarias autorizadas para entrega de fachada corporativa.' ELSE NULL END,
    N'autorizado_nomina',
    N'u-super'
FROM @EmpTable e
CROSS JOIN @DatesTable d
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.HrAttendanceRecords ar WHERE ar.EmployeeId = e.EmployeeId AND ar.RecordDate = d.RecordDate
);

-- --------------------------------------------------------------------------------------
-- 5. SOLICITUDES DE VACACIONES Y PERMISOS CON TRAZABILIDAD COMPLETA
-- --------------------------------------------------------------------------------------
PRINT N'5. Registrando solicitudes de personal, vacaciones y eventos de auditoría...';

DECLARE @ReqId1 UNIQUEIDENTIFIER = 'F1010001-0000-0000-0000-000000000001';
DECLARE @ReqId2 UNIQUEIDENTIFIER = 'F1010001-0000-0000-0000-000000000002';
DECLARE @ReqId3 UNIQUEIDENTIFIER = 'F1010001-0000-0000-0000-000000000003';

IF NOT EXISTS (SELECT 1 FROM dbo.HrRequests WHERE HrRequestId = @ReqId1)
BEGIN
    INSERT INTO dbo.HrRequests (HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details, Status, DecidedByAppUserId, DecidedAt, Resolution, CreatedAt)
    VALUES (@ReqId1, NEWID(), N'emp-04', N'vacaciones', '2026-09-15', '2026-09-20', N'Solicitud de 6 días de vacaciones acumuladas del primer semestre conforme Art. 76 Ley 185.', N'aprobada', N'u-super', '2026-09-10 14:30:00', N'Aprobado. Período cubierto por rotación de turnos en troquelado.', '2026-09-08 09:15:00');

    INSERT INTO dbo.HrRequestEvents (HrRequestEventId, HrRequestId, AppUserId, ActorName, EventType, Detail, OccurredAt)
    VALUES (NEWID(), @ReqId1, N'u-prod', N'Carlos Mendoza', N'enviada', N'Solicitud radicada en la plataforma.', '2026-09-08 09:15:00'),
           (NEWID(), @ReqId1, N'u-super', N'Raquel López', N'aprobada', N'Autorización formal concedida conforme saldo legal.', '2026-09-10 14:30:00');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.HrRequests WHERE HrRequestId = @ReqId2)
BEGIN
    INSERT INTO dbo.HrRequests (HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details, Status, DecidedByAppUserId, DecidedAt, Resolution, CreatedAt)
    VALUES (@ReqId2, NEWID(), N'emp-07', N'permiso', '2026-10-18', '2026-10-18', N'Permiso de media jornada para chequeo médico certificado en Policlínico Central INSS.', N'aprobada', N'u-super', '2026-10-16 11:00:00', N'Concedido con goce de salario según Art. 73 del Código del Trabajo.', '2026-10-15 16:20:00');

    INSERT INTO dbo.HrRequestEvents (HrRequestEventId, HrRequestId, AppUserId, ActorName, EventType, Detail, OccurredAt)
    VALUES (NEWID(), @ReqId2, N'u-prod', N'Carlos Mendoza', N'enviada', N'Permiso recibido con constancia de cita médica.', '2026-10-15 16:20:00'),
           (NEWID(), @ReqId2, N'u-super', N'Raquel López', N'aprobada', N'Permiso con goce salarial aprobado.', '2026-10-16 11:00:00');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.HrRequests WHERE HrRequestId = @ReqId3)
BEGIN
    INSERT INTO dbo.HrRequests (HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details, Status, CreatedAt)
    VALUES (@ReqId3, NEWID(), N'emp-10', N'consulta_laboral', NULL, NULL, N'Consulta sobre cálculo de retención IR progresivo aplicado en la última quincena.', N'en_revision', '2026-10-16 10:00:00');

    INSERT INTO dbo.HrRequestEvents (HrRequestEventId, HrRequestId, AppUserId, ActorName, EventType, Detail, OccurredAt)
    VALUES (NEWID(), @ReqId3, N'u-sales', N'Ana Silva', N'enviada', N'Consulta remitida al área contable.', '2026-10-16 10:00:00');
END;

-- --------------------------------------------------------------------------------------
-- 6. SEGURIDAD E HIGIENE INDUSTRIAL (EPP, LEY 618)
-- --------------------------------------------------------------------------------------
PRINT N'6. Registrando catálogo de EPP, entregas formalizadas e incidentes preventivos...';

DECLARE @Eq1 UNIQUEIDENTIFIER = 'E1010001-0000-0000-0000-000000000001';
DECLARE @Eq2 UNIQUEIDENTIFIER = 'E1010001-0000-0000-0000-000000000002';
DECLARE @Eq3 UNIQUEIDENTIFIER = 'E1010001-0000-0000-0000-000000000003';
DECLARE @Eq4 UNIQUEIDENTIFIER = 'E1010001-0000-0000-0000-000000000004';

IF NOT EXISTS (SELECT 1 FROM dbo.HrSafetyEquipment WHERE EquipmentId = @Eq1)
    INSERT INTO dbo.HrSafetyEquipment VALUES (@Eq1, N'Guantes Anticorte Nivel 5 de Kevlar con Nitrilo', N'vidrio', N'EN 388 / NTON', 45, 90, 1);

IF NOT EXISTS (SELECT 1 FROM dbo.HrSafetyEquipment WHERE EquipmentId = @Eq2)
    INSERT INTO dbo.HrSafetyEquipment VALUES (@Eq2, N'Ventosas Dobles de Succión de Aluminio para Vidrio', N'vidrio', N'ANSI A10.28', 12, 180, 1);

IF NOT EXISTS (SELECT 1 FROM dbo.HrSafetyEquipment WHERE EquipmentId = @Eq3)
    INSERT INTO dbo.HrSafetyEquipment VALUES (@Eq3, N'Arnés de Cuerpo Entero con Línea de Vida para Altura', N'altura', N'ANSI Z359.11', 10, 365, 1);

IF NOT EXISTS (SELECT 1 FROM dbo.HrSafetyEquipment WHERE EquipmentId = @Eq4)
    INSERT INTO dbo.HrSafetyEquipment VALUES (@Eq4, N'Gafas Panorámicas de Policarbonato Antirrayaduras', N'aluminio', N'ANSI Z87.1', 30, 120, 1);

-- Entregas formalizadas de EPP
IF NOT EXISTS (SELECT 1 FROM dbo.HrEquipmentDeliveries WHERE EmployeeId = N'emp-03')
BEGIN
    INSERT INTO dbo.HrEquipmentDeliveries (DeliveryId, EmployeeId, EquipmentId, DeliveryDate, DeliveryType, NextReplacementDate, Notes, DeliveredByAppUserId)
    VALUES (NEWID(), N'emp-03', @Eq1, '2026-08-01', N'dotacion_inicial', '2026-11-01', N'Dotación reglamentaria de guantes anticorte para taller.', N'u-super'),
           (NEWID(), N'emp-03', @Eq4, '2026-08-01', N'dotacion_inicial', '2026-12-01', N'Gafas protectoras de policarbonato para corte.', N'u-super');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.HrEquipmentDeliveries WHERE EmployeeId = N'emp-07')
BEGIN
    INSERT INTO dbo.HrEquipmentDeliveries (DeliveryId, EmployeeId, EquipmentId, DeliveryDate, DeliveryType, NextReplacementDate, Notes, DeliveredByAppUserId)
    VALUES (NEWID(), N'emp-07', @Eq3, '2026-07-15', N'dotacion_inicial', '2027-07-15', N'Arnés certificado para instalación en fachadas.', N'u-super'),
           (NEWID(), N'emp-07', @Eq2, '2026-07-15', N'dotacion_inicial', '2027-01-15', N'Kit de ventosas de seguridad para montaje de cristal templado.', N'u-super');
END;

-- Reportes preventivos e incidentes menores (Ley 618)
IF NOT EXISTS (SELECT 1 FROM dbo.HrSafetyIncidents WHERE Area = N'Área de corte de perfiles')
BEGIN
    INSERT INTO dbo.HrSafetyIncidents (IncidentId, ReportedByAppUserId, IncidentDate, Area, IncidentType, Severity, Description, ImmediateAction, Status)
    VALUES (NEWID(), N'u-prod', '2026-10-05 15:45:00', N'Área de corte de perfiles', N'condicion_insegura', N'media', N'Virutas de aluminio acumuladas cerca de la bancada de corte que obstaculizaban el tope de medida.', N'Parada momentánea y limpieza exhaustiva con aspirador industrial.', N'cerrado');
END;

-- --------------------------------------------------------------------------------------
-- 7. PLANILLA QUINCENAL OFICIAL: PERÍODO 2026-10-Q1
-- --------------------------------------------------------------------------------------
PRINT N'7. Generando corrida oficial de planilla quincenal con desgloses legales...';

DECLARE @RunId NVARCHAR(100) = N'PL-2026-10-Q1';
DECLARE @Period NVARCHAR(40) = N'2026-10-Q1 (1 al 15 Octubre)';

IF EXISTS (SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId = @RunId)
BEGIN
    DELETE FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId = @RunId;
    DELETE FROM dbo.PayrollNovelties WHERE PayrollRunId = @RunId;
    DELETE FROM dbo.PayrollRunItems WHERE PayrollRunId = @RunId;
    DELETE FROM dbo.PayrollRuns WHERE PayrollRunId = @RunId;
END;

-- Totales globales calculados
-- Suma de salarios base mensual = 274,000 C$ -> Quincena ordinaria = 137,000 C$
-- Horas extras = Francisco Valle (5h * 162.50 = 812.50 C$), Roberto Toruño (5h * 123.33 = 616.65 C$), Denis Somarriba (5h * 141.67 = 708.35 C$)
-- Total Extras = 2,137.50 C$
-- Devengado Total Quincena = 139,137.50 C$
-- INSS Laboral (7%) = 9,739.63 C$
-- Retención IR Salarial (Ley 822 Art 23) calculada por escalas = 8,452.18 C$
-- Total Deducciones = 18,191.81 C$
-- Neto a Pagar a Colaboradores = 120,945.69 C$
-- INSS Patronal (21.5%) = 29,914.56 C$
-- Aporte INATEC (2%) = 2,782.75 C$
-- Provisiones Laborales:
--   Aguinaldo (8.333%): 11,594.79 C$
--   Vacaciones (8.333%): 11,594.79 C$
--   Indemnización Antigüedad (8.333%): 11,594.79 C$
-- Costo Total Empresa = 139,137.50 + 29,914.56 + 2,782.75 + 34,784.37 = 206,619.18 C$

INSERT INTO dbo.PayrollRuns (
    PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate, Status,
    Actor, ActorUserId,
    CalculationVersion, Gross, InssLaboral, IncomeTax, OtherDeductionsTotal,
    Net, InssPatronal, Inatec, AguinaldoProvTotal, VacacionesProvTotal,
    IndemnizacionProvTotal, EmployerCost, ConfirmedPaymentsTotal, PendingDiscrepancyTotal,
    PreparedByAppUserId, PreparedAt, CalculatedByAppUserId, CalculatedAt,
    ReviewedByAppUserId, ReviewedAt, ApprovedByAppUserId, ApprovedAt,
    PaidByAppUserId, PaidAt, ReconciledByAppUserId, ReconciledAt, Notes
) VALUES (
    @RunId, @Period, N'quincenal', '2026-10-01', '2026-10-15', '2026-10-15', N'pago_registrado',
    N'María Elena Cruz', N'u-fin',
    1, 139137.50, 9739.63, 8452.18, 0.00,
    120945.69, 29914.56, 2782.75, 11594.79, 11594.79,
    11594.79, 206619.18, 120945.69, 0.00,
    N'u-fin', '2026-10-14 14:00:00', N'u-fin', '2026-10-14 14:30:00',
    N'u-fin', '2026-10-14 16:00:00', N'u-super', '2026-10-15 08:30:00',
    N'u-fin', '2026-10-15 11:00:00', N'u-fin', '2026-10-15 16:30:00',
    N'Planilla ordinaria de la primera quincena de Octubre 2026. Procesada y transferida con éxito.'
);

-- Novedades registradas para la planilla
INSERT INTO dbo.PayrollNovelties (NoveltyId, PayrollRunId, EmployeeId, NoveltyType, Concept, Amount, Hours, LegalJustification, DocReference, PeriodDate, Status, CreatedByAppUserId, AuthorizedByAppUserId)
VALUES
(NEWID(), @RunId, N'emp-03', N'horas_extra', N'Horas extraordinarias por montaje de fachada corporativa', 812.50, 5.0, N'Art. 59 y 62 Ley 185 (Recargo 100%)', N'OT-FAC-2026-088', '2026-10-07', N'procesada', N'u-fin', N'u-super'),
(NEWID(), @RunId, N'emp-04', N'horas_extra', N'Horas extraordinarias troquelado urgente de perfiles', 616.65, 5.0, N'Art. 59 y 62 Ley 185 (Recargo 100%)', N'OT-FAC-2026-088', '2026-10-07', N'procesada', N'u-fin', N'u-super'),
(NEWID(), @RunId, N'emp-07', N'horas_extra', N'Horas extraordinarias montaje en altura edificio Escala', 708.35, 5.0, N'Art. 59 y 62 Ley 185 (Recargo 100%)', N'OT-FAC-2026-089', '2026-10-14', N'procesada', N'u-fin', N'u-super');

-- --------------------------------------------------------------------------------------
-- 8. DESGLOSE INDIVIDUAL DE NÓMINA POR COLABORADOR
-- --------------------------------------------------------------------------------------
PRINT N'8. Registrando desglose quincenal individual para los 14 colaboradores...';

-- Inserción detallada por cada trabajador
INSERT INTO dbo.PayrollRunItems (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot,
    BaseSalaryMonthly, PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary,
    OvertimeHours, OvertimeAmount, BonusesAmount, CommissionsAmount,
    VacationDisfruteAmount, OtherTaxableIncome, Gross, InssBase, InssLaboral,
    IrBase, IncomeTax, OtherDeductions, TotalDeductions, Net,
    InssPatronal, Inatec, Aguinaldo, VacacionesProv, IndemnizacionProv, EmployerCost,
    PaymentStatus, PaymentMethod, PaymentReference, PaymentConfirmedAt, ReceiptStatus
)
VALUES
-- emp-01: Carlos Mendoza (28,000 C$)
(NEWID(), @RunId, N'emp-01', N'Ingeniero de Producción y Diseño', N'produccion', 28000.00, 15, 120, 14000.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 14000.00, 14000.00, 980.00, 13020.00, 946.00, 0.00, 1926.00, 12074.00, 3010.00, 280.00, 1166.67, 1166.67, 1166.67, 20790.01, N'pagado', N'transferencia_bancaria', N'BAC-TX-88401', '2026-10-15 11:15:00', N'disponible'),

-- emp-02: Jhonny Garcia (25,000 C$)
(NEWID(), @RunId, N'emp-02', N'Administrador de Operaciones y Ventas', N'administracion', 25000.00, 15, 120, 12500.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 12500.00, 12500.00, 875.00, 11625.00, 687.50, 0.00, 1562.50, 10937.50, 2687.50, 250.00, 1041.67, 1041.67, 1041.67, 18562.51, N'pagado', N'transferencia_bancaria', N'BAC-TX-88402', '2026-10-15 11:15:00', N'disponible'),

-- emp-03: Francisco Valle (19,500 C$ + 812.50 HE)
(NEWID(), @RunId, N'emp-03', N'Maestro Aluminero y Supervisor de Taller', N'produccion', 19500.00, 15, 125, 9750.00, 5, 812.50, 0.00, 0.00, 0.00, 0.00, 10562.50, 10562.50, 739.38, 9823.12, 373.47, 0.00, 1112.85, 9449.65, 2270.94, 211.25, 880.21, 880.21, 880.21, 15685.32, N'pagado', N'transferencia_bancaria', N'BAC-TX-88403', '2026-10-15 11:15:00', N'disponible'),

-- emp-04: Roberto Toruño (14,800 C$ + 616.65 HE)
(NEWID(), @RunId, N'emp-04', N'Operario de Corte y Troquelado', N'produccion', 14800.00, 15, 125, 7400.00, 5, 616.65, 0.00, 0.00, 0.00, 0.00, 8016.65, 8016.65, 561.17, 7455.48, 102.32, 0.00, 663.49, 7353.16, 1723.58, 160.33, 668.05, 668.05, 668.05, 11904.71, N'pagado', N'transferencia_bancaria', N'BAC-TX-88404', '2026-10-15 11:15:00', N'disponible'),

-- emp-05: Marlon Calero (16,000 C$)
(NEWID(), @RunId, N'emp-05', N'Operario Especialista en Vidrio y Fachadas', N'produccion', 16000.00, 15, 120, 8000.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 8000.00, 8000.00, 560.00, 7440.00, 100.00, 0.00, 660.00, 7340.00, 1720.00, 160.00, 666.67, 666.67, 666.67, 11880.01, N'pagado', N'transferencia_bancaria', N'BAC-TX-88405', '2026-10-15 11:15:00', N'disponible'),

-- emp-06: Wilmer Jarquín (13,500 C$)
(NEWID(), @RunId, N'emp-06', N'Armador de Ventanería y Estructuras', N'produccion', 13500.00, 15, 120, 6750.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 6750.00, 6750.00, 472.50, 6277.50, 0.00, 0.00, 472.50, 6277.50, 1451.25, 135.00, 562.50, 562.50, 562.50, 10023.75, N'pagado', N'transferencia_bancaria', N'BAC-TX-88406', '2026-10-15 11:15:00', N'disponible'),

-- emp-07: Denis Somarriba (17,000 C$ + 708.35 HE)
(NEWID(), @RunId, N'emp-07', N'Instalador Líder de Altura', N'produccion', 17000.00, 15, 125, 8500.00, 5, 708.35, 0.00, 0.00, 0.00, 0.00, 9208.35, 9208.35, 644.58, 8563.77, 212.97, 0.00, 857.55, 8350.80, 1979.80, 184.17, 767.36, 767.36, 767.36, 13674.40, N'pagado', N'transferencia_bancaria', N'BAC-TX-88407', '2026-10-15 11:15:00', N'disponible'),

-- emp-08: José Blandón (11,200 C$)
(NEWID(), @RunId, N'emp-08', N'Auxiliar de Instalación y Montaje', N'produccion', 11200.00, 15, 120, 5600.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 5600.00, 5600.00, 392.00, 5208.00, 0.00, 0.00, 392.00, 5208.00, 1204.00, 112.00, 466.67, 466.67, 466.67, 8316.01, N'pagado', N'transferencia_bancaria', N'BAC-TX-88408', '2026-10-15 11:15:00', N'disponible'),

-- emp-09: Kevin Rivas (10,500 C$)
(NEWID(), @RunId, N'emp-09', N'Auxiliar de Taller y Mantenimiento', N'produccion', 10500.00, 15, 120, 5250.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 5250.00, 5250.00, 367.50, 4882.50, 0.00, 0.00, 367.50, 4882.50, 1128.75, 105.00, 437.50, 437.50, 437.50, 7796.25, N'pagado', N'transferencia_bancaria', N'BAC-TX-88409', '2026-10-15 11:15:00', N'disponible'),

-- emp-10: Ana Silva (18,500 C$)
(NEWID(), @RunId, N'emp-10', N'Ejecutiva de Ventas Técnicas y Cotizaciones', N'ventas', 18500.00, 15, 120, 9250.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 9250.00, 9250.00, 647.50, 8602.50, 218.75, 0.00, 866.25, 8383.75, 1988.75, 185.00, 770.83, 770.83, 770.83, 13736.24, N'pagado', N'transferencia_bancaria', N'BAC-TX-88410', '2026-10-15 11:15:00', N'disponible'),

-- emp-11: María Elena Cruz (26,000 C$)
(NEWID(), @RunId, N'emp-11', N'Contadora General', N'contabilidad', 26000.00, 15, 120, 13000.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 13000.00, 13000.00, 910.00, 12090.00, 772.50, 0.00, 1682.50, 11317.50, 2795.00, 260.00, 1083.33, 1083.33, 1083.33, 19304.99, N'pagado', N'transferencia_bancaria', N'BAC-TX-88411', '2026-10-15 11:15:00', N'disponible'),

-- emp-12: Luis Morales (17,500 C$)
(NEWID(), @RunId, N'emp-12', N'Encargado de Compras y Bodega', N'compras', 17500.00, 15, 120, 8750.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 8750.00, 8750.00, 612.50, 8137.50, 156.25, 0.00, 768.75, 7981.25, 1881.25, 175.00, 729.17, 729.17, 729.17, 12993.76, N'pagado', N'transferencia_bancaria', N'BAC-TX-88412', '2026-10-15 11:15:00', N'disponible'),

-- emp-13: Patricia Mayorga (14,500 C$)
(NEWID(), @RunId, N'emp-13', N'Asistente de Recursos Humanos y Seguridad', N'rrhh', 14500.00, 15, 120, 7250.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 7250.00, 7250.00, 507.50, 6742.50, 71.25, 0.00, 578.75, 6671.25, 1558.75, 145.00, 604.17, 604.17, 604.17, 10766.26, N'pagado', N'transferencia_bancaria', N'BAC-TX-88413', '2026-10-15 11:15:00', N'disponible'),

-- emp-14: Raquel López (42,000 C$)
(NEWID(), @RunId, N'emp-14', N'Gerente General y Propietaria', N'direccion', 42000.00, 15, 120, 21000.00, 0, 0.00, 0.00, 0.00, 0.00, 0.00, 21000.00, 21000.00, 1470.00, 19530.00, 3707.82, 0.00, 5177.82, 15822.18, 4515.00, 420.00, 1750.00, 1750.00, 1750.00, 31185.00, N'pagado', N'transferencia_bancaria', N'BAC-TX-88414', '2026-10-15 11:15:00', N'disponible');

-- --------------------------------------------------------------------------------------
-- 9. OBLIGACIONES INSTITUCIONALES (DGI, INSS, INATEC)
-- --------------------------------------------------------------------------------------
PRINT N'9. Registrando obligaciones fiscales y de seguridad social del período...';

INSERT INTO dbo.PayrollInstitutionalObligations (
    ObligationId, PayrollRunId, EntityName, PeriodLabel,
    BaseAmount, PayableAmount, DueDate, Status, DeclarationReference
) VALUES
(N'OB-INSS-2026-10-Q1', @RunId, N'INSS', N'Octubre 2026 (Quincena 1)', 139137.50, 39654.19, '2026-11-05', N'calculada', N'VET-INSS-FACT-202610-01'),
(N'OB-DGI-2026-10-Q1', @RunId, N'DGI', N'Octubre 2026 (Quincena 1)', 139137.50, 8452.18, '2026-11-05', N'calculada', N'DGI-VET-RET-202610-01'),
(N'OB-INATEC-2026-10-Q1', @RunId, N'INATEC', N'Octubre 2026 (Quincena 1)', 139137.50, 2782.75, '2026-11-05', N'calculada', N'INATEC-APORTE-202610-01'),
(N'OB-PROV-2026-10-Q1', @RunId, N'PROVISIONES_LABORALES', N'Octubre 2026 (Quincena 1)', 139137.50, 34784.37, '2026-12-31', N'calculada', N'PROV-LEY185-202610-01');

-- --------------------------------------------------------------------------------------
-- 10. ASIENTO CONTABLE DE NÓMINA POR PARTIDA DOBLE
-- --------------------------------------------------------------------------------------
PRINT N'10. Generando asiento contable de diario balanceado (Débito == Crédito)...';

DECLARE @EntryId NVARCHAR(100) = N'AS-NOM-2026-10-01';

DELETE FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryId;

INSERT INTO dbo.AccountingEntries (
    AccountingEntryId, EntryNumber, Description, Debit, Credit,
    DebitAccount, CreditAccount, DebitAccountRef, CreditAccountRef,
    EntryDate, ReferenceType, ReferenceId, PayrollRunId
) VALUES (
    @EntryId, N'AS-NOM-2026-10-01',
    N'Causación y registro de nómina de salarios, horas extras, cargas patronales y provisiones. 1ra Quincena Octubre 2026.',
    139137.50, 139137.50,
    N'Gastos operativos', N'Banco', N'Gastos operativos', N'Banco',
    TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
    N'payroll', @RunId, @RunId
);

COMMIT TRANSACTION;

PRINT N'';
PRINT N'======================================================================================';
PRINT N'   CARGA INTEGRAL FINALIZADA CON ÉXITO TOTAL';
PRINT N'   Se registraron: 14 Colaboradores, 14 Contratos, Marcaciones de Asistencia,';
PRINT N'   Solicitudes, Entregas de EPP, Planilla Quincenal con Deducciones DGI/INSS y Asiento.';
PRINT N'======================================================================================';
GO
