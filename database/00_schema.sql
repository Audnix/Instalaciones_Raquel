-- =============================================================================
-- Instalaciones Raquel — esquema PostgreSQL (DBeaver / Beekeeper: New Connection → PostgreSQL)
-- Relacional 3NF para operación, PEPS, partida doble e IVA 15 %.
-- JSONB solo donde el dominio pide documento (auditoría antes/después, QR, snapshot fiscal).
-- Córdobas: NUMERIC(14,2) — RNF03 (nunca float).
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

SET search_path TO public;

-- -----------------------------------------------------------------------------
-- Catálogos de dominio
-- -----------------------------------------------------------------------------
CREATE TABLE warehouses (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL UNIQUE,
  location      TEXT,
  active        BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE product_categories (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL UNIQUE
);

CREATE TABLE chart_of_accounts (
  code          TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  type          TEXT NOT NULL CHECK (type IN ('activo', 'pasivo', 'patrimonio', 'ingreso', 'gasto')),
  parent_code   TEXT REFERENCES chart_of_accounts (code)
);

CREATE TABLE users (
  id            TEXT PRIMARY KEY,
  full_name     TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  password_plain TEXT,
  hierarchy     TEXT NOT NULL CHECK (hierarchy IN ('superadmin', 'administrador', 'estandar', 'invitado')),
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  failed_logins INTEGER NOT NULL DEFAULT 0 CHECK (failed_logins >= 0),
  locked_until  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ
);

CREATE TABLE user_areas (
  user_id       TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  area          TEXT NOT NULL CHECK (area IN (
                  'produccion', 'inventario', 'finanzas', 'contabilidad', 'mercadotecnia',
                  'compras', 'ventas', 'rrhh', 'proyectos', 'gobierno'
                )),
  PRIMARY KEY (user_id, area)
);

-- -----------------------------------------------------------------------------
-- Productos e inventario PEPS (lotes independientes; sale el más antiguo)
-- -----------------------------------------------------------------------------
CREATE TABLE products (
  id            TEXT PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,
  name          TEXT NOT NULL,
  category_id   TEXT NOT NULL REFERENCES product_categories (id),
  unit_price    NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
  min_quantity  NUMERIC(14,3) NOT NULL DEFAULT 0 CHECK (min_quantity >= 0),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ
);

CREATE TABLE inventory_lots (
  id            TEXT PRIMARY KEY,
  product_id    TEXT NOT NULL REFERENCES products (id),
  warehouse_id  TEXT NOT NULL REFERENCES warehouses (id),
  quantity      NUMERIC(14,3) NOT NULL CHECK (quantity >= 0),
  unit_cost     NUMERIC(14,2) NOT NULL CHECK (unit_cost >= 0),
  entry_date    TIMESTAMPTZ NOT NULL,
  origin_doc    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lots_peps ON inventory_lots (product_id, entry_date, id) WHERE quantity > 0;
CREATE INDEX idx_lots_warehouse ON inventory_lots (warehouse_id, product_id);

CREATE TABLE kardex (
  id            TEXT PRIMARY KEY,
  product_id    TEXT NOT NULL REFERENCES products (id),
  lot_id        TEXT REFERENCES inventory_lots (id),
  move_type     TEXT NOT NULL CHECK (move_type IN ('entrada', 'salida', 'ajuste')),
  quantity      NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
  unit_cost     NUMERIC(14,2) NOT NULL CHECK (unit_cost >= 0),
  moved_at      TIMESTAMPTZ NOT NULL,
  reason        TEXT NOT NULL,
  document_ref  TEXT,
  user_id       TEXT REFERENCES users (id),
  user_name     TEXT NOT NULL
);

CREATE INDEX idx_kardex_product_date ON kardex (product_id, moved_at DESC);

CREATE TABLE promotions (
  id            TEXT PRIMARY KEY,
  title         TEXT NOT NULL,
  blurb         TEXT NOT NULL,
  min_subtotal  NUMERIC(14,2) NOT NULL CHECK (min_subtotal >= 0),
  percent_off   NUMERIC(5,2) NOT NULL CHECK (percent_off >= 0 AND percent_off <= 100),
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  badge         TEXT NOT NULL
);

-- -----------------------------------------------------------------------------
-- Clientes y proveedores (misma entidad con tipo; RUC, crédito, evaluación)
-- -----------------------------------------------------------------------------
CREATE TABLE parties (
  id              TEXT PRIMARY KEY,
  party_type      TEXT NOT NULL CHECK (party_type IN ('cliente', 'proveedor')),
  name            TEXT NOT NULL,
  ruc             TEXT,
  contact         TEXT,
  phone           TEXT,
  email           TEXT,
  payment_terms   TEXT,
  credit_limit    NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (credit_limit >= 0),
  score_on_time   NUMERIC(5,2),
  score_price     NUMERIC(5,2),
  score_returns   NUMERIC(5,2),
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_parties_type_name ON parties (party_type, name);

-- -----------------------------------------------------------------------------
-- Ventas, proformas (detalle por composición) e IVA 15 %
-- -----------------------------------------------------------------------------
CREATE TABLE sales (
  id              TEXT PRIMARY KEY,
  sale_number     TEXT NOT NULL UNIQUE,
  party_id        TEXT REFERENCES parties (id),
  client_name     TEXT NOT NULL,
  subtotal        NUMERIC(14,2) NOT NULL CHECK (subtotal >= 0),
  discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  promo_id        TEXT REFERENCES promotions (id),
  promo_code      TEXT,
  tax_amount      NUMERIC(14,2) NOT NULL CHECK (tax_amount >= 0),
  total           NUMERIC(14,2) NOT NULL CHECK (total >= 0),
  payment_kind    TEXT NOT NULL DEFAULT 'contado' CHECK (payment_kind IN ('contado', 'credito')),
  status          TEXT NOT NULL CHECK (status IN ('draft', 'completed', 'void')),
  sale_date       TIMESTAMPTZ NOT NULL,
  created_by      TEXT NOT NULL,
  created_by_id   TEXT REFERENCES users (id),
  qr_payload      TEXT,
  line_snapshot   JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE sale_items (
  id            TEXT PRIMARY KEY,
  sale_id       TEXT NOT NULL REFERENCES sales (id) ON DELETE CASCADE,
  product_id    TEXT NOT NULL REFERENCES products (id),
  quantity      NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
  unit_price    NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
  line_total    NUMERIC(14,2) NOT NULL CHECK (line_total >= 0)
);

CREATE TABLE proformas (
  id              TEXT PRIMARY KEY,
  proforma_number TEXT NOT NULL UNIQUE,
  party_id        TEXT REFERENCES parties (id),
  client_name     TEXT NOT NULL,
  subtotal        NUMERIC(14,2) NOT NULL,
  discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  promo_id        TEXT REFERENCES promotions (id),
  promo_code      TEXT,
  tax_amount      NUMERIC(14,2) NOT NULL,
  total           NUMERIC(14,2) NOT NULL,
  status          TEXT NOT NULL CHECK (status IN ('borrador', 'enviada', 'aceptada', 'vencida', 'convertida')),
  valid_until     TIMESTAMPTZ NOT NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL,
  created_by      TEXT NOT NULL,
  created_by_id   TEXT REFERENCES users (id),
  qr_payload      TEXT,
  converted_sale_id TEXT REFERENCES sales (id)
);

CREATE TABLE proforma_items (
  id            TEXT PRIMARY KEY,
  proforma_id   TEXT NOT NULL REFERENCES proformas (id) ON DELETE CASCADE,
  product_id    TEXT NOT NULL REFERENCES products (id),
  quantity      NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
  unit_price    NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
  line_total    NUMERIC(14,2) NOT NULL CHECK (line_total >= 0)
);

CREATE TABLE accounts_receivable (
  id            TEXT PRIMARY KEY,
  sale_id       TEXT NOT NULL REFERENCES sales (id),
  party_id      TEXT REFERENCES parties (id),
  amount        NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  balance       NUMERIC(14,2) NOT NULL CHECK (balance >= 0),
  due_date      DATE,
  status        TEXT NOT NULL DEFAULT 'abierta' CHECK (status IN ('abierta', 'parcial', 'cobrada', 'vencida'))
);

-- -----------------------------------------------------------------------------
-- Compras y cuentas por pagar
-- -----------------------------------------------------------------------------
CREATE TABLE purchases (
  id                TEXT PRIMARY KEY,
  purchase_number   TEXT NOT NULL UNIQUE,
  party_id          TEXT REFERENCES parties (id),
  supplier_name     TEXT NOT NULL,
  total             NUMERIC(14,2) NOT NULL CHECK (total >= 0),
  tax_amount        NUMERIC(14,2) NOT NULL DEFAULT 0,
  payment_terms     TEXT,
  status            TEXT NOT NULL CHECK (status IN ('draft', 'ordered', 'authorized', 'received', 'cancelled')),
  purchase_date     TIMESTAMPTZ NOT NULL,
  received_at       TIMESTAMPTZ,
  created_by        TEXT NOT NULL,
  created_by_id     TEXT REFERENCES users (id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE purchase_items (
  id            TEXT PRIMARY KEY,
  purchase_id   TEXT NOT NULL REFERENCES purchases (id) ON DELETE CASCADE,
  product_id    TEXT NOT NULL REFERENCES products (id),
  quantity      NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
  unit_price    NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
  received_qty  NUMERIC(14,3) NOT NULL DEFAULT 0 CHECK (received_qty >= 0),
  line_total    NUMERIC(14,2) NOT NULL CHECK (line_total >= 0)
);

CREATE TABLE accounts_payable (
  id            TEXT PRIMARY KEY,
  purchase_id   TEXT NOT NULL REFERENCES purchases (id),
  party_id      TEXT REFERENCES parties (id),
  amount        NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  balance       NUMERIC(14,2) NOT NULL CHECK (balance >= 0),
  due_date      DATE,
  status        TEXT NOT NULL DEFAULT 'abierta' CHECK (status IN ('abierta', 'parcial', 'pagada'))
);

-- -----------------------------------------------------------------------------
-- Contabilidad (partida doble: débito = crédito) y tesorería
-- -----------------------------------------------------------------------------
CREATE TABLE accounting_entries (
  id              TEXT PRIMARY KEY,
  entry_number    TEXT NOT NULL UNIQUE,
  description     TEXT NOT NULL,
  debit           NUMERIC(14,2) NOT NULL CHECK (debit >= 0),
  credit          NUMERIC(14,2) NOT NULL CHECK (credit >= 0),
  debit_account   TEXT NOT NULL REFERENCES chart_of_accounts (code),
  credit_account  TEXT NOT NULL REFERENCES chart_of_accounts (code),
  entry_date      TIMESTAMPTZ NOT NULL,
  reference_type  TEXT NOT NULL CHECK (reference_type IN ('sale', 'purchase', 'manual', 'payroll', 'cash', 'close')),
  reference_id    TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_partida_doble CHECK (debit = credit)
);

CREATE TABLE finance_moves (
  id            TEXT PRIMARY KEY,
  move_type     TEXT NOT NULL CHECK (move_type IN ('ingreso', 'egreso')),
  category      TEXT NOT NULL,
  amount        NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  moved_at      TIMESTAMPTZ NOT NULL,
  note          TEXT NOT NULL,
  user_name     TEXT NOT NULL,
  user_id       TEXT REFERENCES users (id)
);

CREATE TABLE projections (
  id              TEXT PRIMARY KEY,
  year_month      TEXT NOT NULL UNIQUE,
  label           TEXT NOT NULL,
  expected_sales  NUMERIC(14,2) NOT NULL CHECK (expected_sales >= 0),
  expected_costs  NUMERIC(14,2) NOT NULL CHECK (expected_costs >= 0)
);

CREATE TABLE cash_moves (
  id            TEXT PRIMARY KEY,
  account       TEXT NOT NULL CHECK (account IN ('caja', 'banco')),
  move_type     TEXT NOT NULL CHECK (move_type IN ('entrada', 'salida')),
  amount        NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  moved_at      TIMESTAMPTZ NOT NULL,
  concept       TEXT NOT NULL,
  bank_name     TEXT,
  reference_id  TEXT
);

CREATE TABLE cash_sessions (
  id            TEXT PRIMARY KEY,
  opened_at     TIMESTAMPTZ NOT NULL,
  closed_at     TIMESTAMPTZ,
  opening_bal   NUMERIC(14,2) NOT NULL DEFAULT 0,
  closing_bal   NUMERIC(14,2),
  user_id       TEXT REFERENCES users (id),
  status        TEXT NOT NULL DEFAULT 'abierta' CHECK (status IN ('abierta', 'cerrada'))
);

-- -----------------------------------------------------------------------------
-- Producción, proyectos, RRHH y nómina
-- -----------------------------------------------------------------------------
CREATE TABLE projects (
  id            TEXT PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,
  name          TEXT NOT NULL,
  party_id      TEXT REFERENCES parties (id),
  client_name   TEXT NOT NULL,
  amount        NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  budget        NUMERIC(14,2),
  progress      INTEGER NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  state         TEXT NOT NULL CHECK (state IN (
                  'Pendiente', 'Autorizada', 'En proceso', 'Fabricación', 'Instalación', 'Cierre', 'Liquidada', 'Anulada'
                )),
  owner_name    TEXT NOT NULL,
  start_date    DATE,
  due_date      DATE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ
);

CREATE TABLE production_orders (
  id            TEXT PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,
  product_name  TEXT NOT NULL,
  client_name   TEXT NOT NULL,
  party_id      TEXT REFERENCES parties (id),
  project_id    TEXT REFERENCES projects (id),
  qty           NUMERIC(14,3) NOT NULL CHECK (qty > 0),
  stage         TEXT NOT NULL CHECK (stage IN ('backlog', 'corte', 'ensamble', 'instalacion', 'entregado')),
  sprint        TEXT NOT NULL,
  owner_name    TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE project_stages (
  id            TEXT PRIMARY KEY,
  project_id    TEXT NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  start_date    DATE,
  end_date      DATE,
  cost_actual   NUMERIC(14,2) NOT NULL DEFAULT 0
);

CREATE TABLE employees (
  id            TEXT PRIMARY KEY,
  full_name     TEXT NOT NULL,
  position      TEXT NOT NULL,
  salary        NUMERIC(14,2) NOT NULL CHECK (salary >= 0),
  area          TEXT NOT NULL,
  inss          TEXT,
  hire_date     DATE,
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  user_id       TEXT REFERENCES users (id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ
);

CREATE TABLE payroll_periods (
  id            TEXT PRIMARY KEY,
  period_label  TEXT NOT NULL,
  start_date    DATE NOT NULL,
  end_date      DATE NOT NULL,
  status        TEXT NOT NULL DEFAULT 'abierto' CHECK (status IN ('abierto', 'calculado', 'cerrado')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE payroll_lines (
  id                TEXT PRIMARY KEY,
  period_id         TEXT NOT NULL REFERENCES payroll_periods (id) ON DELETE CASCADE,
  employee_id       TEXT NOT NULL REFERENCES employees (id),
  gross_pay         NUMERIC(14,2) NOT NULL,
  inss_laboral      NUMERIC(14,2) NOT NULL DEFAULT 0,
  ir                NUMERIC(14,2) NOT NULL DEFAULT 0,
  net_pay           NUMERIC(14,2) NOT NULL,
  inss_patronal     NUMERIC(14,2) NOT NULL DEFAULT 0,
  provision_aguinaldo NUMERIC(14,2) NOT NULL DEFAULT 0,
  UNIQUE (period_id, employee_id)
);

-- -----------------------------------------------------------------------------
-- Auditoría (documento JSONB: valor anterior / valor nuevo — RF16)
-- -----------------------------------------------------------------------------
CREATE TABLE audit_events (
  id            TEXT PRIMARY KEY,
  occurred_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id       TEXT REFERENCES users (id),
  user_name     TEXT NOT NULL,
  hierarchy     TEXT,
  action        TEXT NOT NULL,
  module        TEXT NOT NULL,
  entity_table  TEXT,
  entity_id     TEXT,
  detail        TEXT NOT NULL,
  ip_address    INET,
  before_data   JSONB,
  after_data    JSONB
);

CREATE INDEX idx_audit_at ON audit_events (occurred_at DESC);
CREATE INDEX idx_audit_module ON audit_events (module, occurred_at DESC);

-- -----------------------------------------------------------------------------
-- Vistas de operación (consultas < 3s con índices — RNF02)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_stock AS
SELECT
  p.id AS product_id,
  p.code,
  p.name,
  p.min_quantity,
  COALESCE(SUM(l.quantity), 0) AS stock,
  COALESCE(SUM(l.quantity * l.unit_cost), 0) AS inventory_value,
  CASE WHEN COALESCE(SUM(l.quantity), 0) <= p.min_quantity THEN TRUE ELSE FALSE END AS critical
FROM products p
LEFT JOIN inventory_lots l ON l.product_id = p.id
WHERE p.deleted_at IS NULL
GROUP BY p.id, p.code, p.name, p.min_quantity;

CREATE OR REPLACE VIEW v_trial_balance AS
SELECT
  debit_account AS account_code,
  SUM(debit) AS debit_total,
  SUM(0) AS credit_total
FROM accounting_entries
GROUP BY debit_account
UNION ALL
SELECT
  credit_account,
  SUM(0),
  SUM(credit)
FROM accounting_entries
GROUP BY credit_account;

COMMENT ON TABLE inventory_lots IS 'Lotes PEPS: el egreso consume quantity>0 ordenado por entry_date ASC.';
COMMENT ON TABLE accounting_entries IS 'Partida doble: CHECK (debit = credit).';
COMMENT ON TABLE audit_events IS 'Bitácora inmutable de aplicación; before_data/after_data en JSONB.';
