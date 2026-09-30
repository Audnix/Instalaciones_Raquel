-- Semilla alineada al prototipo (erpStore + catalog + roles).
SET search_path TO public;

INSERT INTO warehouses (id, name, location) VALUES
  ('wh-central', 'Bodega central', 'Taller principal'),
  ('wh-torre', 'Obra Torre Azul', 'Proyecto'),
  ('wh-show', 'Showroom', 'Sala de ventas');

INSERT INTO product_categories (id, name) VALUES
  ('cat-perf', 'Perfiles'),
  ('cat-vid', 'Vidrios'),
  ('cat-acc', 'Accesorios'),
  ('cat-elec', 'Electrodomésticos');

INSERT INTO chart_of_accounts (code, name, type) VALUES
  ('Caja', 'Caja', 'activo'),
  ('Banco', 'Bancos', 'activo'),
  ('Inventario', 'Inventario de mercadería', 'activo'),
  ('Cuentas por cobrar', 'Cuentas por cobrar', 'activo'),
  ('Cuentas por pagar', 'Cuentas por pagar', 'pasivo'),
  ('Ventas', 'Ingresos por ventas', 'ingreso'),
  ('Costo de ventas', 'Costo de ventas', 'gasto'),
  ('Gastos operativos', 'Gastos operativos', 'gasto'),
  ('INSS por pagar', 'INSS por pagar', 'pasivo'),
  ('IR por pagar', 'IR por pagar', 'pasivo'),
  ('Nómina', 'Gasto de nómina', 'gasto'),
  ('Descuadre detectado', 'Cuenta transitoria de descuadre', 'activo'),
  ('Pendiente auditoría', 'Pendiente de conciliación', 'pasivo');

INSERT INTO users (id, full_name, email, password_hash, password_plain, hierarchy, active) VALUES
  ('u-super', 'Raquel López', 'admin@raquel.com', crypt('raquel2026', gen_salt('bf')), 'raquel2026', 'superadmin', TRUE),
  ('u-fin', 'María Contadora', 'contador@raquel.com', crypt('raquel2026', gen_salt('bf')), 'raquel2026', 'administrador', TRUE),
  ('u-prod', 'Carlos Producción', 'produccion@raquel.com', crypt('raquel2026', gen_salt('bf')), 'raquel2026', 'administrador', TRUE),
  ('u-sales', 'Ana Ventas', 'vendedor@raquel.com', crypt('raquel2026', gen_salt('bf')), 'raquel2026', 'estandar', TRUE),
  ('u-buy', 'Luis Compras', 'compras@raquel.com', crypt('raquel2026', gen_salt('bf')), 'raquel2026', 'estandar', TRUE),
  ('u-guest', 'Invitado Gerencia', 'invitado@raquel.com', crypt('raquel2026', gen_salt('bf')), 'raquel2026', 'invitado', TRUE);

INSERT INTO user_areas (user_id, area) VALUES
  ('u-super', 'gobierno'), ('u-super', 'produccion'), ('u-super', 'finanzas'),
  ('u-super', 'contabilidad'), ('u-super', 'mercadotecnia'), ('u-super', 'compras'),
  ('u-super', 'ventas'), ('u-super', 'rrhh'), ('u-super', 'proyectos'),
  ('u-fin', 'finanzas'), ('u-fin', 'contabilidad'),
  ('u-prod', 'produccion'), ('u-prod', 'inventario'), ('u-prod', 'proyectos'),
  ('u-sales', 'ventas'), ('u-sales', 'mercadotecnia'),
  ('u-buy', 'compras'), ('u-buy', 'inventario'),
  ('u-guest', 'finanzas'), ('u-guest', 'mercadotecnia'), ('u-guest', 'proyectos');

