import { createContext, ReactNode, useContext, useMemo, useState } from "react";
import type { Action, ModuleId, SessionUser } from "../types/erp";
import { can, canAccess, seedUsers } from "./roles";

const SESSION_KEY = "raquel_user";

type AuthValue = {
  user: SessionUser | null;
  isAuthenticated: boolean;
  login: (email: string, password: string, remember: boolean) => Promise<void>;
  logout: () => void;
  can: (moduleId: ModuleId, action?: Action) => boolean;
  canAccess: (moduleId: ModuleId) => boolean;
};

const AuthContext = createContext<AuthValue | null>(null);

function readSession(): SessionUser | null {
  const raw = localStorage.getItem(SESSION_KEY) ?? sessionStorage.getItem(SESSION_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as SessionUser;
  } catch {
    return null;
  }
}

export function AuthProvider({ children, directory }: { children: ReactNode; directory: SessionUser[] }) {
  const [user, setUser] = useState<SessionUser | null>(readSession);

  const value = useMemo<AuthValue>(
    () => ({
      user,
      isAuthenticated: Boolean(user),
      login: async (email, password, remember) => {
        let found: SessionUser | undefined;
        try {
          const response = await fetch("/api/auth/login", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email, password })
          });
          const payload = await response.json();
          if (response.ok && payload.user) {
            found = payload.user as SessionUser;
            if (payload.token) localStorage.setItem("raquel_token", payload.token);
          }
        } catch {
          found = undefined;
        }
        if (!found) {
          found = directory.find(
            (item) => item.email.toLowerCase() === email.toLowerCase() && item.password === password && item.active
          );
        }
        if (!found) throw new Error("Credenciales inválidas o usuario inactivo.");
        const safe = { ...found, password };
        if (remember) localStorage.setItem(SESSION_KEY, JSON.stringify(safe));
        else sessionStorage.setItem(SESSION_KEY, JSON.stringify(safe));
        setUser(safe);
      },
      logout: () => {
        localStorage.removeItem(SESSION_KEY);
        sessionStorage.removeItem(SESSION_KEY);
        localStorage.removeItem("raquel_token");
        setUser(null);
      },
      can: (moduleId, action = "read") => can(user, moduleId, action),
      canAccess: (moduleId) => canAccess(user, moduleId)
    }),
    [directory, user]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth debe usarse dentro de AuthProvider");
  return ctx;
}

export { seedUsers };
