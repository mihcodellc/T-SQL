Grant Permissions to Non-DBAs
https://www.brentozar.com/askbrent/

USE master;
GO
CREATE CERTIFICATE sp_BlitzFirst_cert
ENCRYPTION BY PASSWORD = '5OClockSomewhere'
WITH SUBJECT = 'Certificate for sp_BlitzFirst',
START_DATE = '20130711', EXPIRY_DATE = '21000101';
GO
CREATE LOGIN sp_BlitzFirst_login FROM CERTIFICATE sp_BlitzFirst_cert;
GO
CREATE USER sp_BlitzFirst_login FROM CERTIFICATE sp_BlitzFirst_cert;
GO
GRANT EXECUTE ON dbo.sp_BlitzFirst TO sp_BlitzFirst_login;
GO
GRANT CONTROL SERVER TO sp_BlitzFirst_login;
GO
ADD SIGNATURE TO sp_BlitzFirst BY CERTIFICATE sp_BlitzFirst_cert
WITH PASSWORD = '5OClockSomewhere';
GO
GRANT EXECUTE ON dbo.sp_BlitzFirst TO [public];
GO


ADD SIGNATURE TO sp_BlitzFirst BY CERTIFICATE sp_BlitzFirst_cert
WITH PASSWORD = 'Get lucky';
GO
GRANT EXECUTE ON dbo.sp_BlitzFirst TO [public];
GO
