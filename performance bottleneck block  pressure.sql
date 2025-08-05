--SQL SERVER – ACID (Atomicity, Consistency, Isolation, Durability)

-- SQL SERVER CONFIGURATION MANAGER to activate your sql agent or start db engine ...

--To review on time a year: An Accidental DBA by glenn
https://www.sqlskills.com/help/accidental-dba/?utm_source=accidentaldba&utm_medium=blogs&utm_campaign=training
--events
https://events.microsoft.com/en-us/mvtd?startTime=08:00&endTime=17:00
	
--*** SQL News
-- https://cloudblogs.microsoft.com/sqlserver
-- https://sqlblog.org/
--https://www.red-gate.com/simple-talk/databases/sql-server/
	
-- ***sql server editions compared
-- https://www.microsoft.com/en-us/sql-server/sql-server-2022-comparison
-- https://www.microsoft.com/en-us/sql-server/sql-server-2019-comparison
-- https://download.microsoft.com/download/2/9/0/290f991b-5971-42e5-bb2c-81f700622b2e/SQL%20Server%202019%20Editions%20Datasheet.pdf

-- deprecated features limit.sql

--Contention: refer to 	contention.sql

--check antivirus tasks at OS level	

--run check_instance.ps1

--tsql refreance
--https://learn.microsoft.com/en-us/sql/t-sql/language-reference?view=sql-server-ver15

-- ***sql server max capacities
-- https://docs.microsoft.com/en-us/sql/sql-server/maximum-capacity-specifications-for-sql-server?redirectedfrom=MSDN&view=sql-server-ver16

--*** Cumulative updates
-- https://learn.microsoft.com/en-us/troubleshoot/sql/releases/download-and-install-latest-updates	
--https://sqlserverupdates.com/
--https://www.brentozar.com/archive/2021/06/how-to-patch-sql-server/

-- samples code from MIcrosoft
--https://docs.microsoft.com/en-us/samples/browse/?redirectedfrom=TechNet-Gallery&languages=tsql


--*****Server Performance and Activity Monitoring
--https://docs.microsoft.com/en-us/sql/relational-databases/performance/server-performance-and-activity-monitoring?view=sql-server-ver15
-- AZURE: https://learn.microsoft.com/en-us/azure/search/search-performance-tips	

--******Business continuity and database recovery - SQL Server
--https://docs.microsoft.com/en-us/sql/database-engine/sql-server-business-continuity-dr?view=sql-server-ver15

--******QUERY PERFORMANCE 
--performaNce center
--https://docs.microsoft.com/en-us/sql/relational-databases/performance/performance-center-for-sql-server-database-engine-and-azure-sql-database?view=sql-server-ver15
--https://sqlperformance.com/?s=wait+stat
--https://www.mssqltips.com/sql-server-webcasts/
--https://www.sqlshack.com/category/sql-database-development/


-- sql troubleshooting
-- start here > https://docs.microsoft.com/en-us/troubleshoot/sql/performance/blocked-column-populated-latch-waits
--  https://support.solarwinds.com/SuccessCenter/s/article/SQL-Server-Wait-Types?language=en_US
--https://docs.microsoft.com/en-us/troubleshoot/sql/welcome-sql-server ---you have to find your way to troubleshoot
--https://docs.microsoft.com/en-us/troubleshoot/sql/performance/understand-resolve-blocking
--understand row Row Versioning https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms175492(v=sql.105)?redirectedfrom=MSDN
-- https://BrentOzar.com/go/rcsi OR -- https://www.brentozar.com/archive/2013/01/implementing-snapshot-or-read-committed-snapshot-isolation-in-sql-server-a-guide/
Read Committed Snapshot Isolation RCSI “Readers don’t block writers, writers don’t block readers, but writers still block writers.” 
	if I may, RCSI doesn't apply to writers VS writers; you still have the READ COMMIT in it. RCSI is using SNAPSHOT ie before your query start. 
	OK when reading small chunck of data. the NOLOCK has no effect on writers but on readers and you end up with no commited data in your read data. 
	it won't wait on anyone still the amount of data you request matters either way. not mention not well-writing query.
	session transaction level prevail and begin transaction will hold the lock anyway
