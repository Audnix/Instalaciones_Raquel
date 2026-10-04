import { pool } from "../config/db.js";

const n = (value) => Number(value ?? 0);
const iso = (value) => (value ? new Date(value).toISOString() : new Date().toISOString());

export async function loadSnapshot() {
  const client = await pool.connect();
  try {
    const [
      products,
      lots,
      kardex,
      promotions,
      sales,
      saleItems,
      proformas,
      proformaItems,
      purchases,
      purchaseItems,
      accounting,
      finance,
      projections,
      production,
      parties,
      employees,
      projects,
      cash,
      users,
      areas,
      audit
    ] = await Promise.all([
      client.query(
        `SELECT p.id, p.code, p.name, c.name AS category, p.unit_price, p.min_quantity, p.created_at
         FROM products p JOIN product_categories c ON c.id = p.category_id
         WHERE p.deleted_at IS NULL ORDER BY p.created_at`
      ),
      client.query(
        `SELECT l.id, l.product_id, l.quantity, l.unit_cost, l.entry_date, w.name AS warehouse
         FROM inventory_lots l JOIN warehouses w ON w.id = l.warehouse_id`
      ),
      client.query(
        `SELECT id, product_id, move_type, quantity, unit_cost, moved_at, reason, user_name
         FROM kardex ORDER BY moved_at DESC`
      ),
      client.query(`SELECT * FROM promotions ORDER BY min_subtotal`),
      client.query(`SELECT * FROM sales ORDER BY sale_date DESC`),
      client.query(`SELECT * FROM sale_items`),
      client.query(`SELECT * FROM proformas ORDER BY created_at DESC`),
      client.query(`SELECT * FROM proforma_items`),
      client.query(`SELECT * FROM purchases ORDER BY purchase_date DESC`),
      client.query(`SELECT * FROM purchase_items`),
      client.query(`SELECT * FROM accounting_entries ORDER BY entry_date DESC`),
      client.query(`SELECT * FROM finance_moves ORDER BY moved_at DESC`),
      client.query(`SELECT * FROM projections ORDER BY year_month`),
      client.query(`SELECT * FROM production_orders ORDER BY code`),
      client.query(`SELECT * FROM parties WHERE deleted_at IS NULL ORDER BY name`),
      client.query(`SELECT * FROM employees WHERE deleted_at IS NULL ORDER BY full_name`),
      client.query(`SELECT * FROM projects WHERE deleted_at IS NULL ORDER BY code`),
      client.query(`SELECT * FROM cash_moves ORDER BY moved_at DESC`),
      client.query(`SELECT * FROM users WHERE deleted_at IS NULL ORDER BY full_name`),
      client.query(`SELECT user_id, area FROM user_areas`),
      client.query(`SELECT * FROM audit_events ORDER BY occurred_at DESC LIMIT 200`)
    ]);

    const itemsBySale = group(saleItems.rows, "sale_id");
    const itemsByProforma = group(proformaItems.rows, "proforma_id");
    const itemsByPurchase = group(purchaseItems.rows, "purchase_id");
    const areasByUser = group(areas.rows, "user_id");

    return {
      products: products.rows.map((row) => ({
        id: row.id,
        code: row.code,
        name: row.name,
        category: row.category,
        unitPrice: n(row.unit_price),
        minQuantity: n(row.min_quantity),
        createdAt: iso(row.created_at)
      })),
      lots: lots.rows.map((row) => ({
        id: row.id,
        productId: row.product_id,
        quantity: n(row.quantity),
        unitCost: n(row.unit_cost),
        entryDate: iso(row.entry_date),
        warehouseId: row.warehouse
      })),
      kardex: kardex.rows.map((row) => ({
        id: row.id,
        productId: row.product_id,
        type: row.move_type === "ajuste" ? "salida" : row.move_type,
        quantity: n(row.quantity),
        unitCost: n(row.unit_cost),
        date: iso(row.moved_at),
        reason: row.reason,
        userName: row.user_name
      })),
      promotions: promotions.rows.map((row) => ({
        id: row.id,
        title: row.title,
        blurb: row.blurb,
        minSubtotal: n(row.min_subtotal),
        percentOff: n(row.percent_off),
        active: row.active,
        badge: row.badge
      })),
      sales: sales.rows.map((row) => ({
        id: row.id,
        saleNumber: row.sale_number,
        clientName: row.client_name,
        items: (itemsBySale.get(row.id) ?? []).map(mapLine),
        subtotal: n(row.subtotal),
        discountAmount: n(row.discount_amount),
        promoCode: row.promo_code ?? undefined,
        taxAmount: n(row.tax_amount),
        total: n(row.total),
        status: row.status === "void" ? "draft" : row.status,
        saleDate: iso(row.sale_date),
        createdBy: row.created_by,
        qrPayload: row.qr_payload ?? ""
      })),
      proformas: proformas.rows.map((row) => ({
        id: row.id,
        proformaNumber: row.proforma_number,
        clientName: row.client_name,
        items: (itemsByProforma.get(row.id) ?? []).map(mapLine),
        subtotal: n(row.subtotal),
        discountAmount: n(row.discount_amount),
        promoCode: row.promo_code ?? undefined,
        taxAmount: n(row.tax_amount),
        total: n(row.total),
        status: row.status,
        validUntil: iso(row.valid_until),
        notes: row.notes ?? "",
        createdAt: iso(row.created_at),
        createdBy: row.created_by,
        qrPayload: row.qr_payload ?? "",
        convertedSaleId: row.converted_sale_id ?? undefined
      })),
      purchases: purchases.rows.map((row) => ({
        id: row.id,
        purchaseNumber: row.purchase_number,
        supplierName: row.supplier_name,
        items: (itemsByPurchase.get(row.id) ?? []).map(mapLine),
        total: n(row.total),
        status: row.status === "received" ? "received" : "ordered",
        purchaseDate: iso(row.purchase_date),
        createdBy: row.created_by
      })),
      accounting: accounting.rows.map((row) => ({
        id: row.id,
        entryNumber: row.entry_number,
        description: row.description,
        debit: n(row.debit),
        credit: n(row.credit),
        debitAccount: row.debit_account,
        creditAccount: row.credit_account,
        entryDate: iso(row.entry_date),
        referenceType: row.reference_type === "close" ? "manual" : row.reference_type,
        referenceId: row.reference_id ?? undefined
      })),
      finance: finance.rows.map((row) => ({
        id: row.id,
        type: row.move_type,
        category: row.category,
        amount: n(row.amount),
        date: iso(row.moved_at),
        note: row.note,
        userName: row.user_name
      })),
      projections: projections.rows.map((row) => ({
        id: row.id,
        month: row.label,
        expectedSales: n(row.expected_sales),
        expectedCosts: n(row.expected_costs)
      })),
      production: production.rows.map((row) => ({
        id: row.id,
        code: row.code,
        product: row.product_name,
        client: row.client_name,
        qty: n(row.qty),
        stage: row.stage,
        sprint: row.sprint,
        owner: row.owner_name
      })),
      parties: parties.rows.map((row) => ({
        id: row.id,
        name: row.name,
        contact: row.contact ?? "",
        phone: row.phone ?? "",
        type: row.party_type
      })),
      employees: employees.rows.map((row) => ({
        id: row.id,
        name: row.full_name,
        position: row.position,
        salary: n(row.salary),
        area: row.area
      })),
      projects: projects.rows.map((row) => ({
        id: row.id,
        code: row.code,
        name: row.name,
        client: row.client_name,
        amount: n(row.amount),
        progress: n(row.progress),
        state: row.state,
        owner: row.owner_name
      })),
      cash: cash.rows.map((row) => ({
        id: row.id,
        account: row.account,
        type: row.move_type,
        amount: n(row.amount),
        date: iso(row.moved_at),
        concept: row.concept
      })),
      users: users.rows.map((row) => ({
        id: row.id,
        name: row.full_name,
        email: row.email,
        password: row.password_plain || "raquel2026",
        hierarchy: row.hierarchy,
        areas: (areasByUser.get(row.id) ?? []).map((item) => item.area),
        active: row.active
      })),
      audit: audit.rows.map((row) => ({
        id: row.id,
        at: iso(row.occurred_at),
        userName: row.user_name,
        action: row.action,
        module: row.module,
        detail: row.detail
      }))
    };
  } finally {
    client.release();
  }
}

