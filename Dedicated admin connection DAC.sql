-- https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/diagnostic-connection-for-database-administrators?view=sql-server-ver15
--To establish a DAC from SQL Server Management Studio

--Disconnect all connections to the related SQL Server instance, including the Object Explorer and all open query windows.
--From the menu select File > New > Database Engine Query
--From the connection dialog box in the Server Name field, enter admin:<server_name> if using the default instance or admin:<server_name>\<instance_name> if using a named instance.

--enable
sp_configure 'remote admin connections', 1;  
GO  
RECONFIGURE;  
GO  


-- Who’s using the Dedicated Admin Connection.
-- https://www.brentozar.com/archive/2011/08/dedicated-admin-connection-why-want-when-need-how-tell-whos-using/
SELECT CASE
		 WHEN ses.session_id = @@SPID THEN 'It''s me! ' ELSE ''
	  END + COALESCE(ses.login_name, '???') AS WhosGotTheDAC, ses.session_id, ses.login_time, ses.STATUS, ses.original_login_name
FROM sys.endpoints AS en
JOIN sys.dm_exec_sessions ses ON en.endpoint_id = ses.endpoint_id
WHERE en.name = 'Dedicated Admin Connection';