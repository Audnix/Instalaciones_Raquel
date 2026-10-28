/* 05 — Tesorería, contabilidad, cartera, planilla */
USE [Instalaciones Raquel];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.PayrollRuns', N'U') IS NULL
CREATE TABLE dbo.PayrollRuns
(
    PayrollRunId NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollRuns PRIMARY KEY,
    Period       NVARCHAR(40)  NOT NULL,
    PaidAt       DATETIMEOFFSET(3) NOT NULL,
    Actor        NVARCHAR(200) NOT NULL,
    ActorUserId  NVARCHAR(100) NULL
        CONSTRAINT FK_PayrollRuns_ActorUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
    Gross        DECIMAL(19,4) NOT NULL,
    InssLaboral  DECIMAL(19,4) NOT NULL,
    InssPatronal DECIMAL(19,4) NOT NULL,
    Inatec       DECIMAL(19,4) NOT NULL,
    IncomeTax    DECIMAL(19,4) NOT NULL,
    Net          DECIMAL(19,4) NOT NULL,
    EmployerCost DECIMAL(19,4) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.PayrollRunItems', N'U') IS NULL
CREATE TABLE dbo.PayrollRunItems
(
    PayrollRunId NVARCHAR(100) NOT NULL
        CONSTRAINT FK_PayrollRunItems_PayrollRuns FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EmployeeId   NVARCHAR(100) NOT NULL
        CONSTRAINT FK_PayrollRunItems_Employees FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    Gross        DECIMAL(19,4) NOT NULL,
    InssLaboral  DECIMAL(19,4) NOT NULL,
    IncomeTax    DECIMAL(19,4) NOT NULL,
    Net          DECIMAL(19,4) NOT NULL,
    InssPatronal DECIMAL(19,4) NOT NULL,
    Inatec       DECIMAL(19,4) NOT NULL,
    Aguinaldo    DECIMAL(19,4) NOT NULL,
    EmployerCost DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_PayrollRunItems PRIMARY KEY (PayrollRunId, EmployeeId)
);
GO

IF OBJECT_ID(N'dbo.CashMoves', N'U') IS NULL
CREATE TABLE dbo.CashMoves
(
    CashMoveId      NVARCHAR(100) NOT NULL CONSTRAINT PK_CashMoves PRIMARY KEY,
    Account         NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_CashMoves_Account CHECK (Account IN (N'caja', N'banco')),
    CashAccountCode NVARCHAR(20)  NULL
        CONSTRAINT FK_CashMoves_CashAccounts FOREIGN KEY REFERENCES dbo.CashAccounts(AccountCode),
    MoveType        NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_CashMoves_MoveType CHECK (MoveType IN (N'entrada', N'salida')),
    Amount          DECIMAL(19,4) NOT NULL,
    MoveDate        DATETIMEOFFSET(3) NOT NULL,
    Concept         NVARCHAR(1000) NOT NULL,
    SaleId          NVARCHAR(100) NULL
        CONSTRAINT FK_CashMoves_Sales FOREIGN KEY REFERENCES dbo.Sales(SaleId) ON DELETE SET NULL,
    PurchaseId      NVARCHAR(100) NULL
        CONSTRAINT FK_CashMoves_Purchases FOREIGN KEY REFERENCES dbo.Purchases(PurchaseId) ON DELETE SET NULL,
    PayrollRunId    NVARCHAR(100) NULL
        CONSTRAINT FK_CashMoves_PayrollRuns FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE SET NULL
);
GO

IF OBJECT_ID(N'dbo.FinanceMoves', N'U') IS NULL
CREATE TABLE dbo.FinanceMoves
(
    FinanceMoveId        NVARCHAR(100)  NOT NULL CONSTRAINT PK_FinanceMoves PRIMARY KEY,
    MoveType             NVARCHAR(20)   NOT NULL
        CONSTRAINT CK_FinanceMoves_MoveType CHECK (MoveType IN (N'ingreso', N'egreso')),
    Category             NVARCHAR(160)  NOT NULL,
    FinanceCategoryName  NVARCHAR(160)  NULL
        CONSTRAINT FK_FinanceMoves_Categories FOREIGN KEY REFERENCES dbo.FinanceCategories(CategoryName),
    Amount               DECIMAL(19,4)  NOT NULL,
    MoveDate             DATETIMEOFFSET(3) NOT NULL,
    Note                 NVARCHAR(1000) NOT NULL,
    UserName             NVARCHAR(200)  NOT NULL,
    AppUserId            NVARCHAR(100)  NULL
        CONSTRAINT FK_FinanceMoves_AppUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
    SaleId               NVARCHAR(100)  NULL
        CONSTRAINT FK_FinanceMoves_Sales FOREIGN KEY REFERENCES dbo.Sales(SaleId) ON DELETE SET NULL,
    PurchaseId           NVARCHAR(100)  NULL
        CONSTRAINT FK_FinanceMoves_Purchases FOREIGN KEY REFERENCES dbo.Purchases(PurchaseId) ON DELETE SET NULL,
    PayrollRunId         NVARCHAR(100)  NULL
        CONSTRAINT FK_FinanceMoves_PayrollRuns FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE SET NULL
);
GO

IF OBJECT_ID(N'dbo.AccountingEntries', N'U') IS NULL
CREATE TABLE dbo.AccountingEntries
(
    AccountingEntryId NVARCHAR(100)  NOT NULL CONSTRAINT PK_AccountingEntries PRIMARY KEY,
    EntryNumber       NVARCHAR(80)   NOT NULL CONSTRAINT UQ_AccountingEntries_Number UNIQUE,
    Description       NVARCHAR(1000) NOT NULL,
    Debit             DECIMAL(19,4)  NOT NULL,
    Credit            DECIMAL(19,4)  NOT NULL,
    DebitAccount      NVARCHAR(200)  NOT NULL,
    CreditAccount     NVARCHAR(200)  NOT NULL,
    DebitAccountRef   NVARCHAR(200)  NULL
        CONSTRAINT FK_AccountingEntries_DebitAccounts FOREIGN KEY REFERENCES dbo.ChartOfAccounts(AccountName),
    CreditAccountRef  NVARCHAR(200)  NULL
        CONSTRAINT FK_AccountingEntries_CreditAccounts FOREIGN KEY REFERENCES dbo.ChartOfAccounts(AccountName),
    EntryDate         DATETIMEOFFSET(3) NOT NULL,
    ReferenceType     NVARCHAR(20)   NOT NULL
        CONSTRAINT CK_AccountingEntries_ReferenceType CHECK (ReferenceType IN (N'sale', N'purchase', N'manual', N'payroll', N'cash')),
    ReferenceId       NVARCHAR(100)  NULL,
    SaleId            NVARCHAR(100)  NULL
        CONSTRAINT FK_AccountingEntries_Sales FOREIGN KEY REFERENCES dbo.Sales(SaleId),
    PurchaseId        NVARCHAR(100)  NULL
        CONSTRAINT FK_AccountingEntries_Purchases FOREIGN KEY REFERENCES dbo.Purchases(PurchaseId),
    PayrollRunId      NVARCHAR(100)  NULL
        CONSTRAINT FK_AccountingEntries_PayrollRuns FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId),
    CashMoveId        NVARCHAR(100)  NULL
        CONSTRAINT FK_AccountingEntries_CashMoves FOREIGN KEY REFERENCES dbo.CashMoves(CashMoveId),
    CONSTRAINT CK_AccountingEntries_PartidaDoble CHECK (Debit = Credit)
);
GO

