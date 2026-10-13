# Instalaciones Raquel — base de datos SQL Server

Base: `[Instalaciones Raquel]`. Cubrid el ERP actual: gobierno, catálogo, inventario PEPS, ventas/proformas/compras, producción, obras, tesorería, contabilidad, planilla INSS/IR y auditoría.

## Instalación rápida (recomendada)

Desde la carpeta del proyecto, con el `.env` ya apuntando a tu instancia:

```bash
npm run db:install
```

Para **borrar y recrear** la base desde cero:

```bash
npm run db:rebuild
```

Eso crea tablas, relaciones, vistas, el procedimiento `usp_SaveErpState`, semilla de maestros y el login `raquel_erp_app` con la clave de `DB_PASSWORD`.

## Instalación manual (SSMS)

Ejecuta **en orden**. Si quieres partir de cero, usa `00_reconstruir_desde_cero.sql` en lugar de `00_crear_base.sql`.

| Orden | Archivo | Qué hace |
|------:|---------|----------|
| 0b | `00_reconstruir_desde_cero.sql` | Borra y recrea la base |
| 0 | `00_crear_base.sql` | Crea la base si no existe |
| 1 | `01_catalogos.sql` | Etapas, bodegas, cuentas, meses, categorías |
| 2 | `02_gobierno_y_maestros.sql` | Usuarios, terceros, productos, empleados, snapshot |
| 3 | `03_inventario_y_comercial.sql` | Lotes PEPS, kardex, ventas, proformas, compras, álbum |
| 4 | `04_produccion_proyectos.sql` | Obras, etapas, órdenes de taller |
| 5 | `05_finanzas_nomina.sql` | Caja, finanzas, asientos, CxC, CxP, planilla |
| 6 | `06_vistas.sql` | Vistas en español con JOINs |
| 7 | `07_procedimiento_sincronizacion.sql` | `usp_SaveErpState` |
| 8 | `08_semilla.sql` | Usuarios, clientes, proveedores, productos, promociones |
| 9 | `09_login_aplicacion.sql` | Login de la API (misma clave que `.env`) |
| 10 | `10_verificar.sql` | Tablas, FKs, vistas y conteos |

No mezcles este paquete con `Database/SQLServer/00`–`07` (scripts viejos).

## Cómo se conecta el sistema

1. `.env`: `DB_SERVER`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.
2. La API (`server/src/config/sqlserver.js`) abre un pool a SQL Server.
3. `GET /api/state` lee `dbo.ErpState`.
4. `PUT /api/state` ejecuta `usp_SaveErpState`: guarda el JSON **y** normaliza las 19 colecciones en tablas con llaves foráneas.
5. El frontend (`erpStore`) sincroniza solo si `/health/database` responde bien.

## Mapa de relaciones

```
AppUsers ──< AppUserAreas
AppUsers ──< Employees (1:1 opcional)
Parties (cliente | proveedor)
Products ──> ProductCategories
Products ──< InventoryLots ──> Warehouses
Products ──< KardexMoves ──> AppUsers
Products ──< SaleItems >── Sales ──> Parties, Promotions, AppUsers
Products ──< ProformaItems >── Proformas ──> Parties, Promotions, Sales
Products ──< PurchaseItems >── Purchases ──> Parties, AppUsers
Products ──< CatalogAlbumProducts >── CatalogAlbums
Projects ──> Parties, Employees, ProjectStates
Projects ──< ProjectStages
Projects ──< ProductionOrders ──> Parties, Employees, ProductionStages
PayrollRuns ──< PayrollRunItems ──> Employees
Sales / Purchases / PayrollRuns / CashMoves
   <── AccountingEntries, FinanceMoves, CashMoves
Sales ──< AccountsReceivable
Purchases ──< AccountsPayable
```

`ErpState` es solo el puente JSON de la API. Para el diagrama funcional usa las tablas de negocio y `vw_MapaRelaciones`.
