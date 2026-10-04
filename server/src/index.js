import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import morgan from "morgan";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const envPath = resolve(dirname(fileURLToPath(import.meta.url)), "../../.env");
dotenv.config({ path: envPath });
const [{ errorHandler }, { database, getDatabase }, { stateRouter }] = await Promise.all([
  import("./middleware/errorHandler.js"),
  import("./config/sqlserver.js"),
  import("./routes/state.js")
]);

const app = express();
const port = process.env.PORT ?? 4000;

app.use(helmet());
const corsOrigins = process.env.CORS_ORIGIN?.split(",").map((origin) => origin.trim()).filter(Boolean) ?? [
  "http://127.0.0.1:5173",
  "http://localhost:5173"
];
app.use(cors({ origin: corsOrigins, credentials: true }));
app.use(express.json({ limit: "10mb" }));
app.use(morgan("combined"));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 250 }));

app.get("/health", (_req, res) => res.json({ status: "ok", service: "raquel-erp-api" }));
app.get("/health/database", async (_req, res) => {
  if (!database) {
    return res.status(503).json({ status: "error", message: "Configura las variables DB_* en .env." });
  }

  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ status: "error", message: "Configura las variables DB_* en .env." });
    const result = await pool.request().query("SELECT DB_NAME() AS databaseName");
    res.json({ status: "ok", database: result.recordset[0]?.databaseName });
  } catch (error) {
    res.status(503).json({ status: "error", message: "No se pudo conectar con SQL Server.", detail: error.message });
  }
});
app.use("/api/state", stateRouter);
app.use(errorHandler);

app.listen(port, "127.0.0.1", () => {
  console.log(`ERP API listening on http://127.0.0.1:${port}`);
});
