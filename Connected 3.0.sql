-- code error Timeout expired. The timeout period elapsed 
-- prior to obtaining a connection from the pool. This may have occurred because all pooled connections were in use and max pool size was reached.
-- https://sqlperformance.com/2017/07/sql-performance/find-database-connection-leaks

  
--report on deadlock
-- https://www.mssqltips.com/sqlservertip/6430/monitor-deadlocks-in-sql-server-with-systemhealth-extended-events/

set transaction isolation level read uncommitted
set nocount on

select 'type of connection to this server'
SELECT distinct auth_scheme FROM sys.dm_exec_connections

--==============================================================================
-- See who is connected to the database.
-- Analyse what each spid is doing, reads and writes.
-- If safe you can copy and paste the killcommand - last column.
-- Marcelo Miorelli
-- 18-july-2017 - London (UK)
-- Tested on SQL Server 2016.
-- it run on current database; remove this part if looking for all dbs
-- Complement exec sp_WhoIsActive
--==============================================================================
select 'who is connected : Analyse what each spid is doing, reads and writes'
SELECT
	  DATEDIFF(MINUTE,sdes.last_request_end_time,sdes.last_request_start_time) 'elapse_time in minutes'
    ,sdes.last_request_start_time
    ,sdes.last_request_end_time
    ,sdes.session_id
    ,sdes.host_name 
    ,sdes.program_name
    ,sdes.login_name
    ,db_name(sdes.database_id) DatabaseName
    ,sdes.status
    ,sdest.Query
    ,sdest.text
    ,sdec.num_reads
    ,sdec.num_writes
    ,sdec.last_read
    ,sdec.last_write
    ,sdes.reads
    ,sdes.logical_reads
    ,sdes.writes
    ,KillCommand  = 'Kill '+ CAST(sdes.session_id  AS VARCHAR) + ' WITH STATUSONLY ' --WITH STATUSONLY clause provides progress reports, the time remaining until the blocking is resolved
    ,sdes.login_time
    ,sdes.last_request_start_time
    ,sdes.last_request_end_time
    ,sdes.is_user_process
    ,sdest.ObjName
    ,sdes.client_interface_name
    ,sdes.nt_domain
    ,sdes.nt_user_name 
    ,sdec.client_net_address
    ,sdec.local_net_address
FROM sys.dm_exec_sessions AS sdes

INNER JOIN sys.dm_exec_connections AS sdec
        ON sdec.session_id = sdes.session_id

CROSS APPLY (

    SELECT DB_NAME(dbid) AS DatabaseName, OBJECT_NAME(objectid) AS ObjName, dbid ,
			COALESCE(
										(SELECT TEXT AS [processing-instruction(definition)] FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle) FOR XML PATH('')), '') AS Query, 
			text

    FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle)

) sdest
WHERE sdes.session_id <> @@SPID --and sdes.last_request_end_time < DATEADD(hh,-12,getdate())
  --AND sdest.DatabaseName in('db1', 'db2', ...)-- and sdest.dbid IS NOT NULL
ORDER BY  sdes.last_request_start_time DESC, sdes.session_id

---- maximum number of simultaneous user connections allowed
--SELECT @@MAX_CONNECTIONS AS 'Max Connections';  

--kill 1588
 select 'sessions blocking other, active queries & sql text'
 ;WITH cteBL (session_id, blocking_these) AS 
(SELECT s.session_id, blocking_these = x.blocking_these FROM sys.dm_exec_sessions s 
CROSS APPLY    (SELECT isnull(convert(varchar(6), er.session_id),'') + ', '  
                FROM sys.dm_exec_requests as er
                WHERE er.blocking_session_id = isnull(s.session_id ,0)
                AND er.blocking_session_id <> 0
                FOR XML PATH('') ) AS x (blocking_these)
)
SELECT bl.session_id, blocked_by = r.blocking_session_id, bl.blocking_these
, batch_text = t.text, input_buffer = ib.event_info,sdec.client_net_address, sdec.local_net_address,s.host_name, *
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_connections AS sdec  ON sdec.session_id = s.session_id
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
INNER JOIN cteBL as bl on s.session_id = bl.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
WHERE blocking_these is not null or r.blocking_session_id > 0
ORDER BY len(bl.blocking_these) desc, r.blocking_session_id desc, r.session_id;

