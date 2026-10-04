import { useMemo, useState } from "react";
import { Area, AreaChart, Bar, CartesianGrid, Cell, ComposedChart, Legend, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Money, StatusPill } from "./Ui";
import { buildBooks, IR_CORP, PAYOUT, SHARES, type AccountPulse, type SteeringPack } from "../lib/booksNi";
import { monthLabel } from "../lib/dgiNi";
import { useErp } from "../store/erpStore";

const tabs = [
  { id: "rumbo", label: "Rumbo del mes" },
  { id: "financiera", label: "Estados" },
  { id: "gerencial", label: "Gerencial" },
  { id: "costos", label: "Costos" }
] as const;

const palette = ["#0a92c8", "#2f9b73", "#e84b5f", "#f59e0b", "#8b5cf6"];

export function BooksStudio({ start = "gerencial" }: { start?: (typeof tabs)[number]["id"] }) {
  const { db } = useErp();
  const books = useMemo(() => buildBooks(db), [db]);
  const [tab, setTab] = useState<(typeof tabs)[number]["id"]>(start);
  const last = books.income[books.income.length - 1];
  const lastBs = books.balances[books.balances.length - 1];
  const lastRatio = books.ratios[books.ratios.length - 1];
  const steer = books.steering;

  return (
    <section className="space-y-4 rounded-2xl bg-white p-5 shadow-soft dark:bg-slate-900">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand-700">Finanzas</p>
          <h2 className="mt-1 font-black">Control de resultado y punto de equilibrio</h2>
          <p className="text-sm text-slate-500">IR {IR_CORP * 100}%. Utilidades retenidas {(1 - PAYOUT) * 100}%.</p>
        </div>
        <StatusPill tone="ok">{monthLabel(books.month)}</StatusPill>
      </div>

      <div className="flex flex-wrap gap-2">
        {tabs.map((item) => (
          <button
            key={item.id}
            type="button"
            onClick={() => setTab(item.id)}
            className={`rounded-full px-4 py-2 text-sm font-bold ${tab === item.id ? "bg-brand-600 text-white" : "bg-slate-100 text-slate-700 dark:bg-white/10 dark:text-slate-200"}`}
          >
            {item.label}
          </button>
        ))}
      </div>

      {tab === "rumbo" && <SteeringBoard steer={steer} />}

      {tab === "gerencial" && (
        <div className="space-y-4">
          <div className="grid gap-3 sm:grid-cols-3">
            <Mini label="Hoy · ventas" value={books.dayNow.sales} note={`${books.dayNow.tickets} facturas`} />
            <Mini label="Mes · ventas" value={books.monthNow?.sales ?? 0} note={books.monthNow ? `${books.monthNow.tickets} tickets` : "Sin movimiento"} />
            <Mini label="Año · ventas" value={books.opYear.sales} note={`${books.opYear.tickets} facturas de operación`} />
          </div>
          <p className="text-sm font-semibold text-slate-600 dark:text-slate-300">
            Línea de mayor beneficio: <strong>{books.bestLine?.category ?? "—"}</strong>
            {books.bestLine ? ` · margen ${books.bestLine.weight}% de las ventas` : ""}
          </p>
          <Grid
            title="Ventas diarias (ticket a ticket)"
            head={["Fecha", "Factura", "Línea", "Venta", "Costo", "Margen"]}
            rows={books.dayRows.slice(0, 16).map((item) => [item.date, item.saleNumber, item.line, item.sales, item.cost, item.margin])}
          />
          <Grid
            title="Cierre del mes · real vs presupuesto"
            head={["Mes", "Ventas", "Costo", "Presupuesto", "Desvío"]}
            rows={books.months.map((item) => [item.label, item.sales, item.cost, item.budgetSales, item.sales - item.budgetSales])}
          />
          <Grid
            title="Cierre del año"
            head={["Año", "Origen", "Ventas", "Costo", "Margen"]}
            rows={books.years.map((item) => [item.year, item.source, item.sales, item.cost, item.margin])}
          />
        </div>
      )}

      {tab === "financiera" && (
        <div className="space-y-4">
          <p className="rounded-xl bg-cyan-50 px-4 py-3 text-sm text-cyan-950 dark:bg-cyan-500/10 dark:text-cyan-50">
            {books.diagnosis.reading}
          </p>
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <Mini label="Ventas" value={last.sales} />
            <Mini label="Utilidad neta" value={last.net} />
            <Mini label="Caja" value={lastBs.cash} />
            <Mini label="FCL" value={books.flows[books.flows.length - 1].fcl} note="Flujo de efectivo libre" />
          </div>
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <Ratio label="Margen neto" value={lastRatio.netMargin} />
            <Ratio label="ROA" value={lastRatio.roa} />
            <Ratio label="ROE" value={lastRatio.roe} />
            <Ratio label="Activo corriente" value={books.currentWeight} />
          </div>

          <div className="grid gap-3 lg:grid-cols-2">
            <ChartCard title="Evolución de ingresos, costos y utilidad neta">
              <AreaChart data={books.income.map((item) => ({ periodo: item.period, ventas: item.sales, costo: item.cogs, neto: item.net }))}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,.22)" />
                <XAxis dataKey="periodo" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Area dataKey="ventas" name="Ventas" stroke="#0a92c8" fill="#72d4ef" fillOpacity={0.18} />
                <Area dataKey="costo" name="Costo" stroke="#e84b5f" fill="#e84b5f" fillOpacity={0.1} />
                <Area dataKey="neto" name="Utilidad neta" stroke="#2f9b73" fill="#2f9b73" fillOpacity={0.12} />
              </AreaChart>
            </ChartCard>
            <ChartCard title="Activo, pasivo y patrimonio">
              <LineChart data={books.balances.map((item) => ({ periodo: item.period, activo: item.totalAssets, pasivo: item.totalLiab, patrimonio: item.equity }))}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,.22)" />
                <XAxis dataKey="periodo" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line dataKey="activo" name="Activo" stroke="#0a92c8" strokeWidth={2} />
                <Line dataKey="pasivo" name="Pasivo" stroke="#e84b5f" strokeWidth={2} />
                <Line dataKey="patrimonio" name="Patrimonio" stroke="#2f9b73" strokeWidth={2} />
              </LineChart>
            </ChartCard>
            <ChartCard title="Caja y flujo libre">
              <AreaChart data={books.flows.map((item) => ({ periodo: item.period, caja: item.closing, fcl: item.fcl }))}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,.22)" />
                <XAxis dataKey="periodo" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Area dataKey="caja" name="Caja" stroke="#0a92c8" fill="#72d4ef" fillOpacity={0.2} />
                <Area dataKey="fcl" name="FCL" stroke="#f59e0b" fill="#f59e0b" fillOpacity={0.12} />
              </AreaChart>
            </ChartCard>
            <article className="rounded-xl border border-slate-100 p-3 dark:border-white/10">
              <p className="text-xs font-bold uppercase tracking-wide text-slate-400">Mix por línea · {last.period}</p>
              <div className="mt-2 h-[220px]">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={books.series[books.series.length - 1].mix.map((item) => ({ name: item.category, value: item.sales }))} innerRadius={50} outerRadius={80} dataKey="value" paddingAngle={3}>
                      {books.series[books.series.length - 1].mix.map((item, index) => (
                        <Cell key={item.category} fill={palette[index % palette.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </article>
          </div>

          <Grid
            title="Ingresos por línea de negocio"
            head={["Línea", ...books.series.map((item) => String(item.year))]}
            rows={books.yearMix.map((item) => [item.category, ...item.values])}
          />
          <Grid
            title="Estado de resultados"
            head={["Concepto", ...books.income.map((item) => item.period)]}
            rows={[
              ["Ventas", ...books.income.map((item) => item.sales)],
              ["Costo de ventas", ...books.income.map((item) => item.cogs)],
              ["Utilidad bruta", ...books.income.map((item) => item.gross)],
              ["Gastos de operación", ...books.income.map((item) => item.opex)],
              ["Depreciación", ...books.income.map((item) => item.depreciation)],
              ["Utilidad de operación", ...books.income.map((item) => item.ebit)],
              ["Intereses", ...books.income.map((item) => item.interest)],
              ["IR 30%", ...books.income.map((item) => item.tax)],
              ["Utilidad neta", ...books.income.map((item) => item.net)],
              ["Dividendos 40%", ...books.income.map((item) => item.dividends)],
              ["Utilidades retenidas", ...books.income.map((item) => item.retained)]
            ]}
          />
          <Grid
            title="Balance general"
            head={["Concepto", ...books.balances.map((item) => item.period)]}
            rows={[
              ["Caja y bancos", ...books.balances.map((item) => item.cash)],
              ["Inventario", ...books.balances.map((item) => item.inventory)],
              ["Cuentas por cobrar", ...books.balances.map((item) => item.receivables)],
              ["Activo corriente", ...books.balances.map((item) => item.current)],
              ["Equipo bruto", ...books.balances.map((item) => item.grossFixed)],
              ["Depreciación acumulada", ...books.balances.map((item) => -item.accumDep)],
              ["Activo fijo neto", ...books.balances.map((item) => item.netFixed)],
              ["Total activos", ...books.balances.map((item) => item.totalAssets)],
              ["Total pasivo", ...books.balances.map((item) => item.totalLiab)],
              ["Capital social", ...books.balances.map((item) => item.capital)],
              ["Utilidades retenidas", ...books.balances.map((item) => item.retained)],
              ["Patrimonio", ...books.balances.map((item) => item.equity)],
              ["Cuadre", ...books.balances.map((item) => item.difference)]
            ]}
          />
          <Grid
            title="Flujo de efectivo operativo y libre"
            head={["Concepto", ...books.flows.map((item) => item.period)]}
            rows={[
              ["Saldo inicial", ...books.flows.map((item) => item.opening)],
              ["Utilidad retenida", ...books.flows.map((item) => item.retained)],
              ["(+) Depreciación", ...books.flows.map((item) => item.depreciation)],
              ["(−) Amortización", ...books.flows.map((item) => item.loanPay)],
              ["FEO (UN + Dep)", ...books.flows.map((item) => item.feo)],
              ["CAPEX", ...books.flows.map((item) => item.capex)],
              ["FCL (FEO − CAPEX)", ...books.flows.map((item) => item.fcl)],
              ["Saldo final", ...books.flows.map((item) => item.closing)]
            ]}
          />
          <Grid
            title="Estado de origen y aplicación de fondos"
            head={["Concepto", ...books.eoaf.map((item) => item.period)]}
            rows={[
              ["Origen: utilidad neta", ...books.eoaf.map((item) => item.originNet)],
              ["Origen: depreciación", ...books.eoaf.map((item) => item.originDep)],
              ["Total orígenes", ...books.eoaf.map((item) => item.origins)],
              ["Aplicación: aumento de caja", ...books.eoaf.map((item) => item.appCash)],
              ["Aplicación: CAPEX", ...books.eoaf.map((item) => item.appCapex)],
              ["Aplicación: dividendos", ...books.eoaf.map((item) => item.appDiv)],
              ["Aplicación: baja de pasivo", ...books.eoaf.map((item) => item.appDebt)]
            ]}
          />
          <Grid
            title="Razones financieras"
            head={["Indicador", ...books.ratios.map((item) => item.period)]}
            rows={[
              ["Razón corriente", ...books.ratios.map((item) => item.current ?? "n.a.")],
              ["Prueba ácida", ...books.ratios.map((item) => item.acid ?? "n.a.")],
              ["Deuda / activo %", ...books.ratios.map((item) => item.debtAsset)],
              ["Deuda / patrimonio %", ...books.ratios.map((item) => item.debtEquity)],
              ["Autonomía %", ...books.ratios.map((item) => item.autonomy)],
              ["Solvencia", ...books.ratios.map((item) => item.solvency ?? "n.a.")],
              ["Cobertura intereses", ...books.ratios.map((item) => item.coverage ?? "n.a.")],
              ["Rotación activos", ...books.ratios.map((item) => item.assetTurn)],
              ["Rotación activo fijo", ...books.ratios.map((item) => item.fixedTurn)],
              ["Días de cobro", ...books.ratios.map((item) => item.collectDays)],
              ["Margen bruto %", ...books.ratios.map((item) => item.grossMargin)],
              ["Margen operacional %", ...books.ratios.map((item) => item.opMargin)],
              ["Margen neto %", ...books.ratios.map((item) => item.netMargin)],
              ["ROA %", ...books.ratios.map((item) => item.roa)],
              ["ROE %", ...books.ratios.map((item) => item.roe)],
              [`UPA (C$ / ${SHARES.toLocaleString("es-NI")})`, ...books.ratios.map((item) => item.upa)],
              ["DPA (C$)", ...books.ratios.map((item) => item.dpa)],
              ["Valor en libros", ...books.ratios.map((item) => item.book)],
              ["Payout %", ...books.ratios.map((item) => item.payout)]
            ]}
          />
          <Grid
            title="Análisis vertical (% ventas)"
            head={["Concepto", ...books.vertical.map((item) => item.period)]}
            rows={[
              ["Costo de ventas", ...books.vertical.map((item) => item.cogs)],
              ["Utilidad bruta", ...books.vertical.map((item) => item.gross)],
              ["Gastos de operación", ...books.vertical.map((item) => item.opex)],
              ["Utilidad de operación", ...books.vertical.map((item) => item.ebit)],
              ["Utilidad neta", ...books.vertical.map((item) => item.net)]
            ]}
          />
          <Grid
            title="Análisis horizontal (variación %)"
            head={["Concepto", ...books.horizontal.map((item) => item.period)]}
            rows={[
              ["Ventas", ...books.horizontal.map((item) => item.sales)],
              ["Costo de ventas", ...books.horizontal.map((item) => item.cogs)],
              ["Gastos de operación", ...books.horizontal.map((item) => item.opex)],
              ["Utilidad neta", ...books.horizontal.map((item) => item.net)]
            ]}
          />

          <div className="grid gap-3 md:grid-cols-2">
            <Note title="Fortalezas" items={books.diagnosis.strengths} tone="ok" />
            <Note title="Debilidades" items={books.diagnosis.weaknesses} tone="warn" />
            <Note title="Riesgos" items={books.diagnosis.risks} tone="bad" />
            <Note title="Oportunidades" items={books.diagnosis.opportunities} tone="ok" />
          </div>
          <p className="text-[11px] text-slate-400">
            IR {IR_CORP * 100}%. Dividendos {PAYOUT * 100}%. Utilidades retenidas {(1 - PAYOUT) * 100}% para reinversión. {SHARES.toLocaleString("es-NI")} participaciones.
          </p>
        </div>
      )}

      {tab === "costos" && (
        <div className="space-y-4">
          <div className="grid gap-3 sm:grid-cols-3">
            <Mini label="Materiales" value={books.materials} />
            <Mini label="Mano de obra (mes)" value={books.labor} />
            <Mini label="Costo de ventas del año" value={books.opYear.cost} note="Valuación PEPS de facturas" />
          </div>
          <Grid
            title="Costo por línea"
            head={["Línea", "Ventas", "Costo PEPS", "Margen", "% ventas"]}
            rows={books.mix.map((item) => [item.category, item.sales, item.cost, item.margin, item.weight])}
          />
        </div>
      )}
    </section>
  );
}

function SteeringBoard({ steer }: { steer: SteeringPack }) {
  const tone = steer.status === "ganancia" ? "ok" : steer.status === "perdida" ? "bad" : "warn";
  const kindLabel = { linea: "Línea", gasto: "Gasto", cuenta: "Cuenta" } as const;
  const statusLabel = { mejora: "Mejora", estable: "Estable", deterioro: "Deterioro", perdida: "Pérdida" } as const;
  const statusTone = (status: AccountPulse["status"]): "ok" | "warn" | "bad" | "neutral" =>
    status === "mejora" ? "ok" : status === "estable" ? "neutral" : status === "deterioro" ? "warn" : "bad";

  return (
    <div className="space-y-4">
      <article className={`rounded-xl px-4 py-3 ${tone === "ok" ? "bg-emerald-50 text-emerald-950 dark:bg-emerald-500/10 dark:text-emerald-50" : tone === "bad" ? "bg-rose-50 text-rose-950 dark:bg-rose-500/10 dark:text-rose-50" : "bg-amber-50 text-amber-950 dark:bg-amber-500/10 dark:text-amber-50"}`}>
        <div className="flex flex-wrap items-center gap-2">
          <StatusPill tone={tone}>{steer.statusLabel}</StatusPill>
          <p className="text-sm font-semibold">{steer.label} vs {steer.prevLabel}</p>
        </div>
        <p className="mt-2 text-sm">{steer.headline}</p>
      </article>

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <Mini
          label={`Ventas ${steer.label}`}
          value={steer.sales}
          note={`${steer.tickets} facturas · ${steer.salesDelta >= 0 ? "+" : ""}${steer.salesDeltaPct}% vs mes anterior`}
        />
        <Mini
          label={steer.result >= 0 ? "Ganancia del mes" : "Pérdida del mes"}
          value={steer.result}
          note={`${steer.resultDelta >= 0 ? "+" : ""}${steer.resultDelta.toLocaleString("es-NI")} vs ${steer.prevLabel}`}
        />
        <Mini
          label="Punto de equilibrio"
          value={steer.breakEven}
          note={steer.breakEven ? `Costos fijos C$ ${steer.fixedCosts.toLocaleString("es-NI")} · MC ${steer.cmRatio}%` : "Sin margen de contribución"}
        />
        <Mini
          label={steer.gapToBreakEven > 0 ? "Falta para equilibrar" : "Holgura sobre el PE"}
          value={Math.abs(steer.gapToBreakEven)}
          note={`Margen de seguridad ${steer.safetyMargin}%`}
        />
      </div>

      <div className="grid gap-3 lg:grid-cols-2">
        <ChartCard title="Ventas, resultado y punto de equilibrio (6 meses)">
          <ComposedChart data={steer.monthSeries}>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,.22)" />
            <XAxis dataKey="label" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="sales" name="Ventas" fill="#0a92c8" />
            <Bar dataKey="result" name="Resultado" fill="#2f9b73" />
            <Line type="monotone" dataKey="breakEven" name="Punto de equilibrio" stroke="#e84b5f" strokeWidth={2} />
          </ComposedChart>
        </ChartCard>
        <article className="rounded-xl border border-slate-100 p-4 dark:border-white/10">
          <p className="text-xs font-bold uppercase tracking-wide text-slate-400">Cómo se calcula el equilibrio</p>
          <dl className="mt-3 space-y-2 text-sm">
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Costos fijos del mes</dt><dd className="font-semibold"><Money value={steer.fixedCosts} /></dd></div>
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Margen de contribución</dt><dd className="font-semibold">{steer.cmRatio}%</dd></div>
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Ventas de equilibrio</dt><dd className="font-semibold"><Money value={steer.breakEven} /></dd></div>
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Ventas reales</dt><dd className="font-semibold"><Money value={steer.sales} /></dd></div>
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Presupuesto del mes</dt><dd className="font-semibold"><Money value={steer.budgetSales} /></dd></div>
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Desvío vs presupuesto</dt><dd className="font-semibold"><Money value={steer.budgetGap} /></dd></div>
          </dl>
        </article>
      </div>

      <div className="overflow-x-auto rounded-xl border border-slate-100 dark:border-white/10">
        <p className="px-3 py-2 text-xs font-bold uppercase tracking-wide text-slate-400">Cuentas y líneas que mueven el mes</p>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-[11px] uppercase text-slate-400">
              <th className="p-2">Origen</th>
              <th className="p-2">Cuenta</th>
              <th className="p-2 text-right">Este mes</th>
              <th className="p-2 text-right">Mes anterior</th>
              <th className="p-2 text-right">Variación</th>
              <th className="p-2">Estado</th>
              <th className="p-2">Lectura</th>
            </tr>
          </thead>
          <tbody>
            {steer.accounts.map((item) => (
              <tr key={`${item.kind}-${item.name}`} className="border-t border-slate-100 dark:border-white/10">
                <td className="p-2 text-slate-500">{kindLabel[item.kind]}</td>
                <td className="p-2 font-semibold">{item.name}</td>
                <td className="p-2 text-right tabular-nums">{item.amount.toLocaleString("es-NI", { maximumFractionDigits: 2 })}</td>
                <td className="p-2 text-right tabular-nums">{item.previous.toLocaleString("es-NI", { maximumFractionDigits: 2 })}</td>
                <td className="p-2 text-right tabular-nums">{item.delta.toLocaleString("es-NI", { maximumFractionDigits: 2 })}</td>
                <td className="p-2"><StatusPill tone={statusTone(item.status)}>{statusLabel[item.status]}</StatusPill></td>
                <td className="p-2 text-slate-600 dark:text-slate-300">{item.note}</td>
              </tr>
            ))}
            {!steer.accounts.length && (
              <tr><td className="p-3 text-sm text-slate-500" colSpan={7}>Sin movimientos suficientes para comparar cuentas este mes.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        <article className="rounded-xl bg-slate-50 p-4 dark:bg-slate-950">
          <p className="text-xs font-bold uppercase tracking-wide text-slate-400">Comparativo para el siguiente mes</p>
          <dl className="mt-3 space-y-2 text-sm">
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Ventas {steer.label}</dt><dd className="font-semibold"><Money value={steer.sales} /></dd></div>
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Ventas {steer.prevLabel}</dt><dd className="font-semibold"><Money value={steer.prevSales} /></dd></div>
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Resultado {steer.label}</dt><dd className="font-semibold"><Money value={steer.result} /></dd></div>
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Resultado {steer.prevLabel}</dt><dd className="font-semibold"><Money value={steer.prevResult} /></dd></div>
            <div className="flex justify-between gap-3"><dt className="text-slate-500">Costo {steer.label}</dt><dd className="font-semibold"><Money value={steer.cost} /></dd></div>
          </dl>
        </article>
        <article className="rounded-xl bg-slate-50 p-4 dark:bg-slate-950">
          <p className="text-xs font-bold uppercase tracking-wide text-slate-400">Qué hacer el próximo mes</p>
          <ol className="mt-2 list-decimal space-y-2 pl-5 text-sm">
            {steer.actions.map((item) => <li key={item}>{item}</li>)}
          </ol>
        </article>
      </div>
    </div>
  );
}

function ChartCard({ title, children }: { title: string; children: React.ReactElement }) {
  return (
    <article className="rounded-xl border border-slate-100 p-3 dark:border-white/10">
      <p className="text-xs font-bold uppercase tracking-wide text-slate-400">{title}</p>
      <div className="mt-2 h-[220px]">
        <ResponsiveContainer width="100%" height="100%">
          {children}
        </ResponsiveContainer>
      </div>
    </article>
  );
}

function Note({ title, items, tone }: { title: string; items: string[]; tone: "ok" | "warn" | "bad" }) {
  const skin = tone === "ok" ? "bg-emerald-50 dark:bg-emerald-500/10" : tone === "warn" ? "bg-amber-50 dark:bg-amber-500/10" : "bg-rose-50 dark:bg-rose-500/10";
  return (
    <article className={`rounded-xl p-4 ${skin}`}>
      <p className="text-xs font-bold uppercase tracking-wide">{title}</p>
      <ul className="mt-2 list-disc space-y-1 pl-4 text-sm">
        {items.map((item) => <li key={item}>{item}</li>)}
      </ul>
    </article>
  );
}
function Mini({ label, value, note }: { label: string; value: number; note?: string }) {
  return (
    <article className="rounded-xl bg-slate-50 p-3 dark:bg-slate-950">
      <p className="text-xs text-slate-500">{label}</p>
      <p className="mt-1 text-lg font-black"><Money value={value} /></p>
      {note && <p className="text-[11px] text-slate-400">{note}</p>}
    </article>
  );
}

function Ratio({ label, value }: { label: string; value: number }) {
  return (
    <article className="rounded-xl bg-slate-50 p-3 dark:bg-slate-950">
      <p className="text-xs text-slate-500">{label}</p>
      <p className="mt-1 text-lg font-black">{value.toFixed(1)}%</p>
    </article>
  );
}

function Grid({ title, head, rows }: { title: string; head: string[]; rows: Array<Array<string | number>> }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-slate-100 dark:border-white/10">
      <p className="px-3 py-2 text-xs font-bold uppercase tracking-wide text-slate-400">{title}</p>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-[11px] uppercase text-slate-400">
            {head.map((item) => <th key={item} className="p-2">{item}</th>)}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, index) => (
            <tr key={index} className="border-t border-slate-100 dark:border-white/10">
              {row.map((cell, cellIndex) => (
                <td key={cellIndex} className={`p-2 ${cellIndex === 0 ? "font-semibold" : "text-right tabular-nums"}`}>
                  {typeof cell === "number" ? cell.toLocaleString("es-NI", { maximumFractionDigits: 2 }) : cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
