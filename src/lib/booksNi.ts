import type { ErpDatabase, InventoryLot, Product, Sale } from "../types/erp";
import { monthKey, monthLabel } from "./dgiNi";
import { payrollOf } from "./payrollNi";

/** IR de renta empresarial Ley 822 · misma tasa del modelo financiero. */
export const IR_CORP = 0.3;
export const PAYOUT = 0.4;
export const SHARES = 5000;

export type MixRow = {
  category: string;
  sales: number;
  cost: number;
  margin: number;
  weight: number;
  costWeight: number;
};

export type IncomeStatement = {
  period: string;
  sales: number;
  cogs: number;
  gross: number;
  opex: number;
  depreciation: number;
  ebit: number;
  interest: number;
  ebt: number;
  tax: number;
  net: number;
  dividends: number;
  retained: number;
};

export type BalanceSheet = {
  period: string;
  cash: number;
  inventory: number;
  receivables: number;
  current: number;
  grossFixed: number;
  accumDep: number;
  netFixed: number;
  totalAssets: number;
  payables: number;
  shortDebt: number;
  longDebt: number;
  totalLiab: number;
  capital: number;
  retained: number;
  equity: number;
  totalLplusE: number;
  difference: number;
};

export type CashFlow = {
  period: string;
  opening: number;
  retained: number;
  depreciation: number;
  loanPay: number;
  capex: number;
  flow: number;
  closing: number;
  feo: number;
  fcl: number;
};

export type Eoaf = {
  period: string;
  originNet: number;
  originDep: number;
  origins: number;
  appCash: number;
  appCapex: number;
  appDiv: number;
  appDebt: number;
  applications: number;
  residual: number;
};

export type RatioSet = {
  period: string;
  current: number | null;
  acid: number | null;
  debtAsset: number;
  debtEquity: number;
  autonomy: number;
  solvency: number | null;
  coverage: number | null;
  assetTurn: number;
  fixedTurn: number;
  collectDays: number;
  payDays: number;
  grossMargin: number;
  opMargin: number;
  netMargin: number;
  roa: number;
  roe: number;
  dupont: number;
  upa: number;
  dpa: number;
  book: number;
  payout: number;
};

export type DailyRow = {
  date: string;
  saleNumber: string;
  client: string;
  line: string;
  qty: number;
  sales: number;
  cost: number;
  margin: number;
};

export type MonthRow = {
  month: string;
  label: string;
  sales: number;
  cost: number;
  margin: number;
  budgetSales: number;
  budgetCost: number;
  tickets: number;
};

export type YearAnchor = {
  year: number;
  sales: number;
  cogs: number;
  opex: number;
  depreciation: number;
  interest: number;
  mix: MixRow[];
  cash: number;
  inventory: number;
  receivables: number;
  grossFixed: number;
  accumDep: number;
  payables: number;
  shortDebt: number;
  longDebt: number;
  capital: number;
  retained: number;
  capex: number;
};

export type AccountPulse = {
  name: string;
  kind: "linea" | "gasto" | "cuenta";
  amount: number;
  previous: number;
  delta: number;
  deltaPct: number;
  weight: number;
  status: "mejora" | "estable" | "deterioro" | "perdida";
  note: string;
};

export type SteeringPack = {
  month: string;
  label: string;
  prevLabel: string;
  sales: number;
  prevSales: number;
  salesDelta: number;
  salesDeltaPct: number;
  cost: number;
  prevCost: number;
  result: number;
  prevResult: number;
  resultDelta: number;
  budgetSales: number;
  budgetCost: number;
  budgetGap: number;
  vsBudgetPct: number;
  tickets: number;
  status: "ganancia" | "perdida" | "equilibrio" | "alerta";
  statusLabel: string;
  headline: string;
  contribution: number;
  cmRatio: number;
  fixedCosts: number;
  breakEven: number;
  gapToBreakEven: number;
  safetyMargin: number;
  accounts: AccountPulse[];
  actions: string[];
  nextMonthFocus: string[];
  monthSeries: Array<{ label: string; sales: number; cost: number; result: number; breakEven: number; presupuesto: number }>;
};

const money = (value: number) => Number(value.toFixed(2));
const pct = (num: number, den: number) => (den ? money((num / den) * 100) : 0);
const div = (num: number, den: number) => (Math.abs(den) < 0.0001 ? null : money(num / den));

