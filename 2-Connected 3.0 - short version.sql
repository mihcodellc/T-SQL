--please combine with Expensive queries in Activity monitor
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
SELECT getdate() as RunAt, r.wait_type, r.wait_time / (1000.0) as WaitSec,  r.total_elapsed_time / (1000.0) 'ElapsSec', 
bl.session_id,r.cpu_time, r.reads, r.writes, r.logical_reads,
blocked_by = r.blocking_session_id, bl.blocking_these,s.login_name,
--substring(case when len(ib.event_info)> 0 then ib.event_info else '' end,0,2000) Query_involved,
s.[host_name],
COALESCE((
					SELECT REPLACE(program_name,Substring(program_name,30,34),'"'+j.name+'"') 
					FROM msdb.dbo.sysjobs j WHERE Substring(program_name,32,32) = CONVERT(char(32),CAST(j.job_id AS binary(16)),2)
					),s.[program_name])
as [program_name], 
substring(case when len(ib.event_info)> 0 then ib.event_info else '' end,0,2000) Query_involved,
batch_text = st.text,  r.scheduler_id, r.wait_resource, sdec.client_net_address, sdec.local_net_address, derp.query_plan, r.command,s.status --, r.sql_handle,
--cwhether there is contention
----the waiting resources should be from tempdb to talk about tempdb contention
, COUNT(r.session_id) over ( partition by r.wait_resource ) as sessi_cont_5 --val > 5
, COUNT(r.wait_time) over ( partition by r.wait_resource) as time_cont_10 --val > 10
, 'dbcc traceon (3604); dbcc page(' + replace(wait_resource,':',',') + ',3); dbcc traceoff (3604)' as ContentionOnMe -- PAGELATCH_EX
   -- r.plan_handle --, *
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_connections AS sdec  ON sdec.session_id = s.session_id
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
LEFT JOIN cteBL as bl on s.session_id = bl.session_id
--INNER JOIN cteBL as bl on s.session_id = bl.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) st
OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS derp
WHERE s.session_id != @@SPID and --  s.session_id in (1865, 2890, 2030) --ib.event_info like '%LoaderState_Populate_byView_yearago%'--s.session_id != @@SPID  -- kill 2834, kill 2269 kill 772
 ( --blocking over 3min
		  (
			 (len(bl.blocking_these) > 0 OR r.blocking_session_id <> 0)-- blocked or blocking
			 and 
			 (
				r.total_elapsed_time / (1000.0)  > 0 -- 180=3*60
				or
				DATEDIFF(second, GETDATE(), r.start_time) > 0
			 )
		  )
	       or 
      --running over 20min
		(
		  r.total_elapsed_time / (1000.0)  > 0--1200=20*60 kill 2628
		  or
		  DATEDIFF(second, GETDATE(), r.start_time) > 0
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
--ORDER BY r.wait_resource 
-- *** order by login 
--ORDER BY login_name




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


-- -- Expert, by priority
--EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' ,@Mode = 4
----on one table
--EXEC RmsAdmin.dbo.sp_BlitzIndex @DatabaseName='MedRx', @SchemaName='dbo', @TableName='extractoutput'


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
,session_status,group_id,query_hash,query_plan_hash, Query_involved) 
AS ( SELECT sess.session_id, req.request_id, LEFT (ISNULL (req.wait_type, ''), 50) AS 'wait_type'
    , LEFT (ISNULL (req.wait_resource, ''), 40) AS 'wait_resource', LEFT (req.last_wait_type, 50) AS 'last_wait_type'
    , sess.is_user_process, req.cpu_time AS 'request_cpu_time', req.logical_reads AS 'request_logical_reads'
    , req.reads AS 'request_reads', req.writes AS 'request_writes', req.wait_time, req.blocking_session_id,sess.memory_usage
    , sess.cpu_time AS 'session_cpu_time', sess.reads AS 'session_reads', sess.writes AS 'session_writes', sess.logical_reads AS 'session_logical_reads'
    , CONVERT (decimal(5,2), req.percent_complete) AS 'percent_complete', req.estimated_completion_time AS 'est_completion_time'
    , req.start_time AS 'request_start_time', LEFT (req.status, 15) AS 'request_status', req.command
    , req.plan_handle, req.[sql_handle], req.statement_start_offset, req.statement_end_offset, conn.most_recent_sql_handle
    , LEFT (sess.status, 15) AS 'session_status', sess.group_id, req.query_hash, req.query_plan_hash
	, substring(case when len(ib.event_info)> 0 then ib.event_info else '' end,0,2000) Query_involved
    FROM sys.dm_exec_sessions AS sess
    LEFT OUTER JOIN sys.dm_exec_requests AS req ON sess.session_id = req.session_id
    LEFT OUTER JOIN sys.dm_exec_connections AS conn on conn.session_id = sess.session_id
	 OUTER APPLY sys.dm_exec_input_buffer(sess.session_id, NULL) AS ib -- filtering attention
    )
, cteBlockingHierarchy (head_blocker_session_id, session_id, blocking_session_id, wait_type, wait_duration_ms,
wait_resource, statement_start_offset, statement_end_offset, plan_handle, sql_handle, most_recent_sql_handle, [Level], Query_involved)
AS ( SELECT head.session_id AS head_blocker_session_id, head.session_id AS session_id, head.blocking_session_id
    , head.wait_type, head.wait_time, head.wait_resource, head.statement_start_offset, head.statement_end_offset
    , head.plan_handle, head.sql_handle, head.most_recent_sql_handle, 0 AS [Level], Query_involved
    FROM cteHead AS head
    WHERE (head.blocking_session_id IS NULL OR head.blocking_session_id = 0)
    AND head.session_id IN (SELECT DISTINCT blocking_session_id FROM cteHead WHERE blocking_session_id != 0)
    UNION ALL
    SELECT h.head_blocker_session_id, blocked.session_id, blocked.blocking_session_id, blocked.wait_type,
    blocked.wait_time, blocked.wait_resource, h.statement_start_offset, h.statement_end_offset,
    h.plan_handle, h.sql_handle, h.most_recent_sql_handle, [Level] + 1, blocked.Query_involved
    FROM cteHead AS blocked
    INNER JOIN cteBlockingHierarchy AS h ON h.session_id = blocked.blocking_session_id and h.session_id!=blocked.session_id --avoid infinite recursion for latch type of blocking
    WHERE h.wait_type COLLATE Latin1_General_BIN NOT IN ('EXCHANGE', 'CXPACKET') or h.wait_type is null
    )
SELECT bh.*, txt.text AS blocker_query_or_most_recent_query 
FROM cteBlockingHierarchy AS bh 
OUTER APPLY sys.dm_exec_sql_text (ISNULL ([sql_handle], most_recent_sql_handle)) AS txt;


------***https://www.sqlskills.com/blogs/paul/updated-sys-dm_os_waiting_tasks-script/
--select 'os_waiting task'
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
--    [es].[is_user_process] = 1 ---and owt.session_id = ?
--ORDER BY
--    [owt].[session_id],
--    [owt].[exec_context_id]; 


