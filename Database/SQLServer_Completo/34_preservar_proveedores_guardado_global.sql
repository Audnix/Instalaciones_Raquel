/* Migracion de procedimiento: preserva proveedores y expedientes al guardar otros modulos.
No ejecuta el snapshot, no carga datos ni altera saldos. Con respaldo previo.
Falla ante una definicion no reconocida. Se puede volver a aplicar. */
USE [Instalaciones Raquel];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
DECLARE @Definition NVARCHAR(MAX)=OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_SaveErpState'));
SET @Definition=REPLACE(@Definition,CHAR(13),N'');
IF @Definition IS NULL THROW 50505,'No se puede inspeccionar usp_SaveErpState con esta cuenta.',1;
IF CHARINDEX(N'DELETE FROM dbo.Parties;',@Definition)>0
BEGIN
    DECLARE @EndBlock NVARCHAR(MAX)=N'NextReviewDate DATE ''$.nextReviewDate'''+CHAR(10)+N'        );';
    IF CHARINDEX(N'        UPDATE dbo.ErpState',@Definition)=0 THROW 50801,'No se reconoce el cierre del snapshot; no se modifica.',1;
    IF CHARINDEX(@EndBlock,@Definition)=0 THROW 50506,'Version de snapshot no reconocida; revisar el bloque Parties antes de migrar.',1;
    SET @Definition=REPLACE(@Definition,N'DELETE FROM dbo.Parties;',N'DELETE FROM dbo.Parties WHERE PartyType <> N''proveedor'';');
    SET @Definition=REPLACE(@Definition,@EndBlock,N'NextReviewDate DATE ''$.nextReviewDate'''+CHAR(10)+N'        ) WHERE PartyType <> N''proveedor'';');
    DECLARE @Merge NVARCHAR(MAX)=N'
        /* Proveedores confirmados no se sobrescriben desde un navegador antiguo. */
        DECLARE @DirectoryParties NVARCHAR(MAX);
        SELECT @DirectoryParties=N''[''+COALESCE(STRING_AGG(CONVERT(NVARCHAR(MAX),value),N'',''),N'''')+N'']''
        FROM (
            SELECT value FROM OPENJSON(@Payload,''$.parties'') WHERE JSON_VALUE(value,''$.type'')<>N''proveedor''
            UNION ALL
            SELECT (SELECT p.PartyId AS id,p.Name AS name,p.Contact AS contact,p.Phone AS phone,
                p.Email AS email,p.Address AS address,p.SupplierCategory AS category,p.ProductsServices AS productsServices,
                p.Ruc AS ruc,p.PaymentTerms AS paymentTerms,p.Observations AS observations,p.SupplierStatus AS status,
                p.CreatedAt AS createdAt,p.UpdatedAt AS updatedAt,p.NextReviewDate AS nextReviewDate,N''proveedor'' AS type
                FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
            FROM dbo.Parties p WHERE PartyType=N''proveedor''
        ) AS confirmed;
        SET @Payload=JSON_MODIFY(@Payload,''$.parties'',JSON_QUERY(@DirectoryParties));
        ';
    SET @Definition=REPLACE(@Definition,N'        UPDATE dbo.ErpState',@Merge+N'        UPDATE dbo.ErpState');
    DECLARE @procPos INT = CHARINDEX(N'PROCEDURE', @Definition);
    IF @procPos > 0 SET @Definition = N'CREATE OR ALTER ' + SUBSTRING(@Definition, @procPos, LEN(@Definition));
    EXEC sys.sp_executesql @Definition;
END;
IF CHARINDEX(N'DELETE FROM dbo.Parties WHERE PartyType <> N''proveedor'';',OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_SaveErpState')))=0 THROW 50802,'No se confirmo la proteccion de proveedores.',1;
DECLARE @FinalDefinition NVARCHAR(MAX)=OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_SaveErpState'));
DECLARE @FinalPosition INT=CHARINDEX(N'PROCEDURE',@FinalDefinition);
IF @FinalPosition=0 THROW 50803,'Cabecera de procedimiento no reconocida.',1;
SET @FinalDefinition=N'CREATE OR ALTER '+SUBSTRING(@FinalDefinition,@FinalPosition,LEN(@FinalDefinition));
EXEC sys.sp_executesql @FinalDefinition;
IF EXISTS(SELECT 1 FROM sys.sql_modules WHERE object_id=OBJECT_ID(N'dbo.usp_SaveErpState') AND (uses_quoted_identifier=0 OR uses_ansi_nulls=0)) THROW 50804,'Opciones SQL del procedimiento no confirmadas.',1;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
