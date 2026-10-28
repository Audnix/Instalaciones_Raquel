import { PAYROLL_PAYMENTS_SQL } from "../services/payrollHistorySql.js";
import { checkPayrollPayment } from "../services/payrollPaymentCheck.js";
import { PAYROLL_RUNS_SQL } from "../services/payrollReadSql.js";
import { randomUUID } from "node:crypto";
import { Router } from "express";
import sql from "mssql";
import { z } from "zod";
import { getDatabase } from "../config/sqlserver.js";
import { requireAuth } from "../middleware/auth.js";
import { canManagePayrollMoney, requiresPayrollFinancialPermission } from "../services/payrollPermissions.js";

export const payrollRouter = Router();

function requirePayrollPayment(req, res, next) {
  if (canManagePayrollMoney(req.user)) return next();
  return res.status(403).json({ message: "Registrar un pago requiere un administrador de Finanzas o Contabilidad." });
}

async function requireAccrualIntegrity(pool, res) {
  const check=await pool.request().query("SELECT OBJECT_ID(N'dbo.usp_PayrollAccrualIntegrityVersion',N'P') AS versionMarker");
  if(check.recordset[0]?.versionMarker) return true;
  res.status(503).json({code:"PAYROLL_ACCRUAL_MIGRATION_REQUIRED",message:"Falta aplicar la migración 31 para calcular y aprobar con reglas del período y contabilidad coherente."});
  return false;
}

// Middleware: verifica que el usuario pertenezca a la administración de RRHH, Finanzas o Contabilidad
function requirePayrollManagement(req, res, next) {
  if (req.user?.mustChangePassword) {
    return res.status(403).json({ message: "Debes cambiar la contraseña temporal antes de continuar." });
  }
  const isSuper = req.user?.hierarchy === "superadmin";
  const isAuthorizedAdmin = req.user?.hierarchy === "administrador"
    && req.user?.areas?.some((a) => ["rrhh", "finanzas", "contabilidad"].includes(a));

  if (!isSuper && !isAuthorizedAdmin) {
    return res.status(403).json({
      message: "Operación restringida a personal autorizado de Nómina, Talento Humano o Finanzas."
    });
  }
  return next();
}

