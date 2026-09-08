import { ReactNode } from "react";
import { clsx } from "clsx";

export function PageHeader({
  kicker,
  title,
  subtitle,
  actions
}: {
  kicker: string;
  title: string;
  subtitle: string;
  actions?: ReactNode;
}) {
  return (
    <section className="flex flex-col gap-4 rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900 lg:flex-row lg:items-end lg:justify-between">
      <div>
        <p className="text-sm font-bold uppercase tracking-[0.18em] text-brand-700 dark:text-glass">{kicker}</p>
        <h1 className="mt-1 text-2xl font-extrabold">{title}</h1>
        <p className="mt-2 max-w-3xl text-sm text-slate-500 dark:text-slate-400">{subtitle}</p>
      </div>
      {actions}
    </section>
  );
}

export function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1 block text-sm font-semibold">{label}</span>
      {children}
    </label>
  );
}

export const inputClass =
  "h-11 w-full rounded-lg border border-slate-200 bg-white px-3 outline-none transition focus:border-brand-500 dark:border-white/10 dark:bg-slate-950";

export function Money({ value }: { value: number }) {
  return <span>{value.toLocaleString("es-NI", { style: "currency", currency: "NIO", maximumFractionDigits: 0 }).replace("NIO", "C$")}</span>;
}

export function StatusPill({ children, tone = "neutral" }: { children: ReactNode; tone?: "ok" | "warn" | "bad" | "neutral" }) {
  return (
    <span
      className={clsx(
        "rounded-full px-2.5 py-1 text-xs font-bold",
        tone === "ok" && "bg-emerald-50 text-emerald-700 dark:bg-emerald-400/10 dark:text-emerald-200",
        tone === "warn" && "bg-amber-50 text-amber-700 dark:bg-amber-400/10 dark:text-amber-200",
        tone === "bad" && "bg-rose-50 text-rose-700 dark:bg-rose-400/10 dark:text-rose-200",
        tone === "neutral" && "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-200"
      )}
    >
      {children}
    </span>
  );
}
