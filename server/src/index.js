import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import morgan from "morgan";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { authRouter } from "./routes/auth.js";
import { erpRouter } from "./routes/erp.js";
import { errorHandler } from "./middleware/errorHandler.js";

const envPath = resolve(dirname(fileURLToPath(import.meta.url)), "../../.env");
dotenv.config({ path: envPath });

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

app.get("/health", async (_req, res) => {
  try {
    const { pingDb } = await import("./config/db.js");
    const db = await pingDb();
    res.json({ status: "ok", service: "raquel-erp-api", database: db.db, user: db.usr });
  } catch (error) {
    res.status(503).json({ status: "error", service: "raquel-erp-api", message: error.message });
  }
});
app.use("/api/auth", authRouter);
app.use("/api/erp", erpRouter);
app.use(errorHandler);

app.listen(port, "0.0.0.0", () => {
  console.log(`ERP API listening on http://127.0.0.1:${port}`);
});
