# Datos y pasos para manipular el sistema durante la grabación

Usar junto con GUION_PARA_LEER_VIDEO_1.md. Cada toma se graba por separado. Primero lee la frase, luego realiza una acción y deja visible su resultado entre tres y cinco segundos. No necesitas hablar mientras escribes todos los campos.

Los nombres de campos de productos, compras, clientes, proveedores y registro de trabajadores se contrastaron con el código del proyecto. La ubicación visible puede variar con los permisos. No se ha ejecutado este recorrido en tu navegador.

## Preparación del caso

Todos los datos siguientes son ficticios y pertenecen al ejercicio GRAB-01. Guarda estas operaciones en la copia de práctica, después de comprobar que la aplicación realmente apunta a ella. La existencia de una base de prueba no significa que el navegador la esté utilizando. Si solo tienes la base operativa disponible, muestra los formularios sin confirmar los registros ficticios.

Si repites una toma, busca primero GRAB-01: reutiliza lo guardado. No vuelvas a comprar, facturar o cobrar la misma operación.

## Toma 1. Presentación: todavía sin manipular formularios

**Mostrar:** portada de la presentación.

**Leer:**

Buenos días. Presentamos nuestro proyecto de Ingeniería de Software I, titulado Sistema de Gestión Administrativa para Instalaciones Raquel. Nuestro equipo está integrado por Jhonny Josue Garcias Blas, Raquel Audry Calero Rayo y Jose Yariel Angulo Gago. En este video explicaremos el problema, los requerimientos y los tipos de usuarios. Después mostraremos las operaciones del sistema paso a paso.

**Hacer:** dejar la portada tres segundos; pasar a la lámina del problema y seguir los bloques 2 a 5 del guion principal. En esa parte se explica; aún no necesitas crear registros.

## Toma 2. Registrar el producto

**Leer antes de escribir:** Primero registraremos el producto del ejercicio. Su ficha contiene los datos comerciales; las existencias ingresarán después mediante una compra.

1. Abrir **Base de datos → Productos**.
2. Buscar **GRAB-01-MARCO**. Si existe, abrir o mostrar ese producto y no duplicarlo.
3. Si no existe, completar:

| Campo | Escribir |
|---|---|
| Código | GRAB-01-MARCO |
| Nombre | GRAB-01 Marco de aluminio de practica |
| Categoría | Aluminio |
| Precio | 700 |
| Mínimo | 2 |

4. Pulsar **Alta de producto** una sola vez.
5. Esperar la confirmación de guardado.
6. Buscar el código y mostrar la ficha.

**Resultado que debes revisar:** producto guardado; stock inicial cero si es nuevo y no tiene movimientos. El mínimo de 2 es un umbral de alerta, no una entrada de dos unidades.

**Leer al terminar:** El producto quedó registrado. Ahora prepararemos al proveedor y al cliente que utilizaremos en la misma operación.

## Toma 3. Registrar el proveedor

1. Abrir **Proveedores** y buscar **GRAB-01 Proveedor de aluminio**.
2. Si no existe, pulsar **Nuevo proveedor**.
3. Recorrer las secciones del formulario y completar:

| Campo | Valor del ejercicio |
|---|---|
| Nombre comercial | GRAB-01 Proveedor de aluminio |
| Razón social | Dejar vacía si no difiere |
| Identificación fiscal | Dejar vacía; no inventar un RUC válido |
| Categoría de suministro | Materiales |
| Especialidad técnica | Perfiles de aluminio |
| Productos y servicios ofrecidos | Marcos y perfiles de aluminio de practica |
| Persona de contacto principal | Contacto de practica GRAB-01 |
| Cargo del contacto | Ventas |
| Correo electrónico | proveedor.grab01@example.com |
| Dirección comercial | Managua, direccion ficticia para grabacion |
| Condiciones de pago | Credito de practica a 15 dias |
| Moneda comercial | Córdobas / NIO |
| Plazo habitual de entrega | 3 días |
| Observaciones comerciales | Registro ficticio GRAB-01 para video academico |
| Estado operativo | Activo |
| Resolución de revisión interna | Pendiente |
| Motivo documentado del registro | Alta ficticia GRAB-01 para demostracion academica |

