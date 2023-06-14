-- https://docs.microsoft.com/en-us/troubleshoot/sql/admin/error-run-clr-object-create-assembly
--An error occurred in the Microsoft .NET Framework while trying to load assembly id ...



USE mydb;

EXEC sp_configure 'clr enabled', 1;  
RECONFIGURE;  
GO 


ALTER DATABASE <db_name> SET TRUSTWORTHY ON;

EXEC sp_changedbowner 'apps'

--map user in the database
ALTER USER APPS WITH LOGIN = APPS 



--CLR views
select * from sys.assemblies
select * from sys.dm_clr_appdomains
select * from sys.dm_clr_loaded_assemblies 
select * from sys.dm_clr_tasks 

--details of all assemblies in the current database
 SELECT a.name, a.assembly_id, a.permission_set_desc, a.is_visible, a.create_date, l.load_time   
FROM sys.dm_clr_loaded_assemblies AS l   
INNER JOIN sys.assemblies AS a  
ON l.assembly_id = a.assembly_id;  

--details of the AppDomain in which the assembly_id = 65537  is loaded
SELECT appdomain_id, creation_time, db_id, user_id, state  
FROM sys.dm_clr_appdomains AS a  
WHERE appdomain_address =   
(SELECT appdomain_address   
 FROM sys.dm_clr_loaded_assemblies  
 WHERE assembly_id = 65537); 

----CREATE LOGIN APPS WITH PASSWORD=N'DlcTHf0PGO9bcZL5u+zUvCFd+vV1NU/35Hy++0G+qa4=', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
----GO

----ALTER LOGIN APPS DISABLE
----GO

----ALTER SERVER ROLE [sysadmin] ADD MEMBER APPS
----GO

----ALTER SERVER ROLE [setupadmin] ADD MEMBER APPS
----GO
