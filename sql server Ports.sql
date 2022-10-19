https://www.codeproject.com/Articles/1160147/SCRIPT-Open-ports-in-Windows-Firewall-for-SQL-Serv#:~:text=As%20system%20administrator%20%28on%20the%20machine%20with%20SQL,and%20enter%20the%20list%20of%20ports%20to%20open.

SQL Server Ports List
Here is a list of ports and the component addressed by it that we will be opening:

135 – SQL Debugger and RPC port – if you plan to remote debug stored procedures, etc.
1433 – Database engine – both application and management studio connectivity
1434 – “Administration Connection” or SQL Browser – management studio connectivity
2383 – Analysis Services – both application and management studio connectivity
2382 – SQL Server Browser – required for management studio
4022 – Service Broker – only if you use SQL Server Service Broker

open the port for SQL server
C:\> NETSH advFirewall firewall add rule name="Allow: Inbound: TCP: SQL Server Services" dir=in action=allow protocol=TCP localport=1433,1434,2382


http://www.sql2developers.com/2014/09/how-to-check-port-is-open-in-sql-server.html#:~:text=How%20to%20check%20the%20port%20is%20open%20in,search%20for%20the%20text%20%22Server%20is%20listening%20on%22.

***check open port 
--in powershell
test-netconnection asp-sql003.rms-asp.com -p 1433 -- https://phoenixnap.com/kb/ping-specific-port#:~:text=Ping%20a%20Specific%20Port%20Using%20Telnet%201%201.,Ctrl%20%2B%20%5D%20and%20run%20the%20q%20command.

--search using xp_readErrorLog
DECLARE @logFileType SMALLINT= 1;
DECLARE @start DATETIME;
DECLARE @end DATETIME;
DECLARE @logno INT= 0;
SET @start = dateadd(dd,-7,GETDATE())  ; -- between @date2  and  @date1
SET @end = dateadd(dd,1,GETDATE())  --'2021-11-07 09:00:00.000';
DECLARE @searchString1 NVARCHAR(256)= 'fail';
DECLARE @searchString2 NVARCHAR(256)= 'error';
DECLARE @searchString3 NVARCHAR(256)= 'warning';
DECLARE @searchString4 NVARCHAR(256)= 'Server is listening on';

select  @start, @end

EXEC master.dbo.xp_readerrorlog 
     @logno, 
     @logFileType, 
     null, 
     @searchString4, --warning
     @start, 
     @end;