import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import crypto from "node:crypto";
import dotenv from "dotenv";
import bcrypt from "bcryptjs";
import sql from "mssql";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, "../../.env") });

const { getDatabase } = await import("../src/config/sqlserver.js");

const email = process.argv[2]?.trim().toLowerCase();
const password = process.argv[3];

if (!email || !password) {
  console.log("Uso: node server/scripts/set-user-password.mjs <correo> <contraseña>");
  console.log("Ejemplo: node server/scripts/set-user-password.mjs admin@jhonnyarea.com Jhonny2026!");
  process.exit(1);
}

if (password.length < 8) {
  console.error("Error: La contraseña debe tener al menos 8 caracteres.");
  process.exit(1);
}

async function main() {
  const pool = await getDatabase();
  if (!pool) {
    console.error("Error: No se pudo conectar a SQL Server.");
    process.exit(1);
  }

  // Buscar usuario usando el SP de login que raquel_erp_app sí tiene permiso de ejecutar
  const check = await pool.request()
    .input("Email", sql.NVarChar(320), email)
    .execute("dbo.usp_GetAppUserForLogin");

  if (!check.recordset || check.recordset.length === 0) {
    console.error(`Error: No se encontró ningún usuario con el correo '${email}'.`);
    process.exit(1);
  }

  const user = check.recordset[0];
  const salt = await bcrypt.genSalt(10);
  const hash = await bcrypt.hash(password, salt);

  // Llamar al procedimiento oficial con ownership chaining
  await pool.request()
    .input("AppUserId", sql.NVarChar(100), user.AppUserId)
    .input("SessionId", sql.UniqueIdentifier, crypto.randomUUID())
    .input("PasswordHash", sql.NVarChar(100), hash)
    .execute("dbo.usp_ChangeAppUserPassword");

  console.log("=================================================");
  console.log("CONTRASEÑA ASIGNADA EXITOSAMENTE EN SQL SERVER");
  console.log("=================================================");
  console.log(`Usuario: ${user.Name} (${user.Email})`);
  console.log(`Jerarquía: ${user.Hierarchy}`);
  console.log(`Estado: Activo - Listo para iniciar sesión`);
  console.log("=================================================");
}

main().then(() => process.exit(0)).catch((err) => {
  console.error("Error al actualizar:", err);
  process.exit(1);
});