export async function saveSnapshot(db) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    await client.query(`
      DELETE FROM payroll_lines;
      DELETE FROM payroll_periods;
      DELETE FROM project_stages;
      DELETE FROM production_orders;
      DELETE FROM accounts_receivable;
      DELETE FROM sale_items;
      DELETE FROM proforma_items;
      DELETE FROM purchase_items;
      DELETE FROM accounts_payable;
      UPDATE proformas SET converted_sale_id = NULL;
      DELETE FROM sales;
      DELETE FROM proformas;
      DELETE FROM purchases;
      DELETE FROM kardex;
      DELETE FROM inventory_lots;
      DELETE FROM accounting_entries;
      DELETE FROM finance_moves;
      DELETE FROM cash_moves;
      DELETE FROM cash_sessions;
      DELETE FROM projections;
      DELETE FROM audit_events;
      DELETE FROM user_areas;
      DELETE FROM employees;
      DELETE FROM projects;
      DELETE FROM promotions;
      DELETE FROM parties;
      DELETE FROM products;
      DELETE FROM users;
    `);

    const categoryIds = new Map();
    for (const product of db.products ?? []) {
      const categoryId = await ensureCategory(client, product.category, categoryIds);
      await client.query(
        `INSERT INTO products (id, code, name, category_id, unit_price, min_quantity, created_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [product.id, product.code, product.name, categoryId, product.unitPrice, product.minQuantity, product.createdAt]
      );
    }

    for (const promo of db.promotions ?? []) {
      await client.query(
        `INSERT INTO promotions (id, title, blurb, min_subtotal, percent_off, active, badge)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [promo.id, promo.title, promo.blurb, promo.minSubtotal, promo.percentOff, promo.active, promo.badge]
      );
    }

    for (const party of db.parties ?? []) {
      await client.query(
        `INSERT INTO parties (id, party_type, name, contact, phone) VALUES ($1,$2,$3,$4,$5)`,
        [party.id, party.type, party.name, party.contact, party.phone]
      );
    }

    for (const user of db.users ?? []) {
      await client.query(
        `INSERT INTO users (id, full_name, email, password_hash, password_plain, hierarchy, active)
         VALUES ($1,$2,$3, crypt($4, gen_salt('bf')), $4, $5, $6)`,
        [user.id, user.name, user.email, user.password || "raquel2026", user.hierarchy, user.active]
      );
      for (const area of user.areas ?? []) {
        await client.query(`INSERT INTO user_areas (user_id, area) VALUES ($1,$2) ON CONFLICT DO NOTHING`, [user.id, area]);
      }
    }

    for (const lot of db.lots ?? []) {
      const warehouseId = await ensureWarehouse(client, lot.warehouseId);
      await client.query(
        `INSERT INTO inventory_lots (id, product_id, warehouse_id, quantity, unit_cost, entry_date)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [lot.id, lot.productId, warehouseId, lot.quantity, lot.unitCost, lot.entryDate]
      );
    }

    for (const move of db.kardex ?? []) {
      await client.query(
        `INSERT INTO kardex (id, product_id, move_type, quantity, unit_cost, moved_at, reason, user_name)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [move.id, move.productId, move.type, move.quantity, move.unitCost, move.date, move.reason, move.userName]
      );
    }

    const promoIds = new Set((db.promotions ?? []).map((item) => item.id));
    const promoByTitle = new Map((db.promotions ?? []).map((item) => [item.title, item.id]));

    for (const sale of db.sales ?? []) {
      const promoId = promoIds.has(sale.promoCode) ? sale.promoCode : promoByTitle.get(sale.promoCode) ?? null;
      await client.query(
        `INSERT INTO sales (id, sale_number, client_name, subtotal, discount_amount, promo_id, promo_code, tax_amount, total, payment_kind, status, sale_date, created_by, qr_payload)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'contado',$10,$11,$12,$13)`,
        [
          sale.id,
          sale.saleNumber,
          sale.clientName,
          sale.subtotal,
          sale.discountAmount ?? 0,
          promoId,
          sale.promoCode ?? null,
          sale.taxAmount,
          sale.total,
          sale.status,
          sale.saleDate,
          sale.createdBy,
          sale.qrPayload ?? null
        ]
      );
      for (const [index, item] of (sale.items ?? []).entries()) {
        await client.query(
          `INSERT INTO sale_items (id, sale_id, product_id, quantity, unit_price, line_total)
           VALUES ($1,$2,$3,$4,$5,$6)`,
          [`${sale.id}-i${index}`, sale.id, item.productId, item.quantity, item.unitPrice, item.quantity * item.unitPrice]
        );
      }
    }

    for (const row of db.proformas ?? []) {
      const promoId = promoIds.has(row.promoCode) ? row.promoCode : promoByTitle.get(row.promoCode) ?? null;
      await client.query(
        `INSERT INTO proformas (id, proforma_number, client_name, subtotal, discount_amount, promo_id, promo_code, tax_amount, total, status, valid_until, notes, created_at, created_by, qr_payload, converted_sale_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)`,
        [
          row.id,
          row.proformaNumber,
          row.clientName,
          row.subtotal,
          row.discountAmount ?? 0,
          promoId,
          row.promoCode ?? null,
          row.taxAmount,
          row.total,
          row.status,
          row.validUntil,
          row.notes ?? "",
          row.createdAt,
          row.createdBy,
          row.qrPayload ?? null,
          row.convertedSaleId ?? null
        ]
      );
      for (const [index, item] of (row.items ?? []).entries()) {
        await client.query(
          `INSERT INTO proforma_items (id, proforma_id, product_id, quantity, unit_price, line_total)
           VALUES ($1,$2,$3,$4,$5,$6)`,
          [`${row.id}-i${index}`, row.id, item.productId, item.quantity, item.unitPrice, item.quantity * item.unitPrice]
        );
      }
    }

    for (const purchase of db.purchases ?? []) {
      await client.query(
        `INSERT INTO purchases (id, purchase_number, supplier_name, total, status, purchase_date, created_by)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [purchase.id, purchase.purchaseNumber, purchase.supplierName, purchase.total, purchase.status, purchase.purchaseDate, purchase.createdBy]
      );
      for (const [index, item] of (purchase.items ?? []).entries()) {
        await client.query(
          `INSERT INTO purchase_items (id, purchase_id, product_id, quantity, unit_price, received_qty, line_total)
           VALUES ($1,$2,$3,$4,$5,$6,$7)`,
          [
            `${purchase.id}-i${index}`,
            purchase.id,
            item.productId,
            item.quantity,
            item.unitPrice,
            purchase.status === "received" ? item.quantity : 0,
            item.quantity * item.unitPrice
          ]
        );
      }
    }

    for (const entry of db.accounting ?? []) {
      await ensureAccount(client, entry.debitAccount);
      await ensureAccount(client, entry.creditAccount);
      const referenceType = ["sale", "purchase", "manual", "payroll", "cash", "close"].includes(entry.referenceType)
        ? entry.referenceType
        : "manual";
      await client.query(
        `INSERT INTO accounting_entries (id, entry_number, description, debit, credit, debit_account, credit_account, entry_date, reference_type, reference_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
        [
          entry.id,
          entry.entryNumber,
          entry.description,
          entry.debit,
          entry.credit,
          entry.debitAccount,
          entry.creditAccount,
          entry.entryDate,
          referenceType,
          entry.referenceId ?? null
        ]
      );
    }

    for (const move of db.finance ?? []) {
      await client.query(
        `INSERT INTO finance_moves (id, move_type, category, amount, moved_at, note, user_name)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [move.id, move.type, move.category, move.amount, move.date, move.note, move.userName]
      );
    }

    for (const row of db.projections ?? []) {
      const yearMonth = row.month.length === 7 ? row.month : `2026-${String(monthIndex(row.month)).padStart(2, "0")}`;
      await client.query(
        `INSERT INTO projections (id, year_month, label, expected_sales, expected_costs)
         VALUES ($1,$2,$3,$4,$5)
         ON CONFLICT (year_month) DO UPDATE SET label = EXCLUDED.label, expected_sales = EXCLUDED.expected_sales, expected_costs = EXCLUDED.expected_costs`,
        [row.id, yearMonth, row.month, row.expectedSales, row.expectedCosts]
      );
    }

    for (const order of db.production ?? []) {
      await client.query(
        `INSERT INTO production_orders (id, code, product_name, client_name, qty, stage, sprint, owner_name)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [order.id, order.code, order.product, order.client, order.qty, order.stage, order.sprint, order.owner]
      );
    }

    for (const employee of db.employees ?? []) {
      await client.query(
        `INSERT INTO employees (id, full_name, position, salary, area) VALUES ($1,$2,$3,$4,$5)`,
        [employee.id, employee.name, employee.position, employee.salary, employee.area]
      );
    }

    const projectStates = new Set([
      "Pendiente",
      "Autorizada",
      "En proceso",
      "Fabricación",
      "Instalación",
      "Cierre",
      "Liquidada",
      "Anulada"
    ]);
    for (const project of db.projects ?? []) {
      const state = projectStates.has(project.state) ? project.state : "En proceso";
      await client.query(
        `INSERT INTO projects (id, code, name, client_name, amount, progress, state, owner_name)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [project.id, project.code, project.name, project.client, project.amount, project.progress, state, project.owner]
      );
    }

    for (const move of db.cash ?? []) {
      await client.query(
        `INSERT INTO cash_moves (id, account, move_type, amount, moved_at, concept)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [move.id, move.account, move.type, move.amount, move.date, move.concept]
      );
    }

    for (const event of (db.audit ?? []).slice(0, 200)) {
      await client.query(
        `INSERT INTO audit_events (id, occurred_at, user_name, action, module, detail)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [event.id, event.at, event.userName, event.action, event.module, event.detail]
      );
    }

    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

export async function findUserByCredentials(email, password) {
  const result = await pool.query(
    `SELECT u.id, u.full_name, u.email, u.hierarchy, u.active, u.password_plain,
            ARRAY(SELECT area FROM user_areas a WHERE a.user_id = u.id) AS areas
     FROM users u
     WHERE lower(u.email) = lower($1)
       AND u.active = TRUE
       AND u.deleted_at IS NULL
       AND (u.password_plain = $2 OR u.password_hash = crypt($2, u.password_hash))
     LIMIT 1`,
    [email, password]
  );
  return result.rows[0] ?? null;
}

function mapLine(row) {
  return {
    productId: row.product_id,
    quantity: n(row.quantity),
    unitPrice: n(row.unit_price)
  };
}

function group(rows, key) {
  const map = new Map();
  for (const row of rows) {
    const list = map.get(row[key]) ?? [];
    list.push(row);
    map.set(row[key], list);
  }
  return map;
}

async function ensureCategory(client, name, cache) {
  const label = name || "General";
  if (cache.has(label)) return cache.get(label);
  const found = await client.query(`SELECT id FROM product_categories WHERE name = $1`, [label]);
  if (found.rowCount) {
    cache.set(label, found.rows[0].id);
    return found.rows[0].id;
  }
  const id = `cat-${slug(label)}`;
  await client.query(`INSERT INTO product_categories (id, name) VALUES ($1,$2) ON CONFLICT (id) DO NOTHING`, [id, label]);
  cache.set(label, id);
  return id;
}

async function ensureWarehouse(client, name) {
  const label = name || "Bodega central";
  const found = await client.query(`SELECT id FROM warehouses WHERE name = $1`, [label]);
  if (found.rowCount) return found.rows[0].id;
  const id = `wh-${slug(label)}`;
  await client.query(`INSERT INTO warehouses (id, name) VALUES ($1,$2) ON CONFLICT (id) DO NOTHING`, [id, label]);
  return id;
}

async function ensureAccount(client, code) {
  if (!code) return;
  await client.query(
    `INSERT INTO chart_of_accounts (code, name, type) VALUES ($1,$2,'activo') ON CONFLICT (code) DO NOTHING`,
    [code, code]
  );
}

function slug(value) {
  return String(value)
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 40);
}

function monthIndex(label) {
  const months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
  const index = months.indexOf(label);
  return index >= 0 ? index + 1 : 1;
}
