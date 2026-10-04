import type { Action, AreaRole, HierarchyRole, ModuleId, SessionUser } from "../types/erp";

export type RolePower = "consultar" | "ejecutar" | "aprobar" | "administrar";

export type PowerValue = true | false | "área";

export const rolePowers: Record<HierarchyRole, Record<RolePower, PowerValue>> = {
  superadmin: { consultar: true, ejecutar: true, aprobar: true, administrar: true },
  administrador: { consultar: true, ejecutar: true, aprobar: true, administrar: "área" },
  estandar: { consultar: true, ejecutar: true, aprobar: false, administrar: false },
  invitado: { consultar: true, ejecutar: false, aprobar: false, administrar: false }
};

export const powerLabels: RolePower[] = ["consultar", "ejecutar", "aprobar", "administrar"];

export const hierarchyMeta: Record<
  HierarchyRole,
  { label: string; duty: string; color: string; mark: string; markHint: string }
> = {
  superadmin: {
    label: "Superadministrador",
    duty: "Administra el sistema y también ejecuta cualquier operación. No se queda solo en configurar.",
    color: "bg-amber-500",
    mark: "Corona",
    markHint: "Administra + ejecuta"
  },
  administrador: {
    label: "Administrador de área",
    duty: "Administra su área, aprueba movimientos y ejecuta lo de su equipo.",
    color: "bg-brand-600",
    mark: "Escudo",
    markHint: "Aprueba su área"
  },
  estandar: {
    label: "Usuario estándar",
    duty: "Ejecuta el día a día (facturar, comprar, OT). No configura usuarios ni el sistema.",
    color: "bg-moss",
    mark: "Mano",
    markHint: "Solo ejecuta"
  },
  invitado: {
    label: "Usuario restringido / Invitado",
    duty: "Solo consulta. No ejecuta cobros, ni descuenta stock, ni administra.",
    color: "bg-slate-500",
    mark: "Ojo",
    markHint: "Solo mira"
  }
};

export const areaMeta: Record<AreaRole, { label: string; modules: ModuleId[] }> = {
  produccion: { label: "Producción", modules: ["produccion", "inventario"] },
  inventario: { label: "Inventario", modules: ["inventario", "datos"] },
  finanzas: { label: "Finanzas", modules: ["finanzas", "caja", "bancos", "costos"] },
  contabilidad: { label: "Contabilidad", modules: ["contabilidad", "costos", "reportes"] },
  mercadotecnia: { label: "Mercadotecnia", modules: ["mercadotecnia", "ventas", "reportes"] },
  compras: { label: "Compras y proveedores", modules: ["compras", "proveedores", "inventario"] },
  ventas: { label: "Ventas y clientes", modules: ["ventas", "clientes"] },
  rrhh: { label: "Talento humano", modules: ["rrhh", "nomina"] },
  proyectos: { label: "Proyectos", modules: ["proyectos"] },
  gobierno: { label: "Gobierno del sistema", modules: ["usuarios", "auditoria", "datos", "metodologia", "ers", "reportes"] }
};

const allModules: ModuleId[] = [
  "produccion",
  "inventario",
  "finanzas",
  "caja",
  "bancos",
  "contabilidad",
  "costos",
  "ventas",
  "clientes",
  "mercadotecnia",
  "compras",
  "proveedores",
  "proyectos",
  "rrhh",
  "nomina",
  "reportes",
  "auditoria",
  "usuarios",
  "datos",
  "metodologia",
  "ers"
];

export function modulesForUser(user: SessionUser | null): ModuleId[] {
  if (!user) return [];
  if (user.hierarchy === "superadmin") return allModules;
  const set = new Set<ModuleId>();
  user.areas.forEach((area) => areaMeta[area].modules.forEach((id) => set.add(id)));
  if (user.hierarchy === "administrador") {
    set.add("reportes");
    set.add("auditoria");
    set.add("usuarios");
    set.add("ers");
    set.add("metodologia");
  }
  return [...set];
}

export function canAccess(user: SessionUser | null, moduleId: ModuleId) {
  return modulesForUser(user).includes(moduleId);
}

export function can(user: SessionUser | null, moduleId: ModuleId, action: Action) {
  if (!user || !user.active) return false;
  if (!canAccess(user, moduleId)) return false;
  if (user.hierarchy === "superadmin") return true;
  if (action === "admin") return user.hierarchy === "administrador" && (moduleId === "usuarios" || moduleId === "datos");
  if (user.hierarchy === "invitado") return action === "read";
  if (action === "approve") return user.hierarchy === "administrador";
  if (action === "write") return user.hierarchy === "administrador" || user.hierarchy === "estandar";
  return true;
}

export const seedUsers: SessionUser[] = [
  {
    id: "u-super",
    name: "Raquel López",
    email: "admin@raquel.com",
    password: "raquel2026",
    hierarchy: "superadmin",
    areas: ["gobierno", "produccion", "finanzas", "contabilidad", "mercadotecnia", "compras", "ventas", "rrhh", "proyectos"],
    active: true
  },
  {
    id: "u-fin",
    name: "María Contadora",
    email: "contador@raquel.com",
    password: "raquel2026",
    hierarchy: "administrador",
    areas: ["finanzas", "contabilidad"],
    active: true
  },
  {
    id: "u-prod",
    name: "Carlos Producción",
    email: "produccion@raquel.com",
    password: "raquel2026",
    hierarchy: "administrador",
    areas: ["produccion", "inventario", "proyectos"],
    active: true
  },
  {
    id: "u-sales",
    name: "Ana Ventas",
    email: "vendedor@raquel.com",
    password: "raquel2026",
    hierarchy: "estandar",
    areas: ["ventas", "mercadotecnia"],
    active: true
  },
  {
    id: "u-buy",
    name: "Luis Compras",
    email: "compras@raquel.com",
    password: "raquel2026",
    hierarchy: "estandar",
    areas: ["compras", "inventario"],
    active: true
  },
  {
    id: "u-guest",
    name: "Invitado Gerencia",
    email: "invitado@raquel.com",
    password: "raquel2026",
    hierarchy: "invitado",
    areas: ["finanzas", "mercadotecnia", "proyectos"],
    active: true
  }
];
