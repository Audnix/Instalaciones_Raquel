# Estado actual y pendientes

## Comprobado y aplicado

- Respaldo: VERIFYONLY aprobado; copia restaurada ONLINE y sin errores visibles de CHECKDB según mensajes de SSMS aportados por el usuario.
- Copia de prueba actualizada con parche 34; guardado y venta aprobados.
- Pruebas SQL de compra, lotes, kardex, contabilidad, cotización, factura, producción, cobro, abonos y anulación: aprobadas, con rollback confirmado.
- Banco: apertura, movimientos, saldo, cierre y reapertura aprobados en copia. Caja antigua rechaza movimientos.
- Búsqueda, accesos desde tareas, factura a cobro y preparación de taller implementados. La última ejecución de pruebas automatizadas aprobó 103 casos.
- Producción utiliza una guía desplegable en lugar de indicar comprobaciones físicas como realizadas sin evidencia.

## Revisión visual pendiente

Preparación del video: consultar `guion_video_demo.md`. Inicio ahora distingue ventas menos compras de utilidad neta, limita el gráfico a unidades de ventas confirmadas y respeta permisos en los accesos a ventas e inventario.

La campana de alertas ahora abre y cierra con clic o teclado, admite Escape y se cierra al cambiar de pantalla. El contador lateral muestra un guion mientras la cantidad de tareas no esté confirmada; los fallos de consulta no se presentan como cero pendientes.

Mis tareas y el contador comparten validación de respuestas: los datos incompletos producen un error de consulta, las prioridades deben ser reconocidas y los enlaces deben ser rutas internas. El control operativo retira el informe anterior mientras consulta uno nuevo y muestra el estado de carga.

El control de Windows y navegador falla al iniciar con “failed to write kernel assets”. No se ha comprobado visualmente el navegador ni se afirma que estas pruebas de servicios sustituyan esa revisión.

Recorridos a comprobar con la sesión del usuario:

1. Buscar una factura existente en la barra superior; abrir el resultado y comprobar el resaltado.
2. Desde la factura, abrir Cobrar en efectivo o banco según permisos. Actualizar saldo y preparar el formulario. Verificar referencia, concepto e importe; salir sin confirmar si no corresponde un cobro real.
3. Abrir Preparar orden de taller, seleccionar una línea y completar el formulario. Revisar cliente, trabajo, cantidad, unidad y código; salir sin crear una orden si no corresponde trabajo real.
4. Volver a inventario y proveedores para comprobar que se conservan los filtros.

## Datos de prueba confirmados y mantenimiento aplicado

El usuario confirmó expresamente que la sesión y las tres planillas son datos de prueba.

- Banco del 27/10/2026: cerrado mediante el procedimiento habitual con C$4,152.67 como conteo simulado y explicación explícita. No equivale a una conciliación bancaria real. No quedan sesiones antiguas abiertas en la auditoría.
- Las tres planillas se clasificaron como pruebas mediante eventos de historial. Se conservaron estados, acumulados, netos y movimientos. No se crearon recibos ficticios ni se eliminaron registros.
- La auditoría conserva las tres diferencias y las identifica como Prueba confirmada; no se consideran matemáticamente corregidas.
- El ensayo se revirtió primero; después se aplicó el mantenimiento autorizado en una transacción y se verificó con una consulta independiente.
- El reporte y la captura previa de los registros están en mantenimiento_datos_prueba.json y datos_prueba_antes_mantenimiento.json.

El historial completo y los comandos de verificación están en revision_gestiones_2026-10-30.md; este documento resume el estado vigente y reemplaza los pendientes antiguos que ya se resolvieron.
