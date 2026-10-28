import { getApiBaseUrl } from '../lib/apiBase';
import { PayrollStaffRegistration } from "../components/PayrollStaffRegistration";
import { PayrollPaymentHistory, type PayrollPaidAllocation } from "../components/PayrollPaymentHistory";
import { payrollPaymentGuide, payrollPaymentSteps } from "../lib/payrollGuide";
import { Link, useSearchParams } from "react-router-dom";
import { paidToEmployee, pendingForEmployee } from "../lib/payrollPayments";
import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  AlertCircle,
  AlertTriangle,
  ArrowRight,
  Award,
  Banknote,
  BookOpen,
  Building2,
  Calendar,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  ChevronUp,
  Clock,
  Download,
  FileCheck,
  FileSpreadsheet,
  FileText,
  Filter,
  History,
  Info,
  Layers,
  Lock,
  PieChart,
  Plus,
  Printer,
  RefreshCw,
  RotateCcw,
  Search,
  Shield,
  ShieldAlert,
  Trash2,
  UserCheck,
  UserPlus,
  Users,
  Wallet,
  X
} from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { authenticatedFetch, classifyApiFailure, formatApiErrorMessage } from "../auth/apiSession";
import { Button } from "../components/Button";
import { Field, inputClass, Money, PageHeader, StatusPill } from "../components/Ui";

const API_URL = getApiBaseUrl();

/* =========================================================
   TIPOS DE DATOS DE NÓMINA (PAYROLL)
   ========================================================= */
export type PayrollStatus =
  | "borrador"
  | "calculada"
  | "revisada"
  | "aprobada"
  | "pago_registrado"
  | "conciliada"
  | "cerrada";

export type PayrollTab =
  | "resumen"
  | "trabajadores"
  | "novedades"
  | "validaciones"
  | "aprobaciones"
  | "pagos"
  | "obligaciones"
  | "comprobantes"
  | "reportes"
  | "historial";

export type PayrollRun = {
  id: string;
  period: string;
  periodType: "quincenal" | "mensual" | "catorcenal" | "especial_aguinaldo" | "liquidacion";
  startDate: string;
  endDate: string;
  paymentDate: string;
  status: PayrollStatus;
  calculationVersion: number;
  calculationStale?: boolean | number;
  grossTotal: number;
  inssLaboralTotal: number;
  incomeTaxTotal: number;
  otherDeductionsTotal: number;
  totalDeductions: number;
  // Suma del detalle de la planilla y marca de coherencia de la cabecera
  // historica. Se usan para no mostrar "0" cuando el detalle si tiene montos.
  deductionsFromItems?: number;
  headerConsistent?: boolean | number;
  netTotal: number;
  inssPatronalTotal: number;
  inatecTotal: number;
  aguinaldoProvTotal: number;
  vacacionesProvTotal: number;
  indemnizacionProvTotal: number;
  employerCostTotal: number;
  confirmedPaymentsTotal: number;
  recordedPaymentsTotal?: number;
  paymentTotalsConsistent?: boolean | number;
  pendingPayment?: number;
  pendingDiscrepancyTotal: number;
  preparedByName?: string;
  preparedAt?: string;
  calculatedAt?: string;
  reviewedAt?: string;
  approvedAt?: string;
  paidAt?: string;
  reconciledAt?: string;
  closedAt?: string;
  workersCount: number;
  blockingIssuesCount: number;
  warningIssuesCount: number;
  revision: string;
  updatedAt?: string;
};

export type PayrollItem = {
  id: string;
  employeeId: string;
  employeeName: string;
  position: string;
  area: string;
  baseSalaryMonthly: number;
  daysWorked: number;
  hoursWorked: number;
  ordinarySalary: number;
  overtimeHours: number;
  overtimeAmount: number;
  bonusesAmount: number;
  commissionsAmount: number;
  vacationDisfruteAmount: number;
  otherTaxableIncome: number;
  grossIncome: number;
  inssBase: number;
  inssLaboral: number;
  irBase: number;
  incomeTax: number;
  otherDeductions: number;
  totalDeductions: number;
  netPay: number;
  inssPatronal: number;
  inatec: number;
  aguinaldoProv: number;
  vacacionesProv: number;
  indemnizacionProv: number;
  employerCost: number;
  paymentStatus: "pendiente" | "pagado" | "pago_parcial" | "retenido";
  paymentMethod: string;
  paymentReference: string | null;
  explanationJson?: string;
  receiptStatus: "no_generado" | "disponible" | "consultado";
  revision: string;
};

export type PayrollNovelty = {
  id: string;
  payrollRunId: string | null;
  employeeId: string;
  employeeName?: string;
  noveltyType:
    | "horas_extra"
    | "bono"
    | "comision"
    | "vacaciones"
    | "permiso_sin_sueldo"
    | "subsidio_inss"
    | "ajuste_retroactivo"
    | "deduccion_prestamo"
    | "otro";
  concept: string;
  amount: number;
  hours?: number | null;
  legalJustification?: string | null;
  docReference?: string | null;
  periodDate: string;
  status: string;
  createdAt: string;
};

export type PayrollValidation = {
  id: string;
  severity: "bloqueante" | "advertencia" | "informativa";
  ruleCode: string;
  message: string;
  targetTab: string;
  isResolved: boolean;
};

export type PayrollObligation = {
  id: string;
  entity: string;
  period: string;
  baseAmount: number;
  payableAmount: number;
  dueDate: string | null;
  revision?: string;
  status: string;
  declarationRef?: string | null;
  receiptRef?: string | null;
  paidAt?: string | null;
};

export type PayrollHistoryEvent = {
  id: string;
  actorName: string;
  eventType: string;
  previousStatus?: string | null;
  newStatus?: string | null;
  description: string;
  createdAt: string;
};

export type PayrollReceipt = {
  receiptNumber: string;
  period: string;
  periodType: string;
  startDate: string;
  endDate: string;
  paymentDate: string;
  runStatus: string;
  employeeId: string;
  employeeName: string;
  position: string;
  area: string;
  hireDate: string;
  baseSalaryMonthly: number;
  daysWorked: number;
  hoursWorked: number;
  ordinarySalary: number;
  overtimeHours: number;
  overtimeAmount: number;
  bonusesAmount: number;
  commissionsAmount: number;
  vacationDisfruteAmount: number;
  otherTaxableIncome: number;
  grossTotal: number;
  inssLaboral: number;
  incomeTax: number;
  otherDeductions: number;
  totalDeductions: number;
  netPay: number;
  paymentStatus: string;
  paymentMethod: string;
  paymentReference: string | null;
  paymentConfirmedAt: string | null;
  explanationJson?: string;
  employerInfo: string;
};

const STATUS_LABELS: Record<PayrollStatus, { label: string; tone: "ok" | "warn" | "bad" | "neutral" }> = {
  borrador: { label: "Borrador", tone: "neutral" },
  calculada: { label: "Calculada", tone: "warn" },
  revisada: { label: "Revisada", tone: "warn" },
  aprobada: { label: "Aprobada", tone: "ok" },
  pago_registrado: { label: "Pago Registrado", tone: "ok" },
  conciliada: { label: "Conciliada", tone: "ok" },
  cerrada: { label: "Cerrada", tone: "neutral" }
};

function newPaymentKey(): string {
  const cryptoApi = globalThis.crypto;
  if (cryptoApi && typeof cryptoApi.randomUUID === "function") return cryptoApi.randomUUID();
  return `pay-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 12)}`;
}

