import { Router } from "express";
import sql from "mssql";
import { getDatabase } from "../config/sqlserver.js";

export const stateRouter = Router();

stateRouter.get("/", async (_req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no esta configurado." });
    const result = await pool.request().query("SELECT Payload FROM dbo.ErpState WHERE StateId = 1");
    const payload = result.recordset[0]?.Payload;
    const state = payload ? JSON.parse(payload) : null;

    res.json({ state: state && Object.keys(state).length ? state : null });
  } catch (error) {
    next(error);
  }
});

stateRouter.put("/", async (req, res, next) => {
  try {
    const state = req.body?.state;
    if (!state || typeof state !== "object" || Array.isArray(state)) {
      return res.status(400).json({ message: "Se esperaba el objeto state del ERP." });
    }

    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "SQL Server no esta configurado." });
    const payload = JSON.stringify({
      ...state,
      users: Array.isArray(state.users)
        ? state.users.map(({ password: _password, ...user }) => user)
        : []
    });

    await pool.request()
      .input("payload", sql.NVarChar(sql.MAX), payload)
      .execute("dbo.usp_SaveErpState");

    res.json({ saved: true });
  } catch (error) {
    next(error);
  }
});