1. SNAPSHOT (easy on/off for your session)and 
2. READ COMMITTED SNAPSHOT isolation(not use locks to protect the data)
-- ENABLE with ALTER DATABASE TestBello  SET ALLOW_SNAPSHOT_ISOLATION ON  
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
SELECT * FROM dbo.Orders;


--query processing
--https://docs.microsoft.com/en-us/sql/relational-databases/query-processing-architecture-guide?view=sql-server-ver15
--https://docs.microsoft.com/en-us/sql/relational-databases/sql-server-guides?view=sql-server-2017

--windows log & SQL server Log to inspect or make write in them for analysis

--managing Concurrent Data Access
--https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms189130(v=sql.105)


--system dynamic view ORGANIZED even for disater recovery
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views?view=sql-server-ver15


--usefull links
https://chat.openai.com/c/2a1ba075-f115-4e9f-8d3e-14a0c50f6ee1
https://www.red-gate.com/hub/events/series/postgresql-101?utm_source=mssql&utm_medium=email&utm_campaign=postgres&utm_content=101series&utm_term=350x175?utm_content=head
https://passdatacommunitysummit.com/video-library/
https://info.crunchydata.com/register-for-postgis-day-understanding-postgres-iops-and-json-updates-in-postgres-16?ecid=ACsprvvUXBM7gdkace26Ji-SUn76BntNvuoabv3NZVpS23QfzgHOuM7D-zW_Q_W5LpL2mmV8kPKW&utm_campaign=Crunchy%20Data%20Newsletter&utm_medium=email&_hsmi=282668410&_hsenc=p2ANqtz-_M-hMGBdhHE6x3o_dBkndHtd1cWayYn1TFui6iQA0lq0WqLgs9VcUfu3q12s7VzcGkgkjOZ76wU1xpDSB8OzKQrkEkVg&utm_content=282668410&utm_source=hs_email
https://doc.ubuntu-fr.org/tutoriel/learn_unix_in_10_minutes#substitution_de_commande
https://app.slack.com/client/T1LTZ0BQV/C1MS1RA4B


	
--****CPU pressure & memory pressure: resmon, perfmon whether SQL or VM
-- https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-high-cpu-usage-issues
	--also account for the frequently run queries with high CPU, their executions count can add up and be source of your problem
	--history of blitzCache with its executions couts and CPU usage can help OR Blitz PowerBI file for history
	--make sure the VM tools managers show CPU host Vs VMs at least a way to tell i don't see pressure on your VM and i'm not busy
	-- read the vm cpu usage below: Get CPU Utilization History for last 256 minutes
-- sp_BlitzWho_Easy_Read.sql FIRST		
-- compare to connected.sql	
--compare over time "Check DBA issues from Windows OS.ps1"	
--***ref to sp_PressureDetector.sql likely over time to decide
-- it using some of the queries here and written by elder in the field.
--you should vet always
-- https://docs.microsoft.com/en-us/troubleshoot/sql/performance/troubleshoot-high-cpu-usage-issues

Performance and Resource Monitor (perfmon)
	Counter: Process/%User Time, % Privileged Time
	Instance: sqlservr
	If % User Time is consistently greater than 90 percent, the SQL Server process is causing high CPU usage

optimization: 
	- query plan examined 
	- query structure(ref cahier des charges), not created(by you to support) or suggested index(optimizer) or not covering index
	- tables carrying lot of data: reduce the volume 
	- ...


-- Get CPU Utilization History for last 256 minutes (in one minute intervals)  (Query 42) (CPU Utilization History)
-- processor time _total in perfmon
-- populate by extend event
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



	
-- ********************************MEMORY PRESSURE 
https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-memory-issues
	
select * from sys.dm_os_waiting_tasks 
where wait_type in (N'PAGELATCH_XX')


select * from sys.dm_os_wait_stats 
where wait_type in (N'PAGELATCH_XX')

--mesure pressure using powershell and log it over time on each server and ask why it is high if noted
https://www.mssqltips.com/sqlservertip/5114/sql-server-performance-troubleshooting-system-health-checklist/
output pushed in "check_instance.ps1"

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