// -----------------------------------------------------------------------------
// 1. REGLAS NORMATIVAS Y PARÁMETROS DE NICARAGUA
// -----------------------------------------------------------------------------
payrollRouter.get("/rules", requireAuth, async (_req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await pool.request().query(`
      SELECT RuleId AS id, RuleCode AS code, RuleName AS name, LawReference AS lawReference,
             OfficialSource AS officialSource, EffectiveFrom AS effectiveFrom, EffectiveTo AS effectiveTo,
             ParameterJson AS parameterJson, IsVerified AS isVerified, ReviewedBy AS reviewedBy,
             ReviewedAt AS reviewedAt, Status AS status
      FROM dbo.PayrollRulesCatalog
      ORDER BY EffectiveFrom DESC;
    `);

    res.json({ rules: result.recordset });
  } catch (err) {
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 2. LISTADO DE PLANILLAS DE NÓMINA
// -----------------------------------------------------------------------------
payrollRouter.get("/runs", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await pool.request()
      .input("IncludeClosed", sql.Bit, 0)
      .query(PAYROLL_RUNS_SQL);

    res.json({ runs: result.recordset });
  } catch (err) {
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 3. CREAR BORRADOR DE PLANILLA
// -----------------------------------------------------------------------------
const createDraftSchema = z.object({
  period: z.string().min(3).max(40),
  periodType: z.enum(["quincenal", "mensual", "catorcenal", "especial_aguinaldo", "liquidacion"]).default("quincenal"),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  paymentDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  notes: z.string().max(2000).optional()
});

payrollRouter.post("/runs", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const data = createDraftSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const runId = `run-${Date.now().toString(36)}-${randomUUID().slice(0, 6)}`;

    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), runId)
      .input("Period", sql.NVarChar(40), data.period)
      .input("PeriodType", sql.NVarChar(30), data.periodType)
      .input("StartDate", sql.Date, data.startDate)
      .input("EndDate", sql.Date, data.endDate)
      .input("PaymentDate", sql.Date, data.paymentDate)
      .input("Notes", sql.NVarChar(sql.MAX), data.notes ?? null)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name)
      .execute("dbo.usp_CreatePayrollDraft");

    res.status(201).json({
      message: "Borrador de planilla creado exitosamente con colaboradores activos preseleccionados.",
      run: result.recordset[0]
    });
  } catch (err) {
    if (err.number === 50501 || err.number === 50502) {
      return res.status(400).json({ message: err.message });
    }
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 4. DETALLE DE CABECERA Y RESUMEN DE PLANILLA
// -----------------------------------------------------------------------------
payrollRouter.get("/runs/:id", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await pool.request()
      .input("IncludeClosed", sql.Bit, 1)
      .query(PAYROLL_RUNS_SQL);

    const run = result.recordset.find((r) => r.id === req.params.id);
    if (!run) return res.status(404).json({ message: "La planilla solicitada no existe." });

    // Cargar validaciones pendientes
    const valRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .query(`
        SELECT ValidationId AS id, Severity AS severity, RuleCode AS ruleCode,
               Message AS message, TargetTab AS targetTab, IsResolved AS isResolved
        FROM dbo.PayrollValidations
        WHERE PayrollRunId = @PayrollRunId
        ORDER BY CASE WHEN Severity = 'bloqueante' THEN 1 WHEN Severity = 'advertencia' THEN 2 ELSE 3 END;
      `);

    res.json({ run, validations: valRes.recordset });
  } catch (err) {
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 5. CALCULAR PLANILLA (MOTOR DE CÁLCULO NICARAGUA)
// -----------------------------------------------------------------------------
const calculateSchema = z.object({
  expectedRevision: z.string().regex(/^0x[0-9a-f]{16}$/i)
});

payrollRouter.post("/runs/:id/calculate", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const { expectedRevision } = calculateSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });
    if (!await requireAccrualIntegrity(pool,res)) return;

    const revBuffer = Buffer.from(expectedRevision.slice(2), "hex");
    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .input("ExpectedRevision", sql.VarBinary(8), revBuffer)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name)
      .execute("dbo.usp_CalculatePayroll");

    res.json({
      message: "Cálculo guardado con las reglas configuradas para el período. Revisa los resultados y sus validaciones antes de aprobar.",
      run: result.recordset[0]
    });
  } catch (err) {
    if ([50503, 50504, 50505, 50596, 50620].includes(err.number)) {
      return res.status(400).json({ message: err.message });
    }
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 6. TRANSICIÓN DE ESTADOS (FLUJO DE 7 ETAPAS)
// -----------------------------------------------------------------------------
const transitionSchema = z.object({
  targetStatus: z.enum(["borrador", "calculada", "revisada", "aprobada", "pago_registrado", "conciliada", "cerrada"]),
  notes: z.string().max(1000).optional(),
  expectedRevision: z.string().regex(/^0x[0-9a-f]{16}$/i)
});

payrollRouter.post("/runs/:id/transition", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const data = transitionSchema.parse(req.body);
    if (requiresPayrollFinancialPermission(data.targetStatus) && !canManagePayrollMoney(req.user)) {
      return res.status(403).json({ message: "Aprobar, registrar pago, conciliar o cerrar requiere administración de Finanzas o Contabilidad." });
    }
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });
    if (!await requireAccrualIntegrity(pool,res)) return;

    const revBuffer = Buffer.from(data.expectedRevision.slice(2), "hex");
    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .input("ExpectedRevision", sql.VarBinary(8), revBuffer)
      .input("TargetStatus", sql.NVarChar(30), data.targetStatus)
      .input("Notes", sql.NVarChar(1000), data.notes ?? null)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name)
      .execute("dbo.usp_TransitionPayrollStatus");

    res.json({
      message: `La planilla ha transitado exitosamente al estado '${data.targetStatus}'.`,
      run: result.recordset[0]
    });
  } catch (err) {
    if (err.number === 50621 || (err.number >= 50506 && err.number <= 50516) || (err.number >= 50593 && err.number <= 50597)) {
      return res.status(400).json({ code: "PAYROLL_FLOW", message: err.message });
    }
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 7. LISTA DE TRABAJADORES EN LA PLANILLA
// -----------------------------------------------------------------------------
payrollRouter.get("/runs/:id/items", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_GetPayrollRunItems");

    res.json({ items: result.recordset });
  } catch (err) {
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 8. COMPROBANTE DE PAGO (COLILLA) INDIVIDUAL
// -----------------------------------------------------------------------------
payrollRouter.get("/runs/:id/receipts/:employeeId", requireAuth, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .input("EmployeeId", sql.NVarChar(100), req.params.employeeId)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_GetPayrollEmployeeReceipt");

    if (result.recordset.length === 0) {
      return res.status(404).json({ message: "No se encontró el comprobante para este colaborador en el período indicado." });
    }

    res.json({ receipt: result.recordset[0] });
  } catch (err) {
    if (err.number === 50517) {
      return res.status(403).json({ message: err.message });
    }
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 9. AUTOSERVICIO DEL TRABAJADOR: MIS COMPROBANTES DE PAGO
// -----------------------------------------------------------------------------
payrollRouter.get("/my-receipts", requireAuth, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const empRes = await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_GetHrMyEmployee");

    const employee = empRes.recordset[0];
    if (!employee) {
      return res.json({ receipts: [] });
    }

    const receiptsRes = await pool.request()
      .input("EmployeeId", sql.NVarChar(100), employee.id)
      .query(`
        SELECT r.PayrollRunId AS runId, r.Period AS period, r.StartDate AS startDate,
               r.EndDate AS endDate, r.PaymentDate AS paymentDate, r.Status AS runStatus,
               i.Gross AS grossTotal, i.InssLaboral AS inssLaboral, i.IncomeTax AS incomeTax,
               i.TotalDeductions AS totalDeductions, i.Net AS netPay,
               i.PaymentStatus AS paymentStatus, i.PaymentConfirmedAt AS paymentConfirmedAt,
               i.ReceiptStatus AS receiptStatus
        FROM dbo.PayrollRunItems i
        JOIN dbo.PayrollRuns r ON r.PayrollRunId = i.PayrollRunId
        WHERE i.EmployeeId = @EmployeeId AND r.Status IN ('aprobada', 'pago_registrado', 'conciliada', 'cerrada')
        ORDER BY r.StartDate DESC;
      `);

    res.json({ receipts: receiptsRes.recordset });
  } catch (err) {
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 10. NOVEDADES: GESTIÓN DE HORAS EXTRA, BONOS, VACACIONES Y DESCUENTOS
// -----------------------------------------------------------------------------
const noveltySchema = z.object({
  id: z.string().optional(),
  payrollRunId: z.string().nullable().optional(),
  employeeId: z.string().min(1),
  noveltyType: z.enum(["horas_extra", "bono", "comision", "vacaciones", "permiso_sin_sueldo", "subsidio_inss", "ajuste_retroactivo", "deduccion_prestamo", "otro"]),
  concept: z.string().min(3).max(240),
  amount: z.number().positive(),
  hours: z.number().nonnegative().optional(),
  legalJustification: z.string().max(500).optional(),
  docReference: z.string().max(300).optional(),
  periodDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/)
});

payrollRouter.get("/novelties", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const runId = req.query.runId ? String(req.query.runId) : null;
    let query = `
      SELECT n.NoveltyId AS id, n.PayrollRunId AS payrollRunId, n.EmployeeId AS employeeId,
             e.Name AS employeeName, n.NoveltyType AS noveltyType, n.Concept AS concept,
             n.Amount AS amount, n.Hours AS hours, n.LegalJustification AS legalJustification,
             n.DocReference AS docReference, n.PeriodDate AS periodDate, n.Status AS status,
             n.CreatedAt AS createdAt
      FROM dbo.PayrollNovelties n
      JOIN dbo.Employees e ON e.EmployeeId = n.EmployeeId
    `;
    if (runId) {
      query += ` WHERE n.PayrollRunId = @RunId ORDER BY n.PeriodDate DESC`;
    } else {
      query += ` ORDER BY n.PeriodDate DESC`;
    }

    const reqSql = pool.request();
    if (runId) reqSql.input("RunId", sql.NVarChar(100), runId);
    const result = await reqSql.query(query);

    res.json({ novelties: result.recordset });
  } catch (err) {
    next(err);
  }
});

payrollRouter.post("/novelties", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const data = noveltySchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const noveltyId = data.id || `nov-${Date.now().toString(36)}-${randomUUID().slice(0, 4)}`;

    const result = await pool.request()
      .input("NoveltyId", sql.NVarChar(100), noveltyId)
      .input("PayrollRunId", sql.NVarChar(100), data.payrollRunId ?? null)
      .input("EmployeeId", sql.NVarChar(100), data.employeeId)
      .input("NoveltyType", sql.NVarChar(40), data.noveltyType)
      .input("Concept", sql.NVarChar(240), data.concept)
      .input("Amount", sql.Decimal(19, 4), data.amount)
      .input("Hours", sql.Decimal(9, 2), data.hours ?? null)
      .input("LegalJustification", sql.NVarChar(500), data.legalJustification ?? null)
      .input("DocReference", sql.NVarChar(300), data.docReference ?? null)
      .input("PeriodDate", sql.Date, data.periodDate)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_UpsertPayrollNovelty");

    res.status(201).json({
      message: "Novedad registrada exitosamente.",
      novelty: result.recordset[0]
    });
  } catch (err) {
    if (err.number === 50518) return res.status(400).json({ message: err.message });
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 11. OBLIGACIONES INSTITUCIONALES (DGI, INSS, INATEC, PROVISIONES)
// -----------------------------------------------------------------------------
payrollRouter.get(["/obligations/:runId", "/obligaciones/:runId"], requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.runId)
      .query(`
        SELECT ObligationId AS id, EntityName AS entity, PeriodLabel AS period,
               BaseAmount AS baseAmount, PayableAmount AS payableAmount,
               DueDate AS dueDate, Status AS status, DeclarationReference AS declarationRef,
               PaymentReceiptRef AS receiptRef, PaidAt AS paidAt,
               CONVERT(VARCHAR(20),CONVERT(VARBINARY(8),Revision),1) AS revision
        FROM dbo.PayrollInstitutionalObligations
        WHERE PayrollRunId = @PayrollRunId
        ORDER BY DueDate ASC;
      `);

    res.json({ obligations: result.recordset });
  } catch (err) {
    next(err);
  }
});

