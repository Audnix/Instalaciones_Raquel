# Instalaciones Raquel ERP

ERP web profesional para una empresa de aluminio y vidrio, construido con React, Vite, Tailwind CSS, Framer Motion, React Router, TanStack Query, React Hook Form, Zod y un backend Express preparado para Supabase/PostgreSQL.

## Arranque local

```bash
npm install
npm run dev
```

En otra terminal, inicia el backend:

```bash
npm --prefix server install
npm run server
```

## Conectar SQL Server local

1. En SQL Server Management Studio, ejecuta en orden `Database/SQLServer/00_create_database.sql`, `01_schema.sql` y `02_seed.sql`.
2. En `Database/SQLServer/03_app_login.sql`, cambia el valor de `@AppPassword` por una clave propia y ejecuta el script. Usa la misma clave como `DB_PASSWORD` en el archivo `.env` de la raiz del proyecto. No reutilices claves que ya hayan estado en archivos compartidos.
3. Crea `.env` copiando `.env.example` y verifica `DB_SERVER`, `DB_INSTANCE_NAME`, `DB_NAME` y `DB_USER`. `.env` esta excluido de Git.
4. Si usas una instancia nombrada y no conecta, habilita TCP/IP en SQL Server Configuration Manager, fija un puerto y configura `DB_PORT`; deja `DB_INSTANCE_NAME` vacio.
5. Instala las dependencias del backend y arranca frontend y backend en terminales separadas con `npm run dev` y `npm run server`.
6. Abre `http://127.0.0.1:4000/health/database`. Una respuesta con `"status":"ok"` confirma la conexion; el estado del ERP se sincroniza mediante `dbo.ErpState`.

La API utiliza SQL Server para el estado principal de la aplicacion. Algunas rutas REST de autenticacion y modulos todavia dependen de Supabase y no forman parte de esta conexion local.

## Alcance incluido

- Login personalizado con glassmorphism, modo claro/oscuro, validacion en tiempo real, mostrar/ocultar contrasena y estado de carga.
- Dashboard responsive con KPIs, graficos, calendario, timeline, notificaciones y tabla operativa.
- Modulos navegables para ventas, compras, inventario, clientes, proveedores, proyectos, produccion, RRHH, nomina, caja, bancos, contabilidad, costos, finanzas, reportes y auditoria.
- Componentes reutilizables para botones, tarjetas KPI, loader, shell responsive y tabla avanzada.
- PWA manifest para instalacion.
- Backend REST base con JWT, permisos, rate limiting, helmet, auditoria y soft delete.

## Produccion

Frontend recomendado en Vercel, backend en Render/Railway y base de datos PostgreSQL/Supabase con tablas versionadas mediante migraciones.
