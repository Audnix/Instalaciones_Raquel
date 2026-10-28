# Mapa de evidencia

Este mapa distingue requisito, pantalla de prototipo, servicio, datos y prueba. La existencia de una pantalla no demuestra persistencia, autorización efectiva, prueba aprobada ni conformidad legal. No se declara ningún resultado de carga, respaldo/restauración o revisión normativa que no tenga evidencia registrada.

## Equivalencias de requisitos del Corte 2

| ID conservado | Requisito vigente | Equivalencia del catálogo anterior | Estado actual |
|---|---|---|---|
| RF13 | Proyectos e instalaciones | RF12 anterior | Lectura/alta y estados separados vía API/SQL con eventos auditados; pruebas integradas SQL pendientes |
| RF14 | Nómina | Parte de RF13 anterior | Flujo propuesto; cálculo/pago locales y salarios de demostración retirados; reglas y servicio pendientes |
| RF15 | Reportes e indicadores | RF14 anterior | Catálogo propuesto; no ejecuta consultas ni exporta |
| RF16 | Auditoría e incidentes | RF15 anterior | Comprobación local sobre snapshot; cobertura servidor e incidentes pendientes |
| RF17 | Autenticación | RF01 anterior se conserva como antecedente | API y SQL diseñados; migraciones/configuración/pruebas integradas pendientes |
| RF25 | Talento humano | Parte de RF13 anterior | Directorio sin salario, alta de expediente y solicitudes privadas implementadas en código; pruebas SQL pendientes |
| RF26 | Usuarios y permisos | RF16 anterior | Permisos de módulo emitidos por la API; administración transaccional pendiente |
| RF27 | Continuidad y datos | RF17 anterior | Modelo/estado del prototipo; respaldo y restauración probados pendientes |

RF01 y RF12 se conservan en el historial documental del Corte 2; no se reutilizan para cambiar el significado de RF13–RF17. Los requisitos no incluidos en la tabla conservan sus identificadores. Las referencias a RF14–RF17 en el catálogo anterior se deben leer según esta tabla.

## Cadena de evidencia por requisito

| Requisito | Caso de uso | Modelo / datos | Pantalla | Servicio API | Prueba técnica |
|---|---|---|---|---|---|
| RF13 Proyectos | Consultar expediente; registrar cambios de autorización, etapa y cobro | `dbo.Projects`, `dbo.ProjectEvents`; `dbo.ProjectStages` conserva etapas detalladas | `ProjectsView` | `GET/POST /api/projects`, `PATCH /api/projects/:id/workflow`; los procedimientos registran eventos y auditoría | Build y sintaxis disponibles; prueba integrada SQL pendiente |
| RF14 Nómina | Preparar y revisar nómina (propuesto) | `dbo.PayrollRuns`, `dbo.PayrollRunItems`; estados/versiones de reglas incompletos | `HrView` presenta etapas propuestas; cálculo/pago deshabilitados | No existe servicio de ciclo de nómina | Prueba de cálculo y transición pendiente; revisión normativa pendiente |
| RF15 Reportes | Consultar reporte con período/filtros (propuesto) | Fuentes SQL de cada dominio; consulta consolidada no implementada | `ReportsPage` lista fuentes faltantes | No existe API de reportes | Pruebas de origen, autorización y exportación pendientes |
| RF16 Auditoría | Consultar evento; abrir incidente (propuesto) | `dbo.AuditEvents`; auditoría general no está conectada a cada mutación | `AuditPage` lee eventos del snapshot local | La ruta de proveedor registra algunos eventos; no hay API general de incidentes | Verificación local de hashes disponible; prueba de cobertura/alteración del servidor pendiente |
| RF17 Autenticación | Iniciar sesión, cambiar y recuperar contraseña | `dbo.AppUsers`, `dbo.AppUserSessions`, `dbo.AppPasswordResetCodes` | Login y recuperación de contraseña | `/api/auth/*`; recuperación requiere migración 14, secreto y SMTP | Build y sintaxis; prueba integrada contra SQL/SMTP pendiente |
| RF25 Talento humano | Consultar expediente propio/directorio; crear expediente autorizado; enviar y decidir solicitudes privadas | `dbo.Employees`, `dbo.EmployeeJobHistory`, `dbo.HrRequests`, `dbo.HrRequestEvents`, `dbo.vw_HrEmployeeDirectory`; salarios no se exponen en el directorio | `HrWorkspace`: Mi espacio, alta/directorio para administración, cola y solicitudes propias | `GET /api/hr/me`, `GET/POST /api/hr/employees`, `GET/POST /api/hr/requests`, `PATCH /api/hr/requests/:id`; procedimientos SQL validan alta/decisión y registran eventos | Sintaxis/build por ejecutar; pruebas integradas de aislamiento, roles, concurrencia y auditoría pendientes. Nómina, contratos, asistencia, documentos y vacaciones calculadas no implementados |
| RF26 Usuarios y permisos | Consultar permisos; administrar cuentas (propuesto) | `dbo.AppUsers`, `dbo.AppUserAreas`, sesiones | `UsersPage` y menú | La API entrega permisos de sesión; CRUD de usuarios pendiente | Pruebas de límites por área y separación de funciones pendientes |
| RF27 Continuidad | Consultar disponibilidad/guardado/restaurar (propuesto) | SQL Server y snapshot; catálogo de respaldo/restauración no existe | `DataHubPage` y estado del shell | `/health/database` verifica conexión/esquema | Ninguna prueba de respaldo o restauración registrada |

## Fases y validación

- **Captura de requisitos:** texto de los cortes y lista de cambios del usuario; no se atribuyen entrevistas no documentadas.
- **Análisis y diseño:** equivalencias de IDs anteriores y separación entre interfaz, API, datos y evidencia.
- **Implementación:** cambios de navegación, permisos de lectura entregados por la API, servicios SQL de proyectos y bloqueo de acciones locales que aparentaban registrar nómina.
- **Verificación técnica:** build/sintaxis del código ejecutables en local. Una ejecución contra SQL Server, SMTP, 30 usuarios o los umbrales de consulta no está documentada.
- **Revisión normativa:** pendiente de profesional responsable y fuentes oficiales vigentes. Las referencias legales en la pantalla son una lista inicial, no una interpretación ni aprobación.

Los porcentajes de requisitos catalogados o revisados no se presentan como porcentaje del sistema terminado.
