/* Directorio de proveedores. Aplicar con cuenta de migraciones, sin semilla ni reconstruccion.
   Requiere 11 y 12. No modifica personal, nomina, compras ni otros terceros. */
USE [Instalaciones Raquel];
GO
IF OBJECT_ID(N'dbo.usp_UpsertSupplier', N'P') IS NULL
    THROW 50500, 'Aplica primero 11_actualizar_proveedores.sql y 12_sincronizacion_proveedores.sql.', 1;
GO
/* El snapshot antiguo elimina Parties. Preservar SOLO proveedores y su expediente.
   Fallar antes de crear tablas si la version instalada no tiene el bloque conocido. */
DECLARE @Definition NVARCHAR(MAX)=OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_SaveErpState'));
SET @Definition=REPLACE(@Definition,CHAR(13),N'');
IF @Definition IS NULL THROW 50505,'No se puede inspeccionar usp_SaveErpState con esta cuenta.',1;
IF CHARINDEX(N'DELETE FROM dbo.Parties;',@Definition)>0
BEGIN
    DECLARE @EndBlock NVARCHAR(MAX)=N'NextReviewDate DATE ''$.nextReviewDate'''+CHAR(10)+N'        );';
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
GO
IF OBJECT_ID(N'dbo.SupplierDirectory', N'U') IS NULL
CREATE TABLE dbo.SupplierDirectory (
    PartyId NVARCHAR(100) NOT NULL PRIMARY KEY REFERENCES dbo.Parties(PartyId),
    Data NVARCHAR(MAX) NOT NULL CHECK (ISJSON(Data) = 1),
    UpdatedAt DATETIMEOFFSET(3) NOT NULL,
    UpdatedBy NVARCHAR(200) NOT NULL,
    Version ROWVERSION NOT NULL
);
IF OBJECT_ID(N'dbo.SupplierDirectoryEvents', N'U') IS NULL
CREATE TABLE dbo.SupplierDirectoryEvents (
    MutationId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    PartyId NVARCHAR(100) NOT NULL REFERENCES dbo.Parties(PartyId),
    ActorId NVARCHAR(100) NOT NULL,
    ActorName NVARCHAR(200) NOT NULL,
    RequestHash VARCHAR(64) NOT NULL,
    OccurredAt DATETIMEOFFSET(3) NOT NULL,
    Reason NVARCHAR(500) NOT NULL,
    BeforeData NVARCHAR(MAX) NULL,
    AfterData NVARCHAR(MAX) NOT NULL,
    Response NVARCHAR(MAX) NOT NULL
);
IF OBJECT_ID(N'dbo.SupplierDirectoryFiles', N'U') IS NULL
CREATE TABLE dbo.SupplierDirectoryFiles (
    DocumentId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    PartyId NVARCHAR(100) NOT NULL REFERENCES dbo.Parties(PartyId),
    FileName NVARCHAR(200) NOT NULL,
    ContentType NVARCHAR(80) NOT NULL,
    Content VARBINARY(MAX) NOT NULL,
    CHECK (DATALENGTH(Content) BETWEEN 1 AND 3145728)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.SupplierDirectoryEvents') AND name = N'IX_SupplierDirectoryEvents_Party')
    CREATE INDEX IX_SupplierDirectoryEvents_Party ON dbo.SupplierDirectoryEvents(PartyId, OccurredAt DESC);
GO
INSERT dbo.SupplierDirectory(PartyId,Data,UpdatedAt,UpdatedBy)
SELECT PartyId,N'{}',TODATETIMEOFFSET(SYSUTCDATETIME(),'+00:00'),N'Migracion de directorio'
FROM dbo.Parties p WHERE PartyType=N'proveedor' AND NOT EXISTS(SELECT 1 FROM dbo.SupplierDirectory d WHERE d.PartyId=p.PartyId);
GO
CREATE OR ALTER VIEW dbo.vw_SupplierDirectory AS
SELECT p.PartyId AS id, p.Name AS name, p.Contact AS contact, p.Phone AS phone,
       COALESCE(p.Email,N'') AS email, COALESCE(p.Address,N'') AS address,
       COALESCE(p.SupplierCategory,N'otro') AS category, COALESCE(p.SupplierStatus,N'pendiente') AS status,
       COALESCE(p.ProductsServices,N'') AS productsServices, COALESCE(p.Ruc,N'') AS ruc,
       COALESCE(p.PaymentTerms,N'') AS paymentTerms, COALESCE(p.Observations,N'') AS observations,
       CONVERT(VARCHAR(10),p.NextReviewDate,23) AS nextReviewDate,
       p.CreatedAt AS createdAt, p.UpdatedAt AS updatedAt,
       d.Data AS profile, d.UpdatedBy AS updatedBy,
       CONVERT(VARCHAR(18), d.Version, 1) AS version
FROM dbo.Parties p LEFT JOIN dbo.SupplierDirectory d ON d.PartyId=p.PartyId
WHERE p.PartyType=N'proveedor';
GO
CREATE OR ALTER PROCEDURE dbo.usp_ReadSupplierDirectory
    @PartyId NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_SupplierDirectory WHERE @PartyId IS NULL OR id=@PartyId ORDER BY name,id;
    IF @PartyId IS NOT NULL
    BEGIN
        SELECT TOP (100) MutationId AS id, ActorName AS actor, OccurredAt AS at,
               Reason AS reason, BeforeData AS beforeData, AfterData AS afterData
        FROM dbo.SupplierDirectoryEvents WHERE PartyId=@PartyId ORDER BY OccurredAt DESC,MutationId;
        SELECT p.PurchaseId AS id,p.PurchaseNumber AS number,p.Status AS status,
               p.Total AS total,p.PurchaseDate AS date,p.SupplierPartyId AS supplierId
        FROM dbo.Purchases p WHERE p.SupplierPartyId=@PartyId ORDER BY p.PurchaseDate DESC;
        SELECT DocumentId AS id,FileName AS name,ContentType AS type
        FROM dbo.SupplierDirectoryFiles WHERE PartyId=@PartyId;
    END;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_SaveSupplierDirectory
    @PartyId NVARCHAR(100), @Data NVARCHAR(MAX), @ExpectedVersion VARCHAR(18),
    @MutationId UNIQUEIDENTIFIER, @ActorId NVARCHAR(100), @ActorName NVARCHAR(200),
    @Reason NVARCHAR(500), @RequestHash VARCHAR(64), @FileId UNIQUEIDENTIFIER = NULL, @FileContent VARBINARY(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF ISJSON(@Data)<>1 THROW 50501,'Datos del proveedor invalidos.',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @StoredResponse NVARCHAR(MAX), @StoredParty NVARCHAR(100), @StoredActor NVARCHAR(100), @StoredHash VARCHAR(64);
        SELECT @StoredResponse=Response,@StoredParty=PartyId,@StoredActor=ActorId,@StoredHash=RequestHash
        FROM dbo.SupplierDirectoryEvents WITH (UPDLOCK,HOLDLOCK) WHERE MutationId=@MutationId;
        IF @StoredResponse IS NOT NULL
        BEGIN
            IF @StoredParty<>@PartyId OR @StoredActor<>@ActorId OR @StoredHash<>@RequestHash
                THROW 50502,'Identificador de operacion ya utilizado.',1;
            COMMIT TRANSACTION;
            SELECT @StoredResponse AS response;
            RETURN;
        END;
        DECLARE @SnapshotLock NVARCHAR(MAX);
        SELECT @SnapshotLock=Payload FROM dbo.ErpState WITH(UPDLOCK,HOLDLOCK) WHERE StateId=1;
        DECLARE @Before NVARCHAR(MAX), @CurrentVersion VARCHAR(18), @Exists BIT=0;
        SELECT @Exists=1 FROM dbo.Parties WITH (UPDLOCK,HOLDLOCK) WHERE PartyId=@PartyId AND PartyType=N'proveedor';
        SELECT @CurrentVersion=CONVERT(VARCHAR(18),Version,1)
        FROM dbo.SupplierDirectory WITH (UPDLOCK,HOLDLOCK) WHERE PartyId=@PartyId;
        IF COALESCE(@CurrentVersion,'')<>COALESCE(@ExpectedVersion,'')
            THROW 50503,'Otro usuario modifico el proveedor. Recarga el expediente y compara los cambios.',1;
        IF @Exists=1 SELECT @Before=(SELECT * FROM dbo.vw_SupplierDirectory WHERE id=@PartyId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

        DECLARE @Name NVARCHAR(240)=JSON_VALUE(@Data,'$.name'), @Category NVARCHAR(30)=JSON_VALUE(@Data,'$.category'),
        @Contact NVARCHAR(200)=JSON_VALUE(@Data,'$.contact'), @Phone NVARCHAR(80)=JSON_VALUE(@Data,'$.phone'),
        @Email NVARCHAR(320)=JSON_VALUE(@Data,'$.email'), @Address NVARCHAR(500)=JSON_VALUE(@Data,'$.address'),
        @Products NVARCHAR(1000)=JSON_VALUE(@Data,'$.productsServices'), @Ruc NVARCHAR(40)=JSON_VALUE(@Data,'$.ruc'),
        @Terms NVARCHAR(80)=JSON_VALUE(@Data,'$.paymentTerms'), @Notes NVARCHAR(2000)=JSON_VALUE(@Data,'$.observations'),
        @Status NVARCHAR(20)=JSON_VALUE(@Data,'$.status'), @Review DATE=TRY_CONVERT(DATE,NULLIF(JSON_VALUE(@Data,'$.nextReviewDate'),'')),
        @AuditId NVARCHAR(100)=CONVERT(NVARCHAR(100),@MutationId), @Action NVARCHAR(120)=CASE WHEN @Exists=1 THEN N'actualizar proveedor' ELSE N'alta proveedor' END;
        DECLARE @Saved TABLE (
            id NVARCHAR(100),name NVARCHAR(240),contact NVARCHAR(200),phone NVARCHAR(80),email NVARCHAR(320),address NVARCHAR(500),category NVARCHAR(30),
            productsServices NVARCHAR(1000),ruc NVARCHAR(40),paymentTerms NVARCHAR(80),observations NVARCHAR(2000),status NVARCHAR(20),
            createdAt DATETIMEOFFSET(3),updatedAt DATETIMEOFFSET(3),nextReviewDate DATE,type NVARCHAR(30));
        INSERT INTO @Saved EXEC dbo.usp_UpsertSupplier @PartyId,@Name,@Category,@Contact,@Phone,@Email,@Address,@Products,@Ruc,@Terms,@Notes,@Status,@Review,@ActorName,@AuditId,@Action,@Reason;
        IF EXISTS(SELECT 1 FROM dbo.SupplierDirectory WHERE PartyId=@PartyId)
            UPDATE dbo.SupplierDirectory SET Data=@Data,UpdatedAt=TODATETIMEOFFSET(SYSUTCDATETIME(),'+00:00'),UpdatedBy=@ActorName WHERE PartyId=@PartyId;
        ELSE INSERT dbo.SupplierDirectory(PartyId,Data,UpdatedAt,UpdatedBy)
            VALUES(@PartyId,@Data,TODATETIMEOFFSET(SYSUTCDATETIME(),'+00:00'),@ActorName);

        IF @FileId IS NOT NULL
        BEGIN
            DECLARE @FileName NVARCHAR(200),@FileType NVARCHAR(80);
            SELECT @FileName=fileName,@FileType=fileType FROM OPENJSON(@Data,'$.documents')
            WITH(id UNIQUEIDENTIFIER '$.id',fileName NVARCHAR(200) '$.fileName',fileType NVARCHAR(80) '$.fileType') WHERE id=@FileId;
            IF @FileName IS NULL OR @FileContent IS NULL THROW 50504,'Faltan datos del documento.',1;
            INSERT dbo.SupplierDirectoryFiles(DocumentId,PartyId,FileName,ContentType,Content) VALUES(@FileId,@PartyId,@FileName,@FileType,@FileContent);
        END;
        DECLARE @Response NVARCHAR(MAX)=(SELECT * FROM dbo.vw_SupplierDirectory WHERE id=@PartyId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
        INSERT dbo.SupplierDirectoryEvents(MutationId,PartyId,ActorId,ActorName,RequestHash,OccurredAt,Reason,BeforeData,AfterData,Response)
        VALUES(@MutationId,@PartyId,@ActorId,@ActorName,@RequestHash,TODATETIMEOFFSET(SYSUTCDATETIME(),'+00:00'),@Reason,@Before,@Data,@Response);

        /* Mantener compatible el snapshot existente sin reemplazar otros modulos. */
        DECLARE @Payload NVARCHAR(MAX),@Index INT,@PartyJson NVARCHAR(MAX);
        SELECT @Payload=Payload FROM dbo.ErpState WITH (UPDLOCK,HOLDLOCK) WHERE StateId=1;
        IF ISJSON(@Payload)=1
        BEGIN
            SET @PartyJson=(SELECT id,name,contact,phone,email,address,category,productsServices,ruc,paymentTerms,observations,status,createdAt,updatedAt,nextReviewDate,N'proveedor' AS type FROM dbo.vw_SupplierDirectory WHERE id=@PartyId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
            SELECT @Index=TRY_CONVERT(INT,[key]) FROM OPENJSON(@Payload,'$.parties') WHERE JSON_VALUE(value,'$.id')=@PartyId;
            IF JSON_QUERY(@Payload,'$.parties') IS NULL SET @Payload=JSON_MODIFY(@Payload,'$.parties',JSON_QUERY('[]'));
            IF @Index IS NULL SET @Payload=JSON_MODIFY(@Payload,'append $.parties',JSON_QUERY(@PartyJson));
            ELSE SET @Payload=JSON_MODIFY(@Payload,'$.parties['+CONVERT(VARCHAR(12),@Index)+']',JSON_QUERY(@PartyJson));
            UPDATE dbo.ErpState SET Payload=@Payload,UpdatedAt=SYSUTCDATETIME() WHERE StateId=1;
        END;
        COMMIT TRANSACTION;
        SELECT @Response AS response;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_ReadSupplierDirectoryReceipt
    @MutationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PartyId,ActorId,RequestHash,Response FROM dbo.SupplierDirectoryEvents WHERE MutationId=@MutationId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_ReadSupplierDirectoryFile
    @PartyId NVARCHAR(100), @DocumentId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT FileName,ContentType,Content FROM dbo.SupplierDirectoryFiles WHERE PartyId=@PartyId AND DocumentId=@DocumentId;
END;
GO
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_ReadSupplierDirectory TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_SaveSupplierDirectory TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ReadSupplierDirectoryFile TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ReadSupplierDirectoryReceipt TO [raquel_erp_app];
END;
GO
