import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { AlertTriangle, ArrowDownCircle, ArrowUpCircle, Banknote, Landmark, Lock, RefreshCw, ShieldCheck } from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { authenticatedFetch, formatApiErrorMessage, parseApiResponse } from "../auth/apiSession";
import { Button } from "../components/Button";
import { Field, inputClass, Money, PageHeader, StatusPill } from "../components/Ui";
import { useErp } from "../store/erpStore";
import { cashSessionBlock, explicitCashCount } from "../lib/cashReadiness";

type Account = "caja" | "banco";

type CashMovement = {
  id: string;
  account: Account;
  date: string;
  time?: string | null;
  type: "entrada" | "salida";
  entry?: number | null;
  exit?: number | null;
  balance?: number | null;
  concept: string;
  method?: string | null;
  documentType?: string | null;
  documentRef?: string | null;
  saleId?: string | null;
  purchaseId?: string | null;
  payrollRunId?: string | null;
  sessionId?: string | null;
  responsible?: string | null;
  operationKey?: string | null;
};

type CashSummary = {
  saldoAnterior: number;
  aperturas: number;
  saldoInicial: number;
  entradas: number;
  salidas: number;
  saldoFinal: number;
  movimientos: number;
};

type CashSession = {
  id: string;
  account: Account;
  currency: string;
  sessionDate: string;
  openingBalance: number;
  status: "abierta" | "cerrada";
  openedAt: string;
  openedByName?: string | null;
  closedAt?: string | null;
  countedCash?: number | null;
  expectedCash?: number | null;
  difference?: number | null;
  explanation?: string | null;
  reviewStatus?: "pendiente_revision" | "revisado" | "observado" | null;
  reviewedByName?: string | null;
  reviewedAt?: string | null;
  movements: number;
};

// Arrastre sugerido del saldo: el saldo final de la ultima sesion cerrada de la
// cuenta (o el saldo vivo de la sesion abierta) que se propone como saldo inicial
// al abrir la nueva sesion. Es solo una sugerencia ajustable.
type SuggestedOpening = {
  account: Account;
  amount: number;
  origin: "sesion_cerrada" | "sesion_abierta" | "sin_sesion";
  sourceSessionId?: string | null;
  closedAt?: string | null;
};

const METHODS: Array<{ value: string; label: string; account: Account }> = [
  { value: "efectivo", label: "Efectivo", account: "caja" },
  { value: "transferencia", label: "Transferencia bancaria", account: "banco" },
  { value: "cheque", label: "Cheque", account: "banco" },
  { value: "tarjeta", label: "Tarjeta", account: "banco" },
  { value: "otro", label: "Otro medio bancario", account: "banco" }
];

const DOCUMENT_TYPES = [
  { value: "venta", label: "Venta / factura" },
  { value: "cobro", label: "Cobro de cliente" },
  { value: "anticipo", label: "Anticipo" },
  { value: "compra", label: "Compra" },
  { value: "pago_proveedor", label: "Pago a proveedor" },
  { value: "ajuste", label: "Ajuste" },
  { value: "otro", label: "Otro" }
];

function newOperationKey(): string {
  const cryptoApi = globalThis.crypto;
  if (cryptoApi && typeof cryptoApi.randomUUID === "function") return cryptoApi.randomUUID();
  return `op-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 12)}`;
}

function formatDate(value?: string | null): string {
  if (!value) return "—";
  const iso = String(value).slice(0, 10);
  const [year, month, day] = iso.split("-");
  if (!year || !month || !day) return "—";
  return `${day}/${month}/${year}`;
}

function formatDateTime(value?: string | null): string {
  if (!value) return "—";
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return formatDate(value);
  return parsed.toLocaleString("es-NI", { dateStyle: "short", timeStyle: "short" });
}

