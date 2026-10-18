import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";
import dotenv from "dotenv";
import bcrypt from "bcryptjs";
import sql from "mssql";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = resolve(__dirname, "../..");
const envPath = resolve(rootDir, ".env");
if (existsSync(envPath)) dotenv.config({ path: envPath });

const email = (process.env.BOOTSTRAP_USER_EMAIL || "admin@raquel.com").trim().toLowerCase();
const password = process.env.BOOTSTRAP_USER_PASSWORD?.trim();

if (!password || password.length < 8) {
  console.error("Configura BOOTSTRAP_USER_PASSWORD con al menos 8 caracteres en .env para inicializar la cuenta superadmin.");
  process.exit(1);
}

const server = process.env.DB_SERVER || "127.0.0.1";
const port = Number(process.env.DB_PORT) || 63454;
const dbName = process.env.DB_NAME || "Instalaciones Raquel";
const dbUser = process.env.DB_USER?.trim() || "raquel_erp_app";
const dbPassword = process.env.DB_PASSWORD?.trim();

async function main() {
  console.log(`Inicializando cuenta superadmin: ${email} en SQL Server (${server}:${port})...`);
  const pool = await sql.connect({
    server,
    port,
    database: dbName,
    user: dbUser,
    password: dbPassword,
    options: {
      encrypt: false,
      trustServerCertificate: true
    }
  });

  try {
    // Verificar si ya tiene contraseña hash
    const check = await pool.request()
      .input("email", sql.NVarChar(320), email)
      .query("SELECT AppUserId, Name, PasswordHash, IsActive FROM dbo.AppUsers WHERE LOWER(Email) = LOWER(@email);");

    const user = check.recordset[0];
    if (!user) {
      console.error(`No se encontró el usuario con correo ${email} en dbo.AppUsers.`);
      process.exit(1);
    }

    if (user.PasswordHash) {
      console.log(`La cuenta ${email} ya cuenta con una contraseña segura hash (bcrypt). Conservando credenciales existentes.`);
      process.exit(0);
    }

    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(password, salt);

    await pool.request()
      .input("Email", sql.NVarChar(320), email)
      .input("PasswordHash", sql.NVarChar(100), hash)
      .execute("dbo.usp_BootstrapSuperAdmin");

    console.log(`[EXITO] Cuenta superadministradora ${email} activada con hash bcrypt seguro.`);
  } finally {
    await pool.close();
  }
}

main().catch((err) => {
  console.error("Error en bootstrap superadmin:", err.message);
  process.exit(1);
});
