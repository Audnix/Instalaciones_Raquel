import type { ErpDatabase } from "../types/erp";
import { digest } from "./auditSeal";
import { buildBooks, IR_CORP, PAYOUT } from "./booksNi";
import { IVA_RATE } from "./dgiNi";

function xml(value: string) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function cellText(value: string) {
  return `<Cell><Data ss:Type="String">${xml(value)}</Data></Cell>`;
}

function cellNum(value: number) {
  return `<Cell ss:StyleID="money"><Data ss:Type="Number">${value.toFixed(2)}</Data></Cell>`;
}

function cellPct(value: number) {
  return `<Cell ss:StyleID="pct"><Data ss:Type="Number">${(value / 100).toFixed(4)}</Data></Cell>`;
}

function row(cells: string) {
  return `<Row>${cells}</Row>`;
}

function header(labels: string[]) {
  return row(labels.map((label) => `<Cell ss:StyleID="head"><Data ss:Type="String">${xml(label)}</Data></Cell>`).join(""));
}

function title(text: string) {
  return row(`<Cell ss:StyleID="title"><Data ss:Type="String">${xml(text)}</Data></Cell>`);
}

function na(value: number | null) {
  return value == null ? cellText("n.a.") : cellNum(value);
}

function sheet(name: string, body: string) {
  return `<Worksheet ss:Name="${xml(name)}"><Table>${body}</Table></Worksheet>`;
}

