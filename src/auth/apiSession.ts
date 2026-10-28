import type { SessionUser } from "../types/erp";

const TOKEN_KEY = "raquel_auth_token";
const USER_KEY = "raquel_user";
const LEGACY_TOKEN_KEYS = ["raquel_jwt_token", "raquel_token"];
const LEGACY_USER_KEYS = ["raquel_user_session"];

function storageList(): Storage[] {
  return [localStorage, sessionStorage];
}

export function getAuthToken(): string | null {
  migrateLegacySession();
  return localStorage.getItem(TOKEN_KEY) ?? sessionStorage.getItem(TOKEN_KEY);
}

function migrateLegacySession() {
  const current = localStorage.getItem(TOKEN_KEY) ?? sessionStorage.getItem(TOKEN_KEY);
  if (current) return;

  for (const storage of storageList()) {
    for (const key of LEGACY_TOKEN_KEYS) {
      const legacyToken = storage.getItem(key);
      if (!legacyToken) continue;
      const legacyUser =
        storage.getItem(USER_KEY) ??
        LEGACY_USER_KEYS.map((userKey) => storage.getItem(userKey)).find(Boolean) ??
        null;
      storage.setItem(TOKEN_KEY, legacyToken);
      if (legacyUser) storage.setItem(USER_KEY, legacyUser);
      return;
    }
  }
}

export function saveAuthSession(token: string, user: SessionUser, remember: boolean) {
  const target = remember ? localStorage : sessionStorage;
  const other = remember ? sessionStorage : localStorage;
  for (const storage of [target, other]) {
    storage.removeItem(TOKEN_KEY);
    storage.removeItem(USER_KEY);
    for (const key of LEGACY_TOKEN_KEYS) storage.removeItem(key);
    for (const key of LEGACY_USER_KEYS) storage.removeItem(key);
  }
  target.setItem(TOKEN_KEY, token);
  target.setItem(USER_KEY, JSON.stringify(user));
  window.dispatchEvent(new Event("raquel-auth-changed"));
}

export function readAuthUser(): SessionUser | null {
  migrateLegacySession();
  if (!getAuthToken()) return null;
  const raw = localStorage.getItem(USER_KEY) ?? sessionStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as SessionUser & { password?: string };
    delete parsed.password;
    return parsed;
  } catch {
    return null;
  }
}

export function clearAuthSession() {
  for (const storage of storageList()) {
    storage.removeItem(TOKEN_KEY);
    storage.removeItem(USER_KEY);
    for (const key of LEGACY_TOKEN_KEYS) storage.removeItem(key);
    for (const key of LEGACY_USER_KEYS) storage.removeItem(key);
  }
  window.dispatchEvent(new Event("raquel-auth-changed"));
}

export class ApiRequestError extends Error {
  status: number;
  code: string;

  constructor(message: string, status: number, code = "REQUEST_FAILED") {
    super(message);
    this.name = "ApiRequestError";
    this.status = status;
    this.code = code;
  }
}

export function classifyApiFailure(status: number, message = "", code?: string) {
  const text = `${message} ${code ?? ""}`.toLowerCase();
  if (status === 429) return {
    code: "TOO_MANY_REQUESTS", title: "Servidor ocupado",
    message: "Se alcanzó el límite temporal de consultas. Espera unos minutos y vuelve a consultar. Si estabas confirmando un movimiento, conserva sus datos y reintenta la misma operación."
  };
  if (status === 404 && !message) return {
    code: "API_ROUTE_UNAVAILABLE", title: "Servicio no disponible",
    message: "El servidor no reconoce esta operación. Verifica que esté ejecutándose la versión actual de la API."
  };
  if (status === 401 || text.includes("expirad") || text.includes("token inválido") || text.includes("autenticación activa")) {
    return {
      code: "SESSION_EXPIRED",
      title: "Sesión vencida",
      message: message || "La sesión expiró o no está activa. Inicie sesión nuevamente."
    };
  }
  if (status === 403 || text.includes("denegad") || text.includes("restringida") || text.includes("no autorizado")) {
    return {
      code: "ACCESS_DENIED",
      title: "Acceso denegado",
      message: message || "Tu cuenta no tiene permiso para esta operación."
    };
  }
  if (code === "PAYROLL_MIGRATION_REQUIRED" || text.includes("migración 30") || text.includes("migracion 30")) {
    return {
      code: "PAYROLL_MIGRATION_REQUIRED",
      title: "Pagos de nómina pendientes de habilitar",
      message: message || "Falta aplicar la migración 30 de pagos seguros. Los pagos quedan pausados."
    };
  }
  if (status === 503 || text.includes("sql server no") || text.includes("failed to fetch") || text.includes("network")) {
    if (text.includes("estructura") || code === "SQL_STRUCTURE_PENDING") {
      return {
        code: "SQL_STRUCTURE_PENDING",
        title: "Estructura SQL pendiente",
        message: message || "Falta aplicar la migración de Talento humano o Nómina. No reconstruya la base."
      };
    }
    return {
      code: "API_DISCONNECTED",
      title: "API desconectada",
      message: message || "No hay conexión con la API o SQL Server."
    };
  }
  if (code === "SQL_STRUCTURE_PENDING" || text.includes("invalid object") || text.includes("estructura sql")) {
    return {
      code: "SQL_STRUCTURE_PENDING",
      title: "Estructura SQL pendiente",
      message: message || "Faltan tablas o procedimientos. Aplique la migración 25 sin reconstruir datos."
    };
  }
  return {
    code: code || "REQUEST_FAILED",
    title: "Operación no completada",
    message: message || "No se pudo completar la operación."
  };
}

export async function parseApiResponse<T>(response: Response): Promise<T> {
  let payload: any = {};
  try {
    payload = await response.json();
  } catch {
    payload = {};
  }
  if (!response.ok) {
    const classified = classifyApiFailure(response.status, payload.message, payload.code);
    throw new ApiRequestError(classified.message === "No se pudo completar la operación."
      ? `El servidor rechazó la operación (HTTP ${response.status}). Conserva los datos y vuelve a consultar su estado antes de repetirla.`
      : classified.message, response.status, classified.code);
  }
  return payload as T;
}

export function authenticatedFetch(input: RequestInfo | URL, init: RequestInit = {}) {
  const headers = new Headers(init.headers);
  const token = getAuthToken();
  if (token) headers.set("Authorization", `Bearer ${token}`);
  return fetch(input, { ...init, headers })
    .then((response) => {
      if (response.status === 401 && token) {
        clearAuthSession();
        window.dispatchEvent(new Event("raquel-session-expired"));
      }
      return response;
    })
    .catch((err) => {
      if (err instanceof ApiRequestError) throw err;
      throw new ApiRequestError(
        "No se pudo conectar con el servidor local o la red está inactiva.",
        503,
        "API_DISCONNECTED"
      );
    });
}

export function formatApiErrorMessage(err: unknown): { title: string; message: string; code: string } {
  if (err instanceof ApiRequestError) {
    const classified = classifyApiFailure(err.status, err.message, err.code);
    return { title: classified.title, message: classified.message, code: classified.code };
  }
  if (err instanceof Error) {
    const classified = classifyApiFailure(500, err.message);
    return { title: classified.title, message: classified.message, code: classified.code };
  }
  return { title: "Error", message: String(err), code: "UNKNOWN_ERROR" };
}