--Determining page life expectancy : has to be compare between 2 executions like for any of them in dm_os_performance_counters
SELECT 'Determining page life expectancy',
CASE instance_name WHEN '' THEN 'Overall' ELSE instance_name END AS NUMA_Node, cntr_value AS PLE_s
FROM sys.dm_os_performance_counters    
WHERE counter_name = 'Page life expectancy';


set statistics io, time, profile on

set statistics profile off

set  noexec off

set showplan_text on

-- https://www.brentozar.com/pastetheplan/
-- https://statisticsparser.com/

select * from sys.dm_os_performance_counters 
--order by counter_name
where counter_name in ('Batch Requests/sec', 'SQL Compilations/sec' , 'SQL Re-Compilations/sec') --and 
--where counter_name like '%time%'

--select * FROM sys.dm_os_performance_counters order by wait_type -- https://support.solarwinds.com/SuccessCenter/s/article/SQL-Server-Wait-Types?language=en_US
----------------------------------------------------------------------------------------------------------------
-- all your query wait or not, set options, reads, transactions_isolation_level, deadlock_priority, memory, plan
select * from sys.dm_exec_requests
----------------------------------------------------------------------------------------------------------------


---********************************** CPU pressure
	--by OS "counter at Check DBA issues from Windows OS.ps1" 
select * from sys.dm_os_waiting_tasks  ---https://support.solarwinds.com/SuccessCenter/s/article/SQL-Server-Wait-Types?language=en_US
where wait_type in (N'CXPACKET', N'SOS_SCHEDULER_YIELD', N'THREADPOOL', N'CMEMTHREAD')


select * from sys.dm_os_wait_stats 
where wait_type in (N'CXPACKET', N'SOS_SCHEDULER_YIELD', N'THREADPOOL', N'CMEMTHREAD')


SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2))
AS [%signal (cpu) waits],
CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2))
AS [%resource waits] 
FROM sys.dm_os_wait_stats OPTION (RECOMPILE);


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


---********************************** Disk pressure

-- disk peformance:diskspd, Crystal Mark, IOmeter
-- https://blog.purestorage.com/purely-technical/what-is-sql-servers-io-block-size/
--*****Operation -> IO Block size
-- ----log 512bytes  -> 60 KB
-- ----checkpoint/Lazywriter -> 8K-1MB
-- ----Read-Ahead scans -> 128KB-512KB
-- ----Bulk Loads -> 256 KB
-- ----Backup/Restore -> 1MB
-- ----Columnstore Read-Ahead -> 8MB
-- ----File Initizialization -> 8MB
-- ----In memory checkpoint 1MB

-- https://docs.microsoft.com/en-us/azure-stack/hci/manage/diskspd-overview
-- https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/dn894707(v=ws.11)
-- go to "Step 3: Run DiskSpd trial runs, and tune DiskSpd parameters" in above link to see action,meaning, how to decide
-- in powershell:  .\DiskSpd.exe /? #from its folder
-- in bat file, put : 
-- 	rem warm up 300 run for 30s
--	diskspd.exe -c100G -t24 -si64K -b64K -w70 -d600 -W300 -L -o12 -D -h u:\bello\testfile.dat > 64KB_Concurent_Write_24Threads_12OutstandingIO.txt
-- go look "diskPerformanceTested.ps1" in powershell directory

select * from sys.dm_os_waiting_tasks 
where wait_type in (N'PAGEIOLATCH_XX', N'WRITELOG', N'ASYNC_NETWORK_IO')


select * from sys.dm_os_wait_stats 
where wait_type in (N'PAGEIOLATCH_XX', N'WRITELOG', N'ASYNC_NETWORK_IO')

