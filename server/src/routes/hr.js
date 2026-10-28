import { randomUUID } from "node:crypto";
import { Router } from "express";
import sql from "mssql";
import { z } from "zod";
import { getDatabase } from "../config/sqlserver.js";
import { requireAuth, requireHrManagement } from "../middleware/auth.js";

export const hrRouter = Router();

/* =========================================================
   SUPERFICIE PÚBLICA: BIBLIOTECA DE DERECHOS Y SEGURIDAD
   No requiere autenticación. Cero acceso a datos internos.
   ========================================================= */
hrRouter.get("/public/rights", async (_req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });
    const result = await pool.request().query(`
      SELECT ArticleId AS id, Slug AS slug, Category AS category,
             Question AS question, ShortAnswer AS shortAnswer,
             PracticalExample AS practicalExample, LegalSource AS legalSource,
             ReviewedAt AS reviewedAt, EditorialOwner AS editorialOwner,
             OrderIndex AS orderIndex
      FROM dbo.HrRightsArticles
      WHERE IsPublic = 1
      ORDER BY OrderIndex, Question
    `);
    res.json({ articles: result.recordset });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   SUPERFICIE PRIVADA: AUTENTICACIÓN Y SEGURIDAD OBLIGATORIA
   ========================================================= */
hrRouter.use(requireAuth);
hrRouter.use((req, res, next) => {
  if (req.user.mustChangePassword) {
    return res.status(403).json({ message: "Debes cambiar la contraseña temporal antes de consultar Talento humano." });
  }
  return next();
});

function isManagementUser(user) {
  return user.hierarchy === "superadmin"
    || (user.hierarchy === "administrador" && user.areas.includes("rrhh"));
}

async function getEmployeeId(pool, appUserId) {
  const result = await pool.request()
    .input("ActorId", sql.NVarChar(100), appUserId)
    .execute("dbo.usp_GetHrEmployeeIdForUser");
  return result.recordset[0]?.employeeId ?? null;
}

/* =========================================================
   1. DASHBOARD DE TALENTO HUMANO (MÉTRICAS DINÁMICAS)
   ========================================================= */
hrRouter.get("/dashboard/metrics", async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_GetHrDashboardMetrics");
    res.json({ metrics: result.recordset[0] ?? null, period: "Año en curso", lastUpdate: new Date().toISOString() });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   2. MI ESPACIO (EXPEDIENTE PROPIO DEL TRABAJADOR)
   ========================================================= */
hrRouter.get("/me", async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_GetHrMyEmployee");
    const employee = result.recordset[0] ?? null;

    let contracts = [];
    let ppeItems = [];
    let balance = null;

    if (employee) {
      // Contratos propios
      const cRes = await pool.request()
        .input("EmployeeId", sql.NVarChar(100), employee.id)
        .query(`
          SELECT ContractId AS id, ContractNumber AS contractNumber, ContractType AS contractType,
                 Position AS position, WorkSchedule AS workSchedule, StartDate AS startDate,
                 EndDate AS endDate, AgreedTerms AS agreedTerms, Status AS status,
                 CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), Revision), 1) AS revision
          FROM dbo.HrContracts WHERE EmployeeId = @EmployeeId ORDER BY StartDate DESC
        `);
      contracts = cRes.recordset;

      // EPP propio
      const pRes = await pool.request()
        .input("EmployeeId", sql.NVarChar(100), employee.id)
        .query(`
          SELECT d.DeliveryId AS id, eq.Name AS equipmentName, eq.Category AS category,
                 d.DeliveryDate AS deliveryDate, d.NextReplacementDate AS nextReplacementDate, d.Notes AS notes
          FROM dbo.HrEquipmentDeliveries d
          JOIN dbo.HrSafetyEquipment eq ON eq.EquipmentId = d.EquipmentId
          WHERE d.EmployeeId = @EmployeeId ORDER BY d.DeliveryDate DESC
        `);
      ppeItems = pRes.recordset;

      // Cálculo legal explicable de vacaciones (Ley 185 Art. 76: 15 días por semestre = 2.5 días/mes)
      const hire = employee.hireDate ? new Date(employee.hireDate) : new Date("2025-01-01");
      const today = new Date();
      const diffMonths = Math.max(0, (today.getFullYear() - hire.getFullYear()) * 12 + (today.getMonth() - hire.getMonth()) + (today.getDate() >= hire.getDate() ? 0 : -1));
      const accruedDays = Number((diffMonths * 2.5).toFixed(1));

      const takenRes = await pool.request()
        .input("EmployeeId", sql.NVarChar(100), employee.id)
        .query(`
          SELECT ISNULL(SUM(DATEDIFF(DAY, StartDate, EndDate) + 1), 0) AS takenDays
          FROM dbo.HrRequests
          WHERE EmployeeId = @EmployeeId AND Category = 'vacaciones' AND Status = 'aprobada'
        `);
      const approvedDays = Number(takenRes.recordset[0]?.takenDays ?? 0);

      const pendingRes = await pool.request()
        .input("EmployeeId", sql.NVarChar(100), employee.id)
        .query(`
          SELECT ISNULL(SUM(DATEDIFF(DAY, StartDate, EndDate) + 1), 0) AS pendingDays
          FROM dbo.HrRequests
          WHERE EmployeeId = @EmployeeId AND Category = 'vacaciones' AND Status IN ('enviada', 'en_revision')
        `);
      const pendingDays = Number(pendingRes.recordset[0]?.pendingDays ?? 0);

      balance = {
        period: `${today.getFullYear()}`,
        initialDays: 0,
        accruedDays,
        approvedDays,
        pendingDays,
        availableDays: Math.max(0, Number((accruedDays - approvedDays).toFixed(1))),
        legalBasis: "Código del Trabajo de Nicaragua (Ley 185, Art. 76): 15 días continuos de descanso remunerado por cada 6 meses continuos de labor (2.5 días acumulados por mes)."
      };
    }

    res.json({ employee, contracts, ppeItems, balance });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   3. DIRECTORIO Y EXPEDIENTE DE PERSONAL (ADMINISTRACIÓN)
   ========================================================= */
const employeeSchema = z.object({
  code: z.string().trim().min(1).max(100).optional().nullable(),
  employeeId: z.string().trim().min(1).max(100).optional().nullable(),
  name: z.string().trim().min(1).max(240),
  position: z.string().trim().min(1).max(200),
  area: z.string().trim().min(1).max(120),
  salary: z.number().finite().positive().max(999999999999999),
  hireDate: z.string().date(),
  appUserId: z.string().trim().min(1).max(100).nullable().optional()
});

const employeeUpdateSchema = z.object({
  position: z.string().trim().min(1).max(200),
  area: z.string().trim().min(1).max(120),
  salary: z.number().finite().positive().max(999999999999999).nullable().optional(),
  employmentStatus: z.enum(["activo", "licencia", "baja"])
});

const dismissalSchema = z.object({
  dismissalDate: z.string().date(),
  dismissalReason: z.string().trim().min(3).max(500),
  dismissalDocRef: z.string().trim().max(300).nullable().optional()
});

hrRouter.get("/employees", requireHrManagement, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_GetHrEmployeeDirectory");
    res.json({ employees: result.recordset });
  } catch (error) {
    next(error);
  }
});

