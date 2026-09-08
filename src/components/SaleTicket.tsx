import { QRCodeSVG } from "qrcode.react";
import logo from "../assets/logo-window.png";
import { Button } from "./Button";

export type TicketData = {
  kind: "FAC" | "PRF";
  number: string;
  clientName: string;
  productName: string;
  qty: number;
  subtotal: number;
  discount: number;
  promo?: string;
  tax: number;
  total: number;
  qrPayload: string;
  notes?: string;
  date?: string;
};

function money(value: number) {
  return value.toLocaleString("es-NI", { style: "currency", currency: "NIO", maximumFractionDigits: 2 }).replace("NIO", "C$");
}

export function SaleTicket({
  ticket,
  onClose
}: {
  ticket: TicketData;
  onClose: () => void;
}) {
  const kindLabel = ticket.kind === "FAC" ? "TICKET DE COMPRA" : "PROFORMA";
  const when = ticket.date ?? new Date().toLocaleString("es-NI");

  const savePdf = () => {
    window.print();
  };

  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-slate-950/60 p-3 print:static print:bg-white print:p-0" onClick={onClose}>
      <div
        className="ticket-sheet w-full max-w-[420px] overflow-hidden rounded-2xl bg-white shadow-2xl print:max-w-none print:rounded-none print:shadow-none"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="no-print flex items-center justify-between gap-2 border-b border-slate-100 px-4 py-3">
          <p className="text-sm font-extrabold text-slate-700">Ticket listo</p>
          <div className="flex gap-2">
            <Button variant="secondary" onClick={savePdf}>Guardar PDF</Button>
            <Button onClick={onClose}>Cerrar</Button>
          </div>
        </div>

        <div id="raquel-ticket" className="px-5 py-5 text-slate-900">
          <div className="flex items-center gap-3 border-b border-dashed border-slate-300 pb-4">
            <img src={logo} alt="" className="h-14 w-14 rounded-xl object-contain" />
            <div>
              <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Instalaciones Raquel</p>
              <h2 className="text-lg font-black leading-tight">Aluminio · Vidrio · Hogar</h2>
              <p className="text-xs text-slate-500">{kindLabel}</p>
            </div>
          </div>

          <div className="mt-4 space-y-1 text-sm">
            <div className="flex justify-between gap-3"><span className="text-slate-500">Folio</span><strong>{ticket.number}</strong></div>
            <div className="flex justify-between gap-3"><span className="text-slate-500">Fecha</span><strong>{when}</strong></div>
            <div className="flex justify-between gap-3"><span className="text-slate-500">Cliente</span><strong className="text-right">{ticket.clientName}</strong></div>
          </div>

          <div className="mt-4 rounded-xl bg-slate-50 p-3">
            <div className="flex items-start justify-between gap-3 text-sm">
              <div>
                <p className="font-extrabold">{ticket.productName}</p>
                <p className="text-xs text-slate-500">{ticket.qty} unidad(es)</p>
              </div>
              <p className="font-black">{money(ticket.subtotal)}</p>
            </div>
          </div>

          <div className="mt-3 space-y-1 border-b border-dashed border-slate-300 pb-3 text-sm">
            <div className="flex justify-between"><span>Subtotal</span><span>{money(ticket.subtotal)}</span></div>
            {ticket.discount > 0 && (
              <div className="flex justify-between text-emerald-700">
                <span>Descuento {ticket.promo ? `(${ticket.promo})` : ""}</span>
                <span>- {money(ticket.discount)}</span>
              </div>
            )}
            <div className="flex justify-between"><span>IVA 15%</span><span>{money(ticket.tax)}</span></div>
            <div className="flex justify-between text-base font-black"><span>TOTAL</span><span>{money(ticket.total)}</span></div>
          </div>

          {ticket.notes && <p className="mt-3 text-xs text-slate-500">{ticket.notes}</p>}

          <div className="mt-5 flex flex-col items-center gap-2">
            <div className="rounded-2xl border border-slate-200 bg-white p-3">
              <QRCodeSVG value={ticket.qrPayload} size={168} level="M" includeMargin bgColor="#ffffff" fgColor="#0b3b4a" />
            </div>
            <p className="text-center text-[11px] font-bold uppercase tracking-wide text-slate-500">
              Escaneá y guardá este QR
            </p>
            <p className="max-w-[280px] text-center text-[10px] leading-relaxed text-slate-400">
              El QR abre la factura en el celular. En el diálogo de impresión elegí “Guardar como PDF”.
            </p>
          </div>

          <p className="mt-5 text-center text-[10px] font-semibold text-slate-400">
            ¡Gracias por tu compra!
          </p>
        </div>
      </div>
    </div>
  );
}
