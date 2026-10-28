import { getApiBaseUrl } from '../lib/apiBase';
import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  AlertCircle,
  Award,
  Banknote,
  BookOpen,
  Calendar,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Clock,
  ExternalLink,
  Eye,
  FileCheck,
  FileSpreadsheet,
  FileText,
  Filter,
  HardHat,
  Home,
  Pencil,
  Plus,
  QrCode,
  RefreshCw,
  Search,
  Shield,
  ShieldAlert,
  UserCheck,
  Users,
  Printer,
  Volume2,
  VolumeX,
  X,
  XCircle,
  ZoomIn,
  ZoomOut
} from "lucide-react";
import { QRCodeSVG } from "qrcode.react";
import { useAuth } from "../auth/AuthContext";
import { authenticatedFetch, classifyApiFailure, formatApiErrorMessage } from "../auth/apiSession";
import { Button } from "../components/Button";
import { Field, inputClass, Money, PageHeader, StatusPill } from "../components/Ui";

const API_URL = getApiBaseUrl();

/* =========================================================
   TIPOS DE DATOS DE TALENTO HUMANO
   ========================================================= */
type SectionTab =
  | "inicio"
  | "personal"
  | "contratos"
  | "vacaciones"
  | "asistencia"
  | "seguridad"
  | "mi-espacio"
  | "derechos"
  | "cumplimiento";

type Employee = {
  id: string;
  name: string;
  position: string;
  area: string;
  hireDate: string | null;
  employmentStatus: "activo" | "licencia" | "baja";
  accountActive: boolean | null;
  salary?: number | null;
  dismissalDate?: string | null;
  dismissalReason?: string | null;
};

type HrContract = {
  id: string;
  employeeId: string;
  employeeName?: string;
  contractNumber: string;
  contractType: "indefinido" | "determinado" | "obra_servicio" | "periodo_prueba";
  position: string;
  workSchedule: string;
  startDate: string;
  endDate: string | null;
  agreedTerms: string;
  status: "borrador" | "en_revision" | "registrado" | "finalizado";
  revision: string;
  createdAt?: string;
};

type VacationBalance = {
  period: string;
  initialDays: number;
  accruedDays: number;
  approvedDays: number;
  pendingDays: number;
  availableDays: number;
  legalBasis: string;
};

type HrRequest = {
  id: string;
  employeeId?: string;
  employeeName?: string;
  category: "vacaciones" | "permiso" | "correccion_datos" | "consulta_laboral" | "seguridad" | "trato_recibido";
  startDate: string | null;
  endDate: string | null;
  details: string;
  status: "enviada" | "en_revision" | "aprobada" | "rechazada" | "cancelada";
  resolution: string | null;
  createdAt: string;
  revision: string;
};

type HrRequestEvent = {
  id: string;
  actorName: string;
  eventType: string;
  detail: string | null;
  occurredAt: string;
};

type AttendanceRecord = {
  id: string;
  employeeId: string;
  employeeName?: string;
  recordDate: string;
  shiftName: string;
  scheduledIn: string;
  scheduledOut: string;
  actualIn: string | null;
  actualOut: string | null;
  originalIn: string | null;
  originalOut: string | null;
  hoursLogged: number;
  hoursReviewed: number;
  hoursAuthorized: number;
  incidentType: "ninguna" | "tardanza" | "falta_justificada" | "falta_injustificada" | "salida_anticipada" | "permiso_oficial";
  incidentNotes: string | null;
  correctionReason: string | null;
  status: "registrado" | "en_revision" | "autorizado_nomina";
  revision: string;
};

type SafetyEquipment = {
  id: string;
  name: string;
  category: string;
  standardNorm: string;
  stockQty: number;
  replacementDays: number;
};

type SafetyTraining = {
  id: string;
  topic: string;
  instructor: string;
  trainingDate: string;
  hours: number;
  legalRef: string;
  status: string;
  targetArea: string;
};

type SafetyIncident = {
  id: string;
  incidentDate: string;
  area: string;
  incidentType: "condicion_insegura" | "acto_inseguro" | "casi_accidente" | "incidente_menor";
  severity: "baja" | "media" | "alta" | "critica";
  description: string;
  immediateAction: string | null;
  status: string;
};

type CorrectiveAction = {
  id: string;
  description: string;
  responsibleName: string;
  dueDate: string;
  status: "abierta" | "en_proceso" | "implementada" | "verificada_cerrada";
};

type ComplianceObligation = {
  id: string;
  topic: string;
  lawName: string;
  articleRef: string;
  summary: string;
  responsibilityArea: string;
  complianceStatus: "pendiente_revision" | "documentacion_incompleta" | "revisado_internamente" | "constancia_registrada";
  lastReviewDate: string;
  responsibleName: string;
  notes: string | null;
};

type MyReceipt = {
  runId: string;
  period: string;
  startDate: string;
  endDate: string;
  paymentDate: string;
  runStatus: string;
  grossTotal: number;
  inssLaboral: number;
  incomeTax: number;
  totalDeductions: number;
  netPay: number;
  paymentStatus: string;
  paymentConfirmedAt: string | null;
  receiptStatus: string;
};

type DashboardMetrics = {
  activeEmployees?: number;
  pendingRequests?: number;
  contractsToReview?: number;
  pendingPpeDeliveries?: number;
  openCorrectiveActions?: number;
  myTotalRequests?: number;
  myPendingRequests?: number;
  myActiveContracts?: number;
  mySafetyItems?: number;
  myTrainingsCompleted?: number;
  isManagementView: boolean;
};

const categoryLabels: Record<string, string> = {
  vacaciones: "Vacaciones",
  permiso: "Permiso laboral",
  correccion_datos: "Corrección de datos",
  consulta_laboral: "Consulta laboral",
  seguridad: "Seguridad y bienestar",
  trato_recibido: "Trato recibido"
};

const statusLabels: Record<string, string> = {
  enviada: "Enviada",
  en_revision: "En revisión",
  aprobada: "Aprobada",
  rechazada: "Rechazada",
  cancelada: "Cancelada",
  borrador: "Borrador",
  registrado: "Registrado",
  finalizado: "Finalizado",
  activo: "Activo",
  licencia: "En licencia",
  baja: "Baja registrada"
};

async function hrFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await authenticatedFetch(`${API_URL}/api/hr${path}`, init);
  const result = await response.json().catch(() => ({}));
  if (!response.ok) {
    const classified = classifyApiFailure(response.status, result.message, result.code);
    throw new Error(classified.message);
  }
  return result as T;
}