-- Virtual file statistics:  high volumes of reads or writes, and IO latencies
SELECT DB_NAME(vfs.database_id) AS database_name ,
 vfs.database_id ,
 vfs.file_id ,
 io_stall_read_ms / NULLIF(num_of_reads, 0) AS avg_read_latency ,
 io_stall_write_ms / NULLIF(num_of_writes, 0)
 AS avg_write_latency ,
 io_stall_write_ms / NULLIF(num_of_writes + num_of_writes, 0)
 AS avg_total_latency ,
 num_of_bytes_read / NULLIF(num_of_reads, 0)
 AS avg_bytes_per_read ,
 num_of_bytes_written / NULLIF(num_of_writes, 0)
 AS avg_bytes_per_write ,
 vfs.io_stall ,
 vfs.num_of_reads ,
 vfs.num_of_bytes_read ,
 vfs.io_stall_read_ms ,
 vfs.num_of_writes ,
 vfs.num_of_bytes_written ,
 vfs.io_stall_write_ms ,
 size_on_disk_bytes / 1024 / 1024. AS size_on_disk_mbytes ,
 physical_name
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
 JOIN sys.master_files AS mf ON vfs.database_id = mf.database_id
 AND vfs.file_id = mf.file_id
ORDER BY avg_total_latency DESC

--set statistics IO, TIME on


-- ***query profiling  information about execution plans, namely row count, CPU and I/O usage.
--SET STATISTICS XML ON
--SET STATISTICS PROFILE ON
------search for operators which create the issue
--Live Query Statistics for SQL 2014(12.x) and above
----1. execute the query once
----2. in Activity monitor, select the query -> right click -> show Live Execution Plan
------https://docs.microsoft.com/en-us/sql/relational-databases/performance/live-query-statistics?view=sql-server-ver15
--wait types for a session: sys.dm_exec_session_wait_stats, sys.dm_os_wait_stats => refer to WaitingTasks.sql


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
dynamic managements views (select 'sessions blocking other, ACTIVE/executing(sys.dm_exec_requests) queries & sql text' in "Connected 3.0.sql")
Performance Monitor, perform
SSMS reports, Live stattistics, data-rich map, extended events, Activity Monitor
sp_BlitzWho(better than sp_who isActive, +waits, snif, QUERY HASH, PLAN, Free cache ...), sp_BlitzCache, Power BI Dashboard

	

	
--***TUNING
set statistics io, time on
set statistics profile on
set showplan_all on
set showplan_text on
set noexec on
DBCC SHOW_STATISTICS ('atable','an_index') with STAT_HEADER -- 'DBCC for a table indexes.sql'
DBCC DROPCLEANBUFFERS;     -- Flush data cache or buffer pool
DBCC FREEPROCCACHE;        -- Remove all execution plans/query plan cache

CHECKPOINT;                -- Flush dirty pages
DBCC FREESYSTEMCACHE ('ALL'); -- Releases all unused cache entries from all caches

	
	

--stats on a table: statistic for a table indexes.sql
SELECT sp.stats_id,  name,  filter_definition, last_updated, 
       rows, rows_sampled, steps, unfiltered_rows, modification_counter
 FROM sys.stats AS stat
     CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
WHERE stat.object_id = OBJECT_ID('APPS.BillableUnits');

UPDATE STATISTICS atable; -- may not be usable till there is a change in data
UPDATE STATISTICS dbo.A ix1 WITH FULLSCAN, PERSIST_SAMPLE_PERCENT = ON; -- on not available on all sql server version

CREATE STATISTICS statName ON table(col1, col2) WITH FULLSCAN
DROP STATISTICS table.statName


--io latency
SELECT *
FROM sys.dm_io_virtual_file_stats(DB_ID('AdventureWorks2014'), NULL) divfs
ORDER BY divfs.io_stall DESC;

--WHO IS DOIN WHAT REFER TO CONNECTED.SQL

-- fragmentation ref to fragmentedIndex.sql



SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; 
--set transaction isolation level read uncommitted

-- SET LOCK_TIMEOUT 2000 -- in milliseconds -- If another query does not release the lock in 2000 => error msg 1222
-- SELECT @@LOCK_TIMEOUT

SET XACT_ABORT ON --rollback the tran is certain, batch stop (ON) vs statement stop (OFF)
BEGIN TRY
    BEGIN TRAN
		  EXEC(@query)
    COMMIT TRAN
END TRY
BEGIN CATCH
    IF @@TRANCOUNT <> 0 
    BEGIN
	   ROLLBACK TRAN
	   --RAISERROR ( 'msg', 16, 1 )
	   THROW; -- re raise error from begin try
	   RETURN -1
    END
    ELSE
	   RETURN 0
END CATCH

SET XACT_ABORT OFF --auto rollback disabled



