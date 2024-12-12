set transaction isolation level read uncommitted
set nocount on

SELECT create_date ' last time the server is restarted' FROM sys.databases WHERE name = 'tempdb';
select database_id, name, is_parameterization_forced, is_query_store_on, compatibility_level,is_trustworthy_on, snapshot_isolation_state_desc,recovery_model_desc,
is_auto_create_stats_on, is_auto_update_stats_on, is_concat_null_yields_null_on, is_encrypted, two_digit_year_cutoff, containment_desc,
create_date
 from sys.databases
 WHERE [database_id] > 4


 --know your server 
 exec [RmsAdmin].dbo.[sp_Blitz] @checkServerInfo = 1


 SELECT SERVERPROPERTY('ErrorLogFileName') AS 'Error log file location';
SELECT SERVERPROPERTY('IsSingleUser') IsSingleUser
SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') IsIntegratedSecurityOnly
SELECT SERVERPROPERTY('IsHadrEnabled') IsHadrEnabled -- Always On availability groups is enabled on this server instance.
SELECT SERVERPROPERTY('HadrManagerStatus') HadrManagerStatus -- Indicates whether the Always On availability groups manager has started.
SELECT SERVERPROPERTY('IsClustered') IsClustered

SELECT
 SERVERPROPERTY('MachineName') AS ComputerName,
 SERVERPROPERTY('ServerName') AS InstanceName,
 SERVERPROPERTY('Edition') AS Edition,
 SERVERPROPERTY('ProductVersion') AS ProductVersion,
 SERVERPROPERTY('ProductLevel') AS ProductLevel;
GO
select * from sys.configurations where name like 'max%'
--select * from sys.tcp_endpoints  where name like 'max%'

SELECT [configuration_id], [name], [value], [value_in_use]
FROM rmsAdmin.[sys].[configurations] where name like 'max%'

  
 --options
; with OPTION_VALUES as (
select
optionValues.id,
optionValues.name,
optionValues.description,
row_number() over (partition by 1 order by id) as bitNum
from (values
-- https://learn.microsoft.com/en-us/sql/t-sql/functions/options-transact-sql?view=sql-server-ver16
(1, 'DISABLE_DEF_CNST_CHK', 'Controls interim or deferred constraint checking.'),
(2, 'IMPLICIT_TRANSACTIONS', 'For dblib network library connections, controls whether a transaction is started implicitly when a statement is executed. The IMPLICIT_TRANSACTIONS setting has no effect on ODBC or OLEDB connections.'),
(4, 'CURSOR_CLOSE_ON_COMMIT', 'Controls behavior of cursors after a commit operation has been performed. Close cursor when commit/rolback'),
(8, 'ANSI_WARNINGS', 'Controls truncation and NULL in aggregate warnings.'),
(16, 'ANSI_PADDING', 'Controls padding of fixed-length variables.'),
(32, 'ANSI_NULLS', 'Null to Null yield unknown - ON then col = null or col <> null returns 0 row'),
(64, 'ARITHABORT', 'Terminates a query when an overflow or divide-by-zero error occurs during query execution.'),
(128, 'ARITHIGNORE', 'Returns NULL when an overflow or divide-by-zero error occurs during a query.'),
(256, 'QUOTED_IDENTIFIER', 'Differentiates between single and double quotation marks when evaluating an expression.'),
(512, 'NOCOUNT', 'Turns off the message returned at the end of each statement that states how many rows were affected.'),
(1024, 'ANSI_NULL_DFLT_ON', 'Alters the session'+char(39)+'s behavior to use ANSI compatibility for nullability. New columns defined without explicit nullability are defined to allow nulls.'),
(2048, 'ANSI_NULL_DFLT_OFF', 'Alters the session'+char(39)+'s behavior not to use ANSI compatibility for nullability. New columns defined without explicit nullability do not allow nulls.'),
(4096, 'CONCAT_NULL_YIELDS_NULL', 'Returns NULL when concatenating a NULL value with a string.'),
(8192, 'NUMERIC_ROUNDABORT', 'Generates an error when a loss of precision occurs in an expression.'),
(16384, 'XACT_ABORT', 'Rolls back a transaction if a Transact-SQL statement raises a run-time error.')
) as optionValues(id, name, description)
)
select *, case when (@@options & id) = id then 1 else 0 end as setting
from OPTION_VALUES; -- from https://www.mssqltips.com/sqlservertip/1415/determining-set-options-for-a-current-session-in-sql-server/

 

 -- space is used by the version store in tempdb 
 -- Row versions must be stored for as long as an active transaction needs to access it
 -- Once every minute, a background thread removes row versions that are no longer needed and frees up the version space in tempdb
 -- https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms175492(v=sql.105)?redirectedfrom=MSDN
