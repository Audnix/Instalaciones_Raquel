import { motion } from "framer-motion";
import { useMemo } from "react";
import { useLocation } from "react-router-dom";
import { CheckCircle2, ShieldCheck, Sparkles } from "lucide-react";
import logo from "../assets/logo-window.png";
import { KeepInvoiceVault } from "../components/KeepInvoiceVault";
import { decodePortableDoc, type PortableDoc } from "../lib/invoiceDoc";

function money(value: number) {
  return value.toLocaleString("es-NI", { style: "currency", currency: "NIO", maximumFractionDigits: 2 }).replace("NIO", "C$");
}

export default function ValidateInvoicePage() {
  const location = useLocation();
  const doc = useMemo(() => {
    const hash = location.hash.replace(/^#/, "");
    if (hash) return decodePortableDoc(hash);
    const params = new URLSearchParams(location.search);
    const d = params.get("d");
    return d ? decodePortableDoc(d) : null;
  }, [location.hash, location.search]);

  if (!doc) {
    return (
      <main className="min-h-screen bg-[#071820] px-4 py-10 text-white">
        <div className="mx-auto max-w-md rounded-3xl border border-white/10 bg-white/5 p-6 text-center">
          <ShieldCheck className="mx-auto text-cyan-300" size={42} />
          <h1 className="mt-3 text-xl font-black">Documento no válido</h1>
          <p className="mt-2 text-sm text-cyan-50/70">Escaneá el QR completo de la factura o proforma de Instalaciones Raquel.</p>
        </div>
      </main>
    );
  }

  return <MobileInvoice doc={doc} />;
}

function MobileInvoice({ doc }: { doc: PortableDoc }) {
  const kindLabel = doc.k === "FAC" ? "Factura" : "Proforma";
  const lines = doc.i?.length ? doc.i : [{ n: "Detalle", q: 1, p: doc.t }];

  return (
    <main className="min-h-screen bg-[linear-gradient(165deg,#062029_0%,#0b3b4a_42%,#114b5f_100%)] px-3 py-5 pb-8 text-slate-900 sm:px-4">
      <motion.article
        initial={{ opacity: 0, y: 18 }}
        animate={{ opacity: 1, y: 0 }}
        className="invoice-print-sheet mx-auto w-full max-w-md overflow-hidden rounded-[28px] bg-white shadow-[0_30px_80px_rgba(0,0,0,.35)]"
      >
        <header className="relative overflow-hidden bg-gradient-to-br from-[#0a92c8] via-[#0f6e86] to-[#0b3b4a] px-5 pb-8 pt-5 text-white">
          <div className="pointer-events-none absolute -right-8 -top-8 h-32 w-32 rounded-full bg-white/10" />
          <div className="flex items-center gap-3">
            <div className="grid h-14 w-14 place-items-center rounded-2xl bg-white p-1">
              <img src={logo} alt="" className="h-full w-full object-contain" />
            </div>
            <div>
              <p className="text-[11px] font-bold uppercase tracking-[0.22em] text-cyan-100">Instalaciones Raquel</p>
              <h1 className="text-xl font-black leading-tight">Aluminio · Vidrio · Hogar</h1>
            </div>
          </div>
          <div className="mt-5 flex items-end justify-between gap-3">
            <div>
              <p className="text-xs text-cyan-100">{kindLabel} válida</p>
              <p className="text-2xl font-black">{doc.n}</p>
            </div>
            <div className="rounded-2xl bg-white/15 px-3 py-2 text-right backdrop-blur">
              <p className="text-[10px] uppercase tracking-wide text-cyan-100">Total</p>
              <p className="text-lg font-black">{money(doc.t)}</p>
            </div>
          </div>
        </header>

        <div className="-mt-4 rounded-t-[24px] bg-white px-5 pb-5 pt-5">
          <div className="mb-4 flex items-center gap-2 rounded-2xl bg-emerald-50 px-3 py-2 text-emerald-800">
            <CheckCircle2 size={18} />
            <p className="text-xs font-bold">Código verificado · {doc.v}</p>
          </div>

          <section className="grid grid-cols-2 gap-3 text-sm">
            <div className="rounded-2xl bg-slate-50 p-3">
              <p className="text-[10px] font-bold uppercase tracking-wide text-slate-400">Cliente</p>
              <p className="mt-1 font-extrabold leading-snug">{doc.c}</p>
            </div>
            <div className="rounded-2xl bg-slate-50 p-3">
              <p className="text-[10px] font-bold uppercase tracking-wide text-slate-400">Fecha</p>
              <p className="mt-1 font-extrabold">{doc.d}</p>
            </div>
          </section>

          {doc.p && (
            <div className="mt-3 flex items-center gap-2 rounded-2xl bg-amber-50 px-3 py-2 text-amber-900">
              <Sparkles size={16} />
              <p className="text-xs font-bold">Promo aplicada: {doc.p}</p>
            </div>
          )}

          <section className="mt-4">
            <p className="text-[10px] font-bold uppercase tracking-wide text-slate-400">Detalle</p>
            <div className="mt-2 space-y-2">
              {lines.map((line, index) => (
                <div key={`${line.n}-${index}`} className="flex items-start justify-between gap-3 rounded-2xl border border-slate-100 px-3 py-2.5">
                  <div>
                    <p className="text-sm font-extrabold leading-snug">{line.n}</p>
                    <p className="text-xs text-slate-500">{line.q} × {money(line.p)}</p>
                  </div>
                  <p className="text-sm font-black">{money(line.q * line.p)}</p>
                </div>
              ))}
            </div>
          </section>

          <section className="mt-4 space-y-1.5 rounded-2xl bg-slate-50 p-4 text-sm">
            <Row label="Subtotal" value={money(doc.s)} />
            {doc.o > 0 && <Row label="Descuento" value={`- ${money(doc.o)}`} accent />}
            <Row label="IVA 15%" value={money(doc.x)} />
            <div className="border-t border-slate-200 pt-2">
              <Row label="Total a pagar" value={money(doc.t)} bold />
            </div>
          </section>

          <p className="mt-5 text-center text-[11px] leading-relaxed text-slate-400">
            Usá la Bóveda Raquel abajo para guardar esta factura en tu teléfono.
          </p>
          <p className="mt-1 text-center text-[10px] font-bold uppercase tracking-wide text-slate-300">
            Instalaciones Raquel · Comprobante digital
          </p>
        </div>
      </motion.article>

      <KeepInvoiceVault doc={doc} />
    </main>
  );
}

function Row({ label, value, bold, accent }: { label: string; value: string; bold?: boolean; accent?: boolean }) {
  return (
    <div className={`flex items-center justify-between gap-3 ${bold ? "text-base font-black" : "font-semibold"} ${accent ? "text-emerald-700" : ""}`}>
      <span className={bold ? "" : "text-slate-500"}>{label}</span>
      <span>{value}</span>
    </div>
  );
}
