USE [master];
GO

DECLARE @AppPassword NVARCHAR(128) = N'CAMBIA_ESTA_CLAVE_privada_2026!';

IF @AppPassword = N'CAMBIA_ESTA_CLAVE_privada_2026!'
BEGIN
    THROW 50001, 'Cambia @AppPassword por una clave privada y usa la misma en DB_PASSWORD del archivo .env.', 1;
    RETURN;
END;

IF SUSER_ID(N'raquel_erp_app') IS NULL
BEGIN
    DECLARE @CreateLogin NVARCHAR(MAX) =
        N'CREATE LOGIN [raquel_erp_app] WITH PASSWORD = ' + QUOTENAME(@AppPassword, '''') +
        N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC sys.sp_executesql @CreateLogin;
END;
ELSE
BEGIN
    DECLARE @UpdateLogin NVARCHAR(MAX) =
        N'ALTER LOGIN [raquel_erp_app] WITH PASSWORD = ' + QUOTENAME(@AppPassword, '''') +
        N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC sys.sp_executesql @UpdateLogin;
END;

IF SUSER_ID(N'raquel_erp_app') IS NULL
    THROW 50002, 'No se pudo crear el login raquel_erp_app; revisa los permisos del usuario actual.', 1;

GRANT CONNECT SQL TO [raquel_erp_app];
GRANT CONNECT ON ENDPOINT::[TSQL Default TCP] TO [raquel_erp_app];
GO

USE [Instalaciones Raquel];
GO

IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NULL
    CREATE USER [raquel_erp_app] FOR LOGIN [raquel_erp_app];

GRANT SELECT, INSERT, UPDATE ON dbo.ErpState TO [raquel_erp_app];
GRANT EXECUTE ON OBJECT::dbo.usp_SaveErpState TO [raquel_erp_app];
GO