import { cashRequest } from "../services/cashTransaction.js";
import { CASH_LEDGER_CTE, CASH_MOVEMENTS_SQL, CASH_SUMMARY_SQL, CASH_SUGGESTED_OPENING_SQL } from "../services/cashLedgerSql.js";
import { Router } from "express";
import sql from "mssql";
import { z } from "zod";
import { getDatabase } from "../config/sqlserver.js";
import { requireAuth } from "../middleware/auth.js";

export const cashRouter = Router();

const ACCOUNTS = ["caja", "banco"];
const METHODS = ["efectivo", "transferencia", "tarjeta", "cheque", "otro"];
const DOCUMENT_TYPES = ["apertura", "venta", "cobro", "anticipo", "compra", "pago_proveedor", "nomina", "ajuste", "otro"];

// -----------------------------------------------------------------------------
// Permisos
// Lectura: superadmin, administrador de Finanzas/Contabilidad y usuario estándar
// de Finanzas. Escritura de movimientos: los mismos. Cierre de caja, revisión del
// arqueo y anulación: solo superadmin o administrador (segregación de funciones).
// -----------------------------------------------------------------------------
function financeAreas(req) {
  const areas = req.user?.areas ?? [];
  return areas.includes("finanzas") || areas.includes("contabilidad");
}

function requireCashRead(req, res, next) {
  if (!req.user) return res.status(401).json({ message: "Autenticación requerida." });
  if (req.user.hierarchy === "superadmin") return next();
  if (req.user.hierarchy === "administrador" && financeAreas(req)) return next();
  if (req.user.hierarchy === "estandar" && req.user.areas?.includes("finanzas")) return next();
  return res.status(403).json({
    message: "Acceso denegado: la consulta de caja requiere pertenecer a Finanzas o Contabilidad."
  });
}

function requireCashWrite(req, res, next) {
  if (!req.user) return res.status(401).json({ message: "Autenticación requerida." });
  if (req.user.mustChangePassword) {
    return res.status(403).json({ message: "Debes cambiar la contraseña temporal antes de continuar." });
  }
  if (req.user.hierarchy === "superadmin") return next();
  if (req.user.hierarchy === "administrador" && financeAreas(req)) return next();
  if (req.user.hierarchy === "estandar" && req.user.areas?.includes("finanzas")) return next();
  return res.status(403).json({
    message: "Acceso denegado: registrar movimientos de caja requiere pertenecer a Finanzas."
  });
}

function requireCashSupervision(req, res, next) {
  if (!req.user) return res.status(401).json({ message: "Autenticación requerida." });
  if (req.user.mustChangePassword) return res.status(403).json({ message: "Debes cambiar la contraseña temporal antes de continuar." });
  if (req.user.hierarchy === "superadmin") return next();
  if (req.user.hierarchy === "administrador" && financeAreas(req)) return next();
  return res.status(403).json({
    message: "Operación restringida: el cierre, la revisión del arqueo y la anulación requieren un administrador de Finanzas."
  });
}

// Los códigos 50560-50588 son reglas de negocio de la migración 26.
const CASH_RULE_ERRORS = new Set([
  50560, 50561, 50562, 50563, 50564, 50565, 50566, 50567, 50568, 50569, 50570,
  50571, 50572, 50573, 50574, 50575, 50576, 50577, 50578, 50579, 50580, 50581,
  50582, 50583, 50584, 50585, 50586, 50587, 50588
]);

function handleCashError(err, res, next) {
  if (["ETIMEOUT", "ESOCKET", "ECONNCLOSED", "ENOCONN"].includes(err?.code)) {
    return res.status(503).json({ code: "CASH_CONFIRMATION_UNAVAILABLE", message: "SQL Server no confirmó la respuesta a tiempo. Conserva los datos y la clave de esta operación; actualiza el libro y reintenta la misma operación para evitar duplicados." });
  }
  if ([50609, 50610, 50611, 50612].includes(err?.number)) return res.status(err.number === 50611 ? 409 : 400).json({ code: "CASH_INTEGRITY", message: err.message });
  if (err?.number === 50608) return res.status(409).json({ code: "PAYROLL_REVERSAL_REQUIRED", message: err.message });
  if (err?.number === 2601 || err?.number === 2627) {
    return res.status(409).json({
      code: "DUPLICATE_OPERATION",
      message: "La operación ya fue registrada. Revisa el movimiento existente antes de reintentar."
    });
  }
  if (CASH_RULE_ERRORS.has(err?.number)) {
    return res.status(400).json({ code: "CASH_RULE", message: err.message });
  }
  return next(err);
}