SELECT DB_NAME(database_id) AS database_name,
  reserved_space_kb / 1024.0 AS version_store_mb
FROM sys.dm_tran_version_store_space_usage
WHERE reserved_space_kb > 0
ORDER BY 2 DESC;

/* Previous versions of SQL don't break it out per database: */
SELECT SUM (version_store_reserved_page_count)*8/1024.0  as version_store_mb
FROM tempdb.sys.dm_db_file_space_usage

-- health check
exec [RmsAdmin].dbo.[sp_Blitz] 
	  @CheckProcedureCache = 1 /*top 20-50 resource-intensive cache plans and analyze them for common performance issues*/, 
	  @CheckUserDatabaseObjects = 0/* 1 if you control the db objects*/,
	  @IgnorePrioritiesAbove = 500 /*if you want a daily bulletin of the most important warnings, set 50 */,
	  --@CheckProcedureCacheFilter = 'CPU' --- | 'Reads' | 'Duration' | 'ExecCount'
	  @CheckServerInfo = 1 

--memory dump querys
--how many times, it happened
SELECT filename, creation_time, convert(decimal(10,1),size_in_bytes/1000000.0) as size_in_MB
FROM sys.dm_server_memory_dumps AS dsmd
ORDER BY creation_time DESC;

exec [RmsAdmin].dbo.[sp_Blitz] @outputtype = 'MARKDOWN' -- notes for order

--instant performance check -- + links to wait stats meanings on sqlskills
exec [RmsAdmin].[dbo].[sp_BlitzFirst] --@help = 1 
				 @SinceStartup = 1 --go beyond 5 second snapshot
				 ,@expertmOde = 1

--live activity checker - what’s really happening - Forget sp_Who and sp_Who2---replace Activitor monitor
exec [RmsAdmin].[dbo].[sp_BlitzWho_test] @ExpertMode = 1 --cached_parameter_info(sniffing),top_session_waits, tempdb_allocations, workload_group, resource_pool kill 2902
  --,@OutputDatabaseName = 'RmsAdmin' 
  --,@OutputSchemaName = 'dbo'  
  --,@OutputTableName = 'BlitzWho'
  , @sortOrder= 'host_name' --database_name/*Monktar added elapsed_time desc*/
						  --, request_cpu_time, elapsed_time, request_logical_reads,request_physical_reads, request_writes, grant_memory_kb kill 2620
						  --, login_name, --- [blocking_session_id], host_name

--top running in last @Seconds
exec [RmsAdmin].[dbo].[sp_BlitzFirst] @Seconds = 3600, @expertmOde = 1 -- wait ratio,top session waits, db count, size, cpu utilization, memory grant -- also provide querys parameter's
exec [RmsAdmin].[dbo].[sp_BlitzFirst] @SinceStartup = 1, @outputtype = 'Top10'

--exec [RmsAdmin].[dbo].[sp_BlitzFirst] --@help = 1 
--	    @OutputDatabaseName = 'RmsAdmin' -- output won't work with other mode, has fillfactor
--	   , @OutputSchemaName = 'dbo'
--	   , @OutputTableName = 'BlitzIndex'
--        ,@OutputTableRetentionDays = 31; 

--***wait stats cheat sheet:
--CXPACKET/CXCONSUMER/LATCH_EX: queries going parallel to read a lot of data or do a lot of CPU work. Sort by CPU and by READS.
--						  set CTFP & MAXDOP to good defaults
--LCK%: locking, so look for long-running queries. Sort by DURATION, and look for the warning of "Long Running, Low CPU." That's probably a query being blocked.
	    -- look for aggressive indexes: sp_BlitzIndex @GetALLDatabases = 1
