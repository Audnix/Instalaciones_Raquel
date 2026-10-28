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
| 2b | `11_actualizar_proveedores.sql` | Agrega los campos del directorio, fechas y revisión de proveedores (idempotente) |
| 3 | `03_inventario_y_comercial.sql` | Lotes PEPS, kardex, ventas, proformas, compras, álbum |
| 4 | `04_produccion_proyectos.sql` | Obras, etapas, órdenes de taller |
| 5 | `05_finanzas_nomina.sql` | Caja, finanzas, asientos, CxC, CxP, planilla |
| 6 | `06_vistas.sql` | Vistas en español con JOINs |
| 7 | `07_procedimiento_sincronizacion.sql` | `usp_SaveErpState` |
| 8 | `08_semilla.sql` | Usuarios, clientes, proveedores, productos, promociones |
| 9 | `09_login_aplicacion.sql` | Login de la API (misma clave que `.env`) |
| 9b | `12_sincronizacion_proveedores.sql` | Upsert idempotente, revisión de duplicados y permisos mínimos |
| 9c | `13_autenticacion_y_sesiones.sql` | Hash de credenciales, bloqueo de intentos y sesiones revocables |
| 9d | `14_recuperacion_contrasena.sql` | Códigos de recuperación de un solo uso y auditoría |
| 9e | `15_expedientes_proyectos.sql` | Estados de proyecto separados, API transaccional y eventos auditados |
| 9f | `16_talento_humano_base.sql` | Expedientes, directorio sin salarios, historial inicial y solicitudes privadas |
| 10 | `10_verificar.sql` | Tablas, FKs, vistas, procedimientos y conteos |

No mezcles este paquete con `Database/SQLServer/00`–`07` (scripts viejos).

### Actualizar una base ya instalada

Para actualizar una base ya instalada sin borrar datos, aplica únicamente las migraciones requeridas y en el orden indicado abajo; no ejecutes `db:rebuild`.

Para una base que ya tiene los campos de proveedores (comprobado en esta instancia), ejecuta manualmente en SSMS:

1. `07_procedimiento_sincronizacion.sql` — actualiza `usp_SaveErpState`; el snapshot general ya no reemplaza usuarios, proyectos, personal ni nóminas gestionados por servicios SQL específicos.
2. `12_sincronizacion_proveedores.sql` — instala el guardado idempotente por proveedor.
3. `13_autenticacion_y_sesiones.sql` — agrega hashes, bloqueo de intentos y sesiones revocables.
4. `14_recuperacion_contrasena.sql` — agrega códigos de recuperación y sus procedimientos.
5. `15_expedientes_proyectos.sql` — agrega estados independientes, eventos y procedimientos transaccionales de proyectos.
6. `16_talento_humano_base.sql` — agrega estado laboral, historial inicial, directorio sin salarios y solicitudes privadas.
7. `10_verificar.sql` — comprueba que las migraciones estén instaladas; no instala cambios.

Si la consulta a `COL_LENGTH('dbo.Parties','Email')` no devuelve valor, incluye antes `11_actualizar_proveedores.sql`. Ejecuta los scripts con una cuenta de migraciones con permisos DDL; la API no debe usar esa cuenta. No uses `00_reconstruir_desde_cero.sql`.

## Cómo se conecta el sistema

1. `.env`: `DB_SERVER`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.
2. La API (`server/src/config/sqlserver.js`) abre un pool a SQL Server.
3. `POST /api/auth/login` verifica bcrypt contra SQL Server, limita intentos y crea una sesión revocable.
4. La recuperación genera un código de seis dígitos por correo, lo guarda como HMAC, vence en 15 minutos y permite hasta cinco intentos. Al cambiar la contraseña, revoca las sesiones activas.
5. Los endpoints de ERP exigen token firmado y comprueban que la sesión siga vigente en SQL Server.
6. `PUT /api/suppliers/:id` guarda un proveedor con parámetros, una transacción y `usp_UpsertSupplier`; la identidad de auditoría sale de la sesión validada, no del navegador.
7. `GET/PUT /api/state` queda restringido a superadministración hasta sustituir el snapshot por servicios de negocio por módulo. El PUT general sigue siendo una ruta de transición, no persistencia concurrente recomendada para las demás áreas.
8. `GET/POST /api/projects` y `PATCH /api/projects/:id/workflow` leen y persisten expedientes en SQL Server; altas y cambios escriben un evento de proyecto y una entrada de auditoría dentro de sus procedimientos transaccionales. El snapshot general no borra ni vuelve a insertar los expedientes.
9. El frontend conserva la cola de proveedores y distingue conectado, restringido, cambios pendientes y guardado confirmado. El resto de módulos todavía requiere endpoints transaccionales por registro.
10. `GET/POST /api/hr/employees`, `GET /api/hr/me` y `/api/hr/requests` gestionan el directorio sin salario y solicitudes privadas; la alta y las decisiones usan procedimientos SQL que autorizan y auditan la operación. La migración 16 es requisito previo. Nómina, contratos, saldos/vacaciones calculados, asistencia, descargas de documentos y el historial salarial consultable siguen pendientes; no se presentan como funcionalidad disponible.
11. La orientación pública de derechos en `/derechos-y-seguridad` es general, no constituye asesoría legal ni afirma requisitos, plazos o montos vigentes. Debe validarse editorialmente antes de su uso institucional.

### Arranque y comprobación

Configura `.env` local con el servidor/puerto de SQL Server, `DB_NAME=Instalaciones Raquel`, `DB_USER=raquel_erp_app` y la contraseña de ese login. Las credenciales permanecen en el backend y no se deben copiar a variables `VITE_*`.