// -----------------------------------------------------------------------------
// El vencimiento procede de un documento/calendario verificado, no de sumar dias al guardar.
const obligationDueDateSchema = z.object({
  dueDate: z.string().date(),
  source: z.string().trim().min(5).max(300),
  expectedRevision: z.string().regex(/^0x[0-9a-f]{16}$/i)
});
payrollRouter.patch("/obligations/:id/due-date", requireAuth, requirePayrollManagement, requirePayrollPayment, async (req, res, next) => {
  try {
    const data=obligationDueDateSchema.parse(req.body);
    const pool=await getDatabase();
    if(!pool) return res.status(503).json({message:"SQL Server no está disponible."});
    const result=await pool.request().input("Id",sql.NVarChar(100),req.params.id)
      .input("DueDate",sql.Date,data.dueDate).input("Source",sql.NVarChar(300),data.source)
      .input("Revision",sql.VarBinary(8),Buffer.from(data.expectedRevision.slice(2),"hex"))
      .input("Actor",sql.NVarChar(100),req.user.id).input("ActorName",sql.NVarChar(240),req.user.name)
      .query(`SET XACT_ABORT ON; BEGIN TRY BEGIN TRANSACTION;
        DECLARE @Run NVARCHAR(100),@Status NVARCHAR(30),@Current VARBINARY(8);
        SELECT @Run=PayrollRunId,@Status=Status,@Current=Revision FROM dbo.PayrollInstitutionalObligations WITH(UPDLOCK,HOLDLOCK) WHERE ObligationId=@Id;
        IF @Run IS NULL THROW 50622,'La obligacion no existe.',1;
        IF @Current<>@Revision THROW 50623,'La obligacion cambio. Actualiza antes de guardar.',1;
        IF @Status=N'pagada' THROW 50622,'La obligacion pagada requiere revision documentada; no se cambia su vencimiento directamente.',1;
        UPDATE dbo.PayrollInstitutionalObligations SET DueDate=@DueDate,
          Status=CASE WHEN Status=N'pendiente_vencimiento' THEN N'pendiente' ELSE Status END WHERE ObligationId=@Id;
        INSERT dbo.PayrollHistoryEvents(PayrollRunId,ActorId,ActorName,EventType,Description)
        VALUES(@Run,@Actor,@ActorName,N'vencimiento',N'Obligacion '+@Id+N'; fecha '+CONVERT(NVARCHAR(10),@DueDate,23)+N'; fuente: '+@Source);
        COMMIT; SELECT N'guardado' AS result;
      END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;`);
    res.json({message:"Vencimiento registrado con su fuente y responsable.",result:result.recordset[0]});
  }catch(error){
    if(error instanceof z.ZodError) return res.status(400).json({message:"Indica una fecha real, su fuente y la revisión actual.",issues:error.issues});
    if([50622,50623].includes(error.number)) return res.status(error.number===50623?409:400).json({message:error.message});
    next(error);
  }
});

