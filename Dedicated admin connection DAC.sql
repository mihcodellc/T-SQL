-- if need to get around apps for your queries: "Connected -Get around Apps.sql"


-- https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/diagnostic-connection-for-database-administrators?view=sql-server-ver15
--To establish a DAC from SQL Server Management Studio

--Disconnect all connections to the related SQL Server instance, including the Object Explorer and all open query windows.
--From the menu select File > New > Database Engine Query
--From the connection dialog box in the Server Name field, enter admin:<server_name> if using the default instance or admin:<server_name>\<instance_name> if using a named instance.

OR simple, restart service then try to beat other by connect first(or refresh if you already connect) in management studio
	then run your statement or ALTER DATABASE Medrx SET MULTI_USER GO;
--from "RegainAccessSQLasLocalAdmin.ps1"
--# https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/connect-to-sql-server-when-system-administrators-are-locked-out?view=sql-server-ver16
--# run this after replacing the 3 following variables
$service_name = "MSSQLSERVER"
$sql_server_instance = "ASP-ORBOSQL"
$login_to_be_granted_access = "[rms-asp\mbello]"

--#Stop SQL Server service
net stop $service_name

--# start your SQL Server instance in a single user mode and only allow SQLCMD.exe to connect 
net start $service_name /f /mSQLCMD
--run a query to fix the issue: set the DB to  MULTI_USER
--sqlcmd.exe -E -S $sql_server_instance -Q "CREATE LOGIN $login_to_be_granted_access FROM WINDOWS; ALTER SERVER ROLE sysadmin ADD MEMBER $login_to_be_granted_access; "
sqlcmd.exe -E -S $sql_server_instance -Q "ALTER DATABASE Medrx SET MULTI_USER GO;	 "



#Stop and restart your SQL Server instance in multi-user mode
net stop $service_name
net start $service_name

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