4. Dejar teléfono, cuentas bancarias, documentos y fechas opcionales vacíos. No se necesitan para este caso. Si el formulario pide un dato adicional obligatorio, revisar su etiqueta antes de continuar.
5. Guardar con la acción del formulario, esperar y buscar el proveedor.
6. Mostrar brevemente su expediente.

**Leer:** Aquí identificamos al proveedor del material. Registramos su categoría, especialidad y condiciones comerciales. El expediente permite consultar la información disponible y el historial del registro.

## Toma 4. Registrar el cliente

1. Abrir **Clientes**. Buscar el nombre del ejercicio antes de registrar.
2. Completar el formulario si todavía no existe:

| Campo | Escribir o seleccionar |
|---|---|
| Cliente / Razón Social | GRAB-01 Cliente de practica |
| Persona de Contacto | Contacto cliente GRAB-01 |
| Teléfono / Correo | cliente.grab01@example.com |
| Categoría | Cliente Residencial |

3. Guardar, esperar y localizar el registro.

**Leer:** Este cliente será el mismo que utilizaremos en la proforma y la factura. Mantener un registro común facilita seguir la operación.

## Toma 5. Recibir la compra

1. Abrir **Compras**.
2. Completar:

| Campo | Valor |
|---|---|
| Proveedor | GRAB-01 Proveedor de aluminio |
| Producto | GRAB-01 Marco de aluminio de practica |
| Cantidad | 10 |
| Costo | 400 |

3. Detener el cursor: mostrar los cuatro campos antes de enviar.
4. Leer: Recibiremos diez unidades a cuatrocientos córdobas cada una. El total de esta compra es de cuatro mil córdobas.
5. Pulsar **Recibir compra** una sola vez y esperar la confirmación.
6. Anotar el número generado en la hoja de referencias del final.
7. Abrir **Inventario**, buscar el producto y mostrar lote y kardex.

**Resultado esperado:** 10 unidades si no había movimientos previos; costo total del lote C$4,000. No introducir otra entrada manual de diez unidades.

**Leer:** La recepción incorporó materiales al inventario. Aquí comprobamos el movimiento de entrada y su referencia. Recibir esta compra no significa que ya se haya pagado al proveedor.

## Toma 6. Crear la proforma y facturar

1. Abrir **Ventas** y seleccionar **Proforma**.
2. Elegir el cliente y producto de GRAB-01.
3. Escribir **Cantidad: 2**.
4. Si se muestran estos campos, utilizar **Vigencia: 15 días** y **Notas: Proforma ficticia GRAB-01 para grabacion**.
5. Revisar precio unitario **700**, descuento, impuesto y total. No alterar promociones globales para forzar un resultado.
6. Guardar con la acción disponible y anotar el número.
7. Consultar Inventario: la proforma debe conservar las 10 unidades.
8. Volver a la proforma y utilizar la acción de convertir a factura una sola vez.
9. Mostrar factura y anotar su número y total exactos.
10. Volver a Inventario: deben quedar 8 unidades en este caso aislado.

**Referencia matemática:** subtotal C$1,400. Con descuento cero y un IVA del 15 %, el total sería C$1,610. Usa siempre el total que realmente calcule la aplicación.

**Leer:** Primero elaboramos la proforma, que presenta la propuesta comercial. Después confirmamos la venta mediante su conversión a factura. Ahora verificamos la salida de dos unidades. El cobro se realizará en un paso separado.

## Toma 7. Proyecto y orden de taller

**Proyecto de práctica, si se demuestra su alta:**

| Campo | Valor |
|---|---|
| Código | GRAB-01-PROY |
| Nombre | GRAB-01 Instalacion de marcos |
| Cliente | GRAB-01 Cliente de practica |
| Monto | Copiar el total real de la factura del caso |
| Avance % | 0 |
| Estado | Medicion de practica |

