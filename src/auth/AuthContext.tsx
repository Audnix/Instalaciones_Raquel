import { getApiBaseUrl } from '../lib/apiBase';
import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import type { Action, ModuleId, SessionUser } from "../types/erp";
import { can, canAccess, seedUsers } from "./roles";
import {
  clearAuthSession,
  getAuthToken,
  readAuthUser,
  saveAuthSession
} from "./apiSession";

const API_URL = getApiBaseUrl();

type AuthValue = {
  user: SessionUser | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string, remember: boolean) => Promise<void>;
  logout: () => Promise<void>;
  changePassword: (currentPassword?: string, newPassword?: string) => Promise<void>;
  can: (moduleId: ModuleId, action?: Action) => boolean;
  canAccess: (moduleId: ModuleId) => boolean;
  refreshSession: () => Promise<void>;
  sessionReady: boolean;
  sessionError: string | null;
};

const AuthContext = createContext<AuthValue | null>(null);

function toSafeUser(data: Partial<SessionUser> | undefined, fallback?: SessionUser | null): SessionUser {
  return {
    id: data?.id || fallback?.id || "u-active",
    name: data?.name || fallback?.name || "Usuario",
    email: data?.email || fallback?.email || "",
    hierarchy: data?.hierarchy || "invitado",
    areas: data?.areas || [],
    mustChangePassword: Boolean(data?.mustChangePassword),
    active: data?.active !== false
  };
}

export function AuthProvider({ children }: { children: ReactNode; directory?: SessionUser[] }) {
  const [user, setUser] = useState<SessionUser | null>(readAuthUser);
  const [token, setToken] = useState<string | null>(getAuthToken);

  const [sessionReady, setSessionReady] = useState(!getAuthToken());
  const [sessionError, setSessionError] = useState<string | null>(null);
  const sessionGeneration = useRef(0);
  const refreshSession = useCallback(async () => {
    const generation = ++sessionGeneration.current;
    const activeToken = getAuthToken();
    if (!activeToken) { setUser(null); setToken(null); setSessionReady(true); setSessionError(null); return; }
    try {
      const response = await fetch(API_URL + '/api/auth/session', { headers: { Authorization: 'Bearer ' + activeToken } });
      if (generation !== sessionGeneration.current || getAuthToken() !== activeToken) return;
      if (response.status === 401) {
        clearAuthSession(); setUser(null); setToken(null); setSessionError(null); setSessionReady(true); return;
      }
      if (!response.ok) throw new Error('No se pudieron verificar tus permisos. Reintenta la conexión.');
      const data = await response.json();
      if (generation !== sessionGeneration.current || getAuthToken() !== activeToken) return;
      if (!data.user?.id || !data.user?.hierarchy || !Array.isArray(data.user?.areas)) throw new Error('La sesión no incluye permisos verificables. Vuelve a consultar.');
      const safeUser = toSafeUser(data.user);
      saveAuthSession(activeToken, safeUser, Boolean(localStorage.getItem('raquel_auth_token')));
      setUser(safeUser); setToken(activeToken); setSessionError(null); setSessionReady(true);
    } catch (error) {
      if (generation !== sessionGeneration.current || getAuthToken() !== activeToken) return;
      setSessionError(error instanceof Error ? error.message : 'No se pudo verificar la sesión.');
      setSessionReady(false);
    }
  }, []);

  useEffect(() => {
    const onExpired = () => {
      setUser(null);
      setToken(null);
      setSessionReady(true);
      setSessionError(null);
    };
    window.addEventListener("raquel-session-expired", onExpired);
    return () => window.removeEventListener("raquel-session-expired", onExpired);
  }, []);

  useEffect(() => {
    void refreshSession();
    const sync = () => { if (document.visibilityState === 'visible') void refreshSession(); };
    const storage = (event: StorageEvent) => { if (!event.key || event.key === 'raquel_auth_token') void refreshSession(); };
    window.addEventListener('focus', sync); window.addEventListener('online', sync); window.addEventListener('storage', storage);
    document.addEventListener('visibilitychange', sync);
    const timer = window.setInterval(sync, 60000);
    return () => { window.clearInterval(timer); window.removeEventListener('focus', sync); window.removeEventListener('online', sync); window.removeEventListener('storage', storage); document.removeEventListener('visibilitychange', sync); };
  }, [refreshSession]);

  const value = useMemo<AuthValue>(
    () => ({
      user,
      token,
      sessionReady,
      sessionError,
      isAuthenticated: Boolean(user?.active && token && sessionReady),
      login: async (email, password, remember) => {
        try {
          const res = await fetch(`${API_URL}/api/auth/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email: email.trim().toLowerCase(), password })
          });

          const data = await res.json();
          if (!res.ok) {
            throw new Error(data.message || "Error al autenticar credenciales.");
          }

          const safeUser = toSafeUser(data.user);
          saveAuthSession(data.token, safeUser, remember);
          setUser(safeUser);
          setToken(data.token);
          setSessionReady(true);
          setSessionError(null);
        } catch (apiErr) {
          if (apiErr instanceof Error && !apiErr.message.includes("Failed to fetch")) {
            throw apiErr;
          }
          throw new Error(
            "No se pudo conectar con el servidor de autenticación de SQL Server. Verifique que la API esté activa."
          );
        }
      },
      logout: async () => {
        const activeToken = token || getAuthToken();
        if (activeToken) {
          try {
            await fetch(`${API_URL}/api/auth/logout`, {
              method: "POST",
              headers: { Authorization: `Bearer ${activeToken}` }
            });
          } catch {
            // Silencioso si la red falló
          }
        }
        clearAuthSession();
        setUser(null);
        setToken(null);
        setSessionReady(true);
        setSessionError(null);
      },
      changePassword: async (currentPassword = "", newPassword = "") => {
        const activeToken = token || getAuthToken();
        if (!activeToken) throw new Error("Sesión no iniciada.");
        const res = await fetch(`${API_URL}/api/auth/change-password`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${activeToken}`
          },
          body: JSON.stringify({ currentPassword, newPassword })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.message || "Error al actualizar la contraseña.");
        await refreshSession();
      },
      can: (moduleId, action = "read") => can(user, moduleId, action),
      canAccess: (moduleId) => canAccess(user, moduleId),
      refreshSession
    }),
    [token, user, sessionReady, sessionError, refreshSession]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth debe usarse dentro de AuthProvider");
  return ctx;
}

export { seedUsers };
