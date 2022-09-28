-- https://www.mssqltips.com/sqlservertip/4402/new-drop-if-exists-syntax-in-sql-server-2016/
USE MyDBName
GO

/****** Object:  Table [DBO].[AtABLE]    Script Date: 9/21/2022 12:37:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AtABLE]') AND type in (N'U'))
    DROP TABLE dbo.[AtABLE]
GO
--proc
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_aStore_Proc]') AND type in (N'P'))
    DROP PROCEDURE dbo.[AtABLE]
GO
--job
USE [msdb]
GO
/****** Object:  Job [Ajob]    Script Date: 9/21/2022 1:30:16 PM ******/
IF EXISTS(select '1' from msdb.dbo.sysjobs_view WHERE name='Ajob')
    EXEC msdb.dbo.sp_delete_job @job_name=N'Ajob'
GO

USE [MedRxAnalytics]
GO