function toNumber(value) {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

function round2(value) {
  return Math.round(toNumber(value) * 100) / 100;
}

const isoDate = z.string().date();
const isoTime = z.string().regex(/^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/);
const money = z.number().finite().refine((value) => Math.abs(value * 100 - Math.round(value * 100)) < 0.000001, "Usa hasta dos decimales.");

const movementQuerySchema = z.object({
  account: z.enum(ACCOUNTS).optional(),
  from: isoDate.optional(),
  to: isoDate.optional(),
  limit: z.coerce.number().int().min(1).max(2000).optional()
}).refine((query) => !query.from || !query.to || query.from <= query.to, "El inicio no puede ser posterior al final.");

// -----------------------------------------------------------------------------
// 1. Movimientos con saldo acumulado y saldo anterior al período
// -----------------------------------------------------------------------------
cashRouter.get("/movements", requireAuth, requireCashRead, async (req, res, next) => {
  try {
    const query = movementQuerySchema.parse(req.query);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const request = pool.request()
      .input("Account", sql.NVarChar(30), query.account ?? null)
      .input("FromDate", sql.Date, query.from ?? null)
      .input("ToDate", sql.Date, query.to ?? null)
      .input("Limit", sql.Int, query.limit ?? 500);

    const movements = await request.query(CASH_MOVEMENTS_SQL);

    // Saldo inmediatamente anterior al inicio del período solicitado.
    let openingBalance = 0;
    if (query.from) {
      const opening = await pool.request()
        .input("Account", sql.NVarChar(30), query.account ?? null)
        .input("FromDate", sql.Date, query.from)
        .query(`
          ${CASH_LEDGER_CTE}, Previous AS (
            SELECT v.Account, v.SaldoAcumulado, ROW_NUMBER() OVER (
              PARTITION BY v.Account ORDER BY v.LedgerOrder DESC
            ) AS rn
            FROM CashLedger v
            WHERE (@Account IS NULL OR v.Account=@Account) AND CONVERT(DATE, v.MoveDate)<@FromDate
          ) SELECT Account, SaldoAcumulado FROM Previous WHERE rn=1;
        `);
      openingBalance = opening.recordset.reduce((total, row) => total + toNumber(row.SaldoAcumulado), 0);
    }

    res.json({
      movements: movements.recordset,
      account: query.account ?? null,
      from: query.from ?? null,
      to: query.to ?? null,
      openingBalance: round2(openingBalance)
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ message: "Parámetros de consulta de caja inválidos.", issues: error.issues });
    }
    next(error);
  }
});

// -----------------------------------------------------------------------------
// 2. Resumen del período: saldo inicial, entradas, salidas y saldo final
// -----------------------------------------------------------------------------
cashRouter.get("/summary", requireAuth, requireCashRead, async (req, res, next) => {
  try {
    const query = movementQuerySchema.parse(req.query);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await pool.request()
      .input("Account", sql.NVarChar(30), query.account ?? null)
      .input("FromDate", sql.Date, query.from ?? null)
      .input("ToDate", sql.Date, query.to ?? null)
      .query(CASH_SUMMARY_SQL);
    const row = result.recordset[0] ?? {};
    const previous = round2(row.saldoAnterior);
    // Una reapertura reemplaza la base: solo su diferencia ajusta el saldo.
    const aperturas = round2(row.aperturas);
    const entradas = round2(row.entradas);
    const salidas = round2(row.salidas);
    const saldoInicial = round2(previous + aperturas);

    res.json({
      account: query.account ?? null,
      from: query.from ?? null,
      to: query.to ?? null,
      saldoAnterior: previous,
      aperturas,
      saldoInicial,
      entradas,
      salidas,
      saldoFinal: round2(saldoInicial + entradas - salidas),
      movimientos: toNumber(row.movimientos)
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ message: "Parámetros de resumen de caja inválidos.", issues: error.issues });
    }
    next(error);
  }
});

