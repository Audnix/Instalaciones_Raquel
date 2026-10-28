/* 33: completar auditoria de novedades en instalaciones que no aplicaron 25_operaciones_hr_nomina.
   Solo estructura y permisos ya previstos en 25. No carga ni modifica datos operativos. */
USE [Instalaciones Raquel];
GO
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
GO
BEGIN TRY
 BEGIN TRANSACTION;
 IF OBJECT_ID(N'dbo.PayrollNoveltyEvents',N'U') IS NULL
 CREATE TABLE dbo.PayrollNoveltyEvents(
  EventId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PayrollNoveltyEvents PRIMARY KEY,
  NoveltyId NVARCHAR(100) NOT NULL,ActorId NVARCHAR(100) NOT NULL,ActorName NVARCHAR(240) NOT NULL,
  EventType NVARCHAR(40) NOT NULL,Detail NVARCHAR(1000) NULL,
  OccurredAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollNoveltyEvents_At DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(),N'+00:00'))
 );
 IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
  GRANT SELECT,INSERT ON dbo.PayrollNoveltyEvents TO [raquel_erp_app];
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
