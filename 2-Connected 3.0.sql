-- code error Timeout expired. The timeout period elapsed 
-- prior to obtaining a connection from the pool. This may have occurred because all pooled connections were in use and max pool size was reached.
-- https://sqlperformance.com/2017/07/sql-performance/find-database-connection-leaks
  
 
--report on deadlock
-- https://www.mssqltips.com/sqlservertip/6430/monitor-deadlocks-in-sql-server-with-systemhealth-extended-events/

set transaction isolation level read uncommitted
go
set nocount on
go

--kill 257  
  
select 'type of connection to this server'
SELECT distinct auth_scheme FROM sys.dm_exec_connections
SELECT * FROM sys.dm_exec_connections
where auth_scheme not in ('SQL','NTLM')

--SELECT sdec.auth_scheme
--    ,sdes.session_id
--    ,sdes.host_name 
--    ,sdes.program_name 
--    ,sdes.login_name 
--    ,sdes.client_interface_name
--    ,sdes.nt_domain
--    ,sdes.nt_user_name 
--    ,sdec.client_net_address
--    ,sdec.local_net_address FROM sys.dm_exec_connections sdec
--left join
--sys.dm_exec_sessions AS sdes ON sdec.session_id = sdes.session_id
--where sdec.auth_scheme not in ('SQL','NTLM')

  select '********************job Executing************************'
  ---- job Executing
exec msdb.dbo.sp_help_job @execution_status=1 --- running
--exec msdb.dbo.sp_help_job @job_name= 'OLA - DatabaseBackup - USER DB FULL then DBCC' 


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
	  DATEDIFF(MINUTE,sdes.last_request_start_time, sdes.last_request_end_time) 'elapse_time in minutes'
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
    ,sdec.client_tcp_port
    ,sdec.local_tcp_port
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
ORDER BY  1 desc,  sdes.session_id

---- maximum number of simultaneous user connections allowed
SELECT @@MAX_CONNECTIONS AS 'Max Connections';  


--Previous version commented out
select 'sessions blocking other, ACTIVE/executing(sys.dm_exec_requests) queries & sql text'
 ;WITH cteBL (session_id, blocking_these) AS 
(SELECT s.session_id, blocking_these = x.blocking_these FROM sys.dm_exec_sessions s 
CROSS APPLY    (SELECT isnull(convert(varchar(6), er.session_id),'') + ', '  
                FROM sys.dm_exec_requests as er
                WHERE er.blocking_session_id = isnull(s.session_id ,0)
                AND er.blocking_session_id <> 0
                FOR XML PATH('') ) AS x (blocking_these)
)
SELECT getdate() as RunAt, r.wait_type, r.wait_time / (1000.0) as WaitSec,  r.total_elapsed_time / (1000.0) 'ElapsSec', bl.session_id,r.cpu_time, r.reads, r.writes, r.logical_reads,
blocked_by = r.blocking_session_id, bl.blocking_these,s.login_name,substring(case when len(ib.event_info)> 0 then ib.event_info else '' end,0,2000) Query_involved,
s.[host_name],
COALESCE((
					SELECT REPLACE(program_name,Substring(program_name,30,34),'"'+j.name+'"') 
					FROM msdb.dbo.sysjobs j WHERE Substring(program_name,32,32) = CONVERT(char(32),CAST(j.job_id AS binary(16)),2)
					),s.[program_name])
as [program_name], 
substring(case when len(ib.event_info)> 0 then ib.event_info else '' end,0,2000) Query_involved,
batch_text = st.text,  r.scheduler_id, r.wait_resource, sdec.client_net_address, sdec.local_net_address, derp.query_plan, r.command,s.status --, r.sql_handle,
   -- r.plan_handle --, *
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_connections AS sdec  ON sdec.session_id = s.session_id
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
LEFT JOIN cteBL as bl on s.session_id = bl.session_id
--INNER JOIN cteBL as bl on s.session_id = bl.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) st
OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS derp
WHERE --s.session_id in (1865, 2890, 2030) --ib.event_info like '%LoaderState_Populate_byView_yearago%'--s.session_id != @@SPID  -- kill 2834, kill 2269 kill 772
 ( --blocking over 3min
		  (
			 (len(bl.blocking_these) > 0 OR r.blocking_session_id <> 0)-- blocked or blocking
			 and 
			 (
				r.total_elapsed_time / (1000.0)  > 1 -- 180=3*60
				or
				DATEDIFF(second, GETDATE(), r.start_time) > 1
			 )
		  )
	       or 
      --running over 20min
		(
		  r.total_elapsed_time / (1000.0)  > 10--1200=20*60 kill 2628
		  or
		  DATEDIFF(second, GETDATE(), r.start_time) > 1
		)  
	   )
 --AND (blocking_these is not null or r.blocking_session_id <> 0) -- only blocking	