// 12. REPORTES Y AGREGACIONES DE NÓMINA
// -----------------------------------------------------------------------------
payrollRouter.get("/reports", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const type = req.query.type ? String(req.query.type) : "resumen_periodo";
    const runId = req.query.runId ? String(req.query.runId) : null;

    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await pool.request()
      .input("ReportType", sql.NVarChar(50), type)
      .input("PayrollRunId", sql.NVarChar(100), runId)
      .execute("dbo.usp_GetPayrollReports");

    res.json({ reportType: type, data: result.recordset });
  } catch (err) {
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 13. ATENCIÓN AL TRABAJADOR: CREAR TICKET DE REVISIÓN DE COMPROBANTE
// -----------------------------------------------------------------------------
const ticketSchema = z.object({
  payrollRunId: z.string().min(1),
  employeeId: z.string().min(1),
  subject: z.string().min(4).max(200),
  description: z.string().min(10).max(1000)
});

payrollRouter.post("/receipt-tickets", requireAuth, async (req, res, next) => {
  try {
    const data = ticketSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const ticketId = `tck-${Date.now().toString(36)}-${randomUUID().slice(0, 4)}`;

    const result = await pool.request()
      .input("TicketId", sql.NVarChar(100), ticketId)
      .input("PayrollRunId", sql.NVarChar(100), data.payrollRunId)
      .input("EmployeeId", sql.NVarChar(100), data.employeeId)
      .input("Subject", sql.NVarChar(200), data.subject)
      .input("Description", sql.NVarChar(1000), data.description)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_CreatePayrollReceiptTicket");

    res.status(201).json({
      message: "Tu solicitud de revisión ha sido recibida y asignada al equipo de Talento Humano.",
      ticket: result.recordset[0]
    });
  } catch (err) {
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 14. INCLUIR Y RETIRAR TRABAJADORES EN PLANILLA (EN ESTADO BORRADOR)
// -----------------------------------------------------------------------------
const addWorkerSchema = z.object({
  employeeId: z.string().min(1),
  reason: z.string().max(500).optional().nullable()
});

payrollRouter.post("/runs/:id/workers", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const data = addWorkerSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .input("EmployeeId", sql.NVarChar(100), data.employeeId)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name || req.user.username || "Usuario")
      .input("Reason", sql.NVarChar(500), data.reason || null)
      .execute("dbo.usp_AddWorkerToPayrollRun");

    res.status(201).json({
      message: "Colaborador agregado a la planilla con éxito.",
      worker: result.recordset[0]
    });
  } catch (err) {
    if (err.number === 50520 || err.number === 50521 || err.number === 50522 || err.number === 50523) {
      return res.status(400).json({ message: err.message });
    }
    next(err);
  }
});

payrollRouter.delete("/runs/:id/workers/:employeeId", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const reason = typeof req.query.reason === "string" ? req.query.reason : "Retiro administrativo de colaborador en borrador";

    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .input("EmployeeId", sql.NVarChar(100), req.params.employeeId)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name || req.user.username || "Usuario")
      .input("Reason", sql.NVarChar(500), reason)
      .execute("dbo.usp_RemoveWorkerFromPayrollRun");

    res.json({
      message: "Colaborador retirado de la planilla.",
      result: result.recordset[0]
    });
  } catch (err) {
    if (err.number === 50524 || err.number === 50525 || err.number === 50526) {
      return res.status(400).json({ message: err.message });
    }
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 15. CANCELAR / ELIMINAR NOVEDAD Y MARCAR CÁLCULO COMO DESACTUALIZADO
// -----------------------------------------------------------------------------
payrollRouter.delete("/novelties/:id", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const reason = typeof req.query.reason === "string" ? req.query.reason : "Cancelación de novedad";

    const result = await pool.request()
      .input("NoveltyId", sql.NVarChar(100), req.params.id)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name || req.user.username || "Usuario")
      .input("Reason", sql.NVarChar(500), reason)
      .execute("dbo.usp_DeletePayrollNovelty");

    res.json({
      message: "Novedad eliminada/cancelada y trazabilidad registrada.",
      result: result.recordset[0]
    });
  } catch (err) {
    if (err.number === 50527 || err.number === 50528) {
      return res.status(400).json({ message: err.message });
    }
    next(err);
  }
});

