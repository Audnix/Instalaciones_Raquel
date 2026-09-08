import { AnimatePresence, motion } from "framer-motion";
import { Check, Download, FileImage, Printer, Share2, Sparkles, Wallet } from "lucide-react";
import { useState } from "react";
import type { PortableDoc } from "../lib/invoiceDoc";
import { downloadInvoicePng, shareInvoice } from "../lib/saveInvoice";

type Status = "idle" | "working" | "saved" | "shared" | "error";

export function KeepInvoiceVault({ doc }: { doc: PortableDoc }) {
  const [open, setOpen] = useState(false);
  const [status, setStatus] = useState<Status>("idle");
  const [hint, setHint] = useState("Tu comprobante digital, listo para el bolsillo");

  const run = async (action: "image" | "share" | "pdf") => {
    setStatus("working");
    try {
      if (action === "pdf") {
        window.print();
        setStatus("saved");
        setHint("Elegí “Guardar como PDF” en el diálogo");
      } else if (action === "share") {
        const result = await shareInvoice(doc);
        setStatus(result.startsWith("shared") ? "shared" : "saved");
        setHint(result.startsWith("shared") ? "Lista para enviar desde tu teléfono" : "Imagen guardada en Descargas");
      } else {
        await downloadInvoicePng(doc);
        setStatus("saved");
        setHint("Imagen guardada · buscala en Descargas o Galería");
      }
      window.setTimeout(() => setStatus("idle"), 3200);
    } catch {
      setStatus("error");
      setHint("No se pudo completar. Probá Guardar imagen o PDF.");
      window.setTimeout(() => setStatus("idle"), 3200);
    }
  };

  return (
    <div className="no-print sticky bottom-3 z-20 mx-auto mt-4 w-full max-w-md px-1">
      <AnimatePresence mode="wait">
        {!open ? (
          <motion.button
            key="closed"
            type="button"
            initial={{ opacity: 0, y: 18, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 10, scale: 0.98 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => setOpen(true)}
            className="group relative flex w-full items-center gap-3 overflow-hidden rounded-[22px] bg-[linear-gradient(120deg,#0a92c8,#0b3b4a_55%,#134e4a)] px-4 py-3.5 text-left text-white shadow-[0_18px_50px_rgba(6,32,41,.45)]"
          >
            <span className="pointer-events-none absolute -right-6 -top-8 h-28 w-28 rounded-full bg-white/10 blur-xl transition group-hover:bg-white/20" />
            <span className="grid h-12 w-12 place-items-center rounded-2xl bg-white/15 backdrop-blur">
              <Wallet size={22} />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block text-[11px] font-bold uppercase tracking-[0.18em] text-cyan-100">Bóveda Raquel</span>
              <span className="block truncate text-base font-black">Guardar en mi teléfono</span>
            </span>
            <span className="grid h-10 w-10 place-items-center rounded-full bg-white text-[#0b3b4a] shadow-md">
              <Download size={18} />
            </span>
          </motion.button>
        ) : (
          <motion.div
            key="open"
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 10 }}
            className="overflow-hidden rounded-[26px] border border-white/20 bg-[#071820]/95 text-white shadow-[0_24px_60px_rgba(0,0,0,.45)] backdrop-blur-xl"
          >
            <div className="flex items-start justify-between gap-3 px-4 pb-2 pt-4">
              <div>
                <p className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-[0.18em] text-cyan-200">
                  <Sparkles size={12} /> Bóveda Raquel
                </p>
                <h3 className="mt-1 text-lg font-black leading-tight">¿Cómo la querés guardar?</h3>
                <p className="mt-1 text-xs text-cyan-50/70">{hint}</p>
              </div>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded-full bg-white/10 px-3 py-1 text-xs font-bold text-cyan-50"
              >
                Cerrar
              </button>
            </div>

            <div className="grid gap-2 p-3 pt-1">
              <ActionCard
                icon={<FileImage size={18} />}
                title="Guardar imagen"
                subtitle="PNG en Descargas / Galería"
                accent="from-cyan-400 to-teal-500"
                disabled={status === "working"}
                onClick={() => void run("image")}
              />
              <ActionCard
                icon={<Share2 size={18} />}
                title="Compartir"
                subtitle="WhatsApp, Drive, Archivos…"
                accent="from-emerald-400 to-cyan-500"
                disabled={status === "working"}
                onClick={() => void run("share")}
              />
              <ActionCard
                icon={<Printer size={18} />}
                title="Guardar PDF"
                subtitle="Imprimir → Guardar como PDF"
                accent="from-amber-300 to-orange-400"
                disabled={status === "working"}
                onClick={() => void run("pdf")}
              />
            </div>

            <AnimatePresence>
              {(status === "saved" || status === "shared") && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="overflow-hidden border-t border-white/10 bg-emerald-500/15 px-4 py-3"
                >
                  <p className="flex items-center gap-2 text-sm font-bold text-emerald-200">
                    <Check size={16} /> {status === "shared" ? "Compartida" : "Guardada en tu dispositivo"}
                  </p>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function ActionCard({
  icon,
  title,
  subtitle,
  accent,
  onClick,
  disabled
}: {
  icon: React.ReactNode;
  title: string;
  subtitle: string;
  accent: string;
  onClick: () => void;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className="flex w-full items-center gap-3 rounded-2xl bg-white/5 px-3 py-3 text-left transition hover:bg-white/10 disabled:opacity-60"
    >
      <span className={`grid h-11 w-11 place-items-center rounded-xl bg-gradient-to-br ${accent} text-slate-900 shadow`}>
        {icon}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-sm font-black">{title}</span>
        <span className="block text-xs text-cyan-50/65">{subtitle}</span>
      </span>
    </button>
  );
}
