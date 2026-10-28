import { randomUUID, createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import dotenv from "dotenv";
import sql from "mssql";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, "../../.env") });

const { getDatabase } = await import("../src/config/sqlserver.js");

async function runSuppliersAcceptanceTests() {
  console.log("===================================================================");
  console.log("PRUEBAS DE ACEPTACIÓN - DIRECTORIO Y EXPEDIENTE DE PROVEEDORES");
  console.log("INSTALACIONES RAQUEL - SQL SERVER INTEGRATION");
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

  const testPartyId = `PRV-TEST-${Date.now().toString(36).toUpperCase()}`;

  // Limpieza inicial de pruebas previas
  await pool.request().query(`
    DELETE FROM dbo.SupplierDirectoryEvents WHERE PartyId LIKE 'PRV-TEST%';
    DELETE FROM dbo.SupplierDirectoryFiles WHERE PartyId LIKE 'PRV-TEST%';
    DELETE FROM dbo.SupplierDirectory WHERE PartyId LIKE 'PRV-TEST%';
    DELETE FROM dbo.Parties WHERE PartyId LIKE 'PRV-TEST%';

    DECLARE @CleanParties NVARCHAR(MAX);
    SELECT @CleanParties = N'[' + COALESCE(STRING_AGG(CONVERT(NVARCHAR(MAX), value), N','), N'') + N']'
    FROM OPENJSON((SELECT Payload FROM dbo.ErpState WHERE StateId = 1), '$.parties')
    WHERE JSON_VALUE(value, '$.id') NOT LIKE 'PRV-TEST%';
    UPDATE dbo.ErpState SET Payload = JSON_MODIFY(Payload, '$.parties', JSON_QUERY(@CleanParties)) WHERE StateId = 1;
  `);

  try {
    // -------------------------------------------------------------------------
    // 1. LECTURA DEL DIRECTORIO GENERAL DE PROVEEDORES
    // -------------------------------------------------------------------------
    console.log("--- 1. Directorio general y vista consolidada ---");
    const dirResult = await pool.request().execute("dbo.usp_ReadSupplierDirectory");
    const suppliers = dirResult.recordset ?? [];
    assert(suppliers.length >= 4, "Directorio contiene proveedores base", `Total encontrados: ${suppliers.length}`);

    const pv1 = suppliers.find((s) => s.id === "pv1");
    assert(pv1 !== undefined, "Proveedor base pv1 (Alumex) existe en el directorio");
    assert(pv1?.category === "materiales", "Categoría comercial de pv1 es materiales", pv1?.category);
    assert(pv1?.status === "activo", "Estado operativo de pv1 es activo", pv1?.status);
    assert(pv1?.ruc === "J0310000102030", "RUC fiscal de pv1 registrado", pv1?.ruc);

    // -------------------------------------------------------------------------
    // 2. EXPEDIENTE DETALLADO Y COMPRAS VINCULADAS CON PAGOS
    // -------------------------------------------------------------------------
    console.log("\n--- 2. Expediente de pv1 y compras vinculadas con pagos ---");
    const expResult = await pool.request()
      .input("PartyId", sql.NVarChar(100), "pv1")
      .execute("dbo.usp_ReadSupplierDirectory");

    const expSupplier = expResult.recordsets[0]?.[0];
    const expEvents = expResult.recordsets[1] ?? [];
    const expPurchases = expResult.recordsets[2] ?? [];
    const expFiles = expResult.recordsets[3] ?? [];

    assert(expSupplier !== undefined, "Expediente detallado de pv1 cargado");
    assert(expPurchases.length > 0, "Compras vinculadas por SupplierPartyId", `Total: ${expPurchases.length}`);

    const purchase = expPurchases[0];
    assert(purchase?.number === "OC-2026-00081", "Número de orden de compra correcta", purchase?.number);
    assert(purchase?.status === "received", "Estado de recepción en bodega confirmado", purchase?.status);
    assert(Number(purchase?.total) === 33700, "Monto total de orden C$ 33,700", purchase?.total);
    assert(purchase?.paymentId === "fin-3", "Pago vinculado a Finanzas (fin-3)", purchase?.paymentId);
    assert(purchase?.paymentDate !== null, "Fecha de pago confirmada registrada", purchase?.paymentDate);
    assert(Number(purchase?.paidAmount) === 33700, "Monto pagado coincide exactamente", purchase?.paidAmount);

    // -------------------------------------------------------------------------
    // 3. DOCUMENTOS Y PERMISOS DE ARCHIVO
    // -------------------------------------------------------------------------
    console.log("\n--- 3. Documentos y homologación técnica ---");
    const profile = JSON.parse(expSupplier.profile || "{}");
    const docs = profile.documents ?? [];
    assert(docs.length >= 2, "Documentos en expediente (RUC y Ficha ASTM)", `Total docs: ${docs.length}`);
    const rucDoc = docs.find((d) => d.title.includes("RUC"));
    assert(rucDoc !== undefined, "Cédula RUC DGI presente en documentos");
    assert(rucDoc?.review === "aceptado", "Revisión documental aceptada", rucDoc?.review);

    // -------------------------------------------------------------------------
    // 4. CREACIÓN DE NUEVO PROVEEDOR CON AUDITORÍA Y CONTROL CONCURRENTE
    // -------------------------------------------------------------------------
    console.log("\n--- 4. Creación de nuevo proveedor mediante procedimiento transaccional ---");
    const mutationId = randomUUID();
    const testName = `Vidriería y Templados Central S.A. ${Date.now().toString(36)}`;
    const newSupplierData = {
      name: testName,
      legalName: `${testName} Sociedad Anónima`,
      category: "materiales",
      specialty: "vidrio",
      contact: "Lic. Manuel Centeno",
      contactRole: "Gerente Comercial",
      phone: "2244-8899",
      email: "ventas@vidrieriacentral.com.ni",
      address: "Carretera Norte Km 4.5, Semáforos Portezuelo 1c al Sur",
      dispatchAddress: "Bodega Parque Industrial Portezuelo Mod 8",
      productsServices: "Vidrio templado incoloro y bronce, herrajes de acero inoxidable para arañas y fachadas vidriadas.",
      ruc: "J0310000998877",
      paymentTerms: "Crédito 20 días",
      currency: "NIO",
      leadDays: 4,
      bankDetails: "BAC Nicaragua Cta Corriente NIO ****-8899",
      discounts: "5% en compras superiores a C$ 40,000",
      transportTerms: "Flete incluido en el área metropolitana de Managua",
      observations: "Proveedor de respaldo evaluado para proyectos de cortina de vidrio.",
      status: "activo",
      reviewStatus: "aprobado",
      reviewEvidence: "Inspección técnica de hornos de templado horizontal y solvencia DGI verificada conforme.",
      nextReviewDate: "2027-04-30",
      contacts: [
        { name: "Ing. Sofía Blandón", role: "Calidad de Vidrio", phone: "8899-7711", email: "calidad@vidrieriacentral.com.ni" }
      ],
      documents: [
        {
          id: randomUUID(),
          title: "Cédula RUC DGI Vidriería Central",
          type: "Fiscal",
          reference: "Constancia DGI 2026-RUC-991823",
          issuedOn: "2026-02-01",
          expiresOn: "2027-02-01",
          review: "aceptado",
          reviewNote: "Registro fiscal activo sin contingencias.",
          fileName: "RUC_Central_2026.pdf",
          fileType: "application/pdf",
          uploadedAt: new Date().toISOString(),
          reviewedAt: new Date().toISOString(),
          reviewedBy: "Luis Morales"
        }
      ]
    };

    const hash = createHash("sha256").update(JSON.stringify(newSupplierData)).digest("hex");

    const saveResult = await pool.request()
      .input("PartyId", sql.NVarChar(100), testPartyId)
      .input("Data", sql.NVarChar(sql.MAX), JSON.stringify(newSupplierData))
      .input("ExpectedVersion", sql.VarChar(18), null)
      .input("MutationId", sql.UniqueIdentifier, mutationId)
      .input("ActorId", sql.NVarChar(100), "usr-admin")
      .input("ActorName", sql.NVarChar(200), "Luis Morales")
      .input("Reason", sql.NVarChar(500), "Alta de nuevo proveedor homologado para fachadas")
      .input("RequestHash", sql.VarChar(64), hash)
      .execute("dbo.usp_SaveSupplierDirectory");

    assert(saveResult.recordset[0]?.response !== undefined, "Proveedor nuevo creado exitosamente con usp_SaveSupplierDirectory");

    // -------------------------------------------------------------------------
    // 5. IDEMPOTENCIA Y RECIBO DE MUTACIÓN
    // -------------------------------------------------------------------------
    console.log("\n--- 5. Verificación de idempotencia (Receipt Replay) ---");
    const receiptResult = await pool.request()
      .input("MutationId", sql.UniqueIdentifier, mutationId)
      .execute("dbo.usp_ReadSupplierDirectoryReceipt");

    const receipt = receiptResult.recordset[0];
    assert(receipt !== undefined, "Recibo de mutación persistido en eventos");
    assert(receipt?.PartyId === testPartyId, "PartyId en recibo coincide", receipt?.PartyId);
    assert(receipt?.RequestHash === hash, "Hash de petición verificado", receipt?.RequestHash);

    // -------------------------------------------------------------------------
    // 6. CONTROL DE CONCURRENCIA OPTIMISTA (EXPECTED VERSION)
    // -------------------------------------------------------------------------
    console.log("\n--- 6. Verificación de concurrencia optimista ---");
    let concurrencyFailedAsExpected = false;
    try {
      await pool.request()
        .input("PartyId", sql.NVarChar(100), testPartyId)
        .input("Data", sql.NVarChar(sql.MAX), JSON.stringify({ ...newSupplierData, name: "Nombre Conflicto" }))
        .input("ExpectedVersion", sql.VarChar(18), "0x0000000000000001") // Versión incorrecta
        .input("MutationId", sql.UniqueIdentifier, randomUUID())
        .input("ActorId", sql.NVarChar(100), "usr-admin")
        .input("ActorName", sql.NVarChar(200), "Luis Morales")
        .input("Reason", sql.NVarChar(500), "Intento de actualización con versión obsoleta")
        .input("RequestHash", sql.VarChar(64), "dummyhash")
        .execute("dbo.usp_SaveSupplierDirectory");
    } catch (err) {
      if (err.number === 50503 || err.message.includes("modifico el proveedor")) {
        concurrencyFailedAsExpected = true;
      }
    }
    assert(concurrencyFailedAsExpected, "Control de concurrencia optimista rechazó actualización con versión obsoleta");

    // -------------------------------------------------------------------------
    // 7. PRESERVACIÓN DEL ESTADO ERP (usp_SaveErpState)
    // -------------------------------------------------------------------------
    console.log("\n--- 7. Preservación de proveedores ante snapshots de ErpState ---");
    const countBefore = (await pool.request().query("SELECT COUNT(*) as c FROM dbo.Parties WHERE PartyType = 'proveedor'")).recordset[0].c;

    // Ejecutar usp_SaveErpState con el payload real existente de 19 colecciones
    const stateRow = (await pool.request().query("SELECT Payload, Revision FROM dbo.ErpState WHERE StateId = 1")).recordset[0];
    await pool.request()
      .input("Payload", sql.NVarChar(sql.MAX), stateRow.Payload)
      .input("ExpectedRevision", sql.Binary(8), stateRow.Revision)
      .execute("dbo.usp_SaveErpState");

    const countAfter = (await pool.request().query("SELECT COUNT(*) as c FROM dbo.Parties WHERE PartyType = 'proveedor'")).recordset[0].c;
    assert(countAfter >= countBefore, "usp_SaveErpState preservó intactos los proveedores", `Antes: ${countBefore}, Después: ${countAfter}`);

    // Limpieza del proveedor de prueba
    await pool.request().query(`
      DELETE FROM dbo.SupplierDirectoryEvents WHERE PartyId = '${testPartyId}';
      DELETE FROM dbo.SupplierDirectoryFiles WHERE PartyId = '${testPartyId}';
      DELETE FROM dbo.SupplierDirectory WHERE PartyId = '${testPartyId}';
      DELETE FROM dbo.Parties WHERE PartyId = '${testPartyId}';

      DECLARE @CleanParties NVARCHAR(MAX);
      SELECT @CleanParties = N'[' + COALESCE(STRING_AGG(CONVERT(NVARCHAR(MAX), value), N','), N'') + N']'
      FROM OPENJSON((SELECT Payload FROM dbo.ErpState WHERE StateId = 1), '$.parties')
      WHERE JSON_VALUE(value, '$.id') NOT LIKE 'PRV-TEST%';
      UPDATE dbo.ErpState SET Payload = JSON_MODIFY(Payload, '$.parties', JSON_QUERY(@CleanParties)) WHERE StateId = 1;
    `);

    console.log("\n===================================================================");
    console.log(`RESUMEN DE PRUEBAS DE ACEPTACIÓN:`);
    console.log(`PASADAS: ${passed}`);
    console.log(`FALLADAS: ${failed}`);
    console.log("===================================================================");

    if (failed > 0) {
      process.exit(1);
    } else {
      console.log("\nTODAS LAS PRUEBAS DE ACEPTACIÓN DE PROVEEDORES PASARON CON ÉXITO.\n");
      process.exit(0);
    }
  } catch (error) {
    console.error("Error inesperado durante las pruebas:", error);
    process.exit(1);
  }
}

runSuppliersAcceptanceTests();
