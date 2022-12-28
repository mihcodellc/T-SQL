-- https://docs.microsoft.com/en-us/troubleshoot/sql/admin/error-run-clr-object-create-assembly
--An error occurred in the Microsoft .NET Framework while trying to load assembly id ...

--1
ALTER DATABASE <user_db_name> SET TRUSTWORTHY ON;
--2
USE <user_db_name>;
EXEC sp_changedbowner 'sa' --the original owner db owner 


USE <user_db_name>;

EXEC sp_configure 'clr enabled', 1;  
RECONFIGURE;  
GO 


--map user in the database
ALTER USER APPS WITH LOGIN = APPS --relink the owner with its property


--??use master
--??go
--??GRANT ??UNSAFE ASSEMBLY TO sa;
