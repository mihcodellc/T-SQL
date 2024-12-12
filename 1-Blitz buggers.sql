----***************************STEP 1
---- how much CPU the queries are currently using, out of overall CPU capacity
--DECLARE @init_sum_cpu_time int,
--        @utilizedCpuCount int 
----get CPU count used by SQL Server
--SELECT @utilizedCpuCount = COUNT( * )
--FROM sys.dm_os_schedulers
--WHERE status = 'VISIBLE ONLINE' 
----calculate the CPU usage by queries OVER a 5 sec interval 
--SELECT @init_sum_cpu_time = SUM(cpu_time) FROM sys.dm_exec_requests
--WAITFOR DELAY '00:00:05'
--SELECT CONVERT(DECIMAL(5,2), ((SUM(cpu_time) - @init_sum_cpu_time) / (@utilizedCpuCount * 5000.00)) * 100) AS [CPU from Queries as Percent of Total CPU Capacity] 
--FROM sys.dm_exec_requests

-- Get CPU Utilization History for last 256 minutes (in one minute intervals)  (Query 42) (CPU Utilization History)
-- processor time _total in perfmon
-- populate by extend event
--get top 1 every minute to log CPU usage
DECLARE @ts_now bigint = (SELECT ms_ticks FROM sys.dm_os_sys_info WITH (NOLOCK)); 

SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               --SystemIdle AS [System Idle Process], 
               --100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] ,
			[record]
FROM (SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
              record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
                      AS [SystemIdle], 
              record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') 
                      AS [SQLProcessUtilization], [timestamp], [record] 
         FROM (SELECT [timestamp], CONVERT(xml, record) AS [record] 
                      FROM sys.dm_os_ring_buffers WITH (NOLOCK)
                      WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
                      AND record LIKE N'%<SystemHealth>%') AS x) AS y 
ORDER BY record_id DESC OPTION (RECOMPILE);


go
--exec [RmsAdmin].[dbo].[sp_BlitzWho_RMS] 

--live activity checker - what’s really happening - Forget sp_Who and sp_Who2---replace Activitor monitor
exec [RmsAdmin].[dbo].[sp_BlitzWho_test] @ExpertMode = 1 --cached_parameter_info(sniffing),top_session_waits, tempdb_allocations, workload_group, resource_pool kill 2902
  --,@OutputDatabaseName = 'RmsAdmin' 
  --,@OutputSchemaName = 'dbo'  
  --,@OutputTableName = 'BlitzWho'
  , @sortOrder= 'request_cpu_time' --database_name/*Monktar added elapsed_time desc*/
						  --, request_cpu_time, elapsed_time, request_logical_reads,request_physical_reads, request_writes, grant_memory_kb kill 2620
						  --, login_name, --- [blocking_session_id], host_name
						  --check the is_implicit_transaction column to spot the culprits.
						  --If one of them is a lead blocker, consider killing that query.

go

--    select '********************available space on memory********************'
--    select '********************available space on memory********************'
--    select '********************available space on memory********************'

--    --****Free Memory less 20%, growth day after day -- memory free for OS, SQL server memory shuldn't be unlimited
--    SELECT available_physical_memory_kb/1024 as "Total Memory MB available_physical",
-- available_physical_memory_kb/(total_physical_memory_kb*1.0)*100 AS "% Memory Free",
-- total_physical_memory_kb/1024 AS [Physical Memory (MB)], 
--       total_page_file_kb/1024 AS [Page File Commit Limit (MB)],
--	   total_page_file_kb/1024 - total_physical_memory_kb/1024 AS [Physical Page File Size (MB)],
--	   available_page_file_kb/1024 AS [Available Page File (MB)], 
--	   system_cache_kb/1024 AS [System Cache (MB)],
--       system_memory_state_desc AS [System Memory State]
--FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);


--***************************STEP 2
----top running in last @Seconds
--exec [RmsAdmin].[dbo].[sp_BlitzFirst] @Seconds = 900, @expertmOde = 1 -- wait ratio,top session waits, db count, size, cpu utilization, memory grant -- also provide querys parameter's
-- 

--go
----what was in cache @MinutesBack
--EXEC [RmsAdmin].dbo.sp_BlitzCache @MinutesBack = 15, @Top = 100,   @DatabaseName='jiraservicedesk' -- @sortOrder = 'Spills'

--EXEC [RmsAdmin].dbo.sp_BlitzCache @sortOrder = 'Spills' -- spill to tempdb
--EXEC [RmsAdmin].dbo.sp_BlitzCache @sortOrder = 'cpu', @expertmOde = 1, @Top = 10, @MinutesBack = 15  -- 
--EXEC [RmsAdmin].dbo.sp_BlitzCache @sortOrder = 'reads' -- 



--SET TRANSACTION ISOLATION LEVEL SNAPSHOT