export const yearAnchors: YearAnchor[] = [
  {
    year: 2022,
    sales: 8420000,
    cogs: 3620000,
    opex: 1180000,
    depreciation: 185000,
    interest: 42000,
    mix: [
      { category: "Perfiles", sales: 3280000, cost: 1640000, margin: 1640000, weight: 39, costWeight: 45.3 },
      { category: "Vidrios", sales: 2520000, cost: 1130000, margin: 1390000, weight: 29.9, costWeight: 31.2 },
      { category: "Accesorios", sales: 760000, cost: 310000, margin: 450000, weight: 9, costWeight: 8.6 },
      { category: "Electrodomésticos", sales: 1860000, cost: 540000, margin: 1320000, weight: 22.1, costWeight: 14.9 }
    ],
    cash: 1850000,
    inventory: 980000,
    receivables: 210000,
    grossFixed: 2140000,
    accumDep: 428000,
    payables: 240000,
    shortDebt: 180000,
    longDebt: 420000,
    capital: 1800000,
    retained: 2112000,
    capex: 0
  },
  {
    year: 2023,
    sales: 9860000,
    cogs: 4410000,
    opex: 1240000,
    depreciation: 185000,
    interest: 28000,
    mix: [
      { category: "Perfiles", sales: 3420000, cost: 1740000, margin: 1680000, weight: 34.7, costWeight: 39.5 },
      { category: "Vidrios", sales: 2680000, cost: 1210000, margin: 1470000, weight: 27.2, costWeight: 27.4 },
      { category: "Accesorios", sales: 820000, cost: 340000, margin: 480000, weight: 8.3, costWeight: 7.7 },
      { category: "Electrodomésticos", sales: 2940000, cost: 1120000, margin: 1820000, weight: 29.8, costWeight: 25.4 }
    ],
    cash: 2680000,
    inventory: 1120000,
    receivables: 185000,
    grossFixed: 2140000,
    accumDep: 613000,
    payables: 210000,
    shortDebt: 160000,
    longDebt: 260000,
    capital: 1800000,
    retained: 3642000,
    capex: 0
  },
  {
    year: 2024,
    sales: 12240000,
    cogs: 5480000,
    opex: 1310000,
    depreciation: 185000,
    interest: 14000,
    mix: [
      { category: "Perfiles", sales: 3680000, cost: 1860000, margin: 1820000, weight: 30.1, costWeight: 33.9 },
      { category: "Vidrios", sales: 2940000, cost: 1320000, margin: 1620000, weight: 24, costWeight: 24.1 },
      { category: "Accesorios", sales: 890000, cost: 360000, margin: 530000, weight: 7.3, costWeight: 6.6 },
      { category: "Electrodomésticos", sales: 4730000, cost: 1940000, margin: 2790000, weight: 38.6, costWeight: 35.4 }
    ],
    cash: 4120000,
    inventory: 1280000,
    receivables: 160000,
    grossFixed: 2614000,
    accumDep: 798000,
    payables: 190000,
    shortDebt: 120000,
    longDebt: 140000,
    capital: 1800000,
    retained: 5926000,
    capex: 474000
  },
  {
    year: 2025,
    sales: 14880000,
    cogs: 6680000,
    opex: 1420000,
    depreciation: 185000,
    interest: 4200,
    mix: [
      { category: "Perfiles", sales: 3920000, cost: 1980000, margin: 1940000, weight: 26.3, costWeight: 29.6 },
      { category: "Vidrios", sales: 3180000, cost: 1440000, margin: 1740000, weight: 21.4, costWeight: 21.6 },
      { category: "Accesorios", sales: 960000, cost: 380000, margin: 580000, weight: 6.5, costWeight: 5.7 },
      { category: "Electrodomésticos", sales: 6820000, cost: 2880000, margin: 3940000, weight: 45.8, costWeight: 43.1 }
    ],
    cash: 5960000,
    inventory: 1410000,
    receivables: 98000,
    grossFixed: 2614000,
    accumDep: 983000,
    payables: 150000,
    shortDebt: 80000,
    longDebt: 0,
    capital: 1800000,
    retained: 8869000,
    capex: 0
  }
];

export function pepsCost(productId: string, lots: InventoryLot[]) {
  const live = lots
    .filter((item) => item.productId === productId && item.quantity > 0)
    .sort((a, b) => a.entryDate.localeCompare(b.entryDate));
  return live[0]?.unitCost ?? lots.find((item) => item.productId === productId)?.unitCost ?? 0;
}

function productOf(products: Product[], id: string) {
  return products.find((item) => item.id === id);
}

function saleNet(sale: Sale) {
  return money(sale.subtotal - (sale.discountAmount ?? 0));
}

function saleLines(sale: Sale, products: Product[], lots: InventoryLot[]): DailyRow[] {
  const net = saleNet(sale);
  const gross = sale.items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0) || 1;
  return sale.items.map((item) => {
    const product = productOf(products, item.productId);
    const sales = money((item.quantity * item.unitPrice * net) / gross);
    const cost = money(item.quantity * pepsCost(item.productId, lots));
    return {
      date: sale.saleDate.slice(0, 10),
      saleNumber: sale.saleNumber,
      client: sale.clientName,
      line: product?.category ?? "Otros",
      qty: item.quantity,
      sales,
      cost,
      margin: money(sales - cost)
    };
  });
}

function statementOf(period: string, sales: number, cogs: number, opex: number, depreciation: number, interest: number): IncomeStatement {
  const gross = money(sales - cogs);
  const ebit = money(gross - opex - depreciation);
  const ebt = money(ebit - interest);
  const tax = money(Math.max(0, ebt) * IR_CORP);
  const net = money(ebt - tax);
  const dividends = money(net * PAYOUT);
  const retained = money(net - dividends);
  return { period, sales, cogs, gross, opex, depreciation, ebit, interest, ebt, tax, net, dividends, retained };
}

