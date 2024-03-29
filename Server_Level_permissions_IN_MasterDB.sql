 

--some credits to http://whoisactive.com/docs/28_access/ and https://www.sommarskog.se/grantperm.html#serverlevel
-- https://docs.microsoft.com/en-us/sql/t-sql/statements/create-certificate-transact-sql?view=sql-server-ver15

-- Please change password and keep safe
-- alter to the module here the sp will drop the signature then resign the module
-- replace mbello by the owner of the certificate 
-- signature, certificate, module/proc have to be in the same database
-- THIS IS NOT SAFE BECAUSE ANYONE CAN USE TO IT TO SIGN BETTER DROP THE PRIVATE KEY ONCE MODULE SIGNED
-- you should do all this for dba DB not in master
--refer to 
--	   Server_Level_permissions_To_DB.sql
--	   Server_Level_permissions_To_DB THROUGH ROLE.sql

-- 1 create the certificate
use master
go
create CERTIFICATE Certi_ForServerPermissions AUTHORIZATION sysadmin
ENCRYPTION BY PASSWORD = 'P@ssword!P@mizi'
WITH SUBJECT = 'For Non Admin',
EXPIRY_DATE = '9999-12-31'
GO

--2  create login: won't be able to login to the server
CREATE LOGIN User_ForServerPermissions FROM CERTIFICATE Certi_ForServerPermissions
GO

--3 Grant the server permission not allow for regular user
GRANT VIEW SERVER STATE TO User_ForServerPermissions
GO

--4 sign the module here SP with the certificate existing in the master
use master
go
ADD SIGNATURE TO dbo.sp_WhoIsActive BY CERTIFICATE Certi_ForServerPermissions
WITH PASSWORD = 'P@ssword!P@mizi'
GO

--5 create a user or use an existing
--create user testbello for login testbello

--6 grant the db user "exec" on the module
GRANT EXECUTE ON dbo.sp_WhoIsActive TO testbello

--7 test with the testbello
use master
exec as login = 'testbello'
--select * from fn_my_permissions(null,'database')
exec dbo.sp_WhoIsActive
revert; -- DON'T MISS THIS


--Please clean after yourself
use master
drop user if exists testbello -- if exists IN tsql in version 2016 and up
drop signature FROM dbo.sp_WhoIsActive BY  CERTIFICATE Certi_ForServerPermissions
DROP CERTIFICATE Certi_ForServerPermissions
DROP LOGIN User_ForServerPermissions
DROP PROC IF EXISTS dbo.sp_WhoIsActive
