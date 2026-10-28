import { Router } from "express";
import sql from "mssql";
import { z } from "zod";
import { getDatabase } from "../config/sqlserver.js";
import { permit, requireAuth } from "../middleware/auth.js";

export const suppliersRouter = Router();
suppliersRouter.use(requireAuth);

const supplierSchema = z.object({
  name: z.string().trim().min(1, "El nombre del proveedor es obligatorio.").max(240),
  category: z.enum(["materiales", "servicios", "transporte", "herramientas", "otro"]),
  contact: z.string().trim().max(200).default(""),
  phone: z.string().trim().max(80).default(""),
  email: z.union([z.string().trim().email().max(320), z.literal("")]).default(""),
  address: z.string().trim().max(500).default(""),
  productsServices: z.string().trim().max(1000).default(""),
  ruc: z.string().trim().max(40).default(""),
  paymentTerms: z.string().trim().max(80).default(""),
  observations: z.string().trim().max(2000).default(""),
  status: z.enum(["activo", "pendiente", "inactivo"]),
  nextReviewDate: z.union([
    z.string().regex(/^\d{4}-\d{2}-\d{2}$/).refine((value) => {
      const date = new Date(`${value}T00:00:00.000Z`);
      return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
    }),
    z.literal("")
  ]).default(""),
  mutationId: z.string().trim().min(1).max(100),
  action: z.enum(["alta proveedor", "actualizar proveedor"]),
  detail: z.string().trim().min(1).max(2000)
}).superRefine((supplier, context) => {
  if (!supplier.phone && !supplier.email) {
    context.addIssue({
      code: z.ZodIssueCode.custom,
      path: ["phone"],
      message: "Indica un teléfono o un correo electrónico."
    });
  }
});

suppliersRouter.put("/:id", permit("proveedores", "write"), async (req, res, next) => {
  let transaction;
  let transactionStarted = false;
  try {
    const partyId = z.string().trim().min(1).max(100).parse(req.params.id);
    const supplier = supplierSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });

    transaction = new sql.Transaction(pool);
    await transaction.begin(sql.ISOLATION_LEVEL.SERIALIZABLE);
    transactionStarted = true;
    const stateResult = await new sql.Request(transaction).query(`
      SELECT Payload
      FROM dbo.ErpState WITH (UPDLOCK, HOLDLOCK)
      WHERE StateId = 1
    `);
    const payload = stateResult.recordset[0]?.Payload;
    if (!payload) throw new Error("No existe el estado principal del ERP en SQL Server.");

    const result = await new sql.Request(transaction)
      .input("PartyId", sql.NVarChar(100), partyId)
      .input("Name", sql.NVarChar(240), supplier.name)
      .input("Category", sql.NVarChar(30), supplier.category)
      .input("Contact", sql.NVarChar(200), supplier.contact)
      .input("Phone", sql.NVarChar(80), supplier.phone)
      .input("Email", sql.NVarChar(320), supplier.email || null)
      .input("Address", sql.NVarChar(500), supplier.address || null)
      .input("ProductsServices", sql.NVarChar(1000), supplier.productsServices || null)
      .input("Ruc", sql.NVarChar(40), supplier.ruc || null)
      .input("PaymentTerms", sql.NVarChar(80), supplier.paymentTerms || null)
      .input("Observations", sql.NVarChar(2000), supplier.observations || null)
      .input("Status", sql.NVarChar(20), supplier.status)
      .input("NextReviewDate", sql.Date, supplier.nextReviewDate || null)
      .input("Actor", sql.NVarChar(200), req.user.name)
      .input("AuditEventId", sql.NVarChar(100), supplier.mutationId)
      .input("AuditAction", sql.NVarChar(120), supplier.action)
      .input("AuditDetail", sql.NVarChar(2000), supplier.detail)
      .execute("dbo.usp_UpsertSupplier");

    const savedSupplier = result.recordset[0];
    const state = JSON.parse(payload);
    const party = {
      ...savedSupplier,
      type: "proveedor",
      email: savedSupplier.email ?? "",
      address: savedSupplier.address ?? "",
      productsServices: savedSupplier.productsServices ?? "",
      ruc: savedSupplier.ruc ?? "",
      paymentTerms: savedSupplier.paymentTerms ?? "",
      observations: savedSupplier.observations ?? "",
      nextReviewDate: savedSupplier.nextReviewDate instanceof Date
        ? savedSupplier.nextReviewDate.toISOString().slice(0, 10)
        : savedSupplier.nextReviewDate
    };
    const auditEvent = {
      id: supplier.mutationId,
      at: new Date().toISOString(),
      userName: req.user.name,
      action: supplier.action,
      module: "proveedores",
      detail: supplier.detail,
      severity: "info",
      reference: partyId
    };
    const parties = Array.isArray(state.parties) ? state.parties : [];
    state.parties = [...parties.filter((item) => item.id !== partyId), party];
    const audit = Array.isArray(state.audit) ? state.audit : [];
    state.audit = [
      auditEvent,
      ...audit.filter((item) => item.id !== supplier.mutationId)
    ].slice(0, 200);

    await new sql.Request(transaction)
      .input("payload", sql.NVarChar(sql.MAX), JSON.stringify(state))
      .query(`
        UPDATE dbo.ErpState
        SET Payload = @payload, UpdatedAt = SYSUTCDATETIME()
        WHERE StateId = 1
      `);
    const revisionResult = await new sql.Request(transaction).query(`
      SELECT CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), Revision), 1) AS revision
      FROM dbo.ErpState WHERE StateId = 1
    `);
    await transaction.commit();
    transactionStarted = false;
    res.json({
      saved: true,
      supplier: party,
      auditEvent,
      revision: revisionResult.recordset[0]?.revision ?? null
    });
  } catch (error) {
    if (transaction && transactionStarted) {
      await transaction.rollback();
    }
    if (error.number === 2601 || error.number === 2627) {
      return res.status(409).json({ message: "Ya existe un proveedor con ese nombre o identificación fiscal." });
    }
    next(error);
  }
});
