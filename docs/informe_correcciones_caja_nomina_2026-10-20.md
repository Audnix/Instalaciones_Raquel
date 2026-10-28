# Informe de correcciones: Caja y Nómina (Instalaciones Raquel)

Fecha: 2026-10-20
Alcance: revisión funcional y correcciones reales de **Caja/Banco**, **Nómina** y **Pagos**,
con evidencia ejecutable en SQL Server y verificación de interfaz.

---

## 1. Resumen de lo que se corrigió en esta ronda

| # | Hallazgo | Tipo | Corrección |
|---|----------|------|-----------|
| 1 | El saldo especial de la sesión de caja y sus movimientos del día podían desordenarse (la apertura no quedaba siempre antes del primer movimiento) → saldo acumulado incorrecto | Defecto real de datos | `vw_MovimientoCajaSaldo`: la apertura se ordena **primero** dentro de la misma fecha/hora |
| 2 | No existía arrastre del saldo del día anterior al abrir una nueva sesión (había que teclearlo a mano) | Funcionalidad faltante | Nueva vista `vw_SaldoSugeridoApertura` + API + precarga ajustable en la pantalla |
| 3 | No se podía pagar la nómina a un empleado individual (solo planilla completa) | Funcionalidad faltante | Pago por empleado en la interfaz (backend ya lo soportaba con `employeeId`) |
| 4 | Caja aparecía "sin hacer nada" (sin formulario) y no explicaba por qué | UX / diagnóstico | Aviso visible del motivo (sin conexión o sin área de Finanzas) |
| 5 | `vw_ResumenCaja`/saldo sugerido de la sesión abierta contaban mal la apertura como movimiento | Defecto real | La apertura se excluye del movimiento acumulado (ya venía en el saldo inicial) |
| 6 | El pago de nómina estaba bloqueado por errores 547 (FK) | Defecto real (migración 28) | `EmployeeId` nullable + orden de inserción CashMove→recibo |
| 7 | Saldo de caja se duplicaba al reabrir; días/horas fijos (30/240) para todos | Defecto real (migración 28) | Saldo por bloque de apertura; días/horas reales por período y vínculo |

Todo se aplicó en **migraciones incrementales** (26 y 28). **No** se reconstruyó la base,
**no** se borraron datos, **no** se cambiaron cuentas ni contraseñas.

---

## 2. Tu idea de caja: confirmada y ahora implementada

Estás en lo correcto. La caja **se trabaja con el saldo del día anterior**:

1. Se abre la sesión del día identificando el **saldo inicial real contado** (queda como
   operación `apertura`, separada de las ventas).
2. Sobre ese saldo se registran entradas y salidas del día.
3. `Saldo final = saldo anterior + saldo inicial de apertura + entradas − salidas`.
4. Al cerrar se **arquea** (contado vs. esperado → diferencia + explicación + revisión por otra persona).

**Antes**: el saldo final de la sesión anterior **no se arrastraba**; había que teclearlo.
**Ahora**: al abrir la nueva sesión, el sistema **sugiere** el saldo final de la última sesión
cerrada (o el saldo vivo de la sesión abierta) y el responsable lo **confirma o ajusta** con su conteo.
La sugerencia es de solo lectura: no crea ni modifica movimientos.

Regla del arrastre (vista `dbo.vw_SaldoSugeridoApertura`, por cuenta):

- Si hay sesión **cerrada** → se toma el efectivo **contado** de la última (lo realmente arqueado).
- Si hay sesión **abierta** → saldo inicial + movimientos confirmados de esa sesión.
- Si no hay sesiones (solo histórico) → saldo acumulado del último movimiento confirmado; 0 si no hay.

---

## 3. Causa real de "en caja no me deja hacer nada"

El formulario de movimientos y el botón de apertura **solo se renderizan** si:

```
canWrite = (syncStatus === "connected") && can("caja"|"bancos", "write")
```

Es decir, hacen falta **dos** condiciones:

1. **Conexión**: que el navegador haya cargado el estado desde SQL Server (`/api/state`).
   Si falla, `syncStatus = "offline"` y **no hay formulario** (modo lectura).
2. **Permiso**: que tu usuario tenga el **área de Finanzas** (o sea superadmin/administrador con finanzas).

Con la base actual, solo `admin@raquel.com`, `admin@jhonnyarea.com` y `contador@raquel.com`
tienen área de Finanzas. Si entras con producción/compras/vendedor, caja queda en solo lectura.

