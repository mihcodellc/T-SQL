-- more CPU cumulative: dm_exec_query_stats.total_worker_time

select s.*,p.*
from (select top 10 plan_handle, total_worker_time 
from sys.dm_exec_query_stats)s
cross apply sys.dm_exec_sql_text(s.plan_handle)p order by total_worker_time desc

-- Natively Compiled Stored Procedures with SQL Server 2014 : in C > machine language
--https://www.databasejournal.com/features/mssql/natively-compiled-stored-procedures-with-sql-server-2014.html#:~:text=SQL%20Server%20is%20an%20interpretive,first%20time%20it%20is%20executed.&text=A%20natively%20compiled%20stored%20procedure%20is%20compiled%20when%20it%20is,than%20when%20it%20is%20executed.
select object_id as lookID, * from sys.sql_modules where uses_native_compilation = 1

-- locking information
exec sp_lock -- sp_lock <SPID> --Process ID, Database Engine session ID number from sys.dm_exec_sessions

select * from sys.dm_tran_locks where resource_type <>'database'