--PAGEIOLATCH: reading data pages that aren't cached in RAM. Sort by READS.
	    --	look for high-value missing indexes: sp_BlitzIndex @GetALLDatabases = 1
--RESOURCE_SEMAPHORE: queries can't get enough workspace memory to start running. Sort by MEMORY GRANT, although that isn't available in older versions of SQL.
--SOS_SCHEDULER_YIELD: CPU pressure, so sort by CPU.
--WRITELOG: writing to the transaction log for delete/update/insert (DUI) work. Sort by WRITES.

-- Login a table
--EXEC RmsAdmin.dbo.sp_BlitzFirst 
--  @OutputDatabaseName = 'DBADB', 
--  @OutputSchemaName = 'dbo', 
--  @OutputTableName = 'BlitzFirst',
--  @OutputTableNameFileStats = 'BlitzFirst_FileStats',
--  @OutputTableNamePerfmonStats = 'BlitzFirst_PerfmonStats',
--  @OutputTableNameWaitStats = 'BlitzFirst_WaitStats',
--  @OutputTableNameBlitzCache = 'BlitzCache',
--  @OutputTableNameBlitzWho = 'BlitzWho'
--  @OutputTableRetentionDays = 31; 
  

--exec [RmsAdmin].dbo.sp_WhoIsActive   
--		    @show_own_spid = 0
--		  , @get_task_info =2 /* 1 ie lightweight. task-based metrics : current wait stats, physical I/O, context switches, and blocker information*/
--		  , @get_avg_time = 1
--		  , @get_locks = 1
--		  --, @get_transaction_info = 1
--		  --, @delta_interval = 0 -- Interval in seconds to wait before doing the second data pull
--		  , @find_block_leaders =1
--		  , @show_sleeping_spids = 0 --1 sleeping with open transaction
--		  --, @get_plans = 1 
--		  , @sort_order = '[blocked_session_count] desc, [Used_Memory] desc, [open_tran_count] desc, [CPU] desc' 
--		  --, @destination_table = ''
--		  --, @output_column_list = '[col1][col2]...'


--exec [RmsAdmin].dbo.sp_WhoIsActive @get_locks = 1;
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
		  ,@get_additional_info = 1
		  , @sort_order = '[blocked_session_count] desc, [Used_Memory] desc, [CPU] desc, [open_tran_count] desc' 
		  --, @destination_table = ''
		  , @output_column_list = '[dd%][session_id][blocked_session_count][login_name][host_name][database_name][program_name][used_memory][cpu%][reads%][writes%][wait_info][physical%][sql_text][tasks][sql_command][tran_log%][temp%][context%][query_plan][locks][%]'-- '[col1][col2]...'



 -- index issues 
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' ,@Mode = 0
--index usage details
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' -- or , @GetAllDatabases = 1
	   , @Mode = 2 
	   , @OutputDatabaseName = 'RmsAdmin' -- output won't work with other mode, has fillfactor
	   , @OutputSchemaName = 'dbo'
	   , @OutputTableName = 'BlitzIndex'

--EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' , @Mode = 2, @sortOrder = 'rows'-- or size
-- ***Missing indexes
---- instance of steps:
--1. log index usage in a table and use blitz dashboard for history usage
--2. run sp_BlitzIndex for the table and compare missing indexes, list of index consolidation sp, and hist form dashboard
--3. redefine/consolidate to account for missing indexes based on the usage
SELECT max(captureDate) lastCapture from RmsAdmin.dbo.BlitzMissingIndex
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' ,@Mode = 3
-- Expert, by priority
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' ,@Mode = 4
--on one table
EXEC RmsAdmin.dbo.sp_BlitzIndex_OrderOfColumns @DatabaseName='MedRx', @SchemaName='dbo', @TableName='Payments', @SortOrder = N'reads_per_write', @SortDirection = N'asc' 

--Blitz dashboard
--Example of Steps:
--1. from PowerBI on blitz, on tab "Overview" I noticed the spike comparing "Batch Request" for Fridays
--2. then select each Wait category to find that was Buffer IO around 8:15am
--3. then select the bar of batch request from the grah "Batch Request and wait stats" to filter the graph "Resource Intensive Queries"
--4. then hourOfDay is restricted to 8 to 8
--5. then from that list, I went in tab "Queries over time" and filter each query(from previous step) to read (ie IO) over the time. I have to add a graph just for the reads