-- don't run on heavy load
--select  'Query to return active locks and the duration of the locks being held'
--SELECT  Locks.request_session_id AS SessionID ,
--        Obj.Name AS LockedObjectName ,
--        COUNT(*) AS Locks, ExeSess.host_name, ExeSess.program_name,DATEDIFF(second, ActTra.Transaction_begin_time, GETDATE()) AS Duration, ActTra.Transaction_begin_time  
--FROM    sys.dm_tran_locks Locks
--        JOIN sys.partitions Parti ON Parti.hobt_id = Locks.resource_associated_entity_id
--        JOIN sys.objects Obj ON Obj.object_id = Parti.object_id
--        JOIN sys.dm_exec_sessions ExeSess ON ExeSess.session_id = Locks.request_session_id
--        JOIN sys.dm_tran_session_transactions TranSess ON ExeSess.session_id = TranSess.session_id
--        JOIN sys.dm_tran_active_transactions ActTra ON TranSess.transaction_id = ActTra.transaction_id
--WHERE   resource_database_id = DB_ID()
--	   --db_name(l.resource_database_id) in('MedRx', 'RMSOCR', 'MedRxAnalytics', 'Billing')
--        AND Obj.Type = 'U'
--GROUP BY ActTra.Transaction_begin_time ,
--        Locks.request_session_id ,
--        Obj.Name, ExeSess.host_name, ExeSess.program_name

SELECT t1.resource_type AS [lock type], DB_NAME(resource_database_id) AS [database],
t1.resource_associated_entity_id AS [blk object],t1.request_mode AS [lock req],  -- lock requested
t1.request_session_id AS [waiter sid], t2.wait_duration_ms AS [wait time],       -- spid of waiter  
(SELECT [text] FROM sys.dm_exec_requests AS r WITH (NOLOCK)                      -- get sql for waiter
CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) 
WHERE r.session_id = t1.request_session_id) AS [waiter_batch],
(SELECT SUBSTRING(qt.[text],r.statement_start_offset/2, 
    (CASE WHEN r.statement_end_offset = -1 
    THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
    ELSE r.statement_end_offset END - r.statement_start_offset)/2) 
FROM sys.dm_exec_requests AS r WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) AS qt
WHERE r.session_id = t1.request_session_id) AS [waiter_stmt],					-- statement blocked
t2.blocking_session_id AS [blocker sid],										-- spid of blocker
(SELECT [text] FROM sys.sysprocesses AS p										-- get sql for blocker
CROSS APPLY sys.dm_exec_sql_text(p.[sql_handle]) 
WHERE p.spid = t2.blocking_session_id) AS [blocker_batch]
FROM sys.dm_tran_locks AS t1 WITH (NOLOCK)
INNER JOIN sys.dm_os_waiting_tasks AS t2 WITH (NOLOCK)
ON t1.lock_owner_address = t2.resource_address OPTION (RECOMPILE);


/*
-- https://github.com/amachanic/sp_whoisactive

-- open tran, cpu,memory used
*/
exec [RmsAdmin].dbo.sp_WhoIsActive  
		    @show_own_spid = 0
		  , @get_task_info =2 /* 1 ie lightweight. task-based metrics : current wait stats, physical I/O, context switches, and blocker information*/
		  , @get_avg_time = 1
		  , @get_locks = 1
		  --, @get_transaction_info = 1
		  --, @delta_interval = 5 -- Interval in seconds to wait before doing the second data pull
		  , @find_block_leaders =1
		  , @show_sleeping_spids = 0 --1 sleeping with open transaction
		  --, @get_plans = 1 
		  , @sort_order = '[CPU] desc, [blocked_session_count] desc,[Used_Memory] desc, [open_tran_count] desc' 
		  --, @destination_table = ''
		  --, @output_column_list = '[col1][col2]...'



if (select IS_SRVROLEMEMBER('sysadmin','mbello') IsMemberOfSysAdmin) = 1
begin
    select 'open transaction' 
    dbcc opentran
end


select 'analyze locks'
select db_name(l.resource_database_id),s.host_name,
         --s.host_process_id,
         s.program_name
	    , s.session_id
	    , l.request_status
	    , l.request_mode
	    , l.request_owner_type
	    , CASE WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id) else '' end as objectName 
	    , l.resource_type
	    , l.resource_subtype
from sys.dm_tran_locks l
join sys.dm_exec_sessions s on request_session_id = s.session_id

where s.host_process_id > 0 AND resource_type = 'OBJECT'
and db_name(l.resource_database_id) = db_name() and s.session_id <> @@SPID
order by objectName, request_mode --s.host_name-- request_mode