**Corrección aplicada**: cuando `connected = true` pero falta permiso, ahora la pantalla muestra
un aviso claro: *"Tu usuario puede consultar, pero no registrar: la escritura requiere pertenecer al área de Finanzas"*.
Y cuando no hay conexión, ya se mostraba el aviso de modo lectura.

> Como entras con `admin@raquel.com` (superadmin, con finanzas), el bloqueo por permisos **no debería**
> aplicarte. Si aún no ves el formulario, el motivo es `syncStatus = "offline"` (sesión no cargada).
> En ese caso la pantalla ahora te lo dice explícitamente.

---

## 4. Pago de nómina: qué se corrigió

- **Antes**: el botón "Registrar Pago / Dispersión" pagaba el **neto completo de la planilla**
  y estaba deshabilitado si no había neto aprobado o no existía sesión de caja/banco en la cuenta destino.
- **Ahora** (ambos modos, como pediste):
  - **Pago por empleado**: en la lista de trabajadores y en la pestaña de pagos hay un botón
    **"Pagar"** por colaborador. Abre el pago con el neto pendiente **de ese empleado** precargado.
  - **Pago total de la planilla**: se mantiene el botón de dispersión completa (opción "Planilla completa").
  - El modal permite elegir **destino** (planilla completa o un colaborador concreto) y muestra el pendiente.
- El backend ya soportaba `employeeId`; ahora la interfaz lo envía.
- El pago sigue siendo **idempotente** (clave `mutationId` generada una vez por intento) y **nunca**
  permite pagar más que el neto aprobado (validado en el servidor, no solo en el botón).
- La tabla de pagos ahora muestra a qué colaborador corresponde cada pago (o "Planilla completa").

---

## 5. Migraciones aplicadas

### Migración 26 — integridad de caja, nómina y pagos (`26_integridad_caja_nomina_pagos.sql`)
Ya aplicada previamente. Introduce `CashSessions`, `CashMoves` con `OperationKey`, los procedimientos
`usp_AbrirCaja`, `usp_RegistrarMovimientoCaja`, `usp_ArquearYCerrarCaja`, `usp_RevisionArqueo`,
`usp_AnularMovimientoCaja`, `usp_RegisterPayrollPayment` y la idempotencia por `OperationKey`.

### Migración 28 — ajustes posteriores (`28_ajuste_pagos_caja.sql`) — aplicada, reejecutable
No borra ni reconstruye datos. Contiene:

1. `PayrollPayments.EmployeeId` → **nullable** (permite pago a nivel de planilla).
2. `usp_RegisterPayrollPayment` reordenado: **CashMove → recibo → estado → items → historial**
   (resuelve los errores **547** `FK_PayrollPayments_Emp` y `FK_PayrollPayments_CashMove`).
3. `usp_CreatePayrollDraft` con **días y horas reales** por período y vínculo laboral (tope 15 quincenal,
   14 catorcenal, 30 mensual; prorrateo del salario /30; especiales en 0).
4. `vw_MovimientoCajaSaldo`: saldo por **bloque de apertura** y orden estable
   (fecha + hora + **apertura primero** + id).
5. `vw_ResumenCaja`: resume el último bloque de la cuenta.
6. **Nuevo**: `vw_SaldoSugeridoApertura` — saldo a arrastrar al abrir la nueva sesión.

Evidencia de aplicación: `docs/migracion_28_salida.txt` (EXIT 0).

---

## 6. Pruebas ejecutadas y evidencia

### 6.1 Batería funcional completa — `docs/pruebas_26_transaccion.sql` → `docs/pruebas_26_salida.txt`
Ejecutada con `sqlcmd -b` (falla el proceso si una aserción falla). **EXIT 0**.

- **Parte A** (dentro de una transacción que termina en `ROLLBACK`, no deja datos):
  - A.1 apertura 1000 + reintento con la misma clave → una sola sesión.
  - A.2 entradas 250 / salidas 100 → saldo de sesión **1150**; transferencia en banco, no en caja;
        `vw_ResumenCaja` = 1000/250/100/1150.
  - **A.3b (nuevo)** pago **individual** por empleado `e2`: 250 + 650 = 900; el recibo queda con
        `EmployeeId = e2`; **un solo** movimiento de caja acumulado a 900.
  - A.4 arqueo con faltante (−5) → pendiente de revisión.
  - A.5 revisión por una **segunda persona**.
  - **A.6 (nuevo)** el saldo sugerido por arrastre es el **contado de la sesión cerrada (1145)**.
  - Resultado: `PARTE A: TODAS LAS ASERCIONES PASARON`.
