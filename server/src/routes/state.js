import { Router } from "express";
import { z } from "zod";
import { getDatabase } from "../config/sqlserver.js";
import { requireAuth, requireHierarchy } from "../middleware/auth.js";
import { saveStateSnapshot, revisionToHex } from "../services/stateSnapshot.js";
import {requiredStateCollections} from '../services/operationalIntegrity.js';

export const stateRouter = Router();
// El snapshot completo incluye datos de todas las áreas. Los demás perfiles
// usan los servicios específicos con sus permisos, nunca el guardado global.
stateRouter.use(requireAuth, requireHierarchy("superadmin"));
stateRouter.use((req, res, next) => {
  if (req.method !== "GET" && req.user.mustChangePassword) {
    return res.status(403).json({ message: "Debes cambiar la contraseña temporal antes de continuar." });
  }
  next();
});
stateRouter.get("/", async (_req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const result = await pool.request().query("SELECT Payload, Revision FROM dbo.ErpState WHERE StateId = 1");
    const row = result.recordset[0];
    const state = row?.Payload ? JSON.parse(row.Payload) : null;
    res.json({ state: state && Object.keys(state).length ? state : null, revision: revisionToHex(row?.Revision) });
  } catch (error) { next(error); }
});
export const putStateSchema = z.object({
  state: z.record(z.unknown()).superRefine((state,context)=>{
    for(const key of requiredStateCollections)if(!Array.isArray(state[key]))context.addIssue({code:z.ZodIssueCode.custom,path:[key],message:'Se requiere la colección completa del estado ERP.'});
  }),
  expectedRevision: z.string().regex(/^0x[0-9a-f]{16}$/i).optional().nullable()
});
stateRouter.put("/", async (req, res, next) => {
  try {
    const parsed = putStateSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ message: "Se esperaba el objeto state del ERP.", issues: parsed.error.issues });
    const { state, expectedRevision } = parsed.data;
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no está configurado." });
    const payload = JSON.stringify({ ...state, users: Array.isArray(state.users)
      ? state.users.map(({ password: _password, ...user }) => user) : [] });
    res.json(await saveStateSnapshot(pool, payload, expectedRevision));
  } catch (error) {
    if (error?.status === 428) return res.status(428).json({ code: error.code, message: error.message, revision: error.revision });
    if (error?.status === 409 || error?.number === 50106) return res.status(409).json({ code: "STATE_CONFLICT", message: error.message });
    next(error);
  }
});
