USE [Instalaciones Raquel];
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ErpState WHERE StateId = 1)
BEGIN
    INSERT INTO dbo.ErpState (StateId, Payload)
    VALUES (1, N'{}');
END;
GO

SELECT StateId, UpdatedAt, DATALENGTH(Payload) AS payload_bytes
FROM dbo.ErpState
WHERE StateId = 1;
GO