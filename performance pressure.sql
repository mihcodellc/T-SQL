-- ********************************memory pressure 

--https://docs.microsoft.com/en-us/sql/relational-databases/performance-monitor/monitor-memory-usage?view=sql-server-ver15#monitor-operating-system-memory

--Determining current memory allocation
SELECT 'Determining current memory allocation',
(total_physical_memory_kb/1024) AS Total_OS_Memory_MB,
(available_physical_memory_kb/1024)  AS Available_OS_Memory_MB
FROM sys.dm_os_sys_memory;

SELECT 'Determining current memory allocation', 
(physical_memory_in_use_kb/1024) AS Memory_used_by_Sqlserver_MB,  
(locked_page_allocations_kb/1024) AS Locked_pages_used_by_Sqlserver_MB,  
(total_virtual_address_space_kb/1024) AS Total_VAS_in_MB,
process_physical_memory_low,  
process_virtual_memory_low  
FROM sys.dm_os_process_memory;  

--Determining current SQL Server memory utilization
SELECT 'Determining current SQL Server memory utilization',
sqlserver_start_time,
(committed_kb/1024) AS Total_Server_Memory_MB,
(committed_target_kb/1024)  AS Target_Server_Memory_MB
FROM sys.dm_os_sys_info;

--Determining page life expectancy
SELECT 'Determining page life expectancy',
CASE instance_name WHEN '' THEN 'Overall' ELSE instance_name END AS NUMA_Node, cntr_value AS PLE_s
FROM sys.dm_os_performance_counters    
WHERE counter_name = 'Page life expectancy';


set statistics io, time, profile on

set statistics profile off

set  noexec off

set showplan_text on

select * from sys.dm_os_performance_counters 
--order by counter_name
where counter_name in ('Batch Requests/sec', 'SQL Compilations/sec' , 'SQL Re-Compilations/sec') and 
--where counter_name like '%time%'

--select * FROM sys.dm_os_performance_counters order by wait_type

---********************************** CPU pressure

SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2))
AS [%signal (cpu) waits],
CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2))
AS [%resource waits] FROM sys.dm_os_wait_stats OPTION (RECOMPILE);SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2))
AS [%signal (cpu) waits],
CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2))
AS [%resource waits] FROM sys.dm_os_wait_stats OPTION (RECOMPILE);


SELECT COUNT(*) AS workers_waiting, t2.Scheduler_id
FROM sys.dm_os_workers AS t1, sys.dm_os_schedulers AS t2
WHERE t1.state = 'RUNNABLE' AND
    t1.scheduler_address = t2.scheduler_address AND
    t2.scheduler_id < 255
GROUP BY t2.scheduler_id;


--Average CPU Load
SELECT COUNT(*) Schedulers,
AVG(current_tasks_count) AS [Avg Current Task Count],
AVG(runnable_tasks_count) AS [Avg Runnable Task Count],
AVG(work_queue_count) AS [Avg Work Queue Count],
AVG(pending_disk_io_count) AS [Avg Pending DiskIO Count],
AVG(current_workers_count) AS [Avg Current Worker Count],
AVG(active_workers_count) AS [Avg Active Worker Count]
FROM sys.dm_os_schedulers WITH (NOLOCK)
WHERE scheduler_id < 255;

--Total CPU Load
SELECT COUNT(*) Schedulers,
SUM(current_tasks_count) AS [Sum Current Task Count],
SUM(runnable_tasks_count) AS [Sum Runnable Task Count],
SUM(work_queue_count) AS [Sum Work Queue Count],
SUM(pending_disk_io_count) AS [Sum Pending DiskIO Count],
SUM(current_workers_count) AS [Sum Current Worker Count],
SUM(active_workers_count) AS [Sum Active Worker Count]
FROM sys.dm_os_schedulers WITH (NOLOCK)
WHERE scheduler_id < 255;


-- more CPU cumulative: dm_exec_query_stats.total_worker_time
select s.*,p.*
from (select top 10 plan_handle, total_worker_time 
from sys.dm_exec_query_stats)s
cross apply sys.dm_exec_sql_text(s.plan_handle)p order by total_worker_time desc

--QUERY PERFORMANCE 
--performamce center
--https://docs.microsoft.com/en-us/sql/relational-databases/performance/performance-center-for-sql-server-database-engine-and-azure-sql-database?view=sql-server-ver15
--set statistics IO, TIME on


-- ***query profiling  information about execution plans, namely row count, CPU and I/O usage.
--SET STATISTICS XML ON
--SET STATISTICS PROFILE ON
------search for operators which create the issue
--Live Query Statistics for SQL 2014(12.x) and above
----1. execute the query once
----2. in Activity monitor, select the query -> right click -> show Live Execution Plan
------https://docs.microsoft.com/en-us/sql/relational-databases/performance/live-query-statistics?view=sql-server-ver15
--wait types for a session: sys.dm_exec_session_wait_stats, sys.dm_os_wait_stats => refere to WaitingTasks.sql


----***see the plan before execute
--set showplan_all On
--set showplan_text ON Versus SET STATISTICS PROFILE ON
--use extended events/create the session

--***all tools for monitoring SQL Server
--https://docs.microsoft.com/en-us/sql/relational-databases/performance/performance-monitoring-and-tuning-tools?view=sql-server-ver15
-- Use search fields on Docs page
--Performance Dashboard : right-click on the SQL Server instance name in Object Explorer, select Reports, Standard Reports, and click on Performance Dashboard

--***all metrics for monitoring SQL Server- - use with perform if available
--https://documentation.red-gate.com/sm5/analyzing-performance/analysis-graph/list-of-metrics#Listofmetrics-Userconnections
--https://www.datadoghq.com/blog/sql-server-monitoring-tools/#richer-real-time-sql-server-monitoring-tools

--***TUNING
DBCC SHOW_STATISTICS ('atable','an_index')  
UPDATE STATISTICS atable;
UPDATE STATISTICS dbo.A ix1 WITH FULLSCAN, PERSIST_SAMPLE_PERCENT = ON;