INSERT INTO products (id, code, name, category_id, unit_price, min_quantity, created_at) VALUES
  ('p1', 'ALU-5020', 'Perfil serie 5020', 'cat-perf', 186, 40, NOW() - INTERVAL '40 days'),
  ('p2', 'VID-10T', 'Vidrio templado 10mm', 'cat-vid', 420, 20, NOW() - INTERVAL '40 days'),
  ('p3', 'SIL-NB', 'Silicon neutro blanco', 'cat-acc', 95, 12, NOW() - INTERVAL '30 days'),
  ('p4', 'ACC-HER', 'Herraje de ventana', 'cat-acc', 64, 30, NOW() - INTERVAL '30 days'),
  ('p5', 'ALU-7000', 'Perfil serie 7000', 'cat-perf', 245, 25, NOW() - INTERVAL '20 days'),
  ('p6', 'VID-6CL', 'Vidrio claro 6mm', 'cat-vid', 185, 35, NOW() - INTERVAL '18 days'),
  ('p7', 'MOS-INS', 'Mosquitero enrollable', 'cat-acc', 320, 10, NOW() - INTERVAL '12 days'),
  ('p8', 'BAR-12', 'Barandal templado 12mm', 'cat-vid', 890, 8, NOW() - INTERVAL '10 days'),
  ('e1', 'REF-18P', 'Refrigeradora 18 pies', 'cat-elec', 18500, 3, NOW() - INTERVAL '15 days'),
  ('e2', 'LAV-16K', 'Lavadora 16 kg', 'cat-elec', 12400, 4, NOW() - INTERVAL '14 days'),
  ('e3', 'SEC-8K', 'Secadora 8 kg', 'cat-elec', 9800, 3, NOW() - INTERVAL '14 days'),
  ('e4', 'MIC-30L', 'Microondas 30L', 'cat-elec', 3200, 6, NOW() - INTERVAL '12 days'),
  ('e5', 'EST-4Q', 'Estufa 4 quemadores', 'cat-elec', 7600, 4, NOW() - INTERVAL '11 days'),
  ('e6', 'AIR-12K', 'Aire acondicionado 12k BTU', 'cat-elec', 14900, 3, NOW() - INTERVAL '10 days'),
  ('e7', 'TV-55S', 'Smart TV 55 pulgadas', 'cat-elec', 16800, 5, NOW() - INTERVAL '9 days'),
  ('e8', 'LIC-PRO', 'Licuadora profesional', 'cat-elec', 2100, 8, NOW() - INTERVAL '8 days'),
  ('e9', 'CAF-ESP', 'Cafetera espresso', 'cat-elec', 4500, 5, NOW() - INTERVAL '7 days'),
  ('e10', 'ASP-ROB', 'Aspiradora robot', 'cat-elec', 8900, 4, NOW() - INTERVAL '6 days'),
  ('e11', 'HOR-ELE', 'Horno eléctrico', 'cat-elec', 5400, 4, NOW() - INTERVAL '5 days'),
  ('e12', 'VEN-TOR', 'Ventilador de torre', 'cat-elec', 1800, 10, NOW() - INTERVAL '4 days');

