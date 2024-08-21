
-- Setup: big table with big index -- sp_WhoIsActive -- live monitoring
-- https://www.brentozar.com/archive/2015/01/testing-alter-index-rebuild-wait_at_low_priority-sql-server-2014/
-- https://docs.microsoft.com/en-us/sql/t-sql/statements/create-index-transact-sql?view=sql-server-ver16
--1 RESUMABLE/WAIT_AT_LOW_PRIORITY INDEX APPLY IN ALTER (2014+) CREATE (MANAGED INSTANCE, AZURE DATABASE,2019+)
--2 WAIT_AT_LOW_PRIORITY won't save your day but ABORT_AFTER_WAIT will
-- status with SELECT * FROM  sys.index_resumable_operations 
--3 to resume at will with 
ALTER INDEX id_datecreated on Sales.Orders RESUME 
WITH(MAX_DURATION  = 2) -- to respect maintenance windows
--without it WAIT_AT_LOW_PRIORITY? even nolock will be in queue waiting 


ALTER INDEX id_datecreated on Sales.Orders REBUILD
WITH (
ONLINE = ON (WAIT_AT_LOW_PRIORITY (MAX_DURATION = 5 MINUTES, ABORT_AFTER_WAIT = SELF)) 
, FILLFACTOR = 95
, RESUMABLE = ON
, MAX_DURATION  = 2
)

ALTER INDEX ix_LockBoxRemarkDetail_LbxID_inc_20220427 on dbo.LockBoxRemarkDetail RESUME 
WITH(MAX_DURATION  = 2)

SELECT * FROM  sys.index_resumable_operations 

set statistics profile off

EXECUTE dba.dbo.IndexOptimize
@Databases = 'WideWorldImporters',
@FragmentationLow = NULL,
@FragmentationMedium = NULL,
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@indexes = 'Sales.Orders',
@MaxDOP = 8,
--@FillFactor - fill factor in sys.indexes is used.
--@UpdateStatistics - Do not perform statistics maintenance.
@Resumable = 'Y', -- online index operation is resumable
@WaitAtLowPriorityMaxDuration = 1,  -- in minutes 
@WaitAtLowPriorityAbortAfterWait = 'SELF', -- Abort the online index rebuild operation after 5min
@TimeLimit = 10, -- in seconds ie 2hours  1350s = 23min -- ie no commands are executed
@LogToTable = 'Y',
@Execute = 'Y'



SELECT session_id AS SPID
	,command
	,a.TEXT AS Query
	,start_time
	,percent_complete
	,dateadd(second, estimated_completion_time / 1000, getdate()) AS estimated_completion_time
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
