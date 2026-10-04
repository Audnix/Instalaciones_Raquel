import { useState, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowRight, QrCode, Smartphone, Store, Wallet } from "lucide-react";
import { Button } from "./Button";
import { StatusPill } from "./Ui";

type ScreenId = "acceso" | "pulso" | "ventas" | "ticket" | "telefono" | "denegado" | "bodega";

type Edge = { from: ScreenId; to: ScreenId; event: string; guard?: string };

const screens: { id: ScreenId; title: string; happy?: boolean }[] = [
  { id: "acceso", title: "Acceso", happy: true },
  { id: "pulso", title: "Pulso", happy: true },
  { id: "ventas", title: "Ventas", happy: true },
  { id: "ticket", title: "Ticket", happy: true },
  { id: "telefono", title: "Teléfono", happy: true },
  { id: "denegado", title: "Denegado" },
  { id: "bodega", title: "Bodega" }
];

const edges: Edge[] = [
  { from: "acceso", to: "pulso", event: "Entrar", guard: "clave ok" },
  { from: "acceso", to: "acceso", event: "Reintentar", guard: "clave mala" },
  { from: "pulso", to: "ventas", event: "Facturar", guard: "Ana Ventas" },
  { from: "pulso", to: "denegado", event: "Facturar", guard: "Invitado" },
  { from: "denegado", to: "pulso", event: "Volver" },
  { from: "ventas", to: "ticket", event: "Cobrar", guard: "hay lote" },
  { from: "ventas", to: "bodega", event: "Sin stock" },
  { from: "bodega", to: "ventas", event: "Volver a caja" },
  { from: "ticket", to: "telefono", event: "Escanear QR" },
  { from: "ticket", to: "pulso", event: "Cerrar" },
  { from: "telefono", to: "ticket", event: "Listo" }
];

const happyPath: ScreenId[] = ["acceso", "pulso", "ventas", "ticket", "telefono"];

export function ScreenJourney() {
  const [current, setCurrent] = useState<ScreenId>("acceso");
  const [lastEdge, setLastEdge] = useState<Edge | null>(null);
  const exits = edges.filter((item) => item.from === current);

  const go = (to: ScreenId, edge?: Edge) => {
    setCurrent(to);
    if (edge) setLastEdge(edge);
  };

  return (
    <section id="recorrido" className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand-700">Cobro de una ventana</p>
          <h2 className="mt-1 text-xl font-black">De la clave al QR</h2>
          <p className="mt-1 text-sm text-slate-500">Ana Ventas cobra a Torre Azul. Cada caja es una pantalla; la flecha es el clic.</p>
        </div>
        <StatusPill tone="ok">Ana Ventas · caja</StatusPill>
      </div>

      <TransitionMap current={current} lastEdge={lastEdge} onGo={go} />

      <div className="grid gap-4 xl:grid-cols-[1.15fr_.85fr]">
        <motion.div key={current} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }}>
          <MockScreen
            id={current}
            onGo={(to) => {
              const edge = edges.find((item) => item.from === current && item.to === to);
              go(to, edge);
            }}
          />
        </motion.div>
        <aside className="space-y-3 rounded-2xl bg-white p-5 shadow-soft dark:bg-slate-900">
          <h3 className="font-extrabold">Qué dispara el cambio</h3>
          {lastEdge && (
            <p className="rounded-xl bg-cyan-50 px-3 py-2 text-xs text-cyan-900 dark:bg-cyan-500/10 dark:text-cyan-100">
              Último: <strong>{lastEdge.event}</strong>
              {lastEdge.guard ? ` [${lastEdge.guard}]` : ""} → {screens.find((row) => row.id === lastEdge.to)?.title}
            </p>
          )}
          <div className="space-y-2">
            {exits.map((item) => (
              <button
                key={`${item.event}-${item.to}-${item.guard ?? ""}`}
                type="button"
                onClick={() => go(item.to, item)}
                className="flex w-full items-center justify-between rounded-xl bg-slate-50 px-3 py-3 text-left dark:bg-slate-950"
              >
                <span>
                  <strong className="text-sm">{item.event}</strong>
                  {item.guard && <span className="mt-0.5 block text-xs text-slate-500">[{item.guard}]</span>}
                </span>
                <span className="text-xs font-bold text-brand-700">{screens.find((row) => row.id === item.to)?.title}</span>
              </button>
            ))}
          </div>
          <div className="flex flex-wrap gap-2 pt-2">
            <Link to="/ventas"><Button>Ir a facturar</Button></Link>
            <Link to="/auditoria"><Button variant="secondary">Ver huella</Button></Link>
          </div>
        </aside>
      </div>
    </section>
  );
}

