import { FormEvent, useMemo, useState } from "react";
import { Eye, History, Mail, MapPin, Pencil, Phone, Plus, Search, X } from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";
import { Field, inputClass, Money, PageHeader, StatusPill } from "../components/Ui";
import { useErp } from "../store/erpStore";
import type { Party } from "../types/erp";

type SupplierStatus = NonNullable<Party["status"]>;
type SupplierCategory = NonNullable<Party["category"]>;

type SupplierForm = {
  id?: string;
  name: string;
  category: SupplierCategory;
  contact: string;
  phone: string;
  email: string;
  address: string;
  productsServices: string;
  ruc: string;
  paymentTerms: string;
  observations: string;
  status: SupplierStatus;
  nextReviewDate: string;
};

const emptyForm = (): SupplierForm => ({
  name: "",
  category: "otro",
  contact: "",
  phone: "",
  email: "",
  address: "",
  productsServices: "",
  ruc: "",
  paymentTerms: "",
  observations: "",
  status: "pendiente",
  nextReviewDate: ""
});

const categories: { value: SupplierCategory; label: string }[] = [
  { value: "materiales", label: "Materiales" },
  { value: "servicios", label: "Servicios" },
  { value: "transporte", label: "Transporte" },
  { value: "herramientas", label: "Herramientas" },
  { value: "otro", label: "Otro" }
];

const statuses: { value: SupplierStatus | "todos"; label: string }[] = [
  { value: "todos", label: "Todos los estados" },
  { value: "activo", label: "Activo" },
  { value: "pendiente", label: "Pendiente" },
  { value: "inactivo", label: "Inactivo" }
];

function supplierStatus(party: Party): SupplierStatus {
  return party.status ?? "activo";
}

function statusTone(status: SupplierStatus) {
  if (status === "activo") return "ok";
  if (status === "pendiente") return "warn";
  return "bad";
}

