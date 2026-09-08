export type ReqEstado = "Validado" | "Parcial" | "Innovación";
export type ReqFamilia = "RF" | "RNF" | "RD" | "RU" | "RS";

export type Requirement = {
  id: string;
  familia: ReqFamilia;
  nombre: string;
  caracteristicas: string;
  descripcion: string;
  rnf: string;
  prioridad: "Alta" | "Media";
  estado: ReqEstado;
  area: string;
  fuente: string;
};

export type ValidationRow = {
  funcion: string;
  modulo: string;
  req: string;
  estado: ReqEstado;
  evidencia: string;
};

export const requirements: Requirement[] = [
  {
    id: "RF01",
    familia: "RF",
    nombre: "Autenticación de usuarios",
    caracteristicas: "Usuario y contraseña para módulos autorizados.",
    descripcion: "Acceso según jerarquía: superadmin, administrador, estándar e invitado.",
    rnf: "RNF01, RNF03",
    prioridad: "Alta",
    estado: "Validado",
    area: "Gobierno",
    fuente: "Corte 2"
  },
  {
    id: "RF02",
    familia: "RF",
    nombre: "Gestión de inventario",
    caracteristicas: "Entradas, salidas, consultas y kardex.",
    descripcion: "Producción administra existencias con validación de stock.",
    rnf: "RNF01, RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Producción",
    fuente: "Corte 2"
  },
  {
    id: "RF03",
    familia: "RF",
    nombre: "RBAC por jerarquía y áreas",
    caracteristicas: "Menú y acciones filtrados por rol.",
    descripcion: "Áreas compartidas sin romper la jerarquía de permisos.",
    rnf: "RNF03, RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Gobierno",
    fuente: "Corte 1/2"
  },
  {
    id: "RF04",
    familia: "RF",
    nombre: "Ingresos, egresos y proyecciones",
    caracteristicas: "Flujo monetario y series mensuales.",
    descripcion: "Control financiero para decisiones gerenciales.",
    rnf: "RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Finanzas",
    fuente: "Módulo"
  },
  {
    id: "RF05",
    familia: "RF",
    nombre: "Contabilidad diaria",
    caracteristicas: "Asientos débito/crédito.",
    descripcion: "Libro diario alineado a partida doble.",
    rnf: "RNF02, RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Finanzas",
    fuente: "Módulo"
  },
  {
    id: "RF06",
    familia: "RF",
    nombre: "Mercadotecnia y ABC",
    caracteristicas: "Estadísticas y clasificación de productos.",
    descripcion: "Comportamiento de ventas para priorizar compras.",
    rnf: "RNF01, RNF02",
    prioridad: "Media",
    estado: "Validado",
    area: "Comercial",
    fuente: "Módulo"
  },
  {
    id: "RF07",
    familia: "RF",
    nombre: "Compras y proveedores",
    caracteristicas: "OC, recepción y directorio.",
    descripcion: "Recepción crea lotes PEPS y asiento contable.",
    rnf: "RNF01, RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Comercial",
    fuente: "Corte 2"
  },
  {
    id: "RF08",
    familia: "RF",
    nombre: "Ventas con IVA 15%",
    caracteristicas: "Factura, stock, asiento y caja.",
    descripcion: "Transacción ACID observable de punta a punta.",
    rnf: "RNF01, RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Comercial",
    fuente: "Prototipo"
  },
  {
    id: "RF09",
    familia: "RF",
    nombre: "Caja y bancos",
    caracteristicas: "Tesorería diaria y bancaria.",
    descripcion: "Movimientos separados con trazabilidad.",
    rnf: "RNF02, RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Finanzas",
    fuente: "Expansión"
  },
  {
    id: "RF10",
    familia: "RF",
    nombre: "Costos de obra",
    caracteristicas: "Costeo por proyecto de aluminio/vidrio.",
    descripcion: "Materiales, mano de obra y margen estimado.",
    rnf: "RNF02",
    prioridad: "Media",
    estado: "Parcial",
    area: "Finanzas",
    fuente: "Módulo"
  },
  {
    id: "RF11",
    familia: "RF",
    nombre: "Producción Kanban/Scrum",
    caracteristicas: "OT por estados de sprint.",
    descripcion: "Backlog → corte → ensamble → instalación → entregado.",
    rnf: "RNF01",
    prioridad: "Alta",
    estado: "Validado",
    area: "Producción",
    fuente: "Prototipo"
  },
  {
    id: "RF12",
    familia: "RF",
    nombre: "Proyectos de instalación",
    caracteristicas: "Obras con cliente y avance.",
    descripcion: "Vínculo operativo con taller y costos.",
    rnf: "RNF01",
    prioridad: "Media",
    estado: "Validado",
    area: "Operación",
    fuente: "Módulo"
  },
  {
    id: "RF13",
    familia: "RF",
    nombre: "RRHH y nómina",
    caracteristicas: "Personal, cargos y planilla.",
    descripcion: "Liquidación básica por período.",
    rnf: "RNF01, RNF03",
    prioridad: "Media",
    estado: "Parcial",
    area: "Operación",
    fuente: "Módulo"
  },
  {
    id: "RF14",
    familia: "RF",
    nombre: "Reportes consolidados",
    caracteristicas: "Vistas gerenciales multi-módulo.",
    descripcion: "Soporta consulta de estado financiero (RU02).",
    rnf: "RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Gobierno",
    fuente: "RU02"
  },
  {
    id: "RF15",
    familia: "RF",
    nombre: "Auditoría y trazabilidad",
    caracteristicas: "Bitácora de mutaciones.",
    descripcion: "Usuario, módulo, acción, detalle y timestamp.",
    rnf: "RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Gobierno",
    fuente: "Innovación"
  },
  {
    id: "RF16",
    familia: "RF",
    nombre: "Usuarios y roles",
    caracteristicas: "Alta/edición con jerarquía y áreas.",
    descripcion: "Gobierno de accesos del ERP.",
    rnf: "RNF03",
    prioridad: "Alta",
    estado: "Validado",
    area: "Gobierno",
    fuente: "Jerarquía"
  },
  {
    id: "RF17",
    familia: "RF",
    nombre: "Data Hub central",
    caracteristicas: "Productos, stock, ventas y asientos.",
    descripcion: "Información centralizada y protegida por permisos.",
    rnf: "RNF03, RNF07",
    prioridad: "Alta",
    estado: "Validado",
    area: "Gobierno",
    fuente: "BD Corte 2"
  },
  {
    id: "RF18",
    familia: "RF",
    nombre: "Alertas de stock mínimo",
    caracteristicas: "Aviso cuando stock ≤ mínimo.",
    descripcion: "Campana, dashboard y módulo inventario destacan críticos.",
    rnf: "RNF01, RNF02",
    prioridad: "Media",
    estado: "Validado",
    area: "Producción",
    fuente: "Raquel Pulse"
  },
  {
    id: "RF19",
    familia: "RF",
    nombre: "Comprobante digital post-cobro",
    caracteristicas: "Recibo inmediato tras facturar.",
    descripcion: "El cajero ve el comprobante con IVA y folio.",
    rnf: "RNF01",
    prioridad: "Alta",
    estado: "Validado",
    area: "Comercial",
    fuente: "RU01"
  },
  {
    id: "RF20",
    familia: "RF",
    nombre: "Sync venta multi-módulo",
    caracteristicas: "Una venta dispara todos los efectos.",
    descripcion: "Inventario + kardex + asiento + caja en un acto.",
    rnf: "RNF02, RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Comercial",
    fuente: "RS01"
  },
  {
    id: "RF21",
    familia: "RF",
    nombre: "Kardex con costo PEPS",
    caracteristicas: "Historial y preview de lotes.",
    descripcion: "Muestra qué lote antiguo se consume primero.",
    rnf: "RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Producción",
    fuente: "RD02"
  },
  {
    id: "RF22",
    familia: "RF",
    nombre: "Proyecciones financieras",
    caracteristicas: "Series mensuales de ventas/costos.",
    descripcion: "Planeación preventiva del negocio.",
    rnf: "RNF02",
    prioridad: "Media",
    estado: "Validado",
    area: "Finanzas",
    fuente: "Finanzas"
  },
  {
    id: "RF23",
    familia: "RF",
    nombre: "Metodología embebida",
    caracteristicas: "Scrum, PEPS, partida doble, UML/ER.",
    descripcion: "El sistema documenta su propia ingeniería.",
    rnf: "RNF01",
    prioridad: "Media",
    estado: "Validado",
    area: "Gobierno",
    fuente: "UML/ER"
  },
  {
    id: "RF24",
    familia: "RF",
    nombre: "Pulso gerencial (dashboard)",
    caracteristicas: "Indicadores unificados por rol.",
    descripcion: "Stock, OT, margen, alertas y auditoría en vivo.",
    rnf: "RNF01, RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Gobierno",
    fuente: "INN-01"
  },
  {
    id: "RNF01",
    familia: "RNF",
    nombre: "Interfaz usable",
    caracteristicas: "Paneles y menús claros por perfil.",
    descripcion: "ISO/IEC 9126 Usabilidad.",
    rnf: "ISO 9126",
    prioridad: "Alta",
    estado: "Validado",
    area: "Calidad",
    fuente: "Corte 2"
  },
  {
    id: "RNF02",
    familia: "RNF",
    nombre: "Rendimiento",
    caracteristicas: "Respuesta oportuna en consultas.",
    descripcion: "ISO/IEC 9126 Eficiencia.",
    rnf: "ISO 9126",
    prioridad: "Alta",
    estado: "Parcial",
    area: "Calidad",
    fuente: "Corte 2"
  },
  {
    id: "RNF03",
    familia: "RNF",
    nombre: "Seguridad",
    caracteristicas: "Credenciales y autorización.",
    descripcion: "Sin permiso no hay escritura.",
    rnf: "ISO 9126",
    prioridad: "Alta",
    estado: "Validado",
    area: "Calidad",
    fuente: "IEEE 830"
  },
  {
    id: "RNF04",
    familia: "RNF",
    nombre: "Disponibilidad",
    caracteristicas: "Horario laboral de taller/caja.",
    descripcion: "Continuidad operativa del negocio.",
    rnf: "ISO 9126",
    prioridad: "Media",
    estado: "Innovación",
    area: "Calidad",
    fuente: "Pulse"
  },
  {
    id: "RNF05",
    familia: "RNF",
    nombre: "Portabilidad web",
    caracteristicas: "Navegador multiplataforma.",
    descripcion: "Windows / Linux / macOS.",
    rnf: "ISO 9126",
    prioridad: "Media",
    estado: "Validado",
    area: "Calidad",
    fuente: "Viabilidad"
  },
  {
    id: "RNF06",
    familia: "RNF",
    nombre: "Trazabilidad",
    caracteristicas: "Huella auditable en mutaciones.",
    descripcion: "Confianza y control interno.",
    rnf: "ISO 9126",
    prioridad: "Alta",
    estado: "Validado",
    area: "Calidad",
    fuente: "Auditoría"
  },
  {
    id: "RNF07",
    familia: "RNF",
    nombre: "Mantenibilidad modular",
    caracteristicas: "Módulos por área de negocio.",
    descripcion: "Evolución por cortes RUP.",
    rnf: "ISO 9126",
    prioridad: "Media",
    estado: "Validado",
    area: "Calidad",
    fuente: "Arquitectura"
  },
  {
    id: "RNF08",
    familia: "RNF",
    nombre: "Responsive",
    caracteristicas: "Escritorio y tablet de taller.",
    descripcion: "Layouts legibles en HD+.",
    rnf: "ISO 9126",
    prioridad: "Media",
    estado: "Parcial",
    area: "Calidad",
    fuente: "GUI"
  },
  {
    id: "RD01",
    familia: "RD",
    nombre: "IVA / normativa tributaria",
    caracteristicas: "IVA 15% en facturación.",
    descripcion: "Cálculo fiscal automático en ventas.",
    rnf: "RNF01, RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Dominio",
    fuente: "Corte 2"
  },
  {
    id: "RD02",
    familia: "RD",
    nombre: "Valuación PEPS",
    caracteristicas: "Sale primero el lote más antiguo.",
    descripcion: "Costo de egreso sin distorsión.",
    rnf: "RNF01, RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Dominio",
    fuente: "Corte 2"
  },
  {
    id: "RD03",
    familia: "RD",
    nombre: "Partida doble",
    caracteristicas: "Débito = crédito en cada hecho.",
    descripcion: "Asientos coherentes venta/compra.",
    rnf: "RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Dominio",
    fuente: "Metodología"
  },
  {
    id: "RD04",
    familia: "RD",
    nombre: "Transacciones ACID",
    caracteristicas: "Todo o nada en la venta.",
    descripcion: "Sin estados intermedios inconsistentes.",
    rnf: "RNF02, RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Dominio",
    fuente: "RS01"
  },
  {
    id: "RD05",
    familia: "RD",
    nombre: "Ética profesional SE",
    caracteristicas: "Calidad, costo y agenda claros.",
    descripcion: "Viabilidad Unidad II documentada en ERS.",
    rnf: "RNF03",
    prioridad: "Media",
    estado: "Validado",
    area: "Dominio",
    fuente: "Unidad II"
  },
  {
    id: "RD06",
    familia: "RD",
    nombre: "Flujo taller aluminio/vidrio",
    caracteristicas: "Estados de OT del dominio.",
    descripcion: "Corte, ensamble, instalación y entrega.",
    rnf: "RNF01",
    prioridad: "Media",
    estado: "Validado",
    area: "Dominio",
    fuente: "Kanban"
  },
  {
    id: "RU01",
    familia: "RU",
    nombre: "Comprobante post-cobro",
    caracteristicas: "Cajero genera recibo al instante.",
    descripcion: "Necesidad operativa en lenguaje natural.",
    rnf: "RNF01, RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Usuario",
    fuente: "Corte 2"
  },
  {
    id: "RU02",
    familia: "RU",
    nombre: "Estado financiero gerencial",
    caracteristicas: "Ingresos, egresos y margen.",
    descripcion: "Vista consolidada para dirección.",
    rnf: "RNF01, RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Usuario",
    fuente: "Corte 2"
  },
  {
    id: "RU03",
    familia: "RU",
    nombre: "Avanzar OT en tablero",
    caracteristicas: "Mover órdenes entre estados.",
    descripcion: "Flujo visible sin hojas sueltas.",
    rnf: "RNF01",
    prioridad: "Alta",
    estado: "Validado",
    area: "Usuario",
    fuente: "Producción"
  },
  {
    id: "RU04",
    familia: "RU",
    nombre: "Compra con stock al día",
    caracteristicas: "Recepción actualiza existencias.",
    descripcion: "Sin desfase bodega–contabilidad.",
    rnf: "RNF01",
    prioridad: "Alta",
    estado: "Validado",
    area: "Usuario",
    fuente: "Compras"
  },
  {
    id: "RU05",
    familia: "RU",
    nombre: "Consulta invitado",
    caracteristicas: "Solo lectura autorizada.",
    descripcion: "Reduce riesgo de alteración.",
    rnf: "RNF03",
    prioridad: "Media",
    estado: "Validado",
    area: "Usuario",
    fuente: "Jerarquía"
  },
  {
    id: "RU06",
    familia: "RU",
    nombre: "Ver kardex PEPS",
    caracteristicas: "Historial y lotes por producto.",
    descripcion: "Transparencia del costo de salida.",
    rnf: "RNF01",
    prioridad: "Media",
    estado: "Validado",
    area: "Usuario",
    fuente: "Inventario"
  },
  {
    id: "RU07",
    familia: "RU",
    nombre: "Preparar nómina",
    caracteristicas: "Planilla del personal activo.",
    descripcion: "Reduce errores de liquidación manual.",
    rnf: "RNF01",
    prioridad: "Media",
    estado: "Parcial",
    area: "Usuario",
    fuente: "RRHH"
  },
  {
    id: "RU08",
    familia: "RU",
    nombre: "Auditar cambios",
    caracteristicas: "Quién cambió qué y cuándo.",
    descripcion: "Control interno para gerencia.",
    rnf: "RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Usuario",
    fuente: "Auditoría"
  },
  {
    id: "RS01",
    familia: "RS",
    nombre: "Facturación ACID técnica",
    caracteristicas: "Update stock + asiento + caja.",
    descripcion: "Especificación técnica de venta.",
    rnf: "RNF01, RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Sistema",
    fuente: "Corte 2"
  },
  {
    id: "RS02",
    familia: "RS",
    nombre: "Cierre batch + alerta",
    caracteristicas: "Consolida ventas/compras al mayor.",
    descripcion: "Simulación de cierre nocturno con aviso de descuadre.",
    rnf: "RNF01, RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Sistema",
    fuente: "Corte 2"
  },
  {
    id: "RS03",
    familia: "RS",
    nombre: "Motor RBAC",
    caracteristicas: "can(module, action) + rutas.",
    descripcion: "Implementa RF01/RF03 en software.",
    rnf: "RNF03",
    prioridad: "Alta",
    estado: "Validado",
    area: "Sistema",
    fuente: "Auth"
  },
  {
    id: "RS04",
    familia: "RS",
    nombre: "Motor PEPS",
    caracteristicas: "Lotes por entryDate ascendente.",
    descripcion: "Garantiza RD02 en cada salida.",
    rnf: "RNF02",
    prioridad: "Alta",
    estado: "Validado",
    area: "Sistema",
    fuente: "Store"
  },
  {
    id: "RS05",
    familia: "RS",
    nombre: "Bus de auditoría",
    caracteristicas: "log(action, module, detail).",
    descripcion: "Todas las mutaciones publican evento.",
    rnf: "RNF06",
    prioridad: "Alta",
    estado: "Validado",
    area: "Sistema",
    fuente: "Store"
  },
  {
    id: "RS06",
    familia: "RS",
    nombre: "Store + sesión",
    caracteristicas: "Persistencia local del prototipo.",
    descripcion: "Presentación → auth → store → localStorage.",
    rnf: "RNF05, RNF07",
    prioridad: "Media",
    estado: "Validado",
    area: "Sistema",
    fuente: "Arquitectura"
  }
];