--design indexes refer to https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide?view=sql-server-ver16#General_Design
-->order onsider the order of the columns if the index contains multiple columns. The column that is used 
----in the WHERE clause in an equal to (=), greater than (>), less than (<), or BETWEEN search condition, or 
----participates in a join, should be placed first. Additional columns should be ordered based on their level of distinctness, that is, 
----from the most distinct(selective) to the least distinct.
----the PK will be always include at the end of the non clustered index
----??? the selectivity  has to consider 
----			 - the # of rows left by your 1st chosen key column 
----            - the # of rows left to read when the next key column is involved
----			 - tip: check the distribution of data, count rows returned by each table with its columns in the query
----The index key order specified by the user when they create a nonclustered index is always honored
----optimizer won't use index if the column is NOT first key in the index unless cost dictates otherwise. 
----Remember it can combine indexes and/or cost(size of index) to return data  
----??? to be checked: less indexes imply that you use the existing frequent filter to get the data before applying other filter



--Dedupe
--Eliminate
--Add from missisng indexes
--Tune: indexes for specific queries from sp_BlitzCache: EXEC sp_BlitzCache @OnlyQueryHashes = '0xCAEAE0C9929C7B7A'; --queryhash from JoinKeyBlitzCache in BlitzCache table
--Heaps:  create clustered indexes


----it calculates your current worst-case for Recovery Point Objective and Recovery Time Objective
----"High Availability and Disaster Recovery Planning.pdf" in FirstResponderKit
--EXEC [RmsAdmin].dbo.sp_BlitzBackups


--sp_BlitzCache: query to tune -- a plus if log when sp_BlitzFirst is run
---------only rely on if priority != 1 
EXEC [RmsAdmin].dbo.sp_BlitzCache ---is included when run Blitzfirst
  @OutputDatabaseName = 'RmsAdmin', 
  @OutputSchemaName = 'dbo', 
  @OutputTableName = 'BlitzCache'


--live activity checker - what’s really happening - Forget sp_Who and sp_Who2---replace Activitor monitor
exec [RmsAdmin].[dbo].sp_BlitzWho @ExpertMode = 1 --cached_parameter_info(sniffing),top_session_waits, tempdb_allocations, workload_group, resource_pool
  --@OutputDatabaseName = 'RmsAdmin', 
  --@OutputSchemaName = 'dbo', 
  --@OutputTableName = 'BlitzWho'
exec [RmsAdmin].[dbo].sp_WhoIsActive
exec [RmsAdmin].[dbo].sp_BlitzLock --can save deadlock graph as "aname.xdl" and open it with Plan Explorer. solve at SP, table level by 
--																					   reducing reads/write indexes
--																					   when transaction starts not for reading part
-- use https://www.mssqltips.com/sqlservertip/6456/improve-sql-server-extended-events-systemhealth-session/
-- let you keep log longer
--or log sp_BlitzLock into a table, it can be point to a specific event

--Look for # executions/min 
-- Query Type = "statement" easy to tune 

--chance last 60 min -- !!!ATTENTION TOP 1 Plan Cache Information!!! ---------only rely on if priority != 1 
EXEC [RmsAdmin].dbo.sp_BlitzCache @MinutesBack = 40, @Top = 100,   @DatabaseName='Medrx'
EXEC [RmsAdmin].dbo.sp_BlitzCache @MinutesBack = 40, @Top = 100,   @DatabaseName='RMSOCR'
EXEC [RmsAdmin].dbo.sp_BlitzCache @MinutesBack = 40, @Top = 100,   @DatabaseName='reconciliation'
		  --@StoredProcName = 'TR_ExtractProcedureOrRevenueCode' --0-- @DurationFilter = 5

--exec [RmsAdmin].dbo.sp_BlitzCache @OnlyQueryHashes = 0x53BCBB36510E6C00 j?1hg2ruR$2010
----exec [RmsAdmin].dbo.sp_BlitzCache_new @help = 1

