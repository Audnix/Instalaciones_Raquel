import {
  Boxes,
  BriefcaseBusiness,
  Building2,
  Calculator,
  ChartNoAxesCombined,
  Database,
  Factory,
  FileBarChart,
  GitBranch,
  ScrollText,
  HandCoins,
  HardHat,
  Landmark,
  Scale,
  ShieldCheck,
  ShoppingCart,
  Sparkles,
  Truck,
  UsersRound,
  UserCog,
  WalletCards
} from "lucide-react";
import type { ModuleId } from "../types/erp";

export const modules: {
  id: ModuleId;
  label: string;
  icon: typeof Factory;
  accent: string;
  group: string;
  description: string;
}[] = [
  { id: "produccion", label: "Producción", icon: Factory, accent: "bg-slate-500", group: "Producción", description: "Órdenes de taller, Kanban Scrum y entregas." },
  { id: "inventario", label: "Inventario", icon: Boxes, accent: "bg-moss", group: "Producción", description: "Entradas, salidas y valuación PEPS." },
  { id: "finanzas", label: "Finanzas", icon: ChartNoAxesCombined, accent: "bg-emerald-600", group: "Finanzas", description: "Resultado del mes, cuentas críticas y punto de equilibrio." },
  { id: "caja", label: "Caja", icon: WalletCards, accent: "bg-rose-500", group: "Finanzas", description: "Tesorería diaria de efectivo." },
  { id: "bancos", label: "Bancos", icon: Landmark, accent: "bg-sky-600", group: "Finanzas", description: "Movimientos bancarios." },
  { id: "contabilidad", label: "Contabilidad", icon: Calculator, accent: "bg-indigo-600", group: "Contabilidad", description: "Asientos, cuadre y libros en Excel." },
  { id: "costos", label: "Costos", icon: Scale, accent: "bg-orange-500", group: "Contabilidad", description: "Costo PEPS por línea y margen de contribución." },
  { id: "ventas", label: "Ventas", icon: ShoppingCart, accent: "bg-ember", group: "Mercadotecnia", description: "Facturas con IVA 15% y descuento de stock." },
  { id: "clientes", label: "Clientes", icon: UsersRound, accent: "bg-cyan-500", group: "Mercadotecnia", description: "Cartera comercial." },
  { id: "mercadotecnia", label: "Mercadotecnia", icon: Sparkles, accent: "bg-fuchsia-500", group: "Mercadotecnia", description: "Álbum mensual de productos con fecha y enlace." },
  { id: "compras", label: "Compras", icon: Truck, accent: "bg-brand-600", group: "Compras", description: "Órdenes de compra y recepción." },
  { id: "proveedores", label: "Proveedores", icon: Building2, accent: "bg-violet-500", group: "Compras", description: "Directorio de proveedores." },
  { id: "proyectos", label: "Proyectos", icon: BriefcaseBusiness, accent: "bg-amber-500", group: "Operación", description: "Obras de aluminio y vidrio." },
  { id: "rrhh", label: "RRHH", icon: HardHat, accent: "bg-teal-600", group: "Operación", description: "Personal y cargos." },
  { id: "nomina", label: "Nómina", icon: HandCoins, accent: "bg-lime-600", group: "Operación", description: "Planilla INSS, INATEC e IR." },
  { id: "reportes", label: "Reportes", icon: FileBarChart, accent: "bg-fuchsia-600", group: "Gobierno", description: "Consolidados por módulo." },
  { id: "auditoria", label: "Auditoría", icon: ShieldCheck, accent: "bg-zinc-600", group: "Gobierno", description: "Bitácora sellada, expediente ACID y radar de anomalías." },
  { id: "usuarios", label: "Usuarios y roles", icon: UserCog, accent: "bg-amber-600", group: "Gobierno", description: "Corona, escudo, mano y ojo: quién administra y quién ejecuta." },
  { id: "datos", label: "Base de datos", icon: Database, accent: "bg-brand-700", group: "Gobierno", description: "Esquema UML-E vivo: ER, clases, objetos, ACID y tablas del ERP." },
  { id: "metodologia", label: "Metodología y modelos", icon: GitBranch, accent: "bg-slate-700", group: "Gobierno", description: "Cobro pantalla a pantalla, PEPS, Kanban y roles." },
  { id: "ers", label: "ERS · Requerimientos", icon: ScrollText, accent: "bg-teal-700", group: "Gobierno", description: "Catálogo vivo RF/RNF/RD/RU/RS validado contra funciones." }
];