export const validationMatrix: ValidationRow[] = [
  { funcion: "Login con roles", modulo: "Auth", req: "RF01 / RS03", estado: "Validado", evidencia: "Login + AuthContext" },
  { funcion: "Menú filtrado por área", modulo: "Shell", req: "RF03 / RS03", estado: "Validado", evidencia: "AppShell" },
  { funcion: "Data Hub productos", modulo: "Datos", req: "RF17", estado: "Validado", evidencia: "DataHubPage" },
  { funcion: "Entradas/salidas + lotes PEPS", modulo: "Inventario", req: "RF02 / RF21 / RD02", estado: "Validado", evidencia: "InventoryView" },
  { funcion: "PEPS visual al vender", modulo: "Ventas", req: "RF21 / INN-02", estado: "Validado", evidencia: "SalesView preview" },
  { funcion: "Kanban OT", modulo: "Producción", req: "RF11 / RD06", estado: "Validado", evidencia: "ProductionView" },
  { funcion: "Factura + IVA 15%", modulo: "Ventas", req: "RF08 / RD01", estado: "Validado", evidencia: "SalesView" },
  { funcion: "Venta ACID multi-efecto", modulo: "Ventas", req: "RF20 / RS01 / RD04", estado: "Validado", evidencia: "erpStore.addSale" },
  { funcion: "Comprobante digital", modulo: "Ventas", req: "RF19 / RU01", estado: "Validado", evidencia: "Modal recibo" },
  { funcion: "Compras + lotes", modulo: "Compras", req: "RF07 / RU04", estado: "Validado", evidencia: "PurchasesView" },
  { funcion: "Clientes / proveedores", modulo: "Comercial", req: "RF07 / RF08", estado: "Validado", evidencia: "PartiesView" },
  { funcion: "Finanzas y proyecciones", modulo: "Finanzas", req: "RF04 / RF22 / RU02", estado: "Validado", evidencia: "FinanceView" },
  { funcion: "Caja y bancos", modulo: "Tesorería", req: "RF09", estado: "Validado", evidencia: "CashView" },
  { funcion: "Asientos + cierre batch", modulo: "Contabilidad", req: "RF05 / RS02 / RD03", estado: "Validado", evidencia: "AccountingView" },
  { funcion: "Costos de obra", modulo: "Costos", req: "RF10", estado: "Parcial", evidencia: "CostsView" },
  { funcion: "Proyectos", modulo: "Proyectos", req: "RF12", estado: "Validado", evidencia: "ProjectsView" },
  { funcion: "RRHH / nómina", modulo: "RRHH", req: "RF13 / RU07", estado: "Parcial", evidencia: "HrView" },
  { funcion: "Mercadotecnia ABC", modulo: "Comercial", req: "RF06 / RF14", estado: "Validado", evidencia: "MarketingView" },
  { funcion: "Auditoría", modulo: "Gobierno", req: "RF15 / RU08 / RS05", estado: "Validado", evidencia: "AuditView" },
  { funcion: "Usuarios y jerarquía", modulo: "Gobierno", req: "RF16", estado: "Validado", evidencia: "UsersPage" },
  { funcion: "Metodología UML/ER", modulo: "Gobierno", req: "RF23", estado: "Validado", evidencia: "MethodologyPage" },
  { funcion: "ERS vivo en sistema", modulo: "Gobierno", req: "ERS / RD05", estado: "Validado", evidencia: "RequirementsPage" },
  { funcion: "Dashboard Raquel Pulse", modulo: "Gobierno", req: "RF24 / RF18", estado: "Validado", evidencia: "Dashboard" },
  { funcion: "Alertas stock (campana)", modulo: "Shell", req: "RF18", estado: "Validado", evidencia: "AppShell Bell" }
];

export const innovations = [
  { id: "INN-01", title: "Pulso operativo en vivo", desc: "Dashboard unificado: stock crítico, OT, margen y auditoría." },
  { id: "INN-02", title: "PEPS visual por lotes", desc: "Antes de facturar ves qué lote antiguo se consume." },
  { id: "INN-03", title: "Asiento espejo automático", desc: "Venta/compra → partida doble + caja + auditoría." },
  { id: "INN-04", title: "Roles multi-área", desc: "Un usuario en varias áreas sin romper jerarquía." },
  { id: "INN-05", title: "ABC comercial", desc: "Clasifica productos por comportamiento de venta." },
  { id: "INN-06", title: "Cierre nocturno", desc: "Batch RS02 con alerta de descuadre contable." }
];
