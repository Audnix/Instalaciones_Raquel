USE [Instalaciones Raquel];
GO
SET XACT_ABORT ON;
SET NOCOUNT ON;
SELECT (SELECT COUNT(*) FROM dbo.PayrollRuns) AS Runs,(SELECT COUNT(*) FROM dbo.PayrollRunItems) AS Items,(SELECT COUNT(*) FROM dbo.PayrollPayments) AS Payments,(SELECT COUNT(*) FROM dbo.CashMoves) AS CashMoves INTO #BeforeConfiguration;
BEGIN TRANSACTION;
GO
:r Database/SQLServer_Completo/31_reglas_periodo_y_devengo_nomina.sql
:r Database/SQLServer_Completo/32_conservar_enlaces_snapshot.sql
GO
IF NOT EXISTS(SELECT 1 FROM #BeforeConfiguration WHERE Runs=(SELECT COUNT(*) FROM dbo.PayrollRuns) AND Items=(SELECT COUNT(*) FROM dbo.PayrollRunItems) AND Payments=(SELECT COUNT(*) FROM dbo.PayrollPayments) AND CashMoves=(SELECT COUNT(*) FROM dbo.CashMoves)) THROW 50701,'Los conteos de negocio cambiaron durante la configuracion. Revisar antes de confirmar.',1;
IF OBJECT_ID(N'dbo.usp_PayrollAccrualIntegrityVersion',N'P') IS NULL OR OBJECT_ID(N'dbo.usp_SnapshotLinkIntegrityVersion',N'P') IS NULL THROW 50702,'Faltan marcadores de integridad.',1;
COMMIT TRANSACTION;
SELECT N'Configuracion confirmada, conteos de negocio conservados' AS Result;
SELECT * FROM #BeforeConfiguration;
GO