export function buildAccountingWorkbook(db: ErpDatabase, actor: string) {
  const books = buildBooks(db);
  const entries = db.accounting;
  const debit = entries.reduce((sum, item) => sum + item.debit, 0);
  const credit = entries.reduce((sum, item) => sum + item.credit, 0);
  const iva = db.sales.filter((item) => item.status === "completed").reduce((sum, item) => sum + item.taxAmount, 0);
  const stamp = digest(`${entries.map((item) => item.entryNumber).join("|")}|${books.live.sales}|${books.live.cogs}|${actor}`);
  const when = new Date().toLocaleString("es-NI");

  const ledger = new Map<string, { account: string; debit: number; credit: number }>();
  entries.forEach((item) => {
    const debitRow = ledger.get(item.debitAccount) ?? { account: item.debitAccount, debit: 0, credit: 0 };
    debitRow.debit += item.debit;
    ledger.set(item.debitAccount, debitRow);
    const creditRow = ledger.get(item.creditAccount) ?? { account: item.creditAccount, debit: 0, credit: 0 };
    creditRow.credit += item.credit;
    ledger.set(item.creditAccount, creditRow);
  });

  const diario = [
    header(["Asiento", "Fecha", "Descripción", "Debe", "Haber", "Monto", "Origen"]),
    ...entries.map((item) =>
      row([cellText(item.entryNumber), cellText(item.entryDate.slice(0, 10)), cellText(item.description), cellText(item.debitAccount), cellText(item.creditAccount), cellNum(item.debit), cellText(item.referenceType)].join(""))
    )
  ].join("");

  const mayor = [
    header(["Cuenta", "Débitos", "Créditos", "Saldo"]),
    ...[...ledger.values()].sort((a, b) => a.account.localeCompare(b.account, "es")).map((item) =>
      row([cellText(item.account), cellNum(item.debit), cellNum(item.credit), cellNum(item.debit - item.credit)].join(""))
    )
  ].join("");

  const ivaSheet = [
    header(["Factura", "Cliente", "Fecha", "Base", "IVA 15%", "Total"]),
    ...db.sales.filter((item) => item.status === "completed").map((item) =>
      row([cellText(item.saleNumber), cellText(item.clientName), cellText(item.saleDate.slice(0, 10)), cellNum(item.subtotal - (item.discountAmount ?? 0)), cellNum(item.taxAmount), cellNum(item.total)].join(""))
    )
  ].join("");

  const ventasDia = [
    title("Control de ventas diarias · operación"),
    header(["Fecha", "Factura", "Cliente", "Línea", "Cantidad", "Venta neta", "Costo PEPS", "Margen"]),
    ...books.dayRows.map((item) =>
      row([cellText(item.date), cellText(item.saleNumber), cellText(item.client), cellText(item.line), cellNum(item.qty), cellNum(item.sales), cellNum(item.cost), cellNum(item.margin)].join(""))
    )
  ].join("");

  const ventasMes = [
    title("Cierre mensual · real vs presupuesto"),
    header(["Mes", "Tickets", "Ventas", "Costo", "Margen", "Presupuesto ventas", "Presupuesto costo", "Desvío ventas"]),
    ...books.months.map((item) =>
      row([cellText(item.label), cellNum(item.tickets), cellNum(item.sales), cellNum(item.cost), cellNum(item.margin), cellNum(item.budgetSales), cellNum(item.budgetCost), cellNum(item.sales - item.budgetSales)].join(""))
    )
  ].join("");

  const ventasAnio = [
    title("Cierre anual · 2022-2026"),
    header(["Año", "Origen", "Ventas", "Costo", "Margen", "Tickets"]),
    ...books.years.map((item) =>
      row([cellText(item.year), cellText(item.source), cellNum(item.sales), cellNum(item.cost), cellNum(item.margin), cellNum(item.tickets)].join(""))
    )
  ].join("");

  const resultado = [
    title("Estado de resultados · IR 30% · payout 40%"),
    header(["Concepto", ...books.income.map((item) => item.period)]),
    row([cellText("Ventas"), ...books.income.map((item) => cellNum(item.sales))].join("")),
    row([cellText("Costo de ventas"), ...books.income.map((item) => cellNum(item.cogs))].join("")),
    row([cellText("Utilidad bruta"), ...books.income.map((item) => cellNum(item.gross))].join("")),
    row([cellText("Gastos de operación"), ...books.income.map((item) => cellNum(item.opex))].join("")),
    row([cellText("Depreciación"), ...books.income.map((item) => cellNum(item.depreciation))].join("")),
    row([cellText("Utilidad de operación"), ...books.income.map((item) => cellNum(item.ebit))].join("")),
    row([cellText("Intereses"), ...books.income.map((item) => cellNum(item.interest))].join("")),
    row([cellText("Utilidad antes de IR"), ...books.income.map((item) => cellNum(item.ebt))].join("")),
    row([cellText(`IR ${IR_CORP * 100}%`), ...books.income.map((item) => cellNum(item.tax))].join("")),
    row([cellText("Utilidad neta"), ...books.income.map((item) => cellNum(item.net))].join("")),
    row([cellText(`Dividendos ${PAYOUT * 100}%`), ...books.income.map((item) => cellNum(item.dividends))].join("")),
    row([cellText("Utilidades retenidas"), ...books.income.map((item) => cellNum(item.retained))].join(""))
  ].join("");

  const balance = [
    title("Balance general"),
    header(["Concepto", ...books.balances.map((item) => item.period)]),
    row([cellText("Caja y bancos"), ...books.balances.map((item) => cellNum(item.cash))].join("")),
    row([cellText("Inventario PEPS"), ...books.balances.map((item) => cellNum(item.inventory))].join("")),
    row([cellText("Cuentas por cobrar"), ...books.balances.map((item) => cellNum(item.receivables))].join("")),
    row([cellText("Activo corriente"), ...books.balances.map((item) => cellNum(item.current))].join("")),
    row([cellText("Equipo bruto"), ...books.balances.map((item) => cellNum(item.grossFixed))].join("")),
    row([cellText("Depreciación acumulada"), ...books.balances.map((item) => cellNum(-item.accumDep))].join("")),
    row([cellText("Activo fijo neto"), ...books.balances.map((item) => cellNum(item.netFixed))].join("")),
    row([cellText("Total activos"), ...books.balances.map((item) => cellNum(item.totalAssets))].join("")),
    row([cellText("Cuentas por pagar"), ...books.balances.map((item) => cellNum(item.payables))].join("")),
    row([cellText("Pasivo corto plazo"), ...books.balances.map((item) => cellNum(item.shortDebt))].join("")),
    row([cellText("Pasivo largo plazo"), ...books.balances.map((item) => cellNum(item.longDebt))].join("")),
    row([cellText("Total pasivo"), ...books.balances.map((item) => cellNum(item.totalLiab))].join("")),
    row([cellText("Capital social"), ...books.balances.map((item) => cellNum(item.capital))].join("")),
    row([cellText("Utilidades retenidas"), ...books.balances.map((item) => cellNum(item.retained))].join("")),
    row([cellText("Patrimonio"), ...books.balances.map((item) => cellNum(item.equity))].join("")),
    row([cellText("Pasivo + patrimonio"), ...books.balances.map((item) => cellNum(item.totalLplusE))].join("")),
    row([cellText("Diferencia de cuadre"), ...books.balances.map((item) => cellNum(item.difference))].join(""))
  ].join("");

  const flujo = [
    title("Flujo de efectivo operativo y libre"),
    header(["Concepto", ...books.flows.map((item) => item.period)]),
    row([cellText("Saldo inicial"), ...books.flows.map((item) => cellNum(item.opening))].join("")),
    row([cellText("Utilidad retenida"), ...books.flows.map((item) => cellNum(item.retained))].join("")),
    row([cellText("(+) Depreciación"), ...books.flows.map((item) => cellNum(item.depreciation))].join("")),
    row([cellText("(−) Amortización préstamo"), ...books.flows.map((item) => cellNum(item.loanPay))].join("")),
    row([cellText("Flujo del período"), ...books.flows.map((item) => cellNum(item.flow))].join("")),
    row([cellText("Saldo final"), ...books.flows.map((item) => cellNum(item.closing))].join("")),
    row([cellText("FEO (UN + Dep)"), ...books.flows.map((item) => cellNum(item.feo))].join("")),
    row([cellText("CAPEX"), ...books.flows.map((item) => cellNum(item.capex))].join("")),
    row([cellText("FCL (FEO − CAPEX)"), ...books.flows.map((item) => cellNum(item.fcl))].join(""))
  ].join("");

  const eoaf = [
    title("Estado de origen y aplicación de fondos"),
    header(["Concepto", ...books.eoaf.map((item) => item.period)]),
    row([cellText("Origen: utilidad neta"), ...books.eoaf.map((item) => cellNum(item.originNet))].join("")),
    row([cellText("Origen: depreciación"), ...books.eoaf.map((item) => cellNum(item.originDep))].join("")),
    row([cellText("Total orígenes"), ...books.eoaf.map((item) => cellNum(item.origins))].join("")),
    row([cellText("Aplicación: aumento de caja"), ...books.eoaf.map((item) => cellNum(item.appCash))].join("")),
    row([cellText("Aplicación: CAPEX"), ...books.eoaf.map((item) => cellNum(item.appCapex))].join("")),
    row([cellText("Aplicación: dividendos"), ...books.eoaf.map((item) => cellNum(item.appDiv))].join("")),
    row([cellText("Aplicación: disminución de pasivo"), ...books.eoaf.map((item) => cellNum(item.appDebt))].join("")),
    row([cellText("Total aplicaciones"), ...books.eoaf.map((item) => cellNum(item.applications))].join("")),
    row([cellText("Residual"), ...books.eoaf.map((item) => cellNum(item.residual))].join(""))
  ].join("");

  const razones = [
    title("Razones de liquidez, endeudamiento, solvencia, actividad y rentabilidad"),
    header(["Indicador", ...books.ratios.map((item) => item.period)]),
    row([cellText("Razón corriente"), ...books.ratios.map((item) => na(item.current))].join("")),
    row([cellText("Prueba ácida"), ...books.ratios.map((item) => na(item.acid))].join("")),
    row([cellText("Deuda / activo %"), ...books.ratios.map((item) => cellPct(item.debtAsset))].join("")),
    row([cellText("Deuda / patrimonio %"), ...books.ratios.map((item) => cellPct(item.debtEquity))].join("")),
    row([cellText("Autonomía %"), ...books.ratios.map((item) => cellPct(item.autonomy))].join("")),
    row([cellText("Solvencia"), ...books.ratios.map((item) => na(item.solvency))].join("")),
    row([cellText("Cobertura de intereses"), ...books.ratios.map((item) => na(item.coverage))].join("")),
    row([cellText("Rotación de activos"), ...books.ratios.map((item) => cellNum(item.assetTurn))].join("")),
    row([cellText("Rotación activo fijo"), ...books.ratios.map((item) => cellNum(item.fixedTurn))].join("")),
    row([cellText("Días de cobro"), ...books.ratios.map((item) => cellNum(item.collectDays))].join("")),
    row([cellText("Días de pago"), ...books.ratios.map((item) => cellNum(item.payDays))].join("")),
    row([cellText("Margen bruto %"), ...books.ratios.map((item) => cellPct(item.grossMargin))].join("")),
    row([cellText("Margen operacional %"), ...books.ratios.map((item) => cellPct(item.opMargin))].join("")),
    row([cellText("Margen neto %"), ...books.ratios.map((item) => cellPct(item.netMargin))].join("")),
    row([cellText("ROA %"), ...books.ratios.map((item) => cellPct(item.roa))].join("")),
    row([cellText("ROE %"), ...books.ratios.map((item) => cellPct(item.roe))].join("")),
    row([cellText("Dupont %"), ...books.ratios.map((item) => cellPct(item.dupont))].join(""))
  ].join("");

  const mix = [
    title("Mix gerencial por línea · la de mayor margen manda el negocio"),
    header(["Línea", "Ventas", "Costo", "Margen", "Peso ventas %", "Peso costo %"]),
    ...books.mix.map((item) =>
      row([cellText(item.category), cellNum(item.sales), cellNum(item.cost), cellNum(item.margin), cellPct(item.weight), cellPct(item.costWeight)].join(""))
    )
  ].join("");

  const costos = [
    title("Contabilidad de costos · PEPS, materiales y mano de obra"),
    header(["Campo", "Valor"]),
    row(cellText("Materiales recibidos") + cellNum(books.materials)),
    row(cellText("Mano de obra mes (costo patronal)") + cellNum(books.labor)),
    row(cellText("Gastos generales del año") + cellNum(books.overhead)),
    row(cellText("Costo de ventas YTD") + cellNum(books.live.cogs)),
    row(cellText("IVA aplicado") + cellText(`${IVA_RATE * 100}%`)),
    header(["Producto", "Costo PEPS unitario", "Stock", "Valor inventario"]),
    ...db.products.map((item) => {
      const lot = db.lots.filter((row) => row.productId === item.id && row.quantity > 0).sort((a, b) => a.entryDate.localeCompare(b.entryDate))[0];
      const stock = db.lots.filter((row) => row.productId === item.id).reduce((sum, row) => sum + row.quantity, 0);
      const cost = lot?.unitCost ?? 0;
      return row([cellText(item.name), cellNum(cost), cellNum(stock), cellNum(cost * stock)].join(""));
    })
  ].join("");

  const vertical = [
    title("Análisis vertical · % sobre ventas"),
    header(["Concepto", ...books.vertical.map((item) => item.period)]),
    row([cellText("Costo de ventas"), ...books.vertical.map((item) => cellPct(item.cogs))].join("")),
    row([cellText("Utilidad bruta"), ...books.vertical.map((item) => cellPct(item.gross))].join("")),
    row([cellText("Gastos de operación"), ...books.vertical.map((item) => cellPct(item.opex))].join("")),
    row([cellText("Utilidad de operación"), ...books.vertical.map((item) => cellPct(item.ebit))].join("")),
    row([cellText("Utilidad neta"), ...books.vertical.map((item) => cellPct(item.net))].join(""))
  ].join("");

  const horizontal = [
    title("Análisis horizontal · variación interanual"),
    header(["Concepto", ...books.horizontal.map((item) => item.period)]),
    row([cellText("Ventas"), ...books.horizontal.map((item) => cellPct(item.sales))].join("")),
    row([cellText("Costo de ventas"), ...books.horizontal.map((item) => cellPct(item.cogs))].join("")),
    row([cellText("Gastos de operación"), ...books.horizontal.map((item) => cellPct(item.opex))].join("")),
    row([cellText("Utilidad neta"), ...books.horizontal.map((item) => cellPct(item.net))].join(""))
  ].join("");

  const cierre = [
    header(["Campo", "Valor"]),
    row(cellText("Empresa") + cellText("Instalaciones Raquel")),
    row(cellText("Libro") + cellText("Financiera · Gerencial · Costos")),
    row(cellText("Exportó") + cellText(actor)),
    row(cellText("Cuando") + cellText(when)),
    row(cellText("Día") + cellText(books.today)),
    row(cellText("Mes") + cellText(books.month)),
    row(cellText("Año") + cellNum(books.year)),
    row(cellText("Asientos") + cellNum(entries.length)),
    row(cellText("Débitos") + cellNum(debit)),
    row(cellText("Créditos") + cellNum(credit)),
    row(cellText("IVA 15%") + cellNum(iva)),
    row(cellText("Línea de mayor beneficio") + cellText(books.bestLine?.category ?? "—")),
    row(cellText("Cuadre diario") + cellText(Math.abs(debit - credit) < 0.01 ? "Balanceado" : "Descuadre")),
    row(cellText("Sello") + cellText(stamp))
  ].join("");

  const xmlDoc = `<?xml version="1.0" encoding="UTF-8"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
  <Styles>
    <Style ss:ID="head">
      <Font ss:Bold="1" ss:Color="#FFFFFF"/>
      <Interior ss:Color="#0B6F94" ss:Pattern="Solid"/>
    </Style>
    <Style ss:ID="title">
      <Font ss:Bold="1" ss:Size="13" ss:Color="#0B6F94"/>
    </Style>
    <Style ss:ID="money">
      <NumberFormat ss:Format="#,##0.00"/>
    </Style>
    <Style ss:ID="pct">
      <NumberFormat ss:Format="0.0%"/>
    </Style>
  </Styles>
  ${sheet("Ventas dia", ventasDia)}
  ${sheet("Ventas mes", ventasMes)}
  ${sheet("Ventas anio", ventasAnio)}
  ${sheet("Resultado", resultado)}
  ${sheet("Balance", balance)}
  ${sheet("Flujo", flujo)}
  ${sheet("EOAF", eoaf)}
  ${sheet("Razones", razones)}
  ${sheet("Mix lineas", mix)}
  ${sheet("Costos PEPS", costos)}
  ${sheet("Vertical", vertical)}
  ${sheet("Horizontal", horizontal)}
  ${sheet("Diario", diario)}
  ${sheet("Mayor", mayor)}
  ${sheet("IVA", ivaSheet)}
  ${sheet("Cierre", cierre)}
</Workbook>`;

  return { xml: xmlDoc, stamp, debit, credit, iva, books };
}

export function downloadAccountingWorkbook(db: ErpDatabase, actor: string) {
  const book = buildAccountingWorkbook(db, actor);
  const blob = new Blob(["\uFEFF" + book.xml], { type: "application/vnd.ms-excel;charset=utf-8" });
  const href = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = href;
  link.download = `Libro_Raquel_${book.books.today}.xls`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(href);
  return book;
}
