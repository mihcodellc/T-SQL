


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
--ALTER DATABASE Test SET OFFLINE
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