function balanceOf(period: string, row: Omit<BalanceSheet, "period" | "current" | "netFixed" | "totalAssets" | "totalLiab" | "equity" | "totalLplusE" | "difference">): BalanceSheet {
  const current = money(row.cash + row.inventory + row.receivables);
  const netFixed = money(row.grossFixed - row.accumDep);
  const totalAssets = money(current + netFixed);
  const totalLiab = money(row.payables + row.shortDebt + row.longDebt);
  const equity = money(row.capital + row.retained);
  const totalLplusE = money(totalLiab + equity);
  return {
    period,
    ...row,
    current,
    netFixed,
    totalAssets,
    totalLiab,
    equity,
    totalLplusE,
    difference: money(totalAssets - totalLplusE)
  };
}

function cashOf(period: string, opening: number, net: number, retained: number, depreciation: number, loanPay: number, capex: number): CashFlow {
  const feo = money(net + depreciation);
  const flow = money(retained + depreciation - loanPay);
  return {
    period,
    opening,
    retained,
    depreciation,
    loanPay,
    capex,
    flow,
    closing: money(opening + flow),
    feo,
    fcl: money(feo - capex)
  };
}

function statementFromAnchor(anchor: YearAnchor) {
  const now = new Date().getFullYear();
  const period = anchor.year === now ? `${anchor.year} acum.` : String(anchor.year);
  return statementOf(period, anchor.sales, anchor.cogs, anchor.opex, anchor.depreciation, anchor.interest);
}

function balanceFromAnchor(anchor: YearAnchor) {
  return balanceOf(String(anchor.year), {
    cash: anchor.cash,
    inventory: anchor.inventory,
    receivables: anchor.receivables,
    grossFixed: anchor.grossFixed,
    accumDep: anchor.accumDep,
    payables: anchor.payables,
    shortDebt: anchor.shortDebt,
    longDebt: anchor.longDebt,
    capital: anchor.capital,
    retained: anchor.retained
  });
}

function ratiosOf(is: IncomeStatement, bs: BalanceSheet): RatioSet {
  return {
    period: is.period,
    current: div(bs.current, bs.payables + bs.shortDebt),
    acid: div(bs.cash + bs.receivables, bs.payables + bs.shortDebt),
    debtAsset: pct(bs.totalLiab, bs.totalAssets),
    debtEquity: pct(bs.totalLiab, bs.equity),
    autonomy: pct(bs.equity, bs.totalAssets),
    solvency: div(bs.totalAssets, bs.totalLiab),
    coverage: div(is.ebit, is.interest),
    assetTurn: money(is.sales / (bs.totalAssets || 1)),
    fixedTurn: money(is.sales / (bs.grossFixed || 1)),
    collectDays: money(bs.receivables / (is.sales / 360 || 1)),
    payDays: money(bs.payables / (is.cogs / 360 || 1)),
    grossMargin: pct(is.gross, is.sales),
    opMargin: pct(is.ebit, is.sales),
    netMargin: pct(is.net, is.sales),
    roa: pct(is.net, bs.totalAssets),
    roe: pct(is.net, bs.equity),
    dupont: money((is.net / (is.sales || 1)) * (is.sales / (bs.totalAssets || 1)) * (bs.totalAssets / (bs.equity || 1)) * 100),
    upa: money(is.net / SHARES),
    dpa: money(is.dividends / SHARES),
    book: money(bs.equity / SHARES),
    payout: PAYOUT * 100
  };
}

function mixOf(rows: DailyRow[]): MixRow[] {
  const map = new Map<string, MixRow>();
  const sales = rows.reduce((sum, item) => sum + item.sales, 0);
  const cost = rows.reduce((sum, item) => sum + item.cost, 0);
  rows.forEach((item) => {
    const current = map.get(item.line) ?? { category: item.line, sales: 0, cost: 0, margin: 0, weight: 0, costWeight: 0 };
    current.sales += item.sales;
    current.cost += item.cost;
    map.set(item.line, current);
  });
  return [...map.values()]
    .map((item) => ({
      ...item,
      sales: money(item.sales),
      cost: money(item.cost),
      margin: money(item.sales - item.cost),
      weight: pct(item.sales, sales),
      costWeight: pct(item.cost, cost)
    }))
    .sort((a, b) => b.margin - a.margin);
}

function monthBudget(projections: ErpDatabase["projections"], key: string) {
  const names = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
  const stamp = names[Number(key.slice(5, 7)) - 1];
  const row = projections.find((item) => item.month === stamp);
  return { sales: row?.expectedSales ?? 0, cost: row?.expectedCosts ?? 0 };
}

