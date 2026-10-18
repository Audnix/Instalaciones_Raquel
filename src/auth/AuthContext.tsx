import { createContext, ReactNode, useContext, useEffect, useMemo, useState } from "react";
import type { Action, ModuleId, SessionUser } from "../types/erp";
import { can, canAccess, seedUsers } from "./roles";

const SESSION_KEY = "raquel_user_session";
const TOKEN_KEY = "raquel_jwt_token";
const API_URL = import.meta.env.VITE_API_URL || "http://localhost:4000";

type AuthValue = {
  user: SessionUser | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string, remember: boolean) => Promise<void>;
  logout: () => Promise<void>;
  can: (moduleId: ModuleId, action?: Action) => boolean;
  canAccess: (moduleId: ModuleId) => boolean;
  refreshSession: () => Promise<void>;
};

const AuthContext = createContext<AuthValue | null>(null);

function readStoredUser(): SessionUser | null {
  const raw = localStorage.getItem(SESSION_KEY) || sessionStorage.getItem(SESSION_KEY);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    const { password: _p, ...safe } = parsed;
    return safe as SessionUser;
  } catch {
    return null;
  }
}

function readStoredToken(): string | null {
  return localStorage.getItem(TOKEN_KEY) || sessionStorage.getItem(TOKEN_KEY) || null;
}

export function AuthProvider({ children }: { children: ReactNode; directory?: SessionUser[] }) {
  const [user, setUser] = useState<SessionUser | null>(readStoredUser);
  const [token, setToken] = useState<string | null>(readStoredToken);

  // Validar sesión contra la API de SQL Server al inicializar
  useEffect(() => {
    const activeToken = readStoredToken();
    if (!activeToken) return;

    fetch(`${API_URL}/api/auth/session`, {
      headers: { Authorization: `Bearer ${activeToken}` }
    })
      .then(async (res) => {
        if (!res.ok) {
          // Sesión revocada o expirada
          localStorage.removeItem(SESSION_KEY);
          localStorage.removeItem(TOKEN_KEY);
          sessionStorage.removeItem(SESSION_KEY);
          sessionStorage.removeItem(TOKEN_KEY);
          setUser(null);
          setToken(null);
        } else {
          const data = await res.json();
          if (data.user) {
            setUser((prev) => ({
              id: data.user.id || prev?.id || "u-active",
              name: data.user.name || prev?.name || "Usuario",
              email: data.user.email || prev?.email || "",
              hierarchy: data.user.hierarchy || prev?.hierarchy || "estandar",
              areas: data.user.areas || prev?.areas || [],
              active: true
            }));
          }
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
        // Intento 1: Autenticación segura mediante API contra SQL Server y bcrypt
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

          const safeUser: SessionUser = {
            id: data.user.id,
            name: data.user.name,
            email: data.user.email,
            hierarchy: data.user.hierarchy,
            areas: data.user.areas || [],
            active: data.user.active !== false
          };

          const storage = remember ? localStorage : sessionStorage;
          storage.setItem(SESSION_KEY, JSON.stringify(safeUser));
          storage.setItem(TOKEN_KEY, data.token);

          // Limpiar el otro almacén para evitar desincronización
          const otherStorage = remember ? sessionStorage : localStorage;
          otherStorage.removeItem(SESSION_KEY);
          otherStorage.removeItem(TOKEN_KEY);

          setUser(safeUser);
          setToken(data.token);
          return;
        } catch (apiErr) {
          if (apiErr instanceof Error && apiErr.message.includes("401") || apiErr instanceof Error && apiErr.message.includes("423") || apiErr instanceof Error && apiErr.message.includes("403")) {
            throw apiErr;
          }
          // Si no hay respuesta del servidor pero es error de credenciales propagar
          if (apiErr instanceof Error && !apiErr.message.includes("Failed to fetch")) {
            throw apiErr;
          }
          throw new Error("No se pudo conectar con el servidor de autenticación de SQL Server. Verifique que la API esté activa.");
        }
      },
      logout: async () => {
        const activeToken = token || readStoredToken();
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
        localStorage.removeItem(SESSION_KEY);
        localStorage.removeItem(TOKEN_KEY);
        sessionStorage.removeItem(SESSION_KEY);
        sessionStorage.removeItem(TOKEN_KEY);
        setUser(null);
        setToken(null);
      },
      can: (moduleId, action = "read") => can(user, moduleId, action),
      canAccess: (moduleId) => canAccess(user, moduleId),
      refreshSession: async () => {
        const activeToken = token || readStoredToken();
        if (!activeToken) return;
        try {
          const res = await fetch(`${API_URL}/api/auth/session`, {
            headers: { Authorization: `Bearer ${activeToken}` }
          });
          if (res.ok) {
            const data = await res.json();
            if (data.user) {
              const safeUser: SessionUser = {
                id: data.user.id,
                name: data.user.name,
                email: data.user.email,
                hierarchy: data.user.hierarchy,
                areas: data.user.areas || [],
                active: true
              };
              setUser(safeUser);
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
