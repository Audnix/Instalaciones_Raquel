# SQL Server (SSMS 22)

Estos scripts crean el esquema relacional SQL Server para las colecciones actuales del ERP y conservan `dbo.ErpState` como snapshot compatible con la app.

## Ejecucion en SSMS

Conectate a la instancia que aparece en el Explorador de objetos y ejecuta los archivos en este orden:

1. `00_create_database.sql` crea `[Instalaciones Raquel]` solo si no existe.
2. `01_schema.sql` crea `dbo.ErpState`; `02_seed.sql` inicializa su fila si hace falta.
3. `04_relational_schema.sql` crea las tablas base y las tablas de detalle.
4. `06_relations_and_spanish_views.sql` agrega las primeras llaves foraneas y vistas en espanol.
5. `07_connect_remaining_entities.sql` agrega relaciones de usuarios, promociones, finanzas, caja, contabilidad, produccion y nomina; tambien crea vistas de consulta relacionadas en espanol.
6. `05_sync_erp_state.sql` crea `dbo.usp_SaveErpState`, que valida y sincroniza las 19 colecciones y el detalle de nomina dentro de una transaccion.
7. Ejecuta `03_app_login.sql` con una cuenta administradora de SQL Server. Usa una clave privada y configura exactamente la misma en `DB_PASSWORD` del `.env` del proyecto.

Abre cada archivo desde **Archivo > Abrir > Archivo**, selecciona **Ejecutar** y confirma que no haya errores. Ejecuta los archivos SQL Server de esta carpeta, no los originales `Database/00_schema.sql` y `Database/01_seed.sql`, que son PostgreSQL.

## Persistencia actual

La app envia el estado completo al backend Express. `dbo.usp_SaveErpState` guarda el snapshot en `dbo.ErpState.Payload` y sincroniza en la misma transaccion todas las tablas relacionales. Los renglones de ventas, proformas y compras, los productos de album, las areas de usuario y los recibos por empleado se guardan en tablas hijas. Las llaves foraneas unen documentos, productos, terceros, usuarios, promociones, caja, finanzas y contabilidad. Las vistas `vw_*` muestran relaciones y nombres en espanol. `ErpState` es una tabla tecnica de compatibilidad, no una entidad de negocio; excluyela del diagrama funcional.

El estado enviado por el frontend sigue siendo la fuente de verdad de la app. Cada guardado reemplaza el contenido de las tablas normalizadas desde ese snapshot; no edites esas tablas manualmente esperando que el cambio sobreviva al siguiente guardado. Las contrasenas de usuario no se guardan en SQL Server; la autenticacion actual usa Supabase y el API elimina esos campos antes de persistir. Los productos con lotes, movimientos o documentos asociados no se pueden eliminar; esto protege las llaves foraneas y el historial.

Las tablas se llenan cuando el API recibe el primer `PUT /api/state`. Inicia SQL Server, luego el backend y el frontend; deja que la app termine la sincronizacion. El indicador debe mostrar conexion. `GET /health/database` comprueba la conexion SQL, y `SELECT COUNT(*) FROM dbo.Products` o `SELECT COUNT(*) FROM dbo.Sales` comprueba los datos sincronizados.

## Conexion local

Configura el archivo `.env` en la raiz del proyecto `Instalaciones_Raquel-main`, tomando `.env.example` como base. No guardes contrasenas reales en el repositorio. El backend debe ejecutarse en la misma computadora que SQL Server durante esta demostracion; no publiques el endpoint sin autenticacion de servidor.

Para esta instalacion, habilita TCP/IP en SQL Server Configuration Manager para `MSSQLSERVER2025`. En **Protocols for MSSQLSERVER2025 > TCP/IP > Properties > IP Addresses > IPAll**, limpia `TCP Dynamic Ports` y asigna `51433` a `TCP Port`; luego reinicia el servicio `SQL Server (MSSQLSERVER2025)`. Ese puerto estaba libre al preparar la configuracion. El `.env` queda con `DB_SERVER=127.0.0.1`, `DB_PORT=51433` y `DB_INSTANCE_NAME` vacio. El puerto `57711` no se debe usar para la app: los intentos de autenticacion alli llegan a un endpoint que rechaza el login de la aplicacion.