--select 'find lock esclation on a table '
--SELECT CASE WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id) else OBJECT_NAME(b.OBJECT_ID) end ObjectName, 
--resource_type, request_mode, resource_description, request_session_id, partition_id, request_status, request_type 
----into #mylock
--FROM sys.dm_tran_locks a
--LEFT JOIN sys.partitions b ON b.hobt_id = a.resource_associated_entity_id
--WHERE resource_type <> 'DATABASE' AND db_name(resource_database_id)  in('MedRx', 'RMSOCR', 'MedRxAnalytics', 'Billing')--DB_ID() -- and request_session_id = @@spid;

--Determine Which Queries Are Holding Locks using extend events
--https://docs.microsoft.com/en-us/sql/relational-databases/extended-events/determine-which-queries-are-holding-locks?view=sql-server-ver15




-- sleeping session can be an issue, check the query used and closed them, of no longer needed close or kill it
-- there are using the TempDB
select 'sessions running but asleep'
  select datediff(minute, s.last_request_end_time, getdate()) as minutes_asleep,
         s.session_id,
         db_name(s.database_id) as database_name,
         s.host_name,
         s.host_process_id,
         t.text as last_sql,
         s.program_name, s.status
    from sys.dm_exec_connections c
    join sys.dm_exec_sessions s
         on c.session_id = s.session_id
   cross apply sys.dm_exec_sql_text(c.most_recent_sql_handle) t
   where s.is_user_process = 1 and datediff(minute, s.last_request_end_time, getdate()) > 0
         and s.status <> 'sleeping'
 order by minutes_asleep desc

----query
--select q.text, st.execution_count, st.last_logical_reads, st.last_execution_time, st.last_logical_writes, last_physical_reads from sys.dm_exec_query_stats st
--cross apply sys.dm_exec_sql_text(st.sql_handle) q

----sp
--select q.text, st.execution_count, st.last_logical_reads, st.last_execution_time, st.last_logical_writes, last_physical_reads from sys.dm_exec_procedure_stats st
--cross apply sys.dm_exec_sql_text (st.sql_handle) q

----sp
--select q.query_plan, st.execution_count, st.last_logical_reads, st.last_execution_time, st.last_logical_writes, last_physical_reads from sys.dm_exec_procedure_stats st
--cross apply sys.dm_exec_query_plan(st.sql_handle) q

----exec sp_who 'active';  
--select ' active'
-- select spid , ecid, status  
--              ,loginame=rtrim(loginame)  
--       ,hostname ,blk=convert(char(5),blocked)  
--       ,dbname = case  
--      when dbid = 0 then null  
--      when dbid <> 0 then db_name(dbid)  
--     end  
--    ,cmd  
--    ,request_id  
-- from  sys.sysprocesses  
-- where upper(cmd) <> 'AWAITING COMMAND' -- ACTIVE excludes sessions that are waiting for the next command from the user.
-- and spid  <> @@SPID and status <> 'sleeping'   and loginame <> 'sa'
-- and db_name(dbid) in ('MedRx', 'RMSOCR', 'MedRxAnalytics', 'Billing')
-- order by status
 




---- connection and session info
--SELECT conn.session_id, sess.host_name, sess.program_name,
--    sess.nt_domain, sess.login_name, conn.connect_time, sess.last_request_end_time 
--FROM sys.dm_exec_sessions AS sess
--JOIN sys.dm_exec_connections AS conn
--   ON sess.session_id = conn.session_id;

-- select * from sys.dm_exec_connections

-- --last statement that was submitted by a session
--    DBCC INPUTBUFFER(<session_id>) -- select 1 from  fn_builtin_permissions('server') where permission_name like '%VIEW SERVER STATE%'
--    --OR
--    SELECT * FROM sys.dm_exec_input_buffer (66,0);
--DBCC sqlperf(logspace) -- -- select 1 from  fn_builtin_permissions('server') where permission_name like '%VIEW SERVER STATE%'
--DBCC USEROPTIONS --public

--select open_transaction_count, status, * FROM sys.dm_exec_sessions


 --set transaction isolation level read uncommitted



---- session by host -- look at connections per process per database
--select count(*) as sessions,
--         s.host_name,
--         s.host_process_id,
--         s.program_name,
--         db_name(s.database_id) as database_name
--   from sys.dm_exec_sessions s
--   where is_user_process = 1 --and host_name = 'DEVELOPER15'
--   group by host_name, host_process_id, program_name, database_id
--   order by count(*) desc;