hrRouter.get("/employees/:id", async (req, res, next) => {
  try {
    const employeeId = z.string().trim().min(1).max(100).parse(req.params.id);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const result = await pool.request()
      .input("EmployeeId", sql.NVarChar(100), employeeId)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_GetHrEmployeeDetail");

    const employee = result.recordsets[0]?.[0] ?? null;
    if (!employee) return res.status(404).json({ message: "No se encontró el expediente solicitado." });

    res.json({
      employee,
      contracts: result.recordsets[1] ?? [],
      requests: result.recordsets[2] ?? [],
      ppeItems: result.recordsets[3] ?? []
    });
  } catch (error) {
    if (error.number === 50434) return res.status(403).json({ message: error.message });
    next(error);
  }
});

hrRouter.post("/employees", requireHrManagement, async (req, res, next) => {
  try {
    const values = employeeSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const targetEmployeeId = (values.code || values.employeeId || "").trim() || `EMP-${new Date().getFullYear()}-${Date.now().toString(36).slice(-4).toUpperCase()}`;

    const result = await pool.request()
      .input("MutationId", sql.UniqueIdentifier, randomUUID())
      .input("EmployeeId", sql.NVarChar(100), targetEmployeeId)
      .input("Name", sql.NVarChar(240), values.name)
      .input("Position", sql.NVarChar(200), values.position)
      .input("Salary", sql.Decimal(19, 4), values.salary)
      .input("Area", sql.NVarChar(120), values.area)
      .input("AppUserId", sql.NVarChar(100), values.appUserId || null)
      .input("HireDate", sql.Date, values.hireDate)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_CreateHrEmployee");
    const employee = result.recordset[0];
    if (!employee) throw new Error("SQL Server no confirmó el expediente de personal.");
    res.status(201).json({ employee });
  } catch (error) {
    if (error.number === 2601 || error.number === 2627) {
      return res.status(409).json({ message: "El código de colaborador o la cuenta de usuario ya existe en el sistema." });
    }
    if (error.number === 50434 || error.number === 50435) {
      return res.status(403).json({ message: error.message });
    }
    next(error);
  }
});