-- @SortOrder: "CPU", "Reads", "Writes", "Duration", "Executions", "Recent Compilations", "Memory Grant", "Spills".
-- then look at "Warnings" column from sp_BlitzCache
-- then "Cached Execution Parameters" to get actual execution plan
-- make sure to run the query with the same parameters get from sp_BlitzCache to start tuning

EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'CPU',    @DatabaseName='Medrx' -- CXPACKET then sort by reads 
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'CPU',    @DatabaseName='Medrx' -- SOS_SCHEDULER_YIELD
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'READS',    @DatabaseName='Medrx' -- PAGEIOLATCH reading data pages not in RAM
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'WRITES',    @DatabaseName='Medrx' -- WRITELOG
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'DURATION',    @DatabaseName='Medrx' -- LCK% ie Look for "Long Running, Low CPU"
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'MEMORY GRANT',    @DatabaseName='Medrx' -- RESOURCE_SEMAPHORE ie queries not enough workspace to start running

--***wait stats cheat sheet: noted help also "Waits stats Tasks.sql"
--CXPACKET/CXCONSUMER/LATCH_EX: queries going parallel to read a lot of data or do a lot of CPU work. Sort by CPU and by READS.
--						  set Cost Threshold For Parallelism CTFP & MAXDOP to good defaults
--						  for instance when MAXDOP set to 5, it may be just 2 is used and 3 are waiting => this wait high
--LCK%: locking, so look for long-running queries. Sort by DURATION, and look for the warning of "Long Running, Low CPU." That's probably a query being blocked.
	    -- look for aggressive indexes: sp_BlitzIndex @GetALLDatabases = 1
--PAGEIOLATCH: reading data pages that aren't cached in RAM. Sort by READS. look for high-value missing indexes: sp_BlitzIndex @GetALLDatabases = 1
	    --a thread is waiting for the read of a data file page from disk to complete
	    --is used to synchronize physical access to pages when they're read from or written to disk.
--RESOURCE_SEMAPHORE: queries can't get enough workspace memory to start running. Sort by MEMORY GRANT, although that isn't available in older versions of SQL.
--SOS_SCHEDULER_YIELD: CPU pressure, so sort by CPU.
	    --a thread was able to execute for its full thread quantum and so voluntarily yielded the scheduler, moving to the bottom of the Runnable Queue -- https://www.sqlskills.com/help/waits/sos_scheduler_yield/
--WRITELOG: writing to the transaction log for delete/update/insert (DUI) work. Sort by WRITES.
	    --a thread is waiting for a log block to be written to disk by an asynchronous I/O

-- PAGELATCH (latch on a data page OR index page) is a thread-synchronization mechanism. 
--				page contention is a result of waiting on thread to release the exclusive mode on a page needed by others
--			 It's used to synchronize short-term physical access to database pages that are located in the Buffer cache./data file page in memory
--			share mode prevent CHANGES in data structure VS exclusive mode prevent ACCESS to data structure
--			**in tempdb, PFS page to track allocation and SGAM to track the data extents used by allocation;  
--					drop and create temp object may lead to contention: small temporary table cache; create more datafile helps ie many tables cache available not one
--          **as Insert hotspot, new many rows(identity values) of a table to be fitted on same page a leaf level, last page of that same clustered index in memory; too much thread to do so lead to the contention
------PAGELATCH_UP or PAGELATCH_EX need to modify datafile; if not possible they show as waits
--	   https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/resolve-pagelatch-ex-contention
--	   https://sqlperformance.com/2015/10/sql-performance/knee-jerk-wait-statistics-pagelatch



-- CHECK POWER BI DASHBORD AT 8am AND 5pm

--Query plan: top to bottom, right to left find where actual x10000 than estimate  numbers 
--			 is plan specific to a parameter value ? yes then attention make it for just a specific paramater
--			 look for stats on table, indexes, parameters sniffing, use recompile -- sp with recompile, query OPTION(recompile) 
--			 use only needed columns, gather only rows needed
--			 with no expand on indexed views
--			 update stats on the table, indexes
-- in case a query behave differently variable versus constant or suddenly become slow, compare existing plan and the plan with recompile

 set transaction isolation level read uncommitted
set nocount on

