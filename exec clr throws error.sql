-- https://docs.microsoft.com/en-us/troubleshoot/sql/admin/error-run-clr-object-create-assembly
--An error occurred in the Microsoft .NET Framework while trying to load assembly id ...

USE iThinkHealth;

EXEC sp_configure 'clr enabled', 1;  
RECONFIGURE;  
GO 


ALTER DATABASE <db_name> SET TRUSTWORTHY ON;

EXEC sp_changedbowner 'apps'

--map user in the database
ALTER USER APPS WITH LOGIN = APPS 


----CREATE LOGIN APPS WITH PASSWORD=N'DlcTHf0PGO9bcZL5u+zUvCFd+vV1NU/35Hy++0G+qa4=', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
----GO

----ALTER LOGIN APPS DISABLE
----GO

----ALTER SERVER ROLE [sysadmin] ADD MEMBER APPS
----GO

----ALTER SERVER ROLE [setupadmin] ADD MEMBER APPS
----GO