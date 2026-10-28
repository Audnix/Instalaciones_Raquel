/* ==============================================================================
   INSTALACIONES RAQUEL - VERIFICACIÓN INTEGRAL DEL MÓDULO DE PROVEEDORES
   Ejecutar en SQL Server Management Studio (SSMS) sobre [Instalaciones Raquel]
   ============================================================================== */

USE [Instalaciones Raquel];
GO

PRINT '==============================================================================';
PRINT '1. CONSULTA: MAESTRO GENERAL DE PROVEEDORES (dbo.Parties)';
PRINT '==============================================================================';
SELECT 
    p.PartyId AS [Código],
    p.Name AS [Nombre Comercial],
    p.LegalName AS [Razón Social],
    p.Ruc AS [RUC DGI],
    p.SupplierCategory AS [Categoría],
    p.SupplierStatus AS [Estado Operativo],
    p.PaymentTerms AS [Condiciones de Pago],
    p.NextReviewDate AS [Próxima Revisión]
FROM dbo.Parties p
WHERE p.PartyType = N'proveedor'
ORDER BY p.PartyId;
GO

PRINT '==============================================================================';
PRINT '2. CONSULTA: EXPEDIENTES TÉCNICOS Y HOMOLOGACIÓN (dbo.SupplierDirectory)';
PRINT '==============================================================================';
SELECT 
    d.PartyId AS [Código],
    JSON_VALUE(d.Data, '$.specialty') AS [Especialidad Técnica],
    JSON_VALUE(d.Data, '$.currency') AS [Moneda],
    JSON_VALUE(d.Data, '$.leadDays') AS [Plazo Entrega (Días)],
    JSON_VALUE(d.Data, '$.reviewStatus') AS [Resolución Homologación],
    JSON_VALUE(d.Data, '$.bankDetails') AS [Banco Autorizado],
    (SELECT COUNT(*) FROM OPENJSON(d.Data, '$.documents')) AS [Docs Cargados],
    d.UpdatedBy AS [Responsable Registro],
    CONVERT(VARCHAR(19), d.UpdatedAt, 120) AS [Fecha Actualización]
FROM dbo.SupplierDirectory d
ORDER BY d.PartyId;
GO

PRINT '==============================================================================';
PRINT '3. CONSULTA: DOCUMENTOS LEGALES Y TÉCNICOS POR PROVEEDOR';
PRINT '==============================================================================';
SELECT 
    d.PartyId AS [Código],
    doc.[title] AS [Título Documento],
    doc.[type] AS [Tipo],
    doc.[issuedOn] AS [Emisión],
    COALESCE(NULLIF(doc.[expiresOn], ''), 'No aplica') AS [Vencimiento],
    doc.[review] AS [Revisión Documental],
    doc.[reviewedBy] AS [Revisor],
    doc.[reviewNote] AS [Fundamento Revisión]
FROM dbo.SupplierDirectory d
CROSS APPLY OPENJSON(d.Data, '$.documents') WITH (
    title NVARCHAR(240) '$.title',
    type NVARCHAR(100) '$.type',
    issuedOn NVARCHAR(40) '$.issuedOn',
    expiresOn NVARCHAR(40) '$.expiresOn',
    review NVARCHAR(40) '$.review',
    reviewedBy NVARCHAR(200) '$.reviewedBy',
    reviewNote NVARCHAR(1000) '$.reviewNote'
) AS doc
ORDER BY d.PartyId, doc.type;
GO

PRINT '==============================================================================';
PRINT '4. CONSULTA: COMPRAS VINCULADAS CON RECEPCIÓN EN BODEGA Y PAGOS EN TESORERÍA';
PRINT '==============================================================================';
SELECT 
    p.PurchaseNumber AS [No. Orden],
    p.SupplierPartyId AS [Código Prov],
    p.SupplierName AS [Proveedor],
    p.Total AS [Total Orden C$],
    CASE 
        WHEN p.Status = 'received' THEN 'Recibida en Bodega'
        WHEN p.Status = 'ordered' THEN 'Ordenada / En Tránsito'
        ELSE p.Status 
    END AS [Estado Recepción],
    CONVERT(VARCHAR(10), p.PurchaseDate, 120) AS [Fecha Orden],
    COALESCE(f.FinanceMoveId, 'Pendiente') AS [Comprobante Pago],
    f.Amount AS [Monto Pagado C$],
    CONVERT(VARCHAR(10), f.MoveDate, 120) AS [Fecha Pago Confirmado]
FROM dbo.Purchases p
LEFT JOIN dbo.FinanceMoves f ON f.PurchaseId = p.PurchaseId
ORDER BY p.PurchaseDate DESC;
GO

PRINT '==============================================================================';
PRINT '5. CONSULTA: EJECUCIÓN DEL PROCEDIMIENTO OFICIAL DEL EXPEDIENTE (pv1)';
PRINT '==============================================================================';
EXEC dbo.usp_ReadSupplierDirectory @PartyId = 'pv1';
GO
