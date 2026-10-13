/* 00 — Crear base de datos Instalaciones Raquel */
IF DB_ID(N'Instalaciones Raquel') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [Instalaciones Raquel]');
END;
GO

SELECT name AS database_name, create_date, state_desc
FROM sys.databases
WHERE name = N'Instalaciones Raquel';
GO
