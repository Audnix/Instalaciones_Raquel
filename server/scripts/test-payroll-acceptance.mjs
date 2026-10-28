import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import dotenv from "dotenv";
import sql from "mssql";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, "../../.env") });

const { getDatabase } = await import("../src/config/sqlserver.js");

async function runPayrollAcceptanceTests() {
  console.log("===================================================================");
  console.log("EJECUTANDO SUITE DE PRUEBAS DE ACEPTACIÓN - NÓMINA INSTALACIONES RAQUEL");
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

  const testRunId = `run-test-${Date.now().toString(36)}`;

  try {
    // -------------------------------------------------------------------------
    // 1. REGLAS NORMATIVAS Y PARÁMETROS DE NICARAGUA
    // -------------------------------------------------------------------------
    console.log("--- 1. Catálogo de reglas normativas y parámetros oficiales ---");
    const rulesRes = await pool.request().query(`
      SELECT RuleCode, RuleName, LawReference, IsVerified
      FROM dbo.PayrollRulesCatalog;
    `);
    const rules = rulesRes.recordset;
    const ruleCodes = rules.map(r => r.RuleCode);

    assert(ruleCodes.includes("INSS_LABORAL"), "Existe regla para INSS Laboral (7.0%)");
    assert(ruleCodes.includes("INSS_PATRONAL"), "Existe regla para INSS Patronal (21.5% / 22.5%)");
    assert(ruleCodes.includes("INATEC_PATRONAL"), "Existe regla para Aporte INATEC (2.0%)");
    assert(ruleCodes.includes("IR_PROGRESIVO"), "Existe regla para Tarifa Progresiva IR (Ley 822)");
    assert(ruleCodes.includes("HORA_EXTRA_RECARGO"), "Existe regla para Horas Extraordinarias (Ley 185)");
    assert(ruleCodes.includes("AGUINALDO_PROV"), "Existe regla para Provisión de Aguinaldo (Art. 93)");
    assert(rules.every(r => r.IsVerified === true), "Todas las reglas normativas están formalmente verificadas");

    // -------------------------------------------------------------------------
    // 2. CREACIÓN DE BORRADOR DE PLANILLA (DRAFT)
    // -------------------------------------------------------------------------
    console.log("\n--- 2. Creación de borrador de planilla quincenal ---");
    const testPeriod = `2026-T-${Date.now().toString(36).slice(-6)}`;
    const createDraftRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("Period", sql.NVarChar(40), testPeriod)
      .input("PeriodType", sql.NVarChar(30), "quincenal")
      .input("StartDate", sql.Date, "2026-10-01")
      .input("EndDate", sql.Date, "2026-10-15")
      .input("PaymentDate", sql.Date, "2026-10-15")
      .input("Notes", sql.NVarChar(sql.MAX), "Planilla de prueba de aceptación automatizada")
      .input("ActorId", sql.NVarChar(100), "u-fin")
      .input("ActorName", sql.NVarChar(240), "María Contadora")
      .execute("dbo.usp_CreatePayrollDraft");

    let currentRun = createDraftRes.recordset[0];
    assert(currentRun && currentRun.id === testRunId, "Borrador de planilla creado con ID único");
    assert(currentRun.status === "borrador", "El estado inicial de la planilla es estrictamente 'borrador'");
    assert(currentRun.workersCount > 0, `Trabajadores activos preseleccionados en borrador: ${currentRun.workersCount}`);
    assert(currentRun.grossTotal === 0 && currentRun.netTotal === 0, "Borrador inicial tiene totales en 0 antes del cálculo");
    assert(typeof currentRun.revision === "string" && currentRun.revision.startsWith("0x"), "Revision de control de concurrencia es un hash hex válido 0x...");

    // Verificar que los ítems están creados en estado pendiente_calculo
    const itemsDraftRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_GetPayrollRunItems");
    const draftItems = itemsDraftRes.recordset;
    assert(draftItems.length === currentRun.workersCount, "El número de ítems coincide con workersCount");
    assert(draftItems.every(i => i.paymentStatus === "pendiente"), "Todos los ítems están en estado de pago 'pendiente'");

    // -------------------------------------------------------------------------
    // 3. REGISTRO DE NOVEDADES DEL PERÍODO
    // -------------------------------------------------------------------------
    console.log("\n--- 3. Registro de novedades (Horas Extra y Bonos) ---");
    const testEmployeeId = draftItems[0].employeeId;
    const testEmployeeName = draftItems[0].employeeName;
    const testNoveltyId = `nov-test-${Date.now().toString(36)}`;

    const noveltyRes = await pool.request()
      .input("NoveltyId", sql.NVarChar(100), testNoveltyId)
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("EmployeeId", sql.NVarChar(100), testEmployeeId)
      .input("NoveltyType", sql.NVarChar(40), "horas_extra")
      .input("Concept", sql.NVarChar(240), "Horas extras montaje perfiles especiales")
      .input("Amount", sql.Decimal(19, 4), 1250.50)
      .input("Hours", sql.Decimal(9, 2), 8.0)
      .input("LegalJustification", sql.NVarChar(500), "Art. 62 Código del Trabajo - 100% recargo por jornada extraordinaria")
      .input("DocReference", sql.NVarChar(300), "Boleta de campo #7412")
      .input("PeriodDate", sql.Date, "2026-10-08")
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_UpsertPayrollNovelty");

    assert(noveltyRes.recordset.length > 0, `Novedad de horas extras registrada para ${testEmployeeName} (${testEmployeeId})`);

    // -------------------------------------------------------------------------
    // 4. MOTOR DE CÁLCULO DE NÓMINA (LEY 185, LEY 822, INSS, INATEC, PROVISIONES)
    // -------------------------------------------------------------------------
    console.log("\n--- 4. Ejecución del motor de cálculo de nómina en servidor ---");
    const revBuffer = Buffer.from(currentRun.revision.slice(2), "hex");
    const calcRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("ExpectedRevision", sql.VarBinary(8), revBuffer)
      .input("ActorId", sql.NVarChar(100), "u-fin")
      .input("ActorName", sql.NVarChar(240), "María Contadora")
      .execute("dbo.usp_CalculatePayroll");

    currentRun = calcRes.recordset[0];
    assert(currentRun && currentRun.status === "calculada", "Estado transicionó exitosamente a 'calculada'");
    assert(currentRun.grossTotal > 0, `Devengado total calculado: C$ ${currentRun.grossTotal.toFixed(2)}`);
    assert(currentRun.inssLaboralTotal > 0, `INSS Laboral total retenido: C$ ${currentRun.inssLaboralTotal.toFixed(2)}`);
    assert(currentRun.netTotal > 0, `Neto por pagar total: C$ ${currentRun.netTotal.toFixed(2)}`);
    assert(currentRun.inssPatronalTotal > 0, `Aporte patronal INSS: C$ ${currentRun.inssPatronalTotal.toFixed(2)}`);
    assert(currentRun.inatecTotal > 0, `Aporte patronal INATEC: C$ ${currentRun.inatecTotal.toFixed(2)}`);
    assert(currentRun.provisionsTotal > 0, `Provisiones laborales totales: C$ ${currentRun.provisionsTotal.toFixed(2)}`);
    assert(currentRun.companyCostTotal > currentRun.grossTotal, `Costo total empresa refleja nómina + aportes patronales + provisiones (C$ ${currentRun.companyCostTotal.toFixed(2)})`);

    // Verificar desglose exacto de un trabajador
    const itemsCalcRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_GetPayrollRunItems");
    const calcItems = itemsCalcRes.recordset;
    const testItem = calcItems.find(i => i.employeeId === testEmployeeId);

    assert(testItem && testItem.overtimeAmount === 1250.50, "El desglose individual incluye exactamente las horas extras de la novedad (C$ 1,250.50)");
    const expectedInss = Math.round((testItem.grossIncome * 0.07) * 100) / 100;
    assert(Math.abs(testItem.inssLaboral - expectedInss) <= 0.05, `INSS Laboral coincide con el 7% exacto (Obtenido: ${testItem.inssLaboral}, Esperado: ${expectedInss})`);
    assert(testItem.netPay === (testItem.grossIncome - testItem.totalDeductions), "Neto coincide exactamente con Devengado - Total Deducciones");
    assert(typeof testItem.explanationJson === "string" && testItem.explanationJson.includes("salario"), "El campo de explicación de cálculo contiene desglose detallado");

    // -------------------------------------------------------------------------
    // 5. FLUJO DE ESTADOS Y CONTROL DE SEGREGACIÓN DE FUNCIONES
    // -------------------------------------------------------------------------
    console.log("\n--- 5. Flujo de estados y controles de integridad ---");

    // Transición: calculada -> revisada
    let currentRevBuffer = Buffer.from(currentRun.revision.slice(2), "hex");
    const revToReview = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("ExpectedRevision", sql.VarBinary(8), currentRevBuffer)
      .input("TargetStatus", sql.NVarChar(30), "revisada")
      .input("Notes", sql.NVarChar(1000), "Revisión técnica de horas extra y marcaciones completada")
      .input("ActorId", sql.NVarChar(100), "u-prod")
      .input("ActorName", sql.NVarChar(240), "Carlos Producción")
      .execute("dbo.usp_TransitionPayrollStatus");
    currentRun = revToReview.recordset[0];
    assert(currentRun.status === "revisada", "Transición a 'revisada' confirmada");

    // Intentar aprobar con el mismo usuario que la preparó (debe fallar por segregación de funciones si no es superadmin)
    currentRevBuffer = Buffer.from(currentRun.revision.slice(2), "hex");
    let caughtSegregation = false;
    try {
      await pool.request()
        .input("PayrollRunId", sql.NVarChar(100), testRunId)
        .input("ExpectedRevision", sql.VarBinary(8), currentRevBuffer)
        .input("TargetStatus", sql.NVarChar(30), "aprobada")
        .input("Notes", sql.NVarChar(1000), "Aprobando como preparador (debe ser bloqueado)")
        .input("ActorId", sql.NVarChar(100), "u-fin") // mismo que preparó
        .input("ActorName", sql.NVarChar(240), "María Contadora")
        .execute("dbo.usp_TransitionPayrollStatus");
    } catch (err) {
      if (err.number === 50511) {
        caughtSegregation = true;
      }
    }
    assert(caughtSegregation, "Segregación de funciones: se bloqueó la aprobación por el mismo usuario que preparó la nómina (Error 50511)");

    // Transición: revisada -> aprobada (con superadmin u otro aprobador autorizado)
    const approveRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("ExpectedRevision", sql.VarBinary(8), currentRevBuffer)
      .input("TargetStatus", sql.NVarChar(30), "aprobada")
      .input("Notes", sql.NVarChar(1000), "Aprobación formal por Gerencia General")
      .input("ActorId", sql.NVarChar(100), "u-super")
      .input("ActorName", sql.NVarChar(240), "Super Administrador")
      .execute("dbo.usp_TransitionPayrollStatus");
    currentRun = approveRes.recordset[0];
    assert(currentRun.status === "aprobada", "Planilla aprobada exitosamente por usuario facultado");

    // -------------------------------------------------------------------------
    // 6. CONTABILIDAD AUTOMÁTICA Y OBLIGACIONES INSTITUCIONALES
    // -------------------------------------------------------------------------
    console.log("\n--- 6. Integración contable (Partida Doble) y Obligaciones ---");
    // Verificar que las obligaciones institucionales fueron creadas
    const oblRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .query(`
        SELECT EntityName, PayableAmount, Status
        FROM dbo.PayrollInstitutionalObligations
        WHERE PayrollRunId = @PayrollRunId;
      `);
    const obligations = oblRes.recordset;
    assert(obligations.length >= 3, `Se generaron ${obligations.length} obligaciones institucionales (INSS, DGI, INATEC, PROVISIONES)`);
    const inssObl = obligations.find(o => o.EntityName === "INSS");
    const dgiObl = obligations.find(o => o.EntityName === "DGI");
    const inatecObl = obligations.find(o => o.EntityName === "INATEC");
    assert(inssObl && inssObl.PayableAmount > 0, `Obligación INSS calculada: C$ ${inssObl.PayableAmount}`);
    assert(inatecObl && inatecObl.PayableAmount > 0, `Obligación INATEC calculada: C$ ${inatecObl.PayableAmount}`);

    // Verificar asientos contables cuadrados (Débitos = Créditos)
    const entriesRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .query(`
        SELECT AccountingEntryId, Description, Debit, Credit
        FROM dbo.AccountingEntries
        WHERE PayrollRunId = @PayrollRunId;
      `);
    const entries = entriesRes.recordset;
    assert(entries.length >= 3, `Se registraron ${entries.length} asientos contables de nómina`);
    const sumDebit = entries.reduce((acc, e) => acc + Number(e.Debit), 0);
    const sumCredit = entries.reduce((acc, e) => acc + Number(e.Credit), 0);
    assert(Math.abs(sumDebit - sumCredit) < 0.01, `Principio de partida doble verificado: Total Débito (${sumDebit.toFixed(2)}) == Total Crédito (${sumCredit.toFixed(2)})`);

    // -------------------------------------------------------------------------
    // 7. PAGO REGISTRADO, DISPERSIÓN DE CAJA Y BANCOS
    // -------------------------------------------------------------------------
    console.log("\n--- 7. Registro de pago y dispersión en Caja/Bancos ---");
    currentRevBuffer = Buffer.from(currentRun.revision.slice(2), "hex");
    const payRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("ExpectedRevision", sql.VarBinary(8), currentRevBuffer)
      .input("TargetStatus", sql.NVarChar(30), "pago_registrado")
      .input("Notes", sql.NVarChar(1000), "Dispersión bancaria ACH efectuada vía BAC Credomatic")
      .input("ActorId", sql.NVarChar(100), "u-super")
      .input("ActorName", sql.NVarChar(240), "Super Administrador")
      .execute("dbo.usp_TransitionPayrollStatus");
    currentRun = payRes.recordset[0];
    assert(currentRun.status === "pago_registrado", "Planilla pasó a 'pago_registrado'");

    // Verificar movimiento en CashMoves
    const cashRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .query(`
        SELECT CashMoveId, Amount, Concept
        FROM dbo.CashMoves
        WHERE PayrollRunId = @PayrollRunId;
      `);
    const cashMove = cashRes.recordset[0];
    assert(cashMove && Number(cashMove.Amount) === Number(currentRun.netTotal), `Movimiento de egreso en Caja/Bancos registrado por el neto total: C$ ${cashMove.Amount}`);

    // Transición: conciliada -> cerrada
    currentRevBuffer = Buffer.from(currentRun.revision.slice(2), "hex");
    const concRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("ExpectedRevision", sql.VarBinary(8), currentRevBuffer)
      .input("TargetStatus", sql.NVarChar(30), "conciliada")
      .input("Notes", sql.NVarChar(1000), "Extracto bancario verificado contra nómina")
      .input("ActorId", sql.NVarChar(100), "u-super")
      .input("ActorName", sql.NVarChar(240), "Super Administrador")
      .execute("dbo.usp_TransitionPayrollStatus");
    currentRun = concRes.recordset[0];
    assert(currentRun.status === "conciliada", "Planilla conciliada exitosamente");

    currentRevBuffer = Buffer.from(currentRun.revision.slice(2), "hex");
    const closeRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("ExpectedRevision", sql.VarBinary(8), currentRevBuffer)
      .input("TargetStatus", sql.NVarChar(30), "cerrada")
      .input("Notes", sql.NVarChar(1000), "Cierre formal definitivo del período")
      .input("ActorId", sql.NVarChar(100), "u-super")
      .input("ActorName", sql.NVarChar(240), "Super Administrador")
      .execute("dbo.usp_TransitionPayrollStatus");
    currentRun = closeRes.recordset[0];
    assert(currentRun.status === "cerrada", "Planilla cerrada y archivada definitivamente");

    // -------------------------------------------------------------------------
    // 8. AUTOSERVICIO DEL TRABAJADOR Y COMPROBANTE (COLILLA DE PAGO)
    // -------------------------------------------------------------------------
    console.log("\n--- 8. Autoservicio del trabajador: Comprobante y aclaraciones ---");
    const receiptRes = await pool.request()
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("EmployeeId", sql.NVarChar(100), testEmployeeId)
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_GetPayrollEmployeeReceipt");
    const receipt = receiptRes.recordset[0];
    assert(receipt && receipt.receiptNumber && receipt.netPay > 0, `Colilla generada con número de folio ${receipt.receiptNumber}`);
    assert(receipt.overtimeAmount === 1250.50, "La colilla detalla con transparencia las horas extras devengadas");

    // Creación de ticket de revisión por el trabajador
    const ticketId = `tck-test-${Date.now().toString(36)}`;
    const ticketRes = await pool.request()
      .input("TicketId", sql.NVarChar(100), ticketId)
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .input("EmployeeId", sql.NVarChar(100), testEmployeeId)
      .input("Subject", sql.NVarChar(200), "Consulta sobre retención IR período")
      .input("Description", sql.NVarChar(1000), "Favor verificar si la proyección anual incluye deducción por carga médica de ley.")
      .input("ActorId", sql.NVarChar(100), "u-super")
      .execute("dbo.usp_CreatePayrollReceiptTicket");
    assert(ticketRes.recordset.length > 0 && ticketRes.recordset[0].ticketNumber, "Ticket de revisión de colilla creado satisfactoriamente con número correlativo");

    // -------------------------------------------------------------------------
    // 9. REPORTES DE NÓMINA
    // -------------------------------------------------------------------------
    console.log("\n--- 9. Reportes y resúmenes ejecutivos ---");
    const repPeriodRes = await pool.request()
      .input("ReportType", sql.NVarChar(50), "resumen_periodo")
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .execute("dbo.usp_GetPayrollReports");
    assert(repPeriodRes.recordset.length > 0, "Reporte 'resumen_periodo' generado con éxito");

    const repAreaRes = await pool.request()
      .input("ReportType", sql.NVarChar(50), "por_area")
      .input("PayrollRunId", sql.NVarChar(100), testRunId)
      .execute("dbo.usp_GetPayrollReports");
    assert(repAreaRes.recordset.length > 0, "Reporte 'por_area' generado con éxito con desglose de costos");

  } catch (err) {
    console.error("Error crítico durante la prueba:", err);
    failed++;
  } finally {
    console.log(`\n===================================================================`);
    console.log(`RESULTADO DE LA SUITE: ${passed} PASADAS, ${failed} FALLIDAS`);
    console.log(`===================================================================`);
    await pool.close();
    process.exit(failed > 0 ? 1 : 0);
  }
}

runPayrollAcceptanceTests();
