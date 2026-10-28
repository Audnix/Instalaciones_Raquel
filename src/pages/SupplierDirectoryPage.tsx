import { getApiBaseUrl } from '../lib/apiBase';
import { useCallback, useEffect, useMemo, useRef, useState, type FormEvent, type ReactNode } from "react";
import {
  AlertTriangle,
  Building2,
  Calendar,
  Check,
  CheckCircle2,
  Clock,
  Download,
  Eye,
  EyeOff,
  FileCheck2,
  FileSpreadsheet,
  FileText,
  History,
  LayoutGrid,
  Mail,
  MapPin,
  Pencil,
  Phone,
  Plus,
  RefreshCw,
  Search,
  ShieldAlert,
  ShieldCheck,
  Table,
  Truck,
  User,
  X
} from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";
import { Field, inputClass, PageHeader, StatusPill } from "../components/Ui";

const API = getApiBaseUrl();
const box = "rounded-2xl border border-slate-200 bg-white p-5 dark:border-white/10 dark:bg-slate-900";

export type SupplierContact = {
  name: string;
  role: string;
  phone: string;
  email: string;
};

export type SupplierDoc = {
  id: string;
  title: string;
  type: string;
  reference: string;
  issuedOn: string;
  expiresOn: string;
  review: "pendiente" | "aceptado" | "rechazado";
  reviewNote: string;
  fileName: string;
  fileType: string;
  uploadedAt: string;
  reviewedAt: string;
  reviewedBy: string;
};

export type SupplierRecord = {
  id: string;
  name: string;
  legalName: string;
  category: "materiales" | "servicios" | "transporte" | "herramientas" | "otro";
  specialty: "perfiles" | "vidrio" | "herrajes" | "consumibles" | "transporte" | "servicios" | "otro";
  contact: string;
  contactRole: string;
  phone: string;
  email: string;
  address: string;
  dispatchAddress: string;
  productsServices: string;
  ruc: string;
  paymentTerms: string;
  currency: "NIO" | "USD";
  leadDays: number | null;
  bankDetails: string;
  discounts: string;
  transportTerms: string;
  observations: string;
  status: "activo" | "pendiente" | "inactivo";
  reviewStatus: "pendiente" | "en_revision" | "aprobado" | "rechazado";
  reviewEvidence: string;
  nextReviewDate: string;
  contacts: SupplierContact[];
  documents: SupplierDoc[];
  createdAt: string;
  updatedAt: string;
  updatedBy: string;
  reviewedAt: string;
  reviewedBy: string;
  inactiveAt: string;
  version: string | null;
};

export type PurchaseLinked = {
  id: string;
  number: string;
  date: string;
  status: string;
  total: number;
  paymentId?: string;
  paymentDate?: string;
  paidAmount?: number;
};

export type AuditEvent = {
  id: string;
  actor: string;
  at: string;
  reason: string;
  beforeData: unknown;
  afterData: unknown;
};

export type SupplierDetail = {
  supplier: SupplierRecord;
  events: AuditEvent[];
  purchases: PurchaseLinked[];
  files: { id: string; name: string }[];
};

type Rights = {
  read: boolean;
  write: boolean;
  approve: boolean;
};

const categoriesMap: Record<string, string> = {
  materiales: "Materiales",
  servicios: "Servicios",
  transporte: "Transporte",
  herramientas: "Herramientas",
  otro: "Otro"
};

const specialtiesMap: Record<string, string> = {
  perfiles: "Perfiles de aluminio",
  vidrio: "Vidrio y templados",
  herrajes: "Herrajes y accesorios",
  consumibles: "Consumibles y selladores",
  transporte: "Transporte y fletes",
  servicios: "Servicios técnicos",
  otro: "Otra especialidad"
};

const reviewsMap: Record<string, string> = {
  pendiente: "Pendiente",
  en_revision: "En revisión",
  aprobado: "Aprobado internamente",
  rechazado: "Rechazado"
};

const statesMap: Record<string, string> = {
  pendiente: "Pendiente",
  activo: "Activo",
  inactivo: "Inactivo"
};

const blankSupplier = (): SupplierRecord => ({
  id: `PRV-${Date.now().toString().slice(-4)}`,
  name: "",
  legalName: "",
  category: "materiales",
  specialty: "perfiles",
  contact: "",
  contactRole: "",
  phone: "",
  email: "",
  address: "",
  dispatchAddress: "",
  productsServices: "",
  ruc: "",
  paymentTerms: "Contado contra entrega",
  currency: "NIO",
  leadDays: 3,
  bankDetails: "",
  discounts: "",
  transportTerms: "",
  observations: "",
  status: "activo",
  reviewStatus: "pendiente",
  reviewEvidence: "",
  nextReviewDate: "",
  contacts: [],
  documents: [],
  createdAt: "",
  updatedAt: "",
  updatedBy: "",
  reviewedAt: "",
  reviewedBy: "",
  inactiveAt: "",
  version: null
});

const blankDoc = (): SupplierDoc => ({
  id: crypto.randomUUID(),
  title: "",
  type: "Fiscal",
  reference: "",
  issuedOn: "",
  expiresOn: "",
  review: "pendiente",
  reviewNote: "",
  fileName: "",
  fileType: "",
  uploadedAt: "",
  reviewedAt: "",
  reviewedBy: ""
});

function todayManagua() {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Managua",
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).format(new Date());
}

function formatDate(v: string | undefined, includeTime = false) {
  if (!v) return "Sin registrar";
  const d = new Date(v.length === 10 ? `${v}T12:00:00-06:00` : v);
  if (Number.isNaN(d.getTime())) return "Fecha no válida";
  return new Intl.DateTimeFormat("es-NI", {
    timeZone: "America/Managua",
    dateStyle: "medium",
    ...(includeTime ? { timeStyle: "short" as const } : {})
  }).format(d);
}

function getSupplierAlerts(s: SupplierRecord, alertDays: number) {
  const current = todayManagua();
  const future = new Date(Date.now() + alertDays * 86400000).toISOString().slice(0, 10);
  const items: { level: "warn" | "bad"; text: string; date: string }[] = [];

  if (s.nextReviewDate && s.nextReviewDate <= future) {
    const overdue = s.nextReviewDate < current;
    items.push({
      level: overdue ? "bad" : "warn",
      text: overdue ? "Revisión técnica atrasada" : "Revisión técnica próxima",
      date: s.nextReviewDate
    });
  }

  for (const doc of s.documents) {
    if (doc.expiresOn && doc.expiresOn <= future) {
      const expired = doc.expiresOn < current;
      items.push({
        level: expired ? "bad" : "warn",
        text: `${expired ? "Doc. vencido" : "Doc. por vencer"}: ${doc.title}`,
        date: doc.expiresOn
      });
    }
  }

  if (s.status === "inactivo") {
    items.push({
      level: "bad",
      text: "Proveedor inactivo para compras",
      date: s.inactiveAt || s.updatedAt || ""
    });
  }

  if (!s.ruc) {
    items.push({
      level: "warn",
      text: "Expediente sin identificación fiscal (RUC)",
      date: s.createdAt || ""
    });
  }

  return items;
}

