/* 00b — Borra y recrea [Instalaciones Raquel] desde cero.
   Ejecuta este archivo SOLO si quieres partir de una base vacía.
   Luego corre 00_crear_base.sql no hace falta: este ya crea la base.
   Siguiente: 01_catalogos.sql … 15_expedientes_proyectos.sql … 10_verificar.sql
*/
USE master;
GO

IF DB_ID(N'Instalaciones Raquel') IS NOT NULL
BEGIN
    ALTER DATABASE [Instalaciones Raquel] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [Instalaciones Raquel];
END;
GO

CREATE DATABASE [Instalaciones Raquel];
GO

SELECT name AS database_name, create_date, state_desc
FROM sys.databases
WHERE name = N'Instalaciones Raquel';
GO