function todayIso(): string {
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${now.getFullYear()}-${month}-${day}`;
}

function monthStartIso(): string {
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  return `${now.getFullYear()}-${month}-01`;
}

function methodLabel(value?: string | null): string {
  return METHODS.find((item) => item.value === value)?.label ?? (value === "apertura" ? "Saldo inicial" : value || "—");
}

function documentLabel(value?: string | null): string {
  return DOCUMENT_TYPES.find((item) => item.value === value)?.label ?? (value === "apertura" ? "Apertura de caja" : value || "—");
}

function movementAccountFor(method: string): Account {
  return method === "efectivo" ? "caja" : "banco";
}

export function CashWorkspace({ account }: { account: Account }) {
  const { db } = useErp();
  const { user, can } = useAuth();
  const [connected, setConnected] = useState(false);
  const loadGeneration = useRef(0);
  const canWrite = connected && can(account === "caja" ? "caja" : "bancos", "write");
  const accountMethods = METHODS.filter((method) => method.account === account);
  const canSupervise = connected
    && (user?.hierarchy === "superadmin"
      || (user?.hierarchy === "administrador" && (user?.areas ?? []).some((area) => area === "finanzas" || area === "contabilidad")));

  const [from, setFrom] = useState(monthStartIso);
  const [to, setTo] = useState(todayIso);
  const [movements, setMovements] = useState<CashMovement[]>([]);
  const [summary, setSummary] = useState<CashSummary | null>(null);
  const [sessions, setSessions] = useState<CashSession[]>([]);
  const [businessDate, setBusinessDate] = useState<string | null>(null);
  const [suggestedOpening, setSuggestedOpening] = useState<SuggestedOpening | null>(null);
  const [loading, setLoading] = useState(connected);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<string | null>(null);
  const [showOpenForm, setShowOpenForm] = useState(false);
  const [movementType, setMovementType] = useState<"entrada" | "salida">("entrada");
  const movementFormRef = useRef<HTMLFormElement>(null);
  const sessionSectionRef = useRef<HTMLElement>(null);
  const ledgerSectionRef = useRef<HTMLElement>(null);
  const [reviewNotes, setReviewNotes] = useState("");
  const [countedCash, setCountedCash] = useState("");
  const [explanation, setExplanation] = useState("");
  const [openingBalance, setOpeningBalance] = useState("");

  // Claves de idempotencia: se generan una vez por intento; un doble clic o un
  // reintento reutiliza la misma clave y el servidor devuelve la misma operación.
  const keys = useRef({ movement: newOperationKey(), opening: newOperationKey() });

  const openSession = useMemo(
    () => sessions.find((session) => session.account === account && session.status === "abierta") ?? null,
    [sessions, account]
  );
  const lastClosedPending = useMemo(
    () => sessions.find((session) => session.account === account && session.status === "cerrada" && session.reviewStatus === "pendiente_revision") ?? null,
    [sessions, account]
  );
  const sessionBlock = cashSessionBlock(openSession?.sessionDate, businessDate);
  const canRegister = canWrite && !sessionBlock && !loading;

  const beginMovement = (type: "entrada" | "salida") => {
    if (!canWrite || busy) return;
    setMovementType(type);
    if (openSession && sessionBlock) {
      setError(sessionBlock);
      sessionSectionRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
      return;
    }
    if (!openSession) {
      setShowOpenForm(true);
      sessionSectionRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
      return;
    }
    movementFormRef.current?.scrollIntoView({ behavior: "smooth", block: "center" });
    const amount = movementFormRef.current?.elements.namedItem("amount");
    if (amount instanceof HTMLInputElement) amount.focus({ preventScroll: true });
  };

  const load = useCallback(async () => {
    if (!user) {
      setLoading(false);
      return;
    }
    const generation = ++loadGeneration.current;
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({ account });
      if (from) params.set("from", from);
      if (to) params.set("to", to);

      const [movementResponse, summaryResponse, sessionResponse] = await Promise.all([
        authenticatedFetch(`/api/cash/movements?${params.toString()}`),
        authenticatedFetch(`/api/cash/summary?${params.toString()}`),
        authenticatedFetch(`/api/cash/sessions?account=${account}`)
      ]);

      const movementData = await parseApiResponse<{ movements: CashMovement[] }>(movementResponse);
      const summaryData = await parseApiResponse<CashSummary>(summaryResponse);
      const sessionData = await parseApiResponse<{ sessions: CashSession[]; businessDate: string; suggestedOpening?: SuggestedOpening | null }>(sessionResponse);

      if (generation !== loadGeneration.current) return;
      setConnected(true);
      setMovements(movementData.movements ?? []);
      setSummary(summaryData);
      setSessions(sessionData.sessions ?? []);
      setBusinessDate(sessionData.businessDate ?? null);
      setSuggestedOpening(sessionData.suggestedOpening ?? null);
    } catch (err) {
      if (generation !== loadGeneration.current) return;
      setConnected(false);
      const formatted = formatApiErrorMessage(err);
      setError(formatted.message);
    } finally {
      if (generation === loadGeneration.current) setLoading(false);
    }
  }, [account, user?.id, from, to]);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    const refresh = () => { if (!busy) void load(); };
    window.addEventListener("online", refresh);
    window.addEventListener("focus", refresh);
    return () => {
      window.removeEventListener("online", refresh);
      window.removeEventListener("focus", refresh);
    };
  }, [load, busy]);

  // Al abrir el formulario de apertura, se precarga el saldo sugerido (arrastre de
  // la sesion anterior). El responsable puede ajustarlo con su conteo real: es una
  // sugerencia, no un valor forzado.
  useEffect(() => {
    if (showOpenForm) {
      setOpeningBalance(suggestedOpening ? String(suggestedOpening.amount) : "");
    }
  }, [showOpenForm, suggestedOpening]);

  // Sin conexión se muestra el libro local en modo lectura: el saldo y el arqueo
  // solo se consideran válidos cuando los confirma SQL Server.
  const offlineRows = useMemo(() => {
    const rows = db.cash.filter((item) => item.account === account);
    let running = 0;
    return rows
      .slice()
      .sort((a, b) => a.date.localeCompare(b.date))
      .map((item) => {
        running += item.type === "entrada" ? item.amount : -item.amount;
        return {
          id: item.id,
          account,
          date: item.date,
          type: item.type,
          entry: item.type === "entrada" ? item.amount : null,
          exit: item.type === "salida" ? item.amount : null,
          balance: running,
          concept: item.concept,
          method: item.type === "entrada" ? "efectivo" : "efectivo",
          documentType: "otro",
          responsible: "Registro local",
          operationKey: null
        } as CashMovement;
      })
      .reverse();
  }, [account, db.cash]);

  const rows = connected ? movements : offlineRows;
  const cards = connected
    ? summary ?? { saldoAnterior: 0, aperturas: 0, saldoInicial: 0, entradas: 0, salidas: 0, saldoFinal: 0, movimientos: 0 }
    : {
        saldoAnterior: 0,
        aperturas: 0,
        saldoInicial: 0,
        entradas: offlineRows.filter((row) => row.type === "entrada").reduce((total, row) => total + Number(row.entry ?? 0), 0),
        salidas: offlineRows.filter((row) => row.type === "salida").reduce((total, row) => total + Number(row.exit ?? 0), 0),
        saldoFinal: offlineRows[0]?.balance ?? 0,
        movimientos: offlineRows.length
      };

  const submitMovement = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!canRegister || busy) return;
    const form = event.currentTarget;
    const data = new FormData(form);
    const method = String(data.get("method") ?? "efectivo");
    const methodAccount = movementAccountFor(method);

    if (methodAccount !== account) {
      setError(`El medio «${methodLabel(method)}» afecta ${methodAccount === "caja" ? "la caja de efectivo" : "la cuenta bancaria"}. Registra el movimiento en ${methodAccount}.`);
      return;
    }

    const amount = Number(data.get("amount"));
    if (!Number.isFinite(amount) || amount <= 0) {
      setError("El importe debe ser mayor que cero: el tipo de movimiento (entrada o salida) determina el efecto.");
      return;
    }

    setBusy("movement");
    setError(null);
    setNotice(null);
    try {
      const response = await authenticatedFetch("/api/cash/movements", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          operationKey: keys.current.movement,
          account,
          sessionId: openSession?.id,
          type: String(data.get("type") ?? "entrada"),
          amount,
          concept: String(data.get("concept") ?? ""),
          method,
          documentType: String(data.get("documentType") ?? "ajuste") || "ajuste",
          documentRef: String(data.get("documentRef") ?? "") || null
        })
      });
      const payload = await parseApiResponse<{ repeated: boolean; message: string; operationKey: string }>(response);
      setNotice(payload.message);
      keys.current.movement = newOperationKey();
      form.reset();
      await load();
    } catch (err) {
      // La clave se conserva a propósito: si el usuario reintenta, el servidor
      // devuelve la misma operación en lugar de crear un segundo movimiento.
      const formatted = formatApiErrorMessage(err);
      setError(formatted.message);
    } finally {
      setBusy(null);
    }
  };

  const openCash = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!canWrite) return;
    const form = event.currentTarget;
    const data = new FormData(form);
    const initialBalance = explicitCashCount(String(data.get("initialBalance") ?? ""));

    if (initialBalance === null) {
      setError("Indica el saldo inicial contado, con hasta dos decimales. Escribe 0 si la caja está vacía.");
      return;
    }

    setBusy("open");
    setError(null);
    setNotice(null);
    try {
      const response = await authenticatedFetch("/api/cash/sessions", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          operationKey: keys.current.opening,
          account,
          currency: "C$",
          initialBalance,
          notes: String(data.get("notes") ?? "") || null
        })
      });
      const payload = await parseApiResponse<{ repeated: boolean; message: string }>(response);
      setNotice(payload.message);
      keys.current.opening = newOperationKey();
      form.reset();
      setOpeningBalance("");
      setShowOpenForm(false);
      await load();
    } catch (err) {
      const formatted = formatApiErrorMessage(err);
      setError(formatted.message);
    } finally {
      setBusy(null);
    }
  };

  const closeSession = async () => {
    if (!openSession || !canSupervise) return;
    const counted = explicitCashCount(countedCash);
    if (counted === null) {
      setError("Indica el efectivo contado en el arqueo (no puede ser negativo).");
      return;
    }

    setBusy("close");
    setError(null);
    setNotice(null);
    try {
      const response = await authenticatedFetch(`/api/cash/sessions/${openSession.id}/close`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ countedCash: counted, explanation: explanation || null })
      });
      const payload = await parseApiResponse<{ message: string }>(response);
      setNotice(payload.message);
      setCountedCash("");
      setExplanation("");
      await load();
    } catch (err) {
      const formatted = formatApiErrorMessage(err);
      setError(formatted.message);
    } finally {
      setBusy(null);
    }
  };

  const reviewSession = async (decision: "revisado" | "observado") => {
    if (!lastClosedPending || !canSupervise) return;
    setBusy("review");
    setError(null);
    setNotice(null);
    try {
      const response = await authenticatedFetch(`/api/cash/sessions/${lastClosedPending.id}/review`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ decision, notes: reviewNotes || null })
      });
      const payload = await parseApiResponse<{ message: string }>(response);
      setNotice(payload.message);
      setReviewNotes("");
      await load();
    } catch (err) {
      const formatted = formatApiErrorMessage(err);
      setError(formatted.message);
    } finally {
      setBusy(null);
    }
  };

  const AccountIcon = account === "caja" ? Banknote : Landmark;

  return (
    <div className="space-y-5">
      <PageHeader
        kicker={account === "caja" ? "Tesorería y Caja Chica" : "Cuentas Bancarias"}
        title={account === "caja" ? "Apertura, movimientos y arqueo de caja" : "Movimientos y conciliación bancaria"}
        subtitle="Saldo inicial identificado + entradas - salidas = saldo final. Cada movimiento se confirma una sola vez en SQL Server."
      />

      {!connected && (
        <div className="flex items-start gap-2 rounded-2xl border border-amber-300 bg-amber-50 p-3 text-xs text-amber-800 dark:border-amber-700/50 dark:bg-amber-950/30 dark:text-amber-200">
          <AlertTriangle size={16} className="mt-0.5 shrink-0" />
          <p>
            No se pudo confirmar la consulta de Caja en SQL Server: se muestra el libro local sin verificar, en modo lectura. No se registran movimientos,
            arqueos ni cierres porque el saldo acumulado y la idempotencia solo los garantiza el servidor.
          </p>
        </div>
      )}

      {connected && !canWrite && (
        <div className="flex items-start gap-2 rounded-2xl border border-amber-300 bg-amber-50 p-3 text-xs text-amber-800 dark:border-amber-700/50 dark:bg-amber-950/30 dark:text-amber-200">
          <AlertTriangle size={16} className="mt-0.5 shrink-0" />
          <p>
            Tu usuario <b>{user?.name ?? user?.email ?? "actual"}</b> puede consultar {account === "caja" ? "la caja" : "el banco"},
            pero no registrar movimientos: la escritura de {account === "caja" ? "caja" : "banco"} requiere pertenecer al área de
            <b> Finanzas</b>. Pide acceso a un administrador si necesitas operar esta cuenta.
          </p>
        </div>
      )}

      {error && (
        <div className="rounded-2xl border border-rose-300 bg-rose-50 p-3 text-xs font-semibold text-rose-700 dark:border-rose-800/50 dark:bg-rose-950/30 dark:text-rose-200">
          {error}
        </div>
      )}
      {notice && (
        <div className="rounded-2xl border border-emerald-300 bg-emerald-50 p-3 text-xs font-semibold text-emerald-700 dark:border-emerald-800/50 dark:bg-emerald-950/30 dark:text-emerald-200">
          {notice}
        </div>
      )}

      {connected && openSession && sessionBlock && (
        <div role="alert" className="rounded-2xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950">
          <p>{sessionBlock}</p>
          <Button type="button" variant="secondary" className="mt-2" onClick={() => sessionSectionRef.current?.scrollIntoView({ behavior: "smooth", block: "start" })}>Ir al arqueo y cierre</Button>
        </div>
      )}

      {/* Filtro de período: el saldo anterior al inicio se toma de SQL Server */}
      <div className="flex flex-wrap items-end gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <div className="flex items-center gap-2 text-xs font-bold uppercase text-slate-500">
          <AccountIcon size={16} /> {account === "caja" ? "Caja" : "Banco"}
        </div>
        <Field label="Desde">
          <input type="date" value={from} onChange={(event) => setFrom(event.target.value)} className={inputClass} />
        </Field>
        <Field label="Hasta">
          <input type="date" value={to} onChange={(event) => setTo(event.target.value)} className={inputClass} />
        </Field>
        <Button type="button" variant="secondary" onClick={() => void load()} disabled={loading}>
          <RefreshCw size={14} className={loading ? "animate-spin" : ""} /> Actualizar
        </Button>
        <Button
          type="button"
          variant="ghost"
          onClick={() => {
            setFrom(monthStartIso());
            setTo(todayIso());
          }}
        >
          Este mes
        </Button>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
          <p className="text-[11px] font-bold uppercase text-slate-400">Base del período</p>
          <div className="mt-1 text-xl font-black text-slate-700 dark:text-slate-300">
            <Money value={cards.saldoInicial} />
          </div>
          <p className="mt-0.5 text-[10px] text-slate-400">
            Anterior <Money value={cards.saldoAnterior} /> + ajuste por aperturas <Money value={cards.aperturas} />
          </p>
          <Button
            type="button" variant="secondary" className="mt-3 w-full"
            disabled={Boolean(busy) || (!openSession && !canWrite)}
            onClick={() => {
              if (!openSession) setShowOpenForm(true);
              sessionSectionRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
            }}
          >
            <Lock size={14} /> {openSession ? "Ver apertura" : "Registrar saldo inicial"}
          </Button>
        </div>

        <div className="rounded-2xl border border-emerald-200 bg-emerald-50/60 p-4 shadow-soft dark:border-emerald-900/40 dark:bg-emerald-950/20">
          <p className="text-[11px] font-bold uppercase text-emerald-700 dark:text-emerald-400">(+) Entradas</p>
          <div className="mt-1 text-xl font-black text-emerald-700 dark:text-emerald-300">
            <Money value={cards.entradas} />
          </div>
          <p className="mt-0.5 text-[10px] text-emerald-600/80">Cobros, anticipos y ventas en efectivo</p>
          <Button type="button" variant="secondary" className="mt-3 w-full" disabled={!canWrite || Boolean(busy)} onClick={() => beginMovement("entrada")}><ArrowDownCircle size={14} /> Registrar entrada</Button>
        </div>

        <div className="rounded-2xl border border-rose-200 bg-rose-50/60 p-4 shadow-soft dark:border-rose-900/40 dark:bg-rose-950/20">
          <p className="text-[11px] font-bold uppercase text-rose-700 dark:text-rose-400">(-) Salidas</p>
          <div className="mt-1 text-xl font-black text-rose-700 dark:text-rose-300">
            <Money value={cards.salidas} />
          </div>
          <p className="mt-0.5 text-[10px] text-rose-600/80">Compras, proveedores y nómina</p>
          <Button type="button" variant="secondary" className="mt-3 w-full" disabled={!canWrite || Boolean(busy)} onClick={() => beginMovement("salida")}><ArrowUpCircle size={14} /> Registrar salida</Button>
        </div>

        <div className="rounded-2xl border border-brand-200 bg-gradient-to-br from-brand-50 to-white p-4 shadow-soft dark:border-brand-900/40 dark:from-brand-950/30 dark:to-slate-900">
          <p className="text-[11px] font-bold uppercase text-brand-800 dark:text-cyan-300">(=) Saldo final</p>
          <div className="mt-1 text-2xl font-black text-brand-700 dark:text-cyan-400">
            <Money value={cards.saldoFinal} />
          </div>
          <p className="mt-0.5 text-[10px] text-slate-500">
            {cards.movimientos} movimiento(s) confirmado(s) en el período
          </p>
          <Button type="button" variant="secondary" className="mt-3 w-full"
            onClick={() => ledgerSectionRef.current?.scrollIntoView({ behavior: "smooth", block: "start" })}>
            <Banknote size={14} /> Ver detalle del saldo
          </Button>
        </div>
      </div>

      {canRegister && (
        <form ref={movementFormRef} onSubmit={submitMovement} className="grid gap-3 rounded-2xl bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900 md:grid-cols-6">
          <div className="md:col-span-6">
            <h3 className="font-extrabold">{movementType === "entrada" ? "Registrar entrada" : "Registrar salida"}</h3>
            <p className="mt-1 text-xs text-slate-500">Al confirmar, el movimiento actualizará las entradas, salidas y saldo de esta cuenta.</p>
          </div>
          <Field label="Tipo">
            <select name="type" className={inputClass} value={movementType} onChange={(event) => setMovementType(event.target.value as "entrada" | "salida")}>
              <option value="entrada">Entrada (+)</option>
              <option value="salida">Salida (-)</option>
            </select>
          </Field>
          <Field label="Medio de pago">
            <select name="method" className={inputClass} defaultValue={account === "caja" ? "efectivo" : "transferencia"}>
              {accountMethods.map((method) => (
                <option key={method.value} value={method.value}>
                  {method.label}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Importe (NIO)">
            <input name="amount" type="number" min={0.01} step="0.01" required className={inputClass} placeholder="0.00" />
          </Field>
          <Field label="Concepto">
            <input name="concept" required minLength={3} maxLength={300} className={inputClass} placeholder="Ej. Cobro factura F-1042" />
          </Field>
          <Field label="Documento">
            <select name="documentType" className={inputClass} defaultValue="cobro">
              {DOCUMENT_TYPES.map((item) => (
                <option key={item.value} value={item.value}>{item.label}</option>
              ))}
            </select>
          </Field>
          <Field label="Referencia">
            <input name="documentRef" maxLength={120} className={inputClass} placeholder="F-1042 / LOTE-ACH" />
          </Field>
          <div className="md:col-span-6 flex flex-wrap items-center justify-between gap-2">
            <p className="text-[10px] text-slate-500">
              El efectivo afecta la caja; transferencia, cheque y tarjeta afectan el banco. Un solo efecto por operación.
            </p>
            <Button disabled={Boolean(busy)}>
              {movementType === "entrada" ? <ArrowDownCircle size={14} /> : <ArrowUpCircle size={14} />} {busy === "movement" ? "Guardando…" : "Confirmar movimiento"}
            </Button>
          </div>
        </form>
      )}


      {/* Apertura / sesión vigente */}
      <section ref={sessionSectionRef} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="font-extrabold text-slate-900 dark:text-white">Sesión de {account === "caja" ? "caja" : "banco"}</h3>
          {openSession ? <StatusPill tone="ok">Abierta</StatusPill> : <StatusPill tone="warn">Sin sesión abierta</StatusPill>}
        </div>

        {openSession ? (
          <div className="mt-3 grid gap-3 text-xs md:grid-cols-4">
            <div>
              <p className="text-[10px] uppercase text-slate-400">Apertura</p>
              <p className="font-bold text-slate-700 dark:text-slate-200">{formatDateTime(openSession.openedAt)}</p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-slate-400">Responsable</p>
              <p className="font-bold text-slate-700 dark:text-slate-200">{openSession.openedByName ?? "—"}</p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-slate-400">Saldo inicial</p>
              <p className="font-bold text-slate-700 dark:text-slate-200"><Money value={openSession.openingBalance} /></p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-slate-400">Movimientos</p>
              <p className="font-bold text-slate-700 dark:text-slate-200">{openSession.movements}</p>
            </div>
          </div>
        ) : (
          <div className="mt-3 space-y-3">
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Para registrar movimientos primero se identifica el saldo inicial de la sesión. Ese saldo queda como una
              operación de apertura y no se mezcla con las entradas por ventas.
            </p>
            {canWrite && (
              <div>
                <Button type="button" onClick={() => setShowOpenForm((value) => !value)}>
                  <Lock size={14} /> {showOpenForm ? "Cancelar apertura" : "Abrir caja / banco"}
                </Button>
              </div>
            )}
            {showOpenForm && canWrite && (
              <form onSubmit={openCash} className="grid gap-3 md:grid-cols-3">
                <Field label="Saldo inicial contado (NIO)">
                  <input name="initialBalance" type="number" min={0} step="0.01" required className={inputClass} placeholder="0.00" value={openingBalance} onChange={(event) => setOpeningBalance(event.target.value)} />
                </Field>
                <Field label="Observación de apertura">
                  <input name="notes" className={inputClass} placeholder="Ej. Fondo fijo de caja chica" />
                </Field>
                <div className="flex items-end">
                  <Button className="w-full" disabled={busy === "open"}>Confirmar apertura</Button>
                </div>
                <p className="md:col-span-3 text-[10px] text-slate-500">
                  {suggestedOpening && suggestedOpening.origin === "sesion_cerrada" ? (
                    <>Sugerido por arrastre: <Money value={suggestedOpening.amount} /> (saldo contado de la última sesión cerrada
                    {suggestedOpening.closedAt ? ` del ${formatDateTime(suggestedOpening.closedAt)}` : ""}). Ajústalo si tu conteo difiere.</>
                  ) : suggestedOpening && suggestedOpening.origin === "sesion_abierta" ? (
                    <>Sugerido: <Money value={suggestedOpening.amount} /> (saldo vivo de la sesión abierta de esta cuenta). Ajústalo si tu conteo difiere.</>
                  ) : (
                    <>No hay una sesión anterior cerrada en esta cuenta: captura el saldo inicial real contado. A partir de esta apertura,
                    el saldo final se arrastrará automáticamente como saldo inicial de la próxima sesión.</>
                  )}
                </p>
              </form>
            )}
          </div>
        )}

        {openSession && canSupervise && (
          <div className="mt-4 space-y-3 rounded-xl border border-slate-200 p-3 dark:border-white/10">
            <p className="text-[11px] font-bold uppercase text-slate-500">Arqueo y cierre</p>
            <div className="grid gap-3 md:grid-cols-3">
              <Field label="Efectivo contado">
                <input
                  type="number"
                  min={0}
                  step="0.01"
                  value={countedCash}
                  onChange={(event) => setCountedCash(event.target.value)}
                  className={inputClass}
                  placeholder="0.00"
                />
              </Field>
              <Field label="Explicación de la diferencia (si existe)">
                <input
                  value={explanation}
                  onChange={(event) => setExplanation(event.target.value)}
                  className={inputClass}
                  placeholder="Ej. Faltante de C$ 45 por cambio no registrado"
                />
              </Field>
              <div className="flex items-end">
                <Button type="button" onClick={() => void closeSession()} disabled={busy === "close"}>
                  Arquear y cerrar
                </Button>
              </div>
            </div>
            <p className="text-[10px] text-slate-500">
              Un faltante se registra como diferencia del arqueo y requiere explicación y revisión. Nunca se convierte
              automáticamente en un descuento al trabajador.
            </p>
          </div>
        )}

        {lastClosedPending && (
          <div className="mt-4 space-y-2 rounded-xl border border-amber-300 bg-amber-50/60 p-3 text-xs dark:border-amber-700/40 dark:bg-amber-950/20">
            <p className="font-bold text-amber-800 dark:text-amber-200">
              Arqueo pendiente de revisión ({formatDate(lastClosedPending.sessionDate)}): esperado{" "}
              <Money value={lastClosedPending.expectedCash ?? 0} />, contado <Money value={lastClosedPending.countedCash ?? 0} />,
              diferencia <Money value={lastClosedPending.difference ?? 0} />.
            </p>
            {lastClosedPending.explanation && <p className="text-amber-700 dark:text-amber-300">{lastClosedPending.explanation}</p>}
            {canSupervise && (
              <div className="flex flex-wrap items-end gap-2">
                <input
                  value={reviewNotes}
                  onChange={(event) => setReviewNotes(event.target.value)}
                  className={inputClass}
                  placeholder="Nota de revisión"
                />
                <Button type="button" onClick={() => void reviewSession("revisado")} disabled={busy === "review"}>Revisado</Button>
                <Button type="button" variant="secondary" onClick={() => void reviewSession("observado")} disabled={busy === "review"}>
                  Observado
                </Button>
              </div>
            )}
          </div>
        )}
      </section>

      {canWrite && !openSession && (
        <div className="flex items-start gap-2 rounded-2xl border border-sky-300 bg-sky-50 p-3 text-xs text-sky-900 dark:border-sky-800/50 dark:bg-sky-950/30 dark:text-sky-100">
          <Lock size={16} className="mt-0.5 shrink-0" />
          <p>
            Para registrar entradas o salidas primero abre la sesión del día con el saldo inicial contado.
            El formulario de movimientos se habilita cuando la sesión queda abierta.
          </p>
        </div>
      )}


      <section ref={ledgerSectionRef} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="font-extrabold text-slate-900 dark:text-white">
            Libro de movimientos de {account === "caja" ? "caja" : "banco"}
          </h3>
          <span className="text-[10px] text-slate-400">Orden: fecha y desempate por identificador</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left">
            <thead className="bg-slate-50 uppercase text-slate-500 dark:bg-slate-950">
              <tr>
                <th className="p-2.5">Fecha</th>
                <th className="p-2.5">Referencia</th>
                <th className="p-2.5">Concepto</th>
                <th className="p-2.5">Medio</th>
                <th className="p-2.5 text-right">Entrada</th>
                <th className="p-2.5 text-right">Salida</th>
                <th className="p-2.5 text-right">Saldo</th>
                <th className="p-2.5 text-center">Documento</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-white/5">
              {rows.length === 0 && (
                <tr>
                  <td colSpan={8} className="p-4 text-center text-slate-400">
                    {loading ? "Cargando movimientos..." : "Sin movimientos registrados en el período."}
                  </td>
                </tr>
              )}
              {rows.map((item) => (
                <tr key={item.id} className="hover:bg-slate-50/50 dark:hover:bg-white/5">
                  <td className="p-2.5 whitespace-nowrap text-slate-600 dark:text-slate-300">
                    {formatDate(item.date)}
                    {item.time && <span className="ml-1 text-[10px] text-slate-400">{String(item.time).slice(0, 5)}</span>}
                  </td>
                  <td className="p-2.5 font-mono font-bold text-brand-700 dark:text-cyan-400">
                    {item.documentRef || `MOV-${item.id.slice(-6)}`}
                  </td>
                  <td className="p-2.5 font-medium text-slate-800 dark:text-white">
                    {item.concept}
                    {item.responsible && <span className="block text-[10px] text-slate-400">Responsable: {item.responsible}</span>}
                  </td>
                  <td className="p-2.5 text-slate-500">{methodLabel(item.method)}</td>
                  <td className="p-2.5 text-right font-mono text-emerald-600">
                    {item.entry != null ? <Money value={Number(item.entry)} /> : "—"}
                  </td>
                  <td className="p-2.5 text-right font-mono text-rose-600">
                    {item.exit != null ? <Money value={Number(item.exit)} /> : "—"}
                  </td>
                  <td className="p-2.5 text-right font-mono font-black text-slate-800 dark:text-white">
                    <Money value={Number(item.balance ?? 0)} />
                  </td>
                  <td className="p-2.5 text-center">
                    <button
                      type="button"
                      className="rounded-lg border border-slate-200 px-2 py-1 text-[10px] font-bold text-slate-600 hover:bg-slate-50 dark:border-white/10 dark:text-slate-300"
                      onClick={() => setExpanded((current) => (current === item.id ? null : item.id))}
                    >
                      {expanded === item.id ? "Ocultar" : "Ver documento"}
                    </button>
                    {expanded === item.id && (
                      <div className="mt-2 rounded-lg bg-slate-50 p-2 text-left text-[10px] text-slate-600 dark:bg-slate-950 dark:text-slate-300">
                        <p><b>Tipo:</b> {documentLabel(item.documentType)}</p>
                        <p><b>Operación:</b> <span className="font-mono">{item.operationKey ?? "registro local"}</span></p>
                        {item.saleId && <p><b>Venta:</b> {item.saleId}</p>}
                        {item.purchaseId && <p><b>Compra:</b> {item.purchaseId}</p>}
                        {item.payrollRunId && <p><b>Planilla:</b> {item.payrollRunId}</p>}
                        {item.sessionId && <p><b>Sesión:</b> {item.sessionId}</p>}
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot className="bg-slate-50 dark:bg-slate-950">
              <tr>
                <td colSpan={4} className="p-2.5 text-right font-bold uppercase text-slate-500">Totales del período</td>
                <td className="p-2.5 text-right font-black text-emerald-600"><Money value={cards.entradas} /></td>
                <td className="p-2.5 text-right font-black text-rose-600"><Money value={cards.salidas} /></td>
                <td className="p-2.5 text-right font-black text-slate-800 dark:text-white"><Money value={cards.saldoFinal} /></td>
                <td />
              </tr>
            </tfoot>
          </table>
        </div>
        <p className="mt-2 flex items-center gap-1 text-[10px] text-slate-400">
          <ShieldCheck size={12} /> El saldo acumulado lo calcula SQL Server sobre movimientos confirmados; los anulados se conservan y no afectan el saldo.
        </p>
      </section>
    </div>
  );
}
