# Recuperación de consulta de nómina

Las capturas muestran un fallo de red y una lista sin consultar, no evidencia de pérdida de planillas. Se comprobaron respuestas 200 de API y SQL Server, directamente y mediante el proxy de localhost:5173. Las rutas de nómina y base de datos mediante el proxy devolvieron 401 sin token, como corresponde.

La interfaz usaba http://localhost:4000 explícitamente. Se centralizó la configuración: en desarrollo, las direcciones loopback del puerto 4000 usan el proxy existente /api del mismo sitio. Las API remotas, puertos personalizados y la configuración de producción se conservan. Esto evita depender de CORS y de la resolución IPv6 de localhost en el navegador. No se determinó el error específico del navegador: la herramienta de inspección no pudo inicializarse.

Nómina ahora distingue carga, error de consulta y lista vacía, muestra un aviso persistente y ofrece «Reintentar conexión». No reintenta operaciones de pago ni altera permisos, sesiones o datos.

Se añadieron dos pruebas para configuración local, remota y de producción. La compilación se registra en build_connection_recovery_2026-10-25.txt. No se realizó un recorrido autenticado de la pantalla ni un pago real.

Para cargar el cambio: abrir http://localhost:5173/nomina y recargar con Ctrl+F5. Si ya está abierta, usar «Reintentar conexión». Si la sesión ha vencido, iniciar sesión con la cuenta habitual.
