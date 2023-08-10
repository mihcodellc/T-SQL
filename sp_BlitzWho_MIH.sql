create   proc [dbo].[sp_BlitzWho_RMS]
As 
begin

-- 8/10/2023 By mbello: derived from sp_BlitzWho to allow easy twist

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET LOCK_TIMEOUT 1000;/* To avoid blocking on live query plans. See Github issue #2907. */

DECLARE @blocked TABLE (dbid SMALLINT NOT NULL, last_batch DATETIME NOT NULL, open_tran SMALLINT NOT NULL, sql_handle BINARY (20) NOT NULL, session_id SMALLINT NOT NULL, blocking_session_id SMALLINT NOT NULL, lastwaittype NCHAR(32) NOT NULL, waittime BIGINT NOT NULL, cpu INT NOT NULL, physical_io BIGINT NOT NULL, memusage INT NOT NULL);

INSERT @blocked (dbid, last_batch, open_tran, sql_handle, session_id, blocking_session_id, lastwaittype, waittime, cpu, physical_io, memusage)
SELECT sys1.dbid, sys1.last_batch, sys1.open_tran, sys1.sql_handle, sys2.spid AS session_id, sys2.blocked AS blocking_session_id, sys2.lastwaittype, sys2.waittime, sys2.cpu, sys2.physical_io, sys2.memusage
FROM sys.sysprocesses AS sys1
JOIN sys.sysprocesses AS sys2 ON sys1.spid = sys2.blocked;

DECLARE @LiveQueryPlans TABLE (Session_Id INT NOT NULL, Query_Plan XML NOT NULL);