// -----------------------------------------------------------------------------
// 16. PAGOS: CONSULTA Y REGISTRO IDEMPOTENTE DE LA DISPERSIÓN
// -----------------------------------------------------------------------------
// Un pago es una operación financiera: se identifica con mutationId (idempotency
// key) generado por el cliente una sola vez por intento. Un doble clic o un
// reintento devuelve la MISMA operación y no crea un segundo egreso.
const registerPaymentSchema = z.object({
  mutationId: z.string().uuid(),
  amount: z.number().finite().positive().refine((value) => Math.abs(value * 100 - Math.round(value * 100)) < 0.000001, "Usa hasta dos decimales."),
  paymentMethod: z.enum(["efectivo", "caja", "transferencia", "transferencia_bancaria", "cheque", "tarjeta", "otro"]),
  paymentReference: z.string().min(1).max(120),
  paymentDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  employeeId: z.string().max(100).optional().nullable(),
  notes: z.string().max(1000).optional().nullable()
});

async function requirePaymentIntegrity(pool, res) {
  const check = await pool.request().query("SELECT CASE WHEN OBJECT_ID(N'dbo.usp_PayrollPaymentIntegrityVersion', N'P') IS NOT NULL AND OBJECT_ID(N'dbo.usp_SnapshotLinkIntegrityVersion', N'P') IS NOT NULL THEN 1 ELSE 0 END AS allocationTable");
  if (check.recordset[0]?.allocationTable) return true;
  res.status(503).json({ code: "PAYROLL_MIGRATION_REQUIRED", message: "Faltan las migraciones 30 y/o 32 para pagos seguros y conservación de sus enlaces. Los pagos quedan pausados hasta instalarlas." });
  return false;
}