-- study indexes on a table
exec sp_SQLskills_helpindex @objname= LockboxCHKAdjustments, @IncludeListOrdered = 1, @thresholdOfUnUsed = .019, @HasMeaning = 0
-- FK to know if we can disable or drop the index if any appaear enabled here, don't proceed
	           select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('LockboxCHKAdjustments'),1)
			 union all
			 select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('LockboxCHKAdjustments'),1)

exec sp_SQLskills_ListIndexForConsolidation @ObjName = LockboxCHKAdjustments

EXEC sp_SQLskills_ListIndex  '[dbo].[LockboxDocumentTracking]'

exec sp_SQLskills_helpindex @objname= LockboxCHKAdjustments, @IncludeListOrdered = 1, @thresholdOfUnUsed = .019, @HasMeaning = 1
exec sp_SQLskills_helpindex @objname= Exceptions,  @indnameKey = 'IX_Exceptions_dtException'
exec sp_SQLskills_ListIndexForConsolidation @ObjName = Exceptions,  @KeysFilter = '[LbxID]'
exec sp_SQLskills_ListIndexForConsolidation @ObjName = Exceptions, @KeysFilter = '[flsid]' --- , @expandGroup = 0
exec sp_SQLskills_ListIndexForConsolidation @ObjName = exceptions, @indnameKey ='[IX_Mbxbackfilehistory_Lbxid_inc_20220427]' , @isShowSampleQuery = 1
--exec sp_SQLskills_ListIndexForConsolidation @ObjName = exceptions, @excludeRatioReadWrite = .019, @KeysFilter = '[cdException]', @isShowSampleQuery = 1  

--hist, index isssue, read/write
EXEC RmsAdmin.dbo.sp_BlitzIndex    @DatabaseName='MedRx', @SchemaName='dbo', @TableName='PayerProvider'


--***** Columnstore 

clustered Columnstore indexes have 3 advantages for select query performance:

Eliminating row groups (reading less rows – but it’s really hard to get “segment elimination” on anything but one column)
Eliminating column segments (reading less columns in a wide table)
Batch execution mode (which you can get in 2019 with rowstore indexes anyway)
However, they have some big drawbacks:

Deleted rows are left in place, reducing advantage #1
Update performance is terrible
Index rebuilds & reorgs don’t fix those first two: if your workload does deletes & inserts, and you want advantage #1, you’re going to need to reload the entire table from scratch periodically
Background maintenance processes (that we didn’t explore) are changing our table storage on a schedule we may not be able to predict or control
Repetitive data compresses very well, but unique data – especially data that requires dictionaries, like dates & strings – does not compress well
Different queries (like TOP vs MAX) get different performance gains
So with that in mind, let’s say you’re looking at putting a clustered columnstore index on a table. ColumnScore.com has a quiz to help determine whether it’s a good idea. Try it for the dbo.Users table, think about how some of the other Stack Overflow tables might have fared, and then try your own tables from your day job.


Nonclustered columnstore indexes:

* Are better for transactional (OLTP) tables
  that have inserts, updates, and deletes

* Let you pick which columns you want to index
  (but you don't have to worry about column order)

* Get you great compression ratios

* If you run analytical-style queries on those
  rarely-updated columns, they can help

* But honestly, Users still isn't a good fit:
  it's tiny, and we'd still have to deal with
  index maintenance as we insert/delete rows.

-- QUERY IN CACHE USING AN INDEX
SELECT TOP 20 'IX_Mbxbackfilehistory_Lbxid_inc_20220427' indname, querystats.execution_count, querystats.last_execution_time 
    , SUBSTRING(sqltext.text
		  , (querystats.statement_start_offset / 2) + 1
		  , (CASE querystats.statement_end_offset WHEN -1 THEN DATALENGTH(sqltext.text) 
			 ELSE querystats.statement_end_offset  END - querystats.statement_start_offset) / 2 + 1) AS sqltext
    , sqltext.text, querystats.execution_count, querystats.total_logical_reads, querystats.total_logical_writes 
    , sqltext.*
FROM sys.dm_exec_query_stats as querystats
CROSS APPLY sys.dm_exec_text_query_plan (querystats.plan_handle, querystats.statement_start_offset, querystats.statement_end_offset) as textplan
CROSS APPLY sys.dm_exec_sql_text(querystats.sql_handle) AS sqltext 
WHERE CHARINDEX('IX_Mbxbackfilehistory_Lbxid_inc_20220427', textplan.query_plan, 1)> 0



  
--  SELECT f.database_id, f.name, f.file_id, volume_mount_point
--, v.total_bytes/1000000000 as total_GigaBytes, v.available_bytes/1000000000 as FreeGigaBytes,Cast(f.size * 8. / 1024 AS DECIMAL(10,2)) AS Size  
--FROM sys.master_files AS f  
--CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) v  
--where f.database_id = 9


