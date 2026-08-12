import { Router } from "express";
import { z } from "zod";
import { supabase } from "../config/supabase.js";
import { requireAuth } from "../middleware/auth.js";
import { auditLog } from "../utils/audit.js";

export const erpRouter = Router();

const modules = ["inventario", "proveedores", "compras", "clientes", "proyectos", "empleados", "caja", "bancos", "gastos", "reportes"];

const recordSchema = z.object({
  module: z.enum(modules),
  name: z.string().min(1),
  responsible: z.string().optional().nullable(),
  customer_or_vendor: z.string().optional().nullable(),
  amount: z.coerce.number().min(0).default(0),
  status: z.string().default("Borrador")
});

erpRouter.use(requireAuth);

erpRouter.get("/modules", (_req, res) => {
  res.json({ modules });
});

erpRouter.get("/materials", async (_req, res, next) => {
  try {
    if (!supabase) return res.status(500).json({ message: "Supabase no esta configurado." });

    const { data, error } = await supabase
      .from("materials")
      .select("id, name, purchase_price, current_stock, material_categories(name), units(name)")
      .is("deleted_at", null)
      .order("name");

    if (error) throw error;

    const materials = (data ?? []).map((material) => ({
      id: material.id,
      name: material.name,
      purchase_price: Number(material.purchase_price ?? 0),
      current_stock: Number(material.current_stock ?? 0),
      category_name: material.material_categories?.name ?? "Sin categoria",
      unit_name: material.units?.name ?? "Unidad"
    }));

    res.json({ materials });
  } catch (error) {
    next(error);
  }
});

erpRouter.get("/dashboard", async (_req, res, next) => {
  try {
    if (!supabase) return res.status(500).json({ message: "Supabase no esta configurado." });

    const [
      projectsResult,
      paymentsResult,
      materialsResult,
      purchasesResult,
      expensesResult,
      employeePaymentsResult
    ] = await Promise.all([
      supabase.from("projects").select("id, status, production_cost, sale_price").is("deleted_at", null),
      supabase.from("client_payments").select("amount, payment_date"),
      supabase.from("materials").select("id, current_stock, minimum_stock").is("deleted_at", null),
      supabase.from("purchases").select("total, status").is("deleted_at", null),
      supabase.from("general_expenses").select("amount").is("deleted_at", null),
      supabase.from("employee_payments").select("amount")
    ]);

    const results = [projectsResult, paymentsResult, materialsResult, purchasesResult, expensesResult, employeePaymentsResult];
    const failed = results.find((result) => result.error);
    if (failed?.error) throw failed.error;

    const projects = projectsResult.data ?? [];
    const payments = paymentsResult.data ?? [];
    const materials = materialsResult.data ?? [];
    const purchases = purchasesResult.data ?? [];
    const expenses = expensesResult.data ?? [];
    const employeePayments = employeePaymentsResult.data ?? [];

    const currentMonth = new Date().toISOString().slice(0, 7);
    const incomeThisMonth = payments
      .filter((payment) => String(payment.payment_date).startsWith(currentMonth))
      .reduce((total, payment) => total + Number(payment.amount ?? 0), 0);
    const projectProfit = projects.reduce((total, project) => total + Number(project.sale_price ?? 0) - Number(project.production_cost ?? 0), 0);
    const purchaseDebt = purchases
      .filter((purchase) => purchase.status !== "Confirmada")
      .reduce((total, purchase) => total + Number(purchase.total ?? 0), 0);

    res.json({
      kpis: {
        monthlySales: incomeThisMonth,
        grossProfit: projectProfit,
        activeProjects: projects.filter((project) => !["Finalizado", "Cancelado"].includes(project.status)).length,
        criticalStock: materials.filter((material) => Number(material.current_stock) <= Number(material.minimum_stock)).length
      },
      quickStats: {
        receivable: projects.reduce((total, project) => total + Number(project.sale_price ?? 0), 0) - payments.reduce((total, payment) => total + Number(payment.amount ?? 0), 0),
        payable: purchaseDebt + expenses.reduce((total, expense) => total + Number(expense.amount ?? 0), 0),
        readyOrders: employeePayments.reduce((total, payment) => total + Number(payment.amount ?? 0), 0),
        weeklyAgenda: projects.filter((project) => !["Finalizado", "Cancelado"].includes(project.status)).length
      },
      revenue: [],
      production: [],
      activity: [],
      notifications: [],
      calendar: []
    });
  } catch (error) {
    next(error);
  }
});