// -----------------------------------------------------------------------------
// 3. Sesiones de caja: apertura, arqueo, cierre y revisión
// -----------------------------------------------------------------------------
cashRouter.get("/sessions", requireAuth, requireCashRead, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const account = ACCOUNTS.includes(String(req.query.account)) ? String(req.query.account) : null;
    const result = await pool.request()
      .input("Account", sql.NVarChar(30), account)
      .query(`
        SELECT s.CashSessionId AS id,
               s.Account AS account,
               s.Currency AS currency,
               s.SessionDate AS sessionDate,
               s.OpeningBalance AS openingBalance,
               s.Status AS status,
               s.OpenedAt AS openedAt,
               s.OpenedByName AS openedByName,
               s.ClosedAt AS closedAt,
               s.CountedCash AS countedCash,
               s.ExpectedCash AS expectedCash,
               s.Difference AS difference,
               s.Explanation AS explanation,
               s.ReviewStatus AS reviewStatus,
               s.ReviewedByName AS reviewedByName,
               s.ReviewedAt AS reviewedAt,
               s.Movimientos AS movements
        FROM dbo.vw_EstadoSesionesCaja AS s
        WHERE (@Account IS NULL OR s.Account = @Account)
        ORDER BY s.OpenedAt DESC;
        SELECT CONVERT(VARCHAR(10),SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time',23) AS businessDate;
      `);

    // Arrastre sugerido: saldo final de la ultima sesion cerrada (o saldo vivo de
    // la sesion abierta) de la cuenta. Solo se propone para precargar la apertura;
    // el responsable lo confirma o ajusta con su conteo real.
    const suggested = await pool.request()
      .input("Account", sql.NVarChar(30), account)
      .query(CASH_SUGGESTED_OPENING_SQL);

    const suggestion = account
      ? (suggested.recordset.find((row) => row.account === account) ?? null)
      : null;

    res.json({
      sessions: result.recordset,
      businessDate: result.recordsets[1][0].businessDate,
      suggestedOpening: suggestion
        ? {
            account: suggestion.account,
            amount: round2(suggestion.suggestedOpening),
            origin: suggestion.origin,
            sourceSessionId: suggestion.sourceSessionId ?? null,
            closedAt: suggestion.closedAt ?? null
          }
        : null
    });
  } catch (error) {
    next(error);
  }
});

const openSessionSchema = z.object({
  operationKey: z.string().min(8).max(160),
  account: z.enum(ACCOUNTS),
  currency: z.enum(["C$", "NIO"]).default("C$"),
  initialBalance: money.refine((value) => value >= 0),
  sessionDate: isoDate.optional(),
  notes: z.string().max(1000).optional().nullable()
});

cashRouter.post("/sessions", requireAuth, requireCashWrite, async (req, res, next) => {
  try {
    const data = openSessionSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await cashRequest(pool)
      .input("Account", sql.NVarChar(30), data.account)
      .input("Currency", sql.NVarChar(10), data.currency)
      .input("InitialBalance", sql.Decimal(19, 4), data.initialBalance)
      .input("SessionDate", sql.Date, data.sessionDate ?? null)
      .input("Notes", sql.NVarChar(1000), data.notes ?? null)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name ?? req.user.email ?? "Usuario")
      .input("OperationKey", sql.NVarChar(160), data.operationKey)
      .execute("dbo.usp_AbrirCaja");

    const row = result.recordset[0] ?? {};
    res.status(row.Resultado === "repetida" ? 200 : 201).json({
      repeated: row.Resultado === "repetida",
      message: row.Resultado === "repetida" ? "La apertura ya estaba registrada." : "Caja abierta con saldo inicial identificado.",
      session: row
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ message: "Datos de apertura inválidos.", issues: error.issues });
    }
    handleCashError(error, res, next);
  }
});

const closeSessionSchema = z.object({
  countedCash: money.refine((value) => value >= 0),
  explanation: z.string().max(1000).optional().nullable()
});

cashRouter.post("/sessions/:id/close", requireAuth, requireCashSupervision, async (req, res, next) => {
  try {
    const data = closeSessionSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await cashRequest(pool)
      .input("SessionId", sql.NVarChar(100), req.params.id)
      .input("CountedCash", sql.Decimal(19, 4), data.countedCash)
      .input("Explanation", sql.NVarChar(1000), data.explanation ?? null)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name ?? req.user.email ?? "Usuario")
      .execute("dbo.usp_ArquearYCerrarCaja");

    const row = result.recordset[0] ?? {};
    res.json({
      message: toNumber(row.Difference) === 0
        ? "Arqueo cerrado sin diferencia."
        : "Arqueo cerrado con diferencia: queda pendiente de revisión por otra persona.",
      session: row
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ message: "Datos de arqueo inválidos.", issues: error.issues });
    }
    handleCashError(error, res, next);
  }
});

const reviewSessionSchema = z.object({
  decision: z.enum(["revisado", "observado"]),
  notes: z.string().max(1000).optional().nullable()
});