--blocking_session_id / blocked_by: means
--NULL or equal to 0, the request isn't blocked, or the session information of the blocking session isn't available
---2 = The blocking resource is owned by an orphaned distributed transaction.
---3 = The blocking resource is owned by a deferred recovery transaction.
---4 = Session ID of the blocking latch owner couldn't be determined at this time because of internal latch state transitions.
---5 = Session ID of the blocking latch owner couldn't be determined because it isn't tracked for this latch type (for example, for an SH latch).
--ref https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-requests-transact-sql?view=sql-server-ver16
-- ***blocking the most
--ORDER BY len(bl.blocking_these) desc, r.blocking_session_id desc, r.session_id; -- ***blocking the most
-- ***waiting on the most
ORDER BY ElapsSec desc, waitsec desc,  len(bl.blocking_these) desc, r.blocking_session_id desc, r.session_id; -- ***waiting on the most
---- *** reading the most
--ORDER BY logical_reads desc, writes desc, ElapsSec desc, len(bl.blocking_these) desc, r.blocking_session_id desc, r.session_id; -- ***reading on the most
-- *** resource the most sollicited 
--ORDER BY r.wait_resource kill 2654
-- *** order by login 
--ORDER BY login_name


-- Understand and resolve SQL Server blocking problems
-- https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/understand-resolve-blocking
select 'identify the head of a multiple session blocking chain';
 --identify the head of a multiple session blocking chain, including the query text of the sessions 
 --involved in a blocking chain
 WITH cteHead ( session_id,request_id,wait_type,wait_resource,last_wait_type,is_user_process,request_cpu_time
,request_logical_reads,request_reads,request_writes,wait_time,blocking_session_id,memory_usage
,session_cpu_time,session_reads,session_writes,session_logical_reads
,percent_complete,est_completion_time,request_start_time,request_status,command
,plan_handle,sql_handle,statement_start_offset,statement_end_offset,most_recent_sql_handle
,session_status,group_id,query_hash,query_plan_hash) 
AS ( SELECT sess.session_id, req.request_id, LEFT (ISNULL (req.wait_type, ''), 50) AS 'wait_type'
    , LEFT (ISNULL (req.wait_resource, ''), 40) AS 'wait_resource', LEFT (req.last_wait_type, 50) AS 'last_wait_type'
    , sess.is_user_process, req.cpu_time AS 'request_cpu_time', req.logical_reads AS 'request_logical_reads'
    , req.reads AS 'request_reads', req.writes AS 'request_writes', req.wait_time, req.blocking_session_id,sess.memory_usage
    , sess.cpu_time AS 'session_cpu_time', sess.reads AS 'session_reads', sess.writes AS 'session_writes', sess.logical_reads AS 'session_logical_reads'
    , CONVERT (decimal(5,2), req.percent_complete) AS 'percent_complete', req.estimated_completion_time AS 'est_completion_time'
    , req.start_time AS 'request_start_time', LEFT (req.status, 15) AS 'request_status', req.command
    , req.plan_handle, req.[sql_handle], req.statement_start_offset, req.statement_end_offset, conn.most_recent_sql_handle
    , LEFT (sess.status, 15) AS 'session_status', sess.group_id, req.query_hash, req.query_plan_hash
    FROM sys.dm_exec_sessions AS sess
    LEFT OUTER JOIN sys.dm_exec_requests AS req ON sess.session_id = req.session_id
    LEFT OUTER JOIN sys.dm_exec_connections AS conn on conn.session_id = sess.session_id 
    )
