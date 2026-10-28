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

const [
  { errorHandler },
  { database, getDatabase },
  { authRouter },
  { usersRouter },
  { tasksRouter },
  { stateRouter },
  { supplierDirectoryRouter },
  { hrRouter },
  { payrollRouter },
  { cashRouter },
  { databaseRouter }
] = await Promise.all([
  import("./middleware/errorHandler.js"),
  import("./config/sqlserver.js"),
  import("./routes/auth.js"),
  import("./routes/users.js"),
  import("./routes/tasks.js"),
  import("./routes/state.js"),
  import("./routes/supplierDirectory.js"),
  import("./routes/hr.js"),
  import("./routes/payroll.js"),
  import("./routes/cash.js"),
  import("./routes/database.js")
]);

const app = express();
const port = Number(process.env.PORT) || 4000;

app.use(helmet());
const corsOrigins = process.env.CORS_ORIGIN?.split(",").map((origin) => origin.trim()).filter(Boolean) ?? [
  "http://127.0.0.1:5173",
  "http://localhost:5173"
];
app.use(cors({ origin: corsOrigins, credentials: true }));
app.use(express.json({ limit: "10mb" }));
app.use(morgan("combined"));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 350 }));

app.get("/health", (_req, res) => res.json({ status: "ok", service: "raquel-erp-api" }));

app.get("/health/database", async (_req, res) => {
  if (!database) {
    return res.status(503).json({ status: "error", message: "Configura las variables DB_* en .env." });
  }

  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ status: "error", message: "Configura las variables DB_* en .env." });
    const result = await pool.request().query(`
      SELECT 
        DB_NAME() AS databaseName,
        SUSER_NAME() AS currentLogin,
        (SELECT COUNT(*) FROM dbo.AppUserSessions WHERE RevokedAt IS NULL AND ExpiresAt > SYSUTCDATETIME()) AS activeSessions,
        (SELECT COUNT(*) FROM dbo.AppUsers WHERE PasswordHash IS NOT NULL AND IsActive = 1) AS activatedAccounts;
    `);
    const row = result.recordset?.[0];
    res.json({
      status: "ok",
      database: row?.databaseName,
      user: row?.currentLogin,
      activeSessions: row?.activeSessions || 0,
      activatedAccounts: row?.activatedAccounts || 0
    });
  } catch (error) {
    res.status(503).json({ status: "error", message: "No se pudo conectar con SQL Server.", detail: error.message });
  }
});

// Rutas de API
app.use("/api/auth", authRouter);
app.use("/api/users", usersRouter);
app.use("/api/tasks", tasksRouter);
app.use("/api/supplier-directory", supplierDirectoryRouter);
app.use("/api/hr", hrRouter);
app.use("/api/payroll", payrollRouter);
app.use("/api/cash", cashRouter);
app.use("/api/state", stateRouter);
app.use("/api/database", databaseRouter);

app.use(errorHandler);

app.listen(port, "127.0.0.1", () => {
  console.log(`ERP API listening on http://127.0.0.1:${port}`);
});
