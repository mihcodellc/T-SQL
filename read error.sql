--or UI in ssms under management or partially in beneath sql Agent 
--don't forget windows log is not reset after you restart your machine.


   declare @msg nvarchar(1000)
    set @msg = char(10) + @SPName +'''s parameters : ' +  char(10) +
			'@param1 = ' + CAST(@var1 AS varchar(12))  +
			', @param2 = ' + CAST(@var2 AS varchar(12))  +
			 char(10) + char(10) 
			+ ISNULL(ERROR_MESSAGE(),'') 

	RAISERROR ( @msg, 16, 1 );
	--Logs a user-defined message in the SQL Server log file and in the Windows Event Viewer. ie eventvwr.msc
	-- xp_logevent can be used to send an alert without sending a message to the client
	-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/xp-logevent-transact-sql?view=sql-server-ver15#result-sets
     EXEC xp_logevent 60000, @msg, informational;





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
SET @start = '2021-11-07 00:00:01.000';
SET @end = '2021-11-07 09:00:00.000';
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