-- kill connection to dbBello
SELECT status,database_id, DB_NAME(database_id) DBNAME,
'use master; Kill ' + convert(char(4), session_id) as Command
FROM sys.dm_exec_sessions WHERE DB_NAME(database_id) = 'dbBello' AND database_id>0

----drop database if exists dbBello


create database dbBello WITH TRUSTWORTHY ON
ALTER AUTHORIZATION ON DATABASE::dbBello TO sa; --EXEC sp_changedbowner 'sa' deprecated
--ALTER DATABASE dbBello SET TRUSTWORTHY ON

drop login if exists testbello
create login testbello with password = 'L131atpe?', CHECK_POLICY = OFF;

---- drop an user from all db on the instance
--exec sp_MSforeachdb N'use [?] ; 
--IF  EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''testbello'')
--    DROP USER [testbello];'


use dbBello
create user testbello
go
use MedRx
create user testbello


grant execute on object::dbBello.dbo.sp_WhoIsActive to testbello

EXEC rmsadmin.dbo.sp_WhoIsActive
grant execute on object::dbBello.dbo.sp_WhoIsActive to testbello
go

--create login testbello with name = testbello
use dbBello
grant connect to testBello 
use MedRx
grant connect to testBello

--grant view server state to testBello

select * from sys.databases

EXEC dbBello.dbo.sp_WhoIsActive

USE [master] 
GO 
SELECT 'KILL ' + CAST(session_id AS VARCHAR(10)) AS 'SQL Command', 
login_name as 'Login'
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
AND login_name = 'testbello';
kill 72


--Warning: The join order has been enforced because a local join hint is used.
--Msg 15562, Level 16, State 1, Line 38
--The module being executed is not trusted. Either the owner of the database of the module needs to be granted authenticate permission, or the module needs to be digitally signed.
--Msg 15562, Level 16, State 1, Line 331
--The module being executed is not trusted. Either the owner of the database of the module needs to be granted authenticate permission, or the module needs to be digitally signed.

--Completion time: 2022-03-04T14:22:34.3029593-06:00
