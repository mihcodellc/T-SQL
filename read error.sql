SELECT SERVERPROPERTY('ErrorLogFileName') AS 'Error log file location';

--https://www.sqlshack.com/read-sql-server-error-logs-using-the-xp_readerrorlog-command/

-- exec sp_readerrorlog or exec xp_ReadErrorLog
--Read  error log
EXEC xp_ReadErrorLog 0,1

EXEC xp_ReadErrorLog 0,1, N'Violation'

--Read  agent log
EXEC xp_ReadErrorLog 0,2

--search using xp_readErrorLog
DECLARE @logFileType SMALLINT= 1;
DECLARE @start DATETIME;
DECLARE @end DATETIME;
DECLARE @logno INT= 0;
SET @start = '2019-11-07 00:00:01.000';
SET @end = '2019-11-07 09:00:00.000';
DECLARE @searchString1 NVARCHAR(256)= 'Recovery';
DECLARE @searchString2 NVARCHAR(256)= 'MSDB';
EXEC master.dbo.xp_readerrorlog 
     @logno, 
     @logFileType, 
     @searchString1, 
     @searchString2, 
     @start, 
     @end;



	EXEC sp_readerrorlog