function blobDownload(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function DetailItem({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div>
      <dt className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">{label}</dt>
      <dd className="mt-1 whitespace-pre-wrap break-words text-sm text-slate-900 dark:text-slate-100">
        {children || <span className="italic text-slate-400">Sin registrar</span>}
      </dd>
    </div>
  );
}

export default function SupplierDirectoryPage() {
  const { token, user } = useAuth();
  const [rows, setRows] = useState<SupplierRecord[]>([]);
  const [rights, setRights] = useState<Rights>({ read: false, write: false, approve: false });
  const [loading, setLoading] = useState(true);
  const [online, setOnline] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [saving, setSaving] = useState(false);

  // View mode: Table vs Cards
  const [viewMode, setViewMode] = useState<"table" | "cards">("table");

  // Filters & Search
  const [query, setQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("todos");
  const [specialtyFilter, setSpecialtyFilter] = useState("todos");
  const [statusFilter, setStatusFilter] = useState("todos");
  const [reviewFilter, setReviewFilter] = useState("todos");
  const [alertFilter, setAlertFilter] = useState<"todos" | "alertas" | "pendientes">("todos");
  const [alertDays, setAlertDays] = useState(30);
  const [dateField, setDateField] = useState<"createdAt" | "updatedAt" | "nextReviewDate" | "reviewedAt">("createdAt");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [sortField, setSortField] = useState("name");
  const [page, setPage] = useState(1);
  const itemsPerPage = 10;

  // Expediente Drawer
  const [detail, setDetail] = useState<SupplierDetail | null>(null);
  const [detailTab, setDetailTab] = useState<
    "Resumen" | "Contactos" | "Condiciones" | "Productos" | "Compras" | "Documentos" | "Evaluación" | "Historial"
  >("Resumen");
  const [detailBusy, setDetailBusy] = useState(false);
  const [showSensitiveBank, setShowSensitiveBank] = useState(false);

  // Form Modal
  const [form, setForm] = useState<SupplierRecord | null>(null);
  const [formTab, setFormTab] = useState<"identificacion" | "contactos" | "condiciones" | "homologacion">("identificacion");
  const [reason, setReason] = useState("");
  const [baseline, setBaseline] = useState("");
  const [saveError, setSaveError] = useState("");

  // Document Upload
  const [docModal, setDocModal] = useState<SupplierDoc | null>(null);
  const [docFile, setDocFile] = useState<File | null>(null);

  // Comparator Tool
  const [compareModalOpen, setCompareModalOpen] = useState(false);
  const [selectedToCompare, setSelectedToCompare] = useState<string[]>([]);

  const attempt = useRef<{ fingerprint: string; id: string } | null>(null);
  const sequence = useRef(0);

  const api = useCallback(
    async (path: string, init: RequestInit = {}) => {
      const res = await fetch(`${API}/api/supplier-directory${path}`, {
        ...init,
        headers: {
          ...init.headers,
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json"
        }
      });
      if (!res.ok) {
        const d = await res.json().catch(() => ({}));
        throw new Error(d.message || `No se pudo completar la operación (${res.status}).`);
      }
      return res;
    },
    [token]
  );

  const loadData = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await api("/");
      const data = await res.json();
      setRows(
        data.suppliers.map((s: SupplierRecord) => ({
          ...blankSupplier(),
          ...s,
          contacts: s.contacts ?? [],
          documents: s.documents ?? [],
          nextReviewDate: s.nextReviewDate ?? ""
        }))
      );
      setRights(data.permissions);
      setOnline(true);
    } catch (e) {
      setError((e as Error).message);
      setOnline(false);
      setRows([]);
      setDetail(null);
      setRights({ read: false, write: false, approve: false });
    } finally {
      setLoading(false);
    }
  }, [api]);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  const isFormDirty = form !== null && JSON.stringify({ form, reason }) !== baseline;

  useEffect(() => {
    if (!isFormDirty && !docModal) return;
    const prevent = (e: BeforeUnloadEvent) => {
      e.preventDefault();
      e.returnValue = "";
    };
    window.addEventListener("beforeunload", prevent);
    return () => window.removeEventListener("beforeunload", prevent);
  }, [isFormDirty, docModal]);

  useEffect(() => {
    setPage(1);
  }, [query, categoryFilter, specialtyFilter, statusFilter, reviewFilter, alertFilter, alertDays, dateField, dateFrom, dateTo, sortField]);

  async function openExpediente(id: string) {
    const currentSeq = ++sequence.current;
    setDetailBusy(true);
    setError("");
    setShowSensitiveBank(false);
    try {
      const res = await api(`/${encodeURIComponent(id)}`);
      const data: SupplierDetail = await res.json();
      if (currentSeq === sequence.current) {
        setDetail({
          ...data,
          supplier: {
            ...blankSupplier(),
            ...data.supplier,
            contacts: data.supplier.contacts ?? [],
            documents: data.supplier.documents ?? [],
            nextReviewDate: data.supplier.nextReviewDate ?? ""
          }
        });
      }
    } catch (e) {
      setError((e as Error).message);
    } finally {
      if (currentSeq === sequence.current) {
        setDetailBusy(false);
      }
    }
  }

  function startForm(supplier?: SupplierRecord) {
    if (isFormDirty && !window.confirm("¿Deseas descartar los cambios no guardados?")) return;
    const initial = supplier ? structuredClone(supplier) : blankSupplier();
    setForm(initial);
    setFormTab("identificacion");
    setReason("");
    setBaseline(JSON.stringify({ form: initial, reason: "" }));
    setSaveError("");
    attempt.current = null;
  }

  function closeForm() {
    if (saving) return;
    if (isFormDirty && !window.confirm("¿Deseas descartar los cambios no guardados?")) return;
    setForm(null);
  }

  async function persistSupplier(
    s: SupplierRecord,
    why: string,
    attachment?: { documentId: string; content: string }
  ) {
    const data = {
      name: s.name,
      legalName: s.legalName,
      category: s.category,
      specialty: s.specialty,
      contact: s.contact,
      contactRole: s.contactRole,
      phone: s.phone,
      email: s.email,
      address: s.address,
      dispatchAddress: s.dispatchAddress,
      productsServices: s.productsServices,
      ruc: s.ruc,
      paymentTerms: s.paymentTerms,
      currency: s.currency,
      leadDays: s.leadDays,
      bankDetails: s.bankDetails,
      discounts: s.discounts,
      transportTerms: s.transportTerms,
      observations: s.observations,
      status: s.status,
      reviewStatus: s.reviewStatus,
      reviewEvidence: s.reviewEvidence,
      nextReviewDate: s.nextReviewDate,
      contacts: s.contacts,
      documents: s.documents,
      expectedVersion: s.version,
      reason: why,
      ...(attachment ? { attachment } : {})
    };

    const fingerprint = JSON.stringify({ id: s.id, ...data });
    if (attempt.current?.fingerprint !== fingerprint) {
      attempt.current = { fingerprint, id: crypto.randomUUID() };
    }

    setSaving(true);
    setSaveError("");
    setNotice("");

    try {
      const res = await api(`/${encodeURIComponent(s.id)}`, {
        method: "PUT",
        body: JSON.stringify({ ...data, mutationId: attempt.current.id })
      });
      const result = await res.json();
      if (!result.saved) throw new Error("El servidor no confirmó el guardado.");
      attempt.current = null;
      setNotice(`Operación confirmada en SQL Server. Expediente de "${s.name}" sincronizado con éxito.`);
      await loadData();
      await openExpediente(s.id);
      return true;
    } catch (e) {
      setSaveError((e as Error).message);
      return false;
    } finally {
      setSaving(false);
    }
  }

  async function handleFormSubmit(e: FormEvent) {
    e.preventDefault();
    if (!form) return;

    // Validation
    if (!form.name.trim()) {
      setSaveError("El nombre comercial es obligatorio.");
      setFormTab("identificacion");
      return;
    }
    if (!form.phone.trim() && !form.email.trim()) {
      setSaveError("Debes indicar al menos un canal de contacto: teléfono o correo electrónico.");
      setFormTab("contactos");
      return;
    }
    if (["aprobado", "rechazado"].includes(form.reviewStatus) && !form.reviewEvidence.trim()) {
      setSaveError("Para aprobar o rechazar internamente se requiere documentar el fundamento o evidencia.");
      setFormTab("homologacion");
      return;
    }
    if (!reason.trim() || reason.trim().length < 3) {
      setSaveError("Indica un motivo claro de la modificación (mínimo 3 caracteres).");
      return;
    }

    if (await persistSupplier(form, reason)) {
      setForm(null);
      setBaseline("");
    }
  }

  async function handleAddDocSubmit(e: FormEvent) {
    e.preventDefault();
    if (!detail || !docModal) return;

    if (!docModal.title.trim()) {
      setSaveError("El título del documento es obligatorio.");
      return;
    }

    try {
      let attachment;
      if (docFile) {
        if (docFile.size > 3 * 1024 * 1024) throw new Error("El archivo excede el límite máximo de 3 MB.");
        const content = await new Promise<string>((resolve, reject) => {
          const reader = new FileReader();
          reader.onload = () => resolve(String(reader.result).split(",")[1]);
          reader.onerror = () => reject(new Error("No se pudo leer el archivo seleccionado."));
          reader.readAsDataURL(docFile);
        });
        attachment = { documentId: docModal.id, content };
      }

      const newDoc: SupplierDoc = {
        ...docModal,
        fileName: docFile?.name ?? "",
        fileType: docFile?.type ?? ""
      };

      if (
        await persistSupplier(
          { ...detail.supplier, documents: [...detail.supplier.documents, newDoc] },
          `Documento incorporado al expediente: ${docModal.title}`,
          attachment
        )
      ) {
        setDocModal(null);
        setDocFile(null);
      }
    } catch (e) {
      setSaveError((e as Error).message);
    }
  }

  async function handleReviewDoc(d: SupplierDoc, statusValue: "aceptado" | "rechazado") {
    if (!detail) return;
    const note = window.prompt(`Ingresa el fundamento de la revisión (${statusValue}):`);
    if (!note || !note.trim()) return;

    await persistSupplier(
      {
        ...detail.supplier,
        documents: detail.supplier.documents.map((x) =>
          x.id === d.id ? { ...x, review: statusValue, reviewNote: note.trim() } : x
        )
      },
      `Revisión documental: ${d.title} (${statusValue})`
    );
  }

  async function handleDownloadDoc(d: SupplierDoc) {
    if (!detail) return;
    try {
      const res = await api(`/${encodeURIComponent(detail.supplier.id)}/documents/${d.id}`);
      const blob = await res.blob();
      blobDownload(blob, d.fileName || `documento-${d.id}.pdf`);
    } catch (e) {
      setError((e as Error).message);
    }
  }

  // Filtering
  const filtered = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase();
    return rows
      .filter((s) => {
        const hay = [
          s.id,
          s.name,
          s.legalName,
          s.ruc,
          s.contact,
          s.phone,
          s.email,
          s.productsServices,
          ...s.contacts.map((c) => `${c.name} ${c.phone} ${c.email}`)
        ]
          .join(" ")
          .toLocaleLowerCase();

        const matchQuery = !needle || hay.includes(needle);
        const matchCat = categoryFilter === "todos" || s.category === categoryFilter;
        const matchSpec = specialtyFilter === "todos" || s.specialty === specialtyFilter;
        const matchStat = statusFilter === "todos" || s.status === statusFilter;
        const matchRev = reviewFilter === "todos" || s.reviewStatus === reviewFilter;

        const alertsList = getSupplierAlerts(s, alertDays);
        const matchAlert =
          alertFilter === "todos" ||
          (alertFilter === "alertas" && alertsList.length > 0) ||
          (alertFilter === "pendientes" && s.reviewStatus !== "aprobado");

        const targetDate = String(s[dateField] ?? "").slice(0, 10);
        const matchFrom = !dateFrom || (targetDate && targetDate >= dateFrom);
        const matchTo = !dateTo || (targetDate && targetDate <= dateTo);

        return matchQuery && matchCat && matchSpec && matchStat && matchRev && matchAlert && matchFrom && matchTo;
      })
      .sort((a, b) => {
        if (sortField === "name") return a.name.localeCompare(b.name, "es");
        if (sortField === "leadDays") return (a.leadDays ?? 999) - (b.leadDays ?? 999);
        return String(a[sortField as keyof SupplierRecord] || "9999").localeCompare(
          String(b[sortField as keyof SupplierRecord] || "9999")
        );
      });
  }, [rows, query, categoryFilter, specialtyFilter, statusFilter, reviewFilter, alertFilter, alertDays, dateField, dateFrom, dateTo, sortField]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / itemsPerPage));
  const currentPage = Math.min(page, totalPages);
  const pagedRows = filtered.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  function exportCSV() {
    const escapeCsv = (val: unknown) => {
      const str = String(val ?? "");
      return `"${(/^[=+@\-\t\r]/.test(str) ? "'" : "") + str.replace(/"/g, '""')}"`;
    };

    const headers = [
      "Código",
      "Nombre comercial",
      "Razón social",
      "RUC",
      "Categoría",
      "Especialidad",
      "Estado operativo",
      "Revisión interna",
      "Contacto principal",
      "Teléfono",
      "Correo",
      "Condiciones de pago",
      "Plazo entrega (días)",
      "Próxima revisión",
      "Fecha registro"
    ];

    const body = filtered.map((s) => [
      s.id,
      s.name,
      s.legalName,
      s.ruc,
      categoriesMap[s.category] ?? s.category,
      specialtiesMap[s.specialty] ?? s.specialty,
      statesMap[s.status] ?? s.status,
      reviewsMap[s.reviewStatus] ?? s.reviewStatus,
      s.contact,
      s.phone,
      s.email,
      s.paymentTerms,
      s.leadDays ?? "",
      s.nextReviewDate,
      s.createdAt
    ]);

    const csvContent = "\uFEFF" + [headers, ...body].map((r) => r.map(escapeCsv).join(",")).join("\r\n");
    blobDownload(new Blob([csvContent], { type: "text/csv;charset=utf-8" }), "directorio-proveedores.csv");
  }

  function resetFilters() {
    setQuery("");
    setCategoryFilter("todos");
    setSpecialtyFilter("todos");
    setStatusFilter("todos");
    setReviewFilter("todos");
    setAlertFilter("todos");
    setDateFrom("");
    setDateTo("");
    setSortField("name");
  }

  // Active supplier in detail
  const s = detail?.supplier;

  return (
    <div className="space-y-6">
      {/* 1. Header con acciones principales */}
      <PageHeader
        kicker="Cadena de suministro · Compras"
        title="Directorio de proveedores"
        subtitle="Contactos verificados, homologación con evidencia técnica y seguimiento de compromisos a tiempo."
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <Button variant="secondary" disabled={loading || saving} onClick={() => void loadData()} icon={<RefreshCw size={16} />}>
              Actualizar
            </Button>
            <Button
              variant="secondary"
              onClick={() => {
                setSelectedToCompare(rows.slice(0, 3).map((r) => r.id));
                setCompareModalOpen(true);
              }}
              icon={<FileSpreadsheet size={16} />}
            >
              Comparar condiciones
            </Button>
            {rights.approve && online && (
              <Button variant="secondary" onClick={exportCSV} icon={<Download size={16} />}>
                Exportar CSV
              </Button>
            )}
            {rights.write && online && (
              <Button onClick={() => startForm()} icon={<Plus size={16} />}>
                Nuevo proveedor
              </Button>
            )}
          </div>
        }
      />

      {/* Estado de conexión y alertas del sistema */}
      <div className="flex flex-wrap items-center justify-between gap-3 text-sm">
        <p className="flex items-center gap-2 font-medium text-slate-600 dark:text-slate-300">
          <span
            className={`inline-block h-2.5 w-2.5 rounded-full ${
              online ? "bg-emerald-500 shadow-sm shadow-emerald-500/50" : "bg-rose-500 animate-pulse"
            }`}
          />
          {loading
            ? "Verificando conexión con SQL Server…"
            : online
            ? "Conectado a SQL Server · Zona horaria Managua (-06:00) · Concurrencia optimista activa"
            : "Sin conexión con SQL Server. Los datos se preservan en memoria hasta restablecer conexión."}
        </p>

        {/* Alternador de vista: Tabla / Tarjetas */}
        <div className="flex items-center gap-1 rounded-lg border border-slate-200 bg-slate-50 p-1 dark:border-white/10 dark:bg-slate-800">
          <button
            type="button"
            className={`flex items-center gap-1.5 rounded-md px-3 py-1 text-xs font-bold transition-colors ${
              viewMode === "table"
                ? "bg-white text-brand-700 shadow-sm dark:bg-slate-900 dark:text-white"
                : "text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
            }`}
            onClick={() => setViewMode("table")}
          >
            <Table size={14} /> Tabla compacta
          </button>
          <button
            type="button"
            className={`flex items-center gap-1.5 rounded-md px-3 py-1 text-xs font-bold transition-colors ${
              viewMode === "cards"
                ? "bg-white text-brand-700 shadow-sm dark:bg-slate-900 dark:text-white"
                : "text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
            }`}
            onClick={() => setViewMode("cards")}
          >
            <LayoutGrid size={14} /> Tarjetas
          </button>
        </div>
      </div>

      {error && (
        <div role="alert" className="flex items-center gap-3 rounded-xl border border-rose-400 bg-rose-50 p-4 text-rose-800 dark:bg-rose-950 dark:text-rose-200">
          <ShieldAlert className="shrink-0" size={20} />
          <p className="text-sm font-medium">{error}</p>
        </div>
      )}

      {notice && (
        <div role="status" className="flex items-center gap-3 rounded-xl border border-emerald-400 bg-emerald-50 p-4 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200">
          <CheckCircle2 className="shrink-0" size={20} />
          <p className="text-sm font-medium">{notice}</p>
        </div>
      )}

      {/* 2. Tarjetas Resumen KPI con filtrado interactivo */}
      <section aria-label="Indicadores ejecutivos" className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <button
          type="button"
          disabled={!online}
          className={`${box} text-left transition hover:border-brand-500 focus-visible:ring-2 focus-visible:ring-brand-500`}
          onClick={() => {
            setStatusFilter("activo");
            setReviewFilter("todos");
            setAlertFilter("todos");
          }}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Proveedores activos</span>
            <Building2 className="text-emerald-600" size={20} />
          </div>
          <strong className="mt-2 block text-3xl font-black text-slate-900 dark:text-white">
            {online ? rows.filter((x) => x.status === "activo").length : "—"}
          </strong>
          <span className="text-xs text-slate-500">Habilitados para emitir órdenes</span>
        </button>

        <button
          type="button"
          disabled={!online}
          className={`${box} text-left transition hover:border-brand-500 focus-visible:ring-2 focus-visible:ring-brand-500`}
          onClick={() => {
            setStatusFilter("todos");
            setReviewFilter("todos");
            setAlertFilter("pendientes");
          }}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Revisiones pendientes</span>
            <Clock className="text-amber-500" size={20} />
          </div>
          <strong className="mt-2 block text-3xl font-black text-amber-600 dark:text-amber-400">
            {online ? rows.filter((x) => x.reviewStatus !== "aprobado").length : "—"}
          </strong>
          <span className="text-xs text-slate-500">Requieren validación técnica</span>
        </button>

        <button
          type="button"
          disabled={!online}
          className={`${box} text-left transition hover:border-brand-500 focus-visible:ring-2 focus-visible:ring-brand-500`}
          onClick={() => {
            setAlertFilter("alertas");
            setStatusFilter("todos");
            setReviewFilter("todos");
          }}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Avisos por vencer</span>
            <AlertTriangle className="text-rose-500" size={20} />
          </div>
          <strong className="mt-2 block text-3xl font-black text-rose-600 dark:text-rose-400">
            {online ? rows.filter((x) => getSupplierAlerts(x, alertDays).length > 0).length : "—"}
          </strong>
          <span className="text-xs text-slate-500">En los próximos {alertDays} días</span>
        </button>

        <div className={`${box} text-left`}>
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Homologación interna</span>
            <ShieldCheck className="text-brand-600" size={20} />
          </div>
          <strong className="mt-2 block text-3xl font-black text-brand-700 dark:text-glass">
            {online ? rows.filter((x) => x.reviewStatus === "aprobado").length : "—"}
          </strong>
          <span className="text-xs text-slate-500">Aprobados por Comité de Compras</span>
        </div>
      </section>

      {/* 3. Panel de Búsqueda y Filtros */}
      <section className={`${box} space-y-4`} aria-label="Buscador y filtros avanzados">
        <div className="grid gap-3 md:grid-cols-4">
          <div className="md:col-span-2">
            <Field label="Buscador general">
              <div className="relative">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  className={`${inputClass} pl-9`}
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Buscar por código, nombre, razón social, RUC o producto…"
                />
              </div>
            </Field>
          </div>

          <Field label="Categoría comercial">
            <select className={inputClass} value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}>
              <option value="todos">Todas las categorías</option>
              {Object.entries(categoriesMap).map(([k, v]) => (
                <option key={k} value={k}>{v}</option>
              ))}
            </select>
          </Field>

          <Field label="Especialidad técnica">
            <select className={inputClass} value={specialtyFilter} onChange={(e) => setSpecialtyFilter(e.target.value)}>
              <option value="todos">Todas las especialidades</option>
              {Object.entries(specialtiesMap).map(([k, v]) => (
                <option key={k} value={k}>{v}</option>
              ))}
            </select>
          </Field>
        </div>

        <div className="grid gap-3 sm:grid-cols-2 md:grid-cols-4">
          <Field label="Estado operativo">
            <select className={inputClass} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
              <option value="todos">Todos los estados</option>
              {Object.entries(statesMap).map(([k, v]) => (
                <option key={k} value={k}>{v}</option>
              ))}
            </select>
          </Field>

          <Field label="Estado de revisión">
            <select className={inputClass} value={reviewFilter} onChange={(e) => setReviewFilter(e.target.value)}>
              <option value="todos">Todas las resoluciones</option>
              {Object.entries(reviewsMap).map(([k, v]) => (
                <option key={k} value={k}>{v}</option>
              ))}
            </select>
          </Field>

          <Field label="Alertas y compromisos">
            <select className={inputClass} value={alertFilter} onChange={(e) => setAlertFilter(e.target.value as any)}>
              <option value="todos">Todos los registros</option>
              <option value="alertas">Con alertas o vencimientos</option>
              <option value="pendientes">Pendientes de aprobación</option>
            </select>
          </Field>

          <Field label="Ventana de aviso">
            <select className={inputClass} value={String(alertDays)} onChange={(e) => setAlertDays(Number(e.target.value))}>
              <option value="15">Próximos 15 días</option>
              <option value="30">Próximos 30 días</option>
              <option value="60">Próximos 60 días</option>
              <option value="90">Próximos 90 días</option>
            </select>
          </Field>
        </div>

        <details className="text-sm">
          <summary className="cursor-pointer font-semibold text-brand-700 dark:text-glass">
            Filtros avanzados por rango de fechas y ordenación
          </summary>
          <div className="mt-3 grid gap-3 md:grid-cols-4">
            <Field label="Filtrar por campo de fecha">
              <select className={inputClass} value={dateField} onChange={(e) => setDateField(e.target.value as any)}>
                <option value="createdAt">Fecha de registro</option>
                <option value="updatedAt">Última actualización</option>
                <option value="nextReviewDate">Próxima revisión</option>
                <option value="reviewedAt">Última revisión realizada</option>
              </select>
            </Field>

            <Field label="Fecha desde">
              <input className={inputClass} type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
            </Field>

            <Field label="Fecha hasta">
              <input className={inputClass} type="date" min={dateFrom} value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
            </Field>

            <Field label="Ordenar por">
              <select className={inputClass} value={sortField} onChange={(e) => setSortField(e.target.value)}>
                <option value="name">Nombre comercial</option>
                <option value="nextReviewDate">Próxima revisión</option>
                <option value="createdAt">Fecha de registro</option>
                <option value="leadDays">Menor plazo de entrega</option>
              </select>
            </Field>
          </div>
        </details>

        <div className="flex justify-between items-center pt-1">
          <p className="text-xs text-slate-500">
            Mostrando <strong>{filtered.length}</strong> proveedores según los filtros aplicados.
          </p>
          <Button variant="ghost" onClick={resetFilters}>
            Restablecer filtros
          </Button>
        </div>
      </section>

      {/* 4. Directorio de Proveedores: Tabla Compacta o Tarjetas */}
      {viewMode === "table" ? (
        <section className={`${box} overflow-hidden p-0`} aria-label="Tabla de directorio">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-slate-50 text-xs uppercase tracking-wider text-slate-500 dark:border-white/10 dark:bg-slate-800 dark:text-slate-400">
                <tr>
                  <th className="p-3.5">Proveedor</th>
                  <th className="p-3.5">Categoría / Especialidad</th>
                  <th className="p-3.5">Contacto principal</th>
                  <th className="p-3.5">Estado operativo</th>
                  <th className="p-3.5">Revisión</th>
                  <th className="p-3.5">Próxima revisión</th>
                  <th className="p-3.5 text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-white/10">
                {pagedRows.map((x) => {
                  const alertsList = getSupplierAlerts(x, alertDays);
                  return (
                    <tr key={x.id} className="transition hover:bg-slate-50/50 dark:hover:bg-slate-800/40">
                      <td className="p-3.5">
                        <div className="flex flex-col">
                          <span className="font-bold text-slate-900 dark:text-white flex items-center gap-2">
                            <span className="rounded bg-slate-100 px-1.5 py-0.5 text-[11px] font-mono font-semibold text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                              {x.id}
                            </span>
                            {x.name}
                          </span>
                          {x.legalName && x.legalName !== x.name && (
                            <span className="text-xs text-slate-500">{x.legalName}</span>
                          )}
                          {x.ruc && (
                            <span className="text-[11px] text-slate-400 font-mono">RUC: {x.ruc}</span>
                          )}
                        </div>
                      </td>

                      <td className="p-3.5">
                        <span className="inline-block rounded-md bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                          {categoriesMap[x.category] ?? x.category}
                        </span>
                        <p className="mt-0.5 text-xs text-slate-500">{specialtiesMap[x.specialty] ?? x.specialty}</p>
                      </td>

                      <td className="p-3.5">
                        <div className="text-xs">
                          <p className="font-semibold text-slate-800 dark:text-slate-200">{x.contact || "Sin contacto"}</p>
                          {x.phone && (
                            <a href={`tel:${x.phone}`} className="flex items-center gap-1 text-slate-500 hover:text-brand-600">
                              <Phone size={12} /> {x.phone}
                            </a>
                          )}
                          {x.email && (
                            <a href={`mailto:${x.email}`} className="flex items-center gap-1 text-slate-500 hover:text-brand-600 truncate max-w-[180px]">
                              <Mail size={12} /> {x.email}
                            </a>
                          )}
                        </div>
                      </td>

                      <td className="p-3.5">
                        <StatusPill tone={x.status === "activo" ? "ok" : x.status === "inactivo" ? "bad" : "warn"}>
                          {statesMap[x.status] ?? x.status}
                        </StatusPill>
                      </td>

                      <td className="p-3.5">
                        <StatusPill tone={x.reviewStatus === "aprobado" ? "ok" : x.reviewStatus === "rechazado" ? "bad" : "warn"}>
                          {reviewsMap[x.reviewStatus] ?? x.reviewStatus}
                        </StatusPill>
                      </td>

                      <td className="p-3.5">
                        {x.nextReviewDate ? (
                          <div className="text-xs">
                            <span className={x.nextReviewDate < todayManagua() ? "font-bold text-rose-600 dark:text-rose-400" : ""}>
                              {formatDate(x.nextReviewDate)}
                            </span>
                            {alertsList.length > 0 && (
                              <span className="block text-[11px] font-semibold text-amber-600 dark:text-amber-400">
                                {alertsList[0].text}
                              </span>
                            )}
                          </div>
                        ) : (
                          <span className="text-xs text-slate-400 italic">Sin programar</span>
                        )}
                      </td>

                      <td className="p-3.5 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          <Button
                            variant="secondary"
                            className="text-xs py-1 px-2.5"
                            disabled={detailBusy || saving}
                            onClick={() => {
                              setDetailTab("Resumen");
                              void openExpediente(x.id);
                            }}
                          >
                            Expediente
                          </Button>
                          {rights.write && (
                            <Button
                              variant="ghost"
                              className="text-xs p-1.5"
                              disabled={saving}
                              onClick={() => startForm(x)}
                              title="Editar proveedor"
                            >
                              <Pencil size={15} />
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>
      ) : (
        <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-3" aria-label="Tarjetas de directorio">
          {pagedRows.map((x) => {
            const alertsList = getSupplierAlerts(x, alertDays);
            return (
              <article key={x.id} className={`${box} flex flex-col justify-between gap-4 transition hover:shadow-md`}>
                <div className="space-y-2">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <span className="rounded bg-slate-100 px-1.5 py-0.5 text-xs font-mono font-semibold text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                        {x.id}
                      </span>
                      <h3 className="mt-1 font-bold text-lg text-slate-900 dark:text-white break-words">{x.name}</h3>
                      {x.legalName && x.legalName !== x.name && (
                        <p className="text-xs text-slate-500">{x.legalName}</p>
                      )}
                    </div>
                    <StatusPill tone={x.status === "activo" ? "ok" : x.status === "inactivo" ? "bad" : "warn"}>
                      {statesMap[x.status] ?? x.status}
                    </StatusPill>
                  </div>

                  <p className="text-xs text-slate-600 dark:text-slate-300">
                    <span className="font-semibold">{categoriesMap[x.category] ?? x.category}</span> ·{" "}
                    {specialtiesMap[x.specialty] ?? x.specialty}
                  </p>

                  <div className="flex items-center gap-2">
                    <span className="text-xs text-slate-500">Revisión:</span>
                    <StatusPill tone={x.reviewStatus === "aprobado" ? "ok" : x.reviewStatus === "rechazado" ? "bad" : "warn"}>
                      {reviewsMap[x.reviewStatus] ?? x.reviewStatus}
                    </StatusPill>
                  </div>

                  <div className="rounded-lg bg-slate-50 p-2.5 text-xs text-slate-700 dark:bg-slate-800 dark:text-slate-300 space-y-1">
                    <p className="font-medium flex items-center gap-1.5">
                      <User size={13} className="text-slate-400" /> {x.contact || "Sin contacto principal"}
                    </p>
                    {x.phone && (
                      <p className="flex items-center gap-1.5">
                        <Phone size={13} className="text-slate-400" /> {x.phone}
                      </p>
                    )}
                    {x.email && (
                      <p className="flex items-center gap-1.5 truncate">
                        <Mail size={13} className="text-slate-400" /> {x.email}
                      </p>
                    )}
                  </div>

                  <div className="text-xs text-slate-500 space-y-0.5">
                    <p>Plazo habitual: <strong>{x.leadDays !== null ? `${x.leadDays} días` : "Sin especificar"}</strong></p>
                    <p>Próxima revisión: <strong>{formatDate(x.nextReviewDate)}</strong></p>
                  </div>

                  {alertsList.length > 0 && (
                    <div className="rounded-lg border border-amber-200 bg-amber-50 p-2 text-xs text-amber-800 dark:border-amber-900/50 dark:bg-amber-950/50 dark:text-amber-200">
                      {alertsList.map((a, i) => (
                        <p key={i} className="flex items-center gap-1">
                          <AlertTriangle size={12} className="shrink-0" /> {a.text} ({formatDate(a.date)})
                        </p>
                      ))}
                    </div>
                  )}
                </div>

                <div className="flex items-center justify-between gap-2 border-t pt-3 dark:border-white/10">
                  {rights.write && (
                    <Button variant="ghost" className="text-xs" disabled={saving} onClick={() => startForm(x)} icon={<Pencil size={14} />}>
                      Editar
                    </Button>
                  )}
                  <Button
                    variant="secondary"
                    className="text-xs ml-auto"
                    disabled={detailBusy || saving}
                    onClick={() => {
                      setDetailTab("Resumen");
                      void openExpediente(x.id);
                    }}
                  >
                    Abrir expediente
                  </Button>
                </div>
              </article>
            );
          })}
        </section>
      )}

      {!loading && !filtered.length && (
        <div className={`${box} text-center py-10 text-slate-500`}>
          <Building2 size={36} className="mx-auto text-slate-400 mb-2" />
          <p className="font-semibold text-slate-700 dark:text-slate-200">No se encontraron proveedores</p>
          <p className="text-xs mt-1">Prueba cambiando los filtros o registra un nuevo proveedor en el sistema.</p>
          <Button variant="secondary" className="mt-4 text-xs" onClick={resetFilters}>
            Limpiar filtros de búsqueda
          </Button>
        </div>
      )}

      {/* Paginación */}
      <nav aria-label="Paginación del directorio" className="flex items-center justify-between text-xs text-slate-500">
        <span>
          Página <strong>{currentPage}</strong> de <strong>{totalPages}</strong> ({filtered.length} proveedores en total)
        </span>
        <div className="flex gap-2">
          <Button variant="secondary" disabled={currentPage <= 1} onClick={() => setPage((p) => Math.max(1, p - 1))}>
            Anterior
          </Button>
          <Button variant="secondary" disabled={currentPage >= totalPages} onClick={() => setPage((p) => Math.min(totalPages, p + 1))}>
            Siguiente
          </Button>
        </div>
      </nav>

      {/* 5. Modal / Formulario del Proveedor con 4 Secciones */}
      {form && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm overflow-y-auto">
          <div className="relative w-full max-w-4xl rounded-2xl bg-white shadow-2xl dark:bg-slate-900 border dark:border-white/10 max-h-[92vh] flex flex-col my-auto">
            <div className="flex items-center justify-between border-b px-6 py-4 dark:border-white/10">
              <div>
                <span className="text-xs font-mono font-bold uppercase tracking-wider text-brand-700 dark:text-glass">
                  Código asignado: {form.id}
                </span>
                <h2 className="text-xl font-bold text-slate-900 dark:text-white">
                  {form.version ? `Editar expediente: ${form.name}` : "Nuevo registro de proveedor"}
                </h2>
              </div>
              <Button variant="ghost" disabled={saving} onClick={closeForm} icon={<X size={18} />}>
                Cerrar
              </Button>
            </div>

            {saveError && (
              <div className="mx-6 mt-4 rounded-xl border border-rose-400 bg-rose-50 p-3 text-xs text-rose-800 dark:bg-rose-950 dark:text-rose-200">
                {saveError}
              </div>
            )}

            {/* Pestañas de captura */}
            <div className="flex border-b px-6 text-sm font-semibold dark:border-white/10 overflow-x-auto">
              {[
                { id: "identificacion", label: "1. Identificación" },
                { id: "contactos", label: "2. Contactos y Entrega" },
                { id: "condiciones", label: "3. Condiciones comerciales" },
                { id: "homologacion", label: "4. Homologación y Estado" }
              ].map((t) => (
                <button
                  key={t.id}
                  type="button"
                  onClick={() => setFormTab(t.id as any)}
                  className={`border-b-2 px-4 py-3 transition-colors whitespace-nowrap ${
                    formTab === t.id
                      ? "border-brand-600 text-brand-700 dark:border-brand-400 dark:text-white"
                      : "border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-300"
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>

            <form onSubmit={handleFormSubmit} className="flex-1 overflow-y-auto p-6 space-y-5">
              {formTab === "identificacion" && (
                <div className="space-y-4">
                  <div className="grid gap-4 sm:grid-cols-2">
                    <Field label="Nombre comercial *">
                      <input
                        className={inputClass}
                        required
                        maxLength={240}
                        value={form.name}
                        onChange={(e) => setForm({ ...form, name: e.target.value })}
                        placeholder="Ej. Alumex de Nicaragua S.A."
                      />
                    </Field>

                    <Field label="Razón social (si difiere)">
                      <input
                        className={inputClass}
                        maxLength={240}
                        value={form.legalName}
                        onChange={(e) => setForm({ ...form, legalName: e.target.value })}
                        placeholder="Ej. Alumex de Nicaragua Sociedad Anónima"
                      />
                    </Field>

                    <Field label="Identificación fiscal (RUC DGI)">
                      <input
                        className={inputClass}
                        maxLength={40}
                        value={form.ruc}
                        onChange={(e) => setForm({ ...form, ruc: e.target.value.toUpperCase() })}
                        placeholder="Ej. J0310000102030"
                      />
                    </Field>

                    <Field label="Categoría de suministro *">
                      <select
                        className={inputClass}
                        value={form.category}
                        onChange={(e) => setForm({ ...form, category: e.target.value as any })}
                      >
                        {Object.entries(categoriesMap).map(([k, v]) => (
                          <option key={k} value={k}>{v}</option>
                        ))}
                      </select>
                    </Field>

                    <Field label="Especialidad técnica *">
                      <select
                        className={inputClass}
                        value={form.specialty}
                        onChange={(e) => setForm({ ...form, specialty: e.target.value as any })}
                      >
                        {Object.entries(specialtiesMap).map(([k, v]) => (
                          <option key={k} value={k}>{v}</option>
                        ))}
                      </select>
                    </Field>
                  </div>

                  <Field label="Productos y servicios ofrecidos">
                    <textarea
                      className={`${inputClass} min-h-20 py-2`}
                      maxLength={1000}
                      value={form.productsServices}
                      onChange={(e) => setForm({ ...form, productsServices: e.target.value })}
                      placeholder="Describe los productos, perfiles, calidades, espesores o servicios que suministra…"
                    />
                  </Field>
                </div>
              )}

              {formTab === "contactos" && (
                <div className="space-y-4">
                  <div className="grid gap-4 sm:grid-cols-2">
                    <Field label="Persona de contacto principal">
                      <input
                        className={inputClass}
                        maxLength={200}
                        value={form.contact}
                        onChange={(e) => setForm({ ...form, contact: e.target.value })}
                        placeholder="Ej. Lic. Karla Ruiz"
                      />
                    </Field>

                    <Field label="Cargo del contacto">
                      <input
                        className={inputClass}
                        maxLength={120}
                        value={form.contactRole}
                        onChange={(e) => setForm({ ...form, contactRole: e.target.value })}
                        placeholder="Ej. Gerente de Cuentas Corporativas"
                      />
                    </Field>

                    <Field label="Teléfono de contacto">
                      <input
                        className={inputClass}
                        type="tel"
                        maxLength={80}
                        value={form.phone}
                        onChange={(e) => setForm({ ...form, phone: e.target.value })}
                        placeholder="Ej. 2222-4400 / 8888-1122"
                      />
                    </Field>

                    <Field label="Correo electrónico">
                      <input
                        className={inputClass}
                        type="email"
                        maxLength={320}
                        value={form.email}
                        onChange={(e) => setForm({ ...form, email: e.target.value })}
                        placeholder="Ej. pedidos@proveedor.com.ni"
                      />
                    </Field>

                    <Field label="Dirección comercial / domicilio fiscal">
                      <input
                        className={inputClass}
                        maxLength={500}
                        value={form.address}
                        onChange={(e) => setForm({ ...form, address: e.target.value })}
                        placeholder="Dirección física o legal"
                      />
                    </Field>

                    <Field label="Dirección de bodega / despacho (si difiere)">
                      <input
                        className={inputClass}
                        maxLength={500}
                        value={form.dispatchAddress}
                        onChange={(e) => setForm({ ...form, dispatchAddress: e.target.value })}
                        placeholder="Ubicación de carga o retiro de materiales"
                      />
                    </Field>
                  </div>

                  <div className="border-t pt-4 dark:border-white/10">
                    <div className="flex items-center justify-between mb-2">
                      <h4 className="text-sm font-bold text-slate-800 dark:text-slate-200">Contactos adicionales</h4>
                      <Button
                        type="button"
                        variant="secondary"
                        className="text-xs"
                        disabled={form.contacts.length >= 20}
                        onClick={() =>
                          setForm({
                            ...form,
                            contacts: [...form.contacts, { name: "", role: "", phone: "", email: "" }]
                          })
                        }
                      >
                        + Agregar contacto
                      </Button>
                    </div>

                    {form.contacts.map((c, i) => (
                      <div key={i} className="mb-2 grid gap-2 rounded-lg border p-3 dark:border-white/10 sm:grid-cols-4 items-center">
                        <Field label="Nombre">
                          <input
                            className={inputClass}
                            value={c.name}
                            onChange={(e) =>
                              setForm({
                                ...form,
                                contacts: form.contacts.map((x, j) => (i === j ? { ...x, name: e.target.value } : x))
                              })
                            }
                          />
                        </Field>
                        <Field label="Cargo">
                          <input
                            className={inputClass}
                            value={c.role}
                            onChange={(e) =>
                              setForm({
                                ...form,
                                contacts: form.contacts.map((x, j) => (i === j ? { ...x, role: e.target.value } : x))
                              })
                            }
                          />
                        </Field>
                        <Field label="Teléfono">
                          <input
                            className={inputClass}
                            value={c.phone}
                            onChange={(e) =>
                              setForm({
                                ...form,
                                contacts: form.contacts.map((x, j) => (i === j ? { ...x, phone: e.target.value } : x))
                              })
                            }
                          />
                        </Field>
                        <div className="flex items-end gap-2">
                          <div className="flex-1">
                            <Field label="Correo">
                              <input
                                className={inputClass}
                                value={c.email}
                                onChange={(e) =>
                                  setForm({
                                    ...form,
                                    contacts: form.contacts.map((x, j) => (i === j ? { ...x, email: e.target.value } : x))
                                  })
                                }
                              />
                            </Field>
                          </div>
                          <Button
                            type="button"
                            variant="ghost"
                            className="text-rose-600 text-xs mb-1"
                            onClick={() => setForm({ ...form, contacts: form.contacts.filter((_, j) => j !== i) })}
                          >
                            Quitar
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {formTab === "condiciones" && (
                <div className="space-y-4">
                  <div className="grid gap-4 sm:grid-cols-3">
                    <Field label="Condiciones de pago acordadas">
                      <input
                        className={inputClass}
                        maxLength={80}
                        value={form.paymentTerms}
                        onChange={(e) => setForm({ ...form, paymentTerms: e.target.value })}
                        placeholder="Ej. Crédito 15 días, Contado contra entrega"
                      />
                    </Field>

                    <Field label="Moneda comercial">
                      <select
                        className={inputClass}
                        value={form.currency}
                        onChange={(e) => setForm({ ...form, currency: e.target.value as any })}
                      >
                        <option value="NIO">Córdoba (NIO)</option>
                        <option value="USD">Dólar (USD)</option>
                      </select>
                    </Field>

                    <Field label="Plazo habitual de entrega (días)">
                      <input
                        type="number"
                        min={0}
                        max={365}
                        className={inputClass}
                        value={form.leadDays ?? ""}
                        onChange={(e) => setForm({ ...form, leadDays: e.target.value === "" ? null : Number(e.target.value) })}
                        placeholder="Ej. 3"
                      />
                    </Field>
                  </div>

                  <div className="grid gap-4 sm:grid-cols-2">
                    <Field label="Descuentos pactados">
                      <input
                        className={inputClass}
                        maxLength={500}
                        value={form.discounts}
                        onChange={(e) => setForm({ ...form, discounts: e.target.value })}
                        placeholder="Ej. 5% pronto pago antes de 10 días, mayoreo por volumen"
                      />
                    </Field>

                    <Field label="Condiciones de transporte / flete">
                      <input
                        className={inputClass}
                        maxLength={500}
                        value={form.transportTerms}
                        onChange={(e) => setForm({ ...form, transportTerms: e.target.value })}
                        placeholder="Ej. Entrega en taller con caballete metálico incluida en compras > C$ 30,000"
                      />
                    </Field>
                  </div>

                  <Field label="Datos bancarios autorizados (cuentas bancarias para transferencias)">
                    <input
                      className={inputClass}
                      maxLength={500}
                      value={form.bankDetails}
                      onChange={(e) => setForm({ ...form, bankDetails: e.target.value })}
                      placeholder="Ej. BAC NIO Cta Corriente ****-4401 (Titular: Alumex de Nicaragua S.A.)"
                    />
                  </Field>

                  <Field label="Observaciones comerciales">
                    <textarea
                      className={`${inputClass} min-h-20 py-2`}
                      maxLength={2000}
                      value={form.observations}
                      onChange={(e) => setForm({ ...form, observations: e.target.value })}
                      placeholder="Notas sobre acuerdos comerciales, garantías o condiciones especiales…"
                    />
                  </Field>
                </div>
              )}

              {formTab === "homologacion" && (
                <div className="space-y-4">
                  <div className="grid gap-4 sm:grid-cols-3">
                    <Field label="Estado operativo">
                      <select
                        className={inputClass}
                        value={form.status}
                        disabled={!rights.approve}
                        onChange={(e) => setForm({ ...form, status: e.target.value as any })}
                      >
                        {Object.entries(statesMap).map(([k, v]) => (
                          <option key={k} value={k}>{v}</option>
                        ))}
                      </select>
                    </Field>

                    <Field label="Resolución de revisión interna">
                      <select
                        className={inputClass}
                        value={form.reviewStatus}
                        disabled={!rights.approve}
                        onChange={(e) => setForm({ ...form, reviewStatus: e.target.value as any })}
                      >
                        {Object.entries(reviewsMap).map(([k, v]) => (
                          <option key={k} value={k}>{v}</option>
                        ))}
                      </select>
                    </Field>

                    <Field label="Próxima revisión interna programada">
                      <input
                        className={inputClass}
                        type="date"
                        value={form.nextReviewDate}
                        onChange={(e) => setForm({ ...form, nextReviewDate: e.target.value })}
                      />
                    </Field>
                  </div>

                  <Field label="Fundamento o evidencia de la resolución técnica (requerido para Aprobado/Rechazado)">
                    <textarea
                      className={`${inputClass} min-h-24 py-2`}
                      disabled={!rights.approve}
                      maxLength={2000}
                      value={form.reviewEvidence}
                      onChange={(e) => setForm({ ...form, reviewEvidence: e.target.value })}
                      placeholder="Detalla los criterios técnicos, solvencia fiscal DGI, muestras ensayadas o justificación de la decisión…"
                    />
                  </Field>

                  <div className="rounded-xl border border-amber-200 bg-amber-50/70 p-3 text-xs text-amber-800 dark:border-amber-900/50 dark:bg-amber-950/40 dark:text-amber-300">
                    <strong>Importante:</strong> La homologación es un procedimiento interno de control de calidad y solvencia de Instalaciones Raquel. No constituye ni debe presentarse como certificación de una autoridad oficial.
                  </div>
                </div>
              )}

              {/* Motivo de la modificación (Auditoría) */}
              <div className="border-t pt-4 dark:border-white/10">
                <Field label="Motivo documentado del registro o modificación *">
                  <input
                    className={inputClass}
                    required
                    minLength={3}
                    maxLength={500}
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    placeholder="Ej. Actualización de condiciones comerciales y verificación de RUC DGI 2026"
                  />
                </Field>
                <p className="mt-1 text-[11px] text-slate-500">
                  Este motivo quedará registrado en el historial de auditoría con tu usuario y la hora oficial del servidor.
                </p>
              </div>

              <div className="flex items-center justify-end gap-3 border-t pt-4 dark:border-white/10">
                <Button type="button" variant="secondary" disabled={saving} onClick={closeForm}>
                  Cancelar
                </Button>
                <Button type="submit" disabled={saving || !online}>
                  {saving ? "Confirmando en SQL Server…" : "Guardar en SQL Server"}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 6. Modal / Drawer del Expediente Completo (8 Pestañas) */}
      {detail && s && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm overflow-y-auto">
          <div className="relative w-full max-w-5xl rounded-2xl bg-white shadow-2xl dark:bg-slate-900 border dark:border-white/10 max-h-[94vh] flex flex-col my-auto">
            {/* Header del Expediente */}
            <div className="flex flex-wrap items-center justify-between gap-3 border-b px-6 py-4 dark:border-white/10 bg-slate-50/70 dark:bg-slate-800/50 rounded-t-2xl">
              <div>
                <div className="flex items-center gap-2">
                  <span className="rounded bg-brand-100 px-2 py-0.5 text-xs font-mono font-bold text-brand-800 dark:bg-brand-900/60 dark:text-brand-300">
                    {s.id}
                  </span>
                  <StatusPill tone={s.status === "activo" ? "ok" : s.status === "inactivo" ? "bad" : "warn"}>
                    {statesMap[s.status] ?? s.status}
                  </StatusPill>
                  <StatusPill tone={s.reviewStatus === "aprobado" ? "ok" : s.reviewStatus === "rechazado" ? "bad" : "warn"}>
                    {reviewsMap[s.reviewStatus] ?? s.reviewStatus}
                  </StatusPill>
                </div>
                <h2 className="mt-1 text-2xl font-black text-slate-900 dark:text-white">{s.name}</h2>
                {s.legalName && s.legalName !== s.name && (
                  <p className="text-xs text-slate-500 font-medium">Razón social: {s.legalName}</p>
                )}
              </div>

              <div className="flex items-center gap-2">
                {rights.write && (
                  <Button
                    disabled={saving}
                    onClick={() => {
                      startForm(s);
                    }}
                    icon={<Pencil size={15} />}
                  >
                    Editar expediente
                  </Button>
                )}
                <Button
                  variant="ghost"
                  disabled={saving}
                  onClick={() => {
                    ++sequence.current;
                    setDetail(null);
                  }}
                  icon={<X size={18} />}
                >
                  Cerrar
                </Button>
              </div>
            </div>

            {/* 8 Sub-pestañas del Expediente */}
            <nav className="flex border-b px-6 text-sm font-semibold dark:border-white/10 overflow-x-auto bg-white dark:bg-slate-900">
              {[
                { id: "Resumen", label: "Resumen" },
                { id: "Contactos", label: "Contactos" },
                { id: "Condiciones", label: "Condiciones comerciales" },
                { id: "Productos", label: "Productos y servicios" },
                { id: "Compras", label: `Compras y entregas (${detail.purchases.length})` },
                { id: "Documentos", label: `Documentos (${s.documents.length})` },
                { id: "Evaluación", label: "Evaluación" },
                { id: "Historial", label: `Historial (${detail.events.length})` }
              ].map((t) => (
                <button
                  key={t.id}
                  type="button"
                  onClick={() => setDetailTab(t.id as any)}
                  className={`border-b-2 px-3.5 py-3 transition-colors whitespace-nowrap ${
                    detailTab === t.id
                      ? "border-brand-600 text-brand-700 dark:border-brand-400 dark:text-white"
                      : "border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-300"
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </nav>

            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              {/* Pestaña 1: Resumen */}
              {detailTab === "Resumen" && (
                <div className="space-y-6">
                  {/* Banner "Antes de comprar" */}
                  <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-white/10 dark:bg-slate-800/40">
                    <div className="flex items-center justify-between">
                      <h3 className="font-bold text-slate-900 dark:text-white flex items-center gap-2">
                        <CheckCircle2 className="text-brand-600" size={18} /> Verificación previa: &ldquo;Antes de comprar&rdquo;
                      </h3>
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${
                          s.status === "activo" && s.reviewStatus === "aprobado" && s.ruc
                            ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300"
                            : "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300"
                        }`}
                      >
                        {s.status === "activo" && s.reviewStatus === "aprobado" && s.ruc
                          ? "APTO PARA EMISIÓN DE ÓRDENES"
                          : "REQUIERE REVISIÓN PREVIA"}
                      </span>
                    </div>

                    <div className="mt-3 grid gap-2 text-xs sm:grid-cols-2 md:grid-cols-4">
                      <div className="flex items-center gap-2">
                        {s.status === "activo" ? <Check size={14} className="text-emerald-600" /> : <X size={14} className="text-rose-600" />}
                        <span>Estado operativo: <strong>{statesMap[s.status]}</strong></span>
                      </div>
                      <div className="flex items-center gap-2">
                        {s.reviewStatus === "aprobado" ? <Check size={14} className="text-emerald-600" /> : <AlertTriangle size={14} className="text-amber-600" />}
                        <span>Homologación: <strong>{reviewsMap[s.reviewStatus]}</strong></span>
                      </div>
                      <div className="flex items-center gap-2">
                        {s.ruc ? <Check size={14} className="text-emerald-600" /> : <X size={14} className="text-rose-600" />}
                        <span>RUC DGI: <strong>{s.ruc || "Falta"}</strong></span>
                      </div>
                      <div className="flex items-center gap-2">
                        {s.documents.some((d) => d.review === "aceptado") ? (
                          <Check size={14} className="text-emerald-600" />
                        ) : (
                          <AlertTriangle size={14} className="text-amber-600" />
                        )}
                        <span>Docs validados: <strong>{s.documents.filter((d) => d.review === "aceptado").length}</strong></span>
                      </div>
                    </div>

                    {getSupplierAlerts(s, alertDays).map((a, i) => (
                      <p key={i} className="mt-2 text-xs font-semibold text-amber-700 dark:text-amber-300 flex items-center gap-1.5">
                        <AlertTriangle size={13} /> {a.text} ({formatDate(a.date)})
                      </p>
                    ))}
                  </div>

                  {/* Matriz de fechas clave */}
                  <div>
                    <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200 mb-3">Trazabilidad de fechas del expediente</h4>
                    <dl className="grid gap-4 sm:grid-cols-2 md:grid-cols-3">
                      <DetailItem label="Fecha de registro original">{formatDate(s.createdAt, true)}</DetailItem>
                      <DetailItem label="Última modificación">{`${formatDate(s.updatedAt, true)} · ${s.updatedBy || "sistema"}`}</DetailItem>
                      <DetailItem label="Última revisión técnica">{`${formatDate(s.reviewedAt, true)} · ${s.reviewedBy || "Comité"}`}</DetailItem>
                      <DetailItem label="Próxima revisión programada">{formatDate(s.nextReviewDate)}</DetailItem>
                      <DetailItem label="Última compra">{detail.purchases[0] ? formatDate(detail.purchases[0].date) : "Sin compras registradas"}</DetailItem>
                      {s.status === "inactivo" && (
                        <DetailItem label="Fecha de inactivación">{formatDate(s.inactiveAt, true)}</DetailItem>
                      )}
                    </dl>
                  </div>

                  {/* Datos generales */}
                  <div className="border-t pt-4 dark:border-white/10">
                    <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200 mb-3">Identificación y ubicación</h4>
                    <dl className="grid gap-4 sm:grid-cols-2 md:grid-cols-3">
                      <DetailItem label="Razón social">{s.legalName}</DetailItem>
                      <DetailItem label="Identificación fiscal">{s.ruc}</DetailItem>
                      <DetailItem label="Categoría comercial">{categoriesMap[s.category] ?? s.category}</DetailItem>
                      <DetailItem label="Especialidad">{specialtiesMap[s.specialty] ?? s.specialty}</DetailItem>
                      <DetailItem label="Dirección comercial">{s.address}</DetailItem>
                      <DetailItem label="Dirección de bodega">{s.dispatchAddress}</DetailItem>
                    </dl>
                  </div>

                  {s.observations && (
                    <div className="border-t pt-4 dark:border-white/10">
                      <DetailItem label="Observaciones">{s.observations}</DetailItem>
                    </div>
                  )}
                </div>
              )}

              {/* Pestaña 2: Contactos */}
              {detailTab === "Contactos" && (
                <div className="space-y-6">
                  <div>
                    <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200 mb-3">Contacto principal</h4>
                    <div className="rounded-xl border p-4 dark:border-white/10 bg-slate-50/50 dark:bg-slate-800/30">
                      <p className="font-bold text-base text-slate-900 dark:text-white">{s.contact || "Sin contacto principal registrado"}</p>
                      <p className="text-xs text-slate-500">{s.contactRole || "Cargo no especificado"}</p>
                      <div className="mt-3 flex flex-wrap gap-4 text-xs">
                        {s.phone && (
                          <a href={`tel:${s.phone}`} className="flex items-center gap-1.5 font-medium text-brand-600 hover:underline">
                            <Phone size={14} /> {s.phone}
                          </a>
                        )}
                        {s.email && (
                          <a href={`mailto:${s.email}`} className="flex items-center gap-1.5 font-medium text-brand-600 hover:underline">
                            <Mail size={14} /> {s.email}
                          </a>
                        )}
                      </div>
                    </div>
                  </div>

                  {s.contacts.length > 0 && (
                    <div className="border-t pt-4 dark:border-white/10">
                      <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200 mb-3">
                        Contactos adicionales ({s.contacts.length})
                      </h4>
                      <div className="grid gap-3 sm:grid-cols-2">
                        {s.contacts.map((c, i) => (
                          <div key={i} className="rounded-xl border p-3.5 dark:border-white/10">
                            <p className="font-bold text-sm text-slate-900 dark:text-white">{c.name}</p>
                            <p className="text-xs text-slate-500">{c.role || "Cargo no especificado"}</p>
                            <div className="mt-2 text-xs text-slate-600 dark:text-slate-300 space-y-1">
                              {c.phone && <p className="flex items-center gap-1.5"><Phone size={12} /> {c.phone}</p>}
                              {c.email && <p className="flex items-center gap-1.5 truncate"><Mail size={12} /> {c.email}</p>}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  <div className="border-t pt-4 dark:border-white/10">
                    <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200 mb-3">Direcciones de contacto y entrega</h4>
                    <dl className="grid gap-4 sm:grid-cols-2">
                      <DetailItem label="Dirección comercial / legal">{s.address}</DetailItem>
                      <DetailItem label="Dirección de bodega / despacho">{s.dispatchAddress}</DetailItem>
                    </dl>
                  </div>
                </div>
              )}

              {/* Pestaña 3: Condiciones comerciales */}
              {detailTab === "Condiciones" && (
                <div className="space-y-6">
                  <dl className="grid gap-4 sm:grid-cols-2 md:grid-cols-3">
                    <DetailItem label="Condiciones de pago">{s.paymentTerms}</DetailItem>
                    <DetailItem label="Moneda habitual">{s.currency === "USD" ? "Dólares (USD)" : "Córdobas (NIO)"}</DetailItem>
                    <DetailItem label="Plazo habitual de entrega">
                      {s.leadDays !== null ? `${s.leadDays} días calendario` : "Sin especificar"}
                    </DetailItem>
                    <DetailItem label="Descuentos pactados">{s.discounts}</DetailItem>
                    <DetailItem label="Condiciones de flete / transporte">{s.transportTerms}</DetailItem>
                  </dl>

                  {/* Datos bancarios protegidos */}
                  <div className="border-t pt-4 dark:border-white/10">
                    <div className="flex items-center justify-between mb-2">
                      <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200">
                        Cuentas bancarias autorizadas para transferencias
                      </h4>
                      {rights.approve && (
                        <Button
                          variant="ghost"
                          className="text-xs"
                          onClick={() => setShowSensitiveBank(!showSensitiveBank)}
                          icon={showSensitiveBank ? <EyeOff size={14} /> : <Eye size={14} />}
                        >
                          {showSensitiveBank ? "Ocultar detalles" : "Revelar datos bancarios"}
                        </Button>
                      )}
                    </div>

                    <div className="rounded-xl border p-3.5 dark:border-white/10 bg-slate-50/50 dark:bg-slate-800/20 text-sm">
                      {s.bankDetails ? (
                        showSensitiveBank ? (
                          <p className="font-mono text-slate-900 dark:text-white">{s.bankDetails}</p>
                        ) : (
                          <p className="font-mono text-slate-500">
                            {s.bankDetails.replace(/\b\d{6,14}\b/g, (m) => `****-${m.slice(-4)}`)}
                          </p>
                        )
                      ) : (
                        <p className="italic text-slate-400">Sin datos bancarios registrados.</p>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* Pestaña 4: Productos y servicios */}
              {detailTab === "Productos" && (
                <div className="space-y-6">
                  <div>
                    <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200 mb-2">Catálogo suministrado</h4>
                    <p className="text-sm text-slate-700 dark:text-slate-300 whitespace-pre-wrap rounded-xl border p-4 dark:border-white/10 bg-slate-50/50 dark:bg-slate-800/30">
                      {s.productsServices || "Sin descripción de productos registrada."}
                    </p>
                  </div>

                  <dl className="grid gap-4 sm:grid-cols-2">
                    <DetailItem label="Categoría">{categoriesMap[s.category] ?? s.category}</DetailItem>
                    <DetailItem label="Especialidad técnica">{specialtiesMap[s.specialty] ?? s.specialty}</DetailItem>
                  </dl>
                </div>
              )}

              {/* Pestaña 5: Compras y entregas */}
              {detailTab === "Compras" && (
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200">
                      Órdenes de compra vinculadas por ID ({detail.purchases.length})
                    </h4>
                  </div>

                  {detail.purchases.length > 0 ? (
                    <div className="overflow-x-auto rounded-xl border dark:border-white/10">
                      <table className="w-full text-left text-sm">
                        <thead className="border-b bg-slate-50 text-xs uppercase tracking-wider text-slate-500 dark:border-white/10 dark:bg-slate-800">
                          <tr>
                            <th className="p-3">No. Orden</th>
                            <th className="p-3">Fecha de orden</th>
                            <th className="p-3">Estado de recepción</th>
                            <th className="p-3">Monto total</th>
                            <th className="p-3">Fecha de pago</th>
                            <th className="p-3">Estado de pago</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100 dark:divide-white/10">
                          {detail.purchases.map((p) => (
                            <tr key={p.id}>
                              <td className="p-3 font-semibold text-slate-900 dark:text-white">{p.number}</td>
                              <td className="p-3 text-slate-600 dark:text-slate-300">{formatDate(p.date)}</td>
                              <td className="p-3">
                                <StatusPill tone={p.status === "received" ? "ok" : "warn"}>
                                  {p.status === "received" ? "Recibida en bodega" : "Ordenada / en tránsito"}
                                </StatusPill>
                              </td>
                              <td className="p-3 font-bold">
                                {new Intl.NumberFormat("es-NI", { style: "currency", currency: "NIO" }).format(p.total)}
                              </td>
                              <td className="p-3 text-slate-600 dark:text-slate-300">
                                {p.paymentDate ? formatDate(p.paymentDate) : "Pendiente"}
                              </td>
                              <td className="p-3">
                                <StatusPill tone={p.paymentDate ? "ok" : "warn"}>
                                  {p.paymentDate ? "Pagada en Tesorería" : "Por pagar"}
                                </StatusPill>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  ) : (
                    <p className="rounded-xl border border-dashed p-6 text-center text-sm text-slate-500 dark:border-white/10">
                      No hay compras registradas para este proveedor en la base de datos.
                    </p>
                  )}
                </div>
              )}

              {/* Pestaña 6: Documentos y versiones */}
              {detailTab === "Documentos" && (
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200">
                        Expediente documental y certificaciones
                      </h4>
                      <p className="text-xs text-slate-500">
                        Documentos privados (PDF, PNG, JPG hasta 3 MB). Se conservan versiones históricas.
                      </p>
                    </div>

                    {rights.write && (
                      <Button
                        disabled={saving || s.documents.length >= 50}
                        onClick={() => {
                          setDocModal(blankDoc());
                          setDocFile(null);
                        }}
                        icon={<Plus size={15} />}
                      >
                        Agregar documento
                      </Button>
                    )}
                  </div>

                  {/* Formulario modal para nuevo documento */}
                  {docModal && (
                    <form onSubmit={handleAddDocSubmit} className="rounded-xl border p-4 dark:border-white/10 bg-slate-50/70 dark:bg-slate-800/40 space-y-3">
                      <h5 className="font-bold text-sm text-slate-900 dark:text-white">Nuevo documento para el expediente</h5>
                      <div className="grid gap-3 sm:grid-cols-2">
                        <Field label="Título del documento *">
                          <input
                            className={inputClass}
                            required
                            maxLength={240}
                            value={docModal.title}
                            onChange={(e) => setDocModal({ ...docModal, title: e.target.value })}
                            placeholder="Ej. Cédula RUC DGI 2026, Ficha técnica ASTM"
                          />
                        </Field>

                        <Field label="Tipo de documento">
                          <select
                            className={inputClass}
                            value={docModal.type}
                            onChange={(e) => setDocModal({ ...docModal, type: e.target.value })}
                          >
                            <option value="Fiscal">Fiscal (RUC, Matrícula)</option>
                            <option value="Técnico / Calidad">Técnico / Calidad (Normas ASTM, Ensayos)</option>
                            <option value="Legal">Legal (Poder, Constitución)</option>
                            <option value="Comercial">Comercial (Lista de precios, Cotización)</option>
                          </select>
                        </Field>

                        <Field label="Fecha de emisión">
                          <input
                            className={inputClass}
                            type="date"
                            value={docModal.issuedOn}
                            onChange={(e) => setDocModal({ ...docModal, issuedOn: e.target.value })}
                          />
                        </Field>

                        <Field label="Fecha de vencimiento (dejar vacío si no aplica)">
                          <input
                            className={inputClass}
                            type="date"
                            min={docModal.issuedOn}
                            value={docModal.expiresOn}
                            onChange={(e) => setDocModal({ ...docModal, expiresOn: e.target.value })}
                          />
                        </Field>

                        <Field label="Referencia física o externa (si no adjuntas archivo)">
                          <input
                            className={inputClass}
                            maxLength={500}
                            value={docModal.reference}
                            onChange={(e) => setDocModal({ ...docModal, reference: e.target.value })}
                            placeholder="Ej. Archivero B, Carpeta 3, Constancia No. 104"
                          />
                        </Field>

                        <Field label="Archivo adjunto (PDF, PNG, JPEG máx 3 MB)">
                          <input
                            type="file"
                            className="block w-full text-xs text-slate-500 file:mr-2 file:py-1 file:px-3 file:rounded file:border-0 file:text-xs file:font-semibold file:bg-brand-50 file:text-brand-700 hover:file:bg-brand-100"
                            accept="application/pdf,image/png,image/jpeg"
                            onChange={(e) => setDocFile(e.target.files?.[0] ?? null)}
                          />
                        </Field>
                      </div>

                      <div className="flex justify-end gap-2 pt-2">
                        <Button type="button" variant="secondary" className="text-xs" disabled={saving} onClick={() => setDocModal(null)}>
                          Cancelar
                        </Button>
                        <Button type="submit" className="text-xs" disabled={saving}>
                          {saving ? "Guardando…" : "Guardar documento"}
                        </Button>
                      </div>
                    </form>
                  )}

                  {s.documents.length > 0 ? (
                    <div className="grid gap-3 sm:grid-cols-2">
                      {s.documents.map((d) => {
                        const hasBinary = detail.files.some((f) => f.id.toLowerCase() === d.id.toLowerCase());
                        const isExpired = d.expiresOn && d.expiresOn < todayManagua();
                        return (
                          <div key={d.id} className="rounded-xl border p-4 dark:border-white/10 space-y-2">
                            <div className="flex items-start justify-between gap-2">
                              <h5 className="font-bold text-sm text-slate-900 dark:text-white">{d.title}</h5>
                              <StatusPill tone={d.review === "aceptado" ? "ok" : d.review === "rechazado" ? "bad" : "warn"}>
                                {d.review === "aceptado" ? "Aceptado" : d.review === "rechazado" ? "Rechazado" : "Pendiente"}
                              </StatusPill>
                            </div>

                            <p className="text-xs text-slate-500">
                              Tipo: <strong>{d.type}</strong> · Emisión: {formatDate(d.issuedOn)} · Vencimiento:{" "}
                              <span className={isExpired ? "font-bold text-rose-600 dark:text-rose-400" : ""}>
                                {d.expiresOn ? formatDate(d.expiresOn) : "No aplica"}
                              </span>
                            </p>

                            {d.reference && (
                              <p className="text-xs text-slate-600 dark:text-slate-300">
                                <strong>Ref:</strong> {d.reference}
                              </p>
                            )}

                            {d.reviewedAt && (
                              <div className="rounded bg-slate-50 p-2 text-xs text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                                <p className="font-semibold">{d.reviewedBy} · {formatDate(d.reviewedAt, true)}</p>
                                <p className="mt-0.5 italic">{d.reviewNote}</p>
                              </div>
                            )}

                            <div className="flex flex-wrap items-center gap-2 pt-2 border-t dark:border-white/10">
                              {hasBinary && (
                                <Button
                                  variant="secondary"
                                  className="text-xs py-1 px-2.5"
                                  onClick={() => void handleDownloadDoc(d)}
                                  icon={<Download size={13} />}
                                >
                                  Descargar
                                </Button>
                              )}

                              {rights.approve && (
                                <>
                                  <Button
                                    variant="secondary"
                                    className="text-xs py-1 px-2.5"
                                    disabled={saving}
                                    onClick={() => void handleReviewDoc(d, "aceptado")}
                                  >
                                    Aceptar
                                  </Button>
                                  <Button
                                    variant="ghost"
                                    className="text-xs py-1 px-2.5 text-rose-600"
                                    disabled={saving}
                                    onClick={() => void handleReviewDoc(d, "rechazado")}
                                  >
                                    Rechazar
                                  </Button>
                                </>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  ) : (
                    <p className="rounded-xl border border-dashed p-6 text-center text-sm text-slate-500 dark:border-white/10">
                      No hay documentos adjuntos en este expediente.
                    </p>
                  )}
                </div>
              )}

              {/* Pestaña 7: Evaluación */}
              {detailTab === "Evaluación" && (
                <div className="space-y-6">
                  <div>
                    <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200 mb-2">
                      Evaluación objetiva basada en registros
                    </h4>
                    <p className="text-xs text-slate-500">
                      Cálculo a partir de compras reales registradas. No se inventan cifras si el histórico no es suficiente.
                    </p>
                  </div>

                  {detail.purchases.length >= 2 ? (
                    <div className="grid gap-4 sm:grid-cols-3">
                      <div className="rounded-xl border p-4 dark:border-white/10">
                        <span className="text-xs uppercase text-slate-500">Tasa de recepción</span>
                        <strong className="mt-1 block text-2xl font-black text-emerald-600">
                          {Math.round(
                            (detail.purchases.filter((p) => p.status === "received").length / detail.purchases.length) * 100
                          )}
                          %
                        </strong>
                        <span className="text-xs text-slate-500">
                          {detail.purchases.filter((p) => p.status === "received").length} de {detail.purchases.length} órdenes recibidas
                        </span>
                      </div>

                      <div className="rounded-xl border p-4 dark:border-white/10">
                        <span className="text-xs uppercase text-slate-500">Plazo pactado</span>
                        <strong className="mt-1 block text-2xl font-black text-brand-600">
                          {s.leadDays !== null ? `${s.leadDays} d` : "—"}
                        </strong>
                        <span className="text-xs text-slate-500">Días calendario habituales</span>
                      </div>

                      <div className="rounded-xl border p-4 dark:border-white/10">
                        <span className="text-xs uppercase text-slate-500">Estado de homologación</span>
                        <strong className="mt-1 block text-2xl font-black text-slate-900 dark:text-white">
                          {reviewsMap[s.reviewStatus]}
                        </strong>
                        <span className="text-xs text-slate-500">Evaluación técnica interna</span>
                      </div>
                    </div>
                  ) : (
                    <div className="rounded-xl border border-dashed p-6 text-center text-sm text-slate-500 dark:border-white/10">
                      <p className="font-bold text-slate-700 dark:text-slate-300">
                        Sin datos suficientes para evaluación estadística
                      </p>
                      <p className="text-xs mt-1">
                        Se requieren al menos 2 órdenes de compra ejecutadas para calcular indicadores de puntualidad y entrega.
                      </p>
                    </div>
                  )}

                  <div className="border-t pt-4 dark:border-white/10">
                    <h5 className="font-bold text-sm text-slate-800 dark:text-slate-200 mb-2">
                      Fundamento de la resolución de homologación interna
                    </h5>
                    <div className="rounded-xl border p-4 dark:border-white/10 bg-slate-50/50 dark:bg-slate-800/30">
                      <p className="text-sm text-slate-800 dark:text-slate-200">
                        {s.reviewEvidence || "Sin fundamento de revisión registrado por el evaluador."}
                      </p>
                      <p className="mt-2 text-xs text-slate-500">
                        Responsable: <strong>{s.reviewedBy || "Comité de Compras"}</strong> · Fecha: {formatDate(s.reviewedAt, true)}
                      </p>
                    </div>
                  </div>
                </div>
              )}

              {/* Pestaña 8: Historial de auditoría */}
              {detailTab === "Historial" && (
                <div className="space-y-4">
                  <div>
                    <h4 className="font-bold text-sm text-slate-800 dark:text-slate-200">
                      Trazabilidad y auditoría de cambios ({detail.events.length})
                    </h4>
                    <p className="text-xs text-slate-500">
                      Registro inmutable en SQL Server con hora de Nicaragua (-06:00), usuario responsable y motivo documentado.
                    </p>
                  </div>

                  {detail.events.length > 0 ? (
                    <div className="space-y-3">
                      {detail.events.map((e) => (
                        <div key={e.id} className="rounded-xl border p-4 dark:border-white/10 space-y-1.5">
                          <div className="flex items-center justify-between text-xs">
                            <span className="font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                              <History size={14} className="text-brand-600" /> {e.reason}
                            </span>
                            <span className="text-slate-500">{formatDate(e.at, true)}</span>
                          </div>
                          <p className="text-xs text-slate-500">Usuario: <strong>{e.actor}</strong></p>

                          <details className="text-xs mt-2">
                            <summary className="cursor-pointer font-medium text-brand-700 dark:text-glass">
                              Comparar datos antes y después
                            </summary>
                            <div className="mt-2 grid gap-2 sm:grid-cols-2">
                              <div>
                                <span className="font-semibold text-slate-500 block mb-1">Antes:</span>
                                <pre className="max-h-48 overflow-auto rounded bg-slate-100 p-2 text-[10px] dark:bg-slate-950 font-mono">
                                  {JSON.stringify(e.beforeData, null, 2)}
                                </pre>
                              </div>
                              <div>
                                <span className="font-semibold text-slate-500 block mb-1">Después:</span>
                                <pre className="max-h-48 overflow-auto rounded bg-slate-100 p-2 text-[10px] dark:bg-slate-950 font-mono">
                                  {JSON.stringify(e.afterData, null, 2)}
                                </pre>
                              </div>
                            </div>
                          </details>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="rounded-xl border border-dashed p-6 text-center text-sm text-slate-500 dark:border-white/10">
                      No hay eventos de auditoría previos registrados para este proveedor.
                    </p>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* 7. Modal: Comparador de Proveedores */}
      {compareModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm overflow-y-auto">
          <div className="relative w-full max-w-5xl rounded-2xl bg-white shadow-2xl dark:bg-slate-900 border dark:border-white/10 max-h-[90vh] flex flex-col my-auto">
            <div className="flex items-center justify-between border-b px-6 py-4 dark:border-white/10">
              <div>
                <h3 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
                  <FileSpreadsheet className="text-brand-600" size={20} /> Comparador de condiciones entre proveedores
                </h3>
                <p className="text-xs text-slate-500">
                  Compara plazos, condiciones comerciales y estado de homologación para tomar decisiones de compra.
                </p>
              </div>
              <Button variant="ghost" onClick={() => setCompareModalOpen(false)} icon={<X size={18} />}>
                Cerrar
              </Button>
            </div>

            <div className="p-6 overflow-y-auto space-y-4">
              <div className="flex flex-wrap gap-2 text-xs">
                <span className="font-semibold text-slate-700 dark:text-slate-300 self-center">Selecciona hasta 3 proveedores:</span>
                {rows.map((r) => {
                  const isSel = selectedToCompare.includes(r.id);
                  return (
                    <button
                      key={r.id}
                      type="button"
                      onClick={() => {
                        if (isSel) {
                          setSelectedToCompare(selectedToCompare.filter((id) => id !== r.id));
                        } else if (selectedToCompare.length < 3) {
                          setSelectedToCompare([...selectedToCompare, r.id]);
                        }
                      }}
                      className={`rounded-lg px-2.5 py-1 font-semibold transition ${
                        isSel
                          ? "bg-brand-600 text-white"
                          : "bg-slate-100 text-slate-700 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-300"
                      }`}
                    >
                      {r.name}
                    </button>
                  );
                })}
              </div>

              {selectedToCompare.length > 0 ? (
                <div className="overflow-x-auto rounded-xl border dark:border-white/10">
                  <table className="w-full text-left text-xs">
                    <thead className="border-b bg-slate-50 dark:bg-slate-800 dark:border-white/10">
                      <tr>
                        <th className="p-3">Criterio comparativo</th>
                        {selectedToCompare.map((id) => {
                          const p = rows.find((r) => r.id === id);
                          return <th key={id} className="p-3 font-bold text-slate-900 dark:text-white">{p?.name}</th>;
                        })}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 dark:divide-white/10">
                      <tr>
                        <td className="p-3 font-semibold text-slate-500">Categoría y Especialidad</td>
                        {selectedToCompare.map((id) => {
                          const p = rows.find((r) => r.id === id);
                          return (
                            <td key={id} className="p-3">
                              {categoriesMap[p?.category ?? "otro"]} · {specialtiesMap[p?.specialty ?? "otro"]}
                            </td>
                          );
                        })}
                      </tr>
                      <tr>
                        <td className="p-3 font-semibold text-slate-500">Plazo de entrega habitual</td>
                        {selectedToCompare.map((id) => {
                          const p = rows.find((r) => r.id === id);
                          return <td key={id} className="p-3 font-bold">{p?.leadDays !== null ? `${p?.leadDays} días` : "Sin registrar"}</td>;
                        })}
                      </tr>
                      <tr>
                        <td className="p-3 font-semibold text-slate-500">Condiciones de pago</td>
                        {selectedToCompare.map((id) => {
                          const p = rows.find((r) => r.id === id);
                          return <td key={id} className="p-3">{p?.paymentTerms || "Sin registrar"}</td>;
                        })}
                      </tr>
                      <tr>
                        <td className="p-3 font-semibold text-slate-500">Moneda</td>
                        {selectedToCompare.map((id) => {
                          const p = rows.find((r) => r.id === id);
                          return <td key={id} className="p-3">{p?.currency}</td>;
                        })}
                      </tr>
                      <tr>
                        <td className="p-3 font-semibold text-slate-500">Descuentos acordados</td>
                        {selectedToCompare.map((id) => {
                          const p = rows.find((r) => r.id === id);
                          return <td key={id} className="p-3">{p?.discounts || "Ninguno"}</td>;
                        })}
                      </tr>
                      <tr>
                        <td className="p-3 font-semibold text-slate-500">Condiciones de transporte</td>
                        {selectedToCompare.map((id) => {
                          const p = rows.find((r) => r.id === id);
                          return <td key={id} className="p-3">{p?.transportTerms || "No especificado"}</td>;
                        })}
                      </tr>
                      <tr>
                        <td className="p-3 font-semibold text-slate-500">Homologación interna</td>
                        {selectedToCompare.map((id) => {
                          const p = rows.find((r) => r.id === id);
                          return (
                            <td key={id} className="p-3">
                              <StatusPill tone={p?.reviewStatus === "aprobado" ? "ok" : p?.reviewStatus === "rechazado" ? "bad" : "warn"}>
                                {reviewsMap[p?.reviewStatus ?? "pendiente"]}
                              </StatusPill>
                            </td>
                          );
                        })}
                      </tr>
                      <tr>
                        <td className="p-3 font-semibold text-slate-500">Documentos vigentes</td>
                        {selectedToCompare.map((id) => {
                          const p = rows.find((r) => r.id === id);
                          return (
                            <td key={id} className="p-3">
                              {p?.documents.filter((d) => d.review === "aceptado").length || 0} aceptados
                            </td>
                          );
                        })}
                      </tr>
                    </tbody>
                  </table>
                </div>
              ) : (
                <p className="text-xs text-slate-500">Selecciona al menos un proveedor para comparar.</p>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
