use master
go

create or alter proc sp_User_readerrorlog(
	@p1		int = 0,
	@p2		int = NULL,
	@p3		nvarchar(4000) = NULL,
	@p4		nvarchar(4000) = NULL,
	@date1		datetime = NULL,
	@date2 datetime = NULL)
as
begin

	IF (not is_srvrolemember(N'securityadmin') = 1) AND (not HAS_PERMS_BY_NAME(null, null, 'VIEW SERVER STATE') = 1)
	begin
		raiserror(27219,-1,-1)
		return (1)
	end
	
	if (@p2 is NULL)
		exec sys.xp_readerrorlog @p1
	else
		exec sys.xp_readerrorlog @p1,@p2,@p3,@p4,@date1,@date2
end

go
EXEC sys.sp_MS_marksystemobject 'sp_User_readerrorlog';
GO


--https://www.mssqltips.com/sqlservertip/3135/search-multiple-sql-server-error-logs-at-the-same-time/

--*********Description: search some texts through SQL Server & Agent logs from the last 7 days

-- last update 7/10/2023 By Monktar Bello: 
--						  used only sys.xp_enumerrorlogs
--						  search different texts
--						  enabled search from Agent log or SQL Server Log

SET NOCOUNT ON

DECLARE @maxLog      INT,
        @searchStr   VARCHAR(256),
        @startDate   DATETIME,
	   @EndDate   DATETIME;


declare @searchStrFail VARCHAR(256) = 'fail';
declare @searchStrAll VARCHAR(256) = '';-- !!!!!!!!!****Empty string search returns all from log
declare @searchStrError VARCHAR(256) = 'error';
declare @searchStrWarning VARCHAR(256) = 'warning';
declare @searchStrPort VARCHAR(256) = 'Server is listening on';

--parameters
SET @startDate = dateadd(dd,-7,GETDATE())  ; 
SET @EndDate = dateadd(dd,1,GETDATE())  

declare @LogType  int = 1 -- 1 ServerLog - 2 AgentLog


DECLARE @errorLogs   TABLE (
    LogID    INT,
    LogDate  DATETIME,
    LogFileSizeBytes  BIGINT   );

DECLARE @logData      TABLE (
    LogDate     DATETIME,
    ProcInfo    VARCHAR(64),
    LogText     VARCHAR(MAX)   );


SELECT iif(@logType = 1, 'SQL Server Logs','SQL Agent Logs') as LogType


-- get log files
INSERT INTO @errorLogs 
EXEC sys.xp_enumerrorlogs @LogType;

--locations
--SELECT SERVERPROPERTY('ErrorLogFileName') AS 'SQL Error log file location';
--EXEC msdb.dbo.sp_get_sqlagent_properties

-- errors log files
select logId, LogDate, LogFileSizeBytes/1024 as LogFileSizeKiloBytes  from @errorLogs order by LogID

SELECT @maxLog = max(LogID)
FROM @errorLogs
--WHERE [LogDate] <= @startDate
--ORDER BY [LogDate] DESC;
select @maxLog 'maxlog'



WHILE @maxLog >= 0
BEGIN
    --INSERT INTO @logData
    --EXEC sp_User_readerrorlog @maxLog, @LogType, @searchStrAll ,null, @startDate, @EndDate 
    
    INSERT INTO @logData
    EXEC sp_User_readerrorlog @maxLog, @LogType, @searchStrFail ,null, @startDate, @EndDate 

    INSERT INTO @logData
    EXEC sp_User_readerrorlog @maxLog, @LogType, @searchStrError ,null, @startDate, @EndDate 

      INSERT INTO @logData
    EXEC sp_User_readerrorlog @maxLog, @LogType, @searchStrWarning ,null, @startDate, @EndDate

   INSERT INTO @logData
    EXEC sp_User_readerrorlog @maxLog, @LogType, @searchStrPort ,null, @startDate, @EndDate


    

    SET @maxLog = @maxLog - 1;
END

SELECT [LogDate], [LogText], ProcInfo
FROM @logData
where LogText not like 'CHECKDB%' AND  LogText not like 'Log was backed up%'
ORDER BY [LogDate] DESC;
