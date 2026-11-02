/* 16 - Módulo integral de Talento Humano y Bienestar Laboral para Instalaciones Raquel */
USE [Instalaciones Raquel];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Employees', N'U') IS NULL
    THROW 50430, 'Falta dbo.Employees; ejecuta primero 02_gobierno_y_maestros.sql.', 1;
IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
    THROW 50431, 'Falta dbo.AppUsers; ejecuta primero los scripts de gobierno.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50432, 'Falta dbo.AuditEvents; ejecuta primero los scripts de gobierno.', 1;
IF OBJECT_ID(N'dbo.AppUserAreas', N'U') IS NULL
    THROW 50431, 'Falta dbo.AppUserAreas; ejecuta primero los scripts de gobierno.', 1;
GO

/* =========================================================
   1. AMPLIACIÓN DE EMPLEADOS Y CONTROL DE BAJAS LABORALES
   ========================================================= */
IF COL_LENGTH(N'dbo.Employees', N'EmploymentStatus') IS NULL
BEGIN
    ALTER TABLE dbo.Employees
        ADD EmploymentStatus NVARCHAR(20) NOT NULL CONSTRAINT DF_Employees_EmploymentStatus DEFAULT (N'activo');
END;
GO

IF COL_LENGTH(N'dbo.Employees', N'DismissalDate') IS NULL
    ALTER TABLE dbo.Employees ADD DismissalDate DATE NULL;
IF COL_LENGTH(N'dbo.Employees', N'DismissalReason') IS NULL
    ALTER TABLE dbo.Employees ADD DismissalReason NVARCHAR(500) NULL;
IF COL_LENGTH(N'dbo.Employees', N'DismissalDocRef') IS NULL
    ALTER TABLE dbo.Employees ADD DismissalDocRef NVARCHAR(300) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Employees') AND name = N'CK_Employees_EmploymentStatus')
    ALTER TABLE dbo.Employees ADD CONSTRAINT CK_Employees_EmploymentStatus
        CHECK (EmploymentStatus IN (N'activo', N'licencia', N'baja'));
GO

/* =========================================================
   2. HISTORIAL LABORAL Y SALARIAL
   ========================================================= */
