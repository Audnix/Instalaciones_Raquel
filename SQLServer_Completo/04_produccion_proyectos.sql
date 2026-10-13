/* 04 — Proyectos de instalación y órdenes de taller (Kanban) */
USE [Instalaciones Raquel];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Projects', N'U') IS NULL
CREATE TABLE dbo.Projects
(
    ProjectId        NVARCHAR(100) NOT NULL CONSTRAINT PK_Projects PRIMARY KEY,
    Code             NVARCHAR(80)  NOT NULL CONSTRAINT UQ_Projects_Code UNIQUE,
    Name             NVARCHAR(240) NOT NULL,
    Client           NVARCHAR(240) NOT NULL,
    ClientPartyId    NVARCHAR(100) NULL
        CONSTRAINT FK_Projects_ClientParties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    Amount           DECIMAL(19,4) NOT NULL,
    Budget           DECIMAL(19,4) NULL,
    Progress         DECIMAL(7,4)  NOT NULL,
    ProjectState     NVARCHAR(120) NOT NULL
        CONSTRAINT FK_Projects_States FOREIGN KEY REFERENCES dbo.ProjectStates(StateName),
    Owner            NVARCHAR(200) NOT NULL,
    OwnerEmployeeId  NVARCHAR(100) NULL
        CONSTRAINT FK_Projects_OwnerEmployees FOREIGN KEY REFERENCES dbo.Employees(EmployeeId) ON DELETE SET NULL
);
GO

IF OBJECT_ID(N'dbo.ProjectStages', N'U') IS NULL
CREATE TABLE dbo.ProjectStages
(
    ProjectStageId NVARCHAR(100) NOT NULL CONSTRAINT PK_ProjectStages PRIMARY KEY,
    ProjectId      NVARCHAR(100) NOT NULL
        CONSTRAINT FK_ProjectStages_Projects FOREIGN KEY REFERENCES dbo.Projects(ProjectId) ON DELETE CASCADE,
    Name           NVARCHAR(200) NOT NULL,
    StartDate      DATE          NULL,
    EndDate        DATE          NULL,
    CostActual     DECIMAL(19,4) NOT NULL CONSTRAINT DF_ProjectStages_Cost DEFAULT (0)
);
GO

IF OBJECT_ID(N'dbo.ProductionOrders', N'U') IS NULL
CREATE TABLE dbo.ProductionOrders
(
    ProductionOrderId    NVARCHAR(100) NOT NULL CONSTRAINT PK_ProductionOrders PRIMARY KEY,
    Code                 NVARCHAR(80)  NOT NULL CONSTRAINT UQ_ProductionOrders_Code UNIQUE,
    Product              NVARCHAR(240) NOT NULL,
    Client               NVARCHAR(240) NOT NULL,
    ClientPartyId        NVARCHAR(100) NULL
        CONSTRAINT FK_ProductionOrders_ClientParties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    ProjectId            NVARCHAR(100) NULL
        CONSTRAINT FK_ProductionOrders_Projects FOREIGN KEY REFERENCES dbo.Projects(ProjectId) ON DELETE SET NULL,
    Quantity             DECIMAL(19,4) NOT NULL,
    Stage                NVARCHAR(30)  NOT NULL
        CONSTRAINT CK_ProductionOrders_Stage CHECK (Stage IN (N'backlog', N'corte', N'ensamble', N'instalacion', N'entregado')),
    ProductionStageCode  NVARCHAR(30)  NULL
        CONSTRAINT FK_ProductionOrders_Stages FOREIGN KEY REFERENCES dbo.ProductionStages(StageCode),
    Sprint               NVARCHAR(100) NOT NULL,
    Owner                NVARCHAR(200) NOT NULL,
    OwnerEmployeeId      NVARCHAR(100) NULL
        CONSTRAINT FK_ProductionOrders_OwnerEmployees FOREIGN KEY REFERENCES dbo.Employees(EmployeeId) ON DELETE SET NULL
);
GO