, cteBlockingHierarchy (head_blocker_session_id, session_id, blocking_session_id, wait_type, wait_duration_ms,
wait_resource, statement_start_offset, statement_end_offset, plan_handle, sql_handle, most_recent_sql_handle, [Level])
AS ( SELECT head.session_id AS head_blocker_session_id, head.session_id AS session_id, head.blocking_session_id
    , head.wait_type, head.wait_time, head.wait_resource, head.statement_start_offset, head.statement_end_offset
    , head.plan_handle, head.sql_handle, head.most_recent_sql_handle, 0 AS [Level]
    FROM cteHead AS head
    WHERE (head.blocking_session_id IS NULL OR head.blocking_session_id = 0)
    AND head.session_id IN (SELECT DISTINCT blocking_session_id FROM cteHead WHERE blocking_session_id != 0)
    UNION ALL
    SELECT h.head_blocker_session_id, blocked.session_id, blocked.blocking_session_id, blocked.wait_type,
    blocked.wait_time, blocked.wait_resource, h.statement_start_offset, h.statement_end_offset,
    h.plan_handle, h.sql_handle, h.most_recent_sql_handle, [Level] + 1
    FROM cteHead AS blocked
    INNER JOIN cteBlockingHierarchy AS h ON h.session_id = blocked.blocking_session_id and h.session_id!=blocked.session_id --avoid infinite recursion for latch type of blocking
    WHERE h.wait_type COLLATE Latin1_General_BIN NOT IN ('EXCHANGE', 'CXPACKET') or h.wait_type is null
    )
SELECT bh.*, txt.text AS blocker_query_or_most_recent_query 
FROM cteBlockingHierarchy AS bh 
OUTER APPLY sys.dm_exec_sql_text (ISNULL ([sql_handle], most_recent_sql_handle)) AS txt;


--select 'track an IP'
-- ;WITH cteBL (session_id, blocking_these) AS 
--(SELECT s.session_id, blocking_these = x.blocking_these FROM sys.dm_exec_sessions s 
--CROSS APPLY    (SELECT isnull(convert(varchar(6), er.session_id),'') + ', '  
--                FROM sys.dm_exec_requests as er
--                WHERE er.blocking_session_id = isnull(s.session_id ,0)
--                AND er.blocking_session_id <> 0
--                FOR XML PATH('') ) AS x (blocking_these)
--)
--SELECT r.wait_time / (1000.0) as WaitSec, r.total_elapsed_time / (1000.0) 'ElapsSec', bl.session_id,
--blocked_by = r.blocking_session_id, bl.blocking_these,
--s.login_name,s.[host_name],s.[program_name], 
--substring(case when len(ib.event_info)> 0 then ib.event_info else '' end,0,300) Query_involved,
--batch_text = st.text, r.reads, r.writes, r.logical_reads, r.wait_type, r.wait_resource, sdec.client_net_address, sdec.local_net_address--, *
--FROM sys.dm_exec_sessions s
--right JOIN sys.dm_exec_connections AS sdec  ON sdec.session_id = s.session_id kill 2719
--LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
--left JOIN cteBL as bl on s.session_id = bl.session_id
--OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) st
--OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
--WHERE sdec.client_net_address in( '192.168.203.219')


----***https://www.sqlskills.com/blogs/paul/updated-sys-dm_os_waiting_tasks-script/

--SELECT
--    [owt].[session_id],
--    [owt].[exec_context_id],
--    [ot].[scheduler_id],
--    [owt].[wait_duration_ms],
--    [owt].[wait_type],
--    [owt].[blocking_session_id],
--    [owt].[resource_description],
--    CASE [owt].[wait_type]
--        WHEN N'CXPACKET' THEN
--            RIGHT ([owt].[resource_description],
--                CHARINDEX (N'=', REVERSE ([owt].[resource_description])) - 1)
--        ELSE NULL
--    END AS [Node ID],
--    --[es].[program_name],
--    [est].text,
--    [er].[database_id],
--    [eqp].[query_plan],
--    [er].[cpu_time]
--FROM sys.dm_os_waiting_tasks [owt]
--INNER JOIN sys.dm_os_tasks [ot] ON
--    [owt].[waiting_task_address] = [ot].[task_address]
--INNER JOIN sys.dm_exec_sessions [es] ON
--    [owt].[session_id] = [es].[session_id]
--INNER JOIN sys.dm_exec_requests [er] ON
--    [es].[session_id] = [er].[session_id]
--OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
--OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
--WHERE
--    [es].[is_user_process] = 1 and owt.session_id = ?
--ORDER BY
--    [owt].[session_id],
--    [owt].[exec_context_id];


