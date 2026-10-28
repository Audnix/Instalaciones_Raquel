# Instalaciones Raquel ERP

ERP web para una empresa de aluminio y vidrio, construido con React, Vite y un backend Express. La persistencia local activa usa SQL Server y SSMS.

## Base de datos (SQL Server / SSMS 22)

Los scripts de instalacion, esquema relacional y sincronizacion estan en `Database/SQLServer/`. Sigue el orden indicado en `Database/SQLServer/README.md`. Los scripts PostgreSQL de `database/` pertenecen a una implementacion alternativa y no son usados por el arranque SQL Server local.

## Arranque local

```bash
npm install
npm run server
```

`npm run server` inicia o reutiliza el backend y Vite. El navegador abre `http://localhost:5173/`; la terminal indica si SQL Server esta conectado. Mantén la terminal abierta mientras uses el ERP.

Para preparar SQL Server, copia `.env.example` a `.env`, cambia `DB_PASSWORD` por la clave privada configurada en SSMS y sigue las instrucciones de `Database/SQLServer/README.md`. Nunca subas `.env` ni contrasenas reales al repositorio.

## Alcance incluido

- Login personalizado con glassmorphism, modo claro/oscuro, validacion en tiempo real, mostrar/ocultar contrasena y estado de carga.
- Dashboard responsive con KPIs, graficos, calendario, timeline, notificaciones y tabla operativa.
- Modulos navegables para ventas, compras, inventario, clientes, proveedores, proyectos, produccion, RRHH, nomina, caja, bancos, contabilidad, costos, finanzas, reportes y auditoria.
- Componentes reutilizables para botones, tarjetas KPI, loader, shell responsive y tabla avanzada.
- PWA manifest para instalacion.
- Backend REST base con JWT, permisos, rate limiting, helmet, auditoria y soft delete.

## Produccion

La configuracion de produccion requiere credenciales privadas, autenticacion y un SQL Server accesible desde el backend. No uses las credenciales locales de desarrollo en un despliegue publico.
