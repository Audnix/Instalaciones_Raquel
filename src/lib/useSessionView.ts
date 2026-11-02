import { useState, type Dispatch, type SetStateAction } from "react";
import { useLocation } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function useSessionView<T>(name: string, initial: T, shared = false): [T, Dispatch<SetStateAction<T>>] {
  const { user } = useAuth();
  const { pathname } = useLocation();
  const key = `raquel:view:${user?.id ?? "anonymous"}:${shared ? "shared" : pathname}:${name}`;
  function restore(): T {
    try {
      const raw = sessionStorage.getItem(key);
      const saved = raw === null ? initial : JSON.parse(raw);
      return saved !== null && typeof saved === typeof initial ? saved as T : initial;
    } catch { return initial; }
  }
  const [state, setState] = useState(() => ({ key, value: restore() }));
  const value = state.key === key ? state.value : restore();
  const update: Dispatch<SetStateAction<T>> = next => setState(previousState => {
    const previous = previousState.key === key ? previousState.value : restore();
    const result = typeof next === "function" ? (next as (value: T) => T)(previous) : next;
    try { sessionStorage.setItem(key, JSON.stringify(result)); } catch { /* Optional preference. */ }
    return { key, value: result };
  });
  return [value, update];
}
