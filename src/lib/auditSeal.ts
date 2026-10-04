import type { AuditEvent } from "../types/erp";

export const GENESIS = "GENESIS";

export function digest(text: string) {
  let hash = 2166136261;
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, "0");
}

export function inferSeverity(action: string): AuditEvent["severity"] {
  const key = action.toLowerCase();
  if (key.includes("alerta") || key.includes("descuadre") || key.includes("eliminar") || key.includes("deneg")) return "critical";
  if (key.includes("stock") || key.includes("mínimo") || key.includes("minimo") || key.includes("warn")) return "warn";
  return "info";
}

export function eventFingerprint(event: Pick<AuditEvent, "at" | "userName" | "action" | "module" | "detail">, prevHash: string) {
  return digest(`${prevHash}|${event.at}|${event.userName}|${event.action}|${event.module}|${event.detail}`);
}

export function sealChain(events: Array<Omit<AuditEvent, "hash" | "prevHash"> & Partial<AuditEvent>>): AuditEvent[] {
  const oldestFirst = [...events].sort((a, b) => new Date(a.at).getTime() - new Date(b.at).getTime());
  let prevHash = GENESIS;
  const sealed = oldestFirst.map((event) => {
    const hash = eventFingerprint(event, prevHash);
    const row: AuditEvent = {
      id: event.id,
      at: event.at,
      userName: event.userName,
      action: event.action,
      module: event.module,
      detail: event.detail,
      severity: event.severity ?? inferSeverity(event.action),
      reference: event.reference,
      uml: event.uml,
      prevHash,
      hash
    };
    prevHash = hash;
    return row;
  });
  return sealed.sort((a, b) => new Date(b.at).getTime() - new Date(a.at).getTime());
}

export function verifyChain(events: AuditEvent[]) {
  const oldestFirst = [...events].sort((a, b) => new Date(a.at).getTime() - new Date(b.at).getTime());
  let prevHash = GENESIS;
  const broken: AuditEvent[] = [];
  for (const event of oldestFirst) {
    const expected = eventFingerprint(event, prevHash);
    if (event.prevHash !== prevHash || event.hash !== expected) broken.push(event);
    prevHash = event.hash ?? expected;
  }
  return { ok: broken.length === 0, broken, sealed: oldestFirst.length };
}

export const umlForAction: Record<string, string> = {
  venta: "Secuencia RF08 / RF20",
  compra: "Actividad RF07",
  asiento: "Colaboración RD03",
  kanban: "Estados RF11",
  inicio: "Despliegue RS06",
  consulta: "Caso de uso RU05",
  crear: "Clases RF17",
  eliminar: "Clases + auditoría RF15",
  alerta: "Estados RF18",
  proforma: "Estados cotización",
  autenticar: "Caso de uso RF01"
};