select 'who lock my object using dm_tran_locks light'
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
WHERE p.spid = t2.blocking_session_id) AS [blocker_batch]  --last column
FROM sys.dm_tran_locks AS t1 WITH (NOLOCK)
INNER JOIN sys.dm_os_waiting_tasks AS t2 WITH (NOLOCK)
ON t1.lock_owner_address = t2.resource_address 
order by [blocker_batch] OPTION (RECOMPILE); --order by produces an overview different queries; look for these values and see how to optimize them


 select 'who lock my object commented'
---- don't run on heavy load unless more specific --who lock my object
--select  'Query to return active locks and the duration of the locks being held'
SELECT top 10 Locks.request_session_id AS SessionID ,
        Obj.Name AS LockedObjectName ,
        COUNT(*) AS Locks, ExeSess.host_name, ExeSess.program_name,DATEDIFF(second,  GETDATE(), ActTra.Transaction_begin_time) AS Duration, ActTra.Transaction_begin_time  
FROM    sys.dm_tran_locks Locks
        JOIN sys.partitions Parti ON Parti.hobt_id = Locks.resource_associated_entity_id
        JOIN sys.objects Obj ON Obj.object_id = Parti.object_id
        JOIN sys.dm_exec_sessions ExeSess ON ExeSess.session_id = Locks.request_session_id
        JOIN sys.dm_tran_session_transactions TranSess ON ExeSess.session_id = TranSess.session_id
        JOIN sys.dm_tran_active_transactions ActTra ON TranSess.transaction_id = ActTra.transaction_id
WHERE   resource_database_id = DB_ID()
	   --db_name(l.resource_database_id) in('MedRx', 'RMSOCR', 'MedRxAnalytics', 'Billing')
        AND Obj.Type = 'U'
	   --and Obj.Name like 'Extractoutput%'
GROUP BY ActTra.Transaction_begin_time ,
        Locks.request_session_id ,
        Obj.Name, ExeSess.host_name, ExeSess.program_name
order by Duration

--use sessionId in this part
--select 'sessions blocking other, ACTIVE/executing(sys.dm_exec_requests) queries & sql text'
--to find query reponsible 



--SELECT t1.resource_type AS [lock type], DB_NAME(resource_database_id) AS [database],
--t1.resource_associated_entity_id AS [blk object],t1.request_mode AS [lock req],  -- lock requested
--t1.request_session_id AS [waiter sid], t2.wait_duration_ms AS [wait time],       -- spid of waiter  
--(SELECT [text] FROM sys.dm_exec_requests AS r WITH (NOLOCK)                      -- get sql for waiter
--CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) 
--WHERE r.session_id = t1.request_session_id) AS [waiter_batch],
--(SELECT SUBSTRING(qt.[text],r.statement_start_offset/2, 
--    (CASE WHEN r.statement_end_offset = -1 
--    THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
--    ELSE r.statement_end_offset END - r.statement_start_offset)/2) 
--FROM sys.dm_exec_requests AS r WITH (NOLOCK)
--CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) AS qt
--WHERE r.session_id = t1.request_session_id) AS [waiter_stmt],					-- statement blocked
--t2.blocking_session_id AS [blocker sid],										-- spid of blocker
--(SELECT [text] FROM sys.sysprocesses AS p										-- get sql for blocker
--CROSS APPLY sys.dm_exec_sql_text(p.[sql_handle]) 
--WHERE p.spid = t2.blocking_session_id) AS [blocker_batch]  --last column
--FROM sys.dm_tran_locks AS t1 WITH (NOLOCK)
--INNER JOIN sys.dm_os_waiting_tasks AS t2 WITH (NOLOCK)
--ON t1.lock_owner_address = t2.resource_address OPTION (RECOMPILE);



/*
-- https://github.com/amachanic/sp_whoisactive

-- open tran, cpu,memory used
*/
 select 'sp_WhoIsActive: blocker desc - CPU desc - [Used_Memory] desc - Duration desc'
exec [RmsAdmin].dbo.sp_WhoIsActive  
		    @show_own_spid = 0
		  , @get_task_info =2 /* 1 ie lightweight. task-based metrics : current wait stats, physical I/O, context switches, and blocker information*/
		  , @get_avg_time = 0
		  , @get_locks = 1
		  --, @get_plans = 1
		  --, @get_transaction_info = 1
		  --, @delta_interval = 5 -- Interval in seconds to wait before doing the second data pull
		  , @find_block_leaders =1
		  , @show_sleeping_spids = 0 --1 sleeping with open transaction
		  --, @get_plans = 1 
		  , @sort_order = '[blocked_session_count] desc, [Used_Memory] desc, [CPU] desc, [open_tran_count] desc' 
		  --, @destination_table = ''
		  , @output_column_list = '[dd%][cpu%][reads%][writes%][wait_info][physical%][sql_text][session_id][blocked_session_count][login_name][host_name][database_name][program_name][used_memory][open_tran_count][status][tasks][sql_command][tran_log%][temp%][context%][query_plan][locks][%]'-- '[col1][col2]...'