IF OBJECT_ID(N'dbo.EmployeeJobHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EmployeeJobHistory
    (
        EmployeeJobHistoryId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_EmployeeJobHistory PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        Position NVARCHAR(200) NOT NULL,
        Area NVARCHAR(120) NOT NULL,
        Salary DECIMAL(19,4) NOT NULL,
        ValidFrom DATE NULL,
        ValidTo DATE NULL,
        ChangedByAppUserId NVARCHAR(100) NULL,
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_EmployeeJobHistory_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_EmployeeJobHistory_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_EmployeeJobHistory_AppUsers FOREIGN KEY (ChangedByAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT CK_EmployeeJobHistory_Dates CHECK (ValidFrom IS NULL OR ValidTo IS NULL OR ValidTo >= ValidFrom)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.EmployeeJobHistory') AND name = N'IX_EmployeeJobHistory_Employee_ValidFrom')
    CREATE INDEX IX_EmployeeJobHistory_Employee_ValidFrom
        ON dbo.EmployeeJobHistory(EmployeeId, ValidFrom DESC);
GO

INSERT INTO dbo.EmployeeJobHistory (
    EmployeeJobHistoryId, EmployeeId, Position, Area, Salary, ValidFrom, ChangedByAppUserId
)
SELECT NEWID(), employee.EmployeeId, employee.Position, employee.Area, employee.Salary,
       ISNULL(employee.HireDate, '2025-01-01'), NULL
FROM dbo.Employees AS employee
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.EmployeeJobHistory AS history
    WHERE history.EmployeeId = employee.EmployeeId
);
GO

/* =========================================================
   3. DIRECTORIO SEGURO Y MUTACIONES IDEMPOTENTES
   ========================================================= */
CREATE OR ALTER VIEW dbo.vw_HrEmployeeDirectory
AS
    SELECT employee.EmployeeId, employee.Name, employee.Position, employee.Area,
           employee.HireDate, employee.EmploymentStatus, employee.AppUserId,
           employee.DismissalDate, employee.DismissalReason,
           CASE WHEN employee.AppUserId IS NULL THEN NULL ELSE appUser.IsActive END AS AccountActive
    FROM dbo.Employees AS employee
    LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = employee.AppUserId;
GO

IF OBJECT_ID(N'dbo.HrEmployeeCreations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrEmployeeCreations
    (
        MutationId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrEmployeeCreations PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        CreatedByAppUserId NVARCHAR(100) NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrEmployeeCreations_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrEmployeeCreations_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrEmployeeCreations_Users FOREIGN KEY (CreatedByAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL
    );
END;
GO

/* =========================================================
   4. CONTRATOS Y CONDICIONES PACTADAS
   ========================================================= */
IF OBJECT_ID(N'dbo.HrContracts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrContracts
    (
        ContractId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrContracts PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        ContractNumber NVARCHAR(60) NOT NULL,
        ContractType NVARCHAR(40) NOT NULL CONSTRAINT DF_HrContracts_Type DEFAULT (N'indefinido'),
        Position NVARCHAR(200) NOT NULL,
        WorkSchedule NVARCHAR(100) NOT NULL CONSTRAINT DF_HrContracts_Schedule DEFAULT (N'Diurna 48h (Lun-Sáb)'),
        StartDate DATE NOT NULL,
        EndDate DATE NULL,
        AgreedTerms NVARCHAR(2000) NOT NULL,
        DocumentName NVARCHAR(200) NULL,
        DocumentRef NVARCHAR(500) NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrContracts_Status DEFAULT (N'registrado'),
        ReviewedByAppUserId NVARCHAR(100) NULL,
        ReviewedAt DATETIMEOFFSET(3) NULL,
        Revision ROWVERSION NOT NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrContracts_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        UpdatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrContracts_UpdatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrContracts_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrContracts_ReviewedBy FOREIGN KEY (ReviewedByAppUserId) REFERENCES dbo.AppUsers(AppUserId),
        CONSTRAINT CK_HrContracts_Status CHECK (Status IN (N'borrador', N'en_revision', N'registrado', N'finalizado')),
        CONSTRAINT CK_HrContracts_Type CHECK (ContractType IN (N'indefinido', N'determinado', N'obra_servicio', N'periodo_prueba')),
        CONSTRAINT CK_HrContracts_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.HrContracts') AND name = N'IX_HrContracts_Employee_StartDate')
    CREATE INDEX IX_HrContracts_Employee_StartDate ON dbo.HrContracts(EmployeeId, StartDate DESC);
GO

/* Semilla de contratos iniciales para el personal existente si no los tienen */
INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, EndDate, AgreedTerms, Status)
SELECT 
    NEWID(), e.EmployeeId, 
    CONCAT(N'CT-RAQ-', YEAR(ISNULL(e.HireDate, '2025-01-01')), N'-', RIGHT(CONCAT('00', ROW_NUMBER() OVER (ORDER BY e.EmployeeId)), 3)),
    N'indefinido', e.Position, N'Diurna 48h (Lun-Sáb: 8am-5pm)', ISNULL(e.HireDate, '2025-01-01'), NULL,
    CONCAT(N'Contrato laboral por tiempo indeterminado según Código del Trabajo (Ley 185). Jornada diurna de 48 horas semanales. Área: ', e.Area, N'. Con derecho a descanso semanal remunerado y EPP especializado.'),
    N'registrado'
FROM dbo.Employees AS e
WHERE NOT EXISTS (SELECT 1 FROM dbo.HrContracts c WHERE c.EmployeeId = e.EmployeeId);
GO

/* =========================================================
   5. SOLICITUDES PRIVADAS E INCIDENCIAS DE PERSONAL
   ========================================================= */
IF OBJECT_ID(N'dbo.HrRequests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrRequests
    (
        HrRequestId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrRequests PRIMARY KEY,
        MutationId UNIQUEIDENTIFIER NOT NULL,
        EmployeeId NVARCHAR(100) NOT NULL,
        Category NVARCHAR(30) NOT NULL,
        StartDate DATE NULL,
        EndDate DATE NULL,
        Details NVARCHAR(1000) NOT NULL,
        Status NVARCHAR(20) NOT NULL CONSTRAINT DF_HrRequests_Status DEFAULT (N'enviada'),
        Resolution NVARCHAR(1000) NULL,
        AssignedToAppUserId NVARCHAR(100) NULL,
        DecidedByAppUserId NVARCHAR(100) NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrRequests_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        UpdatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrRequests_UpdatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        DecidedAt DATETIMEOFFSET(3) NULL,
        Revision ROWVERSION NOT NULL,
        CONSTRAINT FK_HrRequests_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrRequests_AssignedUser FOREIGN KEY (AssignedToAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT FK_HrRequests_DecidedUser FOREIGN KEY (DecidedByAppUserId) REFERENCES dbo.AppUsers(AppUserId),
        CONSTRAINT UQ_HrRequests_MutationId UNIQUE (MutationId),
        CONSTRAINT CK_HrRequests_Category CHECK (Category IN (
            N'vacaciones', N'permiso', N'correccion_datos', N'consulta_laboral', N'seguridad', N'trato_recibido'
        )),
        CONSTRAINT CK_HrRequests_Status CHECK (Status IN (
            N'enviada', N'en_revision', N'aprobada', N'rechazada', N'cancelada'
        )),
        CONSTRAINT CK_HrRequests_Dates CHECK (StartDate IS NULL OR EndDate IS NULL OR EndDate >= StartDate),
        CONSTRAINT CK_HrRequests_Decision CHECK (
            (Status IN (N'aprobada', N'rechazada') AND DecidedByAppUserId IS NOT NULL AND DecidedAt IS NOT NULL)
            OR Status NOT IN (N'aprobada', N'rechazada')
        )
    );
END;
GO

IF OBJECT_ID(N'dbo.HrRequestEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrRequestEvents
    (
        HrRequestEventId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrRequestEvents PRIMARY KEY,
        HrRequestId UNIQUEIDENTIFIER NOT NULL,
        AppUserId NVARCHAR(100) NULL,
        ActorName NVARCHAR(240) NOT NULL,
        EventType NVARCHAR(30) NOT NULL,
        Detail NVARCHAR(1000) NULL,
        OccurredAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrRequestEvents_OccurredAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrRequestEvents_Requests FOREIGN KEY (HrRequestId) REFERENCES dbo.HrRequests(HrRequestId),
        CONSTRAINT FK_HrRequestEvents_Users FOREIGN KEY (AppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.HrRequests') AND name = N'IX_HrRequests_Employee_CreatedAt')
    CREATE INDEX IX_HrRequests_Employee_CreatedAt ON dbo.HrRequests(EmployeeId, CreatedAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.HrRequests') AND name = N'IX_HrRequests_Status_CreatedAt')
    CREATE INDEX IX_HrRequests_Status_CreatedAt ON dbo.HrRequests(Status, CreatedAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.HrRequestEvents') AND name = N'IX_HrRequestEvents_Request_OccurredAt')
    CREATE INDEX IX_HrRequestEvents_Request_OccurredAt ON dbo.HrRequestEvents(HrRequestId, OccurredAt DESC);
GO

/* =========================================================
   6. ASISTENCIA Y JORNADA LABORAL
   ========================================================= */
IF OBJECT_ID(N'dbo.HrAttendanceRecords', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrAttendanceRecords
    (
        AttendanceId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrAttendanceRecords PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        RecordDate DATE NOT NULL,
        ShiftName NVARCHAR(60) NOT NULL CONSTRAINT DF_HrAttendance_Shift DEFAULT (N'Taller Diurno (8h)'),
        ScheduledIn TIME(0) NOT NULL CONSTRAINT DF_HrAttendance_SchedIn DEFAULT ('08:00:00'),
        ScheduledOut TIME(0) NOT NULL CONSTRAINT DF_HrAttendance_SchedOut DEFAULT ('17:00:00'),
        ActualIn TIME(0) NULL,
        ActualOut TIME(0) NULL,
        OriginalIn TIME(0) NULL,
        OriginalOut TIME(0) NULL,
        HoursLogged DECIMAL(5,2) NOT NULL CONSTRAINT DF_HrAttendance_Logged DEFAULT (0),
        HoursReviewed DECIMAL(5,2) NOT NULL CONSTRAINT DF_HrAttendance_Reviewed DEFAULT (0),
        HoursAuthorized DECIMAL(5,2) NOT NULL CONSTRAINT DF_HrAttendance_Authorized DEFAULT (0),
        IncidentType NVARCHAR(40) NOT NULL CONSTRAINT DF_HrAttendance_Incident DEFAULT (N'ninguna'),
        IncidentNotes NVARCHAR(500) NULL,
        CorrectionReason NVARCHAR(500) NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrAttendance_Status DEFAULT (N'registrado'),
        AuthorizedByAppUserId NVARCHAR(100) NULL,
        Revision ROWVERSION NOT NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrAttendance_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrAttendance_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrAttendance_Authorizer FOREIGN KEY (AuthorizedByAppUserId) REFERENCES dbo.AppUsers(AppUserId),
        CONSTRAINT UQ_HrAttendance_Employee_Date UNIQUE (EmployeeId, RecordDate),
        CONSTRAINT CK_HrAttendance_Incident CHECK (IncidentType IN (
            N'ninguna', N'tardanza', N'falta_justificada', N'falta_injustificada', N'salida_anticipada', N'permiso_oficial'
        )),
        CONSTRAINT CK_HrAttendance_Status CHECK (Status IN (N'registrado', N'en_revision', N'autorizado_nomina'))
    );
END;
GO

/* Semilla de asistencia reciente para comprobación */
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE RecordDate = CONVERT(DATE, SYSUTCDATETIME()))
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, IncidentType, Status)
    SELECT 
        NEWID(), e.EmployeeId, CONVERT(DATE, SYSUTCDATETIME()), N'Taller Diurno (8h)',
        '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.0, 8.0, 8.0, N'ninguna', N'autorizado_nomina'
    FROM dbo.Employees e
    WHERE e.EmploymentStatus = N'activo';
END;
GO

/* =========================================================
   7. SEGURIDAD Y BIENESTAR: EQUIPOS DE PROTECCIÓN (EPP)
   ========================================================= */
IF OBJECT_ID(N'dbo.HrSafetyEquipment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrSafetyEquipment
    (
        EquipmentId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrSafetyEquipment PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        Category NVARCHAR(50) NOT NULL,
        StandardNorm NVARCHAR(120) NOT NULL,
        StockQty INT NOT NULL CONSTRAINT DF_HrEquipment_Stock DEFAULT (10),
        ReplacementPeriodDays INT NOT NULL CONSTRAINT DF_HrEquipment_Period DEFAULT (90),
        IsActive BIT NOT NULL CONSTRAINT DF_HrEquipment_Active DEFAULT (1),
        CONSTRAINT CK_HrSafetyEquipment_Category CHECK (Category IN (N'vidrio', N'aluminio', N'altura', N'electricidad', N'general'))
    );
END;
GO

/* Semilla de EPP especializado para corte de vidrio, aluminio e instalaciones */
IF NOT EXISTS (SELECT 1 FROM dbo.HrSafetyEquipment)
BEGIN
    INSERT INTO dbo.HrSafetyEquipment (EquipmentId, Name, Category, StandardNorm, StockQty, ReplacementPeriodDays)
    VALUES
        (NEWID(), N'Guantes anticorte nivel 5 con recubrimiento de nitrilo espumado (Manipulación de vidrio y perfiles)', N'vidrio', N'EN 388:2016 (4X43F) / Ley 618 Art. 110', 25, 60),
        (NEWID(), N'Mangas protectoras anticorte nivel 5 para antebrazos (Corte de cristales)', N'vidrio', N'EN 388 / Ley 618 Art. 110', 18, 90),
        (NEWID(), N'Gafas panorámicas de seguridad con ventilación indirecta anti-impacto', N'aluminio', N'ANSI Z87.1+ / Ley 618 Art. 108', 30, 120),
        (NEWID(), N'Calzado de seguridad con puntera dieléctrica y plantilla anti-perforación', N'general', N'ASTM F2413 / Ley 618 Art. 112', 15, 180),
        (NEWID(), N'Ventosas dobles de succión con indicador de vacío para cristal templado (100 kg)', N'vidrio', N'Certificación CE / Inspección mensual', 8, 365),
        (NEWID(), N'Arnés de cuerpo entero de 4 puntos con línea de vida y absorbedor de impacto', N'altura', N'ANSI Z359.11 / Ley 618 Art. 165', 10, 180),
        (NEWID(), N'Protector auditivo tipo copa de alta atenuación (Tronzadora de aluminio)', N'aluminio', N'ANSI S3.19 / Ley 618 Art. 109', 20, 180);
END;
GO

IF OBJECT_ID(N'dbo.HrEquipmentDeliveries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrEquipmentDeliveries
    (
        DeliveryId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrEquipmentDeliveries PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        EquipmentId UNIQUEIDENTIFIER NOT NULL,
        DeliveryDate DATE NOT NULL,
        DeliveryType NVARCHAR(40) NOT NULL CONSTRAINT DF_HrDeliveries_Type DEFAULT (N'dotacion_inicial'),
        NextReplacementDate DATE NULL,
        Notes NVARCHAR(500) NULL,
        DeliveredByAppUserId NVARCHAR(100) NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrDeliveries_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrDeliveries_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrDeliveries_Equipment FOREIGN KEY (EquipmentId) REFERENCES dbo.HrSafetyEquipment(EquipmentId),
        CONSTRAINT FK_HrDeliveries_DeliveredBy FOREIGN KEY (DeliveredByAppUserId) REFERENCES dbo.AppUsers(AppUserId),
        CONSTRAINT CK_HrDeliveries_Type CHECK (DeliveryType IN (N'dotacion_inicial', N'reposicion_desgaste', N'reposicion_dano'))
    );
END;
GO

/* Dotaciones iniciales para supervisores e instaladores */
IF NOT EXISTS (SELECT 1 FROM dbo.HrEquipmentDeliveries)
BEGIN
    INSERT INTO dbo.HrEquipmentDeliveries (DeliveryId, EmployeeId, EquipmentId, DeliveryDate, DeliveryType, NextReplacementDate, Notes)
    SELECT NEWID(), e.EmployeeId, eq.EquipmentId, '2026-09-01', N'dotacion_inicial', DATEADD(DAY, eq.ReplacementPeriodDays, '2026-09-01'), N'Dotación reglamentaria de seguridad para operaciones en taller y obra.'
    FROM dbo.Employees e
    CROSS JOIN (SELECT TOP 2 EquipmentId, ReplacementPeriodDays FROM dbo.HrSafetyEquipment ORDER BY Category) eq
    WHERE e.Area IN (N'Producción', N'Ventas');
END;
GO

/* =========================================================
   8. SEGURIDAD Y BIENESTAR: CAPACITACIONES
   ========================================================= */
IF OBJECT_ID(N'dbo.HrSafetyTrainings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrSafetyTrainings
    (
        TrainingId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrSafetyTrainings PRIMARY KEY,
        Topic NVARCHAR(250) NOT NULL,
        Instructor NVARCHAR(200) NOT NULL,
        TrainingDate DATE NOT NULL,
        Hours INT NOT NULL,
        LegalRef NVARCHAR(120) NOT NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrTrainings_Status DEFAULT (N'completada'),
        TargetArea NVARCHAR(60) NOT NULL CONSTRAINT DF_HrTrainings_Area DEFAULT (N'Taller y Obras'),
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrTrainings_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT CK_HrSafetyTrainings_Status CHECK (Status IN (N'programada', N'completada', N'cancelada'))
    );
END;
GO

IF OBJECT_ID(N'dbo.HrTrainingAttendees', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrTrainingAttendees
    (
        TrainingId UNIQUEIDENTIFIER NOT NULL,
        EmployeeId NVARCHAR(100) NOT NULL,
        Attended BIT NOT NULL CONSTRAINT DF_HrAttendees_Attended DEFAULT (1),
        CertificateIssued BIT NOT NULL CONSTRAINT DF_HrAttendees_Cert DEFAULT (1),
        CONSTRAINT PK_HrTrainingAttendees PRIMARY KEY (TrainingId, EmployeeId),
        CONSTRAINT FK_HrAttendees_Training FOREIGN KEY (TrainingId) REFERENCES dbo.HrSafetyTrainings(TrainingId) ON DELETE CASCADE,
        CONSTRAINT FK_HrAttendees_Employee FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.HrSafetyTrainings)
BEGIN
    DECLARE @T1 UNIQUEIDENTIFIER = NEWID();
    DECLARE @T2 UNIQUEIDENTIFIER = NEWID();
    DECLARE @T3 UNIQUEIDENTIFIER = NEWID();

    INSERT INTO dbo.HrSafetyTrainings (TrainingId, Topic, Instructor, TrainingDate, Hours, LegalRef, Status, TargetArea)
    VALUES
        (@T1, N'Técnicas seguras en manipulación, trasiego y corte de vidrio crudo y templado', N'Ing. Manuel Espinoza (Especialista en Seguridad Industrial)', '2026-08-15', 6, N'Ley 618 Art. 18 / NTON', N'completada', N'Taller de Vidrio'),
        (@T2, N'Seguridad en trabajos en alturas y anclajes en instalación de ventanería y fachadas', N'Téc. Roberto Calero (Certificado OSHA / MITRAB)', '2026-09-20', 8, N'Ley 618 Art. 165', N'completada', N'Instalaciones en Obra'),
        (@T3, N'Operación segura de tronzadoras, ingletadoras y taladros para perfiles de aluminio', N'Ing. Carlos Producción', '2026-10-10', 4, N'Ley 618 Art. 78', N'completada', N'Taller de Aluminio');

    INSERT INTO dbo.HrTrainingAttendees (TrainingId, EmployeeId, Attended, CertificateIssued)
    SELECT @T1, EmployeeId, 1, 1 FROM dbo.Employees WHERE Area IN (N'Producción', N'Ventas');
    INSERT INTO dbo.HrTrainingAttendees (TrainingId, EmployeeId, Attended, CertificateIssued)
    SELECT @T2, EmployeeId, 1, 1 FROM dbo.Employees WHERE Area = N'Producción';
    INSERT INTO dbo.HrTrainingAttendees (TrainingId, EmployeeId, Attended, CertificateIssued)
    SELECT @T3, EmployeeId, 1, 1 FROM dbo.Employees WHERE Area = N'Producción';
END;
GO

/* =========================================================
   9. SEGURIDAD Y BIENESTAR: INCIDENTES Y ACCIONES CORRECTIVAS
   ========================================================= */
IF OBJECT_ID(N'dbo.HrSafetyIncidents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrSafetyIncidents
    (
        IncidentId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrSafetyIncidents PRIMARY KEY,
        IncidentDate DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrIncidents_Date DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        ReportedByAppUserId NVARCHAR(100) NULL,
        Area NVARCHAR(100) NOT NULL,
        IncidentType NVARCHAR(40) NOT NULL,
        Severity NVARCHAR(20) NOT NULL CONSTRAINT DF_HrIncidents_Sev DEFAULT (N'baja'),
        Description NVARCHAR(1000) NOT NULL,
        ImmediateAction NVARCHAR(1000) NULL,
        PhotoUrl NVARCHAR(500) NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrIncidents_Status DEFAULT (N'reportado'),
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrIncidents_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrIncidents_Reporter FOREIGN KEY (ReportedByAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT CK_HrIncidents_Type CHECK (IncidentType IN (N'condicion_insegura', N'acto_inseguro', N'casi_accidente', N'incidente_menor')),
        CONSTRAINT CK_HrIncidents_Severity CHECK (Severity IN (N'baja', N'media', N'alta', N'critica')),
        CONSTRAINT CK_HrIncidents_Status CHECK (Status IN (N'reportado', N'en_investigacion', N'con_accion_correctiva', N'cerrado'))
    );
END;
GO

IF OBJECT_ID(N'dbo.HrCorrectiveActions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrCorrectiveActions
    (
        ActionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrCorrectiveActions PRIMARY KEY,
        IncidentId UNIQUEIDENTIFIER NULL,
        Description NVARCHAR(1000) NOT NULL,
        ResponsibleAppUserId NVARCHAR(100) NULL,
        ResponsibleName NVARCHAR(200) NOT NULL,
        DueDate DATE NOT NULL,
        Evidence NVARCHAR(1000) NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrActions_Status DEFAULT (N'abierta'),
        ClosedAt DATETIMEOFFSET(3) NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrActions_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrActions_Incidents FOREIGN KEY (IncidentId) REFERENCES dbo.HrSafetyIncidents(IncidentId) ON DELETE SET NULL,
        CONSTRAINT FK_HrActions_Responsible FOREIGN KEY (ResponsibleAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT CK_HrActions_Status CHECK (Status IN (N'abierta', N'en_proceso', N'implementada', N'verificada_cerrada'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.HrSafetyIncidents)
BEGIN
    DECLARE @Inc1 UNIQUEIDENTIFIER = NEWID();
    INSERT INTO dbo.HrSafetyIncidents (IncidentId, Area, IncidentType, Severity, Description, ImmediateAction, Status)
    VALUES (
        @Inc1, N'Taller de Vidrio - Mesa de corte #2', N'condicion_insegura', N'media',
        N'Fieltro protector de mesa de corte desgastado con residuos de esquirlas adheridas que pueden rayar o astillar el cristal durante el desprendimiento.',
        N'Se delimitó la mesa y se programó cambio de cubierta acolchada.',
        N'con_accion_correctiva'
    );

    INSERT INTO dbo.HrCorrectiveActions (ActionId, IncidentId, Description, ResponsibleName, DueDate, Status)
    VALUES (
        NEWID(), @Inc1,
        N'Instalar fieltro sintético nuevo de 5mm en mesa de corte y aspirado de viruta de vidrio al final de cada jornada.',
        N'Carlos Producción', DATEADD(DAY, 7, CONVERT(DATE, SYSUTCDATETIME())), N'en_proceso'
    );
END;
GO

/* =========================================================
   10. MARCO LEGAL Y OBLIGACIONES DE CUMPLIMIENTO (NICARAGUA)
   ========================================================= */
IF OBJECT_ID(N'dbo.HrComplianceObligations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrComplianceObligations
    (
        ObligationId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrCompliance PRIMARY KEY,
        Topic NVARCHAR(120) NOT NULL,
        LawName NVARCHAR(200) NOT NULL,
        ArticleRef NVARCHAR(100) NOT NULL,
        Summary NVARCHAR(1000) NOT NULL,
        ResponsibilityArea NVARCHAR(80) NOT NULL,
        ComplianceStatus NVARCHAR(40) NOT NULL CONSTRAINT DF_HrCompliance_Status DEFAULT (N'revisado_internamente'),
        LastReviewDate DATE NOT NULL,
        ResponsibleName NVARCHAR(150) NOT NULL,
        Notes NVARCHAR(1000) NULL,
        CONSTRAINT CK_HrCompliance_Status CHECK (ComplianceStatus IN (
            N'pendiente_revision', N'documentacion_incompleta', N'revisado_internamente', N'constancia_registrada'
        ))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.HrComplianceObligations)
BEGIN
    INSERT INTO dbo.HrComplianceObligations (ObligationId, Topic, LawName, ArticleRef, Summary, ResponsibilityArea, ComplianceStatus, LastReviewDate, ResponsibleName, Notes)
    VALUES
        (NEWID(), N'Jornada Ordinaria y Descanso Semanal', N'Código del Trabajo (Ley 185)', N'Artículos 51, 52, 64',
         N'La jornada ordinaria diurna no excederá de 8 horas diarias ni de 48 semanales. Derecho a un día de descanso continuo remunerado por cada 6 días trabajados.',
         N'Talento humano', N'revisado_internamente', '2026-10-01', N'Raquel López', N'Turnos de taller organizados de 8:00 AM a 5:00 PM con una hora de almuerzo.'),

        (NEWID(), N'Derecho y Cálculo de Vacaciones', N'Código del Trabajo (Ley 185)', N'Artículo 76',
         N'Todo trabajador tiene derecho a 15 días continuos de descanso remunerado por cada 6 meses ininterrumpidos de trabajo (equivalente a 2.5 días acumulados por mes). Las vacaciones se disfrutan, no se compensan en dinero salvo rescisión.',
         N'Talento humano', N'constancia_registrada', '2026-10-01', N'Raquel López', N'Módulo de vacaciones con liquidación y registro de descansos efectivos.'),

        (NEWID(), N'Décimo Tercer Mes (Aguinaldo)', N'Código del Trabajo (Ley 185)', N'Artículos 93 - 99',
         N'Un mes de salario ordinario después de un año de trabajo continuo o la parte proporcional. Se paga en los primeros 10 días de diciembre. Es inembargable y exento de tributos y cargas sociales.',
         N'Contabilidad y nómina', N'revisado_internamente', '2026-10-01', N'María Contadora', N'Provisiones mensuales del 8.33% registradas en la contabilidad.'),

        (NEWID(), N'Comisión Mixta y EPP para Vidrio y Metal', N'Ley General de Higiene y Seguridad del Trabajo (Ley 618)', N'Artículos 32, 108 - 114',
         N'Obligación de constituir Comisión Mixta de Higiene y Seguridad y suministrar EPP certificado gratuito a todo trabajador expuesto a cortes, esquirlas, polvo y alturas.',
         N'Seguridad industrial', N'constancia_registrada', '2026-09-15', N'Carlos Producción', N'EPP entregado con actas firmadas y reposición periódica.'),

        (NEWID(), N'Retención Salarial del IR de Empleados', N'Ley de Concertación Tributaria (Ley 822)', N'Artículo 23',
         N'Retención en la fuente sobre rentas del trabajo conforme a la tarifa progresiva sobre el ingreso neto gravable una vez deducido el aporte laboral del INSS.',
         N'Contabilidad y nómina', N'revisado_internamente', '2026-10-01', N'María Contadora', N'Tablas de retención salarial aplicadas en la nómina.'),

        (NEWID(), N'Aportes a la Seguridad Social (INSS e INATEC)', N'Ley de Seguridad Social y Normativa INATEC', N'Reglamento INSS / Ley INATEC',
         N'Deducción laboral INSS 7.0%, aporte patronal INSS 21.5% o 22.5% según número de colaboradores, y aporte patronal INATEC 2.0% para capacitación.',
         N'Contabilidad y nómina', N'constancia_registrada', '2026-10-01', N'María Contadora', N'Pagos y declaraciones mensuales con comprobante oficial.'),

        (NEWID(), N'Protección y Confidencialidad de Datos', N'Ley de Protección de Datos Personales (Ley 787)', N'Artículos 4, 9, 13',
         N'Los datos laborales y salariales deben tratarse con principio de finalidad, seguridad técnica y reserva estricta. Queda prohibida la divulgación de diagnósticos médicos en tableros comunes.',
         N'Talento humano', N'constancia_registrada', '2026-10-01', N'Raquel López', N'Separación física y digital en base de datos con roles restringidos.');
END;
GO

/* =========================================================
   11. BIBLIOTECA DE DERECHOS Y ORIENTACIÓN ("CONOCE TUS DERECHOS")
   ========================================================= */
IF OBJECT_ID(N'dbo.HrRightsArticles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrRightsArticles
    (
        ArticleId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrRightsArticles PRIMARY KEY,
        Slug NVARCHAR(100) NOT NULL CONSTRAINT UQ_HrRights_Slug UNIQUE,
        Category NVARCHAR(50) NOT NULL,
        Question NVARCHAR(300) NOT NULL,
        ShortAnswer NVARCHAR(1000) NOT NULL,
        PracticalExample NVARCHAR(1500) NOT NULL,
        LegalSource NVARCHAR(300) NOT NULL,
        ReviewedAt DATE NOT NULL,
        EditorialOwner NVARCHAR(150) NOT NULL,
        OrderIndex INT NOT NULL CONSTRAINT DF_HrRights_Order DEFAULT (0),
        IsPublic BIT NOT NULL CONSTRAINT DF_HrRights_Public DEFAULT (1)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.HrRightsArticles)
BEGIN
    INSERT INTO dbo.HrRightsArticles (ArticleId, Slug, Category, Question, ShortAnswer, PracticalExample, LegalSource, ReviewedAt, EditorialOwner, OrderIndex)
    VALUES
        (NEWID(), N'que-debo-revisar-en-un-contrato', N'contratos',
         N'¿Qué debo revisar en mi contrato de trabajo?',
         N'Tu contrato formaliza la relación laboral y debe detallar con precisión tu puesto específico, horario pactado, lugar donde desempeñarás tus labores, fecha de inicio y salario acordado.',
         N'En Instalaciones Raquel, si fuiste contratado como armador de perfiles de aluminio o instalador en obra, tu contrato debe estipular la jornada diurna máxima de 48 horas semanales y las condiciones de seguridad en taller.',
         N'Código del Trabajo de Nicaragua (Ley 185), Artículos 19 al 24.', '2026-10-01', N'Talento Humano Raquel', 1),

        (NEWID(), N'como-entiendo-mi-comprobante-de-pago', N'pagos',
         N'¿Cómo entiendo mi comprobante de nómina?',
         N'Tu colilla desglosa tus ingresos devengados (salario base, horas extras autorizadas, comisiones) y tus deducciones legales obligatorias (7% de INSS laboral y retención del IR si aplica según escala tributaria).',
         N'Por ejemplo, con un devengado de C$ 12,000, el 7% de INSS laboral equivale a C$ 840 deducidos para tu cobertura de salud y pensión. El salario neto a cobrar se calcula restando estas deducciones legales al devengado total.',
         N'Código del Trabajo (Ley 185) Art. 84; Ley de Concertación Tributaria (Ley 822) Art. 23.', '2026-10-01', N'Contabilidad y Nómina', 2),

        (NEWID(), N'como-solicito-vacaciones', N'vacaciones',
         N'¿Cómo solicito y disfruto mis vacaciones?',
         N'Acumulas 2.5 días hábiles de descanso por cada mes continuo de trabajo (15 días por semestre). Puedes solicitar tu período desde "Mi espacio" con un mínimo de 15 días de anticipación para planificar la cobertura en taller.',
         N'Si cumples un año continuo, habrás acumulado 30 días de vacaciones. Al solicitar 15 días, conservas 15 días disponibles. Las vacaciones deben gozarse efectivamente; la ley prohíbe compensarlas con dinero salvo al finalizar la relación laboral.',
         N'Código del Trabajo de Nicaragua (Ley 185), Artículos 76 al 81.', '2026-10-01', N'Talento Humano Raquel', 3),

        (NEWID(), N'que-hago-si-mis-datos-estan-incorrectos', N'datos',
         N'¿Qué hago si mis datos personales están incorrectos en el expediente?',
         N'Tienes derecho a la rectificación inmediata de tu número de cédula, afiliación INSS, número de cuenta bancaria o dirección domiciliaria mediante una solicitud de corrección en "Mi espacio".',
         N'Si te mudaste de domicilio o renovaste tu cédula, envía la solicitud adjuntando el nuevo número. Talento humano valida la información oficial y actualiza el expediente sin sobrescribir el historial previo.',
         N'Ley de Protección de Datos Personales (Ley 787), Artículo 13.', '2026-10-01', N'Seguridad y Cumplimiento', 4),

        (NEWID(), N'que-proteccion-necesito-para-trabajar-con-vidrio', N'seguridad_vidrio',
         N'¿Qué protección obligatoria necesito para trabajar con vidrio y perfiles?',
         N'Para corte y trasiego de vidrio requieres guantes anticorte nivel 5 certificados, mangas protectoras para antebrazos, gafas de seguridad de impacto y calzado con puntera. Para trabajo en altura es obligatorio arnés de cuerpo entero con línea de vida.',
         N'En Instalaciones Raquel todos los EPP son suministrados por la empresa sin costo alguno para el colaborador. Ante cualquier corte o rasgadura del guante, solicita reposición inmediata sin sanción.',
         N'Ley General de Higiene y Seguridad del Trabajo (Ley 618), Artículos 108 al 114 y 165.', '2026-10-01', N'Seguridad Industrial', 5),

        (NEWID(), N'como-comunico-una-condicion-insegura', N'reportes',
         N'¿Cómo comunico una condición o acto inseguro en el taller u obra?',
         N'Puedes registrar un reporte preventivo desde tu teléfono en "Seguridad y bienestar" o avisar directamente a tu supervisor. Si detectas cables pelados, andamios inestables o ventosas defectuosas, repórtalo de inmediato.',
         N'Aviso Importante: Un reporte dentro del sistema tiene carácter de mejora preventiva y no sustituye la llamada de emergencia inmediata ante un accidente grave (Cruz Blanca 128 o Bomberos 115).',
         N'Ley General de Higiene y Seguridad del Trabajo (Ley 618), Artículos 18 y 22.', '2026-10-01', N'Seguridad Industrial', 6);
END;
GO

/* =========================================================
   12. PROCEDIMIENTOS ALMACENADOS DE TALENTO HUMANO
   ========================================================= */

/* --- Consultar Directorio General (con roles y permisos) --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrEmployeeDirectory
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        THROW 50447, 'Se requiere autorización de administración de Talento humano.', 1;

    SELECT employee.EmployeeId AS id, employee.Name AS name, employee.Position AS position,
           employee.Area AS area, employee.HireDate AS hireDate,
           employee.EmploymentStatus AS employmentStatus, employee.AccountActive AS accountActive,
           employee.DismissalDate AS dismissalDate, employee.DismissalReason AS dismissalReason
    FROM dbo.vw_HrEmployeeDirectory AS employee
    ORDER BY employee.Name;
END;
GO

/* --- Consultar Mi Expediente Autenticado --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrMyEmployee
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
    )
        THROW 50447, 'La sesión no está autorizada para consultar Talento humano.', 1;

    SELECT employee.EmployeeId AS id, employee.Name AS name, employee.Position AS position,
           employee.Area AS area, employee.HireDate AS hireDate,
           employee.EmploymentStatus AS employmentStatus, employee.AccountActive AS accountActive
    FROM dbo.vw_HrEmployeeDirectory AS employee
    WHERE employee.AppUserId = @ActorId;
END;
GO

/* --- Resolver EmployeeId a partir de AppUserId --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrEmployeeIdForUser
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
    )
        THROW 50447, 'La sesión no está autorizada para consultar Talento humano.', 1;

    SELECT EmployeeId AS employeeId
    FROM dbo.vw_HrEmployeeDirectory
    WHERE AppUserId = @ActorId AND EmploymentStatus <> N'baja';
END;
GO

/* --- Detalle Completo de Expediente (7 pestañas) --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrEmployeeDetail
    @EmployeeId NVARCHAR(100),
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsManagement BIT = 0;
    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @IsManagement = 1;

    -- Verificar que sea administración o el propio empleado
    IF @IsManagement = 0 AND NOT EXISTS (
        SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId AND AppUserId = @ActorId
    )
        THROW 50434, 'No tienes permiso para consultar el expediente solicitado.', 1;

    -- Resumen y Relación laboral
    SELECT employee.EmployeeId AS id, employee.Name AS name, employee.Position AS position,
           employee.Area AS area, employee.HireDate AS hireDate,
           employee.EmploymentStatus AS employmentStatus,
           employee.DismissalDate AS dismissalDate, employee.DismissalReason AS dismissalReason,
           employee.AppUserId AS appUserId,
           CASE WHEN @IsManagement = 1 THEN employee.Salary ELSE NULL END AS salary
    FROM dbo.Employees AS employee
    WHERE employee.EmployeeId = @EmployeeId;

    -- Contratos
    SELECT c.ContractId AS id, c.ContractNumber AS contractNumber, c.ContractType AS contractType,
           c.Position AS position, c.WorkSchedule AS workSchedule, c.StartDate AS startDate,
           c.EndDate AS endDate, c.AgreedTerms AS agreedTerms, c.Status AS status,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), c.Revision), 1) AS revision
    FROM dbo.HrContracts AS c
    WHERE c.EmployeeId = @EmployeeId
    ORDER BY c.StartDate DESC;

    -- Solicitudes
    SELECT r.HrRequestId AS id, r.Category AS category, r.StartDate AS startDate,
           r.EndDate AS endDate, r.Details AS details, r.Status AS status,
           r.Resolution AS resolution, r.CreatedAt AS createdAt,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision
    FROM dbo.HrRequests AS r
    WHERE r.EmployeeId = @EmployeeId
    ORDER BY r.CreatedAt DESC;

    -- Seguridad (EPP asignado)
    SELECT d.DeliveryId AS id, eq.Name AS equipmentName, eq.Category AS category,
           d.DeliveryDate AS deliveryDate, d.DeliveryType AS deliveryType,
           d.NextReplacementDate AS nextReplacementDate, d.Notes AS notes
    FROM dbo.HrEquipmentDeliveries d
    JOIN dbo.HrSafetyEquipment eq ON eq.EquipmentId = d.EquipmentId
    WHERE d.EmployeeId = @EmployeeId
    ORDER BY d.DeliveryDate DESC;
END;
GO

/* --- Crear Expediente de Personal con Idempotencia --- */
CREATE OR ALTER PROCEDURE dbo.usp_CreateHrEmployee
    @MutationId UNIQUEIDENTIFIER,
    @EmployeeId NVARCHAR(100),
    @Name NVARCHAR(240),
    @Position NVARCHAR(200),
    @Salary DECIMAL(19,4),
    @Area NVARCHAR(120),
    @AppUserId NVARCHAR(100) = NULL,
    @HireDate DATE,
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50434, 'Se requiere autorización de administración de Talento humano.', 1;
    END;

    IF @MutationId IS NULL
       OR (@AppUserId IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM dbo.AppUsers WHERE AppUserId = @AppUserId AND IsActive = 1
       ))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50435, 'La cuenta vinculada no existe o está inactiva.', 1;
    END;

    IF NULLIF(LTRIM(RTRIM(@Name)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Position)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Area)), N'') IS NULL
       OR @Salary IS NULL OR @Salary <= 0
       OR @HireDate IS NULL OR @HireDate > CONVERT(DATE, SYSUTCDATETIME())
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50443, 'Los datos del expediente no son válidos.', 1;
    END;

    DECLARE @ExistingEmployeeId NVARCHAR(100);
    SELECT @ExistingEmployeeId = EmployeeId
    FROM dbo.HrEmployeeCreations WITH (UPDLOCK, HOLDLOCK)
    WHERE MutationId = @MutationId;

    IF @ExistingEmployeeId IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.HrEmployeeCreations
            WHERE MutationId = @MutationId AND CreatedByAppUserId = @ActorId
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50446, 'La clave de repetición ya está asociada a otra operación.', 1;
        END;
        COMMIT TRANSACTION;
        SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
               HireDate AS hireDate, EmploymentStatus AS employmentStatus,
               CAST(NULL AS BIT) AS accountActive, CAST(0 AS BIT) AS wasCreated
        FROM dbo.Employees
        WHERE EmployeeId = @ExistingEmployeeId;
        RETURN;
    END;

    INSERT INTO dbo.Employees (
        EmployeeId, Name, Position, Salary, Area, AppUserId, HireDate, IsActive, EmploymentStatus
    )
    VALUES (
        @EmployeeId, @Name, @Position, @Salary, @Area, @AppUserId, @HireDate, 1, N'activo'
    );

    INSERT INTO dbo.EmployeeJobHistory (
        EmployeeJobHistoryId, EmployeeId, Position, Area, Salary, ValidFrom, ChangedByAppUserId
    )
    VALUES (
        NEWID(), @EmployeeId, @Position, @Area, @Salary, @HireDate, @ActorId
    );

    INSERT INTO dbo.HrContracts (
        ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, EndDate, AgreedTerms, Status
    )
    VALUES (
        NEWID(), @EmployeeId,
        CONCAT(N'CT-RAQ-', YEAR(@HireDate), N'-', RIGHT(CONCAT('00', ABS(CHECKSUM(NEWID())) % 900 + 100), 3)),
        N'indefinido', @Position, N'Diurna 48h (Lun-Sáb)', @HireDate, NULL,
        CONCAT(N'Contrato laboral según Código del Trabajo de Nicaragua (Ley 185). Puesto: ', @Position, N'. Área: ', @Area, N'. Con derecho a descanso semanal y EPP reglamentario.'),
        N'registrado'
    );

    INSERT INTO dbo.HrEmployeeCreations (MutationId, EmployeeId, CreatedByAppUserId)
    VALUES (@MutationId, @EmployeeId, @ActorId);

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(actor.Name, 200), actor.AppUserId, N'crear expediente de personal', N'rrhh',
        CONCAT(N'Expediente ', @EmployeeId, N' creado; sin incluir información salarial en auditoría abierta.'), N'info', @EmployeeId
    FROM dbo.AppUsers AS actor
    WHERE actor.AppUserId = @ActorId;

    COMMIT TRANSACTION;
    SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
           HireDate AS hireDate, EmploymentStatus AS employmentStatus,
           CAST(NULL AS BIT) AS accountActive, CAST(1 AS BIT) AS wasCreated
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;
END;
GO

/* --- Actualizar Expediente y Registro Histórico --- */
CREATE OR ALTER PROCEDURE dbo.usp_UpdateHrEmployee
    @EmployeeId NVARCHAR(100),
    @Position NVARCHAR(200),
    @Area NVARCHAR(120),
    @Salary DECIMAL(19,4) = NULL,
    @EmploymentStatus NVARCHAR(20),
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50434, 'Se requiere autorización de administración de Talento humano.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.Employees WITH (UPDLOCK, HOLDLOCK) WHERE EmployeeId = @EmployeeId)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50448, 'No se encontró el expediente de personal.', 1;
    END;
    IF NULLIF(LTRIM(RTRIM(@Position)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Area)), N'') IS NULL
       OR (@Salary IS NOT NULL AND @Salary <= 0)
       OR @EmploymentStatus IS NULL OR @EmploymentStatus NOT IN (N'activo', N'licencia', N'baja')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50443, 'Los datos laborales no son válidos.', 1;
    END;

    DECLARE @OldPosition NVARCHAR(200), @OldArea NVARCHAR(120),
            @OldSalary DECIMAL(19,4), @EffectiveDate DATE = CONVERT(DATE, SYSUTCDATETIME());
    SELECT @OldPosition = Position, @OldArea = Area, @OldSalary = Salary
    FROM dbo.Employees WHERE EmployeeId = @EmployeeId;

    IF @OldPosition <> @Position OR @OldArea <> @Area OR (@Salary IS NOT NULL AND @OldSalary <> @Salary)
    BEGIN
        UPDATE dbo.EmployeeJobHistory
        SET ValidTo = DATEADD(DAY, -1, @EffectiveDate)
        WHERE EmployeeId = @EmployeeId AND ValidTo IS NULL;

        INSERT INTO dbo.EmployeeJobHistory (
            EmployeeJobHistoryId, EmployeeId, Position, Area, Salary, ValidFrom, ChangedByAppUserId
        )
        VALUES (
            NEWID(), @EmployeeId, @Position, @Area, COALESCE(@Salary, @OldSalary), @EffectiveDate, @ActorId
        );
    END;

    UPDATE dbo.Employees
    SET Position = @Position,
        Area = @Area,
        Salary = COALESCE(@Salary, Salary),
        EmploymentStatus = @EmploymentStatus,
        IsActive = CASE WHEN @EmploymentStatus = N'baja' THEN 0 ELSE 1 END
    WHERE EmployeeId = @EmployeeId;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(actor.Name, 200), actor.AppUserId, N'actualizar expediente de personal', N'rrhh',
        CONCAT(N'Expediente ', @EmployeeId, N' actualizado con nuevo cargo/área/estado.'), N'info', @EmployeeId
    FROM dbo.AppUsers AS actor
    WHERE actor.AppUserId = @ActorId;

    COMMIT TRANSACTION;
    SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
           HireDate AS hireDate, EmploymentStatus AS employmentStatus,
           CAST(NULL AS BIT) AS accountActive
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;
END;
GO

/* --- Registro de Baja Laboral (sin borrar el expediente) --- */
CREATE OR ALTER PROCEDURE dbo.usp_TerminateHrEmployee
    @EmployeeId NVARCHAR(100),
    @DismissalDate DATE,
    @DismissalReason NVARCHAR(500),
    @DismissalDocRef NVARCHAR(300) = NULL,
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50434, 'Se requiere autorización de administración de Talento humano.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50448, 'No se encontró el expediente de personal.', 1;
    END;

    IF @DismissalDate IS NULL OR NULLIF(LTRIM(RTRIM(@DismissalReason)), N'') IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50443, 'Indica la fecha y el motivo formal de la baja laboral.', 1;
    END;

    UPDATE dbo.Employees
    SET EmploymentStatus = N'baja',
        IsActive = 0,
        DismissalDate = @DismissalDate,
        DismissalReason = @DismissalReason,
        DismissalDocRef = @DismissalDocRef
    WHERE EmployeeId = @EmployeeId;

    -- Finalizar contratos vigentes
    UPDATE dbo.HrContracts
    SET Status = N'finalizado', EndDate = @DismissalDate, UpdatedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
    WHERE EmployeeId = @EmployeeId AND Status IN (N'registrado', N'en_revision');

    -- Deshabilitar cuenta si existía vinculada
    UPDATE u
    SET u.IsActive = 0
    FROM dbo.AppUsers u
    JOIN dbo.Employees e ON e.AppUserId = u.AppUserId
    WHERE e.EmployeeId = @EmployeeId;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(actor.Name, 200), actor.AppUserId, N'baja laboral de personal', N'rrhh',
        CONCAT(N'Baja formal registrada para expediente ', @EmployeeId, N' con motivo autorizado; expediente preservado en archivo histórico.'), N'warn', @EmployeeId
    FROM dbo.AppUsers AS actor
    WHERE actor.AppUserId = @ActorId;

    COMMIT TRANSACTION;
    SELECT EmployeeId AS id, Name AS name, EmploymentStatus AS employmentStatus,
           DismissalDate AS dismissalDate, DismissalReason AS dismissalReason
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;
END;
GO

/* --- Consultar Historial Laboral --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrEmployeeJobHistory
    @EmployeeId NVARCHAR(100),
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsManagement BIT = 0;
    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @IsManagement = 1;

    IF @IsManagement = 0 AND NOT EXISTS (
        SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId AND AppUserId = @ActorId
    )
        THROW 50434, 'No tienes permiso para consultar este historial.', 1;

    SELECT history.EmployeeJobHistoryId AS id, history.Position AS position,
           history.Area AS area, history.ValidFrom AS validFrom,
           history.ValidTo AS validTo, history.CreatedAt AS createdAt,
           actor.Name AS changedBy
    FROM dbo.EmployeeJobHistory AS history
    LEFT JOIN dbo.AppUsers AS actor ON actor.AppUserId = history.ChangedByAppUserId
    WHERE history.EmployeeId = @EmployeeId
    ORDER BY history.ValidFrom DESC, history.CreatedAt DESC;
END;
GO

/* --- Crear Solicitud de Personal (Vacaciones, Permisos, etc.) --- */
CREATE OR ALTER PROCEDURE dbo.usp_CreateHrRequest
    @HrRequestId UNIQUEIDENTIFIER,
    @MutationId UNIQUEIDENTIFIER,
    @EmployeeId NVARCHAR(100),
    @Category NVARCHAR(30),
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @Details NVARCHAR(1000),
    @AppUserId NVARCHAR(100),
    @ActorName NVARCHAR(240)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @AppUserId AND IsActive = 1 AND MustChangePassword = 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50447, 'La sesión no está autorizada para crear solicitudes.', 1;
    END;

    DECLARE @ExistingId UNIQUEIDENTIFIER;
    SELECT @ExistingId = HrRequestId
    FROM dbo.HrRequests WITH (UPDLOCK, HOLDLOCK)
    WHERE MutationId = @MutationId;

    IF @ExistingId IS NULL
    BEGIN
        IF @Category IS NULL OR @Category NOT IN (N'vacaciones', N'permiso', N'correccion_datos', N'consulta_laboral', N'seguridad', N'trato_recibido')
           OR NULLIF(LTRIM(RTRIM(@Details)), N'') IS NULL
           OR (@Category IN (N'vacaciones', N'permiso') AND (@StartDate IS NULL OR @EndDate IS NULL))
           OR (@StartDate IS NOT NULL AND @EndDate IS NOT NULL AND @EndDate < @StartDate)
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50444, 'Los datos de la solicitud no son válidos.', 1;
        END;

        -- Validar solapamiento con solicitudes ya aprobadas o enviadas de la misma categoría
        IF @Category IN (N'vacaciones', N'permiso') AND EXISTS (
            SELECT 1 FROM dbo.HrRequests
            WHERE EmployeeId = @EmployeeId AND Status IN (N'enviada', N'en_revision', N'aprobada')
              AND StartDate <= @EndDate AND EndDate >= @StartDate
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50451, 'Ya existe una solicitud de descanso o permiso para ese rango de fechas.', 1;
        END;

        INSERT INTO dbo.HrRequests (
            HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details
        )
        SELECT @HrRequestId, @MutationId, employee.EmployeeId, @Category, @StartDate, @EndDate, @Details
        FROM dbo.Employees AS employee
        WHERE employee.EmployeeId = @EmployeeId
          AND employee.AppUserId = @AppUserId
          AND employee.EmploymentStatus = N'activo';

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50433, 'No existe un expediente activo vinculado con la sesión.', 1;
        END;

        INSERT INTO dbo.HrRequestEvents (
            HrRequestEventId, HrRequestId, AppUserId, ActorName, EventType, Detail
        )
        VALUES (NEWID(), @HrRequestId, @AppUserId, @ActorName, N'enviada', N'Solicitud recibida en la bandeja.');

        SET @ExistingId = @HrRequestId;
    END;

    COMMIT TRANSACTION;
    SELECT HrRequestId AS id, Category AS category, StartDate AS startDate, EndDate AS endDate,
           Details AS details, Status AS status, Resolution AS resolution,
           CreatedAt AS createdAt, UpdatedAt AS updatedAt, DecidedAt AS decidedAt,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), Revision), 1) AS revision
    FROM dbo.HrRequests
    WHERE HrRequestId = @ExistingId;
END;
GO

/* --- Consultar Solicitudes (Cola de gestión o Mis casos) --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrRequests
    @ActorId NVARCHAR(100),
    @Scope NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EmployeeId NVARCHAR(100), @Management BIT = 0;
    SELECT @EmployeeId = employee.EmployeeId
    FROM dbo.Employees AS employee
    JOIN dbo.AppUsers AS actor ON actor.AppUserId = employee.AppUserId
    WHERE actor.AppUserId = @ActorId AND actor.IsActive = 1
      AND actor.MustChangePassword = 0 AND employee.EmploymentStatus <> N'baja';

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
    )
        THROW 50447, 'La sesión no está autorizada para consultar solicitudes.', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND
          (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @Management = 1;

    IF @Scope IS NULL OR @Scope NOT IN (N'mine', N'queue')
        THROW 50444, 'El alcance de solicitudes no es válido.', 1;
    IF @Scope = N'queue' AND @Management = 0
        THROW 50440, 'Se requiere autorización de administración de Talento humano.', 1;
    IF @Scope = N'mine' AND @EmployeeId IS NULL
        RETURN;

    SELECT TOP (200) request.HrRequestId AS id, request.EmployeeId AS employeeId,
           employee.Name AS employeeName, request.Category AS category,
           request.StartDate AS startDate, request.EndDate AS endDate,
           request.Details AS details, request.Status AS status,
           request.Resolution AS resolution, request.CreatedAt AS createdAt,
           request.UpdatedAt AS updatedAt, request.DecidedAt AS decidedAt,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), request.Revision), 1) AS revision
    FROM dbo.HrRequests AS request
    JOIN dbo.Employees AS employee ON employee.EmployeeId = request.EmployeeId
    WHERE (@Scope = N'queue' AND @Management = 1)
       OR (@Scope = N'mine' AND request.EmployeeId = @EmployeeId)
    ORDER BY request.CreatedAt DESC;
END;
GO

/* --- Actualizar Estado de Solicitud (Separación de Funciones y Concurrencia) --- */
CREATE OR ALTER PROCEDURE dbo.usp_UpdateHrRequestStatus
    @HrRequestId UNIQUEIDENTIFIER,
    @ExpectedRevision BINARY(8),
    @Status NVARCHAR(20),
    @Resolution NVARCHAR(1000),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    DECLARE @EmployeeId NVARCHAR(100), @ApplicantId NVARCHAR(100),
            @CurrentStatus NVARCHAR(20), @CurrentRevision BINARY(8);
    SELECT @EmployeeId = request.EmployeeId, @ApplicantId = employee.AppUserId,
           @CurrentStatus = request.Status, @CurrentRevision = request.Revision
    FROM dbo.HrRequests AS request WITH (UPDLOCK, HOLDLOCK)
    JOIN dbo.Employees AS employee ON employee.EmployeeId = request.EmployeeId
    WHERE request.HrRequestId = @HrRequestId;

    IF @EmployeeId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50436, 'No se encontró la solicitud.', 1;
    END;
    IF @CurrentRevision <> @ExpectedRevision
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50437, 'La solicitud cambió desde la última lectura. Actualiza la lista antes de resolver.', 1;
    END;
    IF @CurrentStatus NOT IN (N'enviada', N'en_revision')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50438, 'La solicitud ya tiene una decisión final.', 1;
    END;
    IF @Status IS NULL OR @Status NOT IN (N'en_revision', N'aprobada', N'rechazada', N'cancelada')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50445, 'El estado de la solicitud no es válido.', 1;
    END;

    IF @Status = N'cancelada'
    BEGIN
        IF @ApplicantId <> @ActorId
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50439, 'Solo quien envió la solicitud puede cancelarla.', 1;
        END;
    END
    ELSE
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.AppUsers
            WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
              AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
                  SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
              )))
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50440, 'Se requiere autorización de administración de Talento humano.', 1;
        END;

        -- Regla estricta: Separación de funciones, no se permite auto-aprobar solicitudes propias
        IF @Status IN (N'aprobada', N'rechazada') AND @ApplicantId = @ActorId
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50441, 'No puedes decidir una solicitud propia. Debe revisarla otro administrador.', 1;
        END;

        IF @Status IN (N'aprobada', N'rechazada') AND NULLIF(LTRIM(RTRIM(@Resolution)), N'') IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50442, 'La decisión requiere una explicación clara para el trabajador.', 1;
        END;
    END;

    UPDATE dbo.HrRequests
    SET Status = @Status,
        Resolution = NULLIF(@Resolution, N''),
        AssignedToAppUserId = CASE WHEN @Status = N'en_revision' THEN @ActorId ELSE AssignedToAppUserId END,
        DecidedByAppUserId = CASE WHEN @Status IN (N'aprobada', N'rechazada') THEN @ActorId ELSE NULL END,
        DecidedAt = CASE WHEN @Status IN (N'aprobada', N'rechazada') THEN TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00') ELSE NULL END,
        UpdatedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
    WHERE HrRequestId = @HrRequestId AND Revision = @ExpectedRevision;

    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50437, 'La solicitud cambió concurrentemente.', 1;
    END;

    INSERT INTO dbo.HrRequestEvents (
        HrRequestEventId, HrRequestId, AppUserId, ActorName, EventType, Detail
    )
    VALUES (NEWID(), @HrRequestId, @ActorId, @ActorName, @Status, @Resolution);

    COMMIT TRANSACTION;
    SELECT HrRequestId AS id, EmployeeId AS employeeId, Category AS category,
           StartDate AS startDate, EndDate AS endDate, Details AS details,
           Status AS status, Resolution AS resolution, CreatedAt AS createdAt,
           UpdatedAt AS updatedAt, DecidedAt AS decidedAt,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), Revision), 1) AS revision
    FROM dbo.HrRequests
    WHERE HrRequestId = @HrRequestId;
END;
GO

/* --- Eventos y Trazabilidad de una Solicitud --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrRequestEvents
    @HrRequestId UNIQUEIDENTIFIER,
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EmployeeId NVARCHAR(100), @Management BIT = 0;
    SELECT @EmployeeId = EmployeeId
    FROM dbo.Employees
    WHERE AppUserId = @ActorId AND EmploymentStatus <> N'baja';

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
    )
        THROW 50447, 'La sesión no está autorizada para consultar solicitudes.', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND
          (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @Management = 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.HrRequests
        WHERE HrRequestId = @HrRequestId AND (@Management = 1 OR EmployeeId = @EmployeeId)
    )
        THROW 50450, 'No se encontró la solicitud o no tienes permiso para verla.', 1;

    SELECT event.HrRequestEventId AS id, event.ActorName AS actorName,
           event.EventType AS eventType, event.Detail AS detail, event.OccurredAt AS occurredAt
    FROM dbo.HrRequestEvents AS event
    WHERE event.HrRequestId = @HrRequestId
    ORDER BY event.OccurredAt;
END;
GO

/* --- Métricas Dinámicas del Dashboard de Talento Humano --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrDashboardMetrics
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsManagement BIT = 0, @EmployeeId NVARCHAR(100) = NULL;

    SELECT @EmployeeId = EmployeeId FROM dbo.Employees WHERE AppUserId = @ActorId;

    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @IsManagement = 1;

    IF @IsManagement = 1
    BEGIN
        SELECT
            (SELECT COUNT(*) FROM dbo.Employees WHERE EmploymentStatus = N'activo') AS activeEmployees,
            (SELECT COUNT(*) FROM dbo.HrRequests WHERE Status IN (N'enviada', N'en_revision')) AS pendingRequests,
            (SELECT COUNT(*) FROM dbo.HrContracts WHERE Status = N'en_revision' OR (EndDate IS NOT NULL AND EndDate <= DATEADD(DAY, 45, CONVERT(DATE, SYSUTCDATETIME())))) AS contractsToReview,
            (SELECT COUNT(*) FROM dbo.HrEquipmentDeliveries WHERE NextReplacementDate IS NOT NULL AND NextReplacementDate <= DATEADD(DAY, 15, CONVERT(DATE, SYSUTCDATETIME()))) AS pendingPpeDeliveries,
            (SELECT COUNT(*) FROM dbo.HrCorrectiveActions WHERE Status IN (N'abierta', N'en_proceso')) AS openCorrectiveActions,
            CAST(1 AS BIT) AS isManagementView;
    END
    ELSE
    BEGIN
        SELECT
            (SELECT COUNT(*) FROM dbo.HrRequests WHERE EmployeeId = @EmployeeId) AS myTotalRequests,
            (SELECT COUNT(*) FROM dbo.HrRequests WHERE EmployeeId = @EmployeeId AND Status IN (N'enviada', N'en_revision')) AS myPendingRequests,
            (SELECT COUNT(*) FROM dbo.HrContracts WHERE EmployeeId = @EmployeeId AND Status = N'registrado') AS myActiveContracts,
            (SELECT COUNT(*) FROM dbo.HrEquipmentDeliveries WHERE EmployeeId = @EmployeeId) AS mySafetyItems,
            (SELECT COUNT(*) FROM dbo.HrTrainingAttendees WHERE EmployeeId = @EmployeeId AND Attended = 1) AS myTrainingsCompleted,
            CAST(0 AS BIT) AS isManagementView;
    END;
END;
GO

/* =========================================================
   13. PERMISOS DE EJECUCIÓN PARA EL USUARIO DE LA APLICACIÓN
   ========================================================= */
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    REVOKE SELECT ON OBJECT::dbo.Employees FROM [raquel_erp_app];
    REVOKE SELECT ON OBJECT::dbo.EmployeeJobHistory FROM [raquel_erp_app];
    REVOKE SELECT ON OBJECT::dbo.HrRequests FROM [raquel_erp_app];
    REVOKE SELECT ON OBJECT::dbo.HrRequestEvents FROM [raquel_erp_app];
    REVOKE SELECT ON OBJECT::dbo.vw_HrEmployeeDirectory FROM [raquel_erp_app];

    GRANT SELECT ON OBJECT::dbo.Employees TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.vw_HrEmployeeDirectory TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.HrRequests TO [raquel_erp_app];
    GRANT SELECT, INSERT ON OBJECT::dbo.HrRequestEvents TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.EmployeeJobHistory TO [raquel_erp_app];

    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrMyEmployee TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrEmployeeDirectory TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrEmployeeDetail TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrEmployeeIdForUser TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateHrEmployee TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_UpdateHrEmployee TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_TerminateHrEmployee TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrEmployeeJobHistory TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrRequests TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrRequestEvents TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateHrRequest TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_UpdateHrRequestStatus TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrDashboardMetrics TO [raquel_erp_app];

    -- Tablas complementarias de solo lectura o acceso controlado
    GRANT SELECT ON OBJECT::dbo.HrContracts TO [raquel_erp_app];
    GRANT INSERT, UPDATE ON OBJECT::dbo.HrContracts TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrAttendanceRecords TO [raquel_erp_app];
    GRANT INSERT, UPDATE ON OBJECT::dbo.HrAttendanceRecords TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrSafetyEquipment TO [raquel_erp_app];
    GRANT SELECT, INSERT ON OBJECT::dbo.HrEquipmentDeliveries TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrSafetyTrainings TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrTrainingAttendees TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.HrSafetyIncidents TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.HrCorrectiveActions TO [raquel_erp_app];
    GRANT SELECT, UPDATE ON OBJECT::dbo.HrComplianceObligations TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrRightsArticles TO [raquel_erp_app];
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE AppUserId = N'u-super')
BEGIN
    INSERT INTO dbo.Employees (EmployeeId, Name, Position, Salary, Area, AppUserId, HireDate, IsActive, EmploymentStatus)
    VALUES (N'e0', N'Raquel López', N'Gerente General', 45000, N'Dirección', N'u-super', '2024-01-15', 1, N'activo');
END;
GO
