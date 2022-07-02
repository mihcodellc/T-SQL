-- **Transparent Database Encrytion - TDE

USE master;
GO
--master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Passw0rd';
--DROP MASTER KEY  
GO
--certificate protected the master key

use master
CREATE CERTIFICATE ServerCertificate WITH SUBJECT = 'Master Certificate';
-- DROP CERTIFICATE ServerCertificate  
go

USE AdventureWorks2016;
-- DB Encryption Key (DEK) for a DB
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE ServerCertificate;
go

USE AdventureWorks2016;
-- activate on DB
ALTER DATABASE AdventureWorks2016
SET ENCRYPTION ON;
go

USE master;
-- Backup the certificate to access the DB later on
BACKUP CERTIFICATE ServerCertificate
TO FILE = 'D:\DBA\ServerCertExport'
WITH PRIVATE KEY
(
FILE = 'D:\DBA\PrivateKeyFile',
ENCRYPTION BY PASSWORD = 'Passw0rd'
);
GO

------****encrypt a column 
--create master key ON DB LEVEL
use  AdventureWorks2016; 
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Passw0rd';
--DROP MASTER KEY
GO
--create certificate ON DB LEVEL
CREATE CERTIFICATE DBCertificate WITH SUBJECT = 'Database Certificate';
-- DROP CERTIFICATE ServerCertificate 
go

--create permanent key 'key' VS '#key'
CREATE SYMMETRIC KEY KeyForAcolumn WITH ALGORITHM = AES_256  
ENCRYPTION BY CERTIFICATE DBCertificate; 


-- Create a column in which to store the encrypted data. 
ALTER TABLE HumanResources.Employee  
    ADD EncryptedNationalIDNumber varbinary(128);   
--ALTER TABLE HumanResources.Employee drop column EncryptedNationalIDNumber
GO  

-- Verify the encryption.  
-- First, open the symmetric key with which to decrypt the data. 
OPEN SYMMETRIC KEY KeyForAcolumn  
      DECRYPTION BY CERTIFICATE DBCertificate;  
-- CLOSE SYMMETRIC KEY KeyForAcolumn;  
-- DROP SYMMETRIC KEY KeyForAcolumn; 



UPDATE HumanResources.Employee  
SET EncryptedNationalIDNumber = EncryptByKey(Key_GUID('KeyForAcolumn'), NationalIDNumber);  
GO  

-- Now list the original ID, the encrypted ID, and the   
-- decrypted ciphertext. If the decryption worked, the original  
-- and the decrypted ID will match.  
SELECT NationalIDNumber, EncryptByKey(Key_GUID('KeyForAcolumn'), NationalIDNumber) EncryptedNationalIDNumber
, CONVERT(nvarchar, DecryptByKey(EncryptByKey(Key_GUID('KeyForAcolumn'), NationalIDNumber)))   AS 'Decrypted ID Number' 
--, EncryptedNationalIDNumber 
    FROM HumanResources.Employee;  
GO  