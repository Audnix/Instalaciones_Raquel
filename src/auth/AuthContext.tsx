import { getApiBaseUrl } from '../lib/apiBase';
import { createContext, ReactNode, useContext, useEffect, useMemo, useState } from "react";
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
};

const AuthContext = createContext<AuthValue | null>(null);

function toSafeUser(data: Partial<SessionUser> | undefined, fallback?: SessionUser | null): SessionUser {
  return {
    id: data?.id || fallback?.id || "u-active",
    name: data?.name || fallback?.name || "Usuario",
    email: data?.email || fallback?.email || "",
    hierarchy: data?.hierarchy || fallback?.hierarchy || "estandar",
    areas: data?.areas || fallback?.areas || [],
    active: data?.active !== false
  };
}

export function AuthProvider({ children }: { children: ReactNode; directory?: SessionUser[] }) {
  const [user, setUser] = useState<SessionUser | null>(readAuthUser);
  const [token, setToken] = useState<string | null>(getAuthToken);

  useEffect(() => {
    const onExpired = () => {
      setUser(null);
      setToken(null);
    };
    window.addEventListener("raquel-session-expired", onExpired);
    return () => window.removeEventListener("raquel-session-expired", onExpired);
  }, []);

  useEffect(() => {
    const activeToken = getAuthToken();
    if (!activeToken) return;

    fetch(`${API_URL}/api/auth/session`, {
      headers: { Authorization: `Bearer ${activeToken}` }
    })
      .then(async (res) => {
        if (!res.ok) {
          clearAuthSession();
          setUser(null);
          setToken(null);
          return;
        }
        const data = await res.json();
        if (data.user) {
          const safeUser = toSafeUser(data.user, readAuthUser());
          const remember = Boolean(localStorage.getItem("raquel_auth_token"));
          saveAuthSession(activeToken, safeUser, remember);
          setUser(safeUser);
          setToken(activeToken);
        }
      })
      .catch((err) => {
        console.warn("Validación de sesión con API:", err.message);
      });
  }, []);

  const value = useMemo<AuthValue>(
    () => ({
      user,
      token,
      isAuthenticated: Boolean(user && token),
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
          body: JSON.stringify({ currentPassword: currentPassword || "temporal123", newPassword })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.message || "Error al actualizar la contraseña.");
      },
      can: (moduleId, action = "read") => can(user, moduleId, action),
      canAccess: (moduleId) => canAccess(user, moduleId),
      refreshSession: async () => {
        const activeToken = token || getAuthToken();
        if (!activeToken) return;
        try {
          const res = await fetch(`${API_URL}/api/auth/session`, {
            headers: { Authorization: `Bearer ${activeToken}` }
          });
          if (res.ok) {
            const data = await res.json();
            if (data.user) {
              const safeUser = toSafeUser(data.user);
              const remember = Boolean(localStorage.getItem("raquel_auth_token"));
              saveAuthSession(activeToken, safeUser, remember);
              setUser(safeUser);
              setToken(activeToken);
            }
          }
        } catch {
          // ignore
        }
      }
    }),
    [token, user]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth debe usarse dentro de AuthProvider");
  return ctx;
}

export { seedUsers };
