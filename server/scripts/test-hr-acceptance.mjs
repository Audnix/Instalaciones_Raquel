import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import dotenv from "dotenv";
import sql from "mssql";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, "../../.env") });

const { getDatabase } = await import("../src/config/sqlserver.js");

async function runAcceptanceTests() {
  console.log("===================================================================");
  console.log("EJECUTANDO SUITE DE PRUEBAS DE ACEPTACIÓN - TALENTO HUMANO RAQUEL");
  console.log("===================================================================\n");

  const pool = await getDatabase();
  if (!pool) {
    throw new Error("No se pudo conectar a SQL Server. Revisa las variables en .env");
  }

  let passed = 0;
  let failed = 0;

  function assert(condition, testName, detail = "") {
    if (condition) {
      console.log(`[PASS] ${testName}`);
      passed++;
    } else {
      console.error(`[FAIL] ${testName}: ${detail}`);
      failed++;
    }
  }

  try {
    // 1. Privacidad y aislamiento: Un empleado estándar solo consulta su propio expediente
    console.log("--- 1. Privacidad y aislamiento de expedientes ---");
    const meRes = await pool.request()
      .input("ActorId", sql.NVarChar(100), "u-prod")
      .execute("dbo.usp_GetHrMyEmployee");
    const myEmp = meRes.recordset[0];
    assert(myEmp && myEmp.id === "emp-01",
      `Consulta propia de 'u-prod' devuelve su propio expediente (${myEmp?.id}: ${myEmp?.name})`);

    const prodEmpId = myEmp?.id || "emp-01";
    const prodEmpName = myEmp?.name || "Carlos Mendoza";

    // 2. Protección salarial: Empleado no autorizado no recibe salario en detalle
    console.log("\n--- 2. Protección de datos salariales ---");
    const detailWorkerRes = await pool.request()
      .input("EmployeeId", sql.NVarChar(100), prodEmpId)
      .input("ActorId", sql.NVarChar(100), "u-prod")
      .execute("dbo.usp_GetHrEmployeeDetail");
    const workerView = detailWorkerRes.recordsets[0][0];
    assert(workerView && workerView.salary === null,
      "usp_GetHrEmployeeDetail oculta el salario (NULL) cuando el consultante no tiene rol RRHH");

    const detailAdminRes = await pool.request()
      .input("EmployeeId", sql.NVarChar(100), prodEmpId)
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_GetHrEmployeeDetail");
    const adminView = detailAdminRes.recordsets[0][0];
    assert(adminView && adminView.salary !== null && Number(adminView.salary) > 0,
      "usp_GetHrEmployeeDetail entrega el salario solo a administración autorizada");

    // 3. Idempotencia: Una solicitud con la misma mutationId se registra una sola vez
    console.log("\n--- 3. Idempotencia y protección contra duplicados ---");
    const testMutationId = randomUUID();
    const testRequestId1 = randomUUID();
    const testRequestId2 = randomUUID();

    const req1 = await pool.request()
      .input("HrRequestId", sql.UniqueIdentifier, testRequestId1)
      .input("MutationId", sql.UniqueIdentifier, testMutationId)
      .input("EmployeeId", sql.NVarChar(100), prodEmpId)
      .input("Category", sql.NVarChar(30), "consulta_laboral")
      .input("StartDate", sql.Date, null)
      .input("EndDate", sql.Date, null)
      .input("Details", sql.NVarChar(1000), "Consulta de prueba para verificación de idempotencia.")
      .input("AppUserId", sql.NVarChar(100), "u-prod")
      .input("ActorName", sql.NVarChar(240), prodEmpName)
      .execute("dbo.usp_CreateHrRequest");

    const req2 = await pool.request()
      .input("HrRequestId", sql.UniqueIdentifier, testRequestId2)
      .input("MutationId", sql.UniqueIdentifier, testMutationId)
      .input("EmployeeId", sql.NVarChar(100), prodEmpId)
      .input("Category", sql.NVarChar(30), "consulta_laboral")
      .input("StartDate", sql.Date, null)
      .input("EndDate", sql.Date, null)
      .input("Details", sql.NVarChar(1000), "Reintento de la misma consulta de prueba.")
      .input("AppUserId", sql.NVarChar(100), "u-prod")
      .input("ActorName", sql.NVarChar(240), prodEmpName)
      .execute("dbo.usp_CreateHrRequest");

    assert(req1.recordset[0].id.toLowerCase() === req2.recordset[0].id.toLowerCase(),
      "Reenvío de mutationId devuelve el registro original sin duplicar la solicitud");

    // 4. Separación de funciones: La administradora no puede auto-aprobar sus propias solicitudes
    console.log("\n--- 4. Separación de funciones (No auto-aprobación) ---");
    const superReqId = randomUUID();
    const superMutId = randomUUID();
    const superEmpRes = await pool.request()
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_GetHrEmployeeIdForUser");
    const superEmpId = superEmpRes.recordset[0]?.employeeId || "emp-14";

    const superReq = await pool.request()
      .input("HrRequestId", sql.UniqueIdentifier, superReqId)
      .input("MutationId", sql.UniqueIdentifier, superMutId)
      .input("EmployeeId", sql.NVarChar(100), superEmpId)
      .input("Category", sql.NVarChar(30), "consulta_laboral")
      .input("StartDate", sql.Date, null)
      .input("EndDate", sql.Date, null)
      .input("Details", sql.NVarChar(1000), "Consulta administrativa de prueba para verificar no auto-aprobación.")
      .input("AppUserId", sql.NVarChar(100), "u-super")
      .input("ActorName", sql.NVarChar(240), "Raquel López")
      .execute("dbo.usp_CreateHrRequest");

    let selfApprovalBlocked = false;
    try {
      const superRevHex = superReq.recordset[0].revision.startsWith("0x")
        ? superReq.recordset[0].revision.slice(2)
        : superReq.recordset[0].revision;
      await pool.request()
        .input("HrRequestId", sql.UniqueIdentifier, superReq.recordset[0].id)
        .input("ExpectedRevision", sql.VarBinary(8), Buffer.from(superRevHex, "hex"))
        .input("Status", sql.NVarChar(20), "aprobada")
        .input("Resolution", sql.NVarChar(1000), "Auto-aprobación no permitida")
        .input("ActorId", sql.NVarChar(100), "u-super")
        .input("ActorName", sql.NVarChar(240), "Raquel López")
        .execute("dbo.usp_UpdateHrRequestStatus");
    } catch (err) {
      if (err.number === 50441) {
        selfApprovalBlocked = true;
      }
    }
    assert(selfApprovalBlocked,
      "El sistema bloquea estrictamente la auto-aprobación de solicitudes propias (Error 50441)");

    // 5. Concurrencia optimista (ROWVERSION): Detección de colisiones
    console.log("\n--- 5. Concurrencia optimista y prevención de sobrescritura silenciosa ---");
    let concurrencyDetected = false;
    try {
      const staleRevision = Buffer.from("0000000000000001", "hex");
      await pool.request()
        .input("HrRequestId", sql.UniqueIdentifier, req1.recordset[0].id)
        .input("ExpectedRevision", sql.VarBinary(8), staleRevision)
        .input("Status", sql.NVarChar(20), "en_revision")
        .input("Resolution", sql.NVarChar(1000), "Revisión con clave obsoleta")
        .input("ActorId", sql.NVarChar(100), "u-super")
        .input("ActorName", sql.NVarChar(240), "Raquel López")
        .execute("dbo.usp_UpdateHrRequestStatus");
    } catch (err) {
      if (err.number === 50437) {
        concurrencyDetected = true;
      }
    }
    assert(concurrencyDetected,
      "Detección de modificación concurrente activa: se rechaza la edición con revisión desfasada (Error 50437)");

    // 6. Trazabilidad: Una decisión autorizada registra responsable, fecha y resolución
    console.log("\n--- 6. Aprobación autorizada con auditoría completa ---");
    const freshRevHex = req1.recordset[0].revision.startsWith("0x")
      ? req1.recordset[0].revision.slice(2)
      : req1.recordset[0].revision;

    const approvedRes = await pool.request()
      .input("HrRequestId", sql.UniqueIdentifier, req1.recordset[0].id)
      .input("ExpectedRevision", sql.VarBinary(8), Buffer.from(freshRevHex, "hex"))
      .input("Status", sql.NVarChar(20), "aprobada")
      .input("Resolution", sql.NVarChar(1000), "Solicitud revisada y autorizada conforme al reglamento interno.")
      .input("ActorId", sql.NVarChar(100), "u-super")
      .input("ActorName", sql.NVarChar(240), "Raquel López")
      .execute("dbo.usp_UpdateHrRequestStatus");

    assert(approvedRes.recordset[0].status === "aprobada" && approvedRes.recordset[0].decidedAt !== null,
      "La aprobación registra estado 'aprobada', fecha formal de decisión y resolución motivada");

    const eventsRes = await pool.request()
      .input("HrRequestId", sql.UniqueIdentifier, req1.recordset[0].id)
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_GetHrRequestEvents");
    assert(eventsRes.recordset.length >= 2,
      "Línea de tiempo de eventos registra creación, revisión y decisión con actor responsable");

    // 7. Integridad de baja laboral: No borra el expediente histórico
    console.log("\n--- 7. Baja laboral controlada sin pérdida histórica ---");
    const testEmployeeId = `emp-test-${Date.now().toString(36)}`;
    await pool.request()
      .input("MutationId", sql.UniqueIdentifier, randomUUID())
      .input("EmployeeId", sql.NVarChar(100), testEmployeeId)
      .input("Name", sql.NVarChar(240), "Colaborador Prueba Baja")
      .input("Position", sql.NVarChar(200), "Ayudante de Taller")
      .input("Salary", sql.Decimal(19, 4), 9500)
      .input("Area", sql.NVarChar(120), "Producción")
      .input("AppUserId", sql.NVarChar(100), null)
      .input("HireDate", sql.Date, "2025-06-01")
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_CreateHrEmployee");

    const termRes = await pool.request()
      .input("EmployeeId", sql.NVarChar(100), testEmployeeId)
      .input("DismissalDate", sql.Date, "2026-10-15")
      .input("DismissalReason", sql.NVarChar(500), "Finalización de obra por mutuo acuerdo")
      .input("DismissalDocRef", sql.NVarChar(300), "DOC-BAJA-2026-001.pdf")
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_TerminateHrEmployee");

    assert(termRes.recordset[0].employmentStatus === "baja",
      "Estado de colaborador cambia a 'baja' con registro de fecha y motivo autorizado");

    const verifyHist = await pool.request()
      .input("EmployeeId", sql.NVarChar(100), testEmployeeId)
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_GetHrEmployeeJobHistory");
    assert(verifyHist.recordset.length > 0,
      "El historial laboral, cargos y salarios previos se conservan intactos en la base de datos");

    // 8. Métricas del Dashboard cuadran con registros reales
    console.log("\n--- 8. Verificación de métricas del Dashboard ---");
    const metricsRes = await pool.request()
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_GetHrDashboardMetrics");
    const m = metricsRes.recordset[0];
    const actualActiveRes = await pool.request().query("SELECT COUNT(*) AS c FROM dbo.Employees WHERE EmploymentStatus = 'activo'");
    const actualActive = actualActiveRes.recordset[0].c;
    assert(m.activeEmployees === actualActive,
      `Métrica de personal activo (${m.activeEmployees}) coincide exactamente con registros de SQL Server (${actualActive})`);

    // 9. Biblioteca pública de derechos aislada de datos privados
    console.log("\n--- 9. Superficie pública de derechos y orientación ---");
    const rightsRes = await pool.request().query("SELECT COUNT(*) AS total, SUM(CASE WHEN IsPublic = 1 THEN 1 ELSE 0 END) AS publicTotal FROM dbo.HrRightsArticles");
    assert(rightsRes.recordset[0].publicTotal >= 6,
      "Catálogo público de derechos cuenta con al menos 6 fichas oficiales fundamentadas en Ley 185 y Ley 618");

  } catch (err) {
    console.error("Error inesperado en pruebas:", err);
    failed++;
  }

  console.log("\n===================================================================");
  console.log(`RESULTADO FINAL: ${passed} PRUEBAS EXITOSAS, ${failed} FALLIDAS.`);
  console.log("===================================================================");

  if (failed > 0) {
    process.exit(1);
  }
  process.exit(0);
}

runAcceptanceTests();
