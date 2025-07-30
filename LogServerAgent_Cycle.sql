--Both create a new log file after we restart the SQL Engine. This will disrupt the size of the current log file.
--Set log file max sizes to 1GB and keep only 20 of them: No option available for Agent Log
--I can only change the logging level for SQL Agent nor SQL Server: Agent is set for Errors and Warnings

go

Create or alter proc sp_LogServerAgent
as

begin
-- last update 12/29/2023 By Monktar Bello: Initial version
--						  log Server log & Agent log in DBA database as to not the history because log recycling; daily basis
--						  

SET NOCOUNT ON

declare @LogType  int ; -- 1 ServerLog - 2 AgentLog
declare @retentionDays smallint = 90


DECLARE @maxLog      INT,
        @searchStr   VARCHAR(256),
        @startDate   DATETIME,
	   @EndDate   DATETIME;


declare @searchStrFail VARCHAR(256) = 'fail';
declare @searchStrAll VARCHAR(256) = '';-- !!!!!!!!!****Empty string search returns all from log

--parameters
SET @startDate = convert(datetime,replace(convert(CHAR(10), GETDATE(), 112),'-',''))
SET @EndDate = null

PRINT @startDate


DECLARE @errorLogs   TABLE (
    LogID    INT,
    LogDate  DATETIME,
    LogFileSizeBytes  BIGINT   );

DECLARE @logData      TABLE (
    LogDate     DATETIME,
    ProcInfo    VARCHAR(64),
    LogText     VARCHAR(MAX)   );


-- **errors' details
set @LogType  = 1 --ServerLog
-- get log files
INSERT INTO @errorLogs 
EXEC sys.xp_enumerrorlogs @LogType;
-- get data
INSERT INTO @logData
EXEC sp_User_readerrorlog 0, @LogType, @searchStrAll ,null, @startDate, @EndDate 


set @LogType  = 2 --AgentLog
-- get log files
INSERT INTO @errorLogs 
EXEC sys.xp_enumerrorlogs @LogType;
-- get data
INSERT INTO @logData
EXEC sp_User_readerrorlog 0, @LogType, @searchStrAll ,null, @startDate, @EndDate 



-- files' ErrorLogHeader
INSERT into DBA.dbo.ErrorLogHeader 
select logId, LogDate, LogFileSizeBytes/1024 as LogFileSizeKiloBytes, SERVERPROPERTY('ErrorLogFileName') AS 'SQL_Error_log_file_location', iif(@logType = 1, 'SQL Server Logs','SQL Agent Logs') as LogDescription, getdate() as DateInserted
 from @errorLogs order by LogID

 -- data
 INSERT INTO DBA.dbo.ErrorLogData
SELECT [LogDate], [LogText], ProcInfo, @logType as logType, iif(@logType = 1, 'SQL Server Logs','SQL Agent Logs') as LogDescription, getdate() as DateInserted
FROM @logData
ORDER BY [LogDate] DESC;


--SELECT * FROM DBA.dbo.ErrorLogHeader order by LogDescription, DateInserted

--SELECT * FROM DBA.dbo.ErrorLogData 
--where LogText not like 'Log was backed up%' and logtext not like 'BACKUP DATABASE WITH DIFFERENTIAL successfully%' and logtext not like 'Database differential changes were backed up%'
--    and LogText not like 'Buffer Pool scan%'
--order by LogDescription, DateInserted

delete from DBA.dbo.ErrorLogHeader where DateInserted < DATEADD(dd, -@retentionDays, getdate())
delete from DBA.dbo.ErrorLogData where DateInserted < DATEADD(dd, -@retentionDays, getdate())


end