function liveYear(db: ErpDatabase, year: number): YearAnchor {
  const done = db.sales.filter((item) => item.status === "completed" && item.saleDate.startsWith(String(year)));
  const rows = done.flatMap((sale) => saleLines(sale, db.products, db.lots));
  const sales = money(rows.reduce((sum, item) => sum + item.sales, 0));
  const cogs = money(rows.reduce((sum, item) => sum + item.cost, 0));
  const months = Math.max(1, new Date().getMonth() + 1);
  const payroll = payrollOf(db.employees).employerCost * months;
  const extras = db.finance
    .filter((item) => item.type === "egreso" && item.date.startsWith(String(year)) && item.category !== "Materia prima")
    .reduce((sum, item) => sum + item.amount, 0);
  const prev = yearAnchors.find((item) => item.year === year - 1) ?? yearAnchors[yearAnchors.length - 1];
  const inventory = money(db.lots.reduce((sum, item) => sum + item.quantity * item.unitCost, 0));
  const cashMoves = db.cash.reduce((sum, item) => sum + (item.type === "entrada" ? item.amount : -item.amount), 0);
  const cashSales = done.reduce((sum, item) => sum + item.total, 0);
  const opMix = mixOf(rows);
  const budgetSales = money(db.projections.reduce((sum, item) => sum + item.expectedSales, 0));
  const budgetCogs = money(db.projections.reduce((sum, item) => sum + item.expectedCosts, 0));
  const thin = sales < prev.sales * 0.05;
  const yearSales = thin ? budgetSales : sales;
  const yearCogs = thin ? budgetCogs : cogs;
  const scaledMix = prev.mix.map((item) => {
    const salesPart = money((item.weight / 100) * yearSales);
    const costPart = money((item.costWeight / 100) * yearCogs);
    return { ...item, sales: salesPart, cost: costPart, margin: money(salesPart - costPart) };
  });
  return {
    year,
    sales: yearSales,
    cogs: yearCogs,
    opex: thin ? money(prev.opex * 1.05) : money(payroll + extras),
    depreciation: prev.depreciation,
    interest: 0,
    mix: opMix.length && !thin ? opMix : scaledMix,
    cash: thin ? money(prev.cash + budgetSales * 0.12) : money(Math.max(prev.cash + cashSales - extras, cashMoves || prev.cash)),
    inventory: thin ? prev.inventory : inventory,
    receivables: thin ? money(prev.receivables * 0.6) : 0,
    grossFixed: prev.grossFixed,
    accumDep: money(prev.accumDep + prev.depreciation),
    payables: thin ? money(prev.payables * 0.8) : money(db.purchases.filter((item) => item.status !== "received").reduce((sum, item) => sum + item.total, 0)),
    shortDebt: 0,
    longDebt: 0,
    capital: prev.capital,
    retained: prev.retained,
    capex: 0
  };
}

export function dailySales(db: ErpDatabase, day?: string) {
  const rows = db.sales
    .filter((item) => item.status === "completed" && (!day || item.saleDate.slice(0, 10) === day))
    .flatMap((sale) => saleLines(sale, db.products, db.lots))
    .sort((a, b) => b.date.localeCompare(a.date) || a.saleNumber.localeCompare(b.saleNumber));
  return rows;
}

export function monthlySales(db: ErpDatabase) {
  const map = new Map<string, MonthRow & { refs: Set<string> }>();
  dailySales(db).forEach((row) => {
    const month = row.date.slice(0, 7);
    const current = map.get(month) ?? {
      month,
      label: monthLabel(month),
      sales: 0,
      cost: 0,
      margin: 0,
      budgetSales: monthBudget(db.projections, month).sales,
      budgetCost: monthBudget(db.projections, month).cost,
      tickets: 0,
      refs: new Set<string>()
    };
    current.sales += row.sales;
    current.cost += row.cost;
    current.refs.add(row.saleNumber);
    map.set(month, current);
  });
  return [...map.values()]
    .map((item) => ({
      month: item.month,
      label: item.label,
      sales: money(item.sales),
      cost: money(item.cost),
      margin: money(item.sales - item.cost),
      budgetSales: item.budgetSales,
      budgetCost: item.budgetCost,
      tickets: item.refs.size
    }))
    .sort((a, b) => b.month.localeCompare(a.month));
}

