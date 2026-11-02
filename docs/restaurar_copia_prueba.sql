/* Ejecutar completo desde SSMS con una cuenta administradora.
   Crea SOLO Instalaciones_Raquel_Prueba_20261030 y archivos con ese prefijo.
   Aborta si existe el destino. No usa REPLACE, no elimina bases y no cambia .env.
   Conserva la copia para inspección. Si falla, revisar el error antes de reintentar.
   Referencia: https://learn.microsoft.com/sql/t-sql/statements/restore-statements-filelistonly-transact-sql */
USE master;
GO
SET NOCOUNT ON;
DECLARE @Source sysname=N'Instalaciones Raquel';
DECLARE @Target sysname=N'Instalaciones_Raquel_Prueba_20261030';
IF @Source=@Target OR DB_ID(@Target) IS NOT NULL
 THROW 51000,'El destino ya existe o coincide con origen; se cancela sin reemplazarlo.',1;
DECLARE @MediaSetId int,@Position int,@Devices nvarchar(max),@Sql nvarchar(max);
SELECT TOP(1) @MediaSetId=media_set_id,@Position=position
FROM msdb.dbo.backupset WHERE database_name=@Source AND type='D'
ORDER BY backup_finish_date DESC;
IF @MediaSetId IS NULL THROW 51000,'No se encontro respaldo completo.',1;
IF EXISTS(SELECT 1 FROM msdb.dbo.backupmediafamily WHERE media_set_id=@MediaSetId AND mirror=0 AND device_type<>2)
 THROW 51000,'Solo se admiten respaldos en disco.',1;
SELECT @Devices=STRING_AGG(CAST(N'DISK=N'''+REPLACE(physical_device_name,N'''',N'''''')+N'''' AS nvarchar(max)),N', ')
FROM msdb.dbo.backupmediafamily WHERE media_set_id=@MediaSetId AND mirror=0;
IF @Devices IS NULL THROW 51000,'No se encontraron archivos del respaldo.',1;
DECLARE @DataPath nvarchar(4000)=CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @LogPath nvarchar(4000)=CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultLogPath'));
IF NULLIF(@DataPath,N'') IS NULL OR NULLIF(@LogPath,N'') IS NULL
 THROW 51000,'No se pudieron determinar los directorios de SQL Server.',1;
IF RIGHT(@DataPath,1) NOT IN(N'\',N'/') SET @DataPath+=N'\';
IF RIGHT(@LogPath,1) NOT IN(N'\',N'/') SET @LogPath+=N'\';
CREATE TABLE #Files (
 LogicalName nvarchar(128),PhysicalName nvarchar(260),Type char(1),FileGroupName nvarchar(128),
 Size numeric(20,0),MaxSize numeric(20,0),FileID bigint,CreateLSN numeric(25,0),DropLSN numeric(25,0),
 UniqueID uniqueidentifier,ReadOnlyLSN numeric(25,0),ReadWriteLSN numeric(25,0),BackupSizeInBytes bigint,
 SourceBlockSize int,FileGroupID int,LogGroupGUID uniqueidentifier,DifferentialBaseLSN numeric(25,0),
 DifferentialBaseGUID uniqueidentifier,IsReadOnly bit,IsPresent bit,TDEThumbprint varbinary(32),SnapshotURL nvarchar(360)
);
SET @Sql=N'RESTORE FILELISTONLY FROM '+@Devices+N' WITH FILE='+CONVERT(nvarchar(20),@Position);
INSERT #Files EXEC sys.sp_executesql @Sql;
IF NOT EXISTS(SELECT 1 FROM #Files) OR EXISTS(SELECT 1 FROM #Files WHERE Type NOT IN('D','L') OR ISNULL(IsPresent,0)<>1)
 THROW 51000,'El respaldo tiene archivos especiales o ausentes; requiere revision manual.',1;
DECLARE @Moves nvarchar(max)=N'',@Logical nvarchar(128),@Type char(1),@Id bigint,@Destination nvarchar(4000);
DECLARE @Exists TABLE(FileExists int,IsDirectory int,ParentExists int);
DECLARE files_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT LogicalName,Type,FileID FROM #Files ORDER BY FileID;
OPEN files_cursor;
FETCH NEXT FROM files_cursor INTO @Logical,@Type,@Id;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Destination=CASE WHEN @Type='L' THEN @LogPath ELSE @DataPath END+@Target+N'_'+CONVERT(nvarchar(20),@Id)+CASE WHEN @Type='L' THEN N'.ldf' ELSE N'.mdf' END;
 IF EXISTS(SELECT 1 FROM sys.master_files WHERE physical_name=@Destination)
  THROW 51000,'Un archivo de destino ya pertenece a una base; no se sobrescribe.',1;
 DELETE FROM @Exists;
 INSERT @Exists EXEC master.dbo.xp_fileexist @Destination;
 IF EXISTS(SELECT 1 FROM @Exists WHERE FileExists=1 OR IsDirectory=1 OR ParentExists=0)
  THROW 51000,'Un archivo de destino existe o su directorio no esta disponible.',1;
 SET @Moves+=N', MOVE N'''+REPLACE(@Logical,N'''',N'''''')+N''' TO N'''+REPLACE(@Destination,N'''',N'''''')+N'''';
 FETCH NEXT FROM files_cursor INTO @Logical,@Type,@Id;
END;
CLOSE files_cursor;
DEALLOCATE files_cursor;
-- Repetir la comprobación justo antes de restaurar. Nunca utilizar WITH REPLACE.
IF DB_ID(@Target) IS NOT NULL THROW 51000,'El destino ya existe; se cancela.',1;
SET @Sql=N'RESTORE DATABASE '+QUOTENAME(@Target)+N' FROM '+@Devices+
 N' WITH FILE='+CONVERT(nvarchar(20),@Position)+@Moves+N', RECOVERY, STATS=10;';
EXEC sys.sp_executesql @Sql;
SET @Sql=N'DBCC CHECKDB ('+QUOTENAME(@Target)+N') WITH NO_INFOMSGS;';
EXEC sys.sp_executesql @Sql;
SELECT name,state_desc FROM sys.databases WHERE name=@Target;
SET @Sql=N'USE '+QUOTENAME(@Target)+N'; SELECT (SELECT COUNT(*) FROM dbo.Sales) AS ventas,'+
 N'(SELECT COUNT(*) FROM dbo.InventoryLots) AS lotes,(SELECT COUNT(*) FROM dbo.PayrollRuns) AS planillas;';
EXEC sys.sp_executesql @Sql;
DROP TABLE #Files;
PRINT N'Copia restaurada y CHECKDB ejecutado. Revisar Mensajes: no deben existir errores. La base operativa no fue reemplazada.';
GO
