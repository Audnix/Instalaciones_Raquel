import { Router } from "express";
import { randomUUID } from "node:crypto";
import sql from "mssql";
import { z } from "zod";
import { getDatabase } from "../config/sqlserver.js";
import { permit, requireAuth } from "../middleware/auth.js";

export const projectsRouter = Router();
projectsRouter.use(requireAuth, permit("proyectos", "read"));

const workflowSchema = z.object({
  authorizationStatus: z.enum(["pendiente", "autorizada", "rechazada", "no_verificado"]),
  operationalStage: z.enum(["medicion", "fabricacion", "instalacion", "entregado", "no_verificado"]),
  collectionStatus: z.enum(["pendiente", "anticipo_pendiente", "parcial", "pagado", "vencido", "no_verificado"]),
  mutationId: z.string().uuid()
});

const createProjectSchema = z.object({
  code: z.string().trim().min(1).max(80),
  name: z.string().trim().min(1).max(240),
  client: z.string().trim().min(1).max(240),
  amount: z.number().finite().min(0).max(999999999999999),
  budget: z.number().finite().min(0).max(999999999999999).nullable(),
  mutationId: z.string().uuid()
});

projectsRouter.get("/", async (_req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request().query(`
      SELECT ProjectId AS id, Code AS code, Name AS name, Client AS client,
             Amount AS amount, Budget AS budget, Progress AS progress, ProjectState AS state,
             Owner AS owner, AuthorizationStatus AS authorizationStatus,
             OperationalStage AS operationalStage, CollectionStatus AS collectionStatus
      FROM dbo.Projects
      ORDER BY Code
    `);
    res.json({ projects: result.recordset });
  } catch (error) {
    next(error);
  }
});

projectsRouter.get("/:id/events", async (req, res, next) => {
  try {
    const projectId = z.string().trim().min(1).max(100).parse(req.params.id);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request()
      .input("ProjectId", sql.NVarChar(100), projectId)
      .query(`
        SELECT TOP (100) ProjectEventId AS id, ActorName AS actorName, EventType AS eventType, Detail AS detail,
               OccurredAt AS occurredAt
        FROM dbo.ProjectEvents
        WHERE ProjectId = @ProjectId
        ORDER BY OccurredAt DESC
      `);
    res.json({ events: result.recordset });
  } catch (error) {
    next(error);
  }
});

projectsRouter.post("/", permit("proyectos", "write"), async (req, res, next) => {
  try {
    const project = createProjectSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const projectId = randomUUID();
    const result = await pool.request()
      .input("ProjectId", sql.NVarChar(100), projectId)
      .input("Code", sql.NVarChar(80), project.code)
      .input("Name", sql.NVarChar(240), project.name)
      .input("Client", sql.NVarChar(240), project.client)
      .input("Amount", sql.Decimal(19, 4), project.amount)
      .input("Budget", sql.Decimal(19, 4), project.budget)
      .input("Owner", sql.NVarChar(240), req.user.name)
      .input("AppUserId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name)
      .input("MutationId", sql.UniqueIdentifier, project.mutationId)
      .execute("dbo.usp_CreateProject");
    const savedProject = result.recordset[0];
    if (!savedProject) throw new Error("SQL Server no devolvió el proyecto después de guardarlo.");
    res.status(201).json({ project: savedProject });
  } catch (error) {
    if (error.number === 2601 || error.number === 2627) {
      return res.status(409).json({ message: "Ya existe un proyecto con ese código o esta solicitud ya fue procesada." });
    }
    next(error);
  }
});

projectsRouter.patch("/:id/workflow", permit("proyectos", "write"), async (req, res, next) => {
  try {
    const projectId = z.string().trim().min(1).max(100).parse(req.params.id);
    const workflow = workflowSchema.parse(req.body);
    const detail = `Autorización: ${workflow.authorizationStatus}; etapa: ${workflow.operationalStage}; cobro: ${workflow.collectionStatus}.`;
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request()
      .input("ProjectId", sql.NVarChar(100), projectId)
      .input("AuthorizationStatus", sql.NVarChar(30), workflow.authorizationStatus)
      .input("OperationalStage", sql.NVarChar(30), workflow.operationalStage)
      .input("CollectionStatus", sql.NVarChar(30), workflow.collectionStatus)
      .input("Detail", sql.NVarChar(1000), detail)
      .input("AppUserId", sql.NVarChar(100), req.user.id)
      .input("ActorName", sql.NVarChar(240), req.user.name)
      .input("MutationId", sql.UniqueIdentifier, workflow.mutationId)
      .execute("dbo.usp_UpdateProjectWorkflow");
    if (!result.recordset[0]) return res.status(404).json({ message: "No se encontró el proyecto solicitado." });
    res.json({ project: result.recordset[0] });
  } catch (error) {
    if (error.number === 50423) return res.status(404).json({ message: "No se encontró el proyecto solicitado." });
    if (error.number === 2601 || error.number === 2627) {
      return res.status(409).json({ message: "Esta solicitud ya fue procesada con otro resultado." });
    }
    next(error);
  }
});