**Orden de taller:**

1. Desde la factura, abrir **Preparar orden de taller**, si está disponible, y seleccionar la línea del producto.
2. Revisar datos propuestos. Si ya existe la orden, abrirla.
3. Para una captura manual, usar:

| Campo | Valor |
|---|---|
| N° Orden (OT) | GRAB-01-OT |
| Trabajo / Estructura | Preparacion e instalacion de dos marcos de practica |
| Cliente / Proyecto | GRAB-01 Cliente de practica / GRAB-01-PROY |
| Cantidad | 2 |
| Unidad | Pieza, o la opción equivalente disponible |

4. Guardar y esperar. Si se solicitan medidas adicionales, usar únicamente las definidas por el ejercicio técnico; no inventarlas para completar una orden real.
5. Mostrar las etapas y, en la copia de práctica, avanzar despacio por corte, ensamble, instalación y entrega.

**Leer:** La orden permite seguir el trabajo del taller. Mostraremos las etapas como una simulación del ejercicio. En una operación real, cada cambio debe corresponder al trabajo efectivamente realizado.

## Toma 8. Cobrar la factura

1. Comprobar que la sesión de Caja del día esté abierta. Si existe una sesión anterior pendiente, resolverla con su respaldo antes de continuar.
2. Para una sesión nueva del ejercicio, utilizar **saldo inicial: 1000** en efectivo. No abrir otra si ya hay una sesión válida.
3. Abrir la factura GRAB-01 y actualizar su saldo pendiente.
4. Seleccionar **Cobrar en efectivo** o la acción equivalente disponible.
5. Revisar estos datos:

| Dato | Valor |
|---|---|
| Cuenta / medio | Caja / Efectivo |
| Importe | Total pendiente real de esta factura |
| Referencia documental | Número exacto de la factura generada |
| Concepto, si se solicita | Cobro de factura GRAB-01 de practica |
| Fecha | Día operativo de la sesión |

6. Confirmar una sola vez. Esperar y actualizar la consulta.
7. Mostrar el movimiento y el pendiente actualizado de la factura.

**Resultado esperado si el cobro es completo:** pendiente cero. Si Caja empezó en C$1,000 y no existen otros movimientos, saldo C$1,000 más el cobro. Con factura de C$1,610 sería C$2,610.

**Leer:** Confirmamos el ingreso con la referencia exacta de la factura. Después revisamos el movimiento de Caja y el nuevo saldo pendiente del cliente. No registraremos este mismo cobro nuevamente en Bancos.

## Toma 9. Personal y nómina

**Datos ficticios para registrar en la copia de práctica:**

| Campo | Trabajador 1 | Trabajador 2 |
|---|---|---|
| Nombre completo | GRAB-01 Trabajador A | GRAB-01 Trabajador B |
| Cargo / puesto | Auxiliar de taller de practica | Instalador de practica |
| Área | Produccion | Instalacion |
| Salario mensual (C$) | 12000 | 15000 |
| Fecha real de ingreso | Primer día del mes anterior a la grabación | Primer día del mes anterior a la grabación |

La fecha anterior es un dato simulado del ejercicio, exclusivamente para trabajadores ficticios. Selecciónala en el calendario. No cambies fechas de personal real.

