import { QRCodeSVG } from "qrcode.react";
import { buildDocToken, buildPortableDoc, buildValidateUrl } from "../lib/invoiceDoc";

export { buildDocToken, buildPortableDoc, buildValidateUrl };

export function DocumentQr({
  payload,
  size = 148,
  label = "Escaneá con el teléfono"
}: {
  payload: string;
  size?: number;
  label?: string;
}) {
  const isUrl = payload.startsWith("http");
  return (
    <div className="inline-flex flex-col items-center gap-2 rounded-2xl border border-slate-200 bg-white p-3 dark:border-white/10 dark:bg-slate-950">
      <QRCodeSVG value={payload} size={size} level="M" includeMargin bgColor="#ffffff" fgColor="#0b3b4a" />
      <p className="text-[10px] font-bold uppercase tracking-wide text-slate-500">{label}</p>
      {isUrl ? (
        <a href={payload} target="_blank" rel="noreferrer" className="rounded-full bg-brand-50 px-3 py-1 text-[11px] font-bold text-brand-800">
          Ver factura
        </a>
      ) : (
        <p className="max-w-[160px] break-all text-center font-mono text-[9px] text-slate-400">{payload}</p>
      )}
    </div>
  );
}