function TransitionMap({
  current,
  lastEdge,
  onGo
}: {
  current: ScreenId;
  lastEdge: Edge | null;
  onGo: (to: ScreenId, edge?: Edge) => void;
}) {
  const happyEdges = happyPath.slice(0, -1).map((from, index) =>
    edges.find((item) => item.from === from && item.to === happyPath[index + 1])
  );

  return (
    <div className="overflow-x-auto rounded-2xl bg-slate-950 p-4 text-cyan-50">
      <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
        <p className="text-[11px] font-bold uppercase tracking-wide text-cyan-200">Mapa de pantallas</p>
        <p className="text-[11px] text-cyan-100/70">Caja = pantalla · flecha = clic · [ ] = condición</p>
      </div>

      <div className="flex min-w-[860px] items-center gap-1">
        {happyPath.map((id, index) => {
          const next = happyEdges[index];
          return (
            <div key={id} className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => onGo(id)}
                className={`min-w-[108px] rounded-xl border px-3 py-3 text-center text-xs font-extrabold transition ${
                  current === id
                    ? "border-cyan-300 bg-cyan-400 text-slate-950"
                    : "border-white/15 bg-white/10 text-white hover:bg-white/15"
                }`}
              >
                {screens.find((row) => row.id === id)?.title}
              </button>
              {next && (
                <div className={`flex min-w-[118px] flex-col items-center px-1 text-center ${lastEdge && lastEdge.from === next.from && lastEdge.to === next.to ? "text-cyan-200" : "text-cyan-300/80"}`}>
                  <ArrowRight size={16} />
                  <span className="text-[10px] font-bold leading-tight">{next.event}</span>
                  {next.guard && <span className="text-[9px] text-cyan-100/70">[{next.guard}]</span>}
                </div>
              )}
            </div>
          );
        })}
      </div>

      <div className="mt-4 grid min-w-[860px] grid-cols-2 gap-3">
        <ExceptionLane
          active={current === "denegado" || (lastEdge?.to === "denegado")}
          current={current === "denegado"}
          title="Si entra Invitado"
          from="Pulso"
          event="Facturar"
          guard="Invitado"
          to="Denegado"
          onClick={() => onGo("denegado", edges.find((item) => item.to === "denegado"))}
        />
        <ExceptionLane
          active={current === "bodega" || (lastEdge?.to === "bodega")}
          current={current === "bodega"}
          title="Si no hay lote"
          from="Ventas"
          event="Sin stock"
          to="Bodega"
          onClick={() => onGo("bodega", edges.find((item) => item.to === "bodega"))}
        />
      </div>
    </div>
  );
}

