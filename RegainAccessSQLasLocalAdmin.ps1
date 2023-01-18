# https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/connect-to-sql-server-when-system-administrators-are-locked-out?view=sql-server-ver16
# run this after replacing the 3 following variables
$service_name = "MSSQLSERVER"
$sql_server_instance = "mih-testInstance"
$login_to_be_granted_access = "[mih-test\mbello]"

#Stop SQL Server service
net stop $service_name

# start your SQL Server instance in a single user mode and only allow SQLCMD.exe to connect 
net start $service_name /f /mSQLCMD

sqlcmd.exe -E -S $sql_server_instance -Q "CREATE LOGIN $login_to_be_granted_access FROM WINDOWS; ALTER SERVER ROLE sysadmin ADD MEMBER $login_to_be_granted_access; "

#Stop and restart your SQL Server instance in multi-user mode
net stop $service_name
net start $service_name