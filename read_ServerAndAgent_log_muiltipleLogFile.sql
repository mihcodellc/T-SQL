--https://www.mssqltips.com/sqlservertip/3135/search-multiple-sql-server-error-logs-at-the-same-time/

-- last update 7/10/2023 By Monktar Bello: 
--						  used only sys.xp_enumerrorlogs
--						  search different texts
--						  enabled search from Agent log or SQL Server Log

SET NOCOUNT ON

DECLARE @maxLog      INT,
        @searchStr   VARCHAR(256),
        @startDate   DATETIME;

DECLARE @errorLogs   TABLE (
    LogID    INT,
    LogDate  DATETIME,
    LogFileSizeBytes  BIGINT   );

DECLARE @logData      TABLE (
    LogDate     DATETIME,
    ProcInfo    VARCHAR(64),
    LogText     VARCHAR(MAX)   );

SELECT @startDate = dateadd(dd,-7,GETDATE());

declare @LogType  int = 1 -- 1 ServerLog - 2 AgentLog

SELECT iif(@logType = 1, 'SQL Server Logs','SQL Agent Logs') as LogType

declare @searchStrFail VARCHAR(256) = 'fail';
declare @searchStrError VARCHAR(256) = 'error';
declare @searchStrWarning VARCHAR(256) = 'warning';
declare @searchStrPort VARCHAR(256) = 'Server is listening on';

-- get log files
INSERT INTO @errorLogs 
EXEC sys.xp_enumerrorlogs @LogType;

--locations
--SELECT SERVERPROPERTY('ErrorLogFileName') AS 'SQL Error log file location';
--EXEC msdb.dbo.sp_get_sqlagent_properties

-- errors log files
select * from @errorLogs

SELECT TOP 1 @maxLog = LogID
FROM @errorLogs
WHERE [LogDate] <= @startDate
ORDER BY [LogDate] DESC;

WHILE @maxLog >= 0
BEGIN
    INSERT INTO @logData
    EXEC sys.sp_readerrorlog @maxLog, @LogType, @searchStrFail --optional @startDate, @EndDate 
    
    INSERT INTO @logData
    EXEC sys.sp_readerrorlog @maxLog, @LogType, @searchStrError --optional @startDate, @EndDate 

    INSERT INTO @logData
    EXEC sys.sp_readerrorlog @maxLog, @LogType, @searchStrWarning --optional @startDate, @EndDate 

     INSERT INTO @logData
    EXEC sys.sp_readerrorlog @maxLog, @LogType, @searchStrPort --optional @startDate, @EndDate 

    SET @maxLog = @maxLog - 1;
END

SELECT [LogDate], [LogText]
FROM @logData
WHERE [LogDate] >= @startDate
ORDER BY [LogDate] DESC;