import { LucideIcon } from "lucide-react";
import { motion } from "framer-motion";
import { Area, AreaChart, ResponsiveContainer } from "recharts";

const spark = [
  { value: 18 },
  { value: 24 },
  { value: 20 },
  { value: 35 },
  { value: 32 },
  { value: 46 },
  { value: 52 }
];

export function KpiCard({
  label,
  value,
  change,
  tone,
  icon: Icon
}: {
  label: string;
  value: string;
  change: string;
  tone: string;
  icon: LucideIcon;
}) {
  return (
    <motion.article
      className="relative overflow-hidden rounded-lg bg-white p-5 shadow-soft transition hover:-translate-y-1 hover:shadow-glow dark:bg-slate-900"
      whileHover={{ scale: 1.015 }}
      layout
    >
      <div className={`absolute inset-x-0 top-0 h-1 bg-gradient-to-r ${tone}`} />
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-medium text-slate-500 dark:text-slate-400">{label}</p>
          <strong className="mt-2 block text-2xl font-extrabold text-ink dark:text-white">{value}</strong>
        </div>
        <div className={`grid h-11 w-11 place-items-center rounded-lg bg-gradient-to-br ${tone} text-white`}>
          <Icon size={21} />
        </div>
      </div>
      <div className="mt-4 flex items-end justify-between">
        <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-bold text-emerald-700 dark:bg-emerald-400/10 dark:text-emerald-200">
          {change}
        </span>
        <div className="h-12 w-28">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={spark}>
              <Area type="monotone" dataKey="value" stroke="#0a92c8" fill="#72d4ef" fillOpacity={0.18} strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>
    </motion.article>
  );
}