hrRouter.patch("/employees/:id", requireHrManagement, async (req, res, next) => {
  try {
    const employeeId = z.string().trim().min(1).max(100).parse(req.params.id);
    const values = employeeUpdateSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request()
      .input("EmployeeId", sql.NVarChar(100), employeeId)
      .input("Position", sql.NVarChar(200), values.position)
      .input("Area", sql.NVarChar(120), values.area)
      .input("Salary", sql.Decimal(19, 4), values.salary ?? null)
      .input("EmploymentStatus", sql.NVarChar(20), values.employmentStatus)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_UpdateHrEmployee");
    const employee = result.recordset[0];
    if (!employee) throw new Error("SQL Server no devolvió el expediente actualizado.");
    res.json({ employee });
  } catch (error) {
    if (error.number === 50434) return res.status(403).json({ message: error.message });
    if (error.number === 50448) return res.status(404).json({ message: error.message });
    if (error.number === 50443) return res.status(400).json({ message: error.message });
    next(error);
  }
});

hrRouter.post("/employees/:id/terminate", requireHrManagement, async (req, res, next) => {
  try {
    const employeeId = z.string().trim().min(1).max(100).parse(req.params.id);
    const values = dismissalSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request()
      .input("EmployeeId", sql.NVarChar(100), employeeId)
      .input("DismissalDate", sql.Date, values.dismissalDate)
      .input("DismissalReason", sql.NVarChar(500), values.dismissalReason)
      .input("DismissalDocRef", sql.NVarChar(300), values.dismissalDocRef ?? null)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_TerminateHrEmployee");
    res.json({ employee: result.recordset[0] });
  } catch (error) {
    if (error.number === 50434) return res.status(403).json({ message: error.message });
    if (error.number === 50448) return res.status(404).json({ message: error.message });
    next(error);
  }
});

hrRouter.get("/employees/:id/history", async (req, res, next) => {
  try {
    const employeeId = z.string().trim().min(1).max(100).parse(req.params.id);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request()
      .input("EmployeeId", sql.NVarChar(100), employeeId)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_GetHrEmployeeJobHistory");
    res.json({ history: result.recordset });
  } catch (error) {
    if (error.number === 50434) return res.status(403).json({ message: error.message });
    if (error.number === 50448) return res.status(404).json({ message: error.message });
    next(error);
  }
});

/* =========================================================
   4. CONTRATOS LABORALES
   ========================================================= */
const contractSchema = z.object({
  employeeId: z.string().trim().min(1).max(100),
  contractType: z.enum(["indefinido", "determinado", "obra_servicio", "periodo_prueba"]),
  position: z.string().trim().min(1).max(200),
  workSchedule: z.string().trim().min(1).max(100),
  startDate: z.string().date(),
  endDate: z.string().date().nullable().optional(),
  agreedTerms: z.string().trim().min(5).max(2000),
  docReference: z.string().trim().max(500).nullable().optional(),
  status: z.enum(["borrador", "en_revision", "registrado", "finalizado"]).default("registrado")
});

hrRouter.get("/contracts", async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const isManagement = isManagementUser(req.user);
    const employeeId = await getEmployeeId(pool, req.user.id);

    let query = `
      SELECT c.ContractId AS id, c.EmployeeId AS employeeId, e.Name AS employeeName,
             c.ContractNumber AS contractNumber, c.ContractType AS contractType,
             c.Position AS position, c.WorkSchedule AS workSchedule,
             c.StartDate AS startDate, c.EndDate AS endDate,
             c.AgreedTerms AS agreedTerms, c.DocumentRef AS docReference, c.Status AS status,
             CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), c.Revision), 1) AS revision,
             c.CreatedAt AS createdAt
      FROM dbo.HrContracts c
      JOIN dbo.Employees e ON e.EmployeeId = c.EmployeeId
    `;

    if (!isManagement) {
      if (!employeeId) return res.json({ contracts: [] });
      query += ` WHERE c.EmployeeId = @EmployeeId ORDER BY c.StartDate DESC`;
    } else {
      query += ` ORDER BY c.StartDate DESC`;
    }

    const request = pool.request();
    if (!isManagement) request.input("EmployeeId", sql.NVarChar(100), employeeId);
    const result = await request.query(query);
    res.json({ contracts: result.recordset });
  } catch (error) {
    next(error);
  }
});

