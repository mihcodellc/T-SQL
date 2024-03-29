-- https://www.mssqltips.com/sqlservertip/4402/new-drop-if-exists-syntax-in-sql-server-2016/
USE MyDBName
GO

/****** Object:  Table [DBO].[AtABLE]    Script Date: 9/21/2022 12:37:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--trigger
IF OBJECT_ID('Sales.tr_SalesOrderDetailsDML', 'TR') IS NOT NULL
    DROP TRIGGER Sales.tr_SalesOrderDetailsDML;

--functions
IF OBJECT_ID('dbo].[AFunction]', 'FN') IS NOT NULL --'FN','IF', 'FS'
--IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AFunction]') AND type in ('FN','IF', 'FS'))
    DROP TABLE dbo.[AtABLE]

--table
IF OBJECT_ID('dbo].[AtABLE]', 'U') IS NOT NULL
--IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AtABLE]') AND type in (N'U'))
    DROP TABLE dbo.[AtABLE]
GO

-- column
if exists (select 1 from information_schema.columns where table_name = 'AtABLE' and column_name = 'aColumn')
begin
    ............
END
GO    
    
--proc
IF OBJECT_ID('dbo].[usp_aStore_Proc]', 'P') IS NOT NULL
--IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_aStore_Proc]') AND type in (N'P'))
    DROP PROCEDURE dbo.[usp_aStore_Proc]
GO

--job
USE [msdb]
GO
/****** Object:  Job [Ajob]    Script Date: 9/21/2022 1:30:16 PM ******/
IF EXISTS(select '1' from msdb.dbo.sysjobs_view WHERE name='Ajob')
    EXEC msdb.dbo.sp_delete_job @job_name=N'Ajob'
GO

USE [database]
GO
