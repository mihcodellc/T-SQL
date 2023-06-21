--some credits to http://whoisactive.com/docs/28_access/ and https://www.sommarskog.se/grantperm.html#serverlevel
-- https://docs.microsoft.com/en-us/sql/t-sql/statements/create-certificate-transact-sql?view=sql-server-ver15
--sql server 2017 compati 140


--**1 Create the certificate in the user database.
use DBA_DB
go
CREATE CERTIFICATE Certi_ForServerPermissions AUTHORIZATION dbo
ENCRYPTION BY PASSWORD = 'P@ssword!P@mizi'
WITH SUBJECT = 'For Non Admin',
EXPIRY_DATE = '9999-12-31'
GO

--**2 Sign the procedure. or all objects to secure here
use DBA_DB
go
ADD SIGNATURE TO dbo.sp_WhoIsActive
BY CERTIFICATE Certi_ForServerPermissions
WITH PASSWORD = 'P@ssword!P@mizi'
GO

--**3 Drop the private key.
--	   (safe to avoid anyone to use the pass to sign others thing) because of this, 
--	   drop the signature and the certificate and create a new certificate then resign the proc after alter the proc
ALTER CERTIFICATE Certi_ForServerPermissions REMOVE PRIVATE KEY

--**4 Copy the certificate to master. run all in one till --**5
use DBA_DB
GO
DECLARE @public_key varbinary(MAX), @sql nvarchar(MAX);

SET @public_key = certencoded(cert_id('Certi_ForServerPermissions'));
SET @sql = 'CREATE CERTIFICATE Certi_ForServerPermissions FROM BINARY = ' + convert(varchar(MAX), @public_key, 1);

USE master
--PRINT 
EXEC(@sql)


--**5 Create a login from the certificate.
CREATE LOGIN User_ForServerPermissions FROM CERTIFICATE Certi_ForServerPermissions


--**6 Grant the certificate login the required permissions.
GRANT VIEW SERVER STATE TO User_ForServerPermissions

--**6-2 grant the priv to a role for the object controlled by the certificat 
GRANT EXECUTE ON OBJECT::sp_WhoIsActive TO devops_new

--**7 please clean after yourself
DROP LOGIN User_ForServerPermissions
use master 
DROP CERTIFICATE Certi_ForServerPermissions
use DBA_DB
drop signature FROM dbo.sp_WhoIsActive BY  CERTIFICATE Certi_ForServerPermissions
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

-- objects with certificat name in the current database
SELECT quotename(s.name) + '.' + quotename(o.name) AS Module,
       c.name AS Cert, c.subject, dp.name AS [Username], cp.*
FROM   sys.crypt_properties cp
JOIN   sys.certificates c ON cp.thumbprint = c.thumbprint
LEFT   JOIN sys.database_principals dp ON c.sid = dp.sid
JOIN   sys.objects o ON cp.major_id = o.object_id
JOIN   sys.schemas s ON o.schema_id = s.schema_id



-- draft Certificate permission at server level.sql