erpRouter.get("/records", async (req, res, next) => {
  try {
    if (!supabase) return res.status(500).json({ message: "Supabase no esta configurado." });
    const module = String(req.query.module ?? "");
    const records = await getModuleRecords(module);
    res.json({ records });
  } catch (error) {
    next(error);
  }
});

erpRouter.post("/records", async (req, res, next) => {
  try {
    if (!supabase) return res.status(500).json({ message: "Supabase no esta configurado." });
    const body = recordSchema.parse(req.body);
    const record = await createModuleRecord(body, req.user.sub);

    await auditLog({
      userId: req.user.sub,
      action: "CREATE",
      entity: body.module,
      entityId: record.id,
      after: record,
      ip: req.ip
    });

    res.status(201).json({ record });
  } catch (error) {
    next(error);
  }
});

async function getModuleRecords(module) {
  if (!module || module === "inventario") {
    const { data, error } = await supabase
      .from("materials")
      .select("id, name, purchase_price, current_stock, minimum_stock, created_at, material_categories(name), suppliers(name)")
      .is("deleted_at", null)
      .order("created_at", { ascending: false });
    if (error) throw error;
    return (data ?? []).map((item) => mapRecord({
      id: item.id,
      module: "inventario",
      code: "MAT",
      name: item.name,
      responsible: item.material_categories?.name,
      customer_or_vendor: item.suppliers?.name,
      amount: Number(item.purchase_price ?? 0),
      status: Number(item.current_stock) <= Number(item.minimum_stock) ? "Stock critico" : "Disponible",
      progress: 0,
      created_at: item.created_at
    }));
  }

  const tableByModule = {
    proveedores: "suppliers",
    clientes: "clients",
    proyectos: "projects",
    empleados: "employees",
    compras: "purchases",
    caja: "cash_movements",
    bancos: "bank_movements",
    gastos: "general_expenses"
  };

  const table = tableByModule[module];
  if (!table) return [];

  const { data, error } = await supabase.from(table).select("*").order("created_at", { ascending: false });
  if (error) throw error;

  return (data ?? []).filter((item) => !item.deleted_at).map((item) => mapTableRecord(module, item));
}

async function createModuleRecord(body, userId) {
  const base = { created_by: userId };
  const inserts = {
    proveedores: { table: "suppliers", data: { name: body.name, notes: body.responsible, ...base } },
    clientes: { table: "clients", data: { name: body.name, notes: body.responsible, ...base } },
    empleados: { table: "employees", data: { name: body.name, position: body.responsible, salary: body.amount, ...base } },
    gastos: { table: "general_expenses", data: { category: body.responsible || "General", description: body.name, amount: body.amount, ...base } },
    caja: { table: "cash_movements", data: { movement_type: "Entrada", description: body.name, amount: body.amount || 1, payment_method: body.responsible, ...base } },
    bancos: { table: "bank_movements", data: { movement_type: "Deposito", description: body.name, amount: body.amount || 1, bank_name: body.responsible, ...base } }
  };

  const target = inserts[body.module];
  if (!target) {
    throw Object.assign(new Error("Este modulo requiere su formulario especifico."), { status: 400 });
  }

  const { data, error } = await supabase.from(target.table).insert(target.data).select("*").single();
  if (error) throw error;
  return mapTableRecord(body.module, data);
}

function mapTableRecord(module, item) {
  const name = item.name ?? item.description ?? item.project_number ?? item.concept ?? "Registro";
  return mapRecord({
    id: item.id,
    module,
    code: item.project_number ?? module.toUpperCase().slice(0, 3),
    name,
    responsible: item.position ?? item.category ?? item.payment_method ?? item.bank_name ?? item.status ?? null,
    customer_or_vendor: null,
    amount: Number(item.amount ?? item.total ?? item.sale_price ?? item.salary ?? 0),
    status: item.status ?? item.movement_type ?? (item.active === false ? "Inactivo" : "Activo"),
    progress: item.status === "Finalizado" ? 100 : 0,
    created_at: item.created_at
  });
}

function mapRecord(record) {
  return record;
}
