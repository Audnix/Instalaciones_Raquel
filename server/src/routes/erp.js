import { Router } from "express";
import { pingDb } from "../config/db.js";
import { loadSnapshot, saveSnapshot } from "../db/snapshot.js";

export const erpRouter = Router();

erpRouter.get("/health", async (_req, res, next) => {
  try {
    const db = await pingDb();
    res.json({ status: "ok", database: db.db, user: db.usr, at: db.at });
  } catch (error) {
    next(error);
  }
});

erpRouter.get("/snapshot", async (_req, res, next) => {
  try {
    const snapshot = await loadSnapshot();
    res.json({ snapshot });
  } catch (error) {
    next(error);
  }
});

erpRouter.put("/snapshot", async (req, res, next) => {
  try {
    const snapshot = req.body?.snapshot ?? req.body;
    if (!snapshot?.products) {
      return res.status(400).json({ message: "Snapshot inválido." });
    }
    await saveSnapshot(snapshot);
    res.json({ ok: true });
  } catch (error) {
    next(error);
  }
});