select  
run_date,elapsed_time,session_id,database_name,query_text,blocking_session_id,request_cpu_time,nt_domain,host_name,login_name,nt_user_name,program_name,request_physical_reads,session_cpu,session_logical_reads,query_plan,
live_query_plan,Cached_Parameter_Info,query_cost,STATUS,wait_info,wait_resource,top_session_waits,open_transaction_count,is_implicit_transaction,fix_parameter_sniffing,client_interface_name,login_time,start_time,
request_time,request_logical_reads,request_writes,session_physical_reads,session_writes,tempdb_allocations_mb,memory_usage,estimated_completion_time,percent_complete,DEADLOCK_PRIORITY,transaction_isolation_level,
degree_of_parallelism,last_dop,min_dop,max_dop,last_grant_kb,min_grant_kb,max_grant_kb,last_used_grant_kb,min_used_grant_kb,max_used_grant_kb,last_ideal_grant_kb,min_ideal_grant_kb,max_ideal_grant_kb,last_reserved_threads,
min_reserved_threads,max_reserved_threads,last_used_threads,min_used_threads,max_used_threads,grant_time,requested_memory_kb,grant_memory_kb,is_request_granted,required_memory_kb,query_memory_grant_used_memory_kb,
ideal_memory_kb,is_small,timeout_sec,resource_semaphore_id,wait_order,wait_time_ms,next_candidate_for_memory_grant,target_memory_kb,max_target_memory_kb,total_memory_kb,available_memory_kb,granted_memory_kb,
query_resource_semaphore_used_memory_kb,grantee_count,waiter_count,timeout_error_count,forced_grant_count,workload_group_name,resource_pool_name,context_info,query_hash,query_plan_hash,sql_handle,plan_handle,
statement_start_offset,statement_end_offset
from 
(
SELECT GETDATE() AS run_date, COALESCE(RIGHT('00' + CONVERT(VARCHAR(20), (ABS(r.total_elapsed_time) / 1000) / 86400), 2) + ':' + CONVERT(VARCHAR(20), (DATEADD(SECOND, (r.total_elapsed_time / 1000), 0) + DATEADD(MILLISECOND, (r.total_elapsed_time % 1000), 0)), 114), RIGHT('00' + CONVERT(VARCHAR(20), DATEDIFF(SECOND, s.last_request_start_time, GETDATE()) / 86400), 2) + ':' + CONVERT(VARCHAR(20), DATEADD(SECOND, DATEDIFF(SECOND, s.last_request_start_time, GETDATE()), 0), 114)) AS [elapsed_time], s.session_id, COALESCE(DB_NAME(r.database_id), DB_NAME(blocked.dbid), 'N/A') AS database_name, ISNULL(SUBSTRING(dest.TEXT, (query_stats.statement_start_offset / 2) + 1, (
				(
					CASE query_stats.statement_end_offset
						WHEN - 1
							THEN DATALENGTH(dest.TEXT)
						ELSE query_stats.statement_end_offset
						END - query_stats.statement_start_offset
					) / 2
				) + 1), dest.TEXT) AS query_text, 
		CASE 
		WHEN r.blocking_session_id <> 0 AND blocked.session_id IS NULL
			THEN r.blocking_session_id
		WHEN r.blocking_session_id <> 0 AND s.session_id <> blocked.blocking_session_id
			THEN blocked.blocking_session_id
		WHEN r.blocking_session_id = 0 AND s.session_id = blocked.session_id
			THEN blocked.blocking_session_id
		WHEN r.blocking_session_id <> 0 AND s.session_id = blocked.blocking_session_id
			THEN r.blocking_session_id
		ELSE NULL
		END AS blocking_session_id,
		COALESCE(r.cpu_time, s.cpu_time) AS request_cpu_time,
		qmg.granted_memory_kb AS grant_memory_kb,
		s.nt_domain, s.host_name, s.login_name, s.nt_user_name, 
		COALESCE((
			SELECT REPLACE(program_name, Substring(program_name, 30, 34), '"' + j.name + '"')
			FROM msdb.dbo.sysjobs j
			WHERE Substring(program_name, 32, 32) = CONVERT(CHAR(32), CAST(j.job_id AS BINARY (16)), 2)
			), s.program_name) as program_name, 
	     COALESCE(r.reads, s.reads) AS request_physical_reads, s.cpu_time AS session_cpu, s.logical_reads AS session_logical_reads,
		derp.query_plan, CAST(COALESCE(qs_live.Query_Plan, '<?Live Query Plans were not retrieved. Set @GetLiveQueryPlan=1 to try and retrieve Live Query Plans ?>') AS XML) AS live_query_plan, STUFF((
			SELECT DISTINCT N', ' + Node.Data.value('(@Column)[1]', 'NVARCHAR(4000)') + N' {' + Node.Data.value('(@ParameterDataType)[1]', 'NVARCHAR(4000)') + N'}: ' + Node.Data.value('(@ParameterCompiledValue)[1]', 'NVARCHAR(4000)')
			FROM derp.query_plan.nodes('/*:ShowPlanXML/*:BatchSequence/*:Batch/*:Statements/*:StmtSimple/*:QueryPlan/*:ParameterList/*:ColumnReference') AS Node(Data)
			FOR XML PATH('')
			), 1, 2, '') AS Cached_Parameter_Info, qmg.query_cost, s.STATUS, CASE 
		WHEN s.STATUS <> 'sleeping'
			THEN COALESCE(wt.wait_info, RTRIM(blocked.lastwaittype) + ' (' + CONVERT(VARCHAR(10), blocked.waittime) + ')')
		ELSE NULL
		END AS wait_info, r.wait_resource, SUBSTRING(wt2.session_wait_info, 0, LEN(wt2.session_wait_info)) AS top_session_waits, 
	     COALESCE(r.open_transaction_count, blocked.open_tran) AS open_transaction_count, CASE 
		WHEN EXISTS (
				SELECT 1
				FROM sys.dm_tran_active_transactions AS tat
				JOIN sys.dm_tran_session_transactions AS tst ON tst.transaction_id = tat.transaction_id
				WHERE tat.name = 'implicit_transaction' AND s.session_id = tst.session_id
				)
			THEN 1
		ELSE 0
		END AS is_implicit_transaction, 
		'DBCC FREEPROCCACHE (' + CONVERT(NVARCHAR(128), r.plan_handle, 1) + ');' AS fix_parameter_sniffing, 
		s.client_interface_name, s.login_time, r.start_time, qmg.request_time,  COALESCE(r.logical_reads, s.logical_reads) AS request_logical_reads, COALESCE(r.writes, s.writes) AS request_writes,  s.reads AS session_physical_reads, s.writes AS session_writes, tempdb_allocations.tempdb_allocations_mb, s.memory_usage, r.estimated_completion_time, r.percent_complete, r.DEADLOCK_PRIORITY, CASE 
		WHEN s.transaction_isolation_level = 0
			THEN 'Unspecified'
		WHEN s.transaction_isolation_level = 1
			THEN 'Read Uncommitted'
		WHEN s.transaction_isolation_level = 2 AND EXISTS (
				SELECT 1
				FROM sys.databases
				WHERE name = DB_NAME(r.database_id) AND is_read_committed_snapshot_on = 1
				)
			THEN 'Read Committed Snapshot Isolation'
		WHEN s.transaction_isolation_level = 2
			THEN 'Read Committed'
		WHEN s.transaction_isolation_level = 3
			THEN 'Repeatable Read'
		WHEN s.transaction_isolation_level = 4
			THEN 'Serializable'
		WHEN s.transaction_isolation_level = 5
			THEN 'Snapshot'
		ELSE 'WHAT HAVE YOU DONE?'
		END AS transaction_isolation_level, qmg.dop AS degree_of_parallelism, query_stats.last_dop, query_stats.min_dop, query_stats.max_dop, query_stats.last_grant_kb, query_stats.min_grant_kb, query_stats.max_grant_kb, query_stats.last_used_grant_kb, query_stats.min_used_grant_kb, query_stats.max_used_grant_kb, query_stats.last_ideal_grant_kb, query_stats.min_ideal_grant_kb, query_stats.max_ideal_grant_kb, query_stats.last_reserved_threads, query_stats.min_reserved_threads, query_stats.max_reserved_threads, query_stats.last_used_threads, query_stats.min_used_threads, query_stats.max_used_threads, COALESCE(CAST(qmg.grant_time AS VARCHAR(20)), 'Memory Not Granted') AS grant_time, qmg.requested_memory_kb, CASE 
		WHEN qmg.grant_time IS NULL
			THEN 'N/A'
		WHEN qmg.requested_memory_kb < qmg.granted_memory_kb
			THEN 'Query Granted Less Than Query Requested'
		ELSE 'Memory Request Granted'
		END AS is_request_granted, qmg.required_memory_kb, qmg.used_memory_kb AS query_memory_grant_used_memory_kb, qmg.ideal_memory_kb, qmg.is_small, qmg.timeout_sec, qmg.resource_semaphore_id, COALESCE(CAST(qmg.wait_order AS VARCHAR(20)), 'N/A') AS wait_order, COALESCE(CAST(qmg.wait_time_ms AS VARCHAR(20)), 'N/A') AS wait_time_ms, CASE qmg.is_next_candidate
		WHEN 0
			THEN 'No'
		WHEN 1
			THEN 'Yes'
		ELSE 'N/A'
		END AS next_candidate_for_memory_grant, qrs.target_memory_kb, COALESCE(CAST(qrs.max_target_memory_kb AS VARCHAR(20)), 'Small Query Resource Semaphore') AS max_target_memory_kb, qrs.total_memory_kb, qrs.available_memory_kb, qrs.granted_memory_kb, qrs.used_memory_kb AS query_resource_semaphore_used_memory_kb, qrs.grantee_count, qrs.waiter_count, qrs.timeout_error_count, COALESCE(CAST(qrs.forced_grant_count AS VARCHAR(20)), 'Small Query Resource Semaphore') AS forced_grant_count, wg.name AS workload_group_name, rp.name AS resource_pool_name, CONVERT(VARCHAR(128), r.context_info) AS context_info, r.query_hash, r.query_plan_hash, r.sql_handle, r.plan_handle, r.statement_start_offset, r.statement_end_offset
FROM sys.dm_exec_sessions AS s
LEFT JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
LEFT JOIN (
	SELECT DISTINCT wait.session_id, (
			SELECT waitwait.wait_type + N' (' + CAST(MAX(waitwait.wait_duration_ms) AS NVARCHAR(128)) + N' ms) '
			FROM sys.dm_os_waiting_tasks AS waitwait
			WHERE waitwait.session_id = wait.session_id
			GROUP BY waitwait.wait_type
			ORDER BY SUM(waitwait.wait_duration_ms) DESC
			FOR XML PATH('')
			) AS wait_info
	FROM sys.dm_os_waiting_tasks AS wait
	) AS wt ON s.session_id = wt.session_id
LEFT JOIN sys.dm_exec_query_stats AS query_stats ON r.sql_handle = query_stats.sql_handle AND r.plan_handle = query_stats.plan_handle AND r.statement_start_offset = query_stats.statement_start_offset AND r.statement_end_offset = query_stats.statement_end_offset
LEFT JOIN (
	SELECT DISTINCT wait.session_id, (
			SELECT TOP 5 waitwait.wait_type + N' (' + CAST(MAX(waitwait.wait_time_ms) AS NVARCHAR(128)) + N' ms), '
			FROM sys.dm_exec_session_wait_stats AS waitwait
			WHERE waitwait.session_id = wait.session_id
			GROUP BY waitwait.wait_type
			HAVING SUM(waitwait.wait_time_ms) > 5
			ORDER BY 1
			FOR XML PATH('')
			) AS session_wait_info
	FROM sys.dm_exec_session_wait_stats AS wait
	) AS wt2 ON s.session_id = wt2.session_id
LEFT JOIN sys.dm_exec_query_stats AS session_stats ON r.sql_handle = session_stats.sql_handle AND r.plan_handle = session_stats.plan_handle AND r.statement_start_offset = session_stats.statement_start_offset AND r.statement_end_offset = session_stats.statement_end_offset
LEFT JOIN sys.dm_exec_query_memory_grants qmg ON r.session_id = qmg.session_id AND r.request_id = qmg.request_id
LEFT JOIN sys.dm_exec_query_resource_semaphores qrs ON qmg.resource_semaphore_id = qrs.resource_semaphore_id AND qmg.pool_id = qrs.pool_id
LEFT JOIN sys.resource_governor_workload_groups wg ON s.group_id = wg.group_id
LEFT JOIN sys.resource_governor_resource_pools rp ON wg.pool_id = rp.pool_id
OUTER APPLY (
	SELECT TOP 1 b.dbid, b.last_batch, b.open_tran, b.sql_handle, b.session_id, b.blocking_session_id, b.lastwaittype, b.waittime
	FROM @blocked b
	WHERE (s.session_id = b.session_id OR s.session_id = b.blocking_session_id)
	) AS blocked
OUTER APPLY sys.dm_exec_sql_text(COALESCE(r.sql_handle, blocked.sql_handle)) AS dest
OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS derp
OUTER APPLY (
	SELECT CONVERT(DECIMAL(38, 2), SUM((((tsu.user_objects_alloc_page_count - user_objects_dealloc_page_count) * 8) / 1024.))) AS tempdb_allocations_mb
	FROM sys.dm_db_task_space_usage tsu
	WHERE tsu.request_id = r.request_id AND tsu.session_id = r.session_id AND tsu.session_id = s.session_id
	) AS tempdb_allocations
OUTER APPLY (
	SELECT TOP 1 Query_Plan, STUFF((
				SELECT DISTINCT N', ' + Node.Data.value('(@Column)[1]', 'NVARCHAR(4000)') + N' {' + Node.Data.value('(@ParameterDataType)[1]', 'NVARCHAR(4000)') + N'}: ' + Node.Data.value('(@ParameterCompiledValue)[1]', 'NVARCHAR(4000)') + N' (Actual: ' + Node.Data.value('(@ParameterRuntimeValue)[1]', 'NVARCHAR(4000)') + N')'
				FROM q.Query_Plan.nodes('/*:ShowPlanXML/*:BatchSequence/*:Batch/*:Statements/*:StmtSimple/*:QueryPlan/*:ParameterList/*:ColumnReference') AS Node(Data)
				FOR XML PATH('')
				), 1, 2, '') AS Live_Parameter_Info
	FROM @LiveQueryPlans q
	WHERE (s.session_id = q.Session_Id)
	) AS qs_live
WHERE s.session_id <> @@SPID 
AND s.host_name IS NOT NULL AND r.database_id NOT IN (1, 2, 3, 4) -- medrx id =10
	AND COALESCE(DB_NAME(r.database_id), DB_NAME(blocked.dbid)) IS NOT NULL
) whos
ORDER BY 
[host_name] ASC, [request_cpu_time] desc, grant_memory_kb desc 
-- order by [login_name] ASC
-- elapsed_time desc
OPTION (MAX_GRANT_PERCENT = 1, RECOMPILE);


end