export function HrWorkspace() {
  const { user, canAccess } = useAuth();
  const navigate = useNavigate();
  const isManagement =
    user?.hierarchy === "superadmin" ||
    (user?.hierarchy === "administrador" && user.areas.includes("rrhh"));

  const [activeTab, setActiveTab] = useState<SectionTab>("inicio");
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // Estados de datos
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [myEmployee, setMyEmployee] = useState<Employee | null>(null);
  const [myContracts, setMyContracts] = useState<HrContract[]>([]);
  const [myBalance, setMyBalance] = useState<VacationBalance | null>(null);
  const [myPpe, setMyPpe] = useState<any[]>([]);
  const [myReceipts, setMyReceipts] = useState<MyReceipt[]>([]);
  const [activeReceipt, setActiveReceipt] = useState<any | null>(null);
  const [ticketModalRunId, setTicketModalRunId] = useState<string | null>(null);
  const [ticketSubject, setTicketSubject] = useState("");
  const [ticketDescription, setTicketDescription] = useState("");

  const [employees, setEmployees] = useState<Employee[]>([]);
  const [contracts, setContracts] = useState<HrContract[]>([]);
  const [requests, setRequests] = useState<HrRequest[]>([]);
  const [attendance, setAttendance] = useState<AttendanceRecord[]>([]);
  const [compliance, setCompliance] = useState<ComplianceObligation[]>([]);
  const [complianceSubTab, setComplianceSubTab] = useState<"matriz" | "catalogo">("matriz");
  const [complianceStatusFilter, setComplianceStatusFilter] = useState<string>("todos");
  const [sqlConnected, setSqlConnected] = useState<boolean | null>(null);

  // Seguridad
  const [safetyEquipment, setSafetyEquipment] = useState<SafetyEquipment[]>([]);
  const [safetyTrainings, setSafetyTrainings] = useState<SafetyTraining[]>([]);
  const [safetyIncidents, setSafetyIncidents] = useState<SafetyIncident[]>([]);
  const [correctiveActions, setCorrectiveActions] = useState<CorrectiveAction[]>([]);

  // Filtros de Personal
  const [searchEmployee, setSearchEmployee] = useState("");
  const [filterArea, setFilterArea] = useState("todas");
  const [filterStatus, setFilterStatus] = useState("todos");

  // Detalle de Expediente Modal / Pestañas
  const [selectedEmployeeId, setSelectedEmployeeId] = useState<string | null>(null);
  const [employeeDetail, setEmployeeDetail] = useState<{
    employee: Employee;
    contracts: HrContract[];
    requests: HrRequest[];
    ppeItems: any[];
  } | null>(null);
  const [dossierTab, setDossierTab] = useState<
    "resumen" | "laboral" | "contratos" | "solicitudes" | "seguridad" | "documentos" | "historial"
  >("resumen");
  const [employeeHistory, setEmployeeHistory] = useState<any[]>([]);

  // Formularios con preservación de estado
  const [modalError, setModalError] = useState<string | null>(null);
  const [newEmployeeDraft, setNewEmployeeDraft] = useState({
    code: "",
    name: "",
    position: "",
    area: "Producción",
    salary: "",
    hireDate: new Date().toISOString().slice(0, 10),
    appUserId: ""
  });
  const [showCreateEmployeeModal, setShowCreateEmployeeModal] = useState(false);

  const [terminationDraft, setTerminationDraft] = useState({
    dismissalDate: new Date().toISOString().slice(0, 10),
    dismissalReason: "",
    dismissalDocRef: ""
  });
  const [showTerminationModal, setShowTerminationModal] = useState(false);

  const [requestDraft, setRequestDraft] = useState({
    category: "vacaciones" as HrRequest["category"],
    startDate: "",
    endDate: "",
    details: ""
  });

  const [incidentDraft, setIncidentDraft] = useState({
    area: "Taller de Vidrio",
    incidentType: "condicion_insegura" as SafetyIncident["incidentType"],
    severity: "baja" as SafetyIncident["severity"],
    description: "",
    immediateAction: ""
  });

  const [attendanceCorrectionDraft, setAttendanceCorrectionDraft] = useState({
    attendanceId: "",
    requestedIn: "08:00",
    requestedOut: "17:00",
    reason: ""
  });
  const [showCorrectionModal, setShowCorrectionModal] = useState(false);

  // Edición interactiva de colaborador
  const [editingEmployee, setEditingEmployee] = useState<Employee | null>(null);
  const [editEmployeeDraft, setEditEmployeeDraft] = useState({
    position: "",
    area: "",
    salary: "",
    employmentStatus: "activo"
  });

  // Creación interactiva de Contrato Laboral
  const [showCreateContractModal, setShowCreateContractModal] = useState(false);
  const [contractDraft, setContractDraft] = useState({
    employeeId: "",
    contractType: "indefinido" as "indefinido" | "determinado" | "obra_servicio" | "periodo_prueba",
    position: "",
    workSchedule: "Lunes a Viernes 08:00 - 17:00, Sábados 08:00 - 12:00 (48h Ley 185)",
    startDate: new Date().toISOString().slice(0, 10),
    endDate: "",
    agreedTerms: "Contrato individual de trabajo conforme a la legislación laboral de Nicaragua (Ley 185 - Código del Trabajo).",
    docReference: "",
    status: "registrado" as "borrador" | "en_revision" | "registrado" | "finalizado"
  });

  // Registro interactivo de Asistencia
  const [showCreateAttendanceModal, setShowCreateAttendanceModal] = useState(false);
  const [newAttendanceDraft, setNewAttendanceDraft] = useState({
    employeeId: "",
    recordDate: new Date().toISOString().slice(0, 10),
    shiftName: "Taller Diurno (8h)",
    scheduledIn: "08:00",
    scheduledOut: "17:00",
    actualIn: "08:00",
    actualOut: "17:00",
    incidentType: "ninguna" as "ninguna" | "tardanza" | "falta_justificada" | "falta_injustificada" | "salida_anticipada" | "permiso_oficial",
    incidentNotes: ""
  });

  // Entrega interactiva de EPP (Ley 618)
  const [showDeliverEppModal, setShowDeliverEppModal] = useState(false);
  const [deliverEppDraft, setDeliverEppDraft] = useState({
    employeeId: "",
    equipmentId: "",
    deliveryDate: new Date().toISOString().slice(0, 10),
    deliveryType: "dotacion_inicial" as "dotacion_inicial" | "reposicion_desgaste" | "reposicion_dano",
    nextReplacementDate: new Date(Date.now() + 180 * 24 * 3600 * 1000).toISOString().slice(0, 10),
    notes: "Dotación oficial de protección personal según Ley 618 sin costo para el trabajador."
  });

  // Capacitación y Acciones Correctivas (Ley 618)
  const [showCreateTrainingModal, setShowCreateTrainingModal] = useState(false);
  const [trainingDraft, setTrainingDraft] = useState({
    topic: "",
    instructor: "",
    trainingDate: new Date().toISOString().slice(0, 10),
    hours: 4,
    targetArea: "Taller y Montaje",
    legalRef: "Ley 618 Arto. 18"
  });

  const [showCreateActionModal, setShowCreateActionModal] = useState(false);
  const [actionDraft, setActionDraft] = useState({
    description: "",
    responsibleName: "",
    dueDate: new Date(Date.now() + 14 * 24 * 3600 * 1000).toISOString().slice(0, 10)
  });

  const [resolutions, setResolutions] = useState<Record<string, string>>({});
  const [expandedRequests, setExpandedRequests] = useState<Record<string, boolean>>({});
  const [requestEvents, setRequestEvents] = useState<Record<string, HrRequestEvent[]>>({});

  // Carga general de datos según pestaña
  const loadData = useCallback(async () => {
    setError(null);
    try {
      const [metricsRes, meRes] = await Promise.all([
        hrFetch<{ metrics: DashboardMetrics }>("/dashboard/metrics"),
        hrFetch<{ employee: Employee; contracts: HrContract[]; balance: VacationBalance; ppeItems: any[] }>("/me")
      ]);
      setMetrics(metricsRes.metrics);
      setMyEmployee(meRes.employee ?? null);
      setMyContracts(meRes.contracts ?? []);
      setMyBalance(meRes.balance ?? null);
      setMyPpe(meRes.ppeItems ?? []);

      if (isManagement) {
        const [empRes, reqRes, conRes] = await Promise.all([
          hrFetch<{ employees: Employee[] }>("/employees"),
          hrFetch<{ requests: HrRequest[] }>("/requests?scope=queue"),
          hrFetch<{ contracts: HrContract[] }>("/contracts")
        ]);
        setEmployees(empRes.employees ?? []);
        setRequests(reqRes.requests ?? []);
        setContracts(conRes.contracts ?? []);
      } else {
        const reqRes = await hrFetch<{ requests: HrRequest[] }>("/requests?scope=mine");
        setRequests(reqRes.requests ?? []);
      }

      // Datos de nómina propios (colillas)
      const receiptsRes = await authenticatedFetch(`${API_URL}/api/payroll/my-receipts`).catch(() => null);
      if (receiptsRes && receiptsRes.ok) {
        const rData = await receiptsRes.json();
        setMyReceipts(rData.receipts ?? []);
      }

      // Datos de asistencia y seguridad
      const [attRes, safRes, comRes] = await Promise.all([
        hrFetch<{ records: AttendanceRecord[] }>("/attendance"),
        hrFetch<{
          equipment: SafetyEquipment[];
          trainings: SafetyTraining[];
          incidents: SafetyIncident[];
          actions: CorrectiveAction[];
        }>("/safety/overview"),
        hrFetch<{ obligations: ComplianceObligation[] }>("/compliance")
      ]);
      setAttendance(attRes.records ?? []);
      setSafetyEquipment(safRes.equipment ?? []);
      setSafetyTrainings(safRes.trainings ?? []);
      setSafetyIncidents(safRes.incidents ?? []);
      setCorrectiveActions(safRes.actions ?? []);
      setCompliance(comRes.obligations ?? []);
      setSqlConnected(true);
    } catch (loadErr) {
      const errInfo = formatApiErrorMessage(loadErr);
      setSqlConnected(false);
      setError(errInfo.message);
    }
  }, [isManagement]);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  // Manejador de Solicitud de Vacaciones o Permiso
  const submitRequest = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      await hrFetch("/requests", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          category: requestDraft.category,
          startDate: requestDraft.startDate || null,
          endDate: requestDraft.endDate || null,
          details: requestDraft.details,
          mutationId: crypto.randomUUID()
        })
      });
      setNotice("Solicitud registrada con éxito en SQL Server. Se notificó a la administración.");
      setRequestDraft({
        category: "vacaciones",
        startDate: "",
        endDate: "",
        details: ""
      });
      await loadData();
    } catch (submitErr) {
      setError(
        submitErr instanceof Error
          ? submitErr.message
          : "No pudimos guardar tu solicitud. Conservamos el formulario para que puedas reintentarlo."
      );
    } finally {
      setBusy(false);
    }
  };

  // Manejador de Creación de Expediente
  const submitCreateEmployee = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setModalError(null);
    setError(null);
    setNotice(null);
    try {
      const res = await hrFetch<{ employee: any }>("/employees", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          code: newEmployeeDraft.code?.trim() || undefined,
          name: newEmployeeDraft.name,
          position: newEmployeeDraft.position,
          area: newEmployeeDraft.area,
          salary: Number(newEmployeeDraft.salary),
          hireDate: newEmployeeDraft.hireDate,
          appUserId: newEmployeeDraft.appUserId?.trim() || null
        })
      });
      setNotice("Expediente de personal creado y registrado en SQL Server.");
      setShowCreateEmployeeModal(false);
      const createdEmp = res.employee;
      const createdId = createdEmp?.EmployeeId || createdEmp?.id;
      setNewEmployeeDraft({
        code: "",
        name: "",
        position: "",
        area: "Producción",
        salary: "",
        hireDate: new Date().toISOString().slice(0, 10),
        appUserId: ""
      });
      await loadData();
      if (createdId) {
        void openEmployeeDossier(createdId);
      }
    } catch (createErr) {
      const msg =
        createErr instanceof Error
          ? createErr.message
          : "No se pudo registrar el expediente. Conservamos los datos para reintentar.";
      setModalError(msg);
      setError(msg);
    } finally {
      setBusy(false);
    }
  };

  // Manejador para abrir modal de edición de empleado
  const openEditEmployee = (emp: Employee) => {
    setEditingEmployee(emp);
    setEditEmployeeDraft({
      position: emp.position || "",
      area: emp.area || "Producción",
      salary: emp.salary != null ? String(emp.salary) : "",
      employmentStatus: emp.employmentStatus || "activo"
    });
  };

  // Manejador para guardar edición de empleado (PATCH /employees/:id)
  const submitEditEmployee = async (e: FormEvent) => {
    e.preventDefault();
    if (!editingEmployee) return;
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      await hrFetch(`/employees/${encodeURIComponent(editingEmployee.id)}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          position: editEmployeeDraft.position,
          area: editEmployeeDraft.area,
          salary: editEmployeeDraft.salary ? Number(editEmployeeDraft.salary) : null,
          employmentStatus: editEmployeeDraft.employmentStatus
        })
      });
      setNotice(`Expediente de ${editingEmployee.name} actualizado con éxito.`);
      setEditingEmployee(null);
      await loadData();
      if (selectedEmployeeId === editingEmployee.id) {
        void openEmployeeDossier(editingEmployee.id);
      }
    } catch (editErr) {
      setError(editErr instanceof Error ? editErr.message : "No se pudo actualizar el expediente.");
    } finally {
      setBusy(false);
    }
  };

  // Manejador para crear contrato laboral (POST /contracts)
  const submitCreateContract = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setModalError(null);
    setError(null);
    setNotice(null);
    try {
      await hrFetch("/contracts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          employeeId: contractDraft.employeeId,
          contractType: contractDraft.contractType,
          position: contractDraft.position,
          workSchedule: contractDraft.workSchedule,
          startDate: contractDraft.startDate,
          endDate: contractDraft.endDate || null,
          agreedTerms: contractDraft.agreedTerms,
          docReference: contractDraft.docReference?.trim() || null,
          status: contractDraft.status
        })
      });
      setNotice("Contrato laboral registrado formalmente en SQL Server.");
      setShowCreateContractModal(false);
      setContractDraft({
        employeeId: "",
        contractType: "indefinido",
        position: "",
        workSchedule: "Lunes a Viernes 08:00 - 17:00, Sábados 08:00 - 12:00 (48h Ley 185)",
        startDate: new Date().toISOString().slice(0, 10),
        endDate: "",
        agreedTerms: "Contrato individual de trabajo conforme a la legislación laboral de Nicaragua (Ley 185 - Código del Trabajo).",
        docReference: "",
        status: "registrado"
      });
      await loadData();
    } catch (cErr) {
      const msg = cErr instanceof Error ? cErr.message : "No se pudo registrar el contrato laboral.";
      setModalError(msg);
      setError(msg);
    } finally {
      setBusy(false);
    }
  };

  // Manejador para registrar capacitación de seguridad (POST /safety/trainings)
  const submitCreateTraining = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setModalError(null);
    setError(null);
    setNotice(null);
    try {
      await hrFetch("/safety/trainings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          topic: trainingDraft.topic,
          instructor: trainingDraft.instructor,
          trainingDate: trainingDraft.trainingDate,
          hours: Number(trainingDraft.hours),
          targetArea: trainingDraft.targetArea,
          legalRef: trainingDraft.legalRef
        })
      });
      setNotice("Capacitación de seguridad registrada conforme a Ley 618.");
      setShowCreateTrainingModal(false);
      setTrainingDraft({
        topic: "",
        instructor: "",
        trainingDate: new Date().toISOString().slice(0, 10),
        hours: 4,
        targetArea: "Taller y Montaje",
        legalRef: "Ley 618 Arto. 18"
      });
      await loadData();
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Error al registrar capacitación.";
      setModalError(msg);
      setError(msg);
    } finally {
      setBusy(false);
    }
  };

  // Manejador para registrar acción correctiva (POST /safety/corrective-actions)
  const submitCreateAction = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setModalError(null);
    setError(null);
    setNotice(null);
    try {
      await hrFetch("/safety/corrective-actions", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          description: actionDraft.description,
          responsibleName: actionDraft.responsibleName,
          dueDate: actionDraft.dueDate
        })
      });
      setNotice("Acción correctiva de seguridad registrada.");
      setShowCreateActionModal(false);
      setActionDraft({
        description: "",
        responsibleName: "",
        dueDate: new Date(Date.now() + 14 * 24 * 3600 * 1000).toISOString().slice(0, 10)
      });
      await loadData();
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Error al registrar acción correctiva.";
      setModalError(msg);
      setError(msg);
    } finally {
      setBusy(false);
    }
  };

  // Manejador para registrar asistencia / marcación (POST /attendance)
  const submitCreateAttendance = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      await hrFetch("/attendance", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          employeeId: newAttendanceDraft.employeeId,
          recordDate: newAttendanceDraft.recordDate,
          shiftName: newAttendanceDraft.shiftName,
          scheduledIn: newAttendanceDraft.scheduledIn,
          scheduledOut: newAttendanceDraft.scheduledOut,
          actualIn: newAttendanceDraft.actualIn,
          actualOut: newAttendanceDraft.actualOut,
          incidentType: newAttendanceDraft.incidentType,
          incidentNotes: newAttendanceDraft.incidentNotes || null
        })
      });
      setNotice("Marcación de jornada y asistencia registrada en SQL Server.");
      setShowCreateAttendanceModal(false);
      setNewAttendanceDraft({
        employeeId: "",
        recordDate: new Date().toISOString().slice(0, 10),
        shiftName: "Taller Diurno (8h)",
        scheduledIn: "08:00",
        scheduledOut: "17:00",
        actualIn: "08:00",
        actualOut: "17:00",
        incidentType: "ninguna",
        incidentNotes: ""
      });
      await loadData();
    } catch (attErr) {
      setError(attErr instanceof Error ? attErr.message : "No se pudo registrar la asistencia.");
    } finally {
      setBusy(false);
    }
  };

  // Manejador para registrar entrega de EPP (POST /safety/equipment-delivery)
  const submitDeliverEpp = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      await hrFetch("/safety/equipment-delivery", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          employeeId: deliverEppDraft.employeeId,
          equipmentId: deliverEppDraft.equipmentId,
          deliveryDate: deliverEppDraft.deliveryDate,
          deliveryType: deliverEppDraft.deliveryType,
          nextReplacementDate: deliverEppDraft.nextReplacementDate || null,
          notes: deliverEppDraft.notes || null
        })
      });
      setNotice("Dotación de Equipo de Protección Personal registrada conforme a Ley 618.");
      setShowDeliverEppModal(false);
      setDeliverEppDraft({
        employeeId: "",
        equipmentId: "",
        deliveryDate: new Date().toISOString().slice(0, 10),
        deliveryType: "dotacion_inicial",
        nextReplacementDate: new Date(Date.now() + 180 * 24 * 3600 * 1000).toISOString().slice(0, 10),
        notes: "Dotación oficial de protección personal según Ley 618 sin costo para el trabajador."
      });
      await loadData();
    } catch (eppErr) {
      setError(eppErr instanceof Error ? eppErr.message : "No se pudo registrar la entrega de EPP.");
    } finally {
      setBusy(false);
    }
  };

  // Manejador de Decisión de Solicitud (Aprobar / Rechazar)
  const handleDecision = async (
    reqItem: HrRequest,
    newStatus: "en_revision" | "aprobada" | "rechazada" | "cancelada"
  ) => {
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      await hrFetch(`/requests/${encodeURIComponent(reqItem.id)}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          status: newStatus,
          revision: reqItem.revision,
          resolution: resolutions[reqItem.id] || ""
        })
      });
      setNotice(`Solicitud actualizada a estado '${statusLabels[newStatus]}'. Acción auditada.`);
      await loadData();
    } catch (decErr) {
      setError(
        decErr instanceof Error
          ? decErr.message
          : "No se pudo completar la operación. Revisa los permisos y el estado."
      );
    } finally {
      setBusy(false);
    }
  };

  // Abrir Expediente de Empleado
  const openEmployeeDossier = async (empId: string) => {
    setSelectedEmployeeId(empId);
    setDossierTab("resumen");
    setError(null);
    try {
      const result = await hrFetch<{
        employee: Employee;
        contracts: HrContract[];
        requests: HrRequest[];
        ppeItems: any[];
      }>(`/employees/${encodeURIComponent(empId)}`);
      setEmployeeDetail(result);

      const histRes = await hrFetch<{ history: any[] }>(`/employees/${encodeURIComponent(empId)}/history`);
      setEmployeeHistory(histRes.history ?? []);
    } catch (dossErr) {
      setError(dossErr instanceof Error ? dossErr.message : "No se pudo cargar el expediente.");
    }
  };

  // Registrar Baja Laboral
  const submitTermination = async (e: FormEvent) => {
    e.preventDefault();
    if (!selectedEmployeeId) return;
    setBusy(true);
    setError(null);
    try {
      await hrFetch(`/employees/${encodeURIComponent(selectedEmployeeId)}/terminate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(terminationDraft)
      });
      setNotice("Baja laboral registrada formalmente. El historial y contratos previos se conservan.");
      setShowTerminationModal(false);
      await loadData();
      if (selectedEmployeeId) void openEmployeeDossier(selectedEmployeeId);
    } catch (termErr) {
      setError(termErr instanceof Error ? termErr.message : "No se pudo registrar la baja laboral.");
    } finally {
      setBusy(false);
    }
  };

  // Reportar Incidente o Condición Insegura
  const submitIncident = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      const res = await hrFetch<{ disclaimer: string }>("/safety/incidents", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(incidentDraft)
      });
      setNotice(res.disclaimer || "Reporte preventivo registrado en SQL Server.");
      setIncidentDraft({
        area: "Taller de Vidrio",
        incidentType: "condicion_insegura",
        severity: "baja",
        description: "",
        immediateAction: ""
      });
      await loadData();
    } catch (incErr) {
      setError(incErr instanceof Error ? incErr.message : "No se pudo registrar el reporte preventivo.");
    } finally {
      setBusy(false);
    }
  };

  // Solicitar Corrección de Asistencia
  const submitAttendanceCorrection = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await hrFetch("/attendance/correction", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(attendanceCorrectionDraft)
      });
      setNotice("Solicitud de corrección de marcación enviada para revisión del supervisor.");
      setShowCorrectionModal(false);
      await loadData();
    } catch (attErr) {
      setError(attErr instanceof Error ? attErr.message : "No se pudo solicitar la corrección de asistencia.");
    } finally {
      setBusy(false);
    }
  };

  // Expandir Historial de Eventos de Solicitud
  const toggleRequestEvents = async (requestId: string) => {
    const nextState = !expandedRequests[requestId];
    setExpandedRequests({ ...expandedRequests, [requestId]: nextState });
    if (nextState && !requestEvents[requestId]) {
      try {
        const res = await hrFetch<{ events: HrRequestEvent[] }>(`/requests/${encodeURIComponent(requestId)}/events`);
        setRequestEvents({ ...requestEvents, [requestId]: res.events ?? [] });
      } catch {
        // Silencioso
      }
    }
  };

  // Filtrado de empleados en tabla
  const filteredEmployees = useMemo(() => {
    return employees.filter((emp) => {
      const matchesSearch =
        !searchEmployee ||
        emp.name.toLowerCase().includes(searchEmployee.toLowerCase()) ||
        emp.position.toLowerCase().includes(searchEmployee.toLowerCase()) ||
        emp.id.toLowerCase().includes(searchEmployee.toLowerCase());
      const matchesArea = filterArea === "todas" || emp.area === filterArea;
      const matchesStatus = filterStatus === "todos" || emp.employmentStatus === filterStatus;
      return matchesSearch && matchesArea && matchesStatus;
    });
  }, [employees, searchEmployee, filterArea, filterStatus]);

  // Resumen previo de días calculados en formulario de vacaciones
  const requestedDaysPreview = useMemo(() => {
    if (!requestDraft.startDate || !requestDraft.endDate) return null;
    const start = new Date(requestDraft.startDate);
    const end = new Date(requestDraft.endDate);
    if (end < start) return -1;
    const diffTime = Math.abs(end.getTime() - start.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
  }, [requestDraft.startDate, requestDraft.endDate]);

  return (
    <div className="space-y-6">
      {/* Encabezado General */}
      <PageHeader
        kicker="RRHH · TALENTO HUMANO Y BIENESTAR LABORAL"
        title="Gestión de Personas, Contratos y Seguridad"
        subtitle="Administra el personal, acompaña a los colaboradores y garantiza el cumplimiento normativo en aluminio, vidrio e instalaciones."
        actions={
          <div className="flex flex-wrap items-center gap-2">
            {sqlConnected === true && (
              <div className="flex items-center gap-1.5 rounded-lg border border-emerald-300 bg-emerald-50 px-2.5 py-1.5 text-xs font-semibold text-emerald-800 dark:border-emerald-800/40 dark:bg-emerald-950/40 dark:text-emerald-300">
                <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                <span>RRHH: consulta confirmada</span>
                <span className="hidden sm:inline text-[10px] text-emerald-600 dark:text-emerald-400">· Datos consultados en SQL</span>
              </div>
            )}
            {sqlConnected === false && (
              <div className="flex items-center gap-1.5 rounded-lg border border-amber-300 bg-amber-50 px-2.5 py-1.5 text-xs font-semibold text-amber-800 dark:border-amber-800/40 dark:bg-amber-950/40 dark:text-amber-300">
                <AlertCircle className="h-3.5 w-3.5 text-amber-600" />
                <span>RRHH: consulta no confirmada</span>
                <span className="hidden sm:inline text-[10px] text-amber-600 dark:text-amber-400">· Operaciones definitivas pausadas</span>
              </div>
            )}
            <Button
              type="button"
              variant="secondary"
              onClick={() => void loadData()}
              disabled={busy}
              className="flex items-center gap-1.5"
            >
              <RefreshCw className={`h-4 w-4 ${busy ? "animate-spin" : ""}`} />
              <span>Actualizar</span>
            </Button>
            <Link
              to="/derechos-y-seguridad"
              className="flex items-center gap-1.5 rounded-lg border border-brand-200 bg-white px-3 py-2 text-xs font-semibold text-brand-700 shadow-sm transition hover:bg-brand-50 dark:border-white/10 dark:bg-slate-900 dark:text-brand-300"
            >
              <BookOpen className="h-4 w-4" />
              <span>Biblioteca pública</span>
            </Link>
          </div>
        }
      />

      {/* Alertas de Estado */}
      {error && (
        <div
          role="alert"
          className="flex items-start gap-3 rounded-lg border border-rose-300 bg-rose-50 p-4 text-sm text-rose-900 dark:border-rose-900/50 dark:bg-rose-950/40 dark:text-rose-200"
        >
          <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-rose-600 dark:text-rose-400" />
          <div className="space-y-1">
            <p className="font-bold">Atención en Talento humano</p>
            <p>{error}</p>
          </div>
        </div>
      )}

      {notice && (
        <div
          role="status"
          className="flex items-start gap-3 rounded-lg border border-emerald-300 bg-emerald-50 p-4 text-sm text-emerald-900 dark:border-emerald-900/50 dark:bg-emerald-950/40 dark:text-emerald-200"
        >
          <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-emerald-600 dark:text-emerald-400" />
          <p>{notice}</p>
        </div>
      )}

      {/* Menú de Sub-secciones (9 pestañas obligatorias) */}
      <nav
        className="flex flex-wrap gap-1.5 rounded-xl border border-slate-200 bg-white p-1.5 shadow-sm dark:border-white/10 dark:bg-slate-900"
        aria-label="Navegación del módulo de Talento Humano"
      >
        {[
          ["inicio", "Inicio", Home],
          ["personal", "Personal", Users],
          ["contratos", "Contratos", FileText],
          ["vacaciones", "Vacaciones y permisos", Calendar],
          ["asistencia", "Asistencia", Clock],
          ["seguridad", "Seguridad y bienestar", HardHat],
          ["mi-espacio", "Mi espacio", UserCheck],
          ["derechos", "Derechos y orientación", BookOpen],
          ["cumplimiento", "Marco legal y cumplimiento", Shield]
        ].map(([key, label, IconComponent]: any) => (
          <button
            key={key}
            type="button"
            onClick={() => setActiveTab(key as SectionTab)}
            className={`flex items-center gap-2 rounded-lg px-3.5 py-2 text-xs font-semibold transition ${
              activeTab === key
                ? "bg-brand-600 text-white shadow-sm"
                : "text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800"
            }`}
          >
            <IconComponent className="h-4 w-4" />
            <span>{label}</span>
          </button>
        ))}
      </nav>

      {/* =========================================================
          SECCIÓN 1: INICIO (DASHBOARD ADAPTATIVO)
          ========================================================= */}
      {activeTab === "inicio" && (
        <div className="space-y-6">
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="flex flex-wrap items-center justify-between gap-2 border-b border-slate-100 pb-4 dark:border-white/5">
              <div>
                <h2 className="text-lg font-bold">
                  {isManagement ? "Panel General de Administración" : `Bienvenido(a), ${myEmployee?.name || user?.name || "Colaborador"}`}
                </h2>
                <p className="text-xs text-slate-500">
                  Período: Año en curso · Última actualización: {new Date().toLocaleTimeString()}
                </p>
              </div>
              <StatusPill tone={sqlConnected === true ? "ok" : "warn"}>{sqlConnected === true ? "RRHH: consulta confirmada" : sqlConnected === false ? "RRHH: consulta no confirmada" : "RRHH: verificando consulta"}</StatusPill>
            </div>

            {/* Tarjetas según rol */}
            <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
              {isManagement ? (
                <>
                  <button
                    type="button"
                    onClick={() => setActiveTab("personal")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-brand-300 hover:bg-brand-50/30 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Personal activo</span>
                    <strong className="mt-2 text-2xl font-extrabold text-brand-600 dark:text-brand-400">
                      {metrics?.activeEmployees ?? "Sin información registrada"}
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Ver directorio completo →</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setActiveTab("vacaciones")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-amber-300 hover:bg-amber-50/30 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Solicitudes pendientes</span>
                    <strong className="mt-2 text-2xl font-extrabold text-amber-600 dark:text-amber-400">
                      {metrics?.pendingRequests ?? 0}
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Bandeja de permisos →</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setActiveTab("contratos")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-blue-300 hover:bg-blue-50/30 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Contratos a revisión</span>
                    <strong className="mt-2 text-2xl font-extrabold text-blue-600 dark:text-blue-400">
                      {metrics?.contractsToReview ?? 0}
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Próximos a vencer →</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setActiveTab("seguridad")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-purple-300 hover:bg-purple-50/30 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Dotación EPP pendiente</span>
                    <strong className="mt-2 text-2xl font-extrabold text-purple-600 dark:text-purple-400">
                      {metrics?.pendingPpeDeliveries ?? 0}
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Reposición de guantes/botas →</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setActiveTab("seguridad")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-rose-300 hover:bg-rose-50/30 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Acciones correctivas</span>
                    <strong className="mt-2 text-2xl font-extrabold text-rose-600 dark:text-rose-400">
                      {metrics?.openCorrectiveActions ?? 0}
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Planes abiertos →</span>
                  </button>
                </>
              ) : (
                <>
                  <button
                    type="button"
                    onClick={() => setActiveTab("mi-espacio")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-brand-300 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Mis solicitudes</span>
                    <strong className="mt-2 text-2xl font-extrabold text-brand-600">
                      {metrics?.myTotalRequests ?? 0}
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Ver seguimiento →</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setActiveTab("mi-espacio")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-emerald-300 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Vacaciones disponibles</span>
                    <strong className="mt-2 text-2xl font-extrabold text-emerald-600">
                      {myBalance ? `${myBalance.availableDays} días` : "Consultando"}
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Ley 185 Art. 76 →</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setActiveTab("mi-espacio")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-blue-300 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Mi contrato vigente</span>
                    <strong className="mt-2 text-sm font-bold text-slate-800 dark:text-white">
                      {myContracts[0]?.contractNumber || "Registrado"}
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Consultar condiciones →</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setActiveTab("seguridad")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-purple-300 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Capacitaciones cursadas</span>
                    <strong className="mt-2 text-2xl font-extrabold text-purple-600">
                      {metrics?.myTrainingsCompleted ?? 0}
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Seguridad Ley 618 →</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setActiveTab("derechos")}
                    className="flex flex-col justify-between rounded-xl border border-slate-100 bg-slate-50 p-4 text-left transition hover:border-amber-300 dark:border-white/5 dark:bg-slate-800"
                  >
                    <span className="text-xs font-semibold text-slate-500">Orientación y derechos</span>
                    <strong className="mt-2 text-sm font-bold text-amber-600">
                      Guía comunitaria
                    </strong>
                    <span className="mt-2 text-[11px] text-slate-400">Conoce tus derechos →</span>
                  </button>
                </>
              )}
            </div>
          </div>

          {/* Resumen rápido de actividades recientes */}
          <div className="grid gap-6 lg:grid-cols-2">
            <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <h3 className="font-bold">Solicitudes recientes</h3>
              <div className="mt-4 divide-y divide-slate-100 dark:divide-white/5">
                {requests.slice(0, 4).map((r) => (
                  <div key={r.id} className="flex items-center justify-between py-2.5 text-xs">
                    <div>
                      <p className="font-semibold text-slate-800 dark:text-slate-100">
                        {categoryLabels[r.category] || r.category}
                        {r.employeeName ? ` · ${r.employeeName}` : ""}
                      </p>
                      <p className="text-[11px] text-slate-500 truncate max-w-xs">{r.details}</p>
                    </div>
                    <StatusPill tone={r.status === "aprobada" ? "ok" : r.status === "rechazada" ? "bad" : "warn"}>
                      {statusLabels[r.status] || r.status}
                    </StatusPill>
                  </div>
                ))}
                {requests.length === 0 && <p className="py-4 text-xs text-slate-400">No hay solicitudes para mostrar.</p>}
              </div>
            </section>

            <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <h3 className="font-bold">Seguridad en taller y obras de vidrio</h3>
              <p className="mt-1 text-xs text-slate-500">
                Instalaciones Raquel mantiene estándares de protección para trasiego de láminas crudas y templadas.
              </p>
              <div className="mt-4 space-y-2">
                <div className="rounded-lg bg-slate-50 p-3 text-xs dark:bg-slate-800">
                  <span className="font-bold text-slate-700 dark:text-slate-200">Manipulación de vidrio: </span>
                  <span>Uso obligatorio de guantes anticorte nivel 5 y mangas de antebrazo certificadas (Ley 618).</span>
                </div>
                <div className="rounded-lg bg-slate-50 p-3 text-xs dark:bg-slate-800">
                  <span className="font-bold text-slate-700 dark:text-slate-200">Trabajos en fachada y alturas: </span>
                  <span>Línea de vida asegurada y revisión previa de ventosas de vacío antes de cada izaje.</span>
                </div>
              </div>
            </section>
          </div>
        </div>
      )}

      {/* =========================================================
          SECCIÓN 2: PERSONAL Y EXPEDIENTE
          ========================================================= */}
      {activeTab === "personal" && (
        <div className="space-y-6">
          <div className="flex flex-wrap items-center justify-between gap-4 rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="flex flex-wrap items-center gap-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="search"
                  placeholder="Buscar por código, nombre o cargo..."
                  value={searchEmployee}
                  onChange={(e) => setSearchEmployee(e.target.value)}
                  className="h-9 w-64 rounded-lg border border-slate-200 bg-slate-50 pl-9 pr-3 text-xs outline-none transition focus:border-brand-500 dark:border-white/10 dark:bg-slate-950"
                />
              </div>

              <select
                value={filterArea}
                onChange={(e) => setFilterArea(e.target.value)}
                className="h-9 rounded-lg border border-slate-200 bg-slate-50 px-3 text-xs outline-none dark:border-white/10 dark:bg-slate-950"
              >
                <option value="todas">Todas las áreas</option>
                <option value="Producción">Producción</option>
                <option value="Ventas">Ventas</option>
                <option value="Compras">Compras</option>
                <option value="Contabilidad">Contabilidad</option>
                <option value="Inventario">Inventario</option>
              </select>

              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="h-9 rounded-lg border border-slate-200 bg-slate-50 px-3 text-xs outline-none dark:border-white/10 dark:bg-slate-950"
              >
                <option value="todos">Todos los estados</option>
                <option value="activo">Activos</option>
                <option value="licencia">En licencia</option>
                <option value="baja">Bajas registradas</option>
              </select>
            </div>

            {isManagement && (
              <Button
                type="button"
                onClick={() => setShowCreateEmployeeModal(true)}
                className="flex items-center gap-1.5"
              >
                <Plus className="h-4 w-4" />
                <span>Alta de personal</span>
              </Button>
            )}
          </div>

          {/* Tabla de Personal */}
          <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="border-b border-slate-100 bg-slate-50 text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:border-white/5 dark:bg-slate-800">
                  <tr>
                    <th className="px-4 py-3">Código</th>
                    <th className="px-4 py-3">Nombre</th>
                    <th className="px-4 py-3">Cargo</th>
                    <th className="px-4 py-3">Área</th>
                    <th className="px-4 py-3">Fecha de ingreso</th>
                    <th className="px-4 py-3">Estado laboral</th>
                    <th className="px-4 py-3">Cuenta acceso</th>
                    <th className="px-4 py-3 text-right">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-white/5">
                  {filteredEmployees.map((emp) => (
                    <tr key={emp.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50">
                      <td className="px-4 py-3 font-mono text-[11px] text-slate-500">{emp.id}</td>
                      <td className="px-4 py-3 font-bold text-slate-900 dark:text-white">{emp.name}</td>
                      <td className="px-4 py-3">{emp.position}</td>
                      <td className="px-4 py-3">{emp.area}</td>
                      <td className="px-4 py-3 text-slate-500">{emp.hireDate || "Sin fecha"}</td>
                      <td className="px-4 py-3">
                        <StatusPill tone={emp.employmentStatus === "activo" ? "ok" : emp.employmentStatus === "licencia" ? "warn" : "bad"}>
                          {statusLabels[emp.employmentStatus] || emp.employmentStatus}
                        </StatusPill>
                      </td>
                      <td className="px-4 py-3">
                        {emp.accountActive === true && <span className="text-emerald-600 font-semibold">Habilitada</span>}
                        {emp.accountActive === false && <span className="text-rose-600 font-semibold">Deshabilitada</span>}
                        {emp.accountActive === null && <span className="text-slate-400">Sin cuenta vinculada</span>}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          {isManagement && (
                            <button
                              type="button"
                              onClick={() => openEditEmployee(emp)}
                              className="inline-flex items-center gap-1 rounded-lg bg-blue-50 px-2 py-1 text-xs font-semibold text-blue-700 transition hover:bg-blue-100 dark:bg-blue-950/40 dark:text-blue-300"
                              title="Editar puesto, área, salario o estado"
                            >
                              <Pencil className="h-3 w-3" />
                              <span>Editar</span>
                            </button>
                          )}
                          {canAccess("nomina") && emp.employmentStatus !== "baja" && (
                            <Link to={`/nomina?tab=pagos&employeeId=${encodeURIComponent(emp.id)}`}
                              className="rounded-lg bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300">
                              Pagos / abonos
                            </Link>
                          )}
                          <button
                            type="button"
                            onClick={() => void openEmployeeDossier(emp.id)}
                            className="rounded-lg bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 transition hover:bg-brand-50 hover:text-brand-700 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
                          >
                            Ver expediente
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                  {filteredEmployees.length === 0 && (
                    <tr>
                      <td colSpan={8} className="p-8 text-center text-slate-400">
                        No se encontraron expedientes que coincidan con la búsqueda.
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
          MODAL DETALLE DE EXPEDIENTE (7 PESTAÑAS)
          ========================================================= */}
      {selectedEmployeeId && employeeDetail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <div className="flex max-h-[90vh] w-full max-w-4xl flex-col rounded-2xl bg-white shadow-2xl dark:bg-slate-900">
            {/* Cabecera del expediente */}
            <div className="flex items-center justify-between border-b border-slate-100 p-5 dark:border-white/10">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-brand-600 dark:text-brand-400">
                  Expediente de Personal · {employeeDetail.employee.id}
                </p>
                <h3 className="text-xl font-extrabold">{employeeDetail.employee.name}</h3>
                <p className="text-xs text-slate-500">
                  {employeeDetail.employee.position} · {employeeDetail.employee.area}
                </p>
              </div>
              <div className="flex items-center gap-2">
                {isManagement && (
                  <button
                    type="button"
                    onClick={() => openEditEmployee(employeeDetail.employee)}
                    className="flex items-center gap-1.5 rounded-lg bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-700 transition hover:bg-blue-100 dark:bg-blue-950/40 dark:text-blue-300"
                  >
                    <Pencil className="h-3.5 w-3.5" />
                    <span>Editar datos</span>
                  </button>
                )}
                <button
                  type="button"
                  onClick={() => setSelectedEmployeeId(null)}
                  className="rounded-lg p-2 text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
                  aria-label="Cerrar expediente"
                >
                  ✕
                </button>
              </div>
            </div>

            {/* Pestañas del expediente */}
            <div className="flex flex-wrap gap-1 border-b border-slate-100 bg-slate-50 px-5 pt-2 text-xs font-semibold dark:border-white/5 dark:bg-slate-950">
              {[
                ["resumen", "Resumen"],
                ["laboral", "Relación laboral"],
                ["contratos", "Contratos"],
                ["solicitudes", "Solicitudes"],
                ["seguridad", "Seguridad y EPP"],
                ["documentos", "Documentos"],
                ["historial", "Historial de cargos y salarios"]
              ].map(([tKey, tLabel]) => (
                <button
                  key={tKey}
                  type="button"
                  onClick={() => setDossierTab(tKey as any)}
                  className={`border-b-2 px-3 py-2 transition ${
                    dossierTab === tKey
                      ? "border-brand-600 text-brand-600 font-bold dark:border-brand-400 dark:text-brand-400"
                      : "border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200"
                  }`}
                >
                  {tLabel}
                </button>
              ))}
            </div>

            {/* Contenido según pestaña */}
            <div className="flex-1 overflow-y-auto p-6 text-sm">
              {dossierTab === "resumen" && (
                <div className="space-y-4">
                  <div className="grid gap-4 sm:grid-cols-2">
                    <div>
                      <span className="block text-xs font-bold text-slate-500">Puesto actual:</span>
                      <p className="font-semibold">{employeeDetail.employee.position}</p>
                    </div>
                    <div>
                      <span className="block text-xs font-bold text-slate-500">Área de adscripción:</span>
                      <p className="font-semibold">{employeeDetail.employee.area}</p>
                    </div>
                    <div>
                      <span className="block text-xs font-bold text-slate-500">Fecha de ingreso:</span>
                      <p className="font-semibold">{employeeDetail.employee.hireDate || "Sin información"}</p>
                    </div>
                    <div>
                      <span className="block text-xs font-bold text-slate-500">Estado de relación laboral:</span>
                      <StatusPill tone={employeeDetail.employee.employmentStatus === "activo" ? "ok" : "bad"}>
                        {statusLabels[employeeDetail.employee.employmentStatus]}
                      </StatusPill>
                    </div>
                  </div>

                  {employeeDetail.employee.salary != null && isManagement && (
                    <div className="mt-4 rounded-xl border border-blue-200 bg-blue-50/60 p-4 dark:border-blue-900/50 dark:bg-blue-950/30">
                      <span className="block text-xs font-bold text-blue-900 dark:text-blue-300">
                        Salario registrado (Acceso administrativo restringido):
                      </span>
                      <p className="text-lg font-extrabold text-blue-700 dark:text-blue-400">
                        <Money value={employeeDetail.employee.salary} />
                      </p>
                    </div>
                  )}

                  {canAccess("nomina") && (
                    <div className="mt-4 flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-white/10 dark:bg-slate-800">
                      <div>
                        <h4 className="font-bold text-xs">Módulo Relacionado: Nómina y Pagos</h4>
                        <p className="text-xs text-slate-500">Consulta los comprobantes, deducciones de INSS e IR.</p>
                      </div>
                      <Link
                        to="/nomina"
                        className="flex items-center gap-1.5 rounded-lg bg-brand-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-brand-700"
                      >
                        <ExternalLink className="h-3.5 w-3.5" />
                        <span>Abrir Nómina</span>
                      </Link>
                    </div>
                  )}
                </div>
              )}

              {dossierTab === "laboral" && (
                <div className="space-y-4">
                  <div className="rounded-lg border border-slate-200 bg-slate-50 p-4 text-xs dark:border-white/10 dark:bg-slate-800">
                    <p className="font-semibold text-slate-700 dark:text-slate-200">
                      Diferenciación de Estados según Políticas de Instalaciones Raquel:
                    </p>
                    <ul className="mt-2 list-inside list-disc space-y-1 text-slate-600 dark:text-slate-300">
                      <li>Estado de relación laboral: Activo / Licencia / Baja.</li>
                      <li>Deshabilitar la cuenta de usuario no equivale a rescisión de contrato.</li>
                      <li>Las vacaciones conservan el estatus de colaborador activo.</li>
                    </ul>
                  </div>

                  {employeeDetail.employee.employmentStatus === "baja" ? (
                    <div className="rounded-xl border border-rose-200 bg-rose-50 p-4 text-xs text-rose-900 dark:border-rose-900 dark:bg-rose-950/40 dark:text-rose-200">
                      <p className="font-bold">Baja laboral formalizada</p>
                      <p className="mt-1">Fecha de cese: {employeeDetail.employee.dismissalDate}</p>
                      <p className="mt-1">Motivo autorizado: {employeeDetail.employee.dismissalReason}</p>
                    </div>
                  ) : (
                    isManagement && (
                      <div className="pt-2">
                        <Button
                          type="button"
                          variant="danger"
                          onClick={() => setShowTerminationModal(true)}
                          className="text-xs"
                        >
                          Registrar baja laboral formal
                        </Button>
                      </div>
                    )
                  )}
                </div>
              )}

              {dossierTab === "contratos" && (
                <div className="space-y-3">
                  {employeeDetail.contracts.map((c) => (
                    <div key={c.id} className="rounded-xl border border-slate-200 p-4 dark:border-white/10">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-bold">{c.contractNumber}</span>
                        <StatusPill tone={c.status === "registrado" ? "ok" : "warn"}>{c.status}</StatusPill>
                      </div>
                      <p className="mt-1 text-xs text-slate-600 dark:text-slate-300">{c.agreedTerms}</p>
                      <div className="mt-2 text-[11px] text-slate-400">
                        Vigencia: {c.startDate} {c.endDate ? `hasta ${c.endDate}` : "(Tiempo indeterminado)"}
                      </div>
                    </div>
                  ))}
                  {employeeDetail.contracts.length === 0 && (
                    <p className="text-xs text-slate-400">Sin contratos registrados en este expediente.</p>
                  )}
                </div>
              )}

              {dossierTab === "solicitudes" && (
                <div className="space-y-3">
                  {employeeDetail.requests.map((r) => (
                    <div key={r.id} className="rounded-xl border border-slate-200 p-3.5 text-xs dark:border-white/10">
                      <div className="flex items-center justify-between">
                        <span className="font-bold">{categoryLabels[r.category] || r.category}</span>
                        <StatusPill tone={r.status === "aprobada" ? "ok" : r.status === "rechazada" ? "bad" : "warn"}>
                          {statusLabels[r.status] || r.status}
                        </StatusPill>
                      </div>
                      <p className="mt-1 text-slate-600 dark:text-slate-300">{r.details}</p>
                      {r.resolution && (
                        <p className="mt-2 rounded bg-slate-50 p-2 text-[11px] text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                          <strong>Resolución: </strong>{r.resolution}
                        </p>
                      )}
                    </div>
                  ))}
                  {employeeDetail.requests.length === 0 && (
                    <p className="text-xs text-slate-400">Sin solicitudes registradas.</p>
                  )}
                </div>
              )}

              {dossierTab === "seguridad" && (
                <div className="space-y-3">
                  <h4 className="font-bold text-xs">Dotaciones y reposiciones de EPP</h4>
                  {employeeDetail.ppeItems.map((p: any) => (
                    <div key={p.id} className="flex items-center justify-between rounded-lg border border-slate-200 p-3 text-xs dark:border-white/10">
                      <div>
                        <p className="font-bold">{p.equipmentName}</p>
                        <p className="text-[11px] text-slate-500">Entregado el: {p.deliveryDate}</p>
                      </div>
                      <span className="text-[11px] text-slate-500">Próx. reposición: {p.nextReplacementDate}</span>
                    </div>
                  ))}
                  {employeeDetail.ppeItems.length === 0 && (
                    <p className="text-xs text-slate-400">Sin equipos de protección registrados.</p>
                  )}
                </div>
              )}

              {dossierTab === "documentos" && (
                <div className="space-y-3 text-xs">
                  <p className="text-slate-500">
                    Solo los documentos formalmente autorizados pueden descargarse conforme a la Ley 787.
                  </p>
                  <div className="rounded-lg border border-slate-200 p-4 text-center text-slate-400 dark:border-white/10">
                    Archivo digital en regla. Los documentos confidenciales se entregan bajo requerimiento y auditoría.
                  </div>
                </div>
              )}

              {dossierTab === "historial" && (
                <div className="space-y-3">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs">
                      <thead className="border-b bg-slate-50 text-[11px] font-bold text-slate-500 dark:bg-slate-800">
                        <tr>
                          <th className="p-2">Cargo</th>
                          <th className="p-2">Área</th>
                          <th className="p-2">Vigente desde</th>
                          <th className="p-2">Vigente hasta</th>
                          <th className="p-2">Modificado por</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100 dark:divide-white/5">
                        {employeeHistory.map((h) => (
                          <tr key={h.id}>
                            <td className="p-2 font-semibold">{h.position}</td>
                            <td className="p-2">{h.area}</td>
                            <td className="p-2">{h.validFrom || "Inicio"}</td>
                            <td className="p-2">{h.validTo || "Vigente"}</td>
                            <td className="p-2 text-slate-400">{h.changedBy || "Sistema"}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>

            <div className="border-t border-slate-100 p-4 text-right dark:border-white/10">
              <Button type="button" variant="secondary" onClick={() => setSelectedEmployeeId(null)}>
                Cerrar expediente
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Alta de Personal */}
      {showCreateEmployeeModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <form
            onSubmit={submitCreateEmployee}
            className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900 space-y-4"
          >
            <h3 className="text-lg font-extrabold text-slate-900 dark:text-white">Alta de Personal</h3>
            <p className="text-xs text-slate-500">
              Registra un nuevo colaborador en SQL Server. Se creará su expediente y estará disponible inmediatamente para contratos y nómina.
            </p>

            {modalError && (
              <div className="rounded-lg border border-rose-300 bg-rose-50 p-2.5 text-xs text-rose-900 dark:border-rose-900/50 dark:bg-rose-950/40 dark:text-rose-200">
                {modalError}
              </div>
            )}

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Código de colaborador (opcional / sugerido)">
                <input
                  className={inputClass}
                  placeholder={`ej. EMP-2026-${String(employees.length + 1).padStart(3, "0")}`}
                  value={newEmployeeDraft.code}
                  onChange={(e) => setNewEmployeeDraft({ ...newEmployeeDraft, code: e.target.value })}
                />
              </Field>

              <Field label="Fecha de ingreso">
                <input
                  className={inputClass}
                  type="date"
                  required
                  value={newEmployeeDraft.hireDate}
                  onChange={(e) => setNewEmployeeDraft({ ...newEmployeeDraft, hireDate: e.target.value })}
                />
              </Field>
            </div>

            <Field label="Nombre completo">
              <input
                className={inputClass}
                required
                placeholder="Nombre y dos apellidos"
                value={newEmployeeDraft.name}
                onChange={(e) => setNewEmployeeDraft({ ...newEmployeeDraft, name: e.target.value })}
              />
            </Field>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Cargo / Puesto">
                <input
                  className={inputClass}
                  required
                  placeholder="ej. Armador de Vidrio Templado"
                  value={newEmployeeDraft.position}
                  onChange={(e) => setNewEmployeeDraft({ ...newEmployeeDraft, position: e.target.value })}
                />
              </Field>

              <Field label="Área">
                <select
                  className={inputClass}
                  value={newEmployeeDraft.area}
                  onChange={(e) => setNewEmployeeDraft({ ...newEmployeeDraft, area: e.target.value })}
                >
                  <option value="Producción">Producción</option>
                  <option value="Ventas">Ventas</option>
                  <option value="Compras">Compras</option>
                  <option value="Contabilidad">Contabilidad</option>
                  <option value="Inventario">Inventario</option>
                </select>
              </Field>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Salario mensual autorizado (C$)">
                <input
                  className={inputClass}
                  type="number"
                  step="0.01"
                  required
                  placeholder="ej. 15000.00"
                  value={newEmployeeDraft.salary}
                  onChange={(e) => setNewEmployeeDraft({ ...newEmployeeDraft, salary: e.target.value })}
                />
              </Field>

              <Field label="Cuenta de acceso ERP (opcional)">
                <input
                  className={inputClass}
                  placeholder="ej. ID de usuario de acceso"
                  value={newEmployeeDraft.appUserId}
                  onChange={(e) => setNewEmployeeDraft({ ...newEmployeeDraft, appUserId: e.target.value })}
                />
              </Field>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t dark:border-white/10">
              <Button type="button" variant="secondary" onClick={() => setShowCreateEmployeeModal(false)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={busy}>
                {busy ? "Guardando en SQL..." : "Crear y abrir expediente"}
              </Button>
            </div>
          </form>
        </div>
      )}

      {/* Modal Registrar Baja Laboral */}
      {showTerminationModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <form
            onSubmit={submitTermination}
            className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900 space-y-4"
          >
            <h3 className="text-lg font-extrabold text-rose-600">Registrar baja laboral</h3>
            <p className="text-xs text-slate-500">
              Registra la fecha y motivo autorizado. El expediente histórico y relaciones se conservan para auditoría y nómina.
            </p>

            <Field label="Fecha de baja laboral">
              <input
                type="date"
                required
                className={inputClass}
                value={terminationDraft.dismissalDate}
                onChange={(e) => setTerminationDraft({ ...terminationDraft, dismissalDate: e.target.value })}
              />
            </Field>

            <Field label="Motivo formal autorizado">
              <textarea
                required
                maxLength={500}
                className={`${inputClass} h-24 py-2`}
                placeholder="Detalle de rescisión, fin de contrato o mutuo acuerdo según Código del Trabajo..."
                value={terminationDraft.dismissalReason}
                onChange={(e) => setTerminationDraft({ ...terminationDraft, dismissalReason: e.target.value })}
              />
            </Field>

            {sqlConnected === false && (
              <div className="rounded-lg border border-amber-300 bg-amber-50 p-2.5 text-xs text-amber-900 dark:border-amber-900/50 dark:bg-amber-950/40 dark:text-amber-200">
                ⚠️ <strong>Modo Solo Local:</strong> Conecte SQL Server 2025 para habilitar el registro definitivo de bajas laborales.
              </div>
            )}

            <div className="flex items-center justify-end gap-2 pt-2">
              <Button type="button" variant="secondary" onClick={() => setShowTerminationModal(false)}>
                Cancelar
              </Button>
              <Button type="submit" variant="danger" disabled={busy || sqlConnected === false}>
                Confirmar baja
              </Button>
            </div>
          </form>
        </div>
      )}

      {/* =========================================================
          SECCIÓN 3: CONTRATOS
          ========================================================= */}
      {activeTab === "contratos" && (
        <div className="space-y-6">
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <h2 className="text-lg font-bold">Fichas y Versiones de Contratos</h2>
                <p className="mt-1 text-xs text-slate-500">
                  Contratos formales de trabajo, jornadas pactadas y vigencias. Las adendas y cambios no sobrescriben documentos previos.
                </p>
              </div>
              {isManagement && (
                <Button
                  type="button"
                  onClick={() => setShowCreateContractModal(true)}
                  className="flex items-center gap-1.5"
                >
                  <Plus className="h-4 w-4" />
                  <span>Nuevo contrato laboral</span>
                </Button>
              )}
            </div>

            <div className="mt-6 divide-y divide-slate-100 dark:divide-white/5">
              {contracts.map((c) => {
                const isNearExpiry = c.endDate && new Date(c.endDate).getTime() - Date.now() < 45 * 24 * 3600 * 1000;
                return (
                  <div key={c.id} className="py-4 text-xs">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <div>
                        <span className="font-bold text-sm text-slate-800 dark:text-white">{c.contractNumber}</span>
                        <span className="ml-2 font-semibold text-brand-600 dark:text-brand-400">
                          {c.employeeName || c.position}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        {isNearExpiry && (
                          <StatusPill tone="warn">Próximo a revisión</StatusPill>
                        )}
                        <StatusPill tone={c.status === "registrado" ? "ok" : "neutral"}>
                          {statusLabels[c.status] || c.status}
                        </StatusPill>
                      </div>
                    </div>

                    <p className="mt-2 leading-relaxed text-slate-600 dark:text-slate-300">{c.agreedTerms}</p>

                    <div className="mt-2 flex flex-wrap items-center gap-4 text-[11px] text-slate-400">
                      <span>Jornada: {c.workSchedule}</span>
                      <span>Tipo: {c.contractType}</span>
                      <span>Inicio: {c.startDate}</span>
                      <span>Vencimiento: {c.endDate || "Indefinido"}</span>
                      <span className="font-mono">Rev: {c.revision}</span>
                    </div>
                  </div>
                );
              })}
              {contracts.length === 0 && <p className="py-8 text-center text-slate-400">No hay contratos registrados.</p>}
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          SECCIÓN 4: VACACIONES Y PERMISOS
          ========================================================= */}
      {activeTab === "vacaciones" && (
        <div className="space-y-6">
          {/* Tarjeta Explicable de Saldo de Vacaciones */}
          <div className="rounded-xl border border-emerald-200 bg-emerald-50/60 p-5 shadow-sm dark:border-emerald-900/50 dark:bg-emerald-950/20">
            <h2 className="text-base font-extrabold text-emerald-950 dark:text-emerald-200">
              Saldo Legal de Vacaciones (Ley 185, Art. 76)
            </h2>
            <p className="mt-1 text-xs text-emerald-800 dark:text-emerald-300">
              {myBalance?.legalBasis || "Cálculo verificado según Código del Trabajo de Nicaragua."}
            </p>

            <dl className="mt-4 grid gap-3 text-xs sm:grid-cols-4">
              <div className="rounded-lg bg-white p-3 shadow-xs dark:bg-slate-900">
                <dt className="text-slate-500">Días ganados / acumulados</dt>
                <dd className="text-xl font-extrabold text-slate-800 dark:text-white">
                  {myBalance?.accruedDays ?? 0} días
                </dd>
              </div>
              <div className="rounded-lg bg-white p-3 shadow-xs dark:bg-slate-900">
                <dt className="text-slate-500">Días disfrutados (aprobados)</dt>
                <dd className="text-xl font-extrabold text-blue-600">
                  {myBalance?.approvedDays ?? 0} días
                </dd>
              </div>
              <div className="rounded-lg bg-white p-3 shadow-xs dark:bg-slate-900">
                <dt className="text-slate-500">Días en trámite</dt>
                <dd className="text-xl font-extrabold text-amber-600">
                  {myBalance?.pendingDays ?? 0} días
                </dd>
              </div>
              <div className="rounded-lg bg-white p-3 shadow-xs dark:bg-slate-900">
                <dt className="text-slate-500">Saldo disponible</dt>
                <dd className="text-xl font-extrabold text-emerald-600">
                  {myBalance?.availableDays ?? 0} días
                </dd>
              </div>
            </dl>
          </div>

          {/* Formulario para Solicitar Vacaciones o Permisos */}
          <form
            onSubmit={submitRequest}
            className="grid gap-4 rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900 sm:grid-cols-2"
          >
            <h3 className="font-extrabold sm:col-span-2 text-sm">Nueva Solicitud de Vacaciones o Permiso</h3>

            <Field label="Tipo de solicitud">
              <select
                className={inputClass}
                value={requestDraft.category}
                onChange={(e) => setRequestDraft({ ...requestDraft, category: e.target.value as any })}
              >
                <option value="vacaciones">Vacaciones ordinarias</option>
                <option value="permiso">Permiso con goce / sin goce</option>
                <option value="correccion_datos">Corrección de datos</option>
                <option value="consulta_laboral">Consulta laboral</option>
                <option value="seguridad">Seguridad y bienestar</option>
                <option value="trato_recibido">Trato recibido</option>
              </select>
            </Field>

            <Field label="Motivo y justificación">
              <input
                className={inputClass}
                required
                maxLength={500}
                placeholder="Breve explicación para la solicitud..."
                value={requestDraft.details}
                onChange={(e) => setRequestDraft({ ...requestDraft, details: e.target.value })}
              />
            </Field>

            <Field label="Fecha inicial (desde)">
              <input
                type="date"
                required={requestDraft.category === "vacaciones" || requestDraft.category === "permiso"}
                className={inputClass}
                value={requestDraft.startDate}
                onChange={(e) => setRequestDraft({ ...requestDraft, startDate: e.target.value })}
              />
            </Field>

            <Field label="Fecha final (hasta)">
              <input
                type="date"
                required={requestDraft.category === "vacaciones" || requestDraft.category === "permiso"}
                className={inputClass}
                value={requestDraft.endDate}
                onChange={(e) => setRequestDraft({ ...requestDraft, endDate: e.target.value })}
              />
            </Field>

            {/* Resumen pre-envío */}
            {requestedDaysPreview !== null && requestedDaysPreview > 0 && (
              <div className="sm:col-span-2 rounded-lg bg-slate-50 p-3 text-xs text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                <strong>Resumen previo: </strong>Solicitando {requestedDaysPreview} día(s) continuo(s) desde el {requestDraft.startDate} hasta el {requestDraft.endDate}.
              </div>
            )}

            <div className="sm:col-span-2">
              <Button type="submit" disabled={busy}>
                Enviar solicitud
              </Button>
            </div>
          </form>

          {/* Bandeja de Solicitudes y Gestión */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <h3 className="font-extrabold text-sm">
              {isManagement ? "Bandeja de Gestión de Solicitudes" : "Mis Solicitudes Enviadas"}
            </h3>

            <div className="mt-4 space-y-3">
              {requests.map((r) => {
                const isExpanded = Boolean(expandedRequests[r.id]);
                const isApplicant = myEmployee?.id === r.employeeId;

                return (
                  <div key={r.id} className="rounded-xl border border-slate-200 p-4 text-xs dark:border-white/10">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <div>
                        <span className="font-bold text-sm text-slate-800 dark:text-white">
                          {categoryLabels[r.category] || r.category}
                        </span>
                        {r.employeeName && (
                          <span className="ml-2 font-semibold text-slate-600 dark:text-slate-300">
                            · {r.employeeName}
                          </span>
                        )}
                        <span className="ml-2 text-slate-400">
                          {r.startDate && r.endDate ? `(${r.startDate} al ${r.endDate})` : ""}
                        </span>
                      </div>
                      <StatusPill tone={r.status === "aprobada" ? "ok" : r.status === "rechazada" ? "bad" : "warn"}>
                        {statusLabels[r.status] || r.status}
                      </StatusPill>
                    </div>

                    <p className="mt-2 text-slate-700 dark:text-slate-200">{r.details}</p>

                    {r.resolution && (
                      <div className="mt-2 rounded-lg bg-slate-50 p-2.5 text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                        <strong>Resolución: </strong>{r.resolution}
                      </div>
                    )}

                    {/* Acciones de gestión */}
                    <div className="mt-3 flex flex-wrap items-center justify-between gap-2 border-t border-slate-100 pt-3 dark:border-white/5">
                      <button
                        type="button"
                        onClick={() => void toggleRequestEvents(r.id)}
                        className="flex items-center gap-1 text-[11px] font-semibold text-brand-600 hover:underline dark:text-brand-400"
                      >
                        {isExpanded ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
                        <span>Ver seguimiento e historial</span>
                      </button>

                      {isManagement && (r.status === "enviada" || r.status === "en_revision") && (
                        <div className="flex flex-wrap items-center gap-2">
                          <input
                            type="text"
                            placeholder="Motivo / Justificación..."
                            value={resolutions[r.id] || ""}
                            onChange={(e) => setResolutions({ ...resolutions, [r.id]: e.target.value })}
                            className="h-8 rounded border border-slate-200 px-2 text-xs dark:border-white/10 dark:bg-slate-950"
                          />
                          <Button
                            type="button"
                            variant="secondary"
                            disabled={busy || isApplicant}
                            title={isApplicant ? "No puedes decidir una solicitud propia (Separación de funciones)" : ""}
                            onClick={() => void handleDecision(r, "aprobada")}
                            className="h-8 px-2.5 text-xs text-emerald-700 hover:bg-emerald-50"
                          >
                            Aprobar
                          </Button>
                          <Button
                            type="button"
                            variant="danger"
                            disabled={busy || isApplicant}
                            title={isApplicant ? "No puedes decidir una solicitud propia (Separación de funciones)" : ""}
                            onClick={() => void handleDecision(r, "rechazada")}
                            className="h-8 px-2.5 text-xs"
                          >
                            Rechazar
                          </Button>
                        </div>
                      )}

                      {!isManagement && r.status === "enviada" && (
                        <Button
                          type="button"
                          variant="secondary"
                          disabled={busy}
                          onClick={() => void handleDecision(r, "cancelada")}
                          className="h-8 px-2.5 text-xs text-rose-600 hover:bg-rose-50"
                        >
                          Cancelar solicitud
                        </Button>
                      )}
                    </div>

                    {/* Trazabilidad de eventos */}
                    {isExpanded && requestEvents[r.id] && (
                      <div className="mt-3 rounded-lg bg-slate-50 p-3 space-y-2 dark:bg-slate-800/80">
                        <p className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">Historial de eventos</p>
                        {requestEvents[r.id].map((ev) => (
                          <div key={ev.id} className="text-[11px] text-slate-600 dark:text-slate-300">
                            <span className="font-semibold">{ev.actorName}: </span>
                            <span>{ev.eventType} · {ev.detail || "Sin notas"} </span>
                            <span className="text-slate-400">({new Date(ev.occurredAt).toLocaleString()})</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
              {requests.length === 0 && <p className="py-4 text-center text-slate-400">No hay solicitudes en esta bandeja.</p>}
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          SECCIÓN 5: ASISTENCIA Y JORNADA
          ========================================================= */}
      {activeTab === "asistencia" && (
        <div className="space-y-6">
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <h2 className="text-lg font-bold">Registros de Asistencia y Jornada</h2>
                <p className="text-xs text-slate-500">
                  Jornada ordinaria (Ley 185 Art. 51): Horas registradas, revisadas y autorizadas para la nómina quincenal.
                </p>
              </div>
              {isManagement && (
                <Button
                  type="button"
                  onClick={() => setShowCreateAttendanceModal(true)}
                  className="flex items-center gap-1.5"
                >
                  <Plus className="h-4 w-4" />
                  <span>Registrar marcación / asistencia</span>
                </Button>
              )}
            </div>

            <div className="mt-6 overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="border-b bg-slate-50 text-[11px] font-bold uppercase text-slate-500 dark:bg-slate-800">
                  <tr>
                    <th className="p-3">Fecha</th>
                    <th className="p-3">Colaborador</th>
                    <th className="p-3">Turno</th>
                    <th className="p-3">Programado</th>
                    <th className="p-3">Entrada / Salida</th>
                    <th className="p-3">Horas Autorizadas</th>
                    <th className="p-3">Incidencia</th>
                    <th className="p-3">Estado</th>
                    <th className="p-3 text-right">Acción</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-white/5">
                  {attendance.map((att) => (
                    <tr key={att.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50">
                      <td className="p-3 font-semibold">{att.recordDate}</td>
                      <td className="p-3 font-bold">{att.employeeName || att.employeeId}</td>
                      <td className="p-3">{att.shiftName}</td>
                      <td className="p-3 text-slate-500">{att.scheduledIn} - {att.scheduledOut}</td>
                      <td className="p-3">
                        {att.actualIn && att.actualOut ? (
                          <span className="font-semibold text-slate-800 dark:text-slate-100">
                            {att.actualIn} - {att.actualOut}
                          </span>
                        ) : (
                          <span className="text-slate-400">Sin marcación</span>
                        )}
                        {att.originalIn && (
                          <span className="block text-[10px] text-amber-600">Orig: {att.originalIn}</span>
                        )}
                      </td>
                      <td className="p-3 font-bold text-brand-600 dark:text-brand-400">{att.hoursAuthorized} h</td>
                      <td className="p-3">
                        <StatusPill tone={att.incidentType === "ninguna" ? "ok" : "warn"}>
                          {att.incidentType}
                        </StatusPill>
                      </td>
                      <td className="p-3">
                        <StatusPill tone={att.status === "autorizado_nomina" ? "ok" : "warn"}>
                          {att.status}
                        </StatusPill>
                      </td>
                      <td className="p-3 text-right">
                        <button
                          type="button"
                          onClick={() => {
                            setAttendanceCorrectionDraft({
                              attendanceId: att.id,
                              requestedIn: att.actualIn || "08:00",
                              requestedOut: att.actualOut || "17:00",
                              reason: ""
                            });
                            setShowCorrectionModal(true);
                          }}
                          className="rounded-lg bg-slate-100 px-2 py-1 text-xs font-semibold hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700"
                        >
                          Corregir
                        </button>
                      </td>
                    </tr>
                  ))}
                  {attendance.length === 0 && (
                    <tr>
                      <td colSpan={9} className="p-6 text-center text-slate-400">
                        No hay registros de marcación en el período.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Modal Corrección de Asistencia */}
      {showCorrectionModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <form
            onSubmit={submitAttendanceCorrection}
            className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900 space-y-4"
          >
            <h3 className="text-lg font-extrabold">Solicitar corrección de marcación</h3>
            <p className="text-xs text-slate-500">
              Se conservará el valor original para auditoría. No se aplican deducciones arbitrarias sin revisión previa.
            </p>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Hora real de entrada">
                <input
                  type="time"
                  required
                  className={inputClass}
                  value={attendanceCorrectionDraft.requestedIn}
                  onChange={(e) =>
                    setAttendanceCorrectionDraft({ ...attendanceCorrectionDraft, requestedIn: e.target.value })
                  }
                />
              </Field>
              <Field label="Hora real de salida">
                <input
                  type="time"
                  required
                  className={inputClass}
                  value={attendanceCorrectionDraft.requestedOut}
                  onChange={(e) =>
                    setAttendanceCorrectionDraft({ ...attendanceCorrectionDraft, requestedOut: e.target.value })
                  }
                />
              </Field>
            </div>

            <Field label="Motivo de la corrección">
              <textarea
                required
                maxLength={500}
                className={`${inputClass} h-20 py-2`}
                placeholder="Ej. Falla de reloj marcador o salida a instalación de ventanería en obra..."
                value={attendanceCorrectionDraft.reason}
                onChange={(e) =>
                  setAttendanceCorrectionDraft({ ...attendanceCorrectionDraft, reason: e.target.value })
                }
              />
            </Field>

            <div className="flex items-center justify-end gap-2 pt-2">
              <Button type="button" variant="secondary" onClick={() => setShowCorrectionModal(false)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={busy}>
                Enviar corrección
              </Button>
            </div>
          </form>
        </div>
      )}

      {/* =========================================================
          SECCIÓN 6: SEGURIDAD Y BIENESTAR
          ========================================================= */}
      {activeTab === "seguridad" && (
        <div className="space-y-6">
          {/* Advertencia de Emergencias Físicas */}
          <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-xs text-amber-950 dark:border-amber-700/60 dark:bg-amber-950/30 dark:text-amber-100 flex items-start gap-3">
            <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600 dark:text-amber-400" />
            <div>
              <p className="font-bold text-sm">Protocolo de Emergencia Inmediata en Taller u Obra</p>
              <p className="mt-0.5">
                Una notificación o formulario digital en el sistema tiene fines preventivos y de auditoría; <strong>no sustituye la atención inmediata médica</strong> ante cortes por cristal templado, atrapamientos o caídas.
              </p>
              <p className="mt-1 font-semibold">Líneas de emergencia: Cruz Blanca (128) · Bomberos de Nicaragua (115).</p>
            </div>
          </div>

          {/* Formulario Rápido de Reporte Preventivo de Peligro / Condición Insegura */}
          <form
            onSubmit={submitIncident}
            className="grid gap-4 rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900 sm:grid-cols-2"
          >
            <h3 className="font-extrabold sm:col-span-2 text-sm flex items-center gap-2">
              <ShieldAlert className="h-4 w-4 text-rose-600" />
              <span>Reportar Condición o Acto Inseguro (Rápido desde el móvil)</span>
            </h3>

            <Field label="Área de trabajo">
              <select
                className={inputClass}
                value={incidentDraft.area}
                onChange={(e) => setIncidentDraft({ ...incidentDraft, area: e.target.value })}
              >
                <option value="Taller de Vidrio - Mesa de corte">Taller de Vidrio - Mesa de corte</option>
                <option value="Taller de Aluminio - Tronzadora">Taller de Aluminio - Tronzadora</option>
                <option value="Instalaciones en Obra / Fachada">Instalaciones en Obra / Fachada</option>
                <option value="Transporte y Descarga de Vidrio">Transporte y Descarga de Vidrio</option>
                <option value="Bodega de Perfiles">Bodega de Perfiles</option>
              </select>
            </Field>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Tipo de evento">
                <select
                  className={inputClass}
                  value={incidentDraft.incidentType}
                  onChange={(e) => setIncidentDraft({ ...incidentDraft, incidentType: e.target.value as any })}
                >
                  <option value="condicion_insegura">Condición insegura</option>
                  <option value="acto_inseguro">Acto inseguro</option>
                  <option value="casi_accidente">Casi accidente (Near-miss)</option>
                  <option value="incidente_menor">Incidente menor</option>
                </select>
              </Field>

              <Field label="Severidad estimada">
                <select
                  className={inputClass}
                  value={incidentDraft.severity}
                  onChange={(e) => setIncidentDraft({ ...incidentDraft, severity: e.target.value as any })}
                >
                  <option value="baja">Baja</option>
                  <option value="media">Media</option>
                  <option value="alta">Alta</option>
                  <option value="critica">Crítica</option>
                </select>
              </Field>
            </div>

            <Field label="Descripción de la condición detectada">
              <textarea
                required
                maxLength={1000}
                className={`${inputClass} h-20 py-2 sm:col-span-2`}
                placeholder="Describe el riesgo (ej. Fieltro desgastado, cable pelado en sierra ingletadora, ventosa con pérdida de presión)..."
                value={incidentDraft.description}
                onChange={(e) => setIncidentDraft({ ...incidentDraft, description: e.target.value })}
              />
            </Field>

            <Field label="Acción inmediata tomada en el momento (opcional)">
              <input
                className={inputClass}
                placeholder="ej. Se retiró la herramienta de servicio o se acordonó el área..."
                value={incidentDraft.immediateAction}
                onChange={(e) => setIncidentDraft({ ...incidentDraft, immediateAction: e.target.value })}
              />
            </Field>

            <div className="sm:col-span-2">
              <Button type="submit" disabled={busy}>
                Registrar reporte preventivo
              </Button>
            </div>
          </form>

          {/* Catálogo de EPP y Dotación */}
          <div className="grid gap-6 lg:grid-cols-2">
            <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <div className="flex flex-wrap items-center justify-between gap-2 border-b border-slate-100 pb-3 dark:border-white/5">
                <div>
                  <h3 className="font-bold text-sm">Equipos de Protección Personal (EPP Especializado)</h3>
                  <p className="mt-0.5 text-xs text-slate-500">Suministrados bajo la Ley 618 sin costo para el trabajador.</p>
                </div>
                {isManagement && (
                  <Button
                    type="button"
                    onClick={() => setShowDeliverEppModal(true)}
                    className="flex items-center gap-1.5 text-xs"
                  >
                    <Plus className="h-3.5 w-3.5" />
                    <span>Entregar EPP</span>
                  </Button>
                )}
              </div>
              <div className="mt-4 divide-y divide-slate-100 dark:divide-white/5">
                {safetyEquipment.map((eq) => (
                  <div key={eq.id} className="py-2.5 text-xs">
                    <p className="font-bold text-slate-800 dark:text-white">{eq.name}</p>
                    <div className="mt-1 flex flex-wrap items-center justify-between text-[11px] text-slate-500">
                      <span>Norma: {eq.standardNorm}</span>
                      <span>Stock en taller: {eq.stockQty} u.</span>
                    </div>
                  </div>
                ))}
              </div>
            </section>

            <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-sm">Capacitaciones Obligatorias de Higiene y Seguridad</h3>
                  <p className="mt-1 text-xs text-slate-500">Formación periódica según la Ley 618 y requerimientos de obra.</p>
                </div>
                {isManagement && (
                  <Button
                    type="button"
                    variant="primary"
                    onClick={() => {
                      setModalError(null);
                      setShowCreateTrainingModal(true);
                    }}
                    className="flex items-center gap-1.5 text-xs"
                  >
                    <Plus className="h-4 w-4" />
                    <span>Nueva Capacitación</span>
                  </Button>
                )}
              </div>
              <div className="mt-4 divide-y divide-slate-100 dark:divide-white/5">
                {safetyTrainings.map((tr) => (
                  <div key={tr.id} className="py-2.5 text-xs">
                    <p className="font-bold text-slate-800 dark:text-white">{tr.topic}</p>
                    <p className="text-[11px] text-slate-500">
                      Instructor: {tr.instructor} · Duración: {tr.hours} h · Fecha: {tr.trainingDate}
                    </p>
                  </div>
                ))}
              </div>
            </section>
          </div>

          {/* Acciones Correctivas Abiertas */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-bold text-sm">Planes y Acciones Correctivas</h3>
                <p className="mt-1 text-xs text-slate-500">Medidas de mitigación derivadas de incidentes o inspecciones Ley 618.</p>
              </div>
              {isManagement && (
                <Button
                  type="button"
                  variant="primary"
                  onClick={() => {
                    setModalError(null);
                    setShowCreateActionModal(true);
                  }}
                  className="flex items-center gap-1.5 text-xs"
                >
                  <Plus className="h-4 w-4" />
                  <span>Nueva Acción</span>
                </Button>
              )}
            </div>
            <div className="mt-4 space-y-3">
              {correctiveActions.map((act) => (
                <div key={act.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-slate-200 p-3 text-xs dark:border-white/10">
                  <div>
                    <p className="font-bold text-slate-800 dark:text-white">{act.description}</p>
                    <p className="text-[11px] text-slate-500">
                      Responsable: {act.responsibleName} · Vence: {act.dueDate}
                    </p>
                  </div>
                  <StatusPill tone={act.status === "verificada_cerrada" ? "ok" : "warn"}>
                    {act.status}
                  </StatusPill>
                </div>
              ))}
              {correctiveActions.length === 0 && <p className="text-xs text-slate-400">No hay acciones correctivas pendientes.</p>}
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          SECCIÓN 7: MI ESPACIO (AUTOSERVICIO DEL COLABORADOR)
          ========================================================= */}
      {activeTab === "mi-espacio" && (
        <div className="space-y-6">
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <h2 className="text-lg font-bold">Mi Espacio Personal</h2>
            <p className="text-xs text-slate-500">
              Consulta tus datos autorizados, tus contratos, tus vacaciones y el estado de tus solicitudes con total privacidad.
            </p>

            {myEmployee ? (
              <dl className="mt-4 grid gap-4 rounded-xl bg-slate-50 p-4 text-xs sm:grid-cols-2 lg:grid-cols-4 dark:bg-slate-800">
                <div>
                  <dt className="text-slate-500">Nombre</dt>
                  <dd className="font-bold text-sm">{myEmployee.name}</dd>
                </div>
                <div>
                  <dt className="text-slate-500">Puesto actual</dt>
                  <dd className="font-semibold">{myEmployee.position}</dd>
                </div>
                <div>
                  <dt className="text-slate-500">Área</dt>
                  <dd className="font-semibold">{myEmployee.area}</dd>
                </div>
                <div>
                  <dt className="text-slate-500">Estado de relación laboral</dt>
                  <dd><StatusPill tone="ok">{statusLabels[myEmployee.employmentStatus]}</StatusPill></dd>
                </div>
              </dl>
            ) : (
              <div className="mt-4 rounded-xl border border-amber-200 bg-amber-50 p-4 text-xs text-amber-900 dark:border-amber-900/50 dark:bg-amber-950/40 dark:text-amber-200">
                Tu cuenta de usuario no está vinculada a un expediente de personal. Solicita a Talento humano asociar tu cuenta.
              </div>
            )}
          </div>

          {/* Mis Contratos */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <h3 className="font-bold text-sm">Mis Contratos Registrados</h3>
            <div className="mt-3 space-y-2">
              {myContracts.map((c) => (
                <div key={c.id} className="rounded-lg border border-slate-100 bg-slate-50 p-3 text-xs dark:border-white/5 dark:bg-slate-800">
                  <div className="flex items-center justify-between">
                    <span className="font-bold">{c.contractNumber} · {c.position}</span>
                    <StatusPill tone="ok">{c.status}</StatusPill>
                  </div>
                  <p className="mt-1 text-slate-600 dark:text-slate-300">{c.agreedTerms}</p>
                  <p className="mt-1 text-[11px] text-slate-400">Jornada: {c.workSchedule} · Inicio: {c.startDate}</p>
                </div>
              ))}
              {myContracts.length === 0 && <p className="text-xs text-slate-400">Sin contratos vinculados.</p>}
            </div>
          </div>

          {/* Mi EPP Asignado */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <h3 className="font-bold text-sm">Mi Equipo de Protección Personal (EPP)</h3>
            <div className="mt-3 grid gap-3 sm:grid-cols-2">
              {myPpe.map((p) => (
                <div key={p.id} className="rounded-lg border border-slate-100 bg-slate-50 p-3 text-xs dark:border-white/5 dark:bg-slate-800">
                  <p className="font-bold text-slate-800 dark:text-white">{p.equipmentName}</p>
                  <p className="text-[11px] text-slate-500">Entregado: {p.deliveryDate}</p>
                  <p className="text-[11px] text-slate-500">Próxima reposición: {p.nextReplacementDate || "Al desgastarse"}</p>
                </div>
              ))}
              {myPpe.length === 0 && <p className="text-xs text-slate-400 sm:col-span-2">Sin asignaciones de EPP registradas.</p>}
            </div>
          </div>

          {/* Mis Comprobantes de Pago (Colillas de Nómina) */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="flex flex-wrap items-center justify-between gap-2 border-b pb-3 dark:border-white/10">
              <div>
                <h3 className="font-bold text-sm flex items-center gap-2">
                  <Banknote className="h-4 w-4 text-emerald-600" />
                  <span>Mis Comprobantes de Pago (Colillas)</span>
                </h3>
                <p className="text-xs text-slate-500">
                  Consulta tus pagos confirmados, deducciones de ley y solicita aclaraciones de manera transparente.
                </p>
              </div>
            </div>

            <div className="mt-4 space-y-3">
              {myReceipts.map((rcp) => (
                <div
                  key={rcp.runId}
                  className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50 p-4 text-xs dark:border-white/5 dark:bg-slate-800"
                >
                  <div>
                    <span className="font-extrabold text-sm text-slate-800 dark:text-white">
                      Planilla: {rcp.period}
                    </span>
                    <p className="text-[11px] text-slate-400">
                      Período del {rcp.startDate} al {rcp.endDate} · Fecha de pago: {rcp.paymentDate}
                    </p>
                    <div className="mt-2 flex flex-wrap gap-4 text-xs">
                      <span>Devengado: <strong className="text-emerald-600"><Money value={rcp.grossTotal} /></strong></span>
                      <span>Deducciones: <strong className="text-rose-600"><Money value={rcp.totalDeductions} /></strong></span>
                      <span>Neto Líquido: <strong className="text-brand-600 dark:text-brand-400"><Money value={rcp.netPay} /></strong></span>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-2">
                    <Button
                      type="button"
                      variant="primary"
                      onClick={async () => {
                        if (!myEmployee) return;
                        try {
                          setBusy(true);
                          const res = await authenticatedFetch(`${API_URL}/api/payroll/runs/${rcp.runId}/receipts/${myEmployee.id}`);
                          if (res.ok) {
                            const data = await res.json();
                            setActiveReceipt(data.receipt);
                          }
                        } finally {
                          setBusy(false);
                        }
                      }}
                      className="flex items-center gap-1.5 text-xs bg-brand-600 hover:bg-brand-700"
                    >
                      <Printer className="h-3.5 w-3.5" />
                      <span>Ver Colilla</span>
                    </Button>

                    <Button
                      type="button"
                      variant="secondary"
                      onClick={() => {
                        setTicketModalRunId(rcp.runId);
                        setTicketSubject(`Consulta sobre colilla período ${rcp.period}`);
                        setTicketDescription("");
                      }}
                      className="text-xs"
                    >
                      Solicitar Aclaración
                    </Button>
                  </div>
                </div>
              ))}

              {myReceipts.length === 0 && (
                <p className="text-xs text-slate-400">No hay comprobantes de pago confirmados disponibles para consulta.</p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          SECCIÓN 8: DERECHOS Y ORIENTACIÓN
          ========================================================= */}
      {activeTab === "derechos" && (
        <div className="space-y-6">
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-brand-600 dark:text-brand-400">
                  Biblioteca Comunitaria de Orientación
                </p>
                <h2 className="text-xl font-extrabold">Conoce tus derechos y trabaja con seguridad</h2>
                <p className="mt-1 text-xs text-slate-500">
                  Respuestas claras basadas en el Código del Trabajo (Ley 185) y Ley de Seguridad (Ley 618).
                </p>
              </div>
              <Link
                to="/derechos-y-seguridad"
                target="_blank"
                className="flex items-center gap-1.5 rounded-lg bg-brand-600 px-3.5 py-2 text-xs font-semibold text-white shadow-sm hover:bg-brand-700"
              >
                <ExternalLink className="h-3.5 w-3.5" />
                <span>Abrir vista pública externa</span>
              </Link>
            </div>

            <div className="mt-6 grid gap-4 sm:grid-cols-2">
              {[
                {
                  q: "¿Qué debo revisar en mi contrato?",
                  a: "Tu puesto pactado, jornada diurna máxima de 48 horas semanales y salario convenido (Ley 185 Art. 19-24)."
                },
                {
                  q: "¿Cómo entiendo mi comprobante de pago?",
                  a: "Diferencia devengado total de deducciones legales (7% INSS laboral y retención salarial IR según Ley 822 Art. 23)."
                },
                {
                  q: "¿Cómo calculo y disfruto mis vacaciones?",
                  a: "Acumulas 2.5 días hábiles por mes (15 días por cada 6 meses continuos de labor según Ley 185 Art. 76)."
                },
                {
                  q: "¿Qué protección necesito para manipular vidrio?",
                  a: "Guantes anticorte nivel 5, mangas para antebrazo, gafas anti-impacto ANSI Z87.1 y calzado dieléctrico (Ley 618)."
                },
                {
                  q: "¿Cómo comunico una condición insegura?",
                  a: "Usa la pestaña 'Seguridad y bienestar' o avisa a tu supervisor. No sustituye emergencias médicas (128 / 115)."
                },
                {
                  q: "¿Qué hago si mis datos están incorrectos?",
                  a: "Envía una solicitud de corrección de datos en 'Mi espacio' para rectificar cédula o cuenta bancaria (Ley 787)."
                }
              ].map((item, idx) => (
                <div key={idx} className="rounded-xl border border-slate-100 bg-slate-50 p-4 text-xs dark:border-white/5 dark:bg-slate-800">
                  <h4 className="font-bold text-slate-900 dark:text-white">{item.q}</h4>
                  <p className="mt-1 leading-relaxed text-slate-600 dark:text-slate-300">{item.a}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* =========================================================
          SECCIÓN 9: MARCO LEGAL Y CUMPLIMIENTO (NICARAGUA)
          ========================================================= */}
      {activeTab === "cumplimiento" && (
        <div className="space-y-6">
          {/* Encabezado y Selector de Sub-pestaña */}
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-white/10 dark:bg-slate-900">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-brand-600 dark:text-brand-400">
                  Marco Legal y Cumplimiento Normativo · Instalaciones Raquel
                </p>
                <h2 className="text-xl font-extrabold text-slate-900 dark:text-white">
                  Respaldo Jurídico y Matriz de Obligaciones
                </h2>
                <p className="mt-1 text-xs text-slate-500">
                  Fundamento legal obligatorio y verificación continua bajo la legislación laboral, de seguridad social y tributaria de Nicaragua.
                </p>
              </div>

              {/* Botones de sub-vista */}
              <div className="flex rounded-lg border border-slate-200 bg-slate-100 p-1 text-xs font-semibold dark:border-white/10 dark:bg-slate-800">
                <button
                  type="button"
                  onClick={() => setComplianceSubTab("matriz")}
                  className={`rounded-md px-3.5 py-1.5 transition ${
                    complianceSubTab === "matriz"
                      ? "bg-white text-brand-700 shadow-sm dark:bg-slate-900 dark:text-brand-400"
                      : "text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
                  }`}
                >
                  Matriz de Cumplimiento ({compliance.length})
                </button>
                <button
                  type="button"
                  onClick={() => setComplianceSubTab("catalogo")}
                  className={`rounded-md px-3.5 py-1.5 transition ${
                    complianceSubTab === "catalogo"
                      ? "bg-white text-brand-700 shadow-sm dark:bg-slate-900 dark:text-brand-400"
                      : "text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
                  }`}
                >
                  Catálogo Normativo (Leyes de Nicaragua)
                </button>
              </div>
            </div>

            {/* Sub-vista 1: MATRIZ DE CUMPLIMIENTO INSTITUCIONAL */}
            {complianceSubTab === "matriz" && (
              <div className="mt-6 space-y-6">
                {/* 4 Métricas de los 4 estados explícitos */}
                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                  <div className="rounded-xl border border-emerald-200 bg-emerald-50/60 p-4 text-xs dark:border-emerald-900/40 dark:bg-emerald-950/20">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-emerald-800 dark:text-emerald-300">Constancia registrada</span>
                      <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                    </div>
                    <p className="mt-2 text-2xl font-black text-emerald-900 dark:text-emerald-200">
                      {compliance.filter((c) => c.complianceStatus === "constancia_registrada").length}
                    </p>
                    <p className="mt-1 text-[11px] text-emerald-700 dark:text-emerald-400">
                      Con soporte oficial o acta acreditada
                    </p>
                  </div>

                  <div className="rounded-xl border border-blue-200 bg-blue-50/60 p-4 text-xs dark:border-blue-900/40 dark:bg-blue-950/20">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-blue-800 dark:text-blue-300">Revisado internamente</span>
                      <FileCheck className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                    </div>
                    <p className="mt-2 text-2xl font-black text-blue-900 dark:text-blue-200">
                      {compliance.filter((c) => c.complianceStatus === "revisado_internamente").length}
                    </p>
                    <p className="mt-1 text-[11px] text-blue-700 dark:text-blue-400">
                      Verificado por RRHH / Contabilidad
                    </p>
                  </div>

                  <div className="rounded-xl border border-amber-200 bg-amber-50/60 p-4 text-xs dark:border-amber-900/40 dark:bg-amber-950/20">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-amber-800 dark:text-amber-300">Información incompleta</span>
                      <AlertCircle className="h-4 w-4 text-amber-600 dark:text-amber-400" />
                    </div>
                    <p className="mt-2 text-2xl font-black text-amber-900 dark:text-amber-200">
                      {compliance.filter((c) => c.complianceStatus === "documentacion_incompleta").length}
                    </p>
                    <p className="mt-1 text-[11px] text-amber-700 dark:text-amber-400">
                      Pendiente de adjuntar documentación
                    </p>
                  </div>

                  <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 text-xs dark:border-white/10 dark:bg-slate-800/40">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-slate-700 dark:text-slate-300">Pendiente de revisión</span>
                      <Clock className="h-4 w-4 text-slate-500 dark:text-slate-400" />
                    </div>
                    <p className="mt-2 text-2xl font-black text-slate-900 dark:text-slate-100">
                      {compliance.filter((c) => c.complianceStatus === "pendiente_revision").length}
                    </p>
                    <p className="mt-1 text-[11px] text-slate-500 dark:text-slate-400">
                      En calendario semestral / anual
                    </p>
                  </div>
                </div>

                {/* Filtros por estado explícito */}
                <div className="flex flex-wrap items-center gap-2 border-b border-slate-100 pb-3 text-xs dark:border-white/10">
                  <span className="font-bold text-slate-500">Filtrar por estado:</span>
                  {[
                    ["todos", "Todos los compromisos"],
                    ["constancia_registrada", "Constancia registrada"],
                    ["revisado_internamente", "Revisado internamente"],
                    ["documentacion_incompleta", "Información incompleta"],
                    ["pendiente_revision", "Pendiente de revisión"]
                  ].map(([key, label]) => (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setComplianceStatusFilter(key)}
                      className={`rounded-lg px-2.5 py-1 font-semibold transition ${
                        complianceStatusFilter === key
                          ? "bg-brand-600 text-white"
                          : "bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-300"
                      }`}
                    >
                      {label}
                    </button>
                  ))}
                </div>

                {/* Lista de Obligaciones de Cumplimiento */}
                <div className="space-y-4">
                  {compliance
                    .filter(
                      (c) =>
                        complianceStatusFilter === "todos" || c.complianceStatus === complianceStatusFilter
                    )
                    .map((c) => (
                      <div
                        key={c.id}
                        className="rounded-xl border border-slate-200 bg-white p-5 text-xs shadow-sm transition hover:border-slate-300 dark:border-white/10 dark:bg-slate-900"
                      >
                        <div className="flex flex-wrap items-start justify-between gap-3">
                          <div>
                            <span className="text-sm font-extrabold text-slate-900 dark:text-white">
                              {c.topic}
                            </span>
                            <div className="mt-1 flex flex-wrap items-center gap-2 text-xs">
                              <span className="rounded bg-brand-50 px-2 py-0.5 font-bold text-brand-700 dark:bg-brand-950/40 dark:text-brand-300">
                                {c.lawName}
                              </span>
                              <span className="font-mono text-slate-500 dark:text-slate-400">
                                {c.articleRef}
                              </span>
                            </div>
                          </div>

                          <StatusPill
                            tone={
                              c.complianceStatus === "constancia_registrada"
                                ? "ok"
                                : c.complianceStatus === "revisado_internamente"
                                ? "ok"
                                : c.complianceStatus === "documentacion_incompleta"
                                ? "warn"
                                : "bad"
                            }
                          >
                            {c.complianceStatus === "constancia_registrada"
                              ? "Constancia registrada"
                              : c.complianceStatus === "revisado_internamente"
                              ? "Revisado internamente"
                              : c.complianceStatus === "documentacion_incompleta"
                              ? "Información incompleta"
                              : "Pendiente de revisión"}
                          </StatusPill>
                        </div>

                        <p className="mt-3 text-slate-700 leading-relaxed dark:text-slate-200">
                          {c.summary}
                        </p>

                        {c.notes && (
                          <div className="mt-3 rounded-lg border border-slate-100 bg-slate-50 p-2.5 text-[11px] text-slate-600 dark:border-white/5 dark:bg-slate-800/60 dark:text-slate-300">
                            <strong>Seguimiento de auditoría: </strong>
                            {c.notes}
                          </div>
                        )}

                        <div className="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-slate-100 pt-3 text-[11px] text-slate-400 dark:border-white/5">
                          <span className="flex items-center gap-1">
                            <span className="font-semibold text-slate-600 dark:text-slate-300">Área:</span>
                            {c.responsibilityArea}
                          </span>
                          <span className="flex items-center gap-1">
                            <span className="font-semibold text-slate-600 dark:text-slate-300">Auditor responsable:</span>
                            {c.responsibleName}
                          </span>
                          <span className="flex items-center gap-1">
                            <span className="font-semibold text-slate-600 dark:text-slate-300">Última verificación:</span>
                            {c.lastReviewDate}
                          </span>
                        </div>
                      </div>
                    ))}

                  {compliance.filter(
                    (c) =>
                      complianceStatusFilter === "todos" || c.complianceStatus === complianceStatusFilter
                  ).length === 0 && (
                    <div className="p-8 text-center text-slate-400">
                      No se encontraron obligaciones con el filtro seleccionado.
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Sub-vista 2: CATÁLOGO NORMATIVO DE NICARAGUA */}
            {complianceSubTab === "catalogo" && (
              <div className="mt-6 space-y-6">
                <div className="rounded-xl border border-brand-200 bg-brand-50/50 p-4 text-xs text-brand-900 dark:border-brand-900/40 dark:bg-brand-950/30 dark:text-brand-200">
                  <p className="font-bold">Marco Regulatorio Oficial de Instalaciones Raquel S.A.</p>
                  <p className="mt-1 leading-relaxed">
                    Este catálogo compila las leyes, códigos y reglamentos de la República de Nicaragua que fundamentan cada política interna, fórmula de cálculo de nómina, jornada de trabajo, protocolo de seguridad en cristalería y resguardo de datos de los colaboradores.
                  </p>
                </div>

                <div className="grid gap-6 md:grid-cols-2">
                  {/* 1. Código del Trabajo (Ley 185) */}
                  <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
                    <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
                      <div className="flex items-center gap-2">
                        <BookOpen className="h-5 w-5 text-brand-600 dark:text-brand-400" />
                        <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                          Código del Trabajo de Nicaragua
                        </h3>
                      </div>
                      <span className="rounded bg-brand-50 px-2 py-0.5 text-[10px] font-bold text-brand-700 dark:bg-brand-950/40 dark:text-brand-300">
                        Ley N° 185
                      </span>
                    </div>

                    <div className="mt-3 space-y-2 text-xs text-slate-600 dark:text-slate-300">
                      <p>
                        <strong>Fuente oficial: </strong>La Gaceta N° 205 y 206. Vigente con reformas.
                      </p>
                      <p>
                        <strong>Artículos clave: </strong>Art. 19-24 (Contrato individual y principio protector), Art. 28 (Período de prueba máx 30 días con remuneración íntegra), Art. 51-54 (Jornada diurna máx 48h semanales), Art. 57-63 (Horas extraordinarias con 100% de recargo), Art. 64 (Descanso semanal remunerado), Art. 76-80 (Vacaciones: 2.5 días hábiles por mes o 15 días por semestre continuo), Art. 93-99 (Décimo Tercer Mes o Aguinaldo inembargable), Art. 45 (Indemnización por antigüedad).
                      </p>
                      <p>
                        <strong>Aplicabilidad práctica: </strong>Estructuración de contratos en taller de manufactura de aluminio y cristalería; turnos ordinarios diurnos de lunes a sábado; acumulación y disfrute efectivo de vacaciones.
                      </p>
                      <div className="border-t pt-2 text-[11px] text-slate-400 dark:border-white/5">
                        Responsable de revisión: Talento Humano y Asesoría Legal
                      </div>
                    </div>
                  </div>

                  {/* 2. Ley de Higiene y Seguridad del Trabajo (Ley 618) */}
                  <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
                    <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
                      <div className="flex items-center gap-2">
                        <HardHat className="h-5 w-5 text-amber-600 dark:text-amber-400" />
                        <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                          Higiene y Seguridad del Trabajo
                        </h3>
                      </div>
                      <span className="rounded bg-amber-50 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:bg-amber-950/40 dark:text-amber-300">
                        Ley N° 618
                      </span>
                    </div>

                    <div className="mt-3 space-y-2 text-xs text-slate-600 dark:text-slate-300">
                      <p>
                        <strong>Fuente oficial: </strong>La Gaceta N° 133. Normativa técnica MITRAB.
                      </p>
                      <p>
                        <strong>Artículos clave: </strong>Art. 18, 32 (Constitución obligatoria de Comisión Mixta de Higiene y Seguridad), Art. 108-114 (EPP certificado gratuito para corte de vidrio, fresado de aluminio y soldadura), Art. 165 (Trabajo en alturas superior a 1.80m en instalación de fachadas flotantes con arnés y línea de vida), Art. 220-225 (Investigación y reporte de incidentes y casi-accidentes).
                      </p>
                      <p>
                        <strong>Aplicabilidad práctica: </strong>Dotación reglamentaria de guantes anticorte nivel 5, gafas de seguridad ANSI Z87.1, calzado dieléctrico con puntera reforzada y capacitación preventiva trimestral.
                      </p>
                      <div className="border-t pt-2 text-[11px] text-slate-400 dark:border-white/5">
                        Responsable de revisión: Supervisor de Seguridad Industrial y Comisión Mixta
                      </div>
                    </div>
                  </div>

                  {/* 3. Ley de Protección de Datos Personales (Ley 787) */}
                  <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
                    <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
                      <div className="flex items-center gap-2">
                        <Shield className="h-5 w-5 text-emerald-600 dark:text-emerald-400" />
                        <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                          Protección de Datos Personales
                        </h3>
                      </div>
                      <span className="rounded bg-emerald-50 px-2 py-0.5 text-[10px] font-bold text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300">
                        Ley N° 787
                      </span>
                    </div>

                    <div className="mt-3 space-y-2 text-xs text-slate-600 dark:text-slate-300">
                      <p>
                        <strong>Fuente oficial: </strong>La Gaceta N° 61.
                      </p>
                      <p>
                        <strong>Artículos clave: </strong>Art. 4 (Principios de finalidad, proporcionalidad y veracidad), Art. 9 (Consentimiento para tratamiento de datos laborales), Art. 13 (Deber estricto de reserva y medidas técnicas de seguridad).
                      </p>
                      <p>
                        <strong>Aplicabilidad práctica: </strong>Aislamiento de salarios en API y base de datos (entregados únicamente a usuarios con rol RRHH); prohibición absoluta de publicar diagnósticos médicos o sanciones en tableros abiertos; acceso individual a 'Mi espacio'.
                      </p>
                      <div className="border-t pt-2 text-[11px] text-slate-400 dark:border-white/5">
                        Responsable de revisión: Talento Humano y Administración de Base de Datos
                      </div>
                    </div>
                  </div>

                  {/* 4. Ley de Concertación Tributaria (Ley 822) */}
                  <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
                    <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
                      <div className="flex items-center gap-2">
                        <Banknote className="h-5 w-5 text-indigo-600 dark:text-indigo-400" />
                        <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                          Ley de Concertación Tributaria (IR)
                        </h3>
                      </div>
                      <span className="rounded bg-indigo-50 px-2 py-0.5 text-[10px] font-bold text-indigo-700 dark:bg-indigo-950/40 dark:text-indigo-300">
                        Ley N° 822
                      </span>
                    </div>

                    <div className="mt-3 space-y-2 text-xs text-slate-600 dark:text-slate-300">
                      <p>
                        <strong>Fuente oficial: </strong>La Gaceta N° 241 y Reglamento Ejecutivo.
                      </p>
                      <p>
                        <strong>Artículos clave: </strong>Art. 23 (Tarifa progresiva sobre rentas del trabajo con exención base anual de C$ 100,000.00), Art. 24 (Deducción previa obligatoria del aporte laboral del INSS antes de determinar la base gravable).
                      </p>
                      <p>
                        <strong>Aplicabilidad práctica: </strong>Cálculo automático de retenciones quincenales en nómina; desglose en colillas de pago; declaración mensual y constancia anual de retenciones ante la DGI.
                      </p>
                      <div className="border-t pt-2 text-[11px] text-slate-400 dark:border-white/5">
                        Responsable de revisión: Contabilidad y Nómina
                      </div>
                    </div>
                  </div>

                  {/* 5. Ley de Seguridad Social y Normativa INSS */}
                  <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
                    <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
                      <div className="flex items-center gap-2">
                        <Award className="h-5 w-5 text-cyan-600 dark:text-cyan-400" />
                        <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                          Seguridad Social (INSS)
                        </h3>
                      </div>
                      <span className="rounded bg-cyan-50 px-2 py-0.5 text-[10px] font-bold text-cyan-700 dark:bg-cyan-950/40 dark:text-cyan-300">
                        Reglamento INSS
                      </span>
                    </div>

                    <div className="mt-3 space-y-2 text-xs text-slate-600 dark:text-slate-300">
                      <p>
                        <strong>Fuente oficial: </strong>Decreto N° 975 / La Gaceta. Reformas aplicables.
                      </p>
                      <p>
                        <strong>Parámetros oficiales: </strong>Cotización laboral: 7.0% deducido del salario devengado. Cotización patronal: 21.5% o 22.5% según plantilla. Cobertura en enfermedad común, maternidad, invalidez, vejez, muerte y riesgos profesionales en taller y campo.
                      </p>
                      <p>
                        <strong>Aplicabilidad práctica: </strong>Afiliación inmediata desde el primer día de labores; retención y pago oportuno mediante facturación mensual de la Seguridad Social; cobertura activa de operarios ante contingencias laborales.
                      </p>
                      <div className="border-t pt-2 text-[11px] text-slate-400 dark:border-white/5">
                        Responsable de revisión: Contabilidad y Talento Humano
                      </div>
                    </div>
                  </div>

                  {/* 6. Normativa del Instituto Nacional Tecnológico (INATEC) */}
                  <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-slate-900">
                    <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
                      <div className="flex items-center gap-2">
                        <UserCheck className="h-5 w-5 text-violet-600 dark:text-violet-400" />
                        <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                          Formación Profesional (INATEC)
                        </h3>
                      </div>
                      <span className="rounded bg-violet-50 px-2 py-0.5 text-[10px] font-bold text-violet-700 dark:bg-violet-950/40 dark:text-violet-300">
                        Ley N° 111 / Decreto 3-91
                      </span>
                    </div>

                    <div className="mt-3 space-y-2 text-xs text-slate-600 dark:text-slate-300">
                      <p>
                        <strong>Fuente oficial: </strong>La Gaceta Diario Oficial.
                      </p>
                      <p>
                        <strong>Parámetros oficiales: </strong>Aporte patronal exclusivo del 2.0% sobre la planilla bruta mensual. No se descuenta al trabajador.
                      </p>
                      <p>
                        <strong>Aplicabilidad práctica: </strong>Financiamiento para capacitación técnica de operarios de corte de aluminio, pulido de vidrio templado, soldadura y ensamblaje de muros cortina en Instalaciones Raquel.
                      </p>
                      <div className="border-t pt-2 text-[11px] text-slate-400 dark:border-white/5">
                        Responsable de revisión: Contabilidad y Gerencia General
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
      {/* Modal: Aclaración de Colilla */}
      {ticketModalRunId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <h3 className="font-extrabold text-base text-slate-900 dark:text-white">
                Solicitud de Aclaración sobre Comprobante
              </h3>
              <button
                type="button"
                onClick={() => setTicketModalRunId(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <form
              onSubmit={async (e) => {
                e.preventDefault();
                if (!ticketModalRunId || !myEmployee) return;
                try {
                  setBusy(true);
                  setError(null);
                  const res = await authenticatedFetch(`${API_URL}/api/payroll/receipt-tickets`, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                      payrollRunId: ticketModalRunId,
                      employeeId: myEmployee.id,
                      subject: ticketSubject,
                      description: ticketDescription
                    })
                  });
                  const data = await res.json();
                  if (!res.ok) {
                    throw new Error(data.message || "Error al enviar la solicitud.");
                  }
                  setNotice(data.message);
                  setTicketModalRunId(null);
                  setTicketSubject("");
                  setTicketDescription("");
                } catch (err: any) {
                  setError(err.message);
                } finally {
                  setBusy(false);
                }
              }}
              className="mt-4 space-y-4 text-xs"
            >
              <Field label="Asunto de la consulta">
                <input
                  type="text"
                  required
                  value={ticketSubject}
                  onChange={(e) => setTicketSubject(e.target.value)}
                  className={inputClass}
                />
              </Field>

              <Field label="Detalle o consulta sobre tu pago">
                <textarea
                  required
                  rows={4}
                  value={ticketDescription}
                  onChange={(e) => setTicketDescription(e.target.value)}
                  className={`${inputClass} h-auto py-2`}
                  placeholder="Explica qué rubro, cálculo o comprobante deseas que RRHH y Finanzas revisen..."
                />
              </Field>

              <div className="flex justify-end gap-2 pt-2 border-t dark:border-white/10">
                <Button type="button" variant="secondary" onClick={() => setTicketModalRunId(null)}>
                  Cancelar
                </Button>
                <Button type="submit" variant="primary" disabled={busy}>
                  Enviar Solicitud
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Comprobante Imprimible de Colilla */}
      {activeReceipt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm print:p-0">
          <div className="w-full max-w-2xl rounded-2xl bg-white p-8 shadow-2xl dark:bg-slate-900 print:shadow-none print:m-0 print:w-full print:max-w-none">
            <div className="flex items-center justify-between border-b pb-4 dark:border-white/10 print:hidden">
              <span className="font-bold text-xs text-slate-400">Folio: {activeReceipt.receiptNumber}</span>
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
                  onClick={() => setActiveReceipt(null)}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
            </div>

            <div className="mt-6 border border-slate-300 p-6 text-xs text-slate-800 dark:text-slate-200 print:border-black print:text-black">
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

              <div className="mt-4 grid grid-cols-2 gap-2 border-b pb-4 text-[11px]">
                <div>
                  <span className="text-slate-500 print:text-black">Colaborador:</span>{" "}
                  <strong>{activeReceipt.employeeName}</strong>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Código:</span>{" "}
                  <span className="font-mono">{activeReceipt.employeeId}</span>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Cargo:</span>{" "}
                  <strong>{activeReceipt.position}</strong>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Área:</span>{" "}
                  <strong>{activeReceipt.area}</strong>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Período:</span>{" "}
                  <strong>{activeReceipt.period}</strong>
                </div>
                <div>
                  <span className="text-slate-500 print:text-black">Fecha de Pago:</span>{" "}
                  <strong>{activeReceipt.paymentDate}</strong>
                </div>
              </div>

              <div className="mt-4 grid grid-cols-2 gap-6">
                <div>
                  <h4 className="font-bold border-b pb-1 uppercase text-[10px] text-emerald-800 dark:text-emerald-400 print:text-black">
                    Percepciones (Ingresos)
                  </h4>
                  <div className="mt-2 space-y-1.5 text-[11px]">
                    <div className="flex justify-between">
                      <span>Salario Ordinario ({activeReceipt.daysWorked} días):</span>
                      <span><Money value={activeReceipt.ordinarySalary} /></span>
                    </div>
                    {activeReceipt.overtimeAmount > 0 && (
                      <div className="flex justify-between">
                        <span>Horas Extra ({activeReceipt.overtimeHours} h):</span>
                        <span><Money value={activeReceipt.overtimeAmount} /></span>
                      </div>
                    )}
                    {activeReceipt.bonusesAmount > 0 && (
                      <div className="flex justify-between">
                        <span>Bonos:</span>
                        <span><Money value={activeReceipt.bonusesAmount} /></span>
                      </div>
                    )}
                    <div className="flex justify-between border-t pt-1 font-bold">
                      <span>Total Devengado:</span>
                      <span><Money value={activeReceipt.grossTotal} /></span>
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
                      <span><Money value={activeReceipt.inssLaboral} /></span>
                    </div>
                    <div className="flex justify-between">
                      <span>IR Salarial (Ley 822):</span>
                      <span><Money value={activeReceipt.incomeTax} /></span>
                    </div>
                    {activeReceipt.otherDeductions > 0 && (
                      <div className="flex justify-between">
                        <span>Otras Deducciones:</span>
                        <span><Money value={activeReceipt.otherDeductions} /></span>
                      </div>
                    )}
                    <div className="flex justify-between border-t pt-1 font-bold">
                      <span>Total Retenciones:</span>
                      <span><Money value={activeReceipt.totalDeductions} /></span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="mt-6 border-t-2 border-b-2 py-3 flex items-center justify-between font-black text-sm">
                <span>NETO LÍQUIDO A RECIBIR:</span>
                <span className="text-base"><Money value={activeReceipt.netPay} /></span>
              </div>

              <div className="mt-12 grid grid-cols-2 gap-8 text-center text-[10px]">
                <div className="border-t pt-2">
                  <p className="font-bold">Instalaciones Raquel S.A.</p>
                  <p className="text-slate-400 print:text-black">Firma y Sello Autorizado</p>
                </div>
                <div className="border-t pt-2">
                  <p className="font-bold">{activeReceipt.employeeName}</p>
                  <p className="text-slate-400 print:text-black">Recibí Conforme (Cédula)</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      {/* Modal: Editar Colaborador */}
      {editingEmployee && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <form
            onSubmit={submitEditEmployee}
            className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900 space-y-4"
          >
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <div>
                <span className="text-[11px] font-bold uppercase tracking-wider text-blue-600 dark:text-blue-400">
                  Actualización de Expediente · {editingEmployee.id}
                </span>
                <h3 className="text-lg font-extrabold text-slate-900 dark:text-white">
                  {editingEmployee.name}
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setEditingEmployee(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Cargo / Posición">
                <input
                  className={inputClass}
                  required
                  value={editEmployeeDraft.position}
                  onChange={(e) => setEditEmployeeDraft({ ...editEmployeeDraft, position: e.target.value })}
                />
              </Field>

              <Field label="Área / Departamento">
                <select
                  className={inputClass}
                  value={editEmployeeDraft.area}
                  onChange={(e) => setEditEmployeeDraft({ ...editEmployeeDraft, area: e.target.value })}
                >
                  <option value="Producción">Producción</option>
                  <option value="Taller de Vidrio">Taller de Vidrio</option>
                  <option value="Taller de Aluminio">Taller de Aluminio</option>
                  <option value="Ventas">Ventas</option>
                  <option value="Compras">Compras</option>
                  <option value="Contabilidad">Contabilidad</option>
                  <option value="Inventario">Inventario</option>
                  <option value="Gerencia">Gerencia</option>
                </select>
              </Field>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Salario mensual (C$)">
                <input
                  type="number"
                  step="0.01"
                  className={inputClass}
                  value={editEmployeeDraft.salary}
                  onChange={(e) => setEditEmployeeDraft({ ...editEmployeeDraft, salary: e.target.value })}
                />
              </Field>

              <Field label="Estado laboral">
                <select
                  className={inputClass}
                  value={editEmployeeDraft.employmentStatus}
                  onChange={(e) => setEditEmployeeDraft({ ...editEmployeeDraft, employmentStatus: e.target.value })}
                >
                  <option value="activo">Activo</option>
                  <option value="licencia">En licencia</option>
                  <option value="baja">Baja</option>
                </select>
              </Field>
            </div>

            <p className="text-[11px] text-slate-400">
              * La actualización genera un registro en el historial laboral auditable del colaborador (dbo.HrEmployeeJobHistory).
            </p>

            <div className="flex items-center justify-end gap-2 pt-2 border-t dark:border-white/10">
              <Button type="button" variant="secondary" onClick={() => setEditingEmployee(null)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={busy}>
                Guardar cambios
              </Button>
            </div>
          </form>
        </div>
      )}

      {/* Modal: Nuevo Contrato Laboral */}
      {showCreateContractModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <form
            onSubmit={submitCreateContract}
            className="w-full max-w-xl rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900 space-y-4"
          >
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <h3 className="text-lg font-extrabold text-slate-900 dark:text-white">
                Formalizar Nuevo Contrato Laboral
              </h3>
              <button
                type="button"
                onClick={() => setShowCreateContractModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {modalError && (
              <div className="rounded-lg border border-rose-300 bg-rose-50 p-2.5 text-xs text-rose-900 dark:border-rose-900/50 dark:bg-rose-950/40 dark:text-rose-200">
                {modalError}
              </div>
            )}

            {employees.length === 0 ? (
              <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-xs text-amber-900 dark:border-amber-900/50 dark:bg-amber-950/40 dark:text-amber-200 space-y-2">
                <p className="font-bold">No hay colaboradores registrados en el Directorio.</p>
                <p>Para formalizar un contrato laboral individual, primero debes registrar al colaborador en Talento Humano.</p>
                <div className="pt-2">
                  <Button
                    type="button"
                    variant="primary"
                    onClick={() => {
                      setShowCreateContractModal(false);
                      setShowCreateEmployeeModal(true);
                    }}
                    className="text-xs"
                  >
                    Ir a Alta de Personal
                  </Button>
                </div>
              </div>
            ) : (
              <>
                <div className="grid gap-3 sm:grid-cols-2">
                  <Field label="Colaborador">
                    <select
                      required
                      className={inputClass}
                      value={contractDraft.employeeId}
                      onChange={(e) => {
                        const emp = employees.find((x) => x.id === e.target.value);
                        setContractDraft({
                          ...contractDraft,
                          employeeId: e.target.value,
                          position: emp ? emp.position : contractDraft.position
                        });
                      }}
                    >
                      <option value="">-- Seleccionar colaborador --</option>
                      {employees.map((emp) => (
                        <option key={emp.id} value={emp.id}>
                          {emp.name} ({emp.id} · {emp.position})
                        </option>
                      ))}
                    </select>
                  </Field>

                  <Field label="Modalidad de contrato">
                    <select
                      className={inputClass}
                      value={contractDraft.contractType}
                      onChange={(e) => setContractDraft({ ...contractDraft, contractType: e.target.value as any })}
                    >
                      <option value="indefinido">Tiempo Indeterminado (Ley 185)</option>
                      <option value="determinado">Plazo Determinado</option>
                      <option value="obra_servicio">Obra o Servicio Determinado</option>
                      <option value="periodo_prueba">Período de Prueba (30 días)</option>
                    </select>
                  </Field>
                </div>

                <div className="grid gap-3 sm:grid-cols-2">
                  <Field label="Cargo estipulado">
                    <input
                      required
                      className={inputClass}
                      value={contractDraft.position}
                      onChange={(e) => setContractDraft({ ...contractDraft, position: e.target.value })}
                    />
                  </Field>

                  <Field label="Jornada pactada">
                    <input
                      required
                      className={inputClass}
                      value={contractDraft.workSchedule}
                      onChange={(e) => setContractDraft({ ...contractDraft, workSchedule: e.target.value })}
                    />
                  </Field>
                </div>

                <div className="grid gap-3 sm:grid-cols-2">
                  <Field label="Fecha de inicio">
                    <input
                      type="date"
                      required
                      className={inputClass}
                      value={contractDraft.startDate}
                      onChange={(e) => setContractDraft({ ...contractDraft, startDate: e.target.value })}
                    />
                  </Field>

                  <Field label="Fecha fin (opcional si es indeterminado)">
                    <input
                      type="date"
                      className={inputClass}
                      value={contractDraft.endDate}
                      onChange={(e) => setContractDraft({ ...contractDraft, endDate: e.target.value })}
                    />
                  </Field>
                </div>

                <Field label="Referencia documental / Expediente físico (opcional)">
                  <input
                    className={inputClass}
                    placeholder="ej. EXP-CT-2026-004 o archivador legal"
                    value={contractDraft.docReference}
                    onChange={(e) => setContractDraft({ ...contractDraft, docReference: e.target.value })}
                  />
                </Field>

                <Field label="Términos y cláusulas acordadas">
                  <textarea
                    required
                    maxLength={2000}
                    className={`${inputClass} h-20 py-2`}
                    value={contractDraft.agreedTerms}
                    onChange={(e) => setContractDraft({ ...contractDraft, agreedTerms: e.target.value })}
                  />
                </Field>

                <div className="flex items-center justify-end gap-2 pt-2 border-t dark:border-white/10">
                  <Button type="button" variant="secondary" onClick={() => setShowCreateContractModal(false)}>
                    Cancelar
                  </Button>
                  <Button type="submit" disabled={busy || !contractDraft.employeeId}>
                    {busy ? "Registrando en SQL..." : "Registrar contrato"}
                  </Button>
                </div>
              </>
            )}
          </form>
        </div>
      )}

      {/* Modal: Registrar Marcación / Asistencia */}
      {showCreateAttendanceModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <form
            onSubmit={submitCreateAttendance}
            className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900 space-y-4"
          >
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <h3 className="text-lg font-extrabold text-slate-900 dark:text-white">
                Registrar Marcación de Jornada
              </h3>
              <button
                type="button"
                onClick={() => setShowCreateAttendanceModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Colaborador">
                <select
                  required
                  className={inputClass}
                  value={newAttendanceDraft.employeeId}
                  onChange={(e) => setNewAttendanceDraft({ ...newAttendanceDraft, employeeId: e.target.value })}
                >
                  <option value="">-- Seleccionar colaborador --</option>
                  {employees.map((emp) => (
                    <option key={emp.id} value={emp.id}>
                      {emp.name} ({emp.id})
                    </option>
                  ))}
                </select>
              </Field>

              <Field label="Fecha de la jornada">
                <input
                  type="date"
                  required
                  className={inputClass}
                  value={newAttendanceDraft.recordDate}
                  onChange={(e) => setNewAttendanceDraft({ ...newAttendanceDraft, recordDate: e.target.value })}
                />
              </Field>
            </div>

            <div className="grid gap-3 sm:grid-cols-3">
              <Field label="Turno / Horario">
                <input
                  required
                  className={inputClass}
                  value={newAttendanceDraft.shiftName}
                  onChange={(e) => setNewAttendanceDraft({ ...newAttendanceDraft, shiftName: e.target.value })}
                />
              </Field>

              <Field label="Hora entrada real">
                <input
                  type="time"
                  required
                  className={inputClass}
                  value={newAttendanceDraft.actualIn}
                  onChange={(e) => setNewAttendanceDraft({ ...newAttendanceDraft, actualIn: e.target.value })}
                />
              </Field>

              <Field label="Hora salida real">
                <input
                  type="time"
                  required
                  className={inputClass}
                  value={newAttendanceDraft.actualOut}
                  onChange={(e) => setNewAttendanceDraft({ ...newAttendanceDraft, actualOut: e.target.value })}
                />
              </Field>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Incidencia">
                <select
                  className={inputClass}
                  value={newAttendanceDraft.incidentType}
                  onChange={(e) => setNewAttendanceDraft({ ...newAttendanceDraft, incidentType: e.target.value as any })}
                >
                  <option value="ninguna">Sin incidencia (Jornada normal)</option>
                  <option value="tardanza">Tardanza justificada/injustificada</option>
                  <option value="salida_anticipada">Salida anticipada autorizada</option>
                  <option value="permiso_oficial">Permiso oficial</option>
                  <option value="falta_justificada">Falta justificada</option>
                  <option value="falta_injustificada">Falta injustificada</option>
                </select>
              </Field>

              <Field label="Observaciones o notas">
                <input
                  className={inputClass}
                  placeholder="ej. Jornada completa de corte en taller..."
                  value={newAttendanceDraft.incidentNotes}
                  onChange={(e) => setNewAttendanceDraft({ ...newAttendanceDraft, incidentNotes: e.target.value })}
                />
              </Field>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t dark:border-white/10">
              <Button type="button" variant="secondary" onClick={() => setShowCreateAttendanceModal(false)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={busy || !newAttendanceDraft.employeeId}>
                Guardar marcación
              </Button>
            </div>
          </form>
        </div>
      )}

      {/* Modal: Entrega de EPP (Ley 618) */}
      {showDeliverEppModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <form
            onSubmit={submitDeliverEpp}
            className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900 space-y-4"
          >
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <div>
                <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-400">
                  Higiene y Seguridad Ocupacional · Ley 618
                </span>
                <h3 className="text-lg font-extrabold text-slate-900 dark:text-white">
                  Acta de Entrega de EPP Especializado
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setShowDeliverEppModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Colaborador beneficiario">
                <select
                  required
                  className={inputClass}
                  value={deliverEppDraft.employeeId}
                  onChange={(e) => setDeliverEppDraft({ ...deliverEppDraft, employeeId: e.target.value })}
                >
                  <option value="">-- Seleccionar colaborador --</option>
                  {employees.map((emp) => (
                    <option key={emp.id} value={emp.id}>
                      {emp.name} ({emp.position})
                    </option>
                  ))}
                </select>
              </Field>

              <Field label="Equipo de protección (Catálogo)">
                <select
                  required
                  className={inputClass}
                  value={deliverEppDraft.equipmentId}
                  onChange={(e) => setDeliverEppDraft({ ...deliverEppDraft, equipmentId: e.target.value })}
                >
                  <option value="">-- Seleccionar equipo --</option>
                  {safetyEquipment.map((eq) => (
                    <option key={eq.id} value={eq.id}>
                      {eq.name} ({eq.standardNorm})
                    </option>
                  ))}
                </select>
              </Field>
            </div>

            <div className="grid gap-3 sm:grid-cols-3">
              <Field label="Tipo de dotación">
                <select
                  className={inputClass}
                  value={deliverEppDraft.deliveryType}
                  onChange={(e) => setDeliverEppDraft({ ...deliverEppDraft, deliveryType: e.target.value as any })}
                >
                  <option value="dotacion_inicial">Dotación inicial</option>
                  <option value="reposicion_desgaste">Reposición por desgaste</option>
                  <option value="reposicion_dano">Reposición por daño</option>
                </select>
              </Field>

              <Field label="Fecha de entrega">
                <input
                  type="date"
                  required
                  className={inputClass}
                  value={deliverEppDraft.deliveryDate}
                  onChange={(e) => setDeliverEppDraft({ ...deliverEppDraft, deliveryDate: e.target.value })}
                />
              </Field>

              <Field label="Próxima reposición">
                <input
                  type="date"
                  className={inputClass}
                  value={deliverEppDraft.nextReplacementDate}
                  onChange={(e) => setDeliverEppDraft({ ...deliverEppDraft, nextReplacementDate: e.target.value })}
                />
              </Field>
            </div>

            <Field label="Observaciones y constancia de conformidad">
              <input
                className={inputClass}
                value={deliverEppDraft.notes}
                onChange={(e) => setDeliverEppDraft({ ...deliverEppDraft, notes: e.target.value })}
              />
            </Field>

            <p className="text-[11px] text-slate-400">
              * De conformidad con el Arto. 18 de la Ley 618, todos los equipos de protección individual son de suministro obligatorio y gratuito.
            </p>

            <div className="flex items-center justify-end gap-2 pt-2 border-t dark:border-white/10">
              <Button type="button" variant="secondary" onClick={() => setShowDeliverEppModal(false)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={busy || !deliverEppDraft.employeeId || !deliverEppDraft.equipmentId}>
                Registrar entrega de EPP
              </Button>
            </div>
          </form>
        </div>
      )}

      {/* Modal: Registrar Capacitación de Seguridad (Ley 618) */}
      {showCreateTrainingModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <form
            onSubmit={submitCreateTraining}
            className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900 space-y-4"
          >
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <h3 className="text-lg font-extrabold text-slate-900 dark:text-white">
                Registrar Capacitación de Seguridad (Ley 618)
              </h3>
              <button
                type="button"
                onClick={() => setShowCreateTrainingModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {modalError && (
              <div className="rounded-lg border border-rose-300 bg-rose-50 p-2.5 text-xs text-rose-900 dark:border-rose-900/50 dark:bg-rose-950/40 dark:text-rose-200">
                {modalError}
              </div>
            )}

            <Field label="Tema de capacitación">
              <input
                required
                className={inputClass}
                placeholder="ej. Manejo seguro de tronzadoras y corte de perfiles"
                value={trainingDraft.topic}
                onChange={(e) => setTrainingDraft({ ...trainingDraft, topic: e.target.value })}
              />
            </Field>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Instructor / Facilitador">
                <input
                  required
                  className={inputClass}
                  placeholder="ej. Ing. Inspector de Seguridad MITRAB"
                  value={trainingDraft.instructor}
                  onChange={(e) => setTrainingDraft({ ...trainingDraft, instructor: e.target.value })}
                />
              </Field>

              <Field label="Fecha de realización">
                <input
                  type="date"
                  required
                  className={inputClass}
                  value={trainingDraft.trainingDate}
                  onChange={(e) => setTrainingDraft({ ...trainingDraft, trainingDate: e.target.value })}
                />
              </Field>
            </div>

            <div className="grid gap-3 sm:grid-cols-3">
              <Field label="Horas de duración">
                <input
                  type="number"
                  min="1"
                  max="100"
                  required
                  className={inputClass}
                  value={trainingDraft.hours}
                  onChange={(e) => setTrainingDraft({ ...trainingDraft, hours: Number(e.target.value) })}
                />
              </Field>

              <Field label="Área objetivo">
                <input
                  className={inputClass}
                  value={trainingDraft.targetArea}
                  onChange={(e) => setTrainingDraft({ ...trainingDraft, targetArea: e.target.value })}
                />
              </Field>

              <Field label="Referencia legal">
                <input
                  className={inputClass}
                  value={trainingDraft.legalRef}
                  onChange={(e) => setTrainingDraft({ ...trainingDraft, legalRef: e.target.value })}
                />
              </Field>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t dark:border-white/10">
              <Button type="button" variant="secondary" onClick={() => setShowCreateTrainingModal(false)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={busy}>
                {busy ? "Guardando..." : "Registrar capacitación"}
              </Button>
            </div>
          </form>
        </div>
      )}

      {/* Modal: Registrar Acción Correctiva de Seguridad */}
      {showCreateActionModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
          <form
            onSubmit={submitCreateAction}
            className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900 space-y-4"
          >
            <div className="flex items-center justify-between border-b pb-3 dark:border-white/10">
              <h3 className="text-lg font-extrabold text-slate-900 dark:text-white">
                Registrar Acción Correctiva de Seguridad
              </h3>
              <button
                type="button"
                onClick={() => setShowCreateActionModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {modalError && (
              <div className="rounded-lg border border-rose-300 bg-rose-50 p-2.5 text-xs text-rose-900 dark:border-rose-900/50 dark:bg-rose-950/40 dark:text-rose-200">
                {modalError}
              </div>
            )}

            <Field label="Descripción de la medida correctiva">
              <textarea
                required
                maxLength={1000}
                className={`${inputClass} h-24 py-2`}
                placeholder="Detalla la acción correctiva acordada según la inspección o incidente..."
                value={actionDraft.description}
                onChange={(e) => setActionDraft({ ...actionDraft, description: e.target.value })}
              />
            </Field>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Responsable de ejecución">
                <input
                  required
                  className={inputClass}
                  placeholder="ej. Carlos Producción"
                  value={actionDraft.responsibleName}
                  onChange={(e) => setActionDraft({ ...actionDraft, responsibleName: e.target.value })}
                />
              </Field>

              <Field label="Fecha límite de cumplimiento">
                <input
                  type="date"
                  required
                  className={inputClass}
                  value={actionDraft.dueDate}
                  onChange={(e) => setActionDraft({ ...actionDraft, dueDate: e.target.value })}
                />
              </Field>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t dark:border-white/10">
              <Button type="button" variant="secondary" onClick={() => setShowCreateActionModal(false)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={busy}>
                {busy ? "Guardando..." : "Registrar acción"}
              </Button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