function shiftMonth(key: string, delta: number) {
  const [year, month] = key.split("-").map(Number);
  const date = new Date(year, month - 1 + delta, 1);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function sliceMonth(rows: DailyRow[], key: string) {
  const slice = rows.filter((item) => item.date.startsWith(key));
  const sales = money(slice.reduce((sum, item) => sum + item.sales, 0));
  const cost = money(slice.reduce((sum, item) => sum + item.cost, 0));
  return { sales, cost, margin: money(sales - cost), tickets: new Set(slice.map((item) => item.saleNumber)).size, rows: slice };
}

function pulseStatus(amount: number, previous: number, expense: boolean, loss = false): AccountPulse["status"] {
  if (loss) return "perdida";
  if (previous <= 0 && amount <= 0) return "estable";
  const up = amount > previous * 1.05;
  const down = amount < previous * 0.95;
  if (expense) return up ? "deterioro" : down ? "mejora" : "estable";
  return up ? "mejora" : down ? "deterioro" : "estable";
}

function buildSteering(
  db: ErpDatabase,
  month: string,
  dayRows: DailyRow[],
  last: IncomeStatement,
  live: YearAnchor,
  bestLine?: MixRow
): SteeringPack {
  const prevKey = shiftMonth(month, -1);
  const now = sliceMonth(dayRows, month);
  const prev = sliceMonth(dayRows, prevKey);
  const budget = monthBudget(db.projections, month);
  const payrollMonth = payrollOf(db.employees).employerCost;
  const extrasMonth = db.finance
    .filter((item) => item.type === "egreso" && item.date.startsWith(month) && item.category !== "Materia prima")
    .reduce((sum, item) => sum + item.amount, 0);
  const depMonth = money(live.depreciation / 12);
  const fixedCosts = money(payrollMonth + extrasMonth + depMonth);
  const thin = now.sales < Math.max(budget.sales, 1) * 0.05;
  const peSales = thin ? money(last.sales / 12) : now.sales;
  const peCost = thin ? money(last.cogs / 12) : now.cost;
  const contribution = money(peSales - peCost);
  const cmRatio = peSales > 0 ? contribution / peSales : 0;
  const breakEven = cmRatio > 0.01 ? money(fixedCosts / cmRatio) : 0;
  const gapToBreakEven = money(breakEven - now.sales);
  const safetyMargin = now.sales > 0 && breakEven > 0 ? pct(now.sales - breakEven, now.sales) : now.sales === 0 ? -100 : 0;
  const salesDelta = money(now.sales - prev.sales);
  const resultDelta = money(now.margin - prev.margin);
  const budgetGap = money(now.sales - budget.sales);

  let status: SteeringPack["status"] = "ganancia";
  if (now.sales <= 0) status = "alerta";
  else if (now.margin < 0) status = "perdida";
  else if (breakEven > 0 && now.sales < breakEven) status = "alerta";
  else if (breakEven > 0 && Math.abs(now.sales - breakEven) / breakEven < 0.03) status = "equilibrio";

  const statusLabel =
    status === "ganancia" ? "Ganancia" :
    status === "perdida" ? "Pérdida" :
    status === "equilibrio" ? "En equilibrio" : "Alerta";

  const salesWord = salesDelta > 0 ? "subieron" : salesDelta < 0 ? "bajaron" : "se mantuvieron";
  const resultWord = now.margin >= 0
    ? `cierra con ganancia de C$ ${now.margin.toLocaleString("es-NI")}`
    : `cierra con pérdida de C$ ${Math.abs(now.margin).toLocaleString("es-NI")}`;
  const peWord = !breakEven
    ? "No hay margen de contribución suficiente para calcular el punto de equilibrio."
    : gapToBreakEven > 0
      ? `Faltan C$ ${gapToBreakEven.toLocaleString("es-NI")} para cubrir costos fijos.`
      : `Hay holgura de C$ ${Math.abs(gapToBreakEven).toLocaleString("es-NI")} sobre el punto de equilibrio.`;
  const headline = `${monthLabel(month)} ${resultWord}. Las ventas ${salesWord} ${Math.abs(salesDeltaPctSafe(salesDelta, prev.sales))}% frente a ${monthLabel(prevKey)}. ${peWord}`;

  const nowMix = mixOf(now.rows);
  const prevMix = mixOf(prev.rows);
  const lineAccounts: AccountPulse[] = [
    ...nowMix.map((item) => {
      const previous = prevMix.find((row) => row.category === item.category)?.sales ?? 0;
      const delta = money(item.sales - previous);
      const loss = item.margin < 0;
      return {
        name: item.category,
        kind: "linea" as const,
        amount: item.sales,
        previous,
        delta,
        deltaPct: pct(delta, previous || 1),
        weight: item.weight,
        status: pulseStatus(item.sales, previous, false, loss),
        note: loss
          ? `Margen negativo C$ ${item.margin.toLocaleString("es-NI")}. Esta línea resta al mes.`
          : delta < 0
            ? `Ventas por debajo del mes anterior. Margen C$ ${item.margin.toLocaleString("es-NI")}.`
            : `Margen C$ ${item.margin.toLocaleString("es-NI")} · ${item.weight}% de las ventas del mes.`
      };
    }),
    ...prevMix
      .filter((item) => !nowMix.some((row) => row.category === item.category))
      .map((item) => ({
        name: item.category,
        kind: "linea" as const,
        amount: 0,
        previous: item.sales,
        delta: money(-item.sales),
        deltaPct: -100,
        weight: 0,
        status: "deterioro" as const,
        note: "Esta línea no tuvo ventas en el mes actual."
      }))
  ];

  const expNow = new Map<string, number>();
  const expPrev = new Map<string, number>();
  db.finance.forEach((item) => {
    if (item.type !== "egreso") return;
    const bag = item.date.startsWith(month) ? expNow : item.date.startsWith(prevKey) ? expPrev : null;
    if (bag) bag.set(item.category, money((bag.get(item.category) ?? 0) + item.amount));
  });
  const expenseAccounts: AccountPulse[] = [...new Set([...expNow.keys(), ...expPrev.keys()])].map((name) => {
    const amount = expNow.get(name) ?? 0;
    const previous = expPrev.get(name) ?? 0;
    const delta = money(amount - previous);
    return {
      name,
      kind: "gasto" as const,
      amount,
      previous,
      delta,
      deltaPct: pct(delta, previous || 1),
      weight: pct(amount, [...expNow.values()].reduce((sum, value) => sum + value, 0) || 1),
      status: pulseStatus(amount, previous, true),
      note: amount > previous
        ? `El gasto creció C$ ${delta.toLocaleString("es-NI")} respecto al mes anterior.`
        : amount === 0
          ? "No se registró este gasto en el mes actual."
          : `Gasto contenido. Variación C$ ${delta.toLocaleString("es-NI")}.`
    };
  });

  const debitNow = new Map<string, number>();
  const debitPrev = new Map<string, number>();
  db.accounting.forEach((item) => {
    const bag = item.entryDate.startsWith(month) ? debitNow : item.entryDate.startsWith(prevKey) ? debitPrev : null;
    if (bag) bag.set(item.debitAccount, money((bag.get(item.debitAccount) ?? 0) + item.debit));
  });
  const ledgerAccounts: AccountPulse[] = [...new Set([...debitNow.keys(), ...debitPrev.keys()])].map((name) => {
    const amount = debitNow.get(name) ?? 0;
    const previous = debitPrev.get(name) ?? 0;
    const delta = money(amount - previous);
    return {
      name,
      kind: "cuenta" as const,
      amount,
      previous,
      delta,
      deltaPct: pct(delta, previous || 1),
      weight: pct(amount, [...debitNow.values()].reduce((sum, value) => sum + value, 0) || 1),
      status: pulseStatus(amount, previous, name !== "Caja" && name !== "Banco" && name !== "Inventario"),
      note: `Movimiento al debe en ${name}.`
    };
  });

  const rank: Record<AccountPulse["status"], number> = { perdida: 0, deterioro: 1, estable: 2, mejora: 3 };
  const accounts = [...lineAccounts, ...expenseAccounts, ...ledgerAccounts]
    .sort((a, b) => rank[a.status] - rank[b.status] || Math.abs(b.delta) - Math.abs(a.delta))
    .slice(0, 10);

  const worst = accounts.find((item) => item.status === "perdida" || item.status === "deterioro");
  const actions: string[] = [];
  if (now.sales <= 0) {
    actions.push("Registrar y cerrar las ventas del mes. Sin captura no hay control de rumbo.");
  }
  if (now.margin < 0) {
    actions.push("El mes está en pérdida: congelar gastos que no generen venta en los próximos 30 días.");
  }
  if (breakEven > 0 && now.sales < breakEven) {
    actions.push(`Meta del próximo mes: vender al menos C$ ${breakEven.toLocaleString("es-NI")} para cubrir costos fijos.`);
  }
  if (worst?.kind === "linea") {
    actions.push(`Revisar precio o costo PEPS de ${worst.name}: es la línea que más está restando.`);
  }
  if (worst?.kind === "gasto") {
    actions.push(`Contener la cuenta de gasto ${worst.name} y no repetir el desvío el mes siguiente.`);
  }
  if (bestLine) {
    actions.push(
      now.margin >= 0
        ? `Escalar ${bestLine.category} (mayor margen) sin bajar precio. Es la palanca para ganar más de lo que se pierde.`
        : `Priorizar cotizaciones y cierre de ${bestLine.category} para recuperar el mes.`
    );
  }
  if (budget.sales > 0 && budgetGap < 0) {
    actions.push(`El mes va C$ ${Math.abs(budgetGap).toLocaleString("es-NI")} debajo del presupuesto. Convertir proformas abiertas la primera semana del mes siguiente.`);
  }
  if (now.margin > 0 && safetyMargin > 15) {
    actions.push("Hay holgura sobre el equilibrio: no relajar costos. Subir volumen de la línea líder y vigilar que el gasto no crezca más rápido que la venta.");
  }
  if (cmRatio <= 0.01) {
    actions.push("El margen de contribución es nulo o negativo. Subir precio o bajar costo variable antes de aumentar volumen: vender más ahora agranda la pérdida.");
  }
  if (!actions.length) {
    actions.push("Mantener el mix actual y comparar la primera quincena del mes siguiente contra este cierre.");
  }

  const monthSeries = Array.from({ length: 6 }, (_, index) => {
    const key = shiftMonth(month, index - 5);
    const slice = sliceMonth(dayRows, key);
    const rowBudget = monthBudget(db.projections, key);
    return {
      label: monthLabel(key).replace(/ \d{4}$/, ""),
      sales: slice.sales,
      cost: slice.cost,
      result: slice.margin,
      breakEven,
      presupuesto: rowBudget.sales
    };
  });

  return {
    month,
    label: monthLabel(month),
    prevLabel: monthLabel(prevKey),
    sales: now.sales,
    prevSales: prev.sales,
    salesDelta,
    salesDeltaPct: salesDeltaPctSafe(salesDelta, prev.sales),
    cost: now.cost,
    prevCost: prev.cost,
    result: now.margin,
    prevResult: prev.margin,
    resultDelta,
    budgetSales: budget.sales,
    budgetCost: budget.cost,
    budgetGap,
    vsBudgetPct: pct(budgetGap, budget.sales || 1),
    tickets: now.tickets,
    status,
    statusLabel,
    headline,
    contribution: money(now.sales - now.cost),
    cmRatio: money(cmRatio * 100),
    fixedCosts,
    breakEven,
    gapToBreakEven,
    safetyMargin,
    accounts,
    actions,
    nextMonthFocus: actions.slice(0, 3),
    monthSeries
  };
}

function salesDeltaPctSafe(delta: number, previous: number) {
  return previous ? pct(delta, previous) : delta === 0 ? 0 : 100;
}

export function yearlySales(db: ErpDatabase) {
  const liveYears = new Set(dailySales(db).map((item) => item.date.slice(0, 4)));
  const years = [...new Set([...yearAnchors.map((item) => String(item.year)), ...liveYears])].sort();
  return years.map((year) => {
    const live = dailySales(db).filter((item) => item.date.startsWith(year));
    if (live.length) {
      const sales = money(live.reduce((sum, item) => sum + item.sales, 0));
      const cost = money(live.reduce((sum, item) => sum + item.cost, 0));
      return { year, sales, cost, margin: money(sales - cost), source: "operación" as const, tickets: live.length };
    }
    const anchor = yearAnchors.find((item) => String(item.year) === year)!;
    return { year, sales: anchor.sales, cost: anchor.cogs, margin: money(anchor.sales - anchor.cogs), source: "cierre" as const, tickets: 0 };
  });
}

export function buildBooks(db: ErpDatabase) {
  const today = new Date().toISOString().slice(0, 10);
  const month = monthKey();
  const year = new Date().getFullYear();
  const dayRows = dailySales(db);
  const todayRows = dailySales(db, today);
  const months = monthlySales(db);
  const years = yearlySales(db);
  const live = liveYear(db, year);
  const series = [
    ...yearAnchors,
    live.sales || live.cogs ? live : { ...yearAnchors[yearAnchors.length - 1], year, sales: 0, cogs: 0 }
  ].filter((item, index, list) => list.findIndex((row) => row.year === item.year) === index)
    .sort((a, b) => a.year - b.year);

  const income = series.map(statementFromAnchor);
  const balances = series.map((item, index) => {
    if (item.year !== year) return balanceFromAnchor(item);
    const prev = series[index - 1] ?? item;
    const retained = money(prev.retained + income[index].retained);
    const draft = balanceFromAnchor({ ...item, retained });
    const cash = money(draft.totalLplusE - draft.inventory - draft.receivables - draft.netFixed);
    return balanceFromAnchor({ ...item, retained, cash });
  });
  const flows: CashFlow[] = series.map((item, index) => {
    const prevCash = index === 0 ? money(item.cash - income[index].retained) : series[index - 1].cash;
    const prevDebt = index === 0 ? item.shortDebt + item.longDebt + 180000 : series[index - 1].shortDebt + series[index - 1].longDebt;
    const debt = item.shortDebt + item.longDebt;
    const is = income[index];
    return cashOf(String(item.year), prevCash, is.net, is.retained, item.depreciation, money(Math.max(0, prevDebt - debt)), item.capex);
  });
  const eoaf: Eoaf[] = series.slice(1).map((item, index) => {
    const prev = series[index];
    const is = income[index + 1];
    const appCash = money(item.cash - prev.cash);
    const appDebt = money(Math.max(0, prev.shortDebt + prev.longDebt - (item.shortDebt + item.longDebt)));
    const origins = money(is.net + item.depreciation);
    const applications = money(appCash + item.capex + is.dividends + appDebt);
    return {
      period: `${prev.year}→${item.year}`,
      originNet: is.net,
      originDep: item.depreciation,
      origins,
      appCash,
      appCapex: item.capex,
      appDiv: is.dividends,
      appDebt,
      applications,
      residual: money(applications - origins)
    };
  });
  const ratios = income.map((item, index) => ratiosOf(item, balances[index]));
  const vertical = income.map((item) => ({
    period: item.period,
    cogs: pct(item.cogs, item.sales),
    gross: pct(item.gross, item.sales),
    opex: pct(item.opex + item.depreciation, item.sales),
    ebit: pct(item.ebit, item.sales),
    net: pct(item.net, item.sales)
  }));
  const horizontal = income.slice(1).map((item, index) => {
    const prev = income[index];
    const delta = (now: number, then: number) => pct(now - then, then);
    return {
      period: `${prev.period}→${item.period}`,
      sales: delta(item.sales, prev.sales),
      cogs: delta(item.cogs, prev.cogs),
      opex: delta(item.opex, prev.opex),
      net: delta(item.net, prev.net)
    };
  });
  const opMix = mixOf(dayRows);
  const bestLine = [...opMix].sort((a, b) => b.margin - a.margin)[0] ?? [...(live.mix.length ? live.mix : series[series.length - 1].mix)].sort((a, b) => b.margin - a.margin)[0];
  const materials = money(db.purchases.filter((item) => item.status === "received").reduce((sum, item) => sum + item.total / 1.15, 0));
  const labor = payrollOf(db.employees).employerCost;
  const opYearRows = dayRows.filter((item) => item.date.startsWith(String(year)));
  const opYear = {
    sales: money(opYearRows.reduce((sum, item) => sum + item.sales, 0)),
    cost: money(opYearRows.reduce((sum, item) => sum + item.cost, 0)),
    tickets: new Set(opYearRows.map((item) => item.saleNumber)).size
  };
  const monthNow = months.find((item) => item.month === month);
  const dayNow = {
    sales: money(todayRows.reduce((sum, item) => sum + item.sales, 0)),
    cost: money(todayRows.reduce((sum, item) => sum + item.cost, 0)),
    tickets: new Set(todayRows.map((item) => item.saleNumber)).size
  };

  const last = income[income.length - 1];
  const lastBs = balances[balances.length - 1];
  const lastRatio = ratios[ratios.length - 1];
  const lastFlow = flows[flows.length - 1];
  const yearMixLines = [...new Set(series.flatMap((item) => item.mix.map((row) => row.category)))];
  const yearMix = yearMixLines.map((category) => ({
    category,
    values: series.map((item) => item.mix.find((row) => row.category === category)?.sales ?? 0)
  }));
  const cashWeight = pct(lastBs.cash, lastBs.totalAssets);
  const currentWeight = pct(lastBs.current, lastBs.totalAssets);
  const fixedWeight = pct(lastBs.netFixed, lastBs.totalAssets);
  const worn = pct(lastBs.accumDep, lastBs.grossFixed);
  const firstRatio = ratios[0];
  const steering = buildSteering(db, month, dayRows, last, live, bestLine);
  const diagnosis = {
    reading: steering.headline,
    strengths: [
      `Ventas ${last.period}: C$ ${last.sales.toLocaleString("es-NI")} · margen neto ${lastRatio.netMargin}%.`,
      `Línea de mayor beneficio: ${bestLine?.category ?? "—"}${bestLine ? ` (${bestLine.weight}% de las ventas)` : ""}.`,
      `Autonomía ${lastRatio.autonomy}% · deuda sobre activo ${lastRatio.debtAsset}%.`,
      `Flujo libre ${lastFlow.fcl.toLocaleString("es-NI")} C$ · hay holgura para reponer equipo.`
    ],
    weaknesses: [
      worn > 60 ? `El equipo está depreciado al ${worn}%: falta CAPEX de reemplazo.` : `El CAPEX sigue por debajo de la depreciación acumulada.`,
      cashWeight > 70 ? `Caja ociosa: ${cashWeight}% del activo no está en capacidad productiva.` : `Hay que vigilar que la caja no se estanque.`,
      lastRatio.assetTurn < firstRatio.assetTurn ? `La rotación de activos bajó de ${firstRatio.assetTurn} a ${lastRatio.assetTurn} veces.` : `La rotación de activos se mantiene.`
    ],
    risks: [
      lastRatio.coverage == null ? `Ya no hay deuda: el riesgo no es de impago, es de no reinvertir.` : `La cobertura de intereses es ${lastRatio.coverage} veces.`,
      `Concentración en ${bestLine?.category ?? "una línea"}: es la fortaleza comercial y también el riesgo de mix.`,
      last.interest === 0 ? `Estructura de capital conservadora: el apalancamiento ya no aporta al ROE.` : `Todavía hay servicio de deuda.`
    ],
    opportunities: [
      `Usar el FCL para modernizar taller y showroom, no dejarlo en bancos al 0%.`,
      `Proteger y escalar ${bestLine?.category ?? "la línea líder"}.`,
      `Colocar el excedente de caja que no vaya a CAPEX en un depósito a plazo.`
    ]
  };

  return {
    today,
    month,
    year,
    dayRows,
    todayRows,
    months,
    years,
    live,
    series,
    income,
    balances,
    flows,
    eoaf,
    ratios,
    vertical,
    horizontal,
    mix: opMix.length ? opMix : live.mix,
    yearMix,
    bestLine,
    materials,
    labor,
    overhead: money(Math.max(0, live.opex - labor * Math.max(1, new Date().getMonth() + 1))),
    monthNow,
    dayNow,
    opYear,
    cashWeight,
    currentWeight,
    diagnosis,
    steering
  };
}

export type BooksPack = ReturnType<typeof buildBooks>;