--DECLARE @today DATETIME,@db INT;

--SELECT @today = convert(DATETIME, convert(CHAR(10), GETDATE(), 110), 110)

----select * from [dbo].[RMSDaily_Storage]
--select Collection_Time, Drive, FreeSpace_GB, TotalSpace_GB, convert(smallint,100*(FreeSpace_GB / TotalSpace_GB)) as '% Free'
--    from [dbo].[RMSDaily_Storage] 
--where Collection_Time >= dateadd(yy,-1,getdate())
----and FreeSpace_GB = .75 * TotalSpace_GB
----and FreeSpace_GB = .50 * TotalSpace_GB
--order by Collection_Time


SELECT tab.TABLE_NAME,
    Col.Column_Name as 'PRIMARY KEY COLUMN'
FROM
    INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab,
    INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE Col
WHERE
    Col.Constraint_Name = Tab.Constraint_Name
    AND Col.Table_Name = Tab.Table_Name
    AND Constraint_Type = 'PRIMARY KEY'
    and (Tab.Table_Name like '%PaySplitIDRef%' or Col.Column_Name like '%PaySplitIDRef%')
order by tab.TABLE_NAME

--EXEC sp_MSforeachtable 'TRUNCATE TABLE ?'

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME()  SELECT * FROM SYS.tables WHERE NAME LIKE ''%AnalysisOfE835ClaimDetail%'' order by name;'

--preferred sp_ineachdb developed by Aaron Bertrand as an alternative to sp_MSforeachdb.
EXEC sp_ineachdb @command = N'SELECT DB_NAME()  SELECT * FROM SYS.tables WHERE NAME LIKE ''%sync_tablenames%'' order by name;'
--sp module search
EXEC sp_ineachdb @command = N'SELECT DB_NAME()  select * from sys.all_sql_modules where definition like ''%sp_delete_categorization_profile%'' ;'
EXEC sp_ineachdb @command = N'SELECT DB_NAME()  select * from sys.objects where name like ''%sp_delete_categorization_profile%'' ;'

--3ways
-- select definition from sys.all_sql_modules where definition like ''%tableName%'
--sp_helptext 'tableName'
--SELECT OBJECT_DEFINITION(OBJECT_ID('tableName'))


EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME(); select distinct OBJECT_NAME(object_id) nom,name  
from sys.columns where name like ''%account%'' order by nom'

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME(); 
SELECT TOP 50 st.text, qs.*
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
where st.text like ''%BlitzIndex%''
'

exec sp_helptext'PopulateLoaderState'
exec sp_helptext'sp_SQLskills_ListIndexForConsolidation'

select * from SystemReceiptDetail

EXEC dbo.sp_BlitzIndex @DatabaseName='MedRx', @SchemaName='dbo', @TableName='extractOutput';

exec sp_SQLskills_ListIndexForConsolidation  'dbo.extractOutput'  ---, '[StatusID]'


exec sp_SQLskills_helpindex extractOutput
--exec sp_SQLskills_finddupes HSBankingPartner
--exec sp_SQLskills_finddupes HSLockboxAccount


EXEC sp_SQLskills_ListIndex exceptions

select top 5 ExpectedIndexName from LockboxDocumentTracking
where ExpectedIndexName  is not null

--exec sp_SQLskills_ListIndexForConsolidation 'billingrevamp.billingtransactionrevamp', '[billingdate]'

--exec sp_SQLskills_ListIndexForConsolidation 'dbo.BankingPartner', '[id]'


--EXEC sp_SQLskills_ListIndex LockboxDocumentTracking




 