// Comprobación de solo lectura; no crea recibos, movimientos ni asientos.
payrollRouter.post("/runs/:id/payment-check", requireAuth, requirePayrollManagement, requirePayrollPayment, async (req, res, next) => {
  try {
    const data = registerPaymentSchema.extend({ employeeId: z.string().min(1).max(100) }).parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });
    if (!await requirePaymentIntegrity(pool, res) || !await requireAccrualIntegrity(pool, res)) return;
    res.json(await checkPayrollPayment(pool, req.params.id, data));
  } catch (error) { next(error); }
});

payrollRouter.get("/runs/:id/payments", requireAuth, requirePayrollManagement, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });
    if (!await requirePaymentIntegrity(pool, res)) return;

    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .query(PAYROLL_PAYMENTS_SQL);

    const parseAllocations = (value) => {
      if (Array.isArray(value)) return value;
      if (!value) return [];
      if (typeof value === "string") return JSON.parse(value);
      return [];
    };

    const paid = result.recordset.reduce((total, row) => total + Number(row.amount ?? 0), 0);
    const runRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .query(`
        SELECT Net AS netTotal, ConfirmedPaymentsTotal AS confirmedPaymentsTotal, Status AS status
        FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId;
      `);
    const run = runRes.recordset[0] ?? {};

    res.json({
      payments: result.recordset.map(({ allocationsJson, ...payment }) => ({ ...payment, allocations: parseAllocations(allocationsJson) })),
      paidTotal: Math.round(paid * 100) / 100,
      pending: Math.round((Number(run.netTotal ?? 0) - paid) * 100) / 100,
      run
    });
  } catch (err) {
    next(err);
  }
});