export default function SuppliersPage() {
  const { db, saveParty } = useErp();
  const { user, can } = useAuth();
  const canEdit = can("proveedores", "write");
  const [query, setQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<SupplierCategory | "todos">("todos");
  const [statusFilter, setStatusFilter] = useState<SupplierStatus | "todos">("todos");
  const [form, setForm] = useState<SupplierForm>(emptyForm);
  const [formOpen, setFormOpen] = useState(false);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [notice, setNotice] = useState<{ type: "success" | "error"; text: string } | null>(null);

  const suppliers = useMemo(
    () => db.parties.filter((party) => party.type === "proveedor"),
    [db.parties]
  );
  const filteredSuppliers = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase();
    return suppliers.filter((party) => {
      const matchesQuery = !needle || [
        party.name,
        party.category ?? "otro",
        party.contact,
        party.phone,
        party.email ?? "",
        party.productsServices ?? ""
      ].some((value) => value.toLocaleLowerCase().includes(needle));
      const matchesCategory = categoryFilter === "todos" || (party.category ?? "otro") === categoryFilter;
      const status = supplierStatus(party);
      const matchesStatus = statusFilter === "todos" || status === statusFilter;
      return matchesQuery && matchesCategory && matchesStatus;
    });
  }, [suppliers, query, categoryFilter, statusFilter]);

  const startNew = () => {
    setForm(emptyForm());
    setFormOpen(true);
    setNotice(null);
  };

  const startEdit = (party: Party) => {
    setForm({
      id: party.id,
      name: party.name,
      category: party.category ?? "otro",
      contact: party.contact,
      phone: party.phone,
      email: party.email ?? "",
      address: party.address ?? "",
      productsServices: party.productsServices ?? "",
      ruc: party.ruc ?? "",
      paymentTerms: party.paymentTerms ?? "",
      observations: party.observations ?? "",
      status: supplierStatus(party),
      nextReviewDate: party.nextReviewDate ?? ""
    });
    setFormOpen(true);
    setNotice(null);
  };

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const result = await saveParty({ ...form, type: "proveedor" }, user?.name ?? "sistema");
    if (result.error) {
      setNotice({ type: "error", text: result.error });
      return;
    }
    setNotice({
      type: "success",
      text: result.saved
        ? form.id ? "Proveedor actualizado y guardado en SQL Server." : "Proveedor guardado en SQL Server."
        : form.id ? "Proveedor actualizado localmente; está pendiente de confirmación en SQL Server." : "Proveedor guardado localmente; está pendiente de confirmación en SQL Server."
    });
    setForm(emptyForm());
    setFormOpen(false);
  };

  const selected = suppliers.find((party) => party.id === selectedId);
  const purchaseHistory = selected
    ? db.purchases
        .filter((purchase) => purchase.supplierId === selected.id || purchase.supplierName === selected.name)
        .sort((a, b) => b.purchaseDate.localeCompare(a.purchaseDate))
    : [];

  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Compras"
        title="Directorio de proveedores"
        subtitle="Registra, consulta y mantén al día la información y el historial de tus proveedores."
        actions={canEdit ? <Button type="button" icon={<Plus size={18} />} onClick={startNew}>Nuevo proveedor</Button> : undefined}
      />

      {notice && (
        <p
          role="status"
          className={`rounded-lg p-3 text-sm font-semibold ${
            notice.type === "error"
              ? "bg-rose-50 text-rose-700 dark:bg-rose-400/10 dark:text-rose-200"
              : "bg-emerald-50 text-emerald-700 dark:bg-emerald-400/10 dark:text-emerald-200"
          }`}
        >
          {notice.text}
        </p>
      )}

      {formOpen && canEdit && (
        <form onSubmit={submit} className="space-y-4 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
          <div className="flex items-center justify-between gap-3">
            <h2 className="text-lg font-extrabold">{form.id ? "Editar proveedor" : "Registrar proveedor"}</h2>
            <Button type="button" variant="ghost" icon={<X size={18} />} onClick={() => setFormOpen(false)}>Cerrar</Button>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <Field label="Nombre comercial o razón social">
              <input className={inputClass} required maxLength={240} autoFocus value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} />
            </Field>
            <Field label="Tipo de proveedor">
              <select className={inputClass} value={form.category} onChange={(event) => setForm({ ...form, category: event.target.value as SupplierCategory })}>
                {categories.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
              </select>
            </Field>
            <Field label="Persona de contacto">
              <input className={inputClass} maxLength={200} value={form.contact} onChange={(event) => setForm({ ...form, contact: event.target.value })} />
            </Field>
            <Field label="Teléfono">
              <input className={inputClass} type="tel" maxLength={80} value={form.phone} onChange={(event) => setForm({ ...form, phone: event.target.value })} />
            </Field>
            <Field label="Correo electrónico">
              <input className={inputClass} type="email" maxLength={320} value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })} />
            </Field>
            <Field label="Dirección">
              <input className={inputClass} maxLength={500} value={form.address} onChange={(event) => setForm({ ...form, address: event.target.value })} />
            </Field>
            <Field label="Productos o servicios que ofrece">
              <input className={inputClass} maxLength={1000} value={form.productsServices} onChange={(event) => setForm({ ...form, productsServices: event.target.value })} />
            </Field>
            {canEdit && (
              <>
                <Field label="Identificación fiscal (opcional)">
                  <input className={inputClass} maxLength={40} value={form.ruc} onChange={(event) => setForm({ ...form, ruc: event.target.value })} />
                </Field>
                <Field label="Condiciones de pago">
                  <input className={inputClass} maxLength={80} value={form.paymentTerms} onChange={(event) => setForm({ ...form, paymentTerms: event.target.value })} />
                </Field>
              </>
            )}
            <Field label="Estado">
              <select className={inputClass} value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value as SupplierStatus })}>
                {statuses.filter((item) => item.value !== "todos").map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
              </select>
            </Field>
            <Field label="Próxima revisión (opcional)">
              <input className={inputClass} type="date" value={form.nextReviewDate} onChange={(event) => setForm({ ...form, nextReviewDate: event.target.value })} />
            </Field>
            <div className="sm:col-span-2 lg:col-span-3">
              <Field label="Observaciones">
                <textarea className={`${inputClass} min-h-24 py-2`} maxLength={2000} value={form.observations} onChange={(event) => setForm({ ...form, observations: event.target.value })} />
              </Field>
            </div>
          </div>
          <p className="text-xs text-slate-500">Debes proporcionar al menos un medio de contacto: teléfono o correo electrónico.</p>
          <div className="flex flex-wrap gap-2">
            <Button type="submit">{form.id ? "Guardar cambios" : "Guardar proveedor"}</Button>
            <Button type="button" variant="secondary" onClick={() => setFormOpen(false)}>Cancelar</Button>
          </div>
        </form>
      )}

      <section className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-[minmax(0,1fr)_auto_auto]">
        <label className="relative block">
          <span className="sr-only">Buscar proveedor</span>
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            className={`${inputClass} pl-10`}
            placeholder="Buscar por nombre, producto o contacto"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </label>
        <label>
          <span className="sr-only">Filtrar por tipo de proveedor</span>
          <select className={inputClass} value={categoryFilter} onChange={(event) => setCategoryFilter(event.target.value as SupplierCategory | "todos")}>
            <option value="todos">Todos los tipos</option>
            {categories.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
          </select>
        </label>
        <label>
          <span className="sr-only">Filtrar por estado</span>
          <select className={inputClass} value={statusFilter} onChange={(event) => setStatusFilter(event.target.value as SupplierStatus | "todos")}>
            {statuses.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
          </select>
        </label>
      </section>

      {filteredSuppliers.length ? (
        <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-3" aria-label="Lista de proveedores">
          {filteredSuppliers.map((party) => {
            const status = supplierStatus(party);
            const category = categories.find((item) => item.value === (party.category ?? "otro"))?.label ?? "Otro";
            const latestPurchase = db.purchases
              .filter((purchase) => purchase.supplierId === party.id || purchase.supplierName === party.name)
              .sort((a, b) => b.purchaseDate.localeCompare(a.purchaseDate))[0];
            return (
              <article key={party.id} className="flex flex-col rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <h2 className="break-words text-lg font-extrabold">{party.name}</h2>
                    <p className="mt-1 text-sm text-slate-500">{category}</p>
                  </div>
                  <StatusPill tone={statusTone(status)}>{status}</StatusPill>
                </div>
                <div className="mt-4 space-y-2 text-sm">
                  {party.contact && <p className="font-semibold">{party.contact}</p>}
                  {party.phone && <p className="flex items-center gap-2 text-slate-600 dark:text-slate-300"><Phone size={15} />{party.phone}</p>}
                  {party.email && <p className="flex min-w-0 items-center gap-2 text-slate-600 dark:text-slate-300"><Mail size={15} /><span className="break-all">{party.email}</span></p>}
                  {party.productsServices && <p className="text-slate-500">Ofrece: {party.productsServices}</p>}
                  <p className="text-xs text-slate-500">Última compra: {latestPurchase ? new Date(latestPurchase.purchaseDate).toLocaleDateString("es-NI") : "Sin compras registradas"}</p>
                </div>
                <div className="mt-auto flex flex-wrap gap-2 pt-4">
                  {canEdit && <Button type="button" variant="ghost" icon={<Pencil size={16} />} onClick={() => startEdit(party)}>Editar</Button>}
                  <Button type="button" variant="secondary" icon={<Eye size={16} />} onClick={() => setSelectedId(selectedId === party.id ? null : party.id)}>
                    Ver detalle e historial
                  </Button>
                </div>
              </article>
            );
          })}
        </section>
      ) : (
        <div className="rounded-lg bg-white p-8 text-center text-sm text-slate-500 shadow-soft dark:bg-slate-900">
          No se encontraron proveedores con esos criterios.
        </div>
      )}

      {selected && (
        <section className="space-y-4 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div>
              <p className="text-sm font-bold uppercase tracking-wide text-brand-700">Detalle del proveedor</p>
              <h2 className="text-xl font-extrabold">{selected.name}</h2>
            </div>
            <Button type="button" variant="ghost" icon={<X size={18} />} onClick={() => setSelectedId(null)}>Cerrar</Button>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <p className="text-sm text-slate-500">Fecha de registro: {selected.createdAt ? new Date(selected.createdAt).toLocaleDateString("es-NI") : "Sin fecha registrada"}</p>
            <p className="text-sm text-slate-500">Fecha de próxima revisión: {selected.nextReviewDate ? new Date(`${selected.nextReviewDate}T12:00:00`).toLocaleDateString("es-NI") : "No programada"}</p>
            {selected.address && <p className="flex items-start gap-2 text-sm"><MapPin size={16} className="mt-0.5 shrink-0" />{selected.address}</p>}
            {selected.productsServices && <p className="text-sm"><strong>Productos/servicios:</strong> {selected.productsServices}</p>}
            {selected.observations && <p className="text-sm"><strong>Observaciones:</strong> {selected.observations}</p>}
            {canEdit && selected.ruc && <p className="text-sm"><strong>Identificación fiscal:</strong> {selected.ruc}</p>}
            {canEdit && selected.paymentTerms && <p className="text-sm"><strong>Condiciones de pago:</strong> {selected.paymentTerms}</p>}
            {selected.updatedAt && <p className="text-sm text-slate-500">Última actualización: {new Date(selected.updatedAt).toLocaleString("es-NI")}</p>}
          </div>
          <div>
            <h3 className="mb-2 flex items-center gap-2 font-bold"><History size={17} />Compras relacionadas ({purchaseHistory.length})</h3>
            {purchaseHistory.length ? (
              <ul className="divide-y divide-slate-100 dark:divide-white/10">
                {purchaseHistory.map((purchase) => (
                  <li key={purchase.id} className="flex flex-wrap items-center justify-between gap-2 py-2 text-sm">
                    <span className="font-semibold">{purchase.purchaseNumber} · {purchase.status === "received" ? "Recibida" : "Ordenada"}</span>
                    <span className="text-slate-500">{new Date(purchase.purchaseDate).toLocaleDateString("es-NI")}</span>
                    <span className="font-bold"><Money value={purchase.total} /></span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-slate-500">Este proveedor todavía no tiene compras registradas.</p>
            )}
          </div>
        </section>
      )}
    </div>
  );
}
