/* 10 — Verificación: tablas, FKs, vistas, procedimiento y conteos */
USE [Instalaciones Raquel];
GO

SELECT t.name AS Tabla, SUM(p.rows) AS FilasAprox
FROM sys.tables AS t
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
GROUP BY t.name
ORDER BY t.name;

SELECT fk.name AS Relacion,
       OBJECT_NAME(fk.parent_object_id) AS TablaHija,
       OBJECT_NAME(fk.referenced_object_id) AS TablaPadre
FROM sys.foreign_keys AS fk
ORDER BY TablaPadre, TablaHija;

SELECT name AS Vista FROM sys.views WHERE schema_id = SCHEMA_ID(N'dbo') ORDER BY name;

SELECT OBJECT_ID(N'dbo.usp_SaveErpState', N'P') AS ProcedimientoGuardado,
       (SELECT COUNT(*) FROM dbo.AppUsers) AS Usuarios,
       (SELECT COUNT(*) FROM dbo.Products) AS Productos,
       (SELECT COUNT(*) FROM dbo.Parties) AS Terceros,
       (SELECT COUNT(*) FROM dbo.ErpState) AS Snapshot;
GO