Genera localmente un `JWT_SECRET` con `node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"` y guárdalo solo en `.env`. Para activar por única vez la cuenta superadministradora existente, configura temporalmente `BOOTSTRAP_USER_EMAIL` (correo de un superadministrador activo de `dbo.AppUsers`) y `BOOTSTRAP_USER_PASSWORD` (contraseña aleatoria temporal de al menos 12 caracteres), ejecuta `npm run db:bootstrap-user`, y elimina `BOOTSTRAP_USER_PASSWORD` del archivo. La contraseña temporal se almacena como hash bcrypt y se debe cambiar en el primer inicio de sesión. Este procedimiento solo puede activarse una vez mientras ninguna cuenta tenga hash. Nunca incluyas secretos en la línea de comandos, frontend ni mensajes.

Para habilitar “Olvidé mi contraseña”, configura en `.env` `PASSWORD_RESET_SECRET` con otro secreto aleatorio de al menos 32 caracteres y los valores SMTP `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD` y, opcionalmente, `SMTP_FROM`. Usa el puerto 465 para SSL o 587 para STARTTLS. Aplica `14_recuperacion_contrasena.sql` con tu usuario de migraciones; el instalador normal (`npm run db:install`) también lo aplica. No compartas ni subas estas credenciales.

Los perfiles semilla (nombre, correo, jerarquía y áreas) se guardan en `dbo.AppUsers` y `dbo.AppUserAreas`, pero la migración no asigna contraseñas compartidas: cada usuario debe tener su propio hash y alta segura. El bootstrap solo activa al primer superadministrador. La administración de cuentas desde la pantalla todavía está deshabilitada; el endpoint autorizado y auditable para crear, editar y desactivar usuarios estándar, administradores e invitados es trabajo pendiente. Hasta implementarlo, solo la cuenta superadministradora activada puede iniciar sesión. No reutilices la clave temporal para otras cuentas ni vuelvas a ejecutar `08_semilla.sql` sobre una instalación operativa para administrar usuarios.

```powershell
npm run server
```

Ese comando inicia o reutiliza la API y la interfaz. Comprueba la conexión con una consulta real a SQL Server:

```powershell
Invoke-RestMethod http://127.0.0.1:4000/health/database
```

La respuesta debe indicar `status: ok`, la base `Instalaciones Raquel`, el login `raquel_erp_app`, los procedimientos de proveedor/autenticación y las sesiones. También requiere `JWT_SECRET` configurado. Después de modificar un proveedor, verifica sus datos con:

```sql
USE [Instalaciones Raquel];
SELECT PartyId, Name, SupplierCategory, Contact, Phone, Email, Address,
       ProductsServices, Ruc, PaymentTerms, SupplierStatus, NextReviewDate,
       Observations, CreatedAt, UpdatedAt
FROM dbo.Parties
WHERE PartyType = N'proveedor'
ORDER BY Name;
```

Confirma la instalación de sesiones y el estado de activación sin consultar ni mostrar hashes:

```sql
USE [Instalaciones Raquel];
SELECT OBJECT_ID(N'dbo.usp_GetAppUserForLogin', N'P') AS LoginProcedure,
       OBJECT_ID(N'dbo.usp_GetAppUserSession', N'P') AS SessionProcedure,
       (SELECT COUNT(*) FROM dbo.AppUserSessions WHERE RevokedAt IS NULL AND ExpiresAt > SYSUTCDATETIME()) AS ActiveSessions,
       (SELECT COUNT(*) FROM dbo.AppUsers WHERE PasswordHash IS NOT NULL AND IsActive = 1) AS ActivatedAccounts;
```

Para consultar el listado completo de colaboradores, invitaciones y contraseñas activas en SQL Server, ejecuta el script `18_verificar_usuarios.sql` o la consulta directa:

```sql
USE [Instalaciones Raquel];
GO

SELECT 
    u.AppUserId, u.Name, u.Email, u.Hierarchy, u.IsActive,
    CASE WHEN u.PasswordHash IS NOT NULL THEN 'Activada' ELSE 'Pendiente' END AS EstadoClave,
    i.TokenPrefix, i.DeliveryMethod, i.DeliveryStatus, i.CreatedAt, i.ExpiresAt, i.UsedAt
FROM dbo.AppUsers u
LEFT JOIN dbo.AppUserInvitations i ON u.AppUserId = i.AppUserId
ORDER BY u.Name ASC;
```

La API no requiere `db_owner`, `db_datawriter` ni DML sobre todo `dbo`; usa lectura puntual y ejecución de procedimientos. `npm run db:install` aplica scripts sin reconstruir la base. El instalador de esquema requiere una cuenta administrativa de Windows; la API se conecta como `raquel_erp_app`.

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

## Scripts de Carga Integral y Auditoría Total

Para inicializar todo el sistema con datos de negocio reales y coherentes bajo la legislación nicaragüense (DGI Ley 822, MITRAB Código del Trabajo Ley 185, INSS e INATEC), ejecuta:

```powershell
sqlcmd -S 127.0.0.1,51433 -E -C -i "Database\SQLServer_Completo\19_carga_integral_datos_reales.sql"
```

Para verificar y auditar que todas las tablas, relaciones de clave foránea, facturas con QR fiscal, contratos de trabajo, planillas de nómina y asientos de partida doble estén 100% cuadrados y sincronizados:

```powershell
sqlcmd -S 127.0.0.1,51433 -E -C -i "Database\SQLServer_Completo\20_verificar_integracion_total.sql"
```
