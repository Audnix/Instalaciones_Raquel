import dotenv from "dotenv";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, "../../.env") });

const { getDatabase } = await import("../src/config/sqlserver.js");

async function main() {
  const pool = await getDatabase();
  const users = await pool.request().query("SELECT AppUserId, Name, Email, Hierarchy, IsActive, HasPassword = CASE WHEN PasswordHash IS NOT NULL THEN 1 ELSE 0 END, MustChangePassword FROM dbo.AppUsers WHERE Email = 'admin@jhonnyarea.com'");
  console.log("User:", users.recordset);
  if (users.recordset.length > 0) {
    const userId = users.recordset[0].AppUserId;
    const areas = await pool.request().query(`SELECT Area FROM dbo.AppUserAreas WHERE AppUserId = '${userId}'`);
    console.log("Areas:", areas.recordset.map(r => r.Area));
    const inv = await pool.request().query(`SELECT * FROM dbo.AppUserInvitations WHERE AppUserId = '${userId}'`);
    console.log("Invitations:", inv.recordset);
  }
}

main().then(() => process.exit(0)).catch((err) => {
  console.error(err);
  process.exit(1);
});