INSERT INTO inventory_lots (id, product_id, warehouse_id, quantity, unit_cost, entry_date, origin_doc) VALUES
  ('l1', 'p1', 'wh-central', 120, 140, NOW() - INTERVAL '35 days', 'OC-448'),
  ('l1b', 'p1', 'wh-central', 80, 148, NOW() - INTERVAL '10 days', 'OC-448b'),
  ('l2', 'p2', 'wh-central', 36, 310, NOW() - INTERVAL '28 days', 'inicial'),
  ('l2b', 'p2', 'wh-torre', 22, 325, NOW() - INTERVAL '6 days', 'OC-455'),
  ('l3', 'p3', 'wh-central', 8, 62, NOW() - INTERVAL '20 days', 'inicial'),
  ('l4', 'p4', 'wh-central', 90, 38, NOW() - INTERVAL '22 days', 'inicial'),
  ('l5', 'p5', 'wh-central', 55, 190, NOW() - INTERVAL '14 days', 'OC-451'),
  ('l6', 'p6', 'wh-central', 70, 120, NOW() - INTERVAL '12 days', 'inicial'),
  ('l7', 'p7', 'wh-central', 9, 210, NOW() - INTERVAL '8 days', 'OC-460'),
  ('l8', 'p8', 'wh-central', 6, 640, NOW() - INTERVAL '5 days', 'inicial'),
  ('le1', 'e1', 'wh-show', 5, 14200, NOW() - INTERVAL '15 days', 'showroom'),
  ('le2', 'e2', 'wh-show', 6, 9800, NOW() - INTERVAL '14 days', 'showroom'),
  ('le3', 'e3', 'wh-show', 4, 7600, NOW() - INTERVAL '14 days', 'showroom'),
  ('le4', 'e4', 'wh-show', 12, 2400, NOW() - INTERVAL '12 days', 'showroom'),
  ('le5', 'e5', 'wh-show', 7, 5900, NOW() - INTERVAL '11 days', 'showroom'),
  ('le6', 'e6', 'wh-show', 4, 11800, NOW() - INTERVAL '10 days', 'showroom'),
  ('le7', 'e7', 'wh-show', 8, 12900, NOW() - INTERVAL '9 days', 'showroom'),
  ('le8', 'e8', 'wh-show', 15, 1500, NOW() - INTERVAL '8 days', 'showroom'),
  ('le9', 'e9', 'wh-show', 9, 3200, NOW() - INTERVAL '7 days', 'showroom'),
  ('le10', 'e10', 'wh-show', 5, 6900, NOW() - INTERVAL '6 days', 'showroom'),
  ('le11', 'e11', 'wh-show', 6, 4100, NOW() - INTERVAL '5 days', 'showroom'),
  ('le12', 'e12', 'wh-show', 18, 1100, NOW() - INTERVAL '4 days', 'showroom');

INSERT INTO promotions (id, title, blurb, min_subtotal, percent_off, active, badge) VALUES
  ('promo1', 'Combo Hogar 8%', 'Llevá electrodomésticos o kit de ventana y ahorrá desde C$ 3,000.', 3000, 8, TRUE, '-8%'),
  ('promo2', 'Renovación 12%', 'Compras fuertes de taller o showroom. Ideal para proyectos y packs TV + aire.', 10000, 12, TRUE, '-12%'),
  ('promo3', 'Mega pack 15%', 'Pedidos grandes: refrigeradora, lavadora o fachadas completas.', 20000, 15, TRUE, '-15%'),
  ('promo4', 'Arranque 5%', 'Descuento de bienvenida en compras desde C$ 1,500.', 1500, 5, TRUE, '-5%');

INSERT INTO parties (id, party_type, name, contact, phone, ruc, credit_limit, payment_terms) VALUES
  ('cl1', 'cliente', 'Grupo Hábitat', 'Rosa Méndez', '8888-1100', 'J0310000000001', 500000, '30 días'),
  ('cl2', 'cliente', 'Torre Azul', 'Iván Solís', '8777-2211', 'J0310000000002', 400000, '15 días'),
  ('cl3', 'cliente', 'Casa Norte', 'Elena Cruz', '8555-3344', NULL, 80000, 'contado'),
  ('cl4', 'cliente', 'Plaza Sur', 'Mario Peña', '8666-7788', 'J0310000000004', 200000, '30 días'),
  ('cl5', 'cliente', 'Residencial Sol', 'Patricia Gómez', '8444-9900', NULL, 120000, '15 días'),
  ('cl6', 'cliente', 'Clínica del Lago', 'Dr. Rivas', '8222-1010', 'J0310000000006', 150000, '30 días'),
  ('pv1', 'proveedor', 'Alumex', 'Compras Alumex', '2222-4400', 'J0310000000101', 0, '30 días'),
  ('pv2', 'proveedor', 'Vidrios del Pacífico', 'Karla Ruiz', '2255-9090', 'J0310000000102', 0, '15 días'),
  ('pv3', 'proveedor', 'Ferretería Central', 'José Duarte', '2277-3311', 'J0310000000103', 0, 'contado');