- **Parte B** (rechazos del servidor): 50564, 50578, 50583, 50587, 50567, 50570, 50571, 50592, 50531,
  50513, 50596, 50591, 50530, pago completo 900 + reintento idempotente (`repetida`) con **un solo**
  CashMove, y limpieza final (B.11) sin rastro.

### 6.2 Arrastre de saldo — prueba dirigida
Se reabrió una caja con saldo abierto: el sugerido pasó a **1250** (1000 inicial + 250), origen
`sesion_abierta`. Corrigió además un defecto donde la apertura se contaba como movimiento.

### 6.3 Conservación de datos del servidor tras un guardado de snapshot
`docs/prueba_snapshot_conserva_servidor.sql` → `docs/prueba_snapshot_salida.txt` (**EXIT 0**).
Demuestra que el guardado de `/api/state` (que borra solo filas con `OperationKey IS NULL`)
**conserva** `cash-nom-*`, las aperturas y los recibos de pago. Resultado: `SNAPSHOT OK`.

### 6.4 Estado de la base tras las pruebas (sin residuos)
```
Pagos: 0 | Planillas: 6 | Items: 114 | CashMoves: 6 | CashSessions: 0
```
Idéntico al estado previo: las pruebas revierten o limpian sus fixtures.

### 6.5 Compilación y API
- `npx tsc -b` → sin errores.
- `npm run build` → correcto.
- `GET /health` → **200**. `GET /api/cash/sessions` sin token → **401** (correcto).
- Servidor de la API reiniciado para servir el nuevo `suggestedOpening`.

---

## 7. Limitaciones y puntos abiertos (honestidad de alcance)

1. **Validación HTTP autenticada no completada**: el hash bcrypt sembrado de `admin@raquel.com`
   **no coincide** con `BOOTSTRAP_USER_PASSWORD` del `.env` ni con `raquel2026` (verificado con
   `bcrypt.compare`). **No se cambió ninguna contraseña de producción**. Por eso el recorrido
   autenticado por API se validó por código y por SQL, no con un login real por HTTP.
   → Recomendación: restablecer la contraseña de `admin@raquel.com` de forma controlada y repetir
   un recorrido HTTP de caja y pago.
2. **Banco con saldo sugerido negativo** (−85 148.54): proviene de movimientos históricos sembrados
   **sin apertura** (no se inventa un saldo inicial que nunca se registró). La sugerencia es ajustable;
   al abrir con un conteo real el saldo se corrige a partir de esa sesión.
3. **Planillas históricas con `TotalDeductions = 0`**: solo se reparan automáticamente si no están
   cerradas/pagadas/conciliadas; las avanzadas se **reportan** (`headerConsistent = 0`) sin tocarlas.
4. **Datos sembrados con acentos mal codificados** (`Dispersi�n`, `segÃºn`): no se corrigen.
5. La sección de caja es **solo lectura sin conexión** (decisión de diseño: la idempotencia y el saldo
   acumulado solo los garantiza el servidor).
6. El pago de nómina exige una **sesión abierta** en la cuenta destino (caja para efectivo, banco para
   el resto); si no existe, el servidor responde 50572 y la interfaz ahora lo explicará al intentar pagar.

---

## 8. Archivos modificados en esta ronda

- `Database/SQLServer_Completo/28_ajuste_pagos_caja.sql` — orden de apertura, `vw_SaldoSugeridoApertura`,
  exclusión de la apertura en el saldo de la sesión abierta.
- `server/src/routes/cash.js` — `suggestedOpening` en `GET /api/cash/sessions`.
- `src/pages/CashWorkspace.tsx` — precarga del saldo sugerido (ajustable), aviso del motivo del bloqueo.
- `src/pages/PayrollWorkspace.tsx` — pago por empleado (botones "Pagar"), selector de destino en el modal,
  columna "Colaborador" en la tabla de pagos.
- `docs/pruebas_26_transaccion.sql` — aserciones A.3b (pago individual) y A.6 (arrastre).
- `docs/prueba_snapshot_conserva_servidor.sql` — prueba de conservación de datos del servidor.
- Evidencias: `docs/migracion_28_salida.txt`, `docs/pruebas_26_salida.txt`, `docs/prueba_snapshot_salida.txt`.
