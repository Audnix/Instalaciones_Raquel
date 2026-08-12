import {
  Archive,
  BadgeDollarSign,
  Banknote,
  Boxes,
  BriefcaseBusiness,
  Building2,
  Calculator,
  CalendarDays,
  ChartNoAxesCombined,
  CircleDollarSign,
  ClipboardList,
  Factory,
  FileBarChart,
  HandCoins,
  HardHat,
  Landmark,
  PackageCheck,
  Scale,
  ShieldCheck,
  ShoppingCart,
  Truck,
  UsersRound,
  WalletCards
} from "lucide-react";

export const modules = [
  { id: "ventas", label: "Ventas", icon: ShoppingCart, accent: "bg-ember" },
  { id: "compras", label: "Compras", icon: Truck, accent: "bg-brand-600" },
  { id: "inventario", label: "Inventario", icon: Boxes, accent: "bg-moss" },
  { id: "clientes", label: "Clientes", icon: UsersRound, accent: "bg-cyan-500" },
  { id: "proveedores", label: "Proveedores", icon: Building2, accent: "bg-violet-500" },
  { id: "proyectos", label: "Proyectos", icon: BriefcaseBusiness, accent: "bg-amber-500" },
  { id: "produccion", label: "Produccion", icon: Factory, accent: "bg-slate-500" },
  { id: "rrhh", label: "RRHH", icon: HardHat, accent: "bg-teal-600" },
  { id: "nomina", label: "Nomina", icon: HandCoins, accent: "bg-lime-600" },
  { id: "caja", label: "Caja", icon: WalletCards, accent: "bg-rose-500" },
  { id: "bancos", label: "Bancos", icon: Landmark, accent: "bg-sky-600" },
  { id: "contabilidad", label: "Contabilidad", icon: Calculator, accent: "bg-indigo-600" },
  { id: "costos", label: "Costos", icon: Scale, accent: "bg-orange-500" },
  { id: "finanzas", label: "Finanzas", icon: ChartNoAxesCombined, accent: "bg-emerald-600" },
  { id: "reportes", label: "Reportes", icon: FileBarChart, accent: "bg-fuchsia-600" },
  { id: "auditoria", label: "Auditoria", icon: ShieldCheck, accent: "bg-zinc-600" }
];

export const kpis = [
  { label: "Ventas del mes", value: "C$ 1.84M", change: "+18.4%", tone: "from-brand-600 to-cyan-500", icon: CircleDollarSign },
  { label: "Utilidad bruta", value: "C$ 642K", change: "+11.2%", tone: "from-moss to-emerald-400", icon: BadgeDollarSign },
  { label: "Proyectos activos", value: "38", change: "+6", tone: "from-amber-500 to-orange-400", icon: BriefcaseBusiness },
  { label: "Stock critico", value: "17", change: "-9.1%", tone: "from-ember to-rose-400", icon: Archive }
];

export const revenue = [
  { month: "Ene", ventas: 940, costos: 640, utilidad: 300 },
  { month: "Feb", ventas: 1120, costos: 710, utilidad: 410 },
  { month: "Mar", ventas: 980, costos: 650, utilidad: 330 },
  { month: "Abr", ventas: 1280, costos: 780, utilidad: 500 },
  { month: "May", ventas: 1540, costos: 930, utilidad: 610 },
  { month: "Jun", ventas: 1840, costos: 1198, utilidad: 642 }
];

export const production = [
  { name: "Ventanas", value: 42 },
  { name: "Puertas", value: 24 },
  { name: "Fachadas", value: 16 },
  { name: "Espejos", value: 10 },
  { name: "Barandales", value: 8 }
];

export const activity = [
  { title: "Factura F-1092 aprobada", meta: "Contabilidad · hace 4 min", status: "Listo" },
  { title: "Bodega registro salida de vidrio 6mm", meta: "Inventario · hace 18 min", status: "Stock" },
  { title: "Proyecto Torre Azul paso a instalacion", meta: "Proyectos · hace 42 min", status: "Obra" },
  { title: "Nomina quincenal pendiente de aprobacion", meta: "RRHH · hoy 09:10", status: "Revision" }
];

export const notifications = [
  { title: "Stock bajo", body: "Silicon neutro blanco queda bajo punto de reorden.", level: "Urgente" },
  { title: "Factura vencida", body: "Cliente Casa Norte tiene saldo vencido por C$ 86,400.", level: "Cobro" },
  { title: "Pago de nomina", body: "12 comprobantes listos para autorizacion.", level: "Nomina" }
];

export const rows = [
  { code: "PRJ-2048", name: "Residencial Las Palmas", client: "Grupo Habitat", amount: "C$ 486,200", state: "Fabricacion", owner: "Supervisor", progress: 68 },
  { code: "INV-771", name: "Vidrio templado 10mm", client: "Bodega central", amount: "124 laminas", state: "Stock bajo", owner: "Bodega", progress: 21 },
  { code: "FAC-1092", name: "Fachada modular", client: "Torre Azul", amount: "C$ 312,900", state: "Por cobrar", owner: "Contador", progress: 82 },
  { code: "OC-448", name: "Perfiles serie 5020", client: "Alumex", amount: "C$ 174,500", state: "Recepcion", owner: "Compras", progress: 45 },
  { code: "NOM-0626", name: "Nomina instaladores", client: "RRHH", amount: "C$ 98,700", state: "Aprobacion", owner: "Gerente", progress: 74 }
];

export const calendar = [
  { day: "Lun", job: "Mediciones", count: 5 },
  { day: "Mar", job: "Cortes", count: 12 },
  { day: "Mie", job: "Instalacion", count: 7 },
  { day: "Jue", job: "Entrega", count: 4 },
  { day: "Vie", job: "Cobros", count: 9 }
];

export const quickStats = [
  { label: "Cuentas por cobrar", value: "C$ 428K", icon: Banknote },
  { label: "Cuentas por pagar", value: "C$ 213K", icon: ClipboardList },
  { label: "Ordenes listas", value: "24", icon: PackageCheck },
  { label: "Agenda semanal", value: "37", icon: CalendarDays }
];
