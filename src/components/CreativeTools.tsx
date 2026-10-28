import { useState } from "react";
import {
  AlertCircle,
  ArrowRight,
  Calculator,
  CheckCircle2,
  ChevronRight,
  Clock,
  HelpCircle,
  Layers,
  Ruler,
  Scissors,
  Sparkles,
  X
} from "lucide-react";
import { Button } from "./Button";
import { StatusPill } from "./Ui";

/* =========================================================
   1. QUÉ FALTA PARA CONTINUAR
   ========================================================= */
interface MissingStep {
  label: string;
  done: boolean;
  hint: string;
  actionUrl?: string;
}

export function WhatIsMissingCard({
  title,
  context,
  steps
}: {
  title: string;
  context: string;
  steps: MissingStep[];
}) {
  const pending = steps.filter((s) => !s.done);

  return (
    <div className="rounded-2xl border border-amber-200/80 bg-gradient-to-br from-amber-50/70 to-white p-4 shadow-soft dark:border-amber-900/30 dark:from-amber-950/20 dark:to-slate-900">
      <div className="flex items-center gap-2">
        <Sparkles className="text-amber-600 dark:text-amber-400" size={18} />
        <h4 className="text-sm font-extrabold text-amber-900 dark:text-amber-200">
          ¿Qué falta para continuar? · {title}
        </h4>
        <span className="ml-auto rounded-full bg-amber-100 px-2.5 py-0.5 text-[11px] font-black text-amber-800 dark:bg-amber-950 dark:text-amber-300">
          {pending.length === 0 ? "Listo para avanzar" : `${pending.length} pendiente${pending.length !== 1 ? "s" : ""}`}
        </span>
      </div>
      <p className="mt-1 text-xs text-slate-600 dark:text-slate-400">{context}</p>

      <div className="mt-3 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
        {steps.map((step, idx) => (
          <div
            key={idx}
            className={`flex items-start gap-2.5 rounded-xl border p-2.5 text-xs transition ${
              step.done
                ? "border-emerald-200 bg-emerald-50/40 text-emerald-900 dark:border-emerald-900/30 dark:bg-emerald-950/20 dark:text-emerald-300"
                : "border-slate-200 bg-white text-slate-700 dark:border-white/10 dark:bg-slate-900 dark:text-slate-200"
            }`}
          >
            {step.done ? (
              <CheckCircle2 size={16} className="text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
            ) : (
              <Clock size={16} className="text-amber-500 shrink-0 mt-0.5" />
            )}
            <div>
              <p className={`font-bold ${step.done ? "line-through opacity-80" : ""}`}>{step.label}</p>
              <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5">{step.hint}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

/* =========================================================
   2. EXPLICAR ESTA CIFRA
   ========================================================= */
export interface FigureExplanation {
  figureName: string;
  figureValue: string;
  formula: string;
  origin: string;
  accountingNote: string;
  legalBase?: string;
  variables: { name: string; value: string; description: string }[];
}

export function ExplainFigureModal({
  explanation,
  onClose
}: {
  explanation: FigureExplanation | null;
  onClose: () => void;
}) {
  if (!explanation) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm">
      <div className="relative w-full max-w-lg rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-white/10 dark:bg-slate-900">
        <div className="flex items-center justify-between border-b border-slate-100 dark:border-white/10 pb-4">
          <div className="flex items-center gap-2.5">
            <div className="grid h-10 w-10 place-items-center rounded-2xl bg-cyan-500/10 text-cyan-600 dark:text-cyan-400">
              <Calculator size={20} />
            </div>
            <div>
              <h3 className="font-extrabold text-slate-900 dark:text-white">Explicar esta cifra</h3>
              <p className="text-xs text-slate-500">Desglose matemático y origen contable</p>
            </div>
          </div>
          <button
            type="button"
            className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:hover:bg-white/10"
            onClick={onClose}
          >
            <X size={18} />
          </button>
        </div>

        <div className="mt-4 space-y-4">
          <div className="rounded-2xl bg-slate-900 p-4 text-white">
            <span className="text-[11px] font-bold uppercase tracking-wider text-cyan-300">
              {explanation.figureName}
            </span>
            <div className="mt-1 text-2xl font-black text-white">{explanation.figureValue}</div>
            <div className="mt-2 text-xs font-mono bg-white/10 rounded-lg p-2 text-cyan-200">
              {explanation.formula}
            </div>
          </div>

          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">Variables y Origen</h4>
            <div className="space-y-1.5">
              {explanation.variables.map((v, i) => (
                <div
                  key={i}
                  className="flex items-center justify-between rounded-xl border border-slate-100 bg-slate-50 p-2.5 text-xs dark:border-white/5 dark:bg-white/5"
                >
                  <div>
                    <span className="font-bold text-slate-800 dark:text-white">{v.name}</span>
                    <p className="text-[11px] text-slate-500">{v.description}</p>
                  </div>
                  <span className="font-mono font-bold text-slate-900 dark:text-cyan-300">{v.value}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-xs text-slate-600 dark:border-white/10 dark:bg-slate-950 dark:text-slate-300 leading-relaxed">
            <p><strong>Fuente contable:</strong> {explanation.origin}</p>
            <p className="mt-1"><strong>Criterio:</strong> {explanation.accountingNote}</p>
            {explanation.legalBase && (
              <p className="mt-1 text-cyan-700 dark:text-cyan-400">
                <strong>Base legal:</strong> {explanation.legalBase}
              </p>
            )}
          </div>

          <div className="flex justify-end pt-2">
            <Button onClick={onClose}>Entendido</Button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* =========================================================
   3. DEL PEDIDO AL COBRO (FLUJO COMERCIAL INTEGRADO)
   ========================================================= */
export interface PipelineDoc {
  stage: "Cotización" | "Pedido de Obra" | "Taller / Producción" | "Instalación" | "Factura" | "Cobro";
  code: string;
  status: "completado" | "activo" | "pendiente";
  date?: string;
  amount?: number;
}

export function OrderToCashPipeline({ docs }: { docs: PipelineDoc[] }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-soft dark:border-white/10 dark:bg-slate-900">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h4 className="font-extrabold text-sm text-slate-900 dark:text-white">
            Del Pedido al Cobro · Trazabilidad de Documentos
          </h4>
          <p className="text-xs text-slate-500">
            Cadena comercial unificada: Cotización → Pedido → OT → Entrega → Factura → Cobro
          </p>
        </div>
      </div>

      <div className="relative flex flex-col md:flex-row items-stretch justify-between gap-2 overflow-x-auto pb-2">
        {docs.map((doc, idx) => (
          <div key={idx} className="flex-1 flex md:flex-col items-center gap-2">
            <div
              className={`w-full rounded-2xl border p-3 text-xs transition ${
                doc.status === "completado"
                  ? "border-emerald-300 bg-emerald-50/60 dark:border-emerald-900/40 dark:bg-emerald-950/30"
                  : doc.status === "activo"
                    ? "border-cyan-400 bg-cyan-50/80 ring-2 ring-cyan-400/20 dark:border-cyan-500 dark:bg-cyan-950/40"
                    : "border-slate-200 bg-slate-50 opacity-60 dark:border-white/10 dark:bg-white/5"
              }`}
            >
              <div className="flex items-center justify-between gap-1">
                <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500">
                  {doc.stage}
                </span>
                <StatusPill tone={doc.status === "completado" ? "ok" : doc.status === "activo" ? "warn" : "neutral"}>
                  {doc.status}
                </StatusPill>
              </div>
              <p className="mt-1.5 font-black text-slate-900 dark:text-white text-xs">{doc.code}</p>
              {doc.amount !== undefined && (
                <p className="text-[11px] font-semibold text-brand-700 dark:text-cyan-300 mt-0.5">
                  C$ {doc.amount.toLocaleString("es-NI")}
                </p>
              )}
            </div>
            {idx < docs.length - 1 && (
              <ChevronRight className="hidden md:block text-slate-300 dark:text-slate-600 shrink-0 my-auto" size={18} />
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

/* =========================================================
   4. APROVECHAMIENTO DE REMANENTES (ALUMINIO Y VIDRIO)
   ========================================================= */
export function RemnantOptimizerModal({ onClose }: { onClose: () => void }) {
  // Barra estándar de aluminio 6.10 metros (6100 mm)
  const [profileType, setProfileType] = useState("Línea 25 - Tubo Rectangular 2x1");
  const [barLengthMm, setBarLengthMm] = useState(6100);
  const [cutKerfMm, setCutKerfMm] = useState(4); // Merma de disco de corte
  const [piecesInput, setPiecesInput] = useState("1800, 1800, 1200, 1100");

  const pieces = piecesInput
    .split(",")
    .map((s) => Number(s.trim()))
    .filter((n) => !isNaN(n) && n > 0);

  // Algoritmo First Fit Decreasing para optimizar cortes en barras de 6.10m
  const sorted = [...pieces].sort((a, b) => b - a);
  const bars: { used: number; pieces: number[] }[] = [];

  sorted.forEach((p) => {
    let placed = false;
    for (const b of bars) {
      if (b.used + p + cutKerfMm <= barLengthMm) {
        b.pieces.push(p);
        b.used += p + cutKerfMm;
        placed = true;
        break;
      }
    }
    if (!placed) {
      bars.push({ used: p + cutKerfMm, pieces: [p] });
    }
  });

  const totalUsedMm = bars.reduce((sum, b) => sum + b.used, 0);
  const totalBarMm = bars.length * barLengthMm;
  const scrapMm = totalBarMm - totalUsedMm;
  const efficiencyPct = totalBarMm > 0 ? ((totalUsedMm / totalBarMm) * 100).toFixed(1) : "0.0";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm">
      <div className="relative w-full max-w-2xl rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-white/10 dark:bg-slate-900">
        <div className="flex items-center justify-between border-b border-slate-100 dark:border-white/10 pb-4">
          <div className="flex items-center gap-2.5">
            <div className="grid h-10 w-10 place-items-center rounded-2xl bg-brand-500/10 text-brand-600 dark:text-cyan-400">
              <Scissors size={20} />
            </div>
            <div>
              <h3 className="font-extrabold text-slate-900 dark:text-white">
                Aprovechamiento de Remanentes y Retazos
              </h3>
              <p className="text-xs text-slate-500">
                Optimización lineal de perfiles de 6.10 m y control de mermas de taller
              </p>
            </div>
          </div>
          <button
            type="button"
            className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:hover:bg-white/10"
            onClick={onClose}
          >
            <X size={18} />
          </button>
        </div>

        <div className="mt-4 space-y-4">
          <div className="grid gap-3 sm:grid-cols-3">
            <div>
              <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Perfil</label>
              <input
                className="h-10 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-xs dark:border-white/10 dark:bg-white/5 font-semibold"
                value={profileType}
                onChange={(e) => setProfileType(e.target.value)}
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Largo Barra (mm)</label>
              <input
                type="number"
                className="h-10 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-xs dark:border-white/10 dark:bg-white/5 font-mono"
                value={barLengthMm}
                onChange={(e) => setBarLengthMm(Number(e.target.value))}
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Corte Disco (mm)</label>
              <input
                type="number"
                className="h-10 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-xs dark:border-white/10 dark:bg-white/5 font-mono"
                value={cutKerfMm}
                onChange={(e) => setCutKerfMm(Number(e.target.value))}
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">
              Medidas de corte solicitadas en mm (separadas por coma)
            </label>
            <input
              className="h-11 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-xs dark:border-white/10 dark:bg-white/5 font-mono"
              value={piecesInput}
              onChange={(e) => setPiecesInput(e.target.value)}
              placeholder="1800, 1800, 1200, 1100"
            />
          </div>

          {/* Estadísticas de aprovechamiento */}
          <div className="grid grid-cols-3 gap-3">
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-center dark:border-white/10 dark:bg-white/5">
              <span className="text-[10px] font-bold uppercase text-slate-400">Barras Necesarias</span>
              <p className="text-xl font-black text-brand-600 dark:text-cyan-400">{bars.length}</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-center dark:border-white/10 dark:bg-white/5">
              <span className="text-[10px] font-bold uppercase text-slate-400">Aprovechamiento</span>
              <p className="text-xl font-black text-emerald-600 dark:text-emerald-400">{efficiencyPct}%</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-center dark:border-white/10 dark:bg-white/5">
              <span className="text-[10px] font-bold uppercase text-slate-400">Retazo Restante</span>
              <p className="text-xl font-black text-amber-600 dark:text-amber-400">{(scrapMm / 1000).toFixed(2)} m</p>
            </div>
          </div>

          {/* Desglose barra por barra */}
          <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
            {bars.map((b, idx) => {
              const rem = barLengthMm - b.used;
              return (
                <div
                  key={idx}
                  className="rounded-xl border border-slate-200 bg-white p-3 text-xs dark:border-white/10 dark:bg-slate-950"
                >
                  <div className="flex items-center justify-between font-bold">
                    <span>Barra #{idx + 1} ({barLengthMm} mm)</span>
                    <span className={rem > 500 ? "text-emerald-600 font-bold" : "text-slate-400"}>
                      Sobrante reutilizable: {rem} mm
                    </span>
                  </div>
                  <div className="mt-2 flex flex-wrap gap-1.5 items-center">
                    <span className="text-[11px] text-slate-400">Cortes:</span>
                    {b.pieces.map((p, pIdx) => (
                      <span
                        key={pIdx}
                        className="rounded-lg bg-brand-50 border border-brand-200 px-2 py-0.5 font-mono font-bold text-brand-700 dark:bg-brand-950 dark:border-brand-800 dark:text-cyan-300"
                      >
                        {p} mm
                      </span>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>

          <div className="flex justify-end pt-2 border-t border-slate-100 dark:border-white/10">
            <Button onClick={onClose}>Cerrar Calculador</Button>
          </div>
        </div>
      </div>
    </div>
  );
}
