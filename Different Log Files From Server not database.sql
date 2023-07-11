--********Following are the types of log files you can access using Log File Viewer:
--Audit Collection
--Data Collection
--Database Mail
--Job History
--Maintenance Plans
--Remote Maintenance Plans
--SQL Server
--SQL Server Agent
--Windows NT (These are Windows events that can also be accessed from Event Viewer.)

--**************SQL SERVER ERROR LOGS : management > SQL server Logs > properties
--file location: 
SELECT SERVERPROPERTY('ErrorLogFileName') AS 'Error log file location';
-- Every time SQL Server is started, the current error log is renamed to errorlog.1; errorlog.1 becomes errorlog.2, 
--     errorlog.2 becomes errorlog.3, and so on
USE [master]
GO
--INSERT into @table_error_logs (log_number, log_date, log_bytes) 
EXEC master.dbo.sp_enumerrorlogs
--change log size
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'ErrorLogSizeInKb', REG_DWORD, 1024
GO
--change # log files before recycle -- between 6(default) and 99
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 6 
GO
--recycle ie Closes the current error log file and cycles the error log extension numbers just like a server restart
EXEC sp_cycle_errorlog ;  
GO

--****************SQL SERVER AGENT ERROR LOGS: SQL Server Agent > Error Logs > properties
--SQL Server Agent maintains the nine(9) by default most recent error logs
--file location:
EXEC msdb.dbo.sp_get_sqlagent_properties
-- EXEC msdb.dbo.sp_help_alert
-- recycle ie Closes the current SQL Server Agent error log file and cycles the SQL Server Agent error log extension numbers just like a server restart
EXEC msdb.dbo.sp_cycle_agent_errorlog ;  
GO  
--change Agent log level 
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @errorlogging_level=7
GO
