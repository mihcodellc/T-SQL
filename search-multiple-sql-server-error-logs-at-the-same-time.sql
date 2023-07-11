--https://www.mssqltips.com/sqlservertip/3135/search-multiple-sql-server-error-logs-at-the-same-time/
SET NOCOUNT ON

DECLARE @maxLog      INT,
        @searchStr   VARCHAR(256),
        @startDate   DATETIME;

DECLARE @errorLogs   TABLE (
    LogID    INT,
    LogDate  DATETIME,
    LogSize  BIGINT   );

DECLARE @logData      TABLE (
    LogDate     DATETIME,
    ProcInfo    VARCHAR(64),
    LogText     VARCHAR(MAX)   );

SELECT  @searchStr = 'Server process ID is',
        @startDate = '2013-10-01 08:00';

INSERT INTO @errorLogs
EXEC sys.sp_enumerrorlogs;

SELECT TOP 1 @maxLog = LogID
FROM @errorLogs
WHERE [LogDate] <= @startDate
ORDER BY [LogDate] DESC;

WHILE @maxLog >= 0
BEGIN
    INSERT INTO @logData
    EXEC sys.sp_readerrorlog @maxLog, 1, @searchStr;
    
    SET @maxLog = @maxLog - 1;
END

SELECT [LogDate], [LogText]
FROM @logData
WHERE [LogDate] >= @startDate
ORDER BY [LogDate];