hrRouter.post("/contracts", requireHrManagement, async (req, res, next) => {
  try {
    const values = contractSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const contractNumber = `CT-RAQ-${new Date(values.startDate).getFullYear()}-${Math.floor(100 + Math.random() * 900)}`;

    const result = await pool.request()
      .input("ContractId", sql.UniqueIdentifier, randomUUID())
      .input("EmployeeId", sql.NVarChar(100), values.employeeId)
      .input("ContractNumber", sql.NVarChar(60), contractNumber)
      .input("ContractType", sql.NVarChar(40), values.contractType)
      .input("Position", sql.NVarChar(200), values.position)
      .input("WorkSchedule", sql.NVarChar(100), values.workSchedule)
      .input("StartDate", sql.Date, values.startDate)
      .input("EndDate", sql.Date, values.endDate ?? null)
      .input("AgreedTerms", sql.NVarChar(2000), values.agreedTerms)
      .input("DocumentRef", sql.NVarChar(500), values.docReference ?? null)
      .input("Status", sql.NVarChar(30), values.status)
      .input("ReviewedByAppUserId", sql.NVarChar(100), req.user.id)
      .query(`
        INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, EndDate, AgreedTerms, DocumentRef, Status, ReviewedByAppUserId, ReviewedAt)
        OUTPUT inserted.ContractId AS id, inserted.ContractNumber AS contractNumber, inserted.DocumentRef AS docReference, inserted.Status AS status, CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), inserted.Revision), 1) AS revision
        VALUES (@ContractId, @EmployeeId, @ContractNumber, @ContractType, @Position, @WorkSchedule, @StartDate, @EndDate, @AgreedTerms, @DocumentRef, @Status, @ReviewedByAppUserId, TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'))
      `);

    res.status(201).json({ contract: result.recordset[0] });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   5. VACACIONES Y PERMISOS (SALDOS Y SOLICITUDES)
   ========================================================= */
const requestSchema = z.object({
  category: z.enum(["vacaciones", "permiso", "correccion_datos", "consulta_laboral", "seguridad", "trato_recibido"]),
  startDate: z.string().date().nullable(),
  endDate: z.string().date().nullable(),
  details: z.string().trim().min(1).max(1000),
  mutationId: z.string().uuid()
}).superRefine((request, context) => {
  if (request.category === "vacaciones" || request.category === "permiso") {
    if (!request.startDate || !request.endDate) {
      context.addIssue({ code: z.ZodIssueCode.custom, path: ["startDate"], message: "Indica las fechas de inicio y fin para el permiso o vacaciones." });
    }
  }
  if (request.startDate && request.endDate && request.endDate < request.startDate) {
    context.addIssue({ code: z.ZodIssueCode.custom, path: ["endDate"], message: "La fecha final debe ser igual o posterior a la inicial." });
  }
});

const decisionSchema = z.object({
  status: z.enum(["en_revision", "aprobada", "rechazada", "cancelada"]),
  resolution: z.string().trim().max(1000).default(""),
  revision: z.string().regex(/^0x[0-9a-f]{16}$/i)
});

hrRouter.get("/requests", async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const scope = isManagementUser(req.user) && req.query.scope !== "mine" ? "queue" : "mine";
    const result = await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("Scope", sql.NVarChar(10), scope)
      .execute("dbo.usp_GetHrRequests");
    res.json({ requests: result.recordset, view: scope });
  } catch (error) {
    if (error.number === 50440 || error.number === 50447) {
      return res.status(403).json({ message: error.message });
    }
    if (error.number === 50444) return res.status(400).json({ message: error.message });
    next(error);
  }
});

hrRouter.post("/requests", async (req, res, next) => {
  try {
    const values = requestSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const employeeId = await getEmployeeId(pool, req.user.id);
    if (!employeeId) {
      return res.status(403).json({ message: "Tu cuenta no está vinculada a un expediente activo de personal. Contacta a Talento humano." });
    }
    const result = await pool.request()
      .input("HrRequestId", sql.UniqueIdentifier, randomUUID())
      .input("MutationId", sql.UniqueIdentifier, values.mutationId)
      .input("EmployeeId", sql.NVarChar(100), employeeId)
      .input("Category", sql.NVarChar(30), values.category)
      .input("StartDate", sql.Date, values.startDate)
      .input("EndDate", sql.Date, values.endDate)
      .input("Details", sql.NVarChar(1000), values.details)
      .input("AppUserId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name)
      .execute("dbo.usp_CreateHrRequest");
    const request = result.recordset[0];
    if (!request) throw new Error("SQL Server no confirmó la solicitud.");
    res.status(201).json({ request });
  } catch (error) {
    if (error.number === 50433) return res.status(403).json({ message: "Tu cuenta no está vinculada a un expediente activo de personal." });
    if (error.number === 50451) return res.status(409).json({ message: error.message });
    if (error.number === 50446 || error.number === 2601 || error.number === 2627) {
      return res.status(409).json({ message: "Esta solicitud ya fue recibida anteriormente." });
    }
    next(error);
  }
});

hrRouter.patch("/requests/:id", async (req, res, next) => {
  try {
    const requestId = z.string().uuid().parse(req.params.id);
    const decision = decisionSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    if (["aprobada", "rechazada"].includes(decision.status) && !decision.resolution) {
      return res.status(400).json({ message: "Escribe una explicación para la decisión." });
    }
    const result = await pool.request()
      .input("HrRequestId", sql.UniqueIdentifier, requestId)
      .input("ExpectedRevision", sql.Binary(8), Buffer.from(decision.revision.slice(2), "hex"))
      .input("Status", sql.NVarChar(20), decision.status)
      .input("Resolution", sql.NVarChar(1000), decision.resolution || null)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name)
      .execute("dbo.usp_UpdateHrRequestStatus");
    const request = result.recordset[0];
    if (!request) throw new Error("SQL Server no devolvió la solicitud actualizada.");
    res.json({ request });
  } catch (error) {
    if (error.number === 50436) return res.status(404).json({ message: "No se encontró la solicitud." });
    if (error.number === 50437) return res.status(409).json({ message: "La solicitud cambió desde la última lectura. Actualiza la lista antes de decidir." });
    if (error.number === 50438) return res.status(409).json({ message: "La solicitud ya tiene una decisión final." });
    if (error.number === 50439 || error.number === 50440 || error.number === 50441) {
      return res.status(403).json({ message: error.message });
    }
    if (error.number === 50442) return res.status(400).json({ message: "La decisión requiere una explicación." });
    next(error);
  }
});

hrRouter.get("/requests/:id/events", async (req, res, next) => {
  try {
    const requestId = z.string().uuid().parse(req.params.id);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request()
      .input("HrRequestId", sql.UniqueIdentifier, requestId)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_GetHrRequestEvents");
    res.json({ events: result.recordset });
  } catch (error) {
    if (error.number === 50450) return res.status(404).json({ message: error.message });
    if (error.number === 50447) return res.status(403).json({ message: error.message });
    next(error);
  }
});

/* =========================================================
   6. ASISTENCIA Y JORNADA LABORAL
   ========================================================= */
hrRouter.get("/attendance", async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const isManagement = isManagementUser(req.user);
    const employeeId = await getEmployeeId(pool, req.user.id);

    let query = `
      SELECT a.AttendanceId AS id, a.EmployeeId AS employeeId, e.Name AS employeeName,
             a.RecordDate AS recordDate, a.ShiftName AS shiftName,
             CONVERT(VARCHAR(5), a.ScheduledIn, 108) AS scheduledIn,
             CONVERT(VARCHAR(5), a.ScheduledOut, 108) AS scheduledOut,
             CONVERT(VARCHAR(5), a.ActualIn, 108) AS actualIn,
             CONVERT(VARCHAR(5), a.ActualOut, 108) AS actualOut,
             CONVERT(VARCHAR(5), a.OriginalIn, 108) AS originalIn,
             CONVERT(VARCHAR(5), a.OriginalOut, 108) AS originalOut,
             a.HoursLogged AS hoursLogged, a.HoursReviewed AS hoursReviewed,
             a.HoursAuthorized AS hoursAuthorized, a.IncidentType AS incidentType,
             a.IncidentNotes AS incidentNotes, a.CorrectionReason AS correctionReason,
             a.Status AS status, CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), a.Revision), 1) AS revision
      FROM dbo.HrAttendanceRecords a
      JOIN dbo.Employees e ON e.EmployeeId = a.EmployeeId
    `;

    if (!isManagement) {
      if (!employeeId) return res.json({ records: [] });
      query += ` WHERE a.EmployeeId = @EmployeeId ORDER BY a.RecordDate DESC`;
    } else {
      query += ` ORDER BY a.RecordDate DESC`;
    }

    const request = pool.request();
    if (!isManagement) request.input("EmployeeId", sql.NVarChar(100), employeeId);
    const result = await request.query(query);
    res.json({ records: result.recordset });
  } catch (error) {
    next(error);
  }
});

