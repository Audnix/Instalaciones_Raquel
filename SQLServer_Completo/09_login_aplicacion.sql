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

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members AS rm
    JOIN sys.database_principals AS rolePrincipal ON rolePrincipal.principal_id = rm.role_principal_id
    JOIN sys.database_principals AS memberPrincipal ON memberPrincipal.principal_id = rm.member_principal_id
    WHERE rolePrincipal.name = N'db_datareader'
      AND memberPrincipal.name = N'raquel_erp_app'
)
    ALTER ROLE db_datareader ADD MEMBER [raquel_erp_app];

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members AS rm
    JOIN sys.database_principals AS rolePrincipal ON rolePrincipal.principal_id = rm.role_principal_id
    JOIN sys.database_principals AS memberPrincipal ON memberPrincipal.principal_id = rm.member_principal_id
    WHERE rolePrincipal.name = N'db_datawriter'
      AND memberPrincipal.name = N'raquel_erp_app'
)
    ALTER ROLE db_datawriter ADD MEMBER [raquel_erp_app];

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO [raquel_erp_app];
GRANT EXECUTE ON OBJECT::dbo.usp_SaveErpState TO [raquel_erp_app];
GO
