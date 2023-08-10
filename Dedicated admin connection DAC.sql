-- https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/diagnostic-connection-for-database-administrators?view=sql-server-ver15
--To establish a DAC from SQL Server Management Studio

--Disconnect all connections to the related SQL Server instance, including the Object Explorer and all open query windows.
--From the menu select File > New > Database Engine Query
--From the connection dialog box in the Server Name field, enter admin:<server_name> if using the default instance or admin:<server_name>\<instance_name> if using a named instance.

OR simple, restart service then try to beat other by connect first(or refresh if you already connect) in management studio
	then run your statement or ALTER DATABASE Medrx SET MULTI_USER GO;

--enable
sp_configure 'remote admin connections', 1;  
GO  
RECONFIGURE;  
GO  


--login valid but default db not available -> login failed
-- with dbatools in powershell
$wincred = Get-Credential mbello
$sqlCn = Connect-DbaInstance -SqlInstance MyInstanceName -SqlCredential $wincred -Database master -TrustServerCertificate
Invoke-DbaQuery -SqlInstance $sqlCn -Query "ALTER LOGIN [mbello] WITH DEFAULT_DATABASE = master"


--use sqlcmd to connect to sql server
https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-start-utility?view=sql-server-ver16
https://learn.microsoft.com/en-us/powershell/module/sqlserver/invoke-sqlcmd?view=sqlserver-ps


-- Who’s using the Dedicated Admin Connection.
-- https://www.brentozar.com/archive/2011/08/dedicated-admin-connection-why-want-when-need-how-tell-whos-using/
SELECT CASE
		 WHEN ses.session_id = @@SPID THEN 'It''s me! ' ELSE ''
	  END + COALESCE(ses.login_name, '???') AS WhosGotTheDAC, ses.session_id, ses.login_time, ses.STATUS, ses.original_login_name
FROM sys.endpoints AS en
JOIN sys.dm_exec_sessions ses ON en.endpoint_id = ses.endpoint_id
WHERE en.name = 'Dedicated Admin Connection';
