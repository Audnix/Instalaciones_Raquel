/* 09 — Login de la API. Pon la MISMA clave que DB_PASSWORD en el .env */
USE master;
GO

DECLARE @AppPassword NVARCHAR(128) = N'$(AppPassword)';

IF @AppPassword IN (N'CAMBIA_ESTA_CLAVE', N'change-this-before-running')
   OR @AppPassword = N'$' + N'(AppPassword)'
BEGIN
    THROW 50001, 'Pasa la clave con npm run db:install (usa DB_PASSWORD del .env) o edita 09_login_aplicacion.sql en SSMS.', 1;
    RETURN;
END;

IF SUSER_ID(N'raquel_erp_app') IS NULL
BEGIN
    DECLARE @CreateLogin NVARCHAR(MAX) =
        N'CREATE LOGIN [raquel_erp_app] WITH PASSWORD = ' + QUOTENAME(@AppPassword, '''') +
        N', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;';
    EXEC sys.sp_executesql @CreateLogin;
END;
ELSE
BEGIN
    DECLARE @UpdateLogin NVARCHAR(MAX) =
        N'ALTER LOGIN [raquel_erp_app] WITH PASSWORD = ' + QUOTENAME(@AppPassword, '''') +
        N', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;';
    EXEC sys.sp_executesql @UpdateLogin;
END;

GRANT CONNECT SQL TO [raquel_erp_app];
GO

USE [Instalaciones Raquel];
GO

IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NULL
    CREATE USER [raquel_erp_app] FOR LOGIN [raquel_erp_app];

IF IS_ROLEMEMBER(N'db_datareader', N'raquel_erp_app') = 1
    ALTER ROLE db_datareader DROP MEMBER [raquel_erp_app];
IF IS_ROLEMEMBER(N'db_datawriter', N'raquel_erp_app') = 1
    ALTER ROLE db_datawriter DROP MEMBER [raquel_erp_app];

REVOKE SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo FROM [raquel_erp_app];
GRANT SELECT ON OBJECT::dbo.ErpState TO [raquel_erp_app];
GRANT UPDATE ON OBJECT::dbo.ErpState TO [raquel_erp_app];
GRANT SELECT ON OBJECT::dbo.Parties TO [raquel_erp_app];
GRANT EXECUTE ON OBJECT::dbo.usp_SaveErpState TO [raquel_erp_app];
GO
