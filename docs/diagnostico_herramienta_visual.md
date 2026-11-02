# Diagnóstico del control visual

## Resultado

No recuperado. Error exacto al iniciar ambas herramientas:

```text
failed to write kernel assets: El sistema no puede encontrar la ruta especificada. (os error 3)
```

La causa concreta y la ruta ausente siguen sin identificar. El error ocurre antes de ejecutar la importación de `@oai/sky` o la consulta de superficies del navegador; no demuestra un fallo del ERP.

## Comprobaciones realizadas

- Reinicio de la sesión con `node_repl.js_reset` y reintento de la inicialización documentada: mismo error.
- Reinicio de la sesión con `cua_repl.js_reset` y consulta `cua.getState()`: mismo error.
- El ejecutable instalado `node_repl.exe` existe y responde a `--help`.
- Los directorios temporales examinados existen tanto en la ejecución restringida como en la ejecución local autorizada.
- Se localizaron registros de Codex que identifican el runtime configurado. No se encontró en los registros examinados una ruta concreta asociada al fallo de escritura de los recursos del kernel.
- No se deshabilitó el aislamiento, no se modificaron credenciales ni se sustituyeron binarios.

## Recuperación pendiente

1. Guardar cualquier trabajo abierto y cerrar Codex por completo desde su interfaz.
2. Volver a abrir Codex y este chat; pedir «prueba de nuevo la herramienta visual».
3. Reintentar la inicialización antes de continuar la revisión visual del ERP.
4. Si persiste, comprobar las actualizaciones de Codex y adjuntar el error exacto y este diagnóstico al reporte del problema. No enviar registros completos sin revisar si contienen información privada.

Un reinicio completo de la aplicación aún no se ha realizado. No se afirma que vaya a resolver el fallo.

Referencia consultada: https://developers.openai.com/plugins/deploy/troubleshooting
