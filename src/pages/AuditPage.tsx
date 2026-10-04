import { useMemo, useState, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { Fingerprint, ShieldAlert, ShieldCheck, Users } from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";
import { inputClass, Money, PageHeader, StatusPill } from "../components/Ui";
import { verifyChain } from "../lib/auditSeal";
import { useErp } from "../store/erpStore";
import type { AuditEvent } from "../types/erp";

type Tab = "bitacora" | "cadena" | "expediente" | "casos" | "anomalias";

export default function AuditPage() {
  const { db, stockOf } = useErp();
  const { user } = useAuth();
  const [tab, setTab] = useState<Tab>("bitacora");
  const [q, setQ] = useState("");
  const [moduleFilter, setModuleFilter] = useState("todos");
  const [saleRef, setSaleId] = useState(db.sales[0]?.saleNumber ?? "");

  const chain = useMemo(() => verifyChain(db.audit), [db.audit]);
  const modules = useMemo(() => ["todos", ...new Set(db.audit.map((item) => item.module))], [db.audit]);
  const filtered = useMemo(() => {
    return db.audit.filter((item) => {
      const blob = `${item.userName} ${item.action} ${item.module} ${item.detail} ${item.reference ?? ""}`.toLowerCase();
      const okQ = !q.trim() || blob.includes(q.trim().toLowerCase());
      const okM = moduleFilter === "todos" || item.module === moduleFilter;
      return okQ && okM;
    });
  }, [db.audit, q, moduleFilter]);

  const byUser = useMemo(() => {
    const map = new Map<string, number>();
    db.audit.forEach((item) => map.set(item.userName, (map.get(item.userName) ?? 0) + 1));
    return [...map.entries()].sort((a, b) => b[1] - a[1]);
  }, [db.audit]);

  const sale = db.sales.find((item) => item.saleNumber === saleRef) ?? db.sales[0];
  const dossier = useMemo(() => {
    if (!sale) return [];
    const ref = sale.saleNumber;
    const kardex = db.kardex.filter((item) => item.reason.includes(ref));
    const entry = db.accounting.find((item) => item.referenceId === sale.id || item.description.includes(ref));
    const cash = db.cash.find((item) => item.concept.includes(ref));
    const trail = db.audit.filter((item) => (item.reference ?? item.detail).includes(ref));
    return [
      { step: "1", actor: sale.createdBy, message: `Venta ${ref}`, ok: true, note: `${sale.clientName} · IVA C$ ${sale.taxAmount}` },
      { step: "2", actor: "Bodega", message: "Sale el lote viejo", ok: kardex.length > 0, note: kardex[0] ? `${kardex[0].type} costo ${kardex[0].unitCost}` : "Sin kardex ligado" },
      { step: "3", actor: "Contabilidad", message: "Asiento en cuadre", ok: Boolean(entry) && entry?.debit === entry?.credit, note: entry ? `${entry.entryNumber} débito=crédito` : "Sin asiento" },
      { step: "4", actor: "Caja", message: "Cobro", ok: Boolean(cash), note: cash ? `${cash.account} ${cash.type}` : "Sin movimiento de tesorería" },
      { step: "5", actor: "Auditoría", message: "Huella", ok: trail.length > 0, note: trail.length ? `${trail.length} huellas` : "Sin bitácora" }
    ];
  }, [db, sale]);

  const anomalies = useMemo(() => {
    const rows: { tone: "warn" | "bad" | "ok"; title: string; detail: string; req: string }[] = [];
    if (!chain.ok) {
      rows.push({ tone: "bad", title: "Cadena de integridad rota", detail: `${chain.broken.length} evento(s) no coinciden con el sello anterior.`, req: "Sello" });
    } else {
      rows.push({ tone: "ok", title: "Cadena íntegra", detail: `${chain.sealed} eventos verificados de punta a punta.`, req: "Sello" });
    }
    const debit = db.accounting.reduce((sum, item) => sum + item.debit, 0);
    const credit = db.accounting.reduce((sum, item) => sum + item.credit, 0);
    if (Math.abs(debit - credit) >= 0.01) {
      rows.push({ tone: "bad", title: "Descuadre partida doble", detail: `Débito C$ ${debit.toFixed(2)} ≠ crédito C$ ${credit.toFixed(2)}.`, req: "Contabilidad" });
    }
    db.products.filter((item) => stockOf(item.id) < item.minQuantity).forEach((item) => {
      rows.push({ tone: "warn", title: `Stock crítico · ${item.code}`, detail: `${item.name} por debajo del mínimo ${item.minQuantity}.`, req: "Bodega" });
    });
    const writesByGuest = db.audit.filter((item) => item.userName.toLowerCase().includes("invitado") && !["consulta", "inicio"].includes(item.action));
    if (writesByGuest.length) {
      rows.push({ tone: "bad", title: "Invitado con mutación", detail: writesByGuest.map((item) => item.action).join(", "), req: "Acceso" });
    } else {
      rows.push({ tone: "ok", title: "Invitado solo consulta", detail: "Gerencia ve, no modifica inventario ni caja.", req: "Acceso" });
    }
    return rows;
  }, [chain, db.accounting, db.audit, db.products, stockOf]);

  const constancia = useMemo(() => {
    const lines = [
      "CONSTANCIA DE AUDITORÍA · Instalaciones Raquel",
      `Emitida para ${user?.name ?? "gerencia"} · ${new Date().toLocaleString("es-NI")}`,
      `Cadena: ${chain.ok ? "ÍNTEGRA" : "ROTA"} · ${db.audit.length} eventos`,
      "",
      ...db.audit.slice(0, 12).map((item) => `${item.at.slice(0, 16)} | ${item.userName} | ${item.action} | ${item.detail} | ${item.hash ?? "—"}`)
    ];
    return lines.join("\n");
  }, [chain.ok, db.audit, user?.name]);

  return (
    <motion.div className="space-y-5" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }}>
      <PageHeader
        kicker="Gobierno"
        title="Auditoría"
        subtitle="Quién tocó qué, cuándo, y si el sello sigue cerrado."
        actions={
          <div className="flex flex-wrap gap-2">
            <Link to="/datos"><Button variant="secondary">Base de datos</Button></Link>
            <Link to="/ers"><Button variant="ghost">Requerimientos</Button></Link>
          </div>
        }
      />

      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-zinc-900 via-slate-800 to-brand-800 p-5 text-white shadow-soft">
        <div className="relative grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <Pulse icon={<ShieldCheck size={18} />} label="Eventos" value={String(db.audit.length)} hint="Bitácora" />
          <Pulse icon={<Fingerprint size={18} />} label="Integridad" value={chain.ok ? "Íntegra" : "Rota"} hint={chain.ok ? "Sello encadenado" : `${chain.broken.length} roturas`} />
          <Pulse icon={<Users size={18} />} label="Personas" value={String(byUser.length)} hint="Quién operó" />
          <Pulse icon={<ShieldAlert size={18} />} label="Alertas" value={String(anomalies.filter((item) => item.tone !== "ok").length)} hint="Control interno" />
        </div>
      </section>

      <div className="flex flex-wrap gap-2">
        {(
          [
            ["bitacora", "Bitácora"],
            ["cadena", "Sello"],
            ["expediente", "Expediente"],
            ["casos", "Quién operó"],
            ["anomalias", "Alertas"]
          ] as const
        ).map(([id, label]) => (
          <Button key={id} variant={tab === id ? "primary" : "secondary"} onClick={() => setTab(id)}>{label}</Button>
        ))}
      </div>

      {tab === "bitacora" && (
        <section className="space-y-4 rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
          <div className="flex flex-wrap gap-2">
            <input className={`${inputClass} max-w-xs`} placeholder="Buscar FAC, Ana, kanban…" value={q} onChange={(e) => setQ(e.target.value)} />
            {modules.map((item) => (
              <Button key={item} variant={moduleFilter === item ? "primary" : "secondary"} onClick={() => setModuleFilter(item)}>{item}</Button>
            ))}
          </div>
          <div className="space-y-2">
            {filtered.map((item) => (
              <EventCard key={item.id} item={item} />
            ))}
          </div>
        </section>
      )}

      {tab === "cadena" && (
        <section className="space-y-4 rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 className="font-extrabold">Sello de la bitácora</h2>
              <p className="text-sm text-slate-500">Cada movimiento firma al anterior. Si se altera, el sello no cierra.</p>
            </div>
            <StatusPill tone={chain.ok ? "ok" : "bad"}>{chain.ok ? "Cadena válida" : "Cadena rota"}</StatusPill>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead className="bg-brand-900 text-left text-xs uppercase tracking-wide text-cyan-50">
                <tr>
                  <th className="p-3">Evento</th>
                  <th className="p-3">prevHash</th>
                  <th className="p-3">hash</th>
                  <th className="p-3">Estado</th>
                </tr>
              </thead>
              <tbody>
                {db.audit.map((item) => {
                  const broken = chain.broken.some((row) => row.id === item.id);
                  return (
                    <tr key={item.id} className="border-t border-slate-100 font-mono text-xs dark:border-white/10">
                      <td className="p-2">
                        <p className="font-sans font-bold text-slate-800 dark:text-slate-100">{item.action} · {item.userName}</p>
                        <p className="text-slate-500">{item.detail}</p>
                      </td>
                      <td className="p-2 text-slate-500">{item.prevHash}</td>
                      <td className="p-2 font-bold text-brand-700">{item.hash}</td>
                      <td className="p-2"><StatusPill tone={broken ? "bad" : "ok"}>{broken ? "roto" : "ok"}</StatusPill></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {tab === "expediente" && sale && (
        <div className="space-y-4">
          <section className="rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
            <div className="flex flex-wrap items-end justify-between gap-3">
              <div>
                <h2 className="font-extrabold">Expediente del cobro</h2>
                <p className="text-sm text-slate-500">Cómo salió esa factura: bodega, asiento, caja y huella.</p>
              </div>
              <select className={`${inputClass} max-w-xs`} value={sale.saleNumber} onChange={(e) => setSaleId(e.target.value)}>
                {db.sales.map((item) => (
                  <option key={item.id} value={item.saleNumber}>{item.saleNumber} · {item.clientName}</option>
                ))}
              </select>
            </div>
            <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
              {dossier.map((item) => (
                <article key={item.step} className="rounded-xl bg-slate-50 p-3 dark:bg-slate-950">
                  <div className="mx-auto mb-2 grid h-9 w-9 place-items-center rounded-full bg-brand-600 text-sm font-extrabold text-white">{item.step}</div>
                  <p className="text-center text-xs font-bold uppercase tracking-wide text-slate-400">{item.actor}</p>
                  <p className="mt-1 text-center font-mono text-xs font-bold text-brand-800 dark:text-cyan-100">{item.message}</p>
                  <p className="mt-2 text-center text-xs text-slate-500">{item.note}</p>
                  <div className="mt-2 flex justify-center"><StatusPill tone={item.ok ? "ok" : "bad"}>{item.ok ? "ligado" : "falta"}</StatusPill></div>
                </article>
              ))}
            </div>
            <p className="mt-4 text-sm text-slate-500">
              {sale.saleNumber} · {sale.clientName} · total <Money value={sale.total} /> · IVA 15 % · QR {sale.qrPayload ? "emitido" : "pendiente"}.
            </p>
          </section>
        </div>
      )}

      {tab === "casos" && (
        <section className="rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="font-extrabold">Quién operó</h2>
          <p className="mt-1 text-sm text-slate-500">Personas que dejaron huella en el ERP.</p>
          <div className="mt-4 grid gap-3 md:grid-cols-2">
            {byUser.map(([name, count]) => (
              <div key={name} className="flex items-center justify-between rounded-lg bg-slate-50 p-3 dark:bg-slate-950">
                <strong>{name}</strong>
                <StatusPill>{count} eventos</StatusPill>
              </div>
            ))}
          </div>
        </section>
      )}

      {tab === "anomalias" && (
        <div className="space-y-4">
          <section className="grid gap-3 md:grid-cols-2">
            {anomalies.map((item) => (
              <article key={item.title} className="rounded-xl bg-white p-4 shadow-soft dark:bg-slate-900">
                <StatusPill tone={item.tone === "ok" ? "ok" : item.tone === "warn" ? "warn" : "bad"}>{item.req}</StatusPill>
                <h3 className="mt-2 font-extrabold">{item.title}</h3>
                <p className="mt-1 text-sm text-slate-500">{item.detail}</p>
              </article>
            ))}
          </section>
          <section className="rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 className="font-extrabold">Constancia para gerencia</h2>
                <p className="text-sm text-slate-500">Resumen de quién tocó el sistema.</p>
              </div>
              <Button
                variant="secondary"
                onClick={() => navigator.clipboard.writeText(constancia)}
              >
                Copiar constancia
              </Button>
            </div>
            <pre className="mt-4 overflow-x-auto rounded-lg bg-slate-950 p-4 text-[11px] text-cyan-50">{constancia}</pre>
          </section>
        </div>
      )}
    </motion.div>
  );
}

function Pulse({ icon, label, value, hint }: { icon: ReactNode; label: string; value: string; hint: string }) {
  return (
    <div className="rounded-xl bg-white/10 p-4 backdrop-blur">
      <div className="text-cyan-100">{icon}</div>
      <p className="mt-2 text-xs font-bold uppercase tracking-wide text-cyan-100">{label}</p>
      <p className="text-2xl font-black">{value}</p>
      <p className="text-xs text-cyan-50/80">{hint}</p>
    </div>
  );
}

function EventCard({ item }: { item: AuditEvent }) {
  const tone = item.severity === "critical" ? "bad" : item.severity === "warn" ? "warn" : "ok";
  return (
    <article className="rounded-lg border border-slate-100 bg-white p-4 dark:border-white/10 dark:bg-slate-950">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <StatusPill tone={tone}>{item.action}</StatusPill>
          <strong className="text-sm">{item.module}</strong>
          {item.reference && <span className="font-mono text-xs font-bold text-brand-700">{item.reference}</span>}
        </div>
        <span className="text-xs text-slate-500">{new Date(item.at).toLocaleString("es-NI")}</span>
      </div>
      <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{item.userName}: {item.detail}</p>
      <div className="mt-2 flex flex-wrap items-center gap-3 text-[11px] text-slate-400">
      {item.hash && <span className="font-mono">#{item.hash}</span>}
      </div>
    </article>
  );
}