function ExceptionLane({
  title,
  from,
  event,
  guard,
  to,
  current,
  active,
  onClick
}: {
  title: string;
  from: string;
  event: string;
  guard?: string;
  to: string;
  current: boolean;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex items-center justify-between rounded-xl border px-3 py-2 text-left text-xs ${
        current ? "border-amber-300 bg-amber-300/20" : active ? "border-white/20 bg-white/10" : "border-white/10 bg-white/5"
      }`}
    >
      <span>
        <span className="block font-bold text-cyan-100">{title}</span>
        <span className="text-cyan-100/70">{from} → {to}</span>
      </span>
      <span className="text-right font-bold">
        {event}
        {guard && <span className="block font-normal text-cyan-100/70">[{guard}]</span>}
      </span>
    </button>
  );
}

function MockScreen({ id, onGo }: { id: ScreenId; onGo: (id: ScreenId) => void }) {
  if (id === "acceso") {
    return (
      <Frame title="Acceso">
        <div className="rounded-xl bg-white p-4 text-slate-900">
          <p className="text-xs font-bold uppercase tracking-wide text-slate-400">Instalaciones Raquel</p>
          <h3 className="mt-1 font-black">Bienvenido</h3>
          <div className="mt-3 space-y-2">
            <div className="h-9 rounded-lg bg-slate-100 px-3 text-sm leading-9 text-slate-500">vendedor@raquel.com</div>
            <div className="h-9 rounded-lg bg-slate-100 px-3 text-sm leading-9 text-slate-500">••••••••</div>
            <button type="button" onClick={() => onGo("pulso")} className="h-10 w-full rounded-lg bg-brand-600 text-sm font-bold text-white">Entrar</button>
          </div>
        </div>
      </Frame>
    );
  }
  if (id === "pulso") {
    return (
      <Frame title="Hoy en taller">
        <div className="grid grid-cols-3 gap-2">
          {["Margen", "OT 5", "Stock 3"].map((item) => (
            <div key={item} className="rounded-xl bg-white/15 p-3 text-center text-xs font-bold">{item}</div>
          ))}
        </div>
        <div className="mt-3 flex justify-end">
          <button type="button" onClick={() => onGo("ventas")} className="rounded-lg bg-white px-3 py-2 text-xs font-bold text-brand-800">Facturar</button>
        </div>
      </Frame>
    );
  }
  if (id === "ventas") {
    return (
      <Frame title="Caja">
        <div className="rounded-xl bg-white p-4 text-slate-900">
          <p className="text-xs text-slate-400">Cliente</p>
          <p className="font-extrabold">Torre Azul</p>
          <p className="mt-2 text-sm">Vidrio templado 10 mm · 6 u</p>
          <p className="mt-1 text-xs text-emerald-700">Sale lote viejo · costo C$ 310</p>
          <p className="mt-2 text-sm font-black">IVA 15% · total C$ 2,753</p>
          <button type="button" onClick={() => onGo("ticket")} className="mt-3 h-10 w-full rounded-lg bg-ember text-sm font-bold text-white">Cobrar</button>
        </div>
      </Frame>
    );
  }
  if (id === "ticket") {
    return (
      <Frame title="Ticket FAC-1092">
        <div className="rounded-xl bg-white p-4 text-center text-slate-900">
          <p className="text-[10px] font-bold uppercase tracking-wide text-slate-400">Aluminio · Vidrio · Hogar</p>
          <p className="font-black">FAC-1092</p>
          <button type="button" onClick={() => onGo("telefono")} aria-label="Escanear QR" className="mx-auto mt-3 grid h-24 w-24 place-items-center rounded-2xl border border-slate-200">
            <QrCode className="text-brand-800" />
          </button>
          <p className="mt-2 text-xs text-slate-500">Escaneá y guardá este QR</p>
        </div>
      </Frame>
    );
  }
  if (id === "telefono") {
    return (
      <Frame title="En el teléfono" phone>
        <div className="rounded-[28px] bg-white p-4 text-slate-900">
          <p className="text-[10px] font-bold uppercase tracking-wide text-cyan-700">Factura válida</p>
          <p className="text-lg font-black">FAC-1092</p>
          <p className="text-sm">Torre Azul</p>
          <p className="mt-2 font-black">C$ 2,753</p>
          <p className="mt-3 flex items-center gap-1 text-xs font-bold text-emerald-700"><Smartphone size={14} /> Código verificado</p>
        </div>
      </Frame>
    );
  }
  if (id === "denegado") {
    return (
      <Frame title="Invitado">
        <div className="rounded-xl bg-white p-6 text-center text-slate-900">
          <p className="font-black">Acceso denegado</p>
          <p className="mt-2 text-sm text-slate-500">Gerencia consulta. No cobra ni descuenta stock.</p>
          <button type="button" onClick={() => onGo("pulso")} className="mt-3 text-sm font-bold text-brand-700">Volver</button>
        </div>
      </Frame>
    );
  }
  return (
    <Frame title="Bodega">
      <div className="rounded-xl bg-white p-4 text-slate-900">
        <StatusPill tone="bad">Crítico</StatusPill>
        <p className="mt-2 font-extrabold">Silicon neutro blanco</p>
        <p className="text-sm text-slate-500">8 / mínimo 12. No hay lote para salir.</p>
        <button type="button" onClick={() => onGo("ventas")} className="mt-3 flex items-center gap-1 text-xs font-bold text-brand-700"><Store size={14} /> Volver a caja</button>
      </div>
    </Frame>
  );
}

function Frame({ title, children, phone }: { title: string; children: ReactNode; phone?: boolean }) {
  return (
    <article className={`overflow-hidden rounded-2xl bg-gradient-to-br from-brand-900 via-brand-700 to-cyan-700 p-4 text-white shadow-soft ${phone ? "mx-auto max-w-sm" : ""}`}>
      <div className="mb-3 flex items-center justify-between">
        <p className="text-xs font-bold uppercase tracking-wide text-cyan-100">{title}</p>
        {phone ? <Smartphone size={16} /> : <Wallet size={16} />}
      </div>
      {children}
    </article>
  );
}
