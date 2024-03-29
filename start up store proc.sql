﻿--https://www.mssqltips.com/sqlservertip/1574/automatically-running-stored-procedures-at-sql-server-startup/
--https://blog.sqlauthority.com/2017/10/16/sql-server-configure-stored-procedure-run-server-startup-simple-tutorial/#:~:text=SQL%20SERVER%20%E2%80%93%20Configure%20Stored%20Procedure%20to%20Run,...%205%20Step%205%3A%20Results%20%E2%80%93%20Success%20


-- Check SQL Server services
SELECT
    servicename AS 'Service Name',
    startup_type_desc AS 'Startup Type',
    status_desc AS 'Current State'
FROM
    sys.dm_server_services;

--Enable Scan for Startup Proc
EXEC sys.sp_configure N'scan for startup procs', N'1'
-- --Disable Scan for Startup Proc	
-- EXEC sys.sp_configure N'scan for startup procs', N'1'	
GO
RECONFIGURE WITH OVERRIDE
GO


USE Master; 
GO
-- create SP to be run in master 
CREATE PROCEDURE [dbo].My_StoredProc AS
BEGIN
        -- its statements
	   return 0;
END;
GO
 
USE master
GO
-- make the SP a Startup SP
EXEC sp_procoption 
	   @ProcName = '[master].[dbo].My_StoredProc',
        @OptionName = 'STARTUP', 
	   @OptionValue = 'on' -- off ie to turn it off
GO
 
--Note:  Verify what routines are set as startup procedures thusly:
USE master
GO
SELECT *
FROM master.dbo.sysobjects
WHERE  OBJECTPROPERTY(id, 'ExecIsStartUp') = 1;
-- OR
--SELECT ROUTINE_NAME FROM MASTER.INFORMATION_SCHEMA.ROUTINES
--WHERE OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME),'ExecIsStartup') = 1;
 

 --any job schedule as startu job
SELECT j.name AS 'Job'
FROM msdb.dbo.sysschedules sched
JOIN msdb.dbo.sysjobschedules jsched ON sched.schedule_id = jsched.schedule_id
JOIN msdb.dbo.sysjobs j ON jsched.job_id = j.job_id
WHERE sched.freq_type = 64;
