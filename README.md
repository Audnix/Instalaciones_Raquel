# Instalaciones Raquel ERP

ERP web profesional para una empresa de aluminio y vidrio, construido con React, Vite, Tailwind CSS, Framer Motion, React Router, TanStack Query, React Hook Form, Zod y un backend Express preparado para Supabase/PostgreSQL.

## Base de datos (PostgreSQL / DBeaver)

Esquema relacional completo + semilla del prototipo en `database/`. Conexión: `localhost:5432`, base `instalaciones_raquel`, usuario `raquel`, clave `raquel2026`. Detalle en `database/README.md`.

## Arranque local

```bash
npm install
npm run dev
```

Backend:

```bash
npm --prefix server install
npm run server
```

## Alcance incluido

- Login personalizado con glassmorphism, modo claro/oscuro, validacion en tiempo real, mostrar/ocultar contrasena y estado de carga.
- Dashboard responsive con KPIs, graficos, calendario, timeline, notificaciones y tabla operativa.
- Modulos navegables para ventas, compras, inventario, clientes, proveedores, proyectos, produccion, RRHH, nomina, caja, bancos, contabilidad, costos, finanzas, reportes y auditoria.
- Componentes reutilizables para botones, tarjetas KPI, loader, shell responsive y tabla avanzada.
- PWA manifest para instalacion.
- Backend REST base con JWT, permisos, rate limiting, helmet, auditoria y soft delete.

## Produccion

Frontend recomendado en Vercel, backend en Render/Railway y base de datos PostgreSQL/Supabase con tablas versionadas mediante migraciones.
