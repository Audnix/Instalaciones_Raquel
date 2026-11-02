# Agentes del ERP

Configuración de proyecto para OpenCode, siguiendo https://opencode.ai/docs/agents/ y https://opencode.ai/docs/commands/.

Abre en OpenCode esta carpeta, la que contiene package.json y .opencode. Usa el proveedor y modelo que ya tengas conectado; estos archivos no fijan uno.

- /raquel-revisar: diagnóstico paralelo de SQL, gestiones y pruebas.
- /raquel-mejorar Añadir una opción para limpiar los filtros de inventario: ejemplo de mejora concreta con implementación y comprobaciones.
- @raquel-gestiones: consulta directa de propuestas.

El coordinador delega revisiones y serializa las ediciones. Calidad puede ejecutar npm test y npm run build; esos comandos crean artefactos locales y ejecutan las pruebas del repositorio. Los revisores no editan código. El implementador recibe archivos y alcance concretos.

No se ejecutan solos al abrir el programa: requieren invocar un comando o encargo. Esta configuración no repara la conexión con OpenCode Console. No se ha comprobado su carga en la aplicación local; el ejecutable opencode no estaba disponible en PATH al prepararla. Si tu versión usa otra sintaxis de configuración, consulta su documentación antes de adaptarla.