const attendanceCorrectionSchema = z.object({
  attendanceId: z.string().uuid(),
  requestedIn: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/),
  requestedOut: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/),
  reason: z.string().trim().min(5).max(500)
});

hrRouter.post("/attendance/correction", async (req, res, next) => {
  try {
    const values = attendanceCorrectionSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const result = await pool.request()
      .input("AttendanceId", sql.UniqueIdentifier, values.attendanceId)
      .input("RequestedIn", sql.VarChar(5), values.requestedIn)
      .input("RequestedOut", sql.VarChar(5), values.requestedOut)
      .input("Reason", sql.NVarChar(500), values.reason)
      .query(`
        UPDATE dbo.HrAttendanceRecords
        SET OriginalIn = COALESCE(OriginalIn, ActualIn),
            OriginalOut = COALESCE(OriginalOut, ActualOut),
            ActualIn = @RequestedIn,
            ActualOut = @RequestedOut,
            CorrectionReason = @Reason,
            Status = 'en_revision'
        WHERE AttendanceId = @AttendanceId;
        SELECT AttendanceId AS id, Status AS status FROM dbo.HrAttendanceRecords WHERE AttendanceId = @AttendanceId;
      `);

    res.json({ success: true, record: result.recordset[0] });
  } catch (error) {
    next(error);
  }
});