1. Abrir **Talento humano → Personal** y buscar GRAB-01 antes de crear.
2. Completar los campos de la tabla y pulsar **Registrar trabajador**, una persona a la vez.
3. Abrir cada expediente y revisar que conserve salario y fecha.
4. En **Nómina → Nueva Planilla**, usar el nombre **GRAB-01 Quincena de practica**.
5. Elegir frecuencia quincenal, fecha inicial día 1 del mes de la grabación, fecha final día 15 y fecha prevista de pago día 15. Utilizar un período de práctica no duplicado. Si el sistema impide ese período, revisar la validación antes de cambiarlo.
6. Incluir solo los dos trabajadores ficticios. Revisar que los días y horas correspondan al período mostrado.
7. No añadir horas extra, bonos ni deducciones adicionales para este primer ejercicio; conservar las reglas aplicables del sistema.
8. Calcular y revisar el detalle de cada persona. Copiar neto y pendiente reales; no asumir que el neto es la mitad exacta del salario mensual.
9. Revisar validaciones y realizar revisión y aprobación con los permisos correspondientes.
10. Abrir **Pagos por trabajador** y seleccionar **GRAB-01 Trabajador A**.
11. Si el pendiente es al menos C$500 y Caja tiene fondos, preparar un **abono de C$500**, medio **Efectivo**, concepto o referencia libre **GRAB-01-ABONO-A-01**. Conservar cualquier referencia documental automática que requiera la aplicación.
12. Confirmar una sola vez. Mostrar comprobante y pendiente actualizado. Si los requisitos no se cumplen, mostrar el bloqueo y no forzar el pago.

**Resultado esperado:** el pendiente del trabajador A disminuye C$500; el del trabajador B conserva su importe anterior. Caja disminuye C$500 si el abono se confirmó en efectivo.

**Leer:** La nómina utiliza los datos de cada trabajador y las reglas del período. Después de calcular, revisar y aprobar, registramos un abono individual. Verificamos que disminuya el pendiente de la persona seleccionada y que quede el comprobante correspondiente.

## Toma 10. Pantallas de consulta: aquí no necesitas inventar registros

| Área | Acción lenta | Qué explicar |
|---|---|---|
| Usuarios y roles | Abrir una cuenta y mostrar permisos | Qué puede consultar, registrar y aprobar |
| Requerimientos | Abrir un requisito documentado | Necesidad, módulo y evidencia |
| Contabilidad | Buscar las referencias del caso y mostrar los registros disponibles | Fecha, concepto y documento de origen |
| Estados financieros | Abrir solo los que estén disponibles y revisar período | Alcance real; dejar explícito lo que falte |
| Contratos y permisos | Mostrar secciones y formularios sin aprobar solicitudes reales | Información y seguimiento del expediente |
| Mercadotecnia | Mostrar catálogo o promoción existente | Presentación comercial y condiciones |
| Estadística / reportes | Elegir un período y un indicador | Fuente de datos y significado del resultado |
| Control de operaciones | Actualizar consulta y mostrar historial o pendientes | Trazabilidad y revisiones necesarias |

Para estas tomas utiliza los textos de los bloques correspondientes del guion principal. Si no hay datos en un listado, muestra el estado vacío y explica su propósito sin afirmar que se realizó una operación.

## Hoja de referencias: completar durante el ensayo

| Referencia | Anotar aquí |
|---|---|
| Fecha de grabación | __________________ |
| Base de práctica realmente conectada | __________________ |
| Número de compra | __________________ |
| Número de proforma | __________________ |
| Número de factura | __________________ |
| Total real de factura | __________________ |
| Número de orden de taller | __________________ |
| Identificador de movimiento de cobro | __________________ |
| Nombre / identificador de planilla | __________________ |
| Neto del trabajador A | __________________ |
| Pendiente antes del abono A | __________________ |
| Pendiente después del abono A | __________________ |
| Referencia del comprobante de abono | __________________ |

## Cómo grabar sin apresurarte

1. Ensayar la toma antes de activar la grabación y comprobar sus campos.
2. Iniciar la grabación y dejar dos segundos de silencio.
3. Leer la frase del bloque.
4. Mover el cursor hasta el primer campo, hacer clic y escribir.
5. Esperar dos segundos antes de pasar al siguiente campo.
6. Antes de guardar, dejar visibles los datos tres segundos.
7. Guardar una sola vez y esperar la respuesta completa.
8. Mostrar el resultado cinco segundos y leer la frase de cierre.
9. Detener la toma. Si repites, consultar el registro creado; no repetir el movimiento.

Empieza por la presentación. Las primeras manipulaciones con datos son producto, proveedor y cliente; después continúa con compra, inventario, proforma, factura, taller, cobro y nómina.
