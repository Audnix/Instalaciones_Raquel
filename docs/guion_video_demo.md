# Guion de demostración — Instalaciones Raquel

Duración sugerida: 5–7 minutos. Presentar los registros como datos de prueba.

## Preparación

- Iniciar los servicios habituales y entrar con la cuenta autorizada para los módulos que se mostrarán.
- Cerrar pestañas con credenciales, SQL y herramientas de desarrollo; ocultar notificaciones personales.
- Comprobar en el navegador que Inicio, Mis tareas, Inventario y Ventas cargan sin errores. Esta revisión visual sigue pendiente por fallo de la herramienta de control del equipo.
- Elegir una factura confirmada existente. Para mostrar preparación de cobro, elegir una con saldo pendiente. Anotar su número para buscarla durante el video.
- Ensayar el recorrido antes de grabar. Preparar formularios no guarda operaciones; confirmar un cobro u orden sí modifica los datos. Usar un registro de prueba identificado si se decide completar ese paso.
- Comprobar la campana con clic y con Enter; cerrarla con Escape. El guion junto a Mis tareas significa cantidad sin confirmar, no cero pendientes.

## Recorrido

| Tiempo | Pantalla y acción | Explicación sugerida |
| --- | --- | --- |
| 0:00–0:40 | Inicio: indicadores, unidades vendidas y proyección | «Este sistema reúne las gestiones del taller. Los registros mostrados son de prueba. La proyección es una estimación y el resumen utiliza documentos registrados». |
| 0:40–1:20 | Mis tareas: actualizar, alternar prioridad y abrir un pendiente | «Cada área puede revisar sus pendientes y abrir el módulo relacionado». Si no hay tareas, mostrar el estado vacío sin inventar pendientes. |
| 1:20–2:00 | Inventario: activar Solo stock crítico, filtrar y regresar | «El filtro permite localizar materiales bajo mínimo y conserva la selección para continuar trabajando». |
| 2:00–2:50 | Barra superior: buscar el número de factura y abrir el resultado | «La búsqueda acorta el recorrido hasta el documento y muestra los accesos permitidos para la cuenta». |
| 2:50–3:50 | Factura: Cobrar en efectivo o banco; actualizar saldo y preparar formulario | «El cobro parte de una factura confirmada y del saldo pendiente. Prepararlo permite revisar referencia e importe antes de confirmar». Si no existe sesión del día abierta o no hay deuda, explicar el bloqueo que corresponda. |
| 3:50–4:50 | Factura: Preparar orden de taller; elegir línea | «La factura ayuda a preparar cliente, producto y cantidad. El responsable revisa unidad, medidas y código antes de crear la orden». Si ya existe el código sugerido, abrir la orden existente. |
| 4:50–5:40 | Producción: etapas y guía desplegable | «El avance lo registra el equipo según el trabajo realizado; la guía sirve de referencia». |
| 5:40–6:30 | Control operativo e historial | «Las diferencias permanecen visibles. Las planillas identificadas como pruebas conservan sus importes y su historial». |

## Explicaciones precisas para la grabación

- Ventas menos compras no equivale a utilidad neta ni al saldo disponible de caja.
- Las unidades del gráfico proceden de ventas confirmadas; los productos sin unidades vendidas no generan porciones.
- El cierre del banco del 27/10/2026 utilizó C$4,152.67 de conteo simulado y lleva esa explicación. No presentarlo como conciliación con un estado bancario real.
- Las tres planillas de prueba conservan diferencias históricas y están clasificadas como Prueba confirmada. No afirmar que sus cifras fueron corregidas.
- Los ensayos SQL en la copia restaurada se revirtieron; no deben aparecer como transacciones nuevas en el sistema operativo.
- Las pruebas automatizadas y la compilación no sustituyen el ensayo visual previo.

## Si surge un bloqueo durante el ensayo

Si una pantalla muestra un error de carga, detener ese tramo y registrar el mensaje exacto para corregirlo antes de grabar. Si el sistema rechaza una acción por saldo, sesión o permisos, comprobar ese requisito en lugar de modificar datos para ocultarlo.
