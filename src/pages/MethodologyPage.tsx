import { Link } from "react-router-dom";
import { Button } from "../components/Button";
import { PageHeader, StatusPill } from "../components/Ui";

const methods = [
  { name: "Scrum / Kanban", use: "Tablero de órdenes desde corte hasta entrega." },
  { name: "PEPS", use: "Sale primero el lote más antiguo en bodega." },
  { name: "Partida doble", use: "Cada venta o compra asienta débito y crédito." },
  { name: "Factura + QR", use: "El cobro deja un código para validar en el teléfono." },
  { name: "Proformas", use: "Cotizá, guardá QR y convertí a factura cuando acepten." },
  { name: "ABC comercial", use: "Priorizá productos según rotación real." }
];

const useCases = [
  { actor: "Superadministrador", case: "Configura usuarios, módulos y revisa auditoría." },
  { actor: "Administrador de área", case: "Aprueba movimientos y reporta su área." },
  { actor: "Usuario estándar", case: "Registra ventas, entradas, OT o compras." },
  { actor: "Invitado", case: "Consulta indicadores sin modificar datos." }
];

const entities = [
  "Usuario", "Producto", "Lote", "Kardex", "Venta", "Proforma", "Compra", "Asiento",
  "Proyección", "Orden", "Cliente", "Proveedor", "Empleado", "Proyecto", "Auditoría"
];

export default function MethodologyPage() {
  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Modelos"
        title="Cómo trabaja el ERP"
        subtitle="Flujo de taller, bodega, cobro y roles."
      />
      <section className="rounded-xl bg-gradient-to-r from-brand-900 to-cyan-700 p-5 text-white shadow-soft">
        <p className="text-xs font-bold uppercase tracking-wide text-cyan-100">Catálogo vivo</p>
        <h2 className="mt-1 text-xl font-black">Requerimientos del sistema</h2>
        <p className="mt-2 max-w-2xl text-sm text-cyan-50/90">Lista operativa de funciones validadas en el prototipo.</p>
        <Link to="/ers" className="mt-4 inline-block">
          <Button variant="secondary">Abrir requerimientos</Button>
        </Link>
      </section>
      <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        {methods.map((item) => (
          <article key={item.name} className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
            <StatusPill tone="ok">{item.name}</StatusPill>
            <p className="mt-3 text-sm text-slate-600 dark:text-slate-300">{item.use}</p>
          </article>
        ))}
      </section>
      <section className="grid gap-4 xl:grid-cols-2">
        <article className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="font-extrabold">Casos de uso</h2>
          <div className="mt-4 space-y-3">
            {useCases.map((item) => (
              <div key={item.actor} className="rounded-lg bg-slate-50 p-3 dark:bg-slate-950">
                <strong className="text-sm">{item.actor}</strong>
                <p className="text-sm text-slate-500">{item.case}</p>
              </div>
            ))}
          </div>
        </article>
        <article className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="font-extrabold">Entidades clave</h2>
          <div className="mt-4 flex flex-wrap gap-2">
            {entities.map((item) => (
              <span key={item} className="rounded-lg border border-brand-200 bg-brand-50 px-3 py-1 text-xs font-bold text-brand-800 dark:border-brand-500/30 dark:bg-brand-500/10 dark:text-glass">{item}</span>
            ))}
          </div>
        </article>
      </section>
      <article className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
        <h2 className="font-extrabold">Flujo de una venta</h2>
        <div className="mt-4 grid gap-3 sm:grid-cols-6">
          {["Cliente y producto", "Preview PEPS", "IVA 15%", "Descontar lote", "Asiento + caja", "QR en factura"].map((step, index) => (
            <div key={step} className="rounded-lg bg-slate-50 p-3 text-center dark:bg-slate-950">
              <div className="mx-auto mb-2 grid h-10 w-10 place-items-center rounded-full bg-brand-600 text-sm font-extrabold text-white">{index + 1}</div>
              <p className="text-sm font-semibold">{step}</p>
            </div>
          ))}
        </div>
      </article>
    </div>
  );
}