cashRouter.post("/sessions/:id/review", requireAuth, requireCashSupervision, async (req, res, next) => {
  try {
    const data = reviewSessionSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await cashRequest(pool)
      .input("SessionId", sql.NVarChar(100), req.params.id)
      .input("Decision", sql.NVarChar(30), data.decision)
      .input("Notes", sql.NVarChar(1000), data.notes ?? null)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name ?? req.user.email ?? "Usuario")
      .execute("dbo.usp_RevisionArqueo");

    res.json({ message: "Revisión del arqueo registrada.", session: result.recordset[0] ?? {} });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ message: "Datos de revisión inválidos.", issues: error.issues });
    }
    handleCashError(error, res, next);
  }
});

// -----------------------------------------------------------------------------
// 4. Movimientos: registrar y anular (nunca borrar)
// -----------------------------------------------------------------------------
const registerMovementSchema = z.object({
  operationKey: z.string().min(8).max(160),
  account: z.enum(ACCOUNTS).optional(),
  type: z.enum(["entrada", "salida"]),
  amount: money.refine((value) => value > 0),
  concept: z.string().min(3).max(300),
  method: z.enum(METHODS).default("efectivo"),
  documentType: z.enum(DOCUMENT_TYPES).optional().nullable(),
  documentRef: z.string().max(120).optional().nullable(),
  date: isoDate.optional(),
  time: isoTime.optional(),
  sessionId: z.string().max(100).optional().nullable(),
  notes: z.string().max(1000).optional().nullable()
});

function accountForMethod(method) {
  return method === "efectivo" ? "caja" : "banco";
}

cashRouter.post("/movements", requireAuth, requireCashWrite, async (req, res, next) => {
  try {
    const data = registerMovementSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    // El medio de pago determina el efecto: efectivo -> caja, resto -> banco.
    const account = accountForMethod(data.method);
    if (data.account && data.account !== account) {
      return res.status(400).json({
        code: "PAYMENT_METHOD_ACCOUNT_MISMATCH",
        message: `El medio ${data.method} afecta ${account === "caja" ? "la caja de efectivo" : "la cuenta bancaria"}. Registra el movimiento en ${account}.`
      });
    }

    // La clave de operación la genera el cliente una sola vez por intento; un
    // doble clic o un reintento reutiliza la misma clave y devuelve el mismo
    // movimiento (idempotencia real en SQL Server).
    const operationKey = data.operationKey;

    const result = await cashRequest(pool)
      .input("Account", sql.NVarChar(30), account)
      .input("MoveType", sql.NVarChar(10), data.type)
      .input("Amount", sql.Decimal(19, 4), data.amount)
      .input("Concept", sql.NVarChar(300), data.concept)
      .input("Method", sql.NVarChar(30), data.method)
      .input("DocumentType", sql.NVarChar(40), data.documentType ?? "ajuste")
      .input("DocumentRef", sql.NVarChar(120), data.documentRef ?? null)
      .input("MoveDate", sql.Date, data.date ?? null)
      .input("MoveTime", sql.NVarChar(8), data.time ?? null)
      .input("SessionId", sql.NVarChar(100), data.sessionId ?? null)
      .input("Notes", sql.NVarChar(1000), data.notes ?? null)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name ?? req.user.email ?? "Usuario")
      .input("OperationKey", sql.NVarChar(160), operationKey)
      .execute("dbo.usp_RegistrarMovimientoCaja");

    const row = result.recordset[0] ?? {};
    const repeated = row.Resultado === "repetida";
    res.status(repeated ? 200 : 201).json({
      repeated,
      message: repeated ? "El movimiento ya estaba registrado; se devuelve la misma operación." : "Movimiento de caja registrado.",
      operationKey,
      movement: row
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ message: "Datos del movimiento inválidos.", issues: error.issues });
    }
    handleCashError(error, res, next);
  }
});

const voidMovementSchema = z.object({
  reason: z.string().min(5).max(1000)
});

cashRouter.post("/movements/:id/void", requireAuth, requireCashSupervision, async (req, res, next) => {
  try {
    const data = voidMovementSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está disponible." });

    const result = await cashRequest(pool)
      .input("CashMoveId", sql.NVarChar(100), req.params.id)
      .input("Reason", sql.NVarChar(1000), data.reason)
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name ?? req.user.email ?? "Usuario")
      .execute("dbo.usp_AnularMovimientoCaja");

    res.json({ message: "Movimiento anulado con trazabilidad (la fila se conserva).", movement: result.recordset[0] ?? {} });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ message: "La anulación requiere un motivo de al menos 5 caracteres.", issues: error.issues });
    }
    handleCashError(error, res, next);
  }
});