INSERT INTO kardex (id, product_id, lot_id, move_type, quantity, unit_cost, moved_at, reason, document_ref, user_id, user_name) VALUES
  ('kx1', 'p2', 'l2', 'salida', 6, 310, NOW() - INTERVAL '4 days', 'Venta FAC-1092', 'FAC-1092', 'u-sales', 'Ana Ventas'),
  ('kx2', 'p1', 'l1', 'entrada', 40, 140, NOW() - INTERVAL '7 days', 'OC-448 Alumex', 'OC-448', 'u-buy', 'Luis Compras'),
  ('kx3', 'p5', 'l5', 'entrada', 55, 190, NOW() - INTERVAL '14 days', 'OC-451 Alumex', 'OC-451', 'u-buy', 'Luis Compras'),
  ('kx4', 'e4', 'le4', 'salida', 2, 2400, NOW() - INTERVAL '1 day', 'Venta FAC-1108', 'FAC-1108', 'u-sales', 'Ana Ventas');

INSERT INTO sales (id, sale_number, party_id, client_name, subtotal, discount_amount, promo_id, promo_code, tax_amount, total, payment_kind, status, sale_date, created_by, created_by_id) VALUES
  ('s1', 'FAC-1092', 'cl2', 'Torre Azul', 2520, 126, 'promo4', 'Arranque 5%', 359.10, 2753.10, 'contado', 'completed', NOW() - INTERVAL '4 days', 'Ana Ventas', 'u-sales'),
  ('s2', 'FAC-1095', 'cl1', 'Grupo Hábitat', 4232, 338.56, 'promo1', 'Combo Hogar 8%', 584.02, 4477.46, 'contado', 'completed', NOW() - INTERVAL '2 days', 'Ana Ventas', 'u-sales'),
  ('s3', 'FAC-1108', 'cl3', 'Casa Norte', 6400, 512, 'promo1', 'Combo Hogar 8%', 883.20, 6771.20, 'contado', 'completed', NOW() - INTERVAL '1 day', 'Ana Ventas', 'u-sales'),
  ('s4', 'FAC-1110', 'cl4', 'Plaza Sur', 20400, 3060, 'promo3', 'Mega pack 15%', 2601, 19941, 'contado', 'completed', NOW(), 'Ana Ventas', 'u-sales');

INSERT INTO sale_items (id, sale_id, product_id, quantity, unit_price, line_total) VALUES
  ('si1', 's1', 'p2', 6, 420, 2520),
  ('si2', 's2', 'p1', 20, 186, 3720),
  ('si3', 's2', 'p4', 8, 64, 512),
  ('si4', 's3', 'e4', 2, 3200, 6400),
  ('si5', 's4', 'e7', 1, 16800, 16800),
  ('si6', 's4', 'e12', 2, 1800, 3600);

INSERT INTO proformas (id, proforma_number, party_id, client_name, subtotal, discount_amount, promo_id, promo_code, tax_amount, total, status, valid_until, notes, created_at, created_by, created_by_id) VALUES
  ('pf1', 'PRF-220', 'cl5', 'Residencial Sol', 30900, 4635, 'promo3', 'Mega pack 15%', 3939.75, 30204.75, 'enviada', NOW() + INTERVAL '12 days', 'Pack cocina-lavado. Vigencia 12 días.', NOW() - INTERVAL '3 days', 'Ana Ventas', 'u-sales'),
  ('pf2', 'PRF-221', 'cl6', 'Clínica del Lago', 29800, 4470, 'promo3', 'Mega pack 15%', 3799.50, 29129.50, 'aceptada', NOW() + INTERVAL '8 days', 'Aires consultorios. Lista para facturar.', NOW() - INTERVAL '5 days', 'Ana Ventas', 'u-sales'),
  ('pf3', 'PRF-218', 'cl1', 'Oficinas Metro', 7400, 592, 'promo1', 'Combo Hogar 8%', 1021.20, 7829.20, 'borrador', NOW() + INTERVAL '15 days', 'Mamparas preliminares.', NOW() - INTERVAL '1 day', 'Ana Ventas', 'u-sales');