--exec [RmsAdmin].dbo.sp_WhoIsActive  
--		    @show_own_spid = 0
--		  , @get_task_info =2 /* 1 ie lightweight. task-based metrics : current wait stats, physical I/O, context switches, and blocker information*/
--		  , @get_avg_time = 1
--		  , @get_locks = 1
--		  --, @get_transaction_info = 1
--		  --, @delta_interval = 5 -- Interval in seconds to wait before doing the second data pull
--		  , @find_block_leaders =1
--		  , @show_sleeping_spids = 0 --1 sleeping with open transaction
--		  --, @get_plans = 1 
--		  , @sort_order = '[CPU] desc, [blocked_session_count] desc,[Used_Memory] desc, [open_tran_count] desc' 
--		  --, @destination_table = ''
--		  --, @output_column_list = '[col1][col2]...'



if (select IS_SRVROLEMEMBER('sysadmin','mbello') IsMemberOfSysAdmin) = 1
begin
    select 'open transaction in log that may preventing log truncation' 
    dbcc opentran WITH TABLERESULTS--, NO_INFOMSGS http://www.mssqlspark.com/2021/09/sql-server-fundamentals-dbcc-opentran.html
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
JOIN sys.dm_exec_requests r on r.session_id = s.session_id --*** for running request
where s.host_process_id > 0 AND resource_type = 'OBJECT'
and db_name(l.resource_database_id) = db_name() and s.session_id <> @@SPID
order by objectName, request_mode --s.host_name-- request_mode

--select 'find lock esclation on a table '
SELECT CASE WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id) else OBJECT_NAME(b.OBJECT_ID) end ObjectName, 
resource_type, request_mode, resource_description, request_session_id, partition_id, request_status, request_type 
--into #mylock
FROM sys.dm_tran_locks a
LEFT JOIN sys.partitions b ON b.hobt_id = a.resource_associated_entity_id
WHERE resource_type <> 'DATABASE' AND db_name(resource_database_id)  in('MedRx', 'RMSOCR', 'MedRxAnalytics', 'Billing')--DB_ID() -- and request_session_id = @@spid;

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

SELECT ec.client_net_address, es.[program_name], es.[host_name], es.login_name, 
COUNT(ec.session_id) AS [connection count] 
FROM sys.dm_exec_sessions AS es WITH (NOLOCK) 
INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK) 
ON es.session_id = ec.session_id 
GROUP BY ec.client_net_address, es.[program_name], es.[host_name], es.login_name  
ORDER BY es.login_name

--SELECT distinct ec.client_net_address, es.[host_name], es.login_name
--FROM sys.dm_exec_sessions AS es WITH (NOLOCK) 
--INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK) 
--ON es.session_id = ec.session_id 
--where es.host_name like 'LT-%'

SELECT @@SERVERNAME serverName, 
COUNT(ec.session_id) AS [connection count] 
FROM sys.dm_exec_sessions AS es WITH (NOLOCK) 
INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK) 
ON es.session_id = ec.session_id 


select 'Get server Pressure' 
exec RmsAdmin.dbo.sp_PressureDetector  --@help = 1


-- how much CPU the queries are currently using, out of overall CPU capacity
DECLARE @init_sum_cpu_time int,
        @utilizedCpuCount int 
--get CPU count used by SQL Server
SELECT @utilizedCpuCount = COUNT( * )
FROM sys.dm_os_schedulers
WHERE status = 'VISIBLE ONLINE' 
--calculate the CPU usage by queries OVER a 5 sec interval 
SELECT @init_sum_cpu_time = SUM(cpu_time) FROM sys.dm_exec_requests
WAITFOR DELAY '00:00:05'
SELECT CONVERT(DECIMAL(5,2), ((SUM(cpu_time) - @init_sum_cpu_time) / (@utilizedCpuCount * 5000.00)) * 100) AS [CPU from Queries as Percent of Total CPU Capacity] 
FROM sys.dm_exec_requests


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