--GO
--SELECT 
--    DB_NAME(dbid) as DBName, dbid,
--    (dbid) as NumberOfConnections,
--    loginame as LoginName, status
--FROM  sys.sysprocesses
----WHERE 
--    --dbid =6 
--GROUP BY dbid, loginame, status

---- kill connection to dbBello
--SELECT status,database_id, DB_NAME(database_id) DBNAME,
--'use master; Kill ' + convert(char(4), session_id) as Command
--FROM sys.dm_exec_sessions WHERE DB_NAME(database_id) = 'dbBello' AND database_id>0

----drop database if exists dbBello
----create database dbBello WITH TRUSTWORTHY ON
----ALTER AUTHORIZATION ON DATABASE::dbBello TO sa; --EXEC sp_changedbowner 'sa' deprecated

---- drop an user from all db on the instance
--exec sp_MSforeachdb N'use [?] ; 
--IF  EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''testbello'')
--    DROP USER [testbello];'

--USER HAS TO BE IN THE DATBASE TOALLOW HIM TO DO ANYTHING IN IT




select 'Get a count of SQL connections by IP address (Query 39) (Connection Counts by IP Address)' 
SELECT ec.client_net_address, es.[program_name], es.[host_name], es.login_name, 
COUNT(ec.session_id) AS [connection count] 
FROM sys.dm_exec_sessions AS es WITH (NOLOCK) 
INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK) 
ON es.session_id = ec.session_id 
GROUP BY ec.client_net_address, es.[program_name], es.[host_name], es.login_name  
ORDER BY [connection count] desc--ec.client_net_address, es.[program_name] OPTION (RECOMPILE);

SELECT @@SERVERNAME serverName, 
COUNT(ec.session_id) AS [connection count] 
FROM sys.dm_exec_sessions AS es WITH (NOLOCK) 
INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK) 
ON es.session_id = ec.session_id 


select 'Get server Pressure' 
exec RmsAdmin.dbo.sp_PressureDetector  --@help = 1


-- Get CPU utilization by database (Query 34) (CPU Usage by Database)
;WITH DB_CPU_Stats
AS
(SELECT pa.DatabaseID, DB_Name(pa.DatabaseID) AS [Database Name], SUM(qs.total_worker_time/1000) AS [CPU_Time_Ms]
 FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS pa
 GROUP BY DatabaseID)
SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [CPU Rank],
       [Database Name], [CPU_Time_Ms] AS [CPU Time (ms)], 
       CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPU Percent]
FROM DB_CPU_Stats
WHERE DatabaseID <> 32767 -- ResourceDB
ORDER BY [CPU Rank] OPTION (RECOMPILE);
------

-- Helps determine which database is using the most CPU resources on the instance
-- Note: This only reflects CPU usage from the currently cached query plans


-- Get I/O utilization by database (Query 35) (IO Usage By Database)
WITH Aggregate_IO_Statistics
AS (SELECT DB_NAME(database_id) AS [Database Name],
    CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576 AS DECIMAL(12, 2)) AS [ioTotalMB],
    CAST(SUM(num_of_bytes_read ) / 1048576 AS DECIMAL(12, 2)) AS [ioReadMB],
    CAST(SUM(num_of_bytes_written) / 1048576 AS DECIMAL(12, 2)) AS [ioWriteMB]
    FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS [DM_IO_STATS]
    GROUP BY database_id)
SELECT ROW_NUMBER() OVER (ORDER BY ioTotalMB DESC) AS [I/O Rank],
        [Database Name], ioTotalMB AS [Total I/O (MB)],
        CAST(ioTotalMB / SUM(ioTotalMB) OVER () * 100.0 AS DECIMAL(5, 2)) AS [Total I/O %],
        ioReadMB AS [Read I/O (MB)], 
		CAST(ioReadMB / SUM(ioReadMB) OVER () * 100.0 AS DECIMAL(5, 2)) AS [Read I/O %],
        ioWriteMB AS [Write I/O (MB)], 
		case when ioWriteMB> 0 then CAST(ioWriteMB / SUM(ioWriteMB) OVER () * 100.0 AS DECIMAL(5, 2))
			else 0 end AS [Write I/O %]
FROM Aggregate_IO_Statistics
ORDER BY [I/O Rank] OPTION (RECOMPILE);
------
--kill 501