/* Ejecutar en SSMS con una cuenta administradora autorizada.
   Solo consulta el historial y ejecuta RESTORE VERIFYONLY.
   No crea ni restaura una base; no cambia permisos de la cuenta del ERP.
   No equivale a probar una restauración en un entorno separado. */
USE master;
GO
DECLARE @DatabaseName sysname=N'Instalaciones Raquel';
DECLARE @MediaSetId int,@Position int,@Devices nvarchar(max),@Sql nvarchar(max);
SELECT TOP(1) @MediaSetId=media_set_id,@Position=position
FROM msdb.dbo.backupset WHERE database_name=@DatabaseName AND type='D'
ORDER BY backup_finish_date DESC;
IF @MediaSetId IS NULL THROW 51000,'No existe respaldo completo registrado para esta base.',1;
IF EXISTS(SELECT 1 FROM msdb.dbo.backupmediafamily WHERE media_set_id=@MediaSetId AND mirror=0 AND device_type<>2)
 THROW 51000,'Este diagnóstico solo admite respaldos en disco.',1;
SELECT @Devices=STRING_AGG(CAST(N'DISK = N'''+REPLACE(physical_device_name,N'''',N'''''')+N'''' AS nvarchar(max)),N', ')
FROM msdb.dbo.backupmediafamily WHERE media_set_id=@MediaSetId AND mirror=0;
IF @Devices IS NULL THROW 51000,'No se encontraron archivos del respaldo.',1;
SET @Sql=N'RESTORE VERIFYONLY FROM '+@Devices+N' WITH FILE='+CONVERT(nvarchar(20),@Position)+N';';
EXEC sys.sp_executesql @Sql;
GO
