import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import dotenv from "dotenv";
import sql from "mssql";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, "../../.env") });

const { getDatabase } = await import("../src/config/sqlserver.js");
const { signUser } = await import("../src/middleware/auth.js");

async function testStateSync() {
  const pool = await getDatabase();
  const sessionId = randomUUID();
  const expiresAt = new Date(Date.now() + 12 * 60 * 60 * 1000);

  await pool.request()
    .input("SessionId", sql.UniqueIdentifier, sessionId)
    .input("AppUserId", sql.NVarChar(100), "u-super")
    .input("ExpiresAt", sql.DateTime2(3), expiresAt)
    .execute("dbo.usp_CreateAppUserSession");

  const token = signUser({ id: "u-super" }, sessionId);

  console.log("1. Llamando GET /api/state...");
  const getRes = await fetch("http://127.0.0.1:4000/api/state", {
    headers: { Authorization: "Bearer " + token }
  });
  console.log("Status GET:", getRes.status);
  const getData = await getRes.json();
  console.log("Revision:", getData.revision);

  console.log("2. Llamando PUT /api/state...");
  const putRes = await fetch("http://127.0.0.1:4000/api/state", {
    method: "PUT",
    headers: {
      Authorization: "Bearer " + token,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      state: getData.state,
      expectedRevision: getData.revision
    })
  });
  console.log("Status PUT:", putRes.status);
  const putData = await putRes.json();
  console.log("Respuesta PUT:", putData);

  await pool.close();
}

testStateSync().catch(console.error);