INSERT INTO proforma_items (id, proforma_id, product_id, quantity, unit_price, line_total) VALUES
  ('pi1', 'pf1', 'e1', 1, 18500, 18500),
  ('pi2', 'pf1', 'e2', 1, 12400, 12400),
  ('pi3', 'pf2', 'e6', 2, 14900, 29800),
  ('pi4', 'pf3', 'p6', 40, 185, 7400);

INSERT INTO purchases (id, purchase_number, party_id, supplier_name, total, status, purchase_date, received_at, created_by, created_by_id) VALUES
  ('c1', 'OC-448', 'pv1', 'Alumex', 5600, 'received', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', 'Luis Compras', 'u-buy'),
  ('c2', 'OC-451', 'pv1', 'Alumex', 10450, 'received', NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days', 'Luis Compras', 'u-buy'),
  ('c3', 'OC-455', 'pv2', 'Vidrios del Pacífico', 7150, 'received', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days', 'Luis Compras', 'u-buy'),
  ('c4', 'OC-460', 'pv3', 'Ferretería Central', 2100, 'ordered', NOW() - INTERVAL '1 day', NULL, 'Luis Compras', 'u-buy');

INSERT INTO purchase_items (id, purchase_id, product_id, quantity, unit_price, received_qty, line_total) VALUES
  ('ci1', 'c1', 'p1', 40, 140, 40, 5600),
  ('ci2', 'c2', 'p5', 55, 190, 55, 10450),
  ('ci3', 'c3', 'p2', 22, 325, 22, 7150),
  ('ci4', 'c4', 'p7', 10, 210, 0, 2100);

INSERT INTO accounts_payable (id, purchase_id, party_id, amount, balance, due_date, status) VALUES
  ('ap1', 'c1', 'pv1', 5600, 0, CURRENT_DATE - 7, 'pagada'),
  ('ap2', 'c2', 'pv1', 10450, 0, CURRENT_DATE - 14, 'pagada'),
  ('ap3', 'c3', 'pv2', 7150, 7150, CURRENT_DATE + 9, 'abierta'),
  ('ap4', 'c4', 'pv3', 2100, 2100, CURRENT_DATE + 14, 'abierta');

INSERT INTO accounting_entries (id, entry_number, description, debit, credit, debit_account, credit_account, entry_date, reference_type, reference_id) VALUES
  ('a1', 'AS-1001', 'Venta FAC-1092 Torre Azul', 2898, 2898, 'Caja', 'Ventas', NOW() - INTERVAL '4 days', 'sale', 's1'),
  ('a2', 'AS-1002', 'Compra OC-448 Alumex', 5600, 5600, 'Inventario', 'Cuentas por pagar', NOW() - INTERVAL '7 days', 'purchase', 'c1'),
  ('a3', 'AS-1003', 'Venta FAC-1095 Grupo Hábitat', 4866.80, 4866.80, 'Caja', 'Ventas', NOW() - INTERVAL '2 days', 'sale', 's2'),
  ('a4', 'AS-1004', 'Compra OC-451 Alumex', 10450, 10450, 'Inventario', 'Cuentas por pagar', NOW() - INTERVAL '14 days', 'purchase', 'c2'),
  ('a5', 'AS-1005', 'Venta FAC-1101 Plaza Sur', 2047, 2047, 'Banco', 'Ventas', NOW(), 'sale', 's4');

INSERT INTO finance_moves (id, move_type, category, amount, moved_at, note, user_name, user_id) VALUES
  ('f1', 'ingreso', 'Ventas', 2898, NOW() - INTERVAL '4 days', 'Cobro FAC-1092', 'Ana Ventas', 'u-sales'),
  ('f2', 'egreso', 'Materia prima', 5600, NOW() - INTERVAL '7 days', 'OC Alumex', 'Luis Compras', 'u-buy'),
  ('f3', 'ingreso', 'Ventas', 4866.80, NOW() - INTERVAL '2 days', 'Cobro FAC-1095', 'Ana Ventas', 'u-sales'),
  ('f4', 'egreso', 'Materia prima', 10450, NOW() - INTERVAL '14 days', 'OC-451', 'Luis Compras', 'u-buy'),
  ('f5', 'ingreso', 'Instalación', 2047, NOW(), 'Transferencia FAC-1101', 'Ana Ventas', 'u-sales'),
  ('f6', 'egreso', 'Servicios', 1850, NOW() - INTERVAL '3 days', 'Energía taller', 'María Contadora', 'u-fin');

INSERT INTO projections (id, year_month, label, expected_sales, expected_costs) VALUES
  ('pr1', '2026-01', 'Ene', 980000, 640000),
  ('pr2', '2026-02', 'Feb', 1120000, 710000),
  ('pr3', '2026-03', 'Mar', 1280000, 780000),
  ('pr4', '2026-04', 'Abr', 1540000, 930000),
  ('pr5', '2026-05', 'May', 1680000, 1010000),
  ('pr6', '2026-06', 'Jun', 1840000, 1198000),
  ('pr7', '2026-07', 'Jul', 1920000, 1210000),
  ('pr8', '2026-08', 'Ago', 2050000, 1295000),
  ('pr9', '2026-09', 'Sep', 2180000, 1340000);

INSERT INTO cash_moves (id, account, move_type, amount, moved_at, concept) VALUES
  ('k1', 'caja', 'entrada', 2898, NOW() - INTERVAL '4 days', 'Cobro FAC-1092'),
  ('k2', 'banco', 'salida', 5600, NOW() - INTERVAL '7 days', 'Pago OC-448'),
  ('k3', 'caja', 'entrada', 4866.80, NOW() - INTERVAL '2 days', 'Cobro FAC-1095'),
  ('k4', 'banco', 'entrada', 2047, NOW(), 'Transferencia FAC-1101'),
  ('k5', 'caja', 'salida', 1850, NOW() - INTERVAL '3 days', 'Energía taller'),
  ('k6', 'banco', 'salida', 10450, NOW() - INTERVAL '14 days', 'Pago OC-451');

INSERT INTO projects (id, code, name, party_id, client_name, amount, budget, progress, state, owner_name) VALUES
  ('pj1', 'PRJ-2048', 'Residencial Las Palmas', 'cl1', 'Grupo Hábitat', 486200, 470000, 68, 'Fabricación', 'Supervisor'),
  ('pj2', 'PRJ-2055', 'Fachada Torre Azul', 'cl2', 'Torre Azul', 312900, 300000, 42, 'Instalación', 'Obra'),
  ('pj3', 'PRJ-2060', 'Barandales Plaza Sur', 'cl4', 'Plaza Sur', 158400, 155000, 90, 'Cierre', 'Instalación'),
  ('pj4', 'PRJ-2062', 'Mamparas Clínica del Lago', 'cl6', 'Clínica del Lago', 97400, 95000, 55, 'Instalación', 'Obra');

INSERT INTO project_stages (id, project_id, name, start_date, end_date, cost_actual) VALUES
  ('ps1', 'pj1', 'Corte y ensamble', CURRENT_DATE - 40, CURRENT_DATE - 10, 180000),
  ('ps2', 'pj1', 'Instalación en obra', CURRENT_DATE - 9, CURRENT_DATE + 20, 95000),
  ('ps3', 'pj2', 'Fachada modular', CURRENT_DATE - 25, CURRENT_DATE + 15, 110000);

INSERT INTO production_orders (id, code, product_name, client_name, party_id, project_id, qty, stage, sprint, owner_name) VALUES
  ('o1', 'OT-2048', 'Ventanas residenciales', 'Las Palmas', 'cl1', 'pj1', 18, 'ensamble', 'Sprint 12', 'Carlos Producción'),
  ('o2', 'OT-2049', 'Fachada modular', 'Torre Azul', 'cl2', 'pj2', 4, 'corte', 'Sprint 12', 'Carlos Producción'),
  ('o3', 'OT-2050', 'Puerta de vidrio', 'Casa Norte', 'cl3', NULL, 2, 'backlog', 'Sprint 13', 'Taller'),
  ('o4', 'OT-2031', 'Barandal 12mm', 'Plaza Sur', 'cl4', 'pj3', 9, 'entregado', 'Sprint 11', 'Instalación'),
  ('o5', 'OT-2052', 'Mamparas clínicas', 'Clínica del Lago', 'cl6', 'pj4', 6, 'instalacion', 'Sprint 13', 'Instalación'),
  ('o6', 'OT-2053', 'Mosquiteros balcón', 'Residencial Sol', 'cl5', NULL, 14, 'corte', 'Sprint 13', 'Carlos Producción');

INSERT INTO employees (id, full_name, position, salary, area, user_id, hire_date) VALUES
  ('emp1', 'Carlos Producción', 'Supervisor de taller', 18500, 'Producción', 'u-prod', DATE '2022-03-01'),
  ('emp2', 'Ana Ventas', 'Asesora comercial', 14200, 'Ventas', 'u-sales', DATE '2023-01-15'),
  ('emp3', 'Luis Compras', 'Comprador', 13800, 'Compras', 'u-buy', DATE '2023-06-01'),
  ('emp4', 'María Contadora', 'Contadora general', 16800, 'Contabilidad', 'u-fin', DATE '2021-11-01'),
  ('emp5', 'Diego Instalador', 'Técnico de instalación', 12500, 'Producción', NULL, DATE '2024-02-01'),
  ('emp6', 'Sofía Bodega', 'Encargada de inventario', 11800, 'Inventario', NULL, DATE '2024-05-10');

INSERT INTO payroll_periods (id, period_label, start_date, end_date, status) VALUES
  ('nom-2026-09', 'Septiembre 2026', DATE '2026-09-01', DATE '2026-09-30', 'calculado');

INSERT INTO payroll_lines (id, period_id, employee_id, gross_pay, inss_laboral, ir, net_pay, inss_patronal, provision_aguinaldo) VALUES
  ('nl1', 'nom-2026-09', 'emp1', 18500, 1295.00, 0, 17205.00, 3996.00, 1541.67),
  ('nl2', 'nom-2026-09', 'emp2', 14200, 994.00, 0, 13206.00, 3067.20, 1183.33),
  ('nl3', 'nom-2026-09', 'emp3', 13800, 966.00, 0, 12834.00, 2980.80, 1150.00),
  ('nl4', 'nom-2026-09', 'emp4', 16800, 1176.00, 0, 15624.00, 3628.80, 1400.00),
  ('nl5', 'nom-2026-09', 'emp5', 12500, 875.00, 0, 11625.00, 2700.00, 1041.67),
  ('nl6', 'nom-2026-09', 'emp6', 11800, 826.00, 0, 10974.00, 2548.80, 983.33);

INSERT INTO audit_events (id, occurred_at, user_id, user_name, hierarchy, action, module, entity_table, entity_id, detail, before_data, after_data) VALUES
  ('au1', NOW(), NULL, 'Sistema', NULL, 'inicio', 'datos', NULL, NULL, 'Base operativa lista.', NULL, '{"ok": true}'::jsonb),
  ('au2', NOW(), 'u-sales', 'Ana Ventas', 'estandar', 'venta', 'ventas', 'sales', 's4', 'FAC-1110', NULL, '{"sale_number":"FAC-1110","total":19941}'::jsonb),
  ('au3', NOW() - INTERVAL '1 day', 'u-buy', 'Luis Compras', 'estandar', 'compra', 'compras', 'purchases', 'c4', 'OC-460 pedida', NULL, '{"status":"ordered"}'::jsonb);
