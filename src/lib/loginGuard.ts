const KEY = "raquel_login_guard";
const MAX_FAILS = 3;
const LOCK_MS = 90_000;

type Guard = { fails: number; until: number };

function read(): Guard {
  try {
    const raw = sessionStorage.getItem(KEY);
    if (!raw) return { fails: 0, until: 0 };
    return JSON.parse(raw) as Guard;
  } catch {
    return { fails: 0, until: 0 };
  }
}

function write(guard: Guard) {
  sessionStorage.setItem(KEY, JSON.stringify(guard));
}

export function loginLockMs() {
  const left = read().until - Date.now();
  return left > 0 ? left : 0;
}

export function loginFails() {
  return read().fails;
}

export function registerLoginFail() {
  const current = read();
  const fails = current.fails + 1;
  const until = fails >= MAX_FAILS ? Date.now() + LOCK_MS : 0;
  write({ fails, until });
  return { fails, until, locked: until > Date.now() };
}

export function clearLoginGuard() {
  sessionStorage.removeItem(KEY);
}

export const LOGIN_MAX_FAILS = MAX_FAILS;