IF OBJECT_ID(N'dbo.Projections', N'U') IS NULL
CREATE TABLE dbo.Projections
(
    ProjectionId  NVARCHAR(100) NOT NULL CONSTRAINT PK_Projections PRIMARY KEY,
    MonthLabel    NVARCHAR(40)  NOT NULL,
    MonthNumber   TINYINT       NULL
        CONSTRAINT FK_Projections_ForecastMonths FOREIGN KEY REFERENCES dbo.ForecastMonths(MonthNumber),
    ExpectedSales DECIMAL(19,4) NOT NULL,
    ExpectedCosts DECIMAL(19,4) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.AccountsReceivable', N'U') IS NULL
CREATE TABLE dbo.AccountsReceivable
(
    ReceivableId NVARCHAR(100) NOT NULL CONSTRAINT PK_AccountsReceivable PRIMARY KEY,
    SaleId       NVARCHAR(100) NOT NULL
        CONSTRAINT FK_AccountsReceivable_Sales FOREIGN KEY REFERENCES dbo.Sales(SaleId) ON DELETE CASCADE,
    PartyId      NVARCHAR(100) NULL
        CONSTRAINT FK_AccountsReceivable_Parties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    Amount       DECIMAL(19,4) NOT NULL,
    Balance      DECIMAL(19,4) NOT NULL,
    DueDate      DATE          NULL,
    Status       NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_AccountsReceivable_Status CHECK (Status IN (N'abierta', N'parcial', N'cobrada', N'vencida'))
);
GO

IF OBJECT_ID(N'dbo.AccountsPayable', N'U') IS NULL
CREATE TABLE dbo.AccountsPayable
(
    PayableId  NVARCHAR(100) NOT NULL CONSTRAINT PK_AccountsPayable PRIMARY KEY,
    PurchaseId NVARCHAR(100) NOT NULL
        CONSTRAINT FK_AccountsPayable_Purchases FOREIGN KEY REFERENCES dbo.Purchases(PurchaseId) ON DELETE CASCADE,
    PartyId    NVARCHAR(100) NULL
        CONSTRAINT FK_AccountsPayable_Parties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    Amount     DECIMAL(19,4) NOT NULL,
    Balance    DECIMAL(19,4) NOT NULL,
    DueDate    DATE          NULL,
    Status     NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_AccountsPayable_Status CHECK (Status IN (N'abierta', N'parcial', N'pagada'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.FinanceMoves') AND name = N'IX_FinanceMoves_Date')
    CREATE INDEX IX_FinanceMoves_Date ON dbo.FinanceMoves(MoveDate DESC);
GO