export function PayrollWorkspace() {
  const { user } = useAuth();
  const [searchParams] = useSearchParams();
  const requestedEmployeeId = searchParams.get("employeeId") ?? "";
  const [activeTab, setActiveTab] = useState<PayrollTab>("pagos");

  // Planillas disponibles y seleccionada
  const [runs, setRuns] = useState<PayrollRun[]>([]);
  const [selectedRunId, setSelectedRunId] = useState<string>("");
  const [runDetails, setRunDetails] = useState<PayrollRun | null>(null);
  const [validations, setValidations] = useState<PayrollValidation[]>([]);
  const [items, setItems] = useState<PayrollItem[]>([]);
  const [novelties, setNovelties] = useState<PayrollNovelty[]>([]);
  const [obligations, setObligations] = useState<PayrollObligation[]>([]);
  const [historyEvents, setHistoryEvents] = useState<PayrollHistoryEvent[]>([]);

  // Estados de carga y feedback
  const [loading, setLoading] = useState(false);
  const [runsLoadError, setRunsLoadError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [feedback, setFeedback] = useState<{ type: "success" | "error" | "info"; message: string } | null>(null);

  // Modales
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showNoveltyModal, setShowNoveltyModal] = useState(false);
  const [showRollbackModal, setShowRollbackModal] = useState(false);
  const [showItemDetailModal, setShowItemDetailModal] = useState<PayrollItem | null>(null);
  const [showExplainModal, setShowExplainModal] = useState<PayrollItem | null>(null);
  const [showReceiptModal, setShowReceiptModal] = useState<PayrollReceipt | null>(null);

  // Estados interactivos para gestión de trabajadores y dispersión de pago
  const [modalError, setModalError] = useState<string | null>(null);
  const [employeesDirectory, setEmployeesDirectory] = useState<{ id: string; name: string; position: string; area: string }[]>([]);
  const [showAddWorkerModal, setShowAddWorkerModal] = useState(false);
  const [addWorkerDraft, setAddWorkerDraft] = useState({
    employeeId: "",
    reason: ""
  });
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [paymentWorkerSearch, setPaymentWorkerSearch] = useState("");
  const individualPaymentRef = useRef<HTMLElement>(null);
  const differencesPanelRef = useRef<HTMLDivElement>(null);
  const [confirmedPaymentNotice, setConfirmedPaymentNotice] = useState<{ runId: string; id: string } | null>(null);
  const [paymentCheck, setPaymentCheck] = useState<{ ready: boolean; retryExisting?: boolean; pending?: number; available?: number | null; checks: Array<{ code: string; label: string; ok: boolean }> } | null>(null);
  const [payments, setPayments] = useState<Array<{
    id: string;
    amount: number;
    employeeId?: string | null;
    paymentMethod: string;
    paymentReference: string;
    paymentDate: string;
    confirmedByName?: string | null;
    cashMoveId?: string | null;
    allocations?: PayrollPaidAllocation[];
    calculationVersion?: number;
    period?: string;
  }>>([]);
  const detailGeneration = useRef(0);
  const [paymentsReady, setPaymentsReady] = useState(false);
  const [paymentDraft, setPaymentDraft] = useState({
    amount: "",
    paymentMethod: "transferencia_bancaria",
    paymentReference: "",
    paymentDate: new Date().toISOString().slice(0, 10),
    notes: "",
    employeeId: ""
  });
  // Idempotency key del pago: se genera una sola vez por intento. Un doble clic
  // o un reintento tras un fallo de red reutiliza la clave y el servidor
  // devuelve la misma operación en lugar de registrar un segundo egreso.
  const paymentKeyRef = useRef<string>(newPaymentKey());

  useEffect(() => { setPaymentCheck(null); }, [paymentDraft, selectedRunId]);

  // Formulario nuevo borrador
  const [newDraft, setNewDraft] = useState({
    period: "",
    periodType: "quincenal" as PayrollRun["periodType"],
    startDate: new Date().toISOString().slice(0, 8) + "01",
    endDate: new Date().toISOString().slice(0, 8) + "15",
    paymentDate: new Date().toISOString().slice(0, 8) + "15",
    notes: ""
  });

  // Formulario nueva novedad
  const [newNovelty, setNewNovelty] = useState({
    employeeId: "",
    noveltyType: "horas_extra" as PayrollNovelty["noveltyType"],
    concept: "",
    amount: 0,
    hours: 0,
    legalJustification: "",
    docReference: "",
    periodDate: new Date().toISOString().slice(0, 10)
  });

  // Formulario de retroceso
  const [rollbackNotes, setRollbackNotes] = useState("");
  const [rollbackTarget, setRollbackTarget] = useState<"borrador" | "calculada">("borrador");

  // Filtros de trabajadores
  const [searchWorker, setSearchWorker] = useState("");
  const [filterArea, setFilterArea] = useState("todas");

  // ---------------------------------------------------------------------------
  // CARGA DE LISTA DE PLANILLAS
  // ---------------------------------------------------------------------------
  const loadRuns = useCallback(async () => {
    try {
      setLoading(true);
      const res = await authenticatedFetch(`${API_URL}/api/payroll/runs`);
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const classified = classifyApiFailure(res.status, data.message, data.code);
        throw new Error(classified.message);
      }
      setRuns(data.runs || []);
      setRunsLoadError(null);
      if (data.runs?.length > 0 && !selectedRunId) {
        setSelectedRunId(data.runs[0].id);
      }
      // Cargar colaboradores de Talento Humano para selector de personal elegible
      authenticatedFetch(`${API_URL}/api/hr/employees`)
        .then(r => r.json())
        .then(d => {
          if (Array.isArray(d.employees)) {
            setEmployeesDirectory(d.employees.map((e: any) => ({
              id: e.id || e.EmployeeId,
              name: e.name || e.Name,
              position: e.position || e.Position,
              area: e.area || e.Area
            })));
          }
        })
        .catch(() => null);
    } catch (err: any) {
      const errInfo = formatApiErrorMessage(err);
      setRunsLoadError(errInfo.message);
      setFeedback({ type: "error", message: errInfo.message });
    } finally {
      setLoading(false);
    }
  }, [selectedRunId]);

  useEffect(() => {
    void loadRuns();
  }, [loadRuns]);

  // ---------------------------------------------------------------------------
  // CARGA DEL DETALLE DE LA PLANILLA SELECCIONADA
  // ---------------------------------------------------------------------------
  const loadRunDetail = useCallback(async (runId: string) => {
    if (!runId) return;
    const generation = ++detailGeneration.current;
    setPaymentsReady(false);
    setPayments([]);
    setItems([]);
    setRunDetails(null);
    setValidations([]);
    setNovelties([]);
    setObligations([]);
    try {
      setLoading(true);
      const [resRun, resItems, resNov, resObl, resPay] = await Promise.all([
        authenticatedFetch(`${API_URL}/api/payroll/runs/${runId}`),
        authenticatedFetch(`${API_URL}/api/payroll/runs/${runId}/items`),
        authenticatedFetch(`${API_URL}/api/payroll/novelties?runId=${runId}`),
        authenticatedFetch(`${API_URL}/api/payroll/obligations/${runId}`).catch(() => null),
        authenticatedFetch(`${API_URL}/api/payroll/runs/${runId}/payments`).catch(() => null)
      ]);
      if (generation !== detailGeneration.current) return;

      if (resRun.ok) {
        const dataRun = await resRun.json();
        setRunDetails(dataRun.run);
        setValidations(dataRun.validations || []);
      } else {
        const errJson = await resRun.json().catch(() => ({}));
        const classified = classifyApiFailure(resRun.status, errJson.message);
        setFeedback({ type: "error", message: classified.message });
      }
      if (resItems.ok) {
        const dataItems = await resItems.json();
        setItems(dataItems.items || []);
      }
      if (resNov.ok) {
        const dataNov = await resNov.json();
        setNovelties(dataNov.novelties || []);
      }
      if (resObl && resObl.ok) {
        const dataObl = await resObl.json();
        setObligations(dataObl.obligations || []);
      }
      if (resPay && resPay.ok) {
        const dataPay = await resPay.json();
        setPayments(dataPay.payments || []);
        setPaymentsReady(true);
      } else {
        const failure = resPay ? await resPay.json().catch(() => ({})) : {};
        setFeedback({ type: "error", message: failure.message || "No se pudieron verificar los pagos. Actualiza antes de intentar pagar." });
      }
    } catch (err: any) {
      if (generation !== detailGeneration.current) return;
      const errInfo = formatApiErrorMessage(err);
      setFeedback({ type: "error", message: errInfo.message });
    } finally {
      if (generation === detailGeneration.current) setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (selectedRunId) {
      setFeedback(null);
      setShowPaymentModal(false);
      void loadRunDetail(selectedRunId);
    }
  }, [selectedRunId, loadRunDetail]);

  // ---------------------------------------------------------------------------
  // ACCIONES DEL FLUJO: CÁLCULO Y TRANSICIONES
  // ---------------------------------------------------------------------------
  const handleCalculate = async () => {
    if (!runDetails) return;
    try {
      setBusy(true);
      setFeedback(null);
      const res = await authenticatedFetch(`${API_URL}/api/payroll/runs/${runDetails.id}/calculate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ expectedRevision: runDetails.revision })
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Error al ejecutar el cálculo de nómina.");
      }
      setFeedback({ type: "success", message: data.message });
      await loadRunDetail(runDetails.id);
      await loadRuns();
    } catch (err: any) {
      setFeedback({ type: "error", message: err.message });
    } finally {
      setBusy(false);
    }
  };

  const handleTransition = async (targetStatus: PayrollStatus, notes?: string) => {
    if (!runDetails) return;
    if (["conciliada", "cerrada"].includes(targetStatus) && paymentReconciliationPending) {
      setFeedback({ type: "error", message: "No se puede cerrar ni conciliar: faltan pagos confirmados o hay diferencias con el acumulado histórico. Revisa los comprobantes en Pagos por trabajador." });
      setActiveTab("pagos");
      return;
    }
    try {
      setBusy(true);
      setFeedback(null);
      const res = await authenticatedFetch(`${API_URL}/api/payroll/runs/${runDetails.id}/transition`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          targetStatus,
          expectedRevision: runDetails.revision,
          notes: notes || undefined
        })
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Error en la transición de estado.");
      }
      setFeedback({ type: "success", message: data.message });
      setShowRollbackModal(false);
      setRollbackNotes("");
      await loadRunDetail(runDetails.id);
      await loadRuns();
    } catch (err: any) {
      setFeedback({ type: "error", message: err.message });
    } finally {
      setBusy(false);
    }
  };

  // Crear Borrador
  const handleCreateDraft = async (e: FormEvent) => {
    e.preventDefault();
    try {
      setBusy(true);
      setModalError(null);
      setFeedback(null);
      const res = await authenticatedFetch(`${API_URL}/api/payroll/runs`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(newDraft)
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const classified = classifyApiFailure(res.status, data.message);
        throw new Error(classified.message);
      }
      setFeedback({ type: "success", message: data.message || "Borrador de planilla creado." });
      setShowCreateModal(false);
      setNewDraft({
        period: "",
        periodType: "quincenal",
        startDate: new Date().toISOString().slice(0, 8) + "01",
        endDate: new Date().toISOString().slice(0, 8) + "15",
        paymentDate: new Date().toISOString().slice(0, 8) + "15",
        notes: ""
      });
      await loadRuns();
      if (data.run?.id) {
        setSelectedRunId(data.run.id);
        await loadRunDetail(data.run.id);
      }
    } catch (err: any) {
      setModalError(err.message);
      setFeedback({ type: "error", message: err.message });
    } finally {
      setBusy(false);
    }
  };

  // Agregar Novedad
  const handleCreateNovelty = async (e: FormEvent) => {
    e.preventDefault();
    if (!selectedRunId) return;
    try {
      setBusy(true);
      setModalError(null);
      setFeedback(null);
      const res = await authenticatedFetch(`${API_URL}/api/payroll/novelties`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...newNovelty,
          payrollRunId: selectedRunId,
          amount: Number(newNovelty.amount),
          hours: newNovelty.hours ? Number(newNovelty.hours) : undefined
        })
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const classified = classifyApiFailure(res.status, data.message);
        throw new Error(classified.message);
      }
      setFeedback({ type: "success", message: "Novedad registrada exitosamente." });
      setShowNoveltyModal(false);
      setNewNovelty({
        employeeId: "",
        noveltyType: "horas_extra",
        concept: "",
        amount: 0,
        hours: 0,
        legalJustification: "",
        docReference: "",
        periodDate: new Date().toISOString().slice(0, 10)
      });
      await loadRunDetail(selectedRunId);
      await loadRuns();
    } catch (err: any) {
      setModalError(err.message);
      setFeedback({ type: "error", message: err.message });
    } finally {
      setBusy(false);
    }
  };

  // Incluir Trabajador a Planilla
  const handleAddWorker = async (e: FormEvent) => {
    e.preventDefault();
    if (!selectedRunId || !addWorkerDraft.employeeId) return;
    try {
      setBusy(true);
      setModalError(null);
      const res = await authenticatedFetch(`${API_URL}/api/payroll/runs/${selectedRunId}/workers`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(addWorkerDraft)
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const classified = classifyApiFailure(res.status, data.message);
        throw new Error(classified.message);
      }
      setFeedback({ type: "success", message: data.message || "Colaborador agregado a la planilla con éxito." });
      setShowAddWorkerModal(false);
      setAddWorkerDraft({ employeeId: "", reason: "" });
      await loadRunDetail(selectedRunId);
      await loadRuns();
    } catch (err: any) {
      setModalError(err.message);
    } finally {
      setBusy(false);
    }
  };

  // Retirar Trabajador de Planilla (en Borrador)
  const handleRemoveWorker = async (item: PayrollItem) => {
    if (!selectedRunId) return;
    const reason = window.prompt(
      `¿Desea retirar a ${item.employeeName} de esta planilla en borrador?\nIndique el motivo administrativo:`
    );
    if (reason === null) return;

    try {
      setBusy(true);
      const res = await authenticatedFetch(
        `${API_URL}/api/payroll/runs/${selectedRunId}/workers/${encodeURIComponent(item.employeeId)}?reason=${encodeURIComponent(reason || "Retiro administrativo")}`,
        { method: "DELETE" }
      );
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const classified = classifyApiFailure(res.status, data.message);
        throw new Error(classified.message);
      }
      setFeedback({ type: "success", message: `Colaborador ${item.employeeName} retirado de la planilla.` });
      await loadRunDetail(selectedRunId);
      await loadRuns();
    } catch (err: any) {
      setFeedback({ type: "error", message: err.message });
    } finally {
      setBusy(false);
    }
  };

  // Eliminar / Cancelar Novedad
  const handleDeleteNovelty = async (nov: PayrollNovelty) => {
    if (!selectedRunId) return;
    const confirm = window.confirm(
      `¿Está seguro de eliminar la novedad '${nov.concept}' de ${nov.employeeName || nov.employeeId}?\n` +
      (runDetails?.status === "calculada" ? "El cálculo actual se marcará como desactualizado para requerir recálculo transparente." : "")
    );
    if (!confirm) return;

    try {
      setBusy(true);
      const res = await authenticatedFetch(
        `${API_URL}/api/payroll/novelties/${encodeURIComponent(nov.id)}`,
        { method: "DELETE" }
      );
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const classified = classifyApiFailure(res.status, data.message);
        throw new Error(classified.message);
      }
      setFeedback({ type: "success", message: "Novedad eliminada y cálculo marcado como desactualizado si aplicaba." });
      await loadRunDetail(selectedRunId);
      await loadRuns();
    } catch (err: any) {
      setFeedback({ type: "error", message: err.message });
    } finally {
      setBusy(false);
    }
  };

  // Registrar Dispersión / Pago Bancario
  // Pago por planilla completa (sin employeeId) o pago individual a un empleado
  // (employeeId presente). En ambos casos el servidor garantiza idempotencia y
  // que nunca se pague más que el neto aprobado.
  const validatePaymentBeforeSending = async () => {
    const response = await authenticatedFetch(`${API_URL}/api/payroll/runs/${selectedRunId}/payment-check`, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ mutationId: paymentKeyRef.current, amount: Number(paymentDraft.amount),
        employeeId: paymentDraft.employeeId, paymentMethod: paymentDraft.paymentMethod,
        paymentReference: paymentDraft.paymentReference, paymentDate: paymentDraft.paymentDate, notes: paymentDraft.notes || null })
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.message || "No se pudo verificar el pago en el servidor.");
    setPaymentCheck(result);
    if (!result.ready) throw new Error(result.checks.filter((check: { ok: boolean }) => !check.ok).map((check: { label: string }) => check.label).join(". "));
    return result;
  };
  const handleCheckPayment = async () => {
    if (busy) return;
    setBusy(true); setModalError(null);
    try { await validatePaymentBeforeSending(); }
    catch (error: any) { setModalError(error.message); }
    finally { setBusy(false); }
  };

  const handleRegisterPayment = async (e: FormEvent) => {
    e.preventDefault();
    if (!selectedRunId) return;
    if (paymentBlockReason) { setModalError(paymentBlockReason); return; }
    if (!paymentDraft.employeeId || !items.some((item) => item.employeeId === paymentDraft.employeeId)) {
      setModalError("Selecciona un trabajador de esta planilla para registrar su abono.");
      return;
    }
    if (!paymentsReady) {
      setModalError("Actualiza la planilla: no se ha confirmado el historial de pagos.");
      return;
    }
    if (busy) return; // apoyo visual: la garantía real es la clave de idempotencia
    const employeeId = paymentDraft.employeeId || "";
    const itemEmployee = employeeId ? items.find((item) => item.employeeId === employeeId) : null;
    const itemNet = itemEmployee ? Number(itemEmployee.netPay ?? 0) : 0;
    const pending = employeeId
      ? pendingForEmployee(itemNet, payments, employeeId)
      : Math.max(0, Number(runDetails?.netTotal ?? 0) - Number(runDetails?.confirmedPaymentsTotal ?? 0));
    const amount = Number(paymentDraft.amount);
    if (!Number.isFinite(amount) || amount <= 0) {
      setModalError("El monto del pago debe ser mayor que cero.");
      return;
    }
    if (amount > pending + 0.009) {
      setModalError(
        employeeId
          ? `El pago excede el neto pendiente de ${itemEmployee?.employeeName ?? "el empleado"} (C$ ${pending.toFixed(2)}).`
          : `El pago excede el pendiente aprobado (C$ ${pending.toFixed(2)}). Registra primero un pago parcial válido.`
      );
      return;
    }
    if (!paymentDraft.paymentReference.trim()) {
      setModalError("Indica la referencia del pago (número de transferencia, cheque o comprobante).");
      return;
    }
    try {
      setBusy(true);
      setModalError(null);
      await validatePaymentBeforeSending();
      const res = await authenticatedFetch(`${API_URL}/api/payroll/runs/${selectedRunId}/payments`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          mutationId: paymentKeyRef.current,
          amount,
          paymentMethod: paymentDraft.paymentMethod,
          paymentReference: paymentDraft.paymentReference,
          paymentDate: paymentDraft.paymentDate,
          notes: paymentDraft.notes || null,
          employeeId: employeeId || null
        })
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const classified = classifyApiFailure(res.status, data.message, data.code);
        throw new Error(classified.message);
      }
      if (!data.payment?.PaymentId) throw new Error("Respuesta incierta: no se pudo verificar el identificador del pago. Reintenta con la misma operación; no crees otra referencia.");
      setConfirmedPaymentNotice({ runId: selectedRunId, id: data.payment.PaymentId });
      // Solo se renueva la clave cuando la operación quedó confirmada.
      paymentKeyRef.current = newPaymentKey();
      setFeedback({
        type: "success",
        message: data.message || (employeeId
          ? `Pago registrado a ${itemEmployee?.employeeName ?? "el empleado"}.`
          : "Dispersión de pago registrada formalmente en SQL Server.")
      });
      setShowPaymentModal(false);
      setPaymentDraft((prev) => ({ ...prev, employeeId: "" }));
      await loadRunDetail(selectedRunId);
      await loadRuns();
    } catch (err: any) {
      // Se conserva la misma clave: reintentar devuelve la misma operación.
      setModalError(err.message);
    } finally {
      setBusy(false);
    }
  };

  const handleObligationDate = async (event: FormEvent<HTMLFormElement>, obligation: PayrollObligation) => {
    event.preventDefault();
    if (busy || !obligation.revision) return;
    const data = new FormData(event.currentTarget);
    setBusy(true);
    try {
      const response = await authenticatedFetch(`${API_URL}/api/payroll/obligations/${obligation.id}/due-date`, {
        method: "PATCH", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ dueDate: data.get("dueDate"), source: data.get("source"), expectedRevision: obligation.revision })
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "No se pudo guardar el vencimiento.");
      setFeedback({ type: "success", message: result.message });
      await loadRunDetail(selectedRunId);
    } catch (error: any) { setFeedback({ type: "error", message: error.message }); }
    finally { setBusy(false); }
  };

  // Ver Comprobante
  const handleViewReceipt = async (employeeId: string) => {
    if (!selectedRunId) return;
    try {
      setBusy(true);
      const res = await authenticatedFetch(`${API_URL}/api/payroll/runs/${selectedRunId}/receipts/${employeeId}`);
      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.message || "No se pudo obtener el comprobante.");
      }
      const data = await res.json();
      setShowReceiptModal(data.receipt);
    } catch (err: any) {
      setFeedback({ type: "error", message: err.message });
    } finally {
      setBusy(false);
    }
  };

  // Filtrado de trabajadores
  const filteredItems = useMemo(() => {
    return items.filter((item) => {
      const matchSearch =
        item.employeeName.toLowerCase().includes(searchWorker.toLowerCase()) ||
        item.position.toLowerCase().includes(searchWorker.toLowerCase()) ||
        item.employeeId.toLowerCase().includes(searchWorker.toLowerCase());
      const matchArea = filterArea === "todas" || item.area === filterArea;
      return matchSearch && matchArea;
    });
  }, [items, searchWorker, filterArea]);

  const uniqueAreas = useMemo(() => {
    return Array.from(new Set(items.map((i) => i.area).filter(Boolean)));
  }, [items]);

  // Distinguir "borrador sin calcular" de "cálculo desactualizado" y de una
  // cabecera histórica incoherente evita mostrar C$ 0 como si fuera un cálculo
  // real. La fuente de verdad es el servidor (calculatedAt + deduction detail).
  const calculationState: "pendiente" | "desactualizado" | "sin_calculo" | "calculada" =
    !runDetails
      ? "sin_calculo"
      : runDetails.status === "borrador" && !runDetails.calculatedAt
        ? "pendiente"
        : Boolean(runDetails.calculationStale)
          ? "desactualizado"
          : !runDetails.calculatedAt || Number(runDetails.calculationVersion) === 0
            ? "sin_calculo"
            : "calculada";
  const calculationPending = calculationState !== "calculada";
  const calculationLabel =
    calculationState === "desactualizado"
      ? "Cálculo desactualizado"
      : calculationState === "pendiente"
        ? "Pendiente de cálculo"
        : "Sin cálculo registrado";
  const calculationShort =
    calculationState === "desactualizado"
      ? "Desactualizado"
      : calculationState === "pendiente"
        ? "Pendiente de cálculo"
        : "Sin cálculo";
  const headerInconsistent = Boolean(
    runDetails && (runDetails.headerConsistent === false || Number(runDetails.headerConsistent) === 0)
  );
  const deductionsShown = headerInconsistent
    ? Number(runDetails?.deductionsFromItems ?? 0)
    : Number(runDetails?.totalDeductions ?? 0);
  const pendingPayment = Math.max(
    0,
    Number(runDetails?.pendingPayment ?? (Number(runDetails?.netTotal ?? 0) - Number(runDetails?.confirmedPaymentsTotal ?? 0)))
  );

  const paymentReconciliationPending = !paymentsReady || Math.abs(Number(runDetails?.netTotal ?? 0) - payments.reduce((total, payment) => total + Number(payment.amount), 0)) > 0.009
    || runDetails?.paymentTotalsConsistent === false || runDetails?.paymentTotalsConsistent === 0;
  const paymentBlockReason = !runDetails ? "Selecciona una planilla."
    : ["conciliada", "cerrada"].includes(runDetails.status)
      ? `Esta planilla está ${STATUS_LABELS[runDetails.status].label.toLowerCase()} y no admite nuevos pagos.${pendingPayment > 0 ? " El saldo pendiente requiere revisión documental." : ""}`
      : !["aprobada", "pago_registrado"].includes(runDetails.status)
        ? "Primero calcula, revisa y aprueba esta planilla."
        : calculationPending ? "Se requiere un cálculo confirmado y vigente."
          : !paymentsReady ? "Falta confirmar el historial de pagos. Actualiza la planilla."
            : runDetails.paymentTotalsConsistent === false || runDetails.paymentTotalsConsistent === 0 ? "El acumulado histórico no coincide con los recibos confirmados. Requiere revisión documental."
            : headerInconsistent ? "Los totales de la planilla requieren revisión."
              : null;

  const paymentGuide = runDetails ? payrollPaymentGuide({ status: runDetails.status,
    calculationCurrent: !calculationPending, workers: items.length, blocking: Number(runDetails.blockingIssuesCount ?? 0),
    historyReady: paymentsReady, totalsConsistent: !headerInconsistent, paymentTotalsConsistent: runDetails.paymentTotalsConsistent !== false && runDetails.paymentTotalsConsistent !== 0,
    pending: pendingPayment }) : null;
  const followPaymentGuide = () => {
    if (!paymentGuide || busy || loading) return;
    if (paymentGuide.action === "calcular") { void handleCalculate(); return; }
    if (paymentGuide.action === "actualizar") { void loadRunDetail(selectedRunId); return; }
    if (paymentGuide.action === "diferencias") { differencesPanelRef.current?.scrollIntoView({ behavior: "smooth", block: "center" }); return; }
    if (paymentGuide.action === "revisar") { setActiveTab("validaciones"); return; }
    if (paymentGuide.action === "abono") {
      setModalError(null); setPaymentDraft({ amount: "", employeeId: "", paymentMethod: "transferencia_bancaria",
        paymentReference: "", paymentDate: new Date().toISOString().slice(0, 10), notes: "" });
      setShowPaymentModal(true); return;
    }
    setActiveTab(paymentGuide.action as PayrollTab);
  };

  const selectedPaymentWorker = items.find(item => item.employeeId === paymentDraft.employeeId);
  const renderIndividualPaymentForm = () => (
            <form onSubmit={handleRegisterPayment} className="mt-4 space-y-4 text-xs">
              <fieldset disabled={busy} className="contents">
              <Field label="Trabajador que recibirá el abono">
                <select
                  required
                  value={paymentDraft.employeeId}
                  onChange={(e) => {
                    const employeeId = e.target.value;
                    const itemEmployee = employeeId ? items.find((item) => item.employeeId === employeeId) : null;
                    const nextPending = employeeId
                      ? pendingForEmployee(Number(itemEmployee?.netPay ?? 0), payments, employeeId)
                      : Math.max(0, Number(runDetails?.netTotal ?? 0) - Number(runDetails?.confirmedPaymentsTotal ?? 0));
                    setModalError(null);
                    setPaymentDraft((prev) => ({
                      ...prev,
                      employeeId,
                      amount: ""
                    }));
                  }}
                  className={inputClass}
                >
                  <option value="">Selecciona un trabajador</option>
                  {items.map((item) => (
                    <option key={item.id} value={item.employeeId} disabled={pendingForEmployee(Number(item.netPay ?? 0), payments, item.employeeId) <= 0}>
                      {item.employeeName} — pendiente C$ {pendingForEmployee(Number(item.netPay ?? 0), payments, item.employeeId).toFixed(2)}
                    </option>
                  ))}
                </select>
              </Field>
              <p className="text-[10px] text-slate-500 dark:text-slate-400">
                {paymentDraft.employeeId ? (
                  <>
                    Pago <b>por separado</b> a <b>{items.find((item) => item.employeeId === paymentDraft.employeeId)?.employeeName}</b>. Pendiente de
                    ese colaborador:{" "}
                    <b>
                      C${" "}
                      {pendingForEmployee(
                        Number(items.find((item) => item.employeeId === paymentDraft.employeeId)?.netPay ?? 0),
                        payments,
                        paymentDraft.employeeId
                      ).toFixed(2)}
                    </b>
                    . Puedes ingresar un importe menor y completar el resto en otro pago. Los otros trabajadores conservan su pendiente.
                  </>
                ) : (
                  <>
                    Selecciona al trabajador y registra solo el importe que recibirá ahora.
                  </>
                )}
              </p>
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 dark:border-white/10 dark:bg-slate-950">
                <p className="text-xs font-bold">Período: {runDetails?.period ?? "Selecciona una planilla"}</p>
                {selectedPaymentWorker ? <>
                  <dl className="mt-3 grid grid-cols-2 gap-3 text-xs sm:grid-cols-3">
                    {[
                      ["Salario mensual de referencia", selectedPaymentWorker.baseSalaryMonthly],
                      ["Salario reconocido del período", selectedPaymentWorker.ordinarySalary],
                      ["Bonos del período", selectedPaymentWorker.bonusesAmount],
                      ["Devengado", selectedPaymentWorker.grossIncome],
                      ["INSS laboral", selectedPaymentWorker.inssLaboral],
                      ["IR retenido", selectedPaymentWorker.incomeTax],
                      ["Otras deducciones", selectedPaymentWorker.otherDeductions],
                      ["Neto calculado", selectedPaymentWorker.netPay],
                      ["Abonos confirmados", paidToEmployee(payments, selectedPaymentWorker.employeeId)]
                    ].map(([label, amount]) => <div key={String(label)}><dt className="text-slate-500">{label}</dt><dd className="mt-1 font-bold">{calculationPending ? "Pendiente de cálculo" : <Money value={Number(amount ?? 0)} />}</dd></div>)}
                  </dl>
                  <p className="mt-3 text-[11px] text-slate-500">Las deducciones ya están consideradas en el neto. Los aportes patronales no se descuentan otra vez al pagar.</p>
                  <div className="mt-2 flex flex-wrap gap-2">
                    <Button type="button" variant="ghost" onClick={() => setShowExplainModal(selectedPaymentWorker)}>Explicar cálculo</Button>
                    {runDetails && ["borrador", "calculada"].includes(runDetails.status) && <Button type="button" variant="ghost" onClick={() => { setNewNovelty(prev => ({ ...prev, employeeId: selectedPaymentWorker.employeeId })); setShowPaymentModal(false); setShowNoveltyModal(true); }}>Configurar bonos / deducciones</Button>}
                  </div>
                </> : <p className="mt-2 text-xs text-slate-500">Selecciona un trabajador para consultar su salario, deducciones, neto y pendiente.</p>}
              </div>
              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Importe del abono (C$)">
                  <input
                    type="number"
                    step="0.01"
                    required
                    min={0.01}
                    max={pendingForEmployee(Number(items.find((item) => item.employeeId === paymentDraft.employeeId)?.netPay ?? 0), payments, paymentDraft.employeeId)}
                    placeholder="Escribe cuánto pagarás ahora"
                    value={paymentDraft.amount}
                    onChange={(e) => setPaymentDraft({ ...paymentDraft, amount: e.target.value })}
                    className={inputClass}
                  />
                </Field>

                <Field label="Método de Pago">
                  <select
                    value={paymentDraft.paymentMethod}
                    onChange={(e) => setPaymentDraft({ ...paymentDraft, paymentMethod: e.target.value })}
                    className={inputClass}
                  >
                    <option value="transferencia_bancaria">Transferencia Bancaria (ACH)</option>
                    <option value="cheque">Cheque Bancario</option>
                    <option value="efectivo">Efectivo (Caja General)</option>
                  </select>
                </Field>
              </div>

              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Referencia del comprobante de pago">
                  <input
                    type="text"
                    required
                    placeholder="Ej: LOTE-ACH-BAC-20261015-01"
                    value={paymentDraft.paymentReference}
                    onChange={(e) => setPaymentDraft({ ...paymentDraft, paymentReference: e.target.value })}
                    className={inputClass}
                  />
                </Field>

                <Field label="Fecha de Pago Efectivo">
                  <input
                    type="date"
                    required
                    value={paymentDraft.paymentDate}
                    onChange={(e) => setPaymentDraft({ ...paymentDraft, paymentDate: e.target.value })}
                    className={inputClass}
                  />
                </Field>
              </div>

              {paymentDraft.employeeId && (
                <p className="rounded-lg bg-amber-50 p-3 text-xs text-amber-900 dark:bg-amber-950/30 dark:text-amber-200">
                  Pendiente después de este abono: <Money value={Math.max(0,
                    pendingForEmployee(Number(items.find((item) => item.employeeId === paymentDraft.employeeId)?.netPay ?? 0), payments, paymentDraft.employeeId)
                    - Number(paymentDraft.amount || 0))} />. Se actualizará al confirmar el pago.
                </p>
              )}
              <Field label="Observaciones del pago">
                <textarea
                  rows={2}
                  placeholder="Detalles del desembolso, confirmación bancaria o minuta de depósito..."
                  value={paymentDraft.notes}
                  onChange={(e) => setPaymentDraft({ ...paymentDraft, notes: e.target.value })}
                  className={`${inputClass} h-auto py-2`}
                />
              </Field>

              {paymentCheck && (
                <div role="status" className="rounded-lg border border-slate-200 p-3 text-xs dark:border-white/10">
                  <p className="mb-2 font-bold">Comprobación previa del servidor</p>
                  {paymentCheck.retryExisting ? <p>Se recuperará la operación existente con la misma clave; el servidor comparará su contenido.</p> : (
                    <ul className="space-y-1">{paymentCheck.checks.map(check => <li key={check.code} className={check.ok ? "text-emerald-700 dark:text-emerald-300" : "text-rose-700 dark:text-rose-300"}>{check.ok ? "✓" : "✕"} {check.label}</li>)}</ul>
                  )}
                  <p className="mt-2 text-slate-500">Esta consulta no registra dinero. Las condiciones se vuelven a validar al confirmar.</p>
                </div>
              )}
              <div className="flex justify-end gap-2 pt-3 border-t dark:border-white/10">
                <Button type="button" variant="secondary" onClick={() => void handleCheckPayment()} disabled={busy || !paymentDraft.employeeId || !paymentDraft.amount || !paymentDraft.paymentReference}>Validar requisitos</Button>
                {showPaymentModal && (<Button type="button" variant="secondary" onClick={() => setShowPaymentModal(false)}>
                  Cerrar ventana
                </Button>)}
                <Button type="submit" variant="primary" disabled={busy || Boolean(paymentBlockReason) || !paymentsReady || !paymentDraft.employeeId || !paymentDraft.amount || !paymentDraft.paymentReference}>
                  {busy ? "Confirmando…" : "Registrar pago de nómina"}
                </Button>
              </div>
            </fieldset>
            </form>
  );

  return (
    <div className="space-y-6">
      {/* =========================================================
          ENCABEZADO DE LA PLANILLA Y SELECTOR DE PERÍODO
          ========================================================= */}
      <PageHeader
        kicker="Nómina y Compensaciones"
        title="Gestión de Planillas y Prestaciones Laborales"
        subtitle="Cálculo transparente, trazabilidad contable, cumplimiento normativo (Ley 185, Ley 822 e INSS) e integración con Caja y Bancos."
        actions={
          <div className="flex flex-wrap items-center gap-3">
            <select
              value={selectedRunId}
              disabled={busy || loading}
              onChange={(e) => setSelectedRunId(e.target.value)}
              className="h-10 rounded-lg border border-slate-200 bg-white px-3 font-semibold text-xs shadow-sm dark:border-white/10 dark:bg-slate-900"
            >
              {runs.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.period} ({r.status.toUpperCase()})
                </option>
              ))}
              {runs.length === 0 && <option value="">{loading ? "Cargando planillas…" : runsLoadError ? "Planillas sin consultar" : "Sin planillas creadas"}</option>}
            </select>
            <Button type="button" variant="secondary" disabled={loading || busy} onClick={() => { setFeedback(null); void loadRuns(); if (selectedRunId) void loadRunDetail(selectedRunId); }}>
              <RefreshCw className={`mr-1 h-4 w-4 ${loading ? "animate-spin" : ""}`} /> Reintentar conexión
            </Button>

            <Button
              type="button"
              variant="primary"
              className="flex items-center gap-1.5 text-xs"
              onClick={() => setShowCreateModal(true)}
            >
              <Plus className="h-4 w-4" />
              <span>Nueva Planilla</span>
            </Button>
          </div>
        }
      />

      {runsLoadError && (
        <div role="alert" className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950">
          No se pudieron consultar las planillas. Esto no significa que se hayan borrado. Usa «Reintentar conexión» para volver a cargarlas.
        </div>
      )}

      {/* Alertas y Feedback */}
      {feedback && (
        <div
          className={`flex items-center justify-between rounded-xl p-4 text-xs ${
            feedback.type === "success"
              ? "bg-emerald-50 text-emerald-900 border border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-200"
              : feedback.type === "error"
              ? "bg-rose-50 text-rose-900 border border-rose-200 dark:bg-rose-950/40 dark:text-rose-200"
              : "bg-brand-50 text-brand-900 border border-brand-200 dark:bg-brand-950/40 dark:text-brand-200"
          }`}
        >
          <div className="flex items-center gap-2">
            {feedback.type === "success" && <CheckCircle2 className="h-4 w-4 text-emerald-600" />}
            {feedback.type === "error" && <AlertTriangle className="h-4 w-4 text-rose-600" />}
            {feedback.type === "info" && <Info className="h-4 w-4 text-brand-600" />}
            <span>{feedback.message}</span>
          </div>
          <button type="button" onClick={() => setFeedback(null)} className="text-slate-400 hover:text-slate-600">
            <X className="h-4 w-4" />
          </button>
        </div>
      )}

      {/* Tarjeta de Ficha de Cabecera de la Planilla Activa */}
      {runDetails && (
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-soft dark:border-white/10 dark:bg-slate-900">
          <div className="flex flex-wrap items-center justify-between gap-4 border-b border-slate-100 pb-4 dark:border-white/5">
            <div>
              <div className="flex items-center gap-2">
                <span className="font-mono text-xs text-slate-400">{runDetails.id}</span>
                <StatusPill tone={STATUS_LABELS[runDetails.status]?.tone || "neutral"}>
                  {STATUS_LABELS[runDetails.status]?.label || runDetails.status}
                </StatusPill>
                <span className="rounded bg-slate-100 px-2 py-0.5 font-mono text-[11px] text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                  v{runDetails.calculationVersion}
                </span>
              </div>
              <h2 className="mt-1 font-extrabold text-xl text-slate-900 dark:text-white">
                Planilla: {runDetails.period}
              </h2>
              <p className="text-xs text-slate-500">
                Frecuencia: <strong className="capitalize">{runDetails.periodType}</strong> · Desde{" "}
                <strong>{runDetails.startDate}</strong> hasta <strong>{runDetails.endDate}</strong> · Fecha prevista de
                pago: <strong>{runDetails.paymentDate}</strong>
              </p>
            </div>

            {/* Botones de acción del ciclo de vida */}
            <div className="flex flex-wrap items-center gap-2">
              {runDetails.status === "borrador" && (
                <Button
                  type="button"
                  variant="primary"
                  disabled={busy}
                  onClick={handleCalculate}
                  className="flex items-center gap-1.5 text-xs bg-emerald-600 hover:bg-emerald-700"
                >
                  <RefreshCw className={`h-3.5 w-3.5 ${busy ? "animate-spin" : ""}`} />
                  <span>Calcular Planilla</span>
                </Button>
              )}

              {runDetails.status === "calculada" && (
                <>
                  <Button
                    type="button"
                    variant="primary"
                    disabled={busy || runDetails.blockingIssuesCount > 0}
                    onClick={() => handleTransition("revisada")}
                    className="flex items-center gap-1.5 text-xs"
                  >
                    <CheckCircle2 className="h-3.5 w-3.5" />
                    <span>Marcar como Revisada</span>
                  </Button>
                  <Button
                    type="button"
                    variant="secondary"
                    disabled={busy}
                    onClick={() => {
                      setRollbackTarget("borrador");
                      setShowRollbackModal(true);
                    }}
                    className="flex items-center gap-1.5 text-xs text-slate-600"
                  >
                    <RotateCcw className="h-3.5 w-3.5" />
                    <span>Devolver a Borrador</span>
                  </Button>
                </>
              )}

              {runDetails.status === "revisada" && (
                <>
                  <Button
                    type="button"
                    variant="primary"
                    disabled={busy}
                    onClick={() => handleTransition("aprobada")}
                    className="flex items-center gap-1.5 text-xs bg-indigo-600 hover:bg-indigo-700"
                  >
                    <Shield className="h-3.5 w-3.5" />
                    <span>Aprobar Nómina (Gerencia)</span>
                  </Button>
                  <Button
                    type="button"
                    variant="secondary"
                    disabled={busy}
                    onClick={() => {
                      setRollbackTarget("calculada");
                      setShowRollbackModal(true);
                    }}
                    className="flex items-center gap-1.5 text-xs text-slate-600"
                  >
                    <RotateCcw className="h-3.5 w-3.5" />
                    <span>Devolver a Corrección</span>
                  </Button>
                </>
              )}

              {runDetails.status === "aprobada" && (
                <Button
                  type="button"
                  variant="primary"
                  disabled={busy}
                  onClick={() => { setActiveTab("pagos"); setModalError(null); setPaymentDraft({ amount: "", employeeId: "", paymentMethod: "transferencia_bancaria", paymentReference: "", paymentDate: new Date().toISOString().slice(0, 10), notes: "" }); setShowPaymentModal(true); }}
                  className="flex items-center gap-1.5 text-xs bg-emerald-600 hover:bg-emerald-700"
                >
                  <Banknote className="h-3.5 w-3.5" />
                  <span>Registrar pago individual o abono</span>
                </Button>
              )}

              {runDetails.status === "pago_registrado" && (
                <Button
                  type="button"
                  variant="primary"
                  disabled={busy || paymentReconciliationPending}
                  title={paymentReconciliationPending ? "Faltan pagos confirmados o hay diferencias por revisar" : undefined}
                  onClick={() => handleTransition("conciliada")}
                  className="flex items-center gap-1.5 text-xs bg-teal-600 hover:bg-teal-700"
                >
                  <FileCheck className="h-3.5 w-3.5" />
                  <span>Conciliar con Extracto Bancario</span>
                </Button>
              )}

              {runDetails.status === "conciliada" && (
                <Button
                  type="button"
                  variant="primary"
                  disabled={busy || paymentReconciliationPending}
                  title={paymentReconciliationPending ? "Faltan pagos confirmados o hay diferencias por revisar" : undefined}
                  onClick={() => handleTransition("cerrada")}
                  className="flex items-center gap-1.5 text-xs bg-slate-800 hover:bg-slate-900"
                >
                  <Lock className="h-3.5 w-3.5" />
                  <span>Cierre Definitivo de Planilla</span>
                </Button>
              )}

              {runDetails.status === "cerrada" && (
                <div className="flex items-center gap-1.5 rounded-lg bg-slate-100 px-3 py-1.5 text-xs font-bold text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                  <Lock className="h-3.5 w-3.5" />
                  <span>Planilla Cerrada y Archivada</span>
                </div>
              )}
            </div>
          </div>

          {/* Sub-barra de responsables y sellos de trazabilidad */}
          <div className="mt-3 grid gap-3 text-[11px] text-slate-500 sm:grid-cols-2 lg:grid-cols-4">
            <div>
              <span className="text-slate-400">Preparado por:</span>{" "}
              <strong className="text-slate-700 dark:text-slate-200">
                {runDetails.preparedByName || "Sistema"}
              </strong>
            </div>
            <div>
              <span className="text-slate-400">Trabajadores incluidos:</span>{" "}
              <strong className="text-slate-700 dark:text-slate-200">{runDetails.workersCount} personas</strong>
            </div>
            <div>
              <span className="text-slate-400">Observaciones bloqueantes:</span>{" "}
              <strong
                className={
                  runDetails.blockingIssuesCount > 0
                    ? "font-bold text-rose-600"
                    : "text-slate-700 dark:text-slate-200"
                }
              >
                {runDetails.blockingIssuesCount}
              </strong>
            </div>
            <div>
              <span className="text-slate-400">Última actualización:</span>{" "}
              <strong className="text-slate-700 dark:text-slate-200">
                {runDetails.updatedAt ? new Date(runDetails.updatedAt).toLocaleString("es-NI") : "Reciente"}
              </strong>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          BARRA DE NAVEGACIÓN: 10 PESTAÑAS FUNCIONALES
          ========================================================= */}
      <div className="flex overflow-x-auto border-b border-slate-200 text-xs font-bold dark:border-white/10">
        {[
          { id: "resumen", label: "Resumen", icon: PieChart },
          { id: "trabajadores", label: `Trabajadores (${runDetails?.workersCount || 0})`, icon: Users },
          { id: "novedades", label: `Novedades (${novelties.length})`, icon: Plus },
          {
            id: "validaciones",
            label: `Validaciones (${validations.length})`,
            icon: ShieldAlert,
            badge: runDetails?.blockingIssuesCount ? runDetails.blockingIssuesCount : undefined
          },
          { id: "aprobaciones", label: "Aprobaciones", icon: FileCheck },
          { id: "pagos", label: "Pagos por trabajador", icon: Banknote },
          { id: "obligaciones", label: "Obligaciones (DGI/INSS)", icon: Building2 },
          { id: "comprobantes", label: "Comprobantes (Colillas)", icon: FileText },
          { id: "reportes", label: "Reportes", icon: FileSpreadsheet },
          { id: "historial", label: "Historial de Auditoría", icon: History }
        ].map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              type="button"
              onClick={() => setActiveTab(tab.id as PayrollTab)}
              className={`flex shrink-0 items-center gap-2 border-b-2 px-4 py-3 transition-colors ${
                isActive
                  ? "border-brand-600 text-brand-600 dark:border-brand-400 dark:text-brand-400"
                  : "border-transparent text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200"
              }`}
            >
              <Icon className="h-4 w-4" />
              <span>{tab.label}</span>
              {tab.badge && (
                <span className="rounded-full bg-rose-500 px-1.5 py-0.2 text-[10px] text-white">
                  {tab.badge}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* =========================================================
          PESTAÑA 1: RESUMEN DE LA PLANILLA
          ========================================================= */}
      {activeTab === "resumen" && runDetails && (
        <div className="space-y-6">
          {/* 8 Tarjetas Principales del Resumen */}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {/* 1. Trabajadores */}
            <div
              onClick={() => setActiveTab("trabajadores")}
              className="cursor-pointer rounded-xl border border-slate-200 bg-white p-4 shadow-sm transition hover:shadow-md dark:border-white/10 dark:bg-slate-900"
            >
              <div className="flex items-center justify-between text-slate-400">
                <span className="text-xs font-bold uppercase tracking-wider">Colaboradores</span>
                <Users className="h-4 w-4 text-brand-600" />
              </div>
              <p className="mt-2 font-black text-2xl text-slate-800 dark:text-white">
                {runDetails.workersCount}
              </p>
              <p className="mt-1 text-[11px] text-slate-500">Personas con remuneración en el período</p>
            </div>

            {/* 2. Devengado Total */}
            <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <div className="flex items-center justify-between text-slate-400">
                <span className="text-xs font-bold uppercase tracking-wider">Devengado Total</span>
                <Wallet className="h-4 w-4 text-emerald-600" />
              </div>
              <p className="mt-2 font-black text-2xl text-emerald-700 dark:text-emerald-400">
                {calculationPending ? (
                  <span className="rounded bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">
                    {calculationLabel}
                  </span>
                ) : (
                  <Money value={runDetails.grossTotal} />
                )}
              </p>
              <p className="mt-1 text-[11px] text-slate-500">Salarios ordinarios + horas extra + bonos</p>
            </div>

            {/* 3. Deducciones Laborales */}
            <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <div className="flex items-center justify-between text-slate-400">
                <span className="text-xs font-bold uppercase tracking-wider">Deducciones de Ley</span>
                <ShieldAlert className="h-4 w-4 text-amber-600" />
              </div>
              <p className="mt-2 font-black text-2xl text-amber-700 dark:text-amber-400">
                {calculationPending ? (
                  <span className="rounded bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">
                    {calculationLabel}
                  </span>
                ) : (
                  <Money value={deductionsShown} />
                )}
              </p>
              <p className="mt-1 text-[11px] text-slate-500">
                INSS Lab: <Money value={runDetails.inssLaboralTotal} /> · IR: <Money value={runDetails.incomeTaxTotal} />
              </p>
              {headerInconsistent && (
                <p className="mt-1 text-[10px] font-semibold text-rose-600 dark:text-rose-400">
                  Cabecera histórica incoherente: se muestra la suma del detalle de la planilla.
                </p>
              )}
            </div>

            {/* 4. Neto por Pagar */}
            <div className="rounded-xl border border-brand-200 bg-brand-50/50 p-4 shadow-sm dark:border-brand-900/60 dark:bg-brand-950/20">
              <div className="flex items-center justify-between text-brand-600 dark:text-brand-400">
                <span className="text-xs font-bold uppercase tracking-wider">Neto por Pagar</span>
                <Banknote className="h-4 w-4" />
              </div>
              <p className="mt-2 font-black text-2xl text-brand-900 dark:text-brand-100">
                {calculationPending ? (
                  <span className="rounded bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">
                    {calculationLabel}
                  </span>
                ) : (
                  <Money value={runDetails.netTotal} />
                )}
              </p>
              <p className="mt-1 text-[11px] text-brand-700 dark:text-brand-300">
                Monto líquido a dispersar a trabajadores
              </p>
            </div>

            {/* 5. Aportes Patronales */}
            <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <div className="flex items-center justify-between text-slate-400">
                <span className="text-xs font-bold uppercase tracking-wider">Aportes Patronales</span>
                <Building2 className="h-4 w-4 text-indigo-600" />
              </div>
              <p className="mt-2 font-black text-2xl text-indigo-700 dark:text-indigo-400">
                <Money value={runDetails.inssPatronalTotal + runDetails.inatecTotal} />
              </p>
              <p className="mt-1 text-[11px] text-slate-500">
                INSS Patronal (21.5%): <Money value={runDetails.inssPatronalTotal} /> · INATEC (2%):{" "}
                <Money value={runDetails.inatecTotal} />
              </p>
            </div>

            {/* 6. Provisiones de Pasivo */}
            <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <div className="flex items-center justify-between text-slate-400">
                <span className="text-xs font-bold uppercase tracking-wider">Provisiones Ley 185</span>
                <Layers className="h-4 w-4 text-purple-600" />
              </div>
              <p className="mt-2 font-black text-2xl text-purple-700 dark:text-purple-400">
                <Money
                  value={
                    runDetails.aguinaldoProvTotal +
                    runDetails.vacacionesProvTotal +
                    runDetails.indemnizacionProvTotal
                  }
                />
              </p>
              <p className="mt-1 text-[11px] text-slate-500">
                Aguinaldo (8.33%) · Vacaciones (8.33%) · Antigüedad (8.33%)
              </p>
            </div>

            {/* 7. Pagos Confirmados */}
            <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <div className="flex items-center justify-between text-slate-400">
                <span className="text-xs font-bold uppercase tracking-wider">Pagos Confirmados</span>
                <CheckCircle2 className="h-4 w-4 text-teal-600" />
              </div>
              <p className="mt-2 font-black text-2xl text-teal-700 dark:text-teal-400">
                <Money value={runDetails.confirmedPaymentsTotal} />
              </p>
              <p className="mt-1 text-[11px] text-slate-500">Dispersados por tesorería / banco</p>
            </div>

            {/* 8. Diferencias Pendientes */}
            <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <div className="flex items-center justify-between text-slate-400">
                <span className="text-xs font-bold uppercase tracking-wider">Diferencias Pendientes</span>
                <AlertCircle className="h-4 w-4 text-rose-600" />
              </div>
              <p
                className={`mt-2 font-black text-2xl ${
                  runDetails.pendingDiscrepancyTotal > 0
                    ? "text-rose-600"
                    : "text-slate-800 dark:text-white"
                }`}
              >
                <Money value={runDetails.pendingDiscrepancyTotal} />
              </p>
              <p className="mt-1 text-[11px] text-slate-500">Pendiente de conciliar con bancos</p>
            </div>
          </div>

          {/* Desglose Pedagógico del Costo Total de la Empresa */}
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-soft dark:border-white/10 dark:bg-slate-900">
            <h3 className="font-extrabold text-base text-slate-900 dark:text-white flex items-center gap-2">
              <Building2 className="h-5 w-5 text-brand-600" />
              <span>Estructura del Costo Laboral Total de la Empresa</span>
            </h3>
            <p className="mt-1 text-xs text-slate-500">
              Conforme a las buenas prácticas financieras, diferenciamos claramente: (1) Las remuneraciones directas del
              trabajador, (2) Las cargas tributarias y de seguridad social patronal, y (3) Las provisiones técnicas
              para obligaciones futuras (Aguinaldo, Vacaciones e Indemnización Art. 45).
            </p>

            <div className="mt-6 grid gap-4 rounded-xl bg-slate-50 p-5 dark:bg-slate-800/60 lg:grid-cols-4">
              <div className="rounded-lg bg-white p-4 shadow-sm dark:bg-slate-800">
                <span className="text-[11px] font-bold text-slate-500 uppercase">1. Nómina Bruta (Devengado)</span>
                <p className="mt-2 font-black text-xl text-emerald-600">
                  <Money value={runDetails.grossTotal} />
                </p>
                <p className="mt-1 text-[11px] text-slate-400">
                  Base imponible para cotizaciones y cálculo de impuestos.
                </p>
              </div>

              <div className="rounded-lg bg-white p-4 shadow-sm dark:bg-slate-800">
                <span className="text-[11px] font-bold text-slate-500 uppercase">2. Aportes Patronales</span>
                <p className="mt-2 font-black text-xl text-indigo-600">
                  <Money value={runDetails.inssPatronalTotal + runDetails.inatecTotal} />
                </p>
                <p className="mt-1 text-[11px] text-slate-400">
                  INSS Patronal (21.5%) + Aporte INATEC (2.0%) asumidos por la empresa.
                </p>
              </div>

              <div className="rounded-lg bg-white p-4 shadow-sm dark:bg-slate-800">
                <span className="text-[11px] font-bold text-slate-500 uppercase">3. Provisiones Laborales</span>
                <p className="mt-2 font-black text-xl text-purple-600">
                  <Money
                    value={
                      runDetails.aguinaldoProvTotal +
                      runDetails.vacacionesProvTotal +
                      runDetails.indemnizacionProvTotal
                    }
                  />
                </p>
                <p className="mt-1 text-[11px] text-slate-400">
                  25.0% total acumulado: 1/12 Aguinaldo, 1/12 Vacaciones y 1/12 Art. 45.
                </p>
              </div>

              <div className="rounded-lg bg-brand-600 p-4 text-white shadow-sm dark:bg-brand-700">
                <span className="text-[11px] font-bold uppercase tracking-wider text-brand-100">
                  Costo Total Empresa
                </span>
                <p className="mt-2 font-black text-2xl">
                  <Money value={runDetails.employerCostTotal} />
                </p>
                <p className="mt-1 text-[11px] text-brand-100">
                  Impacto contable total reconocido en estado de resultados.
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          PESTAÑA 2: LISTA DE TRABAJADORES Y EXPEDIENTE DE CÁLCULO
          ========================================================= */}
      {activeTab === "trabajadores" && (
        <div className="space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="flex flex-wrap items-center gap-3">
              <div className="relative">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Buscar por colaborador, puesto o código..."
                  value={searchWorker}
                  onChange={(e) => setSearchWorker(e.target.value)}
                  className="h-9 w-64 rounded-lg border border-slate-200 pl-9 pr-3 text-xs outline-none dark:border-white/10 dark:bg-slate-950"
                />
              </div>

              <select
                value={filterArea}
                onChange={(e) => setFilterArea(e.target.value)}
                className="h-9 rounded-lg border border-slate-200 px-3 text-xs font-semibold dark:border-white/10 dark:bg-slate-950"
              >
                <option value="todas">Todas las áreas</option>
                {uniqueAreas.map((area) => (
                  <option key={area} value={area}>
                    {area}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex items-center gap-3">
              <div className="text-xs text-slate-500">
                Mostrando <strong>{filteredItems.length}</strong> de <strong>{items.length}</strong> colaboradores
              </div>
              {runDetails?.status === "borrador" && (
                <Button
                  type="button"
                  variant="primary"
                  onClick={() => {
                    setModalError(null);
                    setShowAddWorkerModal(true);
                  }}
                  className="flex items-center gap-1.5 text-xs bg-brand-600 hover:bg-brand-700"
                >
                  <UserPlus className="h-4 w-4" />
                  <span>Agregar Trabajador</span>
                </Button>
              )}
            </div>
          </div>

          {items.length === 0 ? (
            <div className="rounded-xl border border-dashed border-slate-300 p-8 text-center dark:border-white/10 bg-white dark:bg-slate-900">
              <Users className="mx-auto h-10 w-10 text-slate-400" />
              <h4 className="mt-3 font-bold text-sm text-slate-800 dark:text-white">Planilla sin trabajadores asignados</h4>
              <p className="mt-1 text-xs text-slate-500 max-w-md mx-auto">
                Esta planilla se encuentra en borrador y vacía. Selecciona "Agregar Trabajador" para incluir participantes elegibles registrados en Talento Humano.
              </p>
              {runDetails?.status === "borrador" && (
                <Button
                  type="button"
                  variant="primary"
                  onClick={() => {
                    setModalError(null);
                    setShowAddWorkerModal(true);
                  }}
                  className="mt-4 inline-flex items-center gap-1.5 text-xs"
                >
                  <UserPlus className="h-4 w-4" />
                  <span>Agregar Trabajador</span>
                </Button>
              )}
            </div>
          ) : (
            <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white shadow-soft dark:border-white/10 dark:bg-slate-900">
              <table className="w-full text-left text-xs">
                <thead className="border-b bg-slate-50 text-[11px] font-bold uppercase text-slate-500 dark:bg-slate-800">
                  <tr>
                    <th className="p-3">Colaborador</th>
                    <th className="p-3">Área / Puesto</th>
                    <th className="p-3 text-right">Tiempo</th>
                    <th className="p-3 text-right">Devengado</th>
                    <th className="p-3 text-right">Deducciones</th>
                    <th className="p-3 text-right">Neto a Pagar</th>
                    <th className="p-3 text-center">Estado</th>
                    <th className="p-3 text-right">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-white/5">
                  {filteredItems.map((item) => (
                    <tr key={item.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50">
                      <td className="p-3">
                        <p className="font-bold text-slate-800 dark:text-white">{item.employeeName}</p>
                        <span className="font-mono text-[10px] text-slate-400">{item.employeeId}</span>
                      </td>
                      <td className="p-3">
                        <p className="font-semibold text-slate-700 dark:text-slate-200">{item.position}</p>
                        <span className="text-[10px] text-slate-400">{item.area}</span>
                      </td>
                      <td className="p-3 text-right font-medium text-slate-600 dark:text-slate-300">
                        {item.daysWorked} días ({item.hoursWorked} h)
                      </td>
                      <td className="p-3 text-right font-bold text-emerald-600">
                        {calculationPending ? (
                          <span className="rounded bg-slate-100 px-2 py-0.5 font-normal text-[10px] text-slate-500 dark:bg-slate-800">
                            {calculationShort}
                          </span>
                        ) : (
                          <Money value={item.grossIncome} />
                        )}
                      </td>
                      <td className="p-3 text-right font-semibold text-amber-600">
                        {calculationPending ? (
                          <span className="rounded bg-slate-100 px-2 py-0.5 font-normal text-[10px] text-slate-500 dark:bg-slate-800">
                            {calculationShort}
                          </span>
                        ) : (
                          <Money value={item.totalDeductions} />
                        )}
                      </td>
                      <td className="p-3 text-right font-black text-brand-600 dark:text-brand-400">
                        {calculationPending ? (
                          <span className="rounded bg-slate-100 px-2 py-0.5 font-normal text-[10px] text-slate-500 dark:bg-slate-800">
                            {calculationShort}
                          </span>
                        ) : (
                          <Money value={item.netPay} />
                        )}
                      </td>
                      <td className="p-3 text-center">
                        <StatusPill tone={item.paymentStatus === "pagado" ? "ok" : "warn"}>
                          {item.paymentStatus}
                        </StatusPill>
                      </td>
                      <td className="p-3 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          {(runDetails?.status === "borrador" || runDetails?.status === "calculada") && (
                            <button
                              type="button"
                              onClick={() => {
                                setNewNovelty((prev) => ({
                                  ...prev,
                                  employeeId: item.employeeId,
                                  concept: `Novedad / Ajuste - ${item.employeeName}`
                                }));
                                setShowNoveltyModal(true);
                              }}
                              className="rounded-lg bg-indigo-50 px-2 py-1 text-xs font-semibold text-indigo-700 hover:bg-indigo-100 dark:bg-indigo-950/60 dark:text-indigo-300"
                              title="Registrar horas extra o novedad a este colaborador"
                            >
                              + Novedad
                            </button>
                          )}
                          {runDetails?.status === "borrador" && (
                            <button
                              type="button"
                              onClick={() => void handleRemoveWorker(item)}
                              className="rounded-lg bg-rose-50 px-2 py-1 text-xs font-semibold text-rose-700 hover:bg-rose-100 dark:bg-rose-950/60 dark:text-rose-300"
                              title="Retirar colaborador de esta planilla borrador"
                            >
                              Retirar
                            </button>
                          )}
                          {(runDetails?.status === "aprobada" || runDetails?.status === "pago_registrado") && pendingForEmployee(Number(item.netPay ?? 0), payments, item.employeeId) > 0 && (
                            <button
                              type="button"
                              onClick={() => {
                                const pendingWorker = pendingForEmployee(Number(item.netPay ?? 0), payments, item.employeeId);
                                setModalError(null);
                                setPaymentDraft({
                                  amount: String(pendingWorker > 0 ? pendingWorker : Number(item.netPay ?? 0)),
                                  paymentMethod: "transferencia_bancaria",
                                  paymentReference: "",
                                  paymentDate: new Date().toISOString().slice(0, 10),
                                  notes: "",
                                  employeeId: item.employeeId
                                });
                                setShowPaymentModal(true);
                              }}
                              className="rounded-lg bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-950/60 dark:text-emerald-300"
                              title="Registrar un abono del importe elegido para este colaborador"
                            >
                              Registrar abono
                            </button>
                          )}
                          <button
                            type="button"
                            onClick={() => setShowItemDetailModal(item)}
                            className="rounded-lg bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
                          >
                            Expediente
                          </button>
                          <button
                            type="button"
                            onClick={() => setShowExplainModal(item)}
                            className="rounded-lg bg-brand-50 px-2 py-1 text-xs font-semibold text-brand-700 hover:bg-brand-100 dark:bg-brand-950/60 dark:text-brand-300"
                            title="Explicar cálculo pedagógico"
                          >
                            Explicar
                          </button>
                          <button
                            type="button"
                            onClick={() => void handleViewReceipt(item.employeeId)}
                            className="rounded-lg bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-950/60 dark:text-emerald-300"
                            title="Ver Colilla Oficial"
                          >
                            Colilla
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                  {filteredItems.length === 0 && (
                    <tr>
                      <td colSpan={8} className="p-8 text-center text-slate-400">
                        No se encontraron colaboradores que coincidan con la búsqueda.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* =========================================================
          PESTAÑA 3: NOVEDADES DEL PERÍODO
          ========================================================= */}
      {activeTab === "novedades" && (
        <div className="space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div>
              <h3 className="font-bold text-sm">Registro de Novedades del Período</h3>
              <p className="text-xs text-slate-500">
                Horas extraordinarias, bonos por productividad, vacaciones disfrutadas, préstamos y ajustes autorizados.
              </p>
            </div>
            {runDetails && (runDetails.status === "borrador" || runDetails.status === "calculada") && (
              <Button
                type="button"
                variant="primary"
                disabled={items.length === 0}
                onClick={() => {
                  setModalError(null);
                  if (items.length > 0 && !newNovelty.employeeId) {
                    setNewNovelty(prev => ({ ...prev, employeeId: items[0].employeeId }));
                  }
                  setShowNoveltyModal(true);
                }}
                className="flex items-center gap-1.5 text-xs bg-brand-600 hover:bg-brand-700"
                title={items.length === 0 ? "Primero debes agregar trabajadores a la planilla" : undefined}
              >
                <Plus className="h-4 w-4" />
                <span>Registrar Novedad</span>
              </Button>
            )}
          </div>

          <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white shadow-soft dark:border-white/10 dark:bg-slate-900">
            <table className="w-full text-left text-xs">
              <thead className="border-b bg-slate-50 text-[11px] font-bold uppercase text-slate-500 dark:bg-slate-800">
                <tr>
                  <th className="p-3">Colaborador</th>
                  <th className="p-3">Tipo</th>
                  <th className="p-3">Concepto</th>
                  <th className="p-3">Horas</th>
                  <th className="p-3 text-right">Monto</th>
                  <th className="p-3">Soporte Legal / Documento</th>
                  <th className="p-3">Fecha</th>
                  <th className="p-3 text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-white/5">
                {novelties.map((nov) => (
                  <tr key={nov.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50">
                    <td className="p-3 font-bold text-slate-800 dark:text-white">
                      {nov.employeeName || nov.employeeId}
                    </td>
                    <td className="p-3">
                      <span className="rounded bg-slate-100 px-2 py-0.5 font-semibold text-[10px] text-slate-700 capitalize dark:bg-slate-800 dark:text-slate-200">
                        {nov.noveltyType.replace("_", " ")}
                      </span>
                    </td>
                    <td className="p-3 font-medium text-slate-700 dark:text-slate-200">{nov.concept}</td>
                    <td className="p-3 font-semibold">{nov.hours ? `${nov.hours} h` : "-"}</td>
                    <td className="p-3 text-right font-black text-emerald-600">
                      <Money value={nov.amount} />
                    </td>
                    <td className="p-3 text-slate-500">
                      {nov.legalJustification && (
                        <p className="text-[11px] font-medium text-slate-700 dark:text-slate-300">
                          {nov.legalJustification}
                        </p>
                      )}
                      {nov.docReference && (
                        <span className="font-mono text-[10px] text-slate-400">Doc: {nov.docReference}</span>
                      )}
                    </td>
                    <td className="p-3 text-slate-400">{nov.periodDate}</td>
                    <td className="p-3 text-right">
                      {(runDetails?.status === "borrador" || runDetails?.status === "calculada") && (
                        <button
                          type="button"
                          onClick={() => void handleDeleteNovelty(nov)}
                          className="inline-flex items-center gap-1 rounded bg-rose-50 px-2 py-1 text-[11px] font-semibold text-rose-700 hover:bg-rose-100 dark:bg-rose-950/60 dark:text-rose-300"
                          title="Eliminar novedad"
                        >
                          <Trash2 className="h-3 w-3" />
                          <span>Eliminar</span>
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
                {novelties.length === 0 && (
                  <tr>
                    <td colSpan={8} className="p-8 text-center text-slate-400">
                      No se han registrado novedades para este período de nómina.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* =========================================================
          PESTAÑA 4: VALIDACIONES NORMATIVAS Y ALERTAS
          ========================================================= */}
      {activeTab === "validaciones" && (
        <div className="space-y-4">
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-soft dark:border-white/10 dark:bg-slate-900">
            <h3 className="font-extrabold text-base text-slate-900 dark:text-white flex items-center gap-2">
              <ShieldAlert className="h-5 w-5 text-amber-500" />
              <span>Validaciones de Integridad y Reglas Laborales</span>
            </h3>
            <p className="mt-1 text-xs text-slate-500">
              El motor de nómina audita cada aspecto legal (topes de horas extraordinarias de la Ley 185, retenciones
              impositivas de la Ley 822 y cotizaciones del INSS) para garantizar cero discrepancias antes de la
              aprobación definitiva.
            </p>

            <div className="mt-5 space-y-3">
              {validations.map((val) => (
                <div
                  key={val.id}
                  className={`flex items-start justify-between gap-3 rounded-xl border p-4 text-xs ${
                    val.severity === "bloqueante"
                      ? "border-rose-300 bg-rose-50 text-rose-950 dark:border-rose-800/60 dark:bg-rose-950/30 dark:text-rose-200"
                      : val.severity === "advertencia"
                      ? "border-amber-300 bg-amber-50 text-amber-950 dark:border-amber-800/60 dark:bg-amber-950/30 dark:text-amber-200"
                      : "border-brand-200 bg-brand-50 text-brand-950 dark:border-brand-800/60 dark:bg-brand-950/30 dark:text-brand-200"
                  }`}
                >
                  <div className="flex items-start gap-3">
                    {val.severity === "bloqueante" ? (
                      <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-rose-600" />
                    ) : (
                      <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" />
                    )}
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold uppercase tracking-wider text-[10px]">
                          {val.severity}
                        </span>
                        <span className="font-mono text-[10px] text-slate-500">Regla: {val.ruleCode}</span>
                      </div>
                      <p className="mt-1 font-semibold">{val.message}</p>
                    </div>
                  </div>

                  {val.targetTab && (
                    <Button
                      type="button"
                      variant="secondary"
                      onClick={() => setActiveTab(val.targetTab as PayrollTab)}
                      className="shrink-0 text-xs"
                    >
                      Ir a resolver
                    </Button>
                  )}
                </div>
              ))}

              {validations.length === 0 && (
                calculationPending ? (
                  <div className="flex flex-wrap items-center justify-between gap-4 rounded-xl border border-amber-200 bg-amber-50/70 p-6 text-xs text-amber-900 dark:border-amber-900/40 dark:bg-amber-950/30 dark:text-amber-200">
                    <div className="flex items-start gap-3">
                      <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" />
                      <div>
                        <p className="font-bold text-sm">Validaciones Pendientes de Ejecución</p>
                        <p className="mt-1 text-slate-600 dark:text-slate-300">
                          La planilla se encuentra en borrador. No se han ejecutado aún las validaciones normativas (topes de horas extraordinarias de la Ley 185, retención IR de la Ley 822 y aportes INSS). Ejecuta el cálculo para auditar las reglas laborales del período.
                        </p>
                      </div>
                    </div>
                    {runDetails?.status === "borrador" && (
                      <Button
                        type="button"
                        variant="primary"
                        disabled={busy}
                        onClick={handleCalculate}
                        className="shrink-0 text-xs bg-emerald-600 hover:bg-emerald-700"
                      >
                        <RefreshCw className={`h-3.5 w-3.5 ${busy ? "animate-spin" : ""}`} />
                        <span>Calcular y Auditar</span>
                      </Button>
                    )}
                  </div>
                ) : (
                  <div className="flex items-center gap-3 rounded-xl border border-emerald-200 bg-emerald-50 p-6 text-xs text-emerald-900 dark:border-emerald-900/40 dark:bg-emerald-950/30 dark:text-emerald-200">
                    <CheckCircle2 className="h-5 w-5 shrink-0 text-emerald-600" />
                    <div>
                      <p className="font-bold text-sm">Validación Completada (v{runDetails?.calculationVersion})</p>
                      <p className="mt-1 text-emerald-800 dark:text-emerald-300">
                        El cálculo cargado no presenta observaciones registradas. Revisa las reglas aplicables y la conciliación antes de aprobar o pagar.
                      </p>
                    </div>
                  </div>
                )
              )}
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          PESTAÑA 5: APROBACIONES Y TRAZABILIDAD
          ========================================================= */}
      {activeTab === "aprobaciones" && runDetails && (
        <div className="space-y-6">
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-soft dark:border-white/10 dark:bg-slate-900">
            <h3 className="font-extrabold text-base text-slate-900 dark:text-white flex items-center gap-2">
              <FileCheck className="h-5 w-5 text-brand-600" />
              <span>Flujo de Aprobación Formal de 7 Etapas</span>
            </h3>
            <p className="mt-1 text-xs text-slate-500">
              Para garantizar el control interno y la separación de funciones, cada transición es validada en el
              servidor con firmas de auditoría no repudiables.
            </p>

            {/* Línea de tiempo de 7 Estados */}
            <div className="mt-8 grid gap-2 sm:grid-cols-7 text-center text-xs">
              {(
                [
                  "borrador",
                  "calculada",
                  "revisada",
                  "aprobada",
                  "pago_registrado",
                  "conciliada",
                  "cerrada"
                ] as PayrollStatus[]
              ).map((st, idx) => {
                const statusOrder = [
                  "borrador",
                  "calculada",
                  "revisada",
                  "aprobada",
                  "pago_registrado",
                  "conciliada",
                  "cerrada"
                ];
                const currentIdx = statusOrder.indexOf(runDetails.status);
                const isPassed = idx <= currentIdx;
                const isCurrent = idx === currentIdx;

                return (
                  <div
                    key={st}
                    className={`rounded-xl border p-3 ${
                      isCurrent
                        ? "border-brand-500 bg-brand-50/60 font-black text-brand-700 shadow-sm dark:bg-brand-950/40 dark:text-brand-300"
                        : isPassed
                        ? "border-emerald-200 bg-emerald-50/40 text-emerald-800 dark:border-emerald-900/40 dark:bg-emerald-950/20 dark:text-emerald-300"
                        : "border-slate-100 bg-slate-50/40 text-slate-400 dark:border-white/5 dark:bg-slate-800/20"
                    }`}
                  >
                    <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Paso {idx + 1}</div>
                    <div className="mt-1 font-bold capitalize">{st.replace("_", " ")}</div>
                    <div className="mt-2 flex justify-center">
                      {isPassed ? (
                        <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                      ) : (
                        <div className="h-4 w-4 rounded-full border border-slate-300 dark:border-slate-700" />
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Aviso de Segregación de Funciones */}
            <div className="mt-6 rounded-xl border border-blue-200 bg-blue-50/60 p-4 text-xs text-blue-900 dark:border-blue-900/40 dark:bg-blue-950/30 dark:text-blue-200 flex items-start gap-3">
              <Shield className="mt-0.5 h-5 w-5 shrink-0 text-blue-600 dark:text-blue-400" />
              <div>
                <p className="font-bold text-sm">Política de Segregación de Funciones</p>
                <p className="mt-0.5">
                  El colaborador que preparó o configuró la nómina (
                  <strong>{runDetails.preparedByName || "Preparador"}</strong>) no puede auto-aprobarla. La
                  aprobación debe ser emitida por una persona con rango administrativo superior (Gerencia General o
                  Superadministrador) para evitar conflictos de interés.
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          PESTAÑA 6: PAGOS Y CAJA / BANCOS
          ========================================================= */}
      {activeTab === "pagos" && runDetails && (
        <div className="space-y-4">
          {confirmedPaymentNotice?.runId === selectedRunId && (
            <div role="status" className="rounded-xl border border-emerald-300 bg-emerald-50 p-3 text-xs text-emerald-900 dark:border-emerald-800 dark:bg-emerald-950/30 dark:text-emerald-200">
              <strong>Pago confirmado:</strong> {confirmedPaymentNotice.id}. Si falla la recarga del historial, conserva esta referencia y actualiza la consulta; no registres el mismo pago como una operación nueva.
            </div>
          )}

          <div className="grid items-start gap-4 xl:grid-cols-2">
            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <div className="flex flex-wrap items-center justify-between gap-2"><div><p className="text-[10px] font-bold uppercase tracking-widest text-brand-600">Trabajadores</p><h3 className="text-lg font-extrabold">Personal de esta planilla</h3></div>
                <Link to="/rrhh" className="text-xs font-semibold text-brand-600">Alta de personal / expedientes →</Link>
              </div>
              <p className="mt-2 text-xs text-slate-500">Cada persona tiene su salario y su neto. Selecciona una para preparar un pago individual.</p>
              <PayrollStaffRegistration allowed={user?.hierarchy === "superadmin" || (user?.hierarchy === "administrador" && Boolean(user.areas?.includes("rrhh")))} onCreated={employee => {
                setEmployeesDirectory(current => [...current.filter(item => item.id !== employee.id), employee]);
                setAddWorkerDraft({ employeeId: employee.id, reason: "" });
                if (runDetails.status === "borrador") setShowAddWorkerModal(true);
              }} />
              <input aria-label="Buscar trabajador para pagar" value={paymentWorkerSearch} onChange={event => setPaymentWorkerSearch(event.target.value)} className={inputClass + " mt-3"} placeholder="Buscar nombre o cargo…" />
              <div className="mt-3 max-h-[520px] overflow-y-auto divide-y divide-slate-100 dark:divide-white/10">
                {items.filter(item => (item.employeeName + " " + item.position).toLocaleLowerCase().includes(paymentWorkerSearch.toLocaleLowerCase())).map(item => <button key={item.id} type="button" disabled={busy}
                  aria-pressed={paymentDraft.employeeId === item.employeeId}
                  onClick={() => { setModalError(null); setPaymentDraft(prev => ({ ...prev, employeeId: item.employeeId, amount: "" })); individualPaymentRef.current?.scrollIntoView({ behavior: "smooth", block: "start" }); }}
                  className={`flex w-full items-center justify-between gap-3 p-3 text-left text-xs hover:bg-sky-50 dark:hover:bg-sky-950/30 ${paymentDraft.employeeId === item.employeeId ? "bg-sky-50 dark:bg-sky-950/30" : ""}`}>
                  <span><strong className="block">{item.employeeName}</strong><span className="text-slate-500">{item.position} · {item.area}</span></span>
                  <span className="text-right"><span className="block text-[10px] text-slate-500">Salario mensual de referencia</span><strong><Money value={item.baseSalaryMonthly} /></strong></span>
                </button>)}
                {items.length === 0 && <p className="p-4 text-xs text-slate-500">No hay trabajadores cargados en esta planilla.</p>}
              </div>
              <Button type="button" variant="secondary" className="mt-3" disabled={busy || runDetails.status !== "borrador"} onClick={() => setShowAddWorkerModal(true)}>Agregar trabajador a la planilla</Button>
            </section>
            <section ref={individualPaymentRef} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <p className="text-[10px] font-bold uppercase tracking-widest text-brand-600">Pago individual</p><h3 className="text-lg font-extrabold">Registrar pago a trabajador</h3>
              {paymentBlockReason && <p role="status" className="mt-3 rounded-lg bg-amber-50 p-3 text-xs text-amber-900 dark:bg-amber-950/30 dark:text-amber-200">{paymentBlockReason}</p>}
              {modalError && <p role="alert" className="mt-3 text-xs text-rose-700 dark:text-rose-300">{modalError}</p>}
              {renderIndividualPaymentForm()}
            </section>
          </div>
          {paymentGuide && (
            <section aria-label="Guía para pagar a un trabajador" className="rounded-xl border border-sky-200 bg-sky-50/60 p-4 dark:border-sky-900 dark:bg-sky-950/20">
              <h3 className="font-extrabold">Guía para pagar a un trabajador</h3>
              <ol className="my-3 grid gap-2 text-xs sm:grid-cols-4">
                {payrollPaymentSteps.map((step, index) => (
                  <li key={step} aria-current={index === paymentGuide.step ? "step" : undefined}
                    className={`rounded-lg border p-2 ${index === paymentGuide.step ? "border-sky-500 bg-sky-100 font-bold dark:bg-sky-900/40" : "border-slate-200 dark:border-white/10"}`}>
                    {index + 1}. {step}
                  </li>
                ))}
              </ol>
              <p className="text-xs text-slate-600 dark:text-slate-300">{paymentGuide.message}</p>
              <Button type="button" className="mt-3" disabled={busy || loading} onClick={followPaymentGuide}>
                {busy ? "Procesando…" : paymentGuide.label}
              </Button>
              <p className="mt-2 text-[11px] text-slate-500">Los abonos se registran uno por trabajador. Registrar una transferencia aquí no envía fondos al banco. La revisión y aprobación requieren responsables autorizados.</p>
            </section>
          )}
          <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div>
              <h3 className="font-bold text-sm">Pagos y abonos por trabajador</h3>
              <p className="text-xs text-slate-500">
                Cada persona conserva su neto aprobado. Registra un abono o completa su pendiente, según el importe que corresponda.
              </p>
            </div>
            {calculationPending && (
              <div className="flex items-start gap-2 rounded-lg border border-amber-200 bg-amber-50 p-3 text-[11px] text-amber-900 dark:border-amber-900/40 dark:bg-amber-950/30 dark:text-amber-200">
                <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                <span>
                  {calculationLabel}: no hay un neto aprobado que dispersar. Ejecuta el cálculo y completa el flujo
                  Borrador → Calculada → Revisada → Aprobada antes de registrar pagos.
                </span>
              </div>
            )}
            {!calculationPending && (runDetails.status === "aprobada" || runDetails.status === "pago_registrado") && (
              <p className="max-w-xl text-[11px] text-slate-500">
                Selecciona una persona y escribe cuánto le pagarás ahora. Puedes hacer varios abonos sin pagar al resto de la planilla. El pendiente se reduce únicamente con pagos confirmados.
              </p>
            )}
            <Button
                type="button"
                variant="primary"
                disabled={busy || Boolean(paymentBlockReason) || pendingPayment <= 0}
                title={paymentBlockReason ?? "Elegir trabajador e ingresar el importe del abono"}
                onClick={() => {
                  setModalError(null);
                  setPaymentDraft({
                    amount: "",
                    paymentMethod: "transferencia_bancaria",
                    paymentReference: "",
                    paymentDate: new Date().toISOString().slice(0, 10),
                    notes: "",
                    employeeId: items.find((item) => item.employeeId === requestedEmployeeId)?.employeeId ?? ""
                  });
                  setShowPaymentModal(true);
                }}
                className="flex items-center gap-1.5 text-xs bg-emerald-600 hover:bg-emerald-700"
              >
                <Banknote className="h-4 w-4" />
                <span>{pendingPayment <= 0 ? "Planilla pagada por completo" : "Registrar abono a trabajador"}</span>
              </Button>
          </div>

          {paymentBlockReason && (
            <div role="status" className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-xs text-amber-900 dark:border-amber-800 dark:bg-amber-950/30 dark:text-amber-200">
              <strong>Pago bloqueado: </strong>{paymentBlockReason}
              <Button type="button" variant="secondary" className="ml-3" onClick={() => {
                const eligible = runs.find((run) => ["aprobada", "pago_registrado"].includes(run.status) && Number(run.pendingPayment ?? (run.netTotal - run.confirmedPaymentsTotal)) > 0);
                if (eligible) setSelectedRunId(eligible.id);
                else setFeedback({ type: "info", message: "No hay una planilla aprobada con saldo pendiente. Selecciona una planilla calculada y completa revisión y aprobación antes de pagar." });
              }}>Buscar planilla habilitada para pagar</Button>
            </div>
          )}
          {(headerInconsistent || runDetails.paymentTotalsConsistent === false || runDetails.paymentTotalsConsistent === 0) && (
            <div ref={differencesPanelRef} role="alert" className="rounded-xl border border-rose-200 bg-rose-50 p-4 text-xs text-rose-900 dark:border-rose-900 dark:bg-rose-950/30 dark:text-rose-200">
              <h3 className="font-extrabold">Diferencias que requieren revisión</h3>
              {headerInconsistent && <p className="mt-2">Deducciones en cabecera: <Money value={runDetails.totalDeductions} />. Suma de los detalles: <Money value={Number(runDetails.deductionsFromItems ?? 0)} />. No se igualan automáticamente importes históricos.</p>}
              {(runDetails.paymentTotalsConsistent === false || runDetails.paymentTotalsConsistent === 0) && <p className="mt-2">Acumulado histórico: <Money value={Number(runDetails.recordedPaymentsTotal ?? 0)} />. Recibos confirmados: <Money value={runDetails.confirmedPaymentsTotal} />. Revisa los comprobantes; la diferencia no demuestra por sí sola si el dinero se entregó.</p>}
              <p className="mt-2">Este bloqueo es independiente de la lista de validaciones del cálculo. No se deben registrar pagos nuevos para compensarlo sin revisar su origen.</p>
            </div>
          )}
          <div className="grid gap-4 sm:grid-cols-3">
            <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <span className="text-xs font-bold uppercase text-slate-400">Total a Dispersar</span>
              <p className="mt-2 font-black text-2xl text-slate-800 dark:text-white">
                <Money value={runDetails.netTotal} />
              </p>
            </div>
            <div className="rounded-xl border border-emerald-200 bg-emerald-50/50 p-4 shadow-sm dark:border-emerald-900/60 dark:bg-emerald-950/20">
              <span className="text-xs font-bold uppercase text-emerald-700 dark:text-emerald-400">
                Pagos Confirmados
              </span>
              <p className="mt-2 font-black text-2xl text-emerald-700 dark:text-emerald-300">
                <Money value={runDetails.confirmedPaymentsTotal} />
              </p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <span className="text-xs font-bold uppercase text-slate-400">Pendiente de Dispersión</span>
              <p className="mt-2 font-black text-2xl text-amber-600">
                {calculationPending ? <span className="text-xs font-semibold">{calculationLabel}</span> : <Money value={pendingPayment} />}
              </p>
              <p className="mt-1 text-[10px] text-slate-500">Neto aprobado − pagos confirmados</p>
            </div>
          </div>

          <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white shadow-soft dark:border-white/10 dark:bg-slate-900">
            <table className="w-full text-left text-xs">
              <thead className="border-b bg-slate-50 text-[11px] font-bold uppercase text-slate-500 dark:bg-slate-800">
                <tr>
                  <th className="p-3">Colaborador</th>
                  <th className="p-3">Método de Pago</th>
                  <th className="p-3">Referencia / Banco</th>
                  <th className="p-3 text-right">Neto aprobado</th>
                  <th className="p-3 text-right">Abonos confirmados</th>
                  <th className="p-3 text-right">Pendiente</th>
                  <th className="p-3 text-center">Estado de Pago</th>
                  <th className="p-3 text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-white/5">
                {items.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50">
                    <td className="p-3 font-bold text-slate-800 dark:text-white">{item.employeeName}</td>
                    <td className="p-3 capitalize text-slate-600 dark:text-slate-300">
                      {item.paymentMethod.replace("_", " ")}
                    </td>
                    <td className="p-3 font-mono text-slate-500">
                      {item.paymentReference || "Sin referencia de pago"}
                    </td>
                    <td className="p-3 text-right font-black text-brand-600 dark:text-brand-400">
                      <Money value={item.netPay} />
                    </td>
                    <td className="p-3 text-right text-emerald-700">{paymentsReady ? <Money value={paidToEmployee(payments, item.employeeId)} /> : "Sin confirmar"}</td>
                    <td className="p-3 text-right font-semibold text-amber-600">
                      {paymentsReady ? <Money value={pendingForEmployee(Number(item.netPay ?? 0), payments, item.employeeId)} /> : "Sin confirmar"}
                    </td>
                    <td className="p-3 text-center">
                      <StatusPill tone={paymentsReady && pendingForEmployee(Number(item.netPay ?? 0), payments, item.employeeId) <= 0 ? "ok" : "warn"}>
                        {!paymentsReady ? "Sin confirmar" : pendingForEmployee(Number(item.netPay ?? 0), payments, item.employeeId) <= 0 ? "Pagado" : paidToEmployee(payments, item.employeeId) > 0 ? "Pago parcial" : "Pendiente"}
                      </StatusPill>
                    </td>
                    <td className="p-3 text-right">
                      <button
                          type="button"
                          disabled={busy || Boolean(paymentBlockReason) || pendingForEmployee(Number(item.netPay ?? 0), payments, item.employeeId) <= 0}
                          title={paymentBlockReason ?? "Registrar un pago o abono a este trabajador"}
                          onClick={() => {
                            const pendingWorker = pendingForEmployee(Number(item.netPay ?? 0), payments, item.employeeId);
                            setModalError(null);
                            setPaymentDraft({
                              amount: "",
                              paymentMethod: "transferencia_bancaria",
                              paymentReference: "",
                              paymentDate: new Date().toISOString().slice(0, 10),
                              notes: "",
                              employeeId: item.employeeId
                            });
                            setShowPaymentModal(true);
                          }}
                          className="inline-flex items-center gap-1 rounded-lg disabled:cursor-not-allowed disabled:opacity-50 bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-950/60 dark:text-emerald-300"
                        >
                          <Banknote className="h-3.5 w-3.5" /> Registrar abono
                        </button>
                      {paymentBlockReason && <span className="mt-1 block text-[10px] text-amber-700 dark:text-amber-300">{["conciliada", "cerrada"].includes(runDetails.status) ? `Planilla ${STATUS_LABELS[runDetails.status].label.toLowerCase()}` : "Ver motivo del bloqueo arriba"}</span>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <PayrollPaymentHistory payments={payments} items={items} period={runDetails.period} ready={paymentsReady} />

        </div>
      )}

      {/* =========================================================
          PESTAÑA 7: OBLIGACIONES INSTITUCIONALES (DGI, INSS, INATEC)
          ========================================================= */}
      {activeTab === "obligaciones" && (
        <div className="space-y-4">
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-soft dark:border-white/10 dark:bg-slate-900">
            <h3 className="font-extrabold text-base text-slate-900 dark:text-white flex items-center gap-2">
              <Building2 className="h-5 w-5 text-indigo-600" />
              <span>Obligaciones Tributarias y de Seguridad Social</span>
            </h3>
            <p className="mt-1 text-xs text-slate-500">
              Seguimiento formal de retenciones fiscales ante la DGI (Ley 822), cotizaciones obligatorias del INSS y
              aporte técnico a INATEC conforme al calendario tributario de Nicaragua.
            </p>

            <div className="mt-6 overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="border-b bg-slate-50 text-[11px] font-bold uppercase text-slate-500 dark:bg-slate-800">
                  <tr>
                    <th className="p-3">Institución</th>
                    <th className="p-3">Período</th>
                    <th className="p-3 text-right">Base Imponible</th>
                    <th className="p-3 text-right">Monto a Pagar</th>
                    <th className="p-3">Fecha Límite</th>
                    <th className="p-3 text-center">Estado</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-white/5">
                  {obligations.map((obl) => (
                    <tr key={obl.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50">
                      <td className="p-3">
                        <strong className="text-slate-800 dark:text-white">{obl.entity}</strong>
                      </td>
                      <td className="p-3 text-slate-500">{obl.period}</td>
                      <td className="p-3 text-right font-medium text-slate-600 dark:text-slate-300">
                        <Money value={obl.baseAmount} />
                      </td>
                      <td className="p-3 text-right font-black text-indigo-600">
                        <Money value={obl.payableAmount} />
                      </td>
                      <td className="p-3 font-semibold text-slate-700 dark:text-slate-300">
                        <span>{obl.dueDate ? String(obl.dueDate).slice(0, 10) : "Pendiente de definir"}</span>
                        {obl.status !== "pagada" && obl.revision && (user?.hierarchy === "superadmin" || (user?.hierarchy === "administrador" && user.areas?.some((area) => ["finanzas", "contabilidad"].includes(area)))) && (
                          <form className="mt-2 flex max-w-xs flex-col gap-2" onSubmit={(event) => void handleObligationDate(event, obl)}>
                            <input name="dueDate" type="date" aria-label="Vencimiento verificado" required defaultValue={obl.dueDate?.slice(0, 10) ?? ""} className={inputClass} />
                            <input name="source" aria-label="Fuente del vencimiento" placeholder="Documento o calendario verificado" required minLength={5} maxLength={300} className={inputClass} />
                            <Button type="submit" variant="secondary" disabled={busy}>Guardar vencimiento</Button>
                          </form>
                        )}
                      </td>
                      <td className="p-3 text-center">
                        <StatusPill tone={obl.status === "pagada" ? "ok" : "warn"}>{obl.status}</StatusPill>
                      </td>
                    </tr>
                  ))}
                  {obligations.length === 0 && (
                    <tr>
                      <td colSpan={6} className="p-8 text-center text-slate-400">
                        Las obligaciones institucionales se generarán formalmente al aprobar la nómina.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          PESTAÑA 8: COMPROBANTES DE PAGO (COLILLAS)
          ========================================================= */}
      {activeTab === "comprobantes" && (
        <div className="space-y-4">
          <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div>
              <h3 className="font-bold text-sm">Comprobantes Oficiales de Pago (Colillas de Nómina)</h3>
              <p className="text-xs text-slate-500">
                Generación y consulta de colillas individuales con detalle de percepciones, retenciones de ley y neto
                recibido.
              </p>
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {items.map((item) => (
              <div
                key={item.id}
                className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm transition hover:shadow-md dark:border-white/10 dark:bg-slate-900"
              >
                <div className="flex items-start justify-between">
                  <div>
                    <h4 className="font-bold text-sm text-slate-800 dark:text-white">{item.employeeName}</h4>
                    <p className="text-[11px] text-slate-400">
                      {item.position} · {item.area}
                    </p>
                  </div>
                  <StatusPill tone={item.receiptStatus === "disponible" ? "ok" : "neutral"}>
                    {item.receiptStatus}
                  </StatusPill>
                </div>

                <div className="mt-4 grid grid-cols-2 gap-2 rounded-lg bg-slate-50 p-2.5 text-[11px] dark:bg-slate-800">
                  <div>
                    <span className="text-slate-400">Devengado:</span>
                    <p className="font-bold text-emerald-600">
                      <Money value={item.grossIncome} />
                    </p>
                  </div>
                  <div>
                    <span className="text-slate-400">Neto:</span>
                    <p className="font-bold text-brand-600 dark:text-brand-400">
                      <Money value={item.netPay} />
                    </p>
                  </div>
                </div>

                <div className="mt-4 flex items-center justify-end">
                  <Button
                    type="button"
                    variant="secondary"
                    onClick={() => void handleViewReceipt(item.employeeId)}
                    className="flex items-center gap-1.5 text-xs w-full justify-center"
                  >
                    <Printer className="h-3.5 w-3.5" />
                    <span>Ver e Imprimir Colilla</span>
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* =========================================================
          PESTAÑA 9: REPORTES EJECUTIVOS
          ========================================================= */}
      {activeTab === "reportes" && runDetails && (
        <div className="space-y-6">
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-soft dark:border-white/10 dark:bg-slate-900">
            <h3 className="font-extrabold text-base text-slate-900 dark:text-white flex items-center gap-2">
              <FileSpreadsheet className="h-5 w-5 text-emerald-600" />
              <span>Resumen Ejecutivo y Distribución del Gasto de Nómina</span>
            </h3>
            <p className="mt-1 text-xs text-slate-500">
              Análisis comparativo de costos laborales por departamento y proyectos de Instalaciones Raquel.
            </p>

            <div className="mt-6 grid gap-4 lg:grid-cols-3">
              {uniqueAreas.map((area) => {
                const areaItems = items.filter((i) => i.area === area);
                const areaGross = areaItems.reduce((acc, i) => acc + i.grossIncome, 0);
                const areaCost = areaItems.reduce((acc, i) => acc + i.employerCost, 0);

                return (
                  <div
                    key={area}
                    className="rounded-xl border border-slate-100 bg-slate-50 p-4 dark:border-white/5 dark:bg-slate-800"
                  >
                    <h4 className="font-bold text-sm text-slate-800 dark:text-white">{area}</h4>
                    <p className="text-[11px] text-slate-400">{areaItems.length} colaboradores</p>
                    <div className="mt-3 space-y-1 text-xs">
                      <div className="flex justify-between">
                        <span className="text-slate-500">Devengado Directo:</span>
                        <strong className="text-emerald-600">
                          <Money value={areaGross} />
                        </strong>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-500">Costo Empresa Total:</span>
                        <strong className="text-brand-600 dark:text-brand-400">
                          <Money value={areaCost} />
                        </strong>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          PESTAÑA 10: HISTORIAL DE AUDITORÍA
          ========================================================= */}
      {activeTab === "historial" && (
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-soft dark:border-white/10 dark:bg-slate-900">
          <h3 className="font-extrabold text-base text-slate-900 dark:text-white flex items-center gap-2">
            <History className="h-5 w-5 text-brand-600" />
            <span>Trazabilidad y Bitácora de Auditoría</span>
          </h3>
          <p className="mt-1 text-xs text-slate-500">
            Registro cronológico inmutable de eventos, cambios de estado y cálculos de la planilla.
          </p>

          <div className="mt-6 space-y-4">
            {runDetails && (
              <div className="rounded-lg border border-slate-100 bg-slate-50 p-4 text-xs dark:border-white/5 dark:bg-slate-800">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-slate-800 dark:text-white">Estado Actual: {runDetails.status}</span>
                  <span className="text-slate-400">Versión: v{runDetails.calculationVersion}</span>
                </div>
                <p className="mt-1 text-slate-600 dark:text-slate-300">
                  Responsable inicial: {runDetails.preparedByName || "Sistema"}
                </p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* =========================================================
          MODAL: CREAR BORRADOR DE PLANILLA
          ========================================================= */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <h3 className="font-extrabold text-base text-slate-900 dark:text-white">
                Crear Borrador de Planilla
              </h3>
              <button
                type="button"
                onClick={() => setShowCreateModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {modalError && (
              <div className="mt-3 p-3 rounded-lg border border-rose-200 bg-rose-50 text-xs text-rose-800 dark:border-rose-900/40 dark:bg-rose-950/40 dark:text-rose-200">
                {modalError}
              </div>
            )}

            <form onSubmit={handleCreateDraft} className="mt-4 space-y-4 text-xs">
              <Field label="Nombre / Identificación del Período">
                <input
                  type="text"
                  required
                  placeholder="Ej: 2026-10-Q1 (1ra Quincena Octubre)"
                  value={newDraft.period}
                  onChange={(e) => setNewDraft({ ...newDraft, period: e.target.value })}
                  className={inputClass}
                />
              </Field>

              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Frecuencia de Pago">
                  <select
                    value={newDraft.periodType}
                    onChange={(e) =>
                      setNewDraft({ ...newDraft, periodType: e.target.value as any })
                    }
                    className={inputClass}
                  >
                    <option value="quincenal">Quincenal (15 días)</option>
                    <option value="mensual">Mensual (30 días)</option>
                    <option value="catorcenal">Catorcenal</option>
                    <option value="especial_aguinaldo">Especial Aguinaldo (13vo)</option>
                    <option value="liquidacion">Liquidación Final</option>
                  </select>
                </Field>

                <Field label="Fecha Prevista de Pago">
                  <input
                    type="date"
                    required
                    value={newDraft.paymentDate}
                    onChange={(e) => setNewDraft({ ...newDraft, paymentDate: e.target.value })}
                    className={inputClass}
                  />
                </Field>
              </div>

              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Fecha de Inicio">
                  <input
                    type="date"
                    required
                    value={newDraft.startDate}
                    onChange={(e) => setNewDraft({ ...newDraft, startDate: e.target.value })}
                    className={inputClass}
                  />
                </Field>
                <Field label="Fecha de Fin">
                  <input
                    type="date"
                    required
                    value={newDraft.endDate}
                    onChange={(e) => setNewDraft({ ...newDraft, endDate: e.target.value })}
                    className={inputClass}
                  />
                </Field>
              </div>

              <Field label="Notas u Observaciones">
                <textarea
                  value={newDraft.notes}
                  onChange={(e) => setNewDraft({ ...newDraft, notes: e.target.value })}
                  rows={2}
                  className={`${inputClass} h-auto py-2`}
                  placeholder="Detalles sobre el período, turno extraordinario o consideraciones..."
                />
              </Field>

              <div className="flex justify-end gap-2 pt-3 border-t dark:border-white/10">
                <Button type="button" variant="secondary" onClick={() => setShowCreateModal(false)}>
                  Cancelar
                </Button>
                <Button type="submit" variant="primary" disabled={busy}>
                  Crear Borrador
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =========================================================
          MODAL: REGISTRAR NOVEDAD
          ========================================================= */}
      {showNoveltyModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <h3 className="font-extrabold text-base text-slate-900 dark:text-white">
                Registrar Novedad del Período
              </h3>
              <button
                type="button"
                onClick={() => setShowNoveltyModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {modalError && (
              <div className="mt-3 p-3 rounded-lg border border-rose-200 bg-rose-50 text-xs text-rose-800 dark:border-rose-900/40 dark:bg-rose-950/40 dark:text-rose-200">
                {modalError}
              </div>
            )}

            <form onSubmit={handleCreateNovelty} className="mt-4 space-y-4 text-xs">
              <Field label="Colaborador">
                <select
                  required
                  value={newNovelty.employeeId}
                  onChange={(e) => setNewNovelty({ ...newNovelty, employeeId: e.target.value })}
                  className={inputClass}
                >
                  <option value="">Selecciona un colaborador...</option>
                  {items.map((it) => (
                    <option key={it.employeeId} value={it.employeeId}>
                      {it.employeeName} ({it.employeeId}) - {it.position}
                    </option>
                  ))}
                </select>
              </Field>

              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Tipo de Novedad">
                  <select
                    value={newNovelty.noveltyType}
                    onChange={(e) =>
                      setNewNovelty({ ...newNovelty, noveltyType: e.target.value as any })
                    }
                    className={inputClass}
                  >
                    <option value="horas_extra">Horas Extraordinarias (Recargo 100%)</option>
                    <option value="bono">Bono de Productividad / Cumplimiento</option>
                    <option value="comision">Comisión de Ventas / Instalación</option>
                    <option value="vacaciones">Pago de Vacaciones Disfrutadas</option>
                    <option value="ajuste_retroactivo">Ajuste Salarial Retroactivo</option>
                    <option value="deduccion_prestamo">Deducción de Préstamo / Anticipo</option>
                    <option value="otro">Otro Concepto Autorizado</option>
                  </select>
                </Field>

                <Field label="Monto en Córdobas (C$)">
                  <input
                    type="number"
                    step="0.01"
                    required
                    min={0.01}
                    value={newNovelty.amount || ""}
                    onChange={(e) =>
                      setNewNovelty({ ...newNovelty, amount: parseFloat(e.target.value) || 0 })
                    }
                    className={inputClass}
                  />
                </Field>
              </div>

              {newNovelty.noveltyType === "horas_extra" && (
                <Field label="Cantidad de Horas Extraordinarias">
                  <input
                    type="number"
                    step="0.5"
                    min={0.5}
                    value={newNovelty.hours || ""}
                    onChange={(e) =>
                      setNewNovelty({ ...newNovelty, hours: parseFloat(e.target.value) || 0 })
                    }
                    placeholder="Ej: 4.5"
                    className={inputClass}
                  />
                </Field>
              )}

              <Field label="Concepto / Descripción">
                <input
                  type="text"
                  required
                  placeholder="Ej: Horas extras en instalación de muro cortina Torre Azul..."
                  value={newNovelty.concept}
                  onChange={(e) => setNewNovelty({ ...newNovelty, concept: e.target.value })}
                  className={inputClass}
                />
              </Field>

              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Referencia Documental / Soporte">
                  <input
                    type="text"
                    placeholder="Ej: Memo-RRHH-2026-104 / Tarjeta reloj"
                    value={newNovelty.docReference}
                    onChange={(e) =>
                      setNewNovelty({ ...newNovelty, docReference: e.target.value })
                    }
                    className={inputClass}
                  />
                </Field>
                <Field label="Fecha de la Novedad">
                  <input
                    type="date"
                    required
                    value={newNovelty.periodDate}
                    onChange={(e) =>
                      setNewNovelty({ ...newNovelty, periodDate: e.target.value })
                    }
                    className={inputClass}
                  />
                </Field>
              </div>

              <Field label="Fundamento Legal / Justificación">
                <input
                  type="text"
                  placeholder="Ej: Código del Trabajo Art. 62 - Recargo del 100%"
                  value={newNovelty.legalJustification}
                  onChange={(e) =>
                    setNewNovelty({ ...newNovelty, legalJustification: e.target.value })
                  }
                  className={inputClass}
                />
              </Field>

              <div className="flex justify-end gap-2 pt-3 border-t dark:border-white/10">
                <Button type="button" variant="secondary" onClick={() => setShowNoveltyModal(false)}>
                  Cancelar
                </Button>
                <Button type="submit" variant="primary" disabled={busy}>
                  Guardar Novedad
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =========================================================
          MODAL: DEVOLVER PLANILLA CON JUSTIFICACIÓN MOTIVADA
          ========================================================= */}
      {showRollbackModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900">
            <h3 className="font-extrabold text-base text-slate-900 dark:text-white">
              Devolver Planilla a {rollbackTarget === "borrador" ? "Borrador" : "Cálculo"}
            </h3>
            <p className="mt-1 text-xs text-slate-500">
              Conforme a los estándares de auditoría, debes fundamentar el motivo por el cual se devuelve la nómina.
            </p>

            <div className="mt-4 space-y-3 text-xs">
              <Field label="Motivo formal de la devolución">
                <textarea
                  required
                  rows={3}
                  value={rollbackNotes}
                  onChange={(e) => setRollbackNotes(e.target.value)}
                  className={`${inputClass} h-auto py-2`}
                  placeholder="Ej: Discrepancia en horas extraordinarias del área de vidrio reportadas por supervisor..."
                />
              </Field>

              <div className="flex justify-end gap-2 pt-2">
                <Button type="button" variant="secondary" onClick={() => setShowRollbackModal(false)}>
                  Cancelar
                </Button>
                <Button
                  type="button"
                  variant="primary"
                  disabled={busy || !rollbackNotes.trim()}
                  onClick={() => handleTransition(rollbackTarget, rollbackNotes)}
                  className="bg-rose-600 hover:bg-rose-700"
                >
                  Confirmar Devolución
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          MODAL: EXPEDIENTE DE CÁLCULO INDIVIDUAL
          ========================================================= */}
      {showItemDetailModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900">
            <div className="flex items-start justify-between border-b pb-4 dark:border-white/10">
              <div>
                <h3 className="font-extrabold text-lg text-slate-900 dark:text-white">
                  Expediente de Cálculo de Remuneraciones
                </h3>
                <p className="text-xs text-slate-500">
                  {showItemDetailModal.employeeName} · {showItemDetailModal.position} ({showItemDetailModal.area})
                </p>
              </div>
              <button
                type="button"
                onClick={() => setShowItemDetailModal(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mt-4 space-y-4 text-xs">
              <div className="grid gap-3 sm:grid-cols-3 rounded-xl bg-slate-50 p-4 dark:bg-slate-800">
                <div>
                  <span className="text-slate-400">Salario Mensual Base:</span>
                  <p className="font-bold text-slate-800 dark:text-white text-sm">
                    <Money value={showItemDetailModal.baseSalaryMonthly} />
                  </p>
                </div>
                <div>
                  <span className="text-slate-400">Tiempo Reconocido:</span>
                  <p className="font-bold text-slate-800 dark:text-white text-sm">
                    {showItemDetailModal.daysWorked} días ({showItemDetailModal.hoursWorked} h)
                  </p>
                </div>
                <div>
                  <span className="text-slate-400">Salario Ordinario Período:</span>
                  <p className="font-bold text-slate-800 dark:text-white text-sm">
                    <Money value={showItemDetailModal.ordinarySalary} />
                  </p>
                </div>
              </div>

              {/* Remuneraciones adicionales */}
              <div>
                <h4 className="font-bold text-slate-700 dark:text-slate-200">Percepciones y Adicionales</h4>
                <div className="mt-2 grid grid-cols-2 gap-2">
                  <div className="flex justify-between border-b py-1">
                    <span className="text-slate-500">Horas Extraordinarias ({showItemDetailModal.overtimeHours} h):</span>
                    <strong className="text-emerald-600">
                      <Money value={showItemDetailModal.overtimeAmount} />
                    </strong>
                  </div>
                  <div className="flex justify-between border-b py-1">
                    <span className="text-slate-500">Bonos de Productividad:</span>
                    <strong className="text-emerald-600">
                      <Money value={showItemDetailModal.bonusesAmount} />
                    </strong>
                  </div>
                  <div className="flex justify-between border-b py-1">
                    <span className="text-slate-500">Comisiones de Obra:</span>
                    <strong className="text-emerald-600">
                      <Money value={showItemDetailModal.commissionsAmount} />
                    </strong>
                  </div>
                  <div className="flex justify-between border-b py-1">
                    <span className="text-slate-500">Total Devengado (Bruto):</span>
                    <strong className="font-black text-emerald-700 text-sm">
                      <Money value={showItemDetailModal.grossIncome} />
                    </strong>
                  </div>
                </div>
              </div>

              {/* Deducciones de Ley */}
              <div>
                <h4 className="font-bold text-slate-700 dark:text-slate-200">Deducciones de Ley</h4>
                <div className="mt-2 grid grid-cols-2 gap-2">
                  <div className="flex justify-between border-b py-1">
                    <span className="text-slate-500">INSS Laboral (7.0% s/ devengado):</span>
                    <strong className="text-rose-600">
                      <Money value={showItemDetailModal.inssLaboral} />
                    </strong>
                  </div>
                  <div className="flex justify-between border-b py-1">
                    <span className="text-slate-500">Retención IR Salarial (Ley 822):</span>
                    <strong className="text-rose-600">
                      <Money value={showItemDetailModal.incomeTax} />
                    </strong>
                  </div>
                  <div className="flex justify-between border-b py-1">
                    <span className="text-slate-500">Otras Deducciones / Préstamos:</span>
                    <strong className="text-rose-600">
                      <Money value={showItemDetailModal.otherDeductions} />
                    </strong>
                  </div>
                  <div className="flex justify-between border-b py-1">
                    <span className="text-slate-500">Total Retenciones:</span>
                    <strong className="font-black text-rose-700 text-sm">
                      <Money value={showItemDetailModal.totalDeductions} />
                    </strong>
                  </div>
                </div>
              </div>

              {/* Neto a recibir */}
              <div className="flex items-center justify-between rounded-xl bg-brand-50 p-4 text-brand-950 dark:bg-brand-950/40 dark:text-brand-100">
                <span className="font-extrabold text-sm">Neto Líquido a Pagar:</span>
                <span className="font-black text-2xl text-brand-700 dark:text-brand-300">
                  <Money value={showItemDetailModal.netPay} />
                </span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          MODAL: EXPLICAR CÁLCULO EN LENGUAJE PEDAGÓGICO
          ========================================================= */}
      {showExplainModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900">
            <div className="flex items-start justify-between border-b pb-3 dark:border-white/10">
              <div>
                <h3 className="font-extrabold text-base text-slate-900 dark:text-white flex items-center gap-2">
                  <BookOpen className="h-5 w-5 text-brand-600" />
                  <span>Explicación del Cálculo de Nómina</span>
                </h3>
                <p className="text-xs text-slate-500">Colaborador: {showExplainModal.employeeName}</p>
              </div>
              <button
                type="button"
                onClick={() => setShowExplainModal(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mt-4 max-h-[65vh] space-y-3 overflow-y-auto text-xs leading-relaxed text-slate-700 dark:text-slate-200">
              {calculationPending && <p className="rounded-lg bg-amber-50 p-3 text-amber-900">Este cálculo está pendiente o desactualizado. No sirve como autorización de pago.</p>}
              <p>Tiempo reconocido en el período: <strong>{showExplainModal.daysWorked} días y {showExplainModal.hoursWorked} horas</strong>. Estos valores proceden del detalle del servidor.</p>
              <dl className="grid grid-cols-2 gap-3">{[
                ["Salario mensual de referencia", showExplainModal.baseSalaryMonthly], ["Salario del período", showExplainModal.ordinarySalary],
                ["Horas extra", showExplainModal.overtimeAmount], ["Bonos", showExplainModal.bonusesAmount], ["Devengado", showExplainModal.grossIncome],
                ["Base INSS", showExplainModal.inssBase], ["INSS laboral", showExplainModal.inssLaboral], ["Base IR", showExplainModal.irBase],
                ["IR", showExplainModal.incomeTax], ["Otras deducciones", showExplainModal.otherDeductions], ["Total deducciones", showExplainModal.totalDeductions], ["Neto", showExplainModal.netPay]
              ].map(([label, amount]) => <div key={String(label)}><dt className="text-slate-500">{label}</dt><dd className="font-bold"><Money value={Number(amount ?? 0)} /></dd></div>)}</dl>
              <p className="rounded-lg bg-emerald-50 p-3 text-emerald-900 dark:bg-emerald-950/30 dark:text-emerald-200">Devengado − deducciones del trabajador = neto. Los aportes patronales se registran por separado. El pago cancela parte o todo el neto pendiente; no vuelve a descontar las deducciones.</p>
              <details className="rounded-lg border border-slate-200 p-3 dark:border-white/10"><summary className="cursor-pointer font-bold">Reglas y trazabilidad guardadas por el cálculo</summary><pre className="mt-2 whitespace-pre-wrap break-all text-[10px]">{showExplainModal.explanationJson || "No hay una traza de cálculo disponible para esta versión. Requiere revisión."}</pre></details>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          MODAL: COMPROBANTE OFICIAL DE PAGO (COLILLA) IMPRIMIBLE
          ========================================================= */}
      {showReceiptModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm print:p-0">
          <div className="w-full max-w-2xl rounded-2xl bg-white p-8 shadow-2xl dark:bg-slate-900 print:shadow-none print:m-0 print:w-full print:max-w-none">
            <div className="flex items-center justify-between border-b pb-4 dark:border-white/10 print:hidden">
              <span className="font-bold text-xs text-slate-400">Folio: {showReceiptModal.receiptNumber}</span>
              <div className="flex items-center gap-2">
                <Button
                  type="button"
                  variant="primary"
                  onClick={() => window.print()}
                  className="flex items-center gap-1.5 text-xs bg-brand-600 hover:bg-brand-700"
                >
                  <Printer className="h-4 w-4" />
                  <span>Imprimir Colilla</span>
                </Button>
                <button
                  type="button"
                  onClick={() => setShowReceiptModal(null)}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
            </div>

            {/* Formato oficial de la colilla de pago para Nicaragua */}
            <div className="mt-6 border border-slate-300 p-6 text-xs text-slate-800 dark:text-slate-200 print:border-black print:text-black">
              {/* Encabezado */}
              <div className="text-center border-b pb-4">
                <h2 className="font-black text-lg tracking-wider uppercase">Instalaciones Raquel S.A.</h2>
                <p className="text-[11px] font-semibold text-slate-500 print:text-black">
                  Aluminio, Vidrio y Fachadas Arquitectónicas · Managua, Nicaragua
                </p>
                <p className="text-[10px] font-mono text-slate-400 print:text-black">RUC: J0310000123456</p>
                <h3 className="mt-2 font-extrabold text-sm uppercase bg-slate-100 py-1 dark:bg-slate-800 print:bg-transparent">
                  Comprobante Oficial de Pago de Salario
                </h3>
              </div>

              {/* Datos del Trabajador */}
              <div className="mt-4 grid grid-cols-2 gap-2 border-b pb-4 text-[11px]">
                <div>
                  <span className="text-slate-500 print:text-black">Colaborador:</span>{" "}
                  <strong>{showReceiptModal.employeeName}</strong>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Código:</span>{" "}
                  <span className="font-mono">{showReceiptModal.employeeId}</span>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Cargo:</span>{" "}
                  <strong>{showReceiptModal.position}</strong>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Área:</span>{" "}
                  <strong>{showReceiptModal.area}</strong>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Período:</span>{" "}
                  <strong>{showReceiptModal.period}</strong>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Fecha de Pago:</span>{" "}
                  <strong>{showReceiptModal.paymentDate}</strong>
                </div>
              </div>

              {/* Tabla de Conceptos */}
              <div className="mt-4 grid grid-cols-2 gap-6">
                <div>
                  <h4 className="font-bold border-b pb-1 uppercase text-[10px] text-emerald-800 dark:text-emerald-400 print:text-black">
                    Percepciones (Ingresos)
                  </h4>
                  <div className="mt-2 space-y-1.5 text-[11px]">
                    <div className="flex justify-between">
                      <span>Salario Ordinario ({showReceiptModal.daysWorked} días):</span>
                      <span><Money value={showReceiptModal.ordinarySalary} /></span>
                    </div>
                    {showReceiptModal.overtimeAmount > 0 && (
                      <div className="flex justify-between">
                        <span>Horas Extraordinarias ({showReceiptModal.overtimeHours} h):</span>
                        <span><Money value={showReceiptModal.overtimeAmount} /></span>
                      </div>
                    )}
                    {showReceiptModal.bonusesAmount > 0 && (
                      <div className="flex justify-between">
                        <span>Bonos de Productividad:</span>
                        <span><Money value={showReceiptModal.bonusesAmount} /></span>
                      </div>
                    )}
                    <div className="flex justify-between border-t pt-1 font-bold">
                      <span>Total Devengado:</span>
                      <span><Money value={showReceiptModal.grossTotal} /></span>
                    </div>
                  </div>
                </div>

                <div>
                  <h4 className="font-bold border-b pb-1 uppercase text-[10px] text-rose-800 dark:text-rose-400 print:text-black">
                    Deducciones de Ley
                  </h4>
                  <div className="mt-2 space-y-1.5 text-[11px]">
                    <div className="flex justify-between">
                      <span>INSS Laboral (7%):</span>
                      <span><Money value={showReceiptModal.inssLaboral} /></span>
                    </div>
                    <div className="flex justify-between">
                      <span>IR Salarial (Ley 822):</span>
                      <span><Money value={showReceiptModal.incomeTax} /></span>
                    </div>
                    {showReceiptModal.otherDeductions > 0 && (
                      <div className="flex justify-between">
                        <span>Otras Deducciones:</span>
                        <span><Money value={showReceiptModal.otherDeductions} /></span>
                      </div>
                    )}
                    <div className="flex justify-between border-t pt-1 font-bold">
                      <span>Total Retenciones:</span>
                      <span><Money value={showReceiptModal.totalDeductions} /></span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Neto a Recibir */}
              <div className="mt-6 border-t-2 border-b-2 py-3 flex items-center justify-between font-black text-sm">
                <span>NETO LÍQUIDO A RECIBIR:</span>
                <span className="text-base"><Money value={showReceiptModal.netPay} /></span>
              </div>

              {/* Firmas de Ley */}
              <div className="mt-12 grid grid-cols-2 gap-8 text-center text-[10px]">
                <div className="border-t pt-2">
                  <p className="font-bold">Instalaciones Raquel S.A.</p>
                  <p className="text-slate-400 print:text-black">Firma y Sello Autorizado</p>
                </div>
                <div className="border-t pt-2">
                  <p className="font-bold">{showReceiptModal.employeeName}</p>
                  <p className="text-slate-400 print:text-black">Recibí Conforme (Cédula)</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      {/* =========================================================
          MODAL: AGREGAR TRABAJADOR A PLANILLA
          ========================================================= */}
      {showAddWorkerModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <h3 className="font-extrabold text-base text-slate-900 dark:text-white flex items-center gap-2">
                <UserPlus className="h-5 w-5 text-brand-600" />
                <span>Agregar Trabajador a Planilla</span>
              </h3>
              <button
                type="button"
                onClick={() => setShowAddWorkerModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {modalError && (
              <div className="mt-3 p-3 rounded-lg border border-rose-200 bg-rose-50 text-xs text-rose-800 dark:border-rose-900/40 dark:bg-rose-950/40 dark:text-rose-200">
                {modalError}
              </div>
            )}

            <form onSubmit={handleAddWorker} className="mt-4 space-y-4 text-xs">
              <Field label="Colaborador Elegible (Talento Humano)">
                <select
                  required
                  value={addWorkerDraft.employeeId}
                  onChange={(e) => setAddWorkerDraft({ ...addWorkerDraft, employeeId: e.target.value })}
                  className={inputClass}
                >
                  <option value="">Selecciona un colaborador del directorio...</option>
                  {employeesDirectory
                    .filter((emp) => !items.some((it) => it.employeeId === emp.id))
                    .map((emp) => (
                      <option key={emp.id} value={emp.id}>
                        {emp.name} ({emp.id}) — {emp.position} ({emp.area})
                      </option>
                    ))}
                </select>
                {employeesDirectory.filter((emp) => !items.some((it) => it.employeeId === emp.id)).length === 0 && (
                  <p className="mt-1 text-[11px] text-amber-600">
                    Todos los colaboradores del directorio ya están incluidos en esta planilla o no hay colaboradores activos.
                  </p>
                )}
              </Field>

              <Field label="Motivo de Inclusión">
                <input
                  type="text"
                  required
                  placeholder="Ej: Colaborador activo en período ordinario"
                  value={addWorkerDraft.reason}
                  onChange={(e) => setAddWorkerDraft({ ...addWorkerDraft, reason: e.target.value })}
                  className={inputClass}
                />
              </Field>

              <div className="flex justify-end gap-2 pt-3 border-t dark:border-white/10">
                <Button type="button" variant="secondary" onClick={() => setShowAddWorkerModal(false)}>
                  Cancelar
                </Button>
                <Button type="submit" variant="primary" disabled={busy || !addWorkerDraft.employeeId}>
                  Agregar a Planilla
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =========================================================
          MODAL: REGISTRAR PAGO / DISPERSIÓN DE NÓMINA
          ========================================================= */}
      {showPaymentModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <h3 className="font-extrabold text-base text-slate-900 dark:text-white flex items-center gap-2">
                <Banknote className="h-5 w-5 text-emerald-600" />
                <span>Registrar pago individual</span>
              </h3>
              <button
                type="button"
                onClick={() => setShowPaymentModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {modalError && (
              <div className="mt-3 p-3 rounded-lg border border-rose-200 bg-rose-50 text-xs text-rose-800 dark:border-rose-900/40 dark:bg-rose-950/40 dark:text-rose-200">
                {modalError}
              </div>
            )}

            {renderIndividualPaymentForm()}
          </div>
        </div>
      )}
    </div>
  );
}