payrollRouter.post("/runs/:id/payments", requireAuth, requirePayrollManagement, requirePayrollPayment, async (req, res, next) => {
  try {
    const data = registerPaymentSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });
    if (!await requirePaymentIntegrity(pool, res)) return;

    const result = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), req.params.id)
      .input("Amount", sql.Decimal(19, 4), data.amount)
      .input("PaymentMethod", sql.NVarChar(60), data.paymentMethod)
      .input("PaymentReference", sql.NVarChar(120), data.paymentReference)
      .input("PaymentDate", sql.Date, data.paymentDate)
      .input("Notes", sql.NVarChar(1000), data.notes || null)
      .input("IdempotencyKey", sql.UniqueIdentifier, data.mutationId)
      .input("EmployeeId", sql.NVarChar(100), data.employeeId || null)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name || req.user.username || "Usuario")
      .execute("dbo.usp_RegisterPayrollPayment");

    const row = result.recordset[0] ?? {};
    const repeated = row.Resultado === "repetida";

    res.status(repeated ? 200 : 201).json({
      repeated,
      message: repeated
        ? "El pago ya estaba registrado; se devuelve la misma operación sin crear un segundo egreso."
        : "Pago confirmado y registrado en caja/banco una sola vez.",
      payment: row
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ code: "INVALID_PAYMENT", message: "Datos del pago inválidos.", issues: err.issues });
    }
    if (err.number === 2601 || err.number === 2627) {
      return res.status(409).json({
        code: "DUPLICATE_PAYMENT",
        message: "La operación de pago ya fue registrada. Recarga la planilla antes de reintentar."
      });
    }
    if (err.number === 50602) return res.status(409).json({ code: "PAYMENT_KEY_CONFLICT", message: err.message });
    if ([50529, 50530, 50531, 50589, 50590, 50591, 50592, 50600, 50601, 50603, 50604, 50605, 50606, 50607, 50609].includes(err.number)) {
      return res.status(400).json({ code: "PAYROLL_PAYMENT", message: err.message });
    }
    next(err);
  }
});

