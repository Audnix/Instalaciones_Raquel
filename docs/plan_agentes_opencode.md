# Propuesta de trabajo con agentes en OpenCode

Propuesta para este ERP. No instala agentes ni activa tareas en segundo plano.

## Primera ronda: diagnóstico en paralelo

1. Agente SQL: revisar el catálogo de scripts y la compatibilidad de las migraciones 26 y 32. Hay seis pruebas fallidas en databaseScripts.test.mjs y snapshotLinkPatch.test.mjs. Entregar causas, rutas y propuesta de corrección; no ejecutar migraciones ni cambiar datos.
2. Agente de experiencia de uso: revisar Ventas, Compras e Inventario; localizar campos repetidos, acciones confusas y formularios que pueden simplificarse. Entregar tres mejoras pequeñas con pasos para comprobarlas.
3. Agente de calidad: ejecutar npm test y npm run build; distinguir fallos existentes de los introducidos por cada cambio. Entregar resultados y comandos reproducibles.

Un coordinador reúne los informes, asigna archivos distintos a cada implementación y revisa la integración. Si dos trabajos requieren ModuleWorkspace.tsx o erpStore.tsx, integrarlos de forma secuencial o mediante ramas separadas.

## Otras automatizaciones útiles

- Revisar coherencia de ventas, kardex y asientos mediante las comprobaciones de integridad existentes; producir un informe de excepciones.
- Detectar enlaces o botones que no llevan al registro esperado y preparar correcciones pequeñas.
- Mantener una guía breve por puesto a partir del comportamiento confirmado del sistema.
- Revisar dependencias y proponer actualizaciones aisladas con compilación y pruebas.

Para auditorías con datos reales, acordar el alcance y utilizar una conexión de solo lectura. Las pruebas de desarrollo se ejecutan con datos de prueba. Los agentes no deben decidir cobros, pagos, salarios o ajustes de existencias.

## Encargo inicial para copiar en OpenCode

Revisa este repositorio con tres agentes: uno para catálogo y parches SQL, otro para simplificación de gestiones y otro para pruebas. Primero entrega diagnósticos independientes con archivos, causas y validación propuesta. Conserva los cambios locales existentes. No ejecutes migraciones ni reconstrucciones, no leas archivos .env y no modifiques datos operativos. El coordinador consolidará un máximo de cinco tareas, priorizadas por beneficio y esfuerzo; cada tarea debe indicar qué archivos tocaría y cómo se comprobaría.

## Referencia

OpenCode admite agentes y subagentes configurables. Verificar la versión instalada antes de escribir configuración, porque la sintaxis de permisos varía entre versiones.

https://opencode.ai/docs/agents/
