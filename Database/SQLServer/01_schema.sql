USE [Instalaciones Raquel];
GO

IF OBJECT_ID(N'dbo.ErpState', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ErpState
    (
        StateId TINYINT NOT NULL
            CONSTRAINT PK_ErpState PRIMARY KEY
            CONSTRAINT DF_ErpState_StateId DEFAULT (1),
        Payload NVARCHAR(MAX) NOT NULL,
        UpdatedAt DATETIME2(3) NOT NULL
            CONSTRAINT DF_ErpState_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        Revision ROWVERSION NOT NULL,
        CONSTRAINT CK_ErpState_Singleton CHECK (StateId = 1),
        CONSTRAINT CK_ErpState_Json CHECK (ISJSON(Payload) = 1)
    );
END;
GO

SELECT OBJECT_ID(N'dbo.ErpState', N'U') AS erp_state_table_id;
GO