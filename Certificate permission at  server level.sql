--some credits to http://whoisactive.com/docs/28_access/ and https://www.sommarskog.se/grantperm.html#serverlevel
-- https://docs.microsoft.com/en-us/sql/t-sql/statements/create-certificate-transact-sql?view=sql-server-ver15
--sql server 2017 compati 140


--**1 Create the certificate in the user database. 
use AdminDB
go
CREATE CERTIFICATE Certi_ForServerPermissions AUTHORIZATION dbo
ENCRYPTION BY PASSWORD = 'P@ssword!P@mizi'
WITH SUBJECT = 'For Non Admin',
EXPIRY_DATE = '9999-12-31'
GO

--**2 Sign the procedure.
use AdminDB
go
ADD SIGNATURE TO dbo.p_RMSInsertDDL
BY CERTIFICATE Certi_ForServerPermissions
WITH PASSWORD = 'P@ssword!P@mizi'
GO

ADD SIGNATURE TO dbo.sp_WhoIsActive
BY CERTIFICATE Certi_ForServerPermissions
WITH PASSWORD = 'P@ssword!P@mizi'
GO


ADD SIGNATURE TO dbo.TestCreditRatingSP
BY CERTIFICATE Certi_ForServerPermissions
WITH PASSWORD = 'P@ssword!P@mizi'
GO

--**3 Drop the private key.
--	   (safe to avoid anyone to use the pass to sign others thing) because of this, 
--	   drop the signature and the certificate and create a new certificate then resign the proc after alter the proc
ALTER CERTIFICATE Certi_ForServerPermissions REMOVE PRIVATE KEY

--**4 Copy the certificate to master.
use AdminDB
GO
DECLARE @public_key varbinary(MAX), @sql nvarchar(MAX);

SET @public_key = certencoded(cert_id('Certi_ForServerPermissions'));
SET @sql = 'CREATE CERTIFICATE Certi_ForServerPermissions FROM BINARY = ' + convert(varchar(MAX), @public_key, 1);

USE UserDB
--PRINT 
EXEC(@sql)


--**5 Create a login from the certificate.
CREATE LOGIN User_ForServerPermissions FROM CERTIFICATE Certi_ForServerPermissions


--**6 Grant the certificate login the required permissions.
GRANT VIEW SERVER STATE TO User_ForServerPermissions
--GRANT insert on object::AdminDB.dbo.RMSDDLTracker TO User_ForServerPermissions



use AdminDB
create user User_ForServerPermissions FROM CERTIFICATE Certi_ForServerPermissions
grant execute on object::dbo.p_RMSInsertDDL to User_ForServerPermissions
revoke execute on object::dbo.TestCreditRatingSP to User_ForServerPermissions
revoke execute on object::dbo.sp_WhoIsActive to User_ForServerPermissions


revoke execute on object::dbo.TestCreditRatingSP to jmartin

grant insert, select on object::dbo.RMSDDLTracker to User_ForServerPermissions

exec dbo.TestCreditRatingSP

create role InsertDDL
grant execute on object::dbo.p_RMSInsertDDL to InsertDDL

drop user User_ForServerPermissions without login

use UserDB
create user testbello for login testbello
--alter user testbello with login = testbello
grant select, alter on object::messages to testbello

select * from dbo.RMSDDLTracker

--know the execution context
select * from sys.sysusers
select * from sys.user_token
select * from sys.login_token


exec as login = 'jmartin'
exec dbo.TestCreditRatingSP
--select * from fn_my_permissions(null,'database')
--union all
--select * from fn_my_permissions(null,'server')
revert; -- DON'T MISS THIS


--**7 please clean after yourself
DROP LOGIN User_ForServerPermissions
use master 
DROP CERTIFICATE Certi_ForServerPermissions
use AdminDB
drop signature FROM dbo.p_RMSInsertDDL BY  CERTIFICATE Certi_ForServerPermissions
drop signature FROM dbo.sp_WhoIsActive BY  CERTIFICATE Certi_ForServerPermissions
drop signature FROM dbo.RMSDDLTracker BY  CERTIFICATE Certi_ForServerPermissions
drop signature FROM dbo.TestCreditRatingSP BY  CERTIFICATE Certi_ForServerPermissions

DROP CERTIFICATE Certi_ForServerPermissions
--drop user if exists testbello -- if exists IN tsql in version 2016 and up
--DROP PROC IF EXISTS dbo.sp_WhoIsActive

--find the entities used by your certificat
SELECT SCHEMA_NAME(so.[schema_id]) AS [SchemaName],
       so.[name] AS [ObjectName],
       so.[type_desc] AS [ObjectType],
       ---
       scp.crypt_type_desc AS [SignatureType],
       ISNULL(sc.[name], sak.[name]) AS [CertOrAsymKeyName],
       ---
       scp.thumbprint
FROM sys.crypt_properties scp
INNER JOIN sys.objects so
        ON so.[object_id] = scp.[major_id]
LEFT JOIN sys.certificates sc
        ON sc.thumbprint = scp.thumbprint
LEFT JOIN sys.asymmetric_keys sak
        ON sak.thumbprint = scp.thumbprint
WHERE   
--so.[type] <> 'U'
--AND 
ISNULL(sc.[name], sak.[name]) = 'Certi_ForServerPermissions'
ORDER BY [SchemaName], [ObjectType], [ObjectName], [CertOrAsymKeyName];

SELECT quotename(s.name) + '.' + quotename(o.name) AS Module,
       c.name AS Cert, c.subject, dp.name AS [Username], cp.*
FROM   sys.crypt_properties cp
JOIN   sys.certificates c ON cp.thumbprint = c.thumbprint
LEFT   JOIN sys.database_principals dp ON c.sid = dp.sid
JOIN   sys.objects o ON cp.major_id = o.object_id
JOIN   sys.schemas s ON o.schema_id = s.schema_id


--exec AdminDB.dbo.sp_WhoIsActive
--select * from Messages
--begin tran
--alter table Messages drop column itsdate
--rollback tran
--alter table Messages drop  ct_date
--alter table Messages add  ct_date constraint 

--exec AdminDB.dbo.TestCreditRatingSP


-- SELECT SYSTEM_USER 'system Login'  
--   , USER AS 'Database Login'  
--   , NAME AS 'Context'  
--   , TYPE  
--   , USAGE   
--   FROM sys.user_token 


--   select * from RMSDDLTracker


use UserDB
create role roleInsertDDL

grant execute on object::dbo.p_RMSInsertDDL to roleInsertDDL

exec sp_addrolemember roleInsertDDL, DevStoredProc
exec sp_addrolemember DevStoredProc, [cross]

--use AdminDB
--drop role roleInsertDDL
--revoke insert on object::dbo.RMSDDLTracker to roleInsertDDL
