import { Link } from "react-router-dom";
import { Button } from "../components/Button";
import { RolePowerGrid } from "../components/RoleMark";
import { ScreenJourney } from "../components/ScreenJourney";
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
  { actor: "Superadministrador", case: "Corona: administra usuarios y también puede cobrar, asentar o cerrar periodo." },
  { actor: "Administrador de área", case: "Escudo: aprueba y ejecuta dentro de su equipo (finanzas, taller…)." },
  { actor: "Usuario estándar", case: "Mano: ejecuta ventas, compras u OT. No configura el sistema." },
  { actor: "Invitado", case: "Ojo: consulta indicadores. No cobra ni descuenta stock." }
];

const entities = [
  "Usuario", "Producto", "Lote", "Kardex", "Venta", "Proforma", "Compra", "Asiento",
  "Proyección", "Orden", "Cliente", "Proveedor", "Empleado", "Proyecto", "Auditoría"
];

export default function MethodologyPage() {
  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Taller"
        title="Cómo se cobra una ventana"
        subtitle="Pantalla a pantalla: clave, pulso, caja, ticket y teléfono."
      />
      <ScreenJourney />
      <RolePowerGrid />
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
          <h2 className="font-extrabold">Quién entra a qué</h2>
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
          <h2 className="font-extrabold">Lo que se guarda</h2>
          <p className="mt-1 text-sm text-slate-500">Todo lo que mueve el ERP queda acá.</p>
          <div className="mt-4 flex flex-wrap gap-2">
            {entities.map((item) => (
              <span key={item} className="rounded-lg border border-brand-200 bg-brand-50 px-3 py-1 text-xs font-bold text-brand-800 dark:border-brand-500/30 dark:bg-brand-500/10 dark:text-glass">{item}</span>
            ))}
          </div>
          <Link to="/datos" className="mt-4 inline-block">
            <Button variant="secondary">Abrir almacén</Button>
          </Link>
        </article>
      </section>
    </div>
  );
}
