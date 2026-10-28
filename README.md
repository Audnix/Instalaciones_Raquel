# Instalaciones Raquel ERP

ERP web para una empresa de aluminio y vidrio, construido con React, Vite y un backend Express. La persistencia local activa usa SQL Server y SSMS.

## Base de datos (SQL Server / SSMS 22)

Los scripts de instalacion, esquema relacional y sincronizacion estan en `Database/SQLServer_Completo/`. Sigue el orden indicado en `Database/SQLServer_Completo/README.md`. El instalador aplica también la migración incremental más reciente; no uses `db:rebuild` para actualizar una base operativa.

## Arranque local

```bash
npm install
npm run server
```

`npm run server` inicia o reutiliza el backend y Vite. El navegador abre `http://localhost:5173/`; la terminal indica si SQL Server esta conectado. Mantén la terminal abierta mientras uses el ERP.

El puerto de la API se configura con `PORT` en `.env`; si queda vacío, se usa `4000`.

Para preparar SQL Server, copia `.env.example` a `.env`, cambia `DB_PASSWORD` por la clave privada configurada en SSMS y sigue las instrucciones de `Database/SQLServer_Completo/README.md`. Nunca subas `.env` ni contrasenas reales al repositorio.

Para activar la recuperación de contraseña, configura `PASSWORD_RESET_SECRET` y las variables `SMTP_*` descritas en `.env.example`, y aplica `Database/SQLServer_Completo/14_recuperacion_contrasena.sql` a tu base instalada. Para proyectos, aplica también `Database/SQLServer_Completo/15_expedientes_proyectos.sql`; para Talento humano, aplica `Database/SQLServer_Completo/16_talento_humano_base.sql`. Luego ejecuta `10_verificar.sql` para comprobar el esquema; ese script no instala cambios. Las instrucciones de actualización están en la guía SQL Server.

Talento humano ya permite consultar el directorio sin salarios, crear expedientes y tramitar solicitudes privadas con control de acceso desde la API. Nómina, contratos, asistencia, cálculo de saldos y descargas privadas aún no están implementados. La orientación pública `/derechos-y-seguridad` es informativa y debe revisarse antes de tratarse como guía laboral oficial.

## Alcance incluido

- Login personalizado con glassmorphism, modo claro/oscuro, validacion en tiempo real, mostrar/ocultar contrasena y estado de carga.
- Recuperacion de contrasena por codigo de correo con SMTP y codigos de un solo uso.
- Dashboard responsive con KPIs, graficos, calendario, timeline, notificaciones y tabla operativa.
- Modulos navegables para ventas, compras, inventario, clientes, proveedores, proyectos, produccion, RRHH, nomina, caja, bancos, contabilidad, costos, finanzas, reportes y auditoria.
- Componentes reutilizables para botones, tarjetas KPI, loader, shell responsive y tabla avanzada.
- PWA manifest para instalacion.
- Backend REST base con JWT, permisos, rate limiting, helmet, auditoria y soft delete.

## Produccion

La configuracion de produccion requiere credenciales privadas, autenticacion y un SQL Server accesible desde el backend. No uses las credenciales locales de desarrollo en un despliegue publico.
