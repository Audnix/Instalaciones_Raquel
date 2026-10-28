import fs from "fs";
import path from "path";
import mssql from "mssql";

const config = {
  server: process.env.DB_SERVER || "127.0.0.1",
  port: Number(process.env.DB_PORT) || 51433,
  database: process.env.DB_NAME || "Instalaciones Raquel",
  user: process.env.DB_USER || "raquel_erp_app",
  password: process.env.DB_PASSWORD || "Jose090507",
  options: {
    encrypt: false,
    trustServerCertificate: true
  }
};

async function run() {
  const filePath = path.resolve("Database/SQLServer_Completo/25_mejoras_gestion_talento_humano_y_nomina.sql");
  console.log("Reading:", filePath);
  const content = fs.readFileSync(filePath, "utf-8");

  const batches = content
    .split(/^\s*GO\s*$/gmi)
    .map(b => b.trim())
    .filter(b => b.length > 0 && !b.startsWith("USE "));

  console.log(`Connecting to SQL Server at ${config.server}:${config.port}...`);
  const pool = await mssql.connect(config);
  console.log("Connected successfully!");

  for (let i = 0; i < batches.length; i++) {
    const batch = batches[i];
    try {
      await pool.request().batch(batch);
      console.log(`Batch ${i + 1}/${batches.length} executed successfully.`);
    } catch (err) {
      console.error(`Error executing batch ${i + 1}:`, err.message);
      process.exit(1);
    }
  }

  console.log("Migration 25 applied completely and successfully!");
  await pool.close();
}

run().catch(err => {
  console.error("Migration failed:", err);
  process.exit(1);
});
