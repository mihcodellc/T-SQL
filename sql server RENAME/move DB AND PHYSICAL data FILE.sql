
--rename the instance
--https://docs.microsoft.com/en-us/sql/database-engine/install-windows/rename-a-computer-that-hosts-a-stand-alone-instance-of-sql-server?view=sql-server-ver16
EXEC sp_dropserver 'asp-sql-new3'; 
GO 
EXEC sp_addserver 'asp-sql', local; 
GO


--find the db files and locations
 SELECT name ,  is_percent_growth, physical_name 
FROM sys.database_files


--find the db files and locations --CERTAIN THAN PREVIOUS sys.database_files
 SELECT DB_name(database_id) dbName, name ,  is_percent_growth, physical_name 
FROM sys.master_files-- database_files
where database_id = DB_ID(Db_name())
order by 1

 --!!!!!IF DATABASE IN LOGSHIPPING, DISABLE RETORE JOB, MAKE SURE NO PENDING RESTORE IS ACTIVE
 --!!!!! remember to enable it back once done
  
ALTER DATABASE belloTest SET ONLINE;
--change the name
ALTER DATABASE belloTest MODIFY NAME = Test;
-- Changing logical names
ALTER DATABASE Test MODIFY FILE (NAME = belloTest, NEWNAME = Test);
ALTER DATABASE Test MODIFY FILE (NAME = belloTest_log, NEWNAME = Test_log);
--Take Database Offline EXCEPT FOR Tempdb ; no need because it gets created the next the server is restarted
USE master --Important otherwise a failure
ALTER DATABASE Test SET OFFLINE;

---- IF ABOVE QUERY FAILS, RUN  BELOW QUERY
--USE [master];
--GO
--ALTER DATABASE Test
--SET SINGLE_USER WITH ROLLBACK IMMEDIATE
--GO
--ALTER DATABASE Test SET OFFLINE -- easy way to set db offline : restart sql instance and set it right away offline
--GO

--Change the file location inside SQL Server with new name
ALTER DATABASE Test MODIFY FILE ( NAME = Test, FILENAME = 'E:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Test.mdf' ); -- proof that you can change DB files' names 
ALTER DATABASE Test MODIFY FILE ( NAME = Test_log, FILENAME = 'E:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Test_log.ldf' );---- proof that you can change DB files' names 
GO
-- !!! ATTENTION !!! go inside the physical folder and and change the physical name
--Bring Database Online
USE [master];
GO
ALTER DATABASE Test SET ONLINE
Go
ALTER DATABASE Test SET MULTI_USER
GO

