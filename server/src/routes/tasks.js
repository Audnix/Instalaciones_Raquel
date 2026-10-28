import { Router } from "express";
import sql from "mssql";
import { getDatabase } from "../config/sqlserver.js";
import { requireAuth } from "../middleware/auth.js";

export const tasksRouter = Router();

tasksRouter.use(requireAuth);

/* =========================================================
   BANDEJA "MIS TAREAS": PENDIENTES REALES ADAPTADOS AL ROL
   ========================================================= */
tasksRouter.get("/my-tasks", async (req, res, next) => {
  try {
    const user = req.user;
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    const tasks = [];
    const isSuper = user.hierarchy === "superadmin";
    const userAreas = user.areas || [];

    // 1. VENTAS / COMERCIAL
    if (isSuper || userAreas.includes("ventas") || userAreas.includes("mercadotecnia")) {
      // Cotizaciones por vencer o vigentes sin convertir
      const proformas = await pool.request().query(`
        SELECT TOP 5 ProformaNumber, ClientName, Total, ValidUntil, Status
        FROM dbo.Proformas
        WHERE Status IN (N'enviada', N'aceptada')
        ORDER BY ValidUntil ASC;
      `);
      for (const row of proformas.recordset || []) {
        tasks.push({
          id: `task-prf-${row.ProformaNumber}`,
          module: "ventas",
          title: `Cotización ${row.ProformaNumber} (${row.ClientName})`,
          detail: `Estado: ${row.Status}. Monto: C$ ${Number(row.Total).toLocaleString("es-NI")}. Vence: ${row.ValidUntil ? new Date(row.ValidUntil).toLocaleDateString("es-NI") : "Sin fecha"}`,
          priority: row.Status === "aceptada" ? "alta" : "media",
          actionUrl: "/ventas",
          actionLabel: row.Status === "aceptada" ? "Facturar pedido" : "Hacer seguimiento"
        });
      }
    }

    // 2. PRODUCCIÓN / TALLER
    if (isSuper || userAreas.includes("produccion")) {
      const orders = await pool.request().query(`
        SELECT TOP 5 Code, Product, Client, Stage, Owner
        FROM dbo.ProductionOrders
        WHERE Stage IN (N'backlog', N'corte', N'ensamble', N'instalacion')
        ORDER BY Code ASC;
      `);
      for (const row of orders.recordset || []) {
        tasks.push({
          id: `task-ot-${row.Code}`,
          module: "produccion",
          title: `Orden de taller ${row.Code} · ${row.Product}`,
          detail: `Cliente: ${row.Client} · Etapa: ${row.Stage} · Responsable: ${row.Owner}`,
          priority: row.Stage === "corte" ? "alta" : "media",
          actionUrl: "/produccion",
          actionLabel: "Ver en Kanban"
        });
      }
    }

    // 3. INVENTARIO / BODEGA
    if (isSuper || userAreas.includes("inventario") || userAreas.includes("produccion")) {
      const lowStock = await pool.request().query(`
        SELECT p.Code, p.Name, p.MinQuantity, ISNULL(SUM(l.Quantity), 0) AS OnHand
        FROM dbo.Products p
        LEFT JOIN dbo.InventoryLots l ON l.ProductId = p.ProductId
        WHERE p.DeletedAt IS NULL
        GROUP BY p.Code, p.Name, p.MinQuantity
        HAVING ISNULL(SUM(l.Quantity), 0) < p.MinQuantity;
      `);
      for (const row of lowStock.recordset || []) {
        tasks.push({
          id: `task-stock-${row.Code}`,
          module: "inventario",
          title: `Stock bajo mínimo: ${row.Name} (${row.Code})`,
          detail: `Existencia actual: ${row.OnHand} · Mínimo reglamentario: ${row.MinQuantity}`,
          priority: "alta",
          actionUrl: "/inventario",
          actionLabel: "Generar reposición"
        });
      }
    }

    // 4. COMPRAS / ABASTECIMIENTO
    if (isSuper || userAreas.includes("compras")) {
      const purchases = await pool.request().query(`
        SELECT TOP 5 PurchaseNumber, SupplierName, Total, Status
        FROM dbo.Purchases
        WHERE Status = N'ordered'
        ORDER BY PurchaseDate ASC;
      `);
      for (const row of purchases.recordset || []) {
        tasks.push({
          id: `task-oc-${row.PurchaseNumber}`,
          module: "compras",
          title: `Orden de compra ${row.PurchaseNumber} (${row.SupplierName})`,
          detail: `Monto: C$ ${Number(row.Total).toLocaleString("es-NI")}. Pendiente de recepción física en almacén.`,
          priority: "media",
          actionUrl: "/compras",
          actionLabel: "Recibir materiales"
        });
      }
    }

    // 5. FINANZAS / CONTABILIDAD
    if (isSuper || userAreas.includes("finanzas") || userAreas.includes("contabilidad")) {
      const pendingEntries = await pool.request().query(`
        SELECT TOP 5 EntryNumber, Description, Debit, EntryDate
        FROM dbo.AccountingEntries
        ORDER BY EntryDate DESC;
      `);
      tasks.push({
        id: "task-fin-balance",
        module: "contabilidad",
        title: "Revisión de balance y comprobación mensual",
        detail: "Verificar cuadre de débitos y créditos con libros auxiliares de inventario y caja.",
        priority: "media",
        actionUrl: "/contabilidad",
        actionLabel: "Revisar libros"
      });
    }

    // 6. TALENTO HUMANO / RRHH
    if (isSuper || userAreas.includes("rrhh")) {
      const pendingRequests = await pool.request().query(`
        SELECT TOP 5 r.HrRequestId, e.Name AS EmployeeName, r.Category, r.CreatedAt
        FROM dbo.HrRequests r
        JOIN dbo.Employees e ON e.EmployeeId = r.EmployeeId
        WHERE r.Status IN (N'enviada', N'en_revision')
        ORDER BY r.CreatedAt ASC;
      `);
      for (const row of pendingRequests.recordset || []) {
        tasks.push({
          id: `task-hr-${row.HrRequestId}`,
          module: "rrhh",
          title: `Solicitud de ${row.Category} · ${row.EmployeeName}`,
          detail: `Pendiente de resolución. Enviada: ${new Date(row.CreatedAt).toLocaleDateString("es-NI")}`,
          priority: "alta",
          actionUrl: "/rrhh",
          actionLabel: "Revisar y resolver"
        });
      }
    }

    // 7. COLABORADOR / TRABAJADOR ("MI ESPACIO")
    const myRequests = await pool.request()
      .input("UserId", sql.NVarChar(100), user.id)
      .query(`
        SELECT TOP 3 r.HrRequestId, r.Category, r.Status, r.CreatedAt
        FROM dbo.HrRequests r
        JOIN dbo.Employees e ON e.EmployeeId = r.EmployeeId
        WHERE e.AppUserId = @UserId
        ORDER BY r.CreatedAt DESC;
      `);
    for (const row of myRequests.recordset || []) {
      tasks.push({
        id: `task-my-req-${row.HrRequestId}`,
        module: "rrhh",
        title: `Mi solicitud de ${row.Category}`,
        detail: `Estado actual: ${row.Status}. Registrada: ${new Date(row.CreatedAt).toLocaleDateString("es-NI")}`,
        priority: "baja",
        actionUrl: "/rrhh",
        actionLabel: "Ver estado"
      });
    }

    res.json({
      count: tasks.length,
      tasks
    });
  } catch (error) {
    next(error);
  }
});