const attendanceCreateSchema = z.object({
  employeeId: z.string().trim().min(1).max(100),
  recordDate: z.string().date(),
  shiftName: z.string().trim().min(1).max(60).default("Taller Diurno (8h)"),
  scheduledIn: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/).default("08:00"),
  scheduledOut: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/).default("17:00"),
  actualIn: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/).nullable().optional(),
  actualOut: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/).nullable().optional(),
  incidentType: z.enum(["ninguna", "tardanza", "falta_justificada", "falta_injustificada", "salida_anticipada", "permiso_oficial"]).default("ninguna"),
  incidentNotes: z.string().trim().max(500).nullable().optional()
});

hrRouter.post("/attendance", requireHrManagement, async (req, res, next) => {
  try {
    const values = attendanceCreateSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const attendanceId = randomUUID();
    let hoursLogged = 8.0;
    if (values.actualIn && values.actualOut) {
      const [inH, inM] = values.actualIn.split(":").map(Number);
      const [outH, outM] = values.actualOut.split(":").map(Number);
      const totalMinutes = (outH * 60 + outM) - (inH * 60 + inM) - 60;
      hoursLogged = Math.max(0, Number((totalMinutes / 60).toFixed(2)));
    }

    const result = await pool.request()
      .input("AttendanceId", sql.UniqueIdentifier, attendanceId)
      .input("EmployeeId", sql.NVarChar(100), values.employeeId)
      .input("RecordDate", sql.Date, values.recordDate)
      .input("ShiftName", sql.NVarChar(60), values.shiftName)
      .input("ScheduledIn", sql.VarChar(5), values.scheduledIn)
      .input("ScheduledOut", sql.VarChar(5), values.scheduledOut)
      .input("ActualIn", sql.VarChar(5), values.actualIn ?? values.scheduledIn)
      .input("ActualOut", sql.VarChar(5), values.actualOut ?? values.scheduledOut)
      .input("HoursLogged", sql.Decimal(5, 2), hoursLogged)
      .input("HoursReviewed", sql.Decimal(5, 2), hoursLogged)
      .input("HoursAuthorized", sql.Decimal(5, 2), hoursLogged)
      .input("IncidentType", sql.NVarChar(40), values.incidentType)
      .input("IncidentNotes", sql.NVarChar(500), values.incidentNotes ?? null)
      .input("Status", sql.NVarChar(30), "autorizado_nomina")
      .input("AuthorizedByAppUserId", sql.NVarChar(100), req.user.id)
      .query(`
        IF EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = @EmployeeId AND RecordDate = @RecordDate)
        BEGIN
          UPDATE dbo.HrAttendanceRecords
          SET ShiftName = @ShiftName,
              ScheduledIn = @ScheduledIn,
              ScheduledOut = @ScheduledOut,
              ActualIn = @ActualIn,
              ActualOut = @ActualOut,
              HoursLogged = @HoursLogged,
              HoursReviewed = @HoursReviewed,
              HoursAuthorized = @HoursAuthorized,
              IncidentType = @IncidentType,
              IncidentNotes = @IncidentNotes,
              Status = @Status,
              AuthorizedByAppUserId = @AuthorizedByAppUserId
          OUTPUT inserted.AttendanceId AS id, inserted.RecordDate AS recordDate, inserted.Status AS status
          WHERE EmployeeId = @EmployeeId AND RecordDate = @RecordDate;
        END
        ELSE
        BEGIN
          INSERT INTO dbo.HrAttendanceRecords (
            AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut,
            ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized,
            IncidentType, IncidentNotes, Status, AuthorizedByAppUserId
          )
          OUTPUT inserted.AttendanceId AS id, inserted.RecordDate AS recordDate, inserted.Status AS status
          VALUES (
            @AttendanceId, @EmployeeId, @RecordDate, @ShiftName, @ScheduledIn, @ScheduledOut,
            @ActualIn, @ActualOut, @HoursLogged, @HoursReviewed, @HoursAuthorized,
            @IncidentType, @IncidentNotes, @Status, @AuthorizedByAppUserId
          );
        END;
      `);

    res.status(201).json({ record: result.recordset[0] });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   7. SEGURIDAD Y BIENESTAR (VIDRIO, ALUMINIO, ALTURAS)
   ========================================================= */
const equipmentDeliverySchema = z.object({
  employeeId: z.string().trim().min(1).max(100),
  equipmentId: z.string().uuid(),
  deliveryDate: z.string().date(),
  deliveryType: z.enum(["dotacion_inicial", "reposicion_desgaste", "reposicion_dano"]).default("dotacion_inicial"),
  nextReplacementDate: z.string().date().nullable().optional(),
  notes: z.string().trim().max(500).nullable().optional()
});

hrRouter.post("/safety/equipment-delivery", requireHrManagement, async (req, res, next) => {
  try {
    const values = equipmentDeliverySchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const deliveryId = randomUUID();
    const result = await pool.request()
      .input("DeliveryId", sql.UniqueIdentifier, deliveryId)
      .input("EmployeeId", sql.NVarChar(100), values.employeeId)
      .input("EquipmentId", sql.UniqueIdentifier, values.equipmentId)
      .input("DeliveryDate", sql.Date, values.deliveryDate)
      .input("DeliveryType", sql.NVarChar(40), values.deliveryType)
      .input("NextReplacementDate", sql.Date, values.nextReplacementDate ?? null)
      .input("Notes", sql.NVarChar(500), values.notes ?? null)
      .input("DeliveredByAppUserId", sql.NVarChar(100), req.user.id)
      .query(`
        INSERT INTO dbo.HrEquipmentDeliveries (
          DeliveryId, EmployeeId, EquipmentId, DeliveryDate, DeliveryType,
          NextReplacementDate, Notes, DeliveredByAppUserId
        )
        OUTPUT inserted.DeliveryId AS id, inserted.DeliveryDate AS deliveryDate, inserted.DeliveryType AS deliveryType
        VALUES (
          @DeliveryId, @EmployeeId, @EquipmentId, @DeliveryDate, @DeliveryType,
          @NextReplacementDate, @Notes, @DeliveredByAppUserId
        );
      `);

    res.status(201).json({ delivery: result.recordset[0] });
  } catch (error) {
    next(error);
  }
});
hrRouter.get("/safety/overview", async (_req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const [equipmentRes, trainingsRes, incidentsRes, actionsRes] = await Promise.all([
      pool.request().query(`SELECT EquipmentId AS id, Name AS name, Category AS category, StandardNorm AS standardNorm, StockQty AS stockQty, ReplacementPeriodDays AS replacementDays FROM dbo.HrSafetyEquipment WHERE IsActive = 1 ORDER BY Category`),
      pool.request().query(`SELECT TrainingId AS id, Topic AS topic, Instructor AS instructor, TrainingDate AS trainingDate, Hours AS hours, LegalRef AS legalRef, Status AS status, TargetArea AS targetArea FROM dbo.HrSafetyTrainings ORDER BY TrainingDate DESC`),
      pool.request().query(`SELECT IncidentId AS id, IncidentDate AS incidentDate, Area AS area, IncidentType AS incidentType, Severity AS severity, Description AS description, ImmediateAction AS immediateAction, Status AS status FROM dbo.HrSafetyIncidents ORDER BY IncidentDate DESC`),
      pool.request().query(`SELECT ActionId AS id, Description AS description, ResponsibleName AS responsibleName, DueDate AS dueDate, Status AS status FROM dbo.HrCorrectiveActions ORDER BY DueDate ASC`)
    ]);

    res.json({
      equipment: equipmentRes.recordset,
      trainings: trainingsRes.recordset,
      incidents: incidentsRes.recordset,
      actions: actionsRes.recordset
    });
  } catch (error) {
    next(error);
  }
});

const reportIncidentSchema = z.object({
  area: z.string().trim().min(2).max(100),
  incidentType: z.enum(["condicion_insegura", "acto_inseguro", "casi_accidente", "incidente_menor"]),
  severity: z.enum(["baja", "media", "alta", "critica"]),
  description: z.string().trim().min(5).max(1000),
  immediateAction: z.string().trim().max(1000).optional()
});

hrRouter.post("/safety/incidents", async (req, res, next) => {
  try {
    const values = reportIncidentSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const result = await pool.request()
      .input("IncidentId", sql.UniqueIdentifier, randomUUID())
      .input("ReportedByAppUserId", sql.NVarChar(100), req.user.id)
      .input("Area", sql.NVarChar(100), values.area)
      .input("IncidentType", sql.NVarChar(40), values.incidentType)
      .input("Severity", sql.NVarChar(20), values.severity)
      .input("Description", sql.NVarChar(1000), values.description)
      .input("ImmediateAction", sql.NVarChar(1000), values.immediateAction ?? null)
      .query(`
        INSERT INTO dbo.HrSafetyIncidents (IncidentId, ReportedByAppUserId, Area, IncidentType, Severity, Description, ImmediateAction, Status)
        OUTPUT inserted.IncidentId AS id, inserted.Area AS area, inserted.Status AS status, inserted.IncidentDate AS incidentDate
        VALUES (@IncidentId, @ReportedByAppUserId, @Area, @IncidentType, @Severity, @Description, @ImmediateAction, 'reportado')
      `);

    res.status(201).json({
      incident: result.recordset[0],
      disclaimer: "Reporte preventivo registrado en el sistema. Recuerda que no sustituye la atención inmediata médica ante emergencias."
    });
  } catch (error) {
    next(error);
  }
});

const trainingSchema = z.object({
  topic: z.string().trim().min(3).max(250),
  instructor: z.string().trim().min(2).max(200),
  trainingDate: z.string().date(),
  hours: z.number().int().positive().max(100),
  legalRef: z.string().trim().max(120).default("Ley 618 Arto. 18"),
  targetArea: z.string().trim().max(60).default("Taller y Montaje"),
  status: z.enum(["programada", "completada", "cancelada"]).default("completada")
});

hrRouter.post("/safety/trainings", requireHrManagement, async (req, res, next) => {
  try {
    const values = trainingSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const result = await pool.request()
      .input("Topic", sql.NVarChar(200), values.topic)
      .input("Instructor", sql.NVarChar(200), values.instructor)
      .input("TrainingDate", sql.Date, values.trainingDate)
      .input("Hours", sql.Int, values.hours)
      .input("LegalRef", sql.NVarChar(100), values.legalRef)
      .input("TargetArea", sql.NVarChar(100), values.targetArea)
      .input("Status", sql.NVarChar(30), values.status)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_CreateHrTraining");

    res.status(201).json({
      message: "Capacitación de seguridad registrada conforme a Ley 618.",
      training: result.recordset[0]
    });
  } catch (error) {
    next(error);
  }
});

const correctiveActionSchema = z.object({
  description: z.string().trim().min(5).max(1000),
  responsibleName: z.string().trim().min(2).max(200),
  dueDate: z.string().date(),
  status: z.enum(["abierta", "en_proceso", "implementada", "verificada_cerrada"]).default("abierta")
});

hrRouter.post("/safety/corrective-actions", requireHrManagement, async (req, res, next) => {
  try {
    const values = correctiveActionSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const result = await pool.request()
      .input("Description", sql.NVarChar(1000), values.description)
      .input("ResponsibleName", sql.NVarChar(200), values.responsibleName)
      .input("DueDate", sql.Date, values.dueDate)
      .input("Status", sql.NVarChar(30), values.status)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_CreateHrCorrectiveAction");

    res.status(201).json({
      message: "Acción correctiva de seguridad registrada.",
      action: result.recordset[0]
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   8. MARCO LEGAL Y CUMPLIMIENTO (NICARAGUA)
   ========================================================= */
hrRouter.get("/compliance", async (_req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request().query(`
      SELECT ObligationId AS id, Topic AS topic, LawName AS lawName,
             ArticleRef AS articleRef, Summary AS summary,
             ResponsibilityArea AS responsibilityArea, ComplianceStatus AS complianceStatus,
             LastReviewDate AS lastReviewDate, ResponsibleName AS responsibleName,
             Notes AS notes
      FROM dbo.HrComplianceObligations
      ORDER BY Topic
    `);
    res.json({ obligations: result.recordset });
  } catch (error) {
    next(error);
  }
});

hrRouter.patch("/compliance/:id", requireHrManagement, async (req, res, next) => {
  try {
    const obligationId = z.string().uuid().parse(req.params.id);
    const schema = z.object({
      complianceStatus: z.enum(["pendiente_revision", "documentacion_incompleta", "revisado_internamente", "constancia_registrada"]),
      notes: z.string().trim().max(1000).optional()
    });
    const values = schema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    const result = await pool.request()
      .input("ObligationId", sql.UniqueIdentifier, obligationId)
      .input("ComplianceStatus", sql.NVarChar(40), values.complianceStatus)
      .input("Notes", sql.NVarChar(1000), values.notes ?? null)
      .input("LastReviewDate", sql.Date, new Date().toISOString().slice(0, 10))
      .query(`
        UPDATE dbo.HrComplianceObligations
        SET ComplianceStatus = @ComplianceStatus,
            Notes = COALESCE(@Notes, Notes),
            LastReviewDate = @LastReviewDate
        WHERE ObligationId = @ObligationId;
        SELECT ObligationId AS id, ComplianceStatus AS complianceStatus, LastReviewDate AS lastReviewDate
        FROM dbo.HrComplianceObligations WHERE ObligationId = @ObligationId;
      `);

    res.json({ obligation: result.recordset[0] });
  } catch (error) {
    next(error);
  }
});
