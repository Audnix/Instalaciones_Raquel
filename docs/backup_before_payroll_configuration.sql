SET NOCOUNT ON;
DECLARE @folder NVARCHAR(4000)=CONVERT(NVARCHAR(4000),SERVERPROPERTY('InstanceDefaultBackupPath'));
IF @folder IS NULL THROW 50700,'No se pudo resolver el directorio de respaldo del servidor.',1;
IF RIGHT(@folder,1) NOT IN ('\','/') SET @folder=@folder+N'\';
DECLARE @backup NVARCHAR(4000)=@folder+N'Raquel_before_payroll_'+REPLACE(CONVERT(NVARCHAR(36),NEWID()),N'-',N'')+N'.bak';
BACKUP DATABASE [Instalaciones Raquel] TO DISK=@backup WITH COPY_ONLY,NOFORMAT,NOINIT,CHECKSUM;
RESTORE VERIFYONLY FROM DISK=@backup WITH CHECKSUM;
SELECT @backup AS VerifiedBackup;
GO
