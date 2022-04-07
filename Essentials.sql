exec [RmsAdmin].[dbo].[sp_BlitzFirst] --@help = 1 look into the last VERSION OF THIS SCRIPT TO HAVE IMPROVEMENTS available 
				-- @ExpertModel = 1
				-- @SinceStartup = 1 --go beyond 5 second snapshot
-- Login a table
--EXEC RmsAdmin.dbo.sp_BlitzFirst 
--  @OutputDatabaseName = 'DBADB', 
--  @OutputSchemaName = 'dbo', 
--  @OutputTableName = 'BlitzFirst',
--  @OutputTableNameFileStats = 'BlitzFirst_FileStats',
--  @OutputTableNamePerfmonStats = 'BlitzFirst_PerfmonStats',
--  @OutputTableNameWaitStats = 'BlitzFirst_WaitStats',
--  @OutputTableNameBlitzCache = 'BlitzCache',
--  @OutputTableRetentionDays = 31;


exec [RmsAdmin].dbo.[sp_Blitz] 
	  @CheckProcedureCache = 1 /*top 20-50 resource-intensive cache plans and analyze them for common performance issues*/, 
	  @CheckUserDatabaseObjects = 0,
	  @IgnorePrioritiesAbove = 50 /*if you want a daily bulletin of the most important warnings, set*/
	  --@CheckProcedureCacheFilter = 'CPU' --- | 'Reads' | 'Duration' | 'ExecCount'
	  --@CheckServerInfo = 1 

exec [RmsAdmin].dbo.sp_WhoIsActive  
		    @show_own_spid = 0
		  , @get_task_info =2 /*task-based metrics*/
		  , @get_avg_time = 1
		  , @get_locks = 1
		  --, @get_transaction_info = 1
		  --, @delta_interval = 0
		  , @find_block_leaders =1
		  , @show_sleeping_spids = 0 --1 sleeping with open transaction
		  --, @get_plans = 1 
		  , @sort_order = '[blocked_session_count] desc, [Used_Memory] desc, [open_tran_count] desc, [CPU] desc' 
		  --, @destination_table = ''
		  --, @output_column_list = '[col1][col2]...'

-- index issues
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' ,@Mode = 0
--index usage details
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' -- or , @GetAllDatabases = 1
	   , @Mode = 2 
	   , @OutputDatabaseName = 'RmsAdmin' -- output won't work with other mode, has fillfactor
	   , @OutputSchemaName = 'dbo'
	   , @OutputTableName = 'BlitzIndex'
-- Missing indexes
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' ,@Mode = 3
--on one table
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' , @TableName = 'LockboxDocumentTrackingArchive'


--sp_BlitzCache -- a plus if log when sp_BlitzFirst is run
EXEC [RmsAdmin].dbo.sp_BlitzCache ---is included when run Blitzfirst
  @OutputDatabaseName = 'RmsAdmin', 
  @OutputSchemaName = 'dbo', 
  @OutputTableName = 'BlitzCache'
  
  SELECT TOP (1000) [LoggedDateTime]
      ,[DatabaseName]
      ,[AllocatedDataSizeMB]
      ,[UsedDataSizeMB]
      ,[AllocatedLogSizeMB]
      ,[UsedLogSizeMB]
  FROM [RmsAdmin].[dbo].[RMSMaintenanceDBSize]
  
  SELECT [ServerName],[CheckDate],[CheckID],[Priority],[FindingsGroup],[Finding],[URL],[Details],[HowToStopIt],[QueryPlan]
      ,[QueryText],[StartTime],[LoginName],[NTUserName],[OriginalLoginName],[ProgramName],[HostName]      ,[DatabaseID]
      ,[DatabaseName],[OpenTransactionCount],[DetailsInt]
  FROM [RmsAdmin].[dbo].[BlitzFirst]
  where 
  FindingsGroup  in ('Query Problems', 'Query Performance','Server Performance', 'Wait Stats') 
  UNION ALL
  SELECT [ServerName],[CheckDate],[CheckID],[Priority],[FindingsGroup],[Finding],[URL],[Details],[HowToStopIt],[QueryPlan]
      ,[QueryText],[StartTime],[LoginName],[NTUserName],[OriginalLoginName],[ProgramName],[HostName]      ,[DatabaseID]
      ,[DatabaseName],[OpenTransactionCount],[DetailsInt]
  FROM [RmsAdmin].[dbo].[BlitzFirst]
  where 
  FindingsGroup  in ('SQL Server Internal Maintenance', 'Maintenance Tasks Running', 'Server Info') 

  

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


EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME()  SELECT * FROM SYS.tables WHERE NAME LIKE ''%RecordTypes%'' order by name;'

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME(); select distinct OBJECT_NAME(object_id) nom,name  
from sys.columns where name like ''%mbhid%'' order by nom'

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME(); 
SELECT TOP 50 st.text, qs.*
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
where st.text like ''%BlitzIndex%''
'

exec sp_helptext'PopulateLoaderState'
exec sp_helptext'sp_SQLskills_helpindex'

select * from SystemReceiptDetail
EXEC dbo.sp_BlitzIndex @DatabaseName='MedRx', @SchemaName='dbo', @TableName='MbxBackfileHistory';

exec sp_SQLskills_helpindex MbxBackfileHistory
--exec sp_SQLskills_finddupes MbxBackfileHistory

exec sp_SQLskills_ListIndexForConsolidation 'dbo.LockboxDocumentTracking', '[StatusID]'

EXEC sp_SQLskills_ListIndex LockboxDocumentTracking

select top 5 ExpectedIndexName from LockboxDocumentTracking
where ExpectedIndexName  is not null

--exec sp_SQLskills_ListIndexForConsolidation 'billingrevamp.billingtransactionrevamp', '[billingdate]'

--exec sp_SQLskills_ListIndexForConsolidation 'dbo.BankingPartner', '[id]'


--EXEC sp_SQLskills_ListIndex LockboxDocumentTracking


SELECT create_date ' last time the server is restarted' FROM sys.databases WHERE name = 'tempdb';
select database_id, name, is_query_store_on, compatibility_level,is_trustworthy_on, snapshot_isolation_state_desc,recovery_model_desc,
is_auto_create_stats_on, is_auto_update_stats_on, is_concat_null_yields_null_on, is_encrypted, two_digit_year_cutoff, containment_desc,
create_date
 from sys.databases
 WHERE [database_id] > 4
