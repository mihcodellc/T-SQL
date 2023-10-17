--exec [RmsAdmin].dbo.[sp_Blitz] 
--	  @CheckProcedureCache = 1 /*top 20-50 resource-intensive cache plans and analyze them for common performance issues*/, 
--	  @CheckUserDatabaseObjects = 0/* 1 if you control the db objects*/,
--	  @IgnorePrioritiesAbove = 500 /*if you want a daily bulletin of the most important warnings, set 50 */,
--	  --@CheckProcedureCacheFilter = 'CPU' --- | 'Reads' | 'Duration' | 'ExecCount'
--	  @CheckServerInfo = 1 

-- Returns the SET options active (set) for the current connection.
--DBCC USEROPTIONS


select 'services'
select 'enabled brokers and databses' Services
SELECT is_broker_enabled, name FROM sys.databases where is_broker_enabled = 1

declare   @tm table (mail_service nvarchar(7))
insert into @tm
EXECUTE msdb.dbo.sysmail_help_status_sp;

--debug
select * from @tm

--if (select top 1 avalue from @tm) <> 'STARTED'
--    EXECUTE msdb.dbo.sysmail_start_sp

----https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sysmail-help-queue-sp-transact-sql?view=sql-server-ver16
----two queues in Database Mail: the mail queue and status queue. 
----The mail queue stores mail items that are waiting to be sent. The status queue stores the status of items that have already been sent.
---- State = state of the monitor. 
--exec msdb.dbo.sysmail_help_queue_sp  

select 'MSSQLServer, SQLServerAgent, SQLBrowser' Services
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'MSSQLServer'
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'SQLServerAgent'
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'SQLBrowser'


-- check important alerts are created. used "Add_important_SQL_Agent _Alerts.sql" to create them
-- check alert scheduled.
Select 'SQL Agent Alerts'
SELECT a.name, a.severity, a.enabled, a.delay_between_responses,a.has_notification, a.job_id, n.operator_id,  a.database_name 
FROM msdb.dbo.sysalerts a
left join msdb.dbo.sysnotifications n on n.alert_id = a.id
where enabled = 1

--  fail jobs based on scheduled period covering all your current jobs
--must worry when table 2 is not empty 

--1  
  declare @date1 int, @date2 int;
    set @date1 = convert(int,replace(convert(CHAR(10), dateadd(dd,1,GETDATE()), 112),'-','')) --20220316
    set @date2 = convert(int,replace(convert(CHAR(10), dateadd(dd,-7,GETDATE()), 112),'-','')) --20220316
      
    select @date2 'start date', @date1 'end date'
 SELECT job.name, his.step_name, his.run_status , his.run_time, his.run_date,
			CASE WHEN his.run_status = 1 THEN 'Success'  
		     WHEN his.run_status = 0 THEN 'Failure' 
			WHEN his.run_status = 2 THEN 'Retried'
			WHEN his.run_status = 3 THEN 'Cancelled'
			WHEN his.run_status = 4 THEN 'Check its steps' 
			ELSE 'Unknown' END   AS outcome_message,   
			his.run_duration as 'Duration HHMMSS', his.[message],
 his.sql_severity, his.retries_attempted, job.job_id 
	    , job.notify_email_operator_id,  his.[server]
  FROM [msdb].[dbo].[sysjobhistory] as his
  JOIN [msdb].[dbo].[sysjobs] as job on job.job_id = his.job_id
  WHERE run_date between @date2  and  @date1
  AND his.run_status IN (0/*FAILED*/,2/*RETRY*/, 3/*CANCELED*/, 5 /*unknown*/) --1 Succeeded
  --and job.name='OLA - DatabaseBackup - USER DB FULL then DBCC'
  order by run_date desc, run_time desc

    --select * from [msdb].[dbo].[sysjobs]
    --order by date_created desc



    ---2 steps outcome on last run
  select job.name, step_id, step_name, command, last_run_outcome,last_run_date [run Date (yyyymmdd)], last_run_time [Time (hhmmss)], step_id, last_run_duration [Duration (hhmmss)],
    database_name, output_file_name 
  from msdb.dbo.sysjobsteps s
  INNER JOIN [msdb].[dbo].[sysjobs] job on job.job_id = s.job_id
  where last_run_date  between @date2  and  @date1
  --and job.name='OLA - DatabaseBackup - USER DB FULL then DBCC'
  and exists (
  select 1
  FROM [msdb].[dbo].[sysjobhistory] as his
  JOIN [msdb].[dbo].[sysjobs] as j on job.job_id = his.job_id
  WHERE run_date between @date2  and  @date1
  AND his.run_status IN (0/*FAILED*/,2/*RETRY*/, 3/*CANCELED*/, 5 /*unknown*/)
  and job.job_id = j.job_id
  )
  --and last_run_outcome <> 1-- (0/*FAILED*/,2/*RETRY*/, 3/*CANCELED*/, 4, 5/*Unknown*/) --1 Succeeded 
  order by s.job_id, last_run_date desc, last_run_time desc


  --3 for jobs managed by OLA script
  SELECT 
      [DatabaseName]
      ,[SchemaName]     
      ,[ErrorNumber]
      ,[ErrorMessage]
	 , StartTime, Command
  FROM [maintenance].[dbo].[CommandLog]
  where StartTime between dateadd(dd,-45,GETDATE())  and  GETDATE() 
  and ErrorNumber >0
  --and Command like 'DBCC%'
  order by StartTime desc

   select 'DBCC CHECKDB in progress '
   SELECT 
      [DatabaseName]
      ,[SchemaName]     
      ,[ErrorNumber]
      ,[ErrorMessage]
	 , StartTime, Command
  FROM [maintenance].[dbo].[CommandLog]
  where StartTime between dateadd(dd,-1,GETDATE())  and  GETDATE() 
  and Command like 'DBCC CHECKDB%'
  order by [DatabaseName], StartTime desc


  select '********************job Executing************************'
  ---- job Executing
exec msdb.dbo.sp_help_job @execution_status=1 --- running
--exec msdb.dbo.sp_help_job @job_name= 'OLA - DatabaseBackup - USER DB FULL then DBCC' 

  select '********************job schedule ************************'
     --exec rmsAdmin.dbo.p_RMSJobInfo -- content below -- an overview on active jobs and schedules excluding one time job

	SELECT --s.schedule_id,
		  'job_name' = j.name,
		   j.date_created,
		   j.enabled,
		   case when freq_type = 1 then 'One time' when freq_type = 4 then 'Daily' when freq_type = 8 then 'Weekly' when freq_type in(16,32) then 'Monthly' when freq_type = 64 then 'Start when Agent starts' else 'when idle' end as frequence, 
		   js.next_run_date, case when freq_type = 1 then s.active_start_time else js.next_run_time end run_time  , 
		   case when freq_subday_type = 1 then 'At the specified time' when freq_subday_type = 2 then 'seconds' when freq_subday_type = 4 then 'Minutes' when freq_subday_type = 8 then 'Hours' else '' end as freq_subday_type,
		   freq_subday_interval,	    
		   s.active_end_date, 
		   active_start_date, j.owner_sid
    --INTO #temp_jobschedule
    FROM msdb.dbo.sysjobschedules AS js
    LEFT JOIN msdb.dbo.sysschedules AS s
			 ON js.schedule_id = s.schedule_id
    join [msdb].[dbo].[sysjobs] j 
			 ON js.job_id =j.job_id
    where j.enabled = 1 
			 --and s.freq_type <> 1
			 and js.next_run_date <> 0
    order by 'job_name',js.next_run_date, run_time --freq_type, 'job_name', js.next_run_time


    

 -- select '********************DBA: DR_BackupLogins************************'

 -- SELECT job.name, his.step_name, his.run_status , his.run_time, his.run_date, 
	--		CASE WHEN his.run_status = 1 THEN 'Success'  
	--	     WHEN his.run_status = 0 THEN 'Failure'
	--		WHEN his.run_status = 2 THEN 'Retried'
	--		WHEN his.run_status = 3 THEN 'Cancelled'
	--		WHEN his.run_status = 4 THEN 'Check its steps'
	--		ELSE 'Unknown' END   AS outcome_message,  
	--		his.run_duration as 'Duration HHMMSS', his.[message],
 --his.sql_severity, his.retries_attempted, job.job_id 
	--    , job.notify_email_operator_id,  his.[server]
 -- FROM [msdb].[dbo].[sysjobhistory] as his
 -- JOIN [msdb].[dbo].[sysjobs] as job on job.job_id = his.job_id
 -- WHERE run_date between @date2  and  @date1
 -- --AND job.name = 'DBA: DR_BackupLogins' --1 Succeeded (0/*FAILED*/,2/*RETRY*/, 3/*CANCELED*/, 4/*In Progress*/, 5 /*unknown*/) --1 Succeeded
 -- order by run_date desc, run_time desc



  select '********************Your backups************************'
  select '********************How long does backup take COMMENTED************************'



SELECT ISNULL(d.[name], bs.[database_name]) AS [Database], d.recovery_model_desc AS [Recovery Model], 
       d.log_reuse_wait_desc AS [Log Reuse Wait Desc],
    MAX(CASE WHEN [type] = 'D' THEN bs.backup_finish_date ELSE NULL END) AS [Last Full Backup],
    MAX(CASE WHEN [type] = 'I' THEN bs.backup_finish_date ELSE NULL END) AS [Last Differential Backup],
    MAX(CASE WHEN [type] = 'L' THEN bs.backup_finish_date ELSE NULL END) AS [Last Log Backup],
	DATABASEPROPERTYEX ((d.[name]), 'LastGoodCheckDbTime') AS [Last Good CheckDB], --, bs.has_backup_checksums
	'rms-svc@sql-backups' as isCopyOverCheckEmailreceived
FROM sys.databases AS d WITH (NOLOCK)
LEFT OUTER JOIN msdb.dbo.backupset AS bs WITH (NOLOCK)
ON bs.[database_name] = d.[name]
AND bs.backup_finish_date > GETDATE()- 60
WHERE d.name <> N'tempdb' and not exists (select 1 from msdb.dbo.backupset a where bs.backup_set_id= a.backup_set_id and  a.is_copy_only = 1)
GROUP BY ISNULL(d.[name], bs.[database_name]), d.recovery_model_desc, d.log_reuse_wait_desc, d.[name]--,  bs.has_backup_checksums
ORDER BY [Last Good CheckDB], [Last Full Backup], [Last Differential Backup], [Last Log Backup]  OPTION (RECOMPILE);

-- --backups duration
select  bs.[database_name], 
    backup_start_date, backup_finish_date, 
	CONVERT(VARCHAR(12), DATEDIFF(SECOND,backup_start_date, backup_finish_date) /60/60/24) + ' - ' 
	 +                   CONVERT(VARCHAR(12), DATEDIFF(SECOND,backup_start_date, backup_finish_date) /60/60 % 24) 
	 + ':' + RIGHT('0' + CONVERT(VARCHAR(2),  DATEDIFF(SECOND,backup_start_date, backup_finish_date) /60 % 60), 2) 
	 + ':' + RIGHT('0' + CONVERT(VARCHAR(2),  DATEDIFF(SECOND,backup_start_date, backup_finish_date) % 60), 2)
    [Duration_Day - h:m:s] /*credit to Aaron Bertrand */,
    CASE WHEN [type] = 'D' then 'FULL'
	    WHEN [type] = 'I' then 'DIFF'
	    WHEN [type] = 'L' then 'LOG'
    ELSE 'OTHER' END as [Backup Type], DATENAME(dw, backup_finish_date) dayOfWeeks
from msdb.dbo.backupset bs
where bs.backup_finish_date > GETDATE()- 30
and [type] in ('D','I') 
and bs.[database_name] = 'MedRx'
order by [type], backup_finish_date desc

-- last backup by db, backup type, +infos
--;with cte_b as (
--SELECT ISNULL(d.[name], bs.[database_name]) AS [DatabaseName], d.recovery_model_desc AS [Recovery Model], 
--       d.log_reuse_wait_desc AS [Log Reuse Wait Desc], bs.backup_finish_date,  
--	  ROW_NUMBER() over (partition by bs.type, ISNULL(d.[name], bs.[database_name]), 
--					   d.recovery_model_desc,  d.log_reuse_wait_desc, d.[name] 
--					   order by backup_finish_date desc) as NumTypeOfBackUp,
--	DATABASEPROPERTYEX ((d.[name]), 'LastGoodCheckDbTime') AS [Last Good CheckDB],bs.is_copy_only, bs.type, bs.backup_size, bs.compatibility_level, bs.is_password_protected, bs.is_snapshot, bs.has_backup_checksums
--FROM sys.databases AS d WITH (NOLOCK)
--LEFT OUTER JOIN msdb.dbo.backupset AS bs WITH (NOLOCK)
--ON bs.[database_name] = d.[name]
--AND bs.backup_finish_date > GETDATE()- 30
--WHERE d.name <> N'tempdb'  and bs.is_copy_only = 0
--)
--SELECT [DatabaseName],  [Log Reuse Wait Desc],
--CASE WHEN [type] = 'D' THEN 'FULL' 
--     WHEN [type] = 'I' THEN 'DIFFERENTIAL'
--     WHEN [type] = 'L' THEN 'LOG'
--     WHEN [type] = 'F' THEN 'FILE OR FILEGROUP'
--     WHEN [type] = 'G' THEN 'DIFFERENTIAL FILE'
--     WHEN [type] = 'P' THEN 'PARTIAL'
--     WHEN [type] = 'Q' THEN 'DIFFERENTIAL PARTIAL'
--ELSE NULL END [Backup Type],

--CASE WHEN [type] = 'D' THEN backup_finish_date ELSE NULL END AS [Last Full Backup],
--CASE WHEN [type] = 'I' THEN backup_finish_date ELSE NULL END AS [Last Differential Backup],
--CASE WHEN [type] = 'L' THEN backup_finish_date ELSE NULL END AS [Last Log Backup],
--is_copy_only, Type BackUpType,  backup_size, compatibility_level, is_password_protected, is_snapshot, has_backup_checksums 
--from cte_b 
--where NumTypeOfBackUp =1 
--ORDER BY [DatabaseName], BackUpType

select  '********************space of database level SUMMARY********************'
 --EXEC sp_spaceused @updateusage = N'TRUE'; 
declare @t table (database_name nvarchar(128), database_Data_Log nvarchar(128), unallocated_space nvarchar(128), reserved nvarchar(128), 
data nvarchar(128), index_size nvarchar(128), unused nvarchar(128))

insert into @t
--EXEC sp_spaceused @oneresultset = 1 
--db
EXEC sp_MSforeachdb N'USE [?]; EXEC sp_spaceused @oneresultset = 1'
----tables with rows count
--create table #t (name_table nvarchar(128), rows nvarchar(128), reserved nvarchar(128), 
--data nvarchar(128), index_size nvarchar(128), unused nvarchar(128))

--use MedRx
--declare @clause nvarchar(2000)
--EXEC sp_MSforeachtable ' 
--begin try
--if ''?'' <> ''[dbo].[SysProcesses]''
--insert into #t EXEC sp_spaceused @objname = ''?'' 
--end try
--begin catch
--    select ''?'' as [Full Name]
--end catch
--'


--Insert into RmsAdmin.dbo.RMSTables_growth
--select name_table,
--convert(bigint,rows)  rows,
--convert(bigint,substring(reserved,0,CHARINDEX(' ', reserved)))/1024 reserved_MB,
--convert(bigint,substring(data,0,CHARINDEX(' ', data)))/1024 data_MB,
--convert(bigint,substring(index_size,0,CHARINDEX(' ', index_size)))/1024 index_size_MB,
--convert(bigint,substring(unused,0,CHARINDEX(' ', unused)))/1024 unused_MB, GETDATE(), DB_NAME() 
-- from #t
--where rows > 0 order by data_MB desc, name_table     

--if object_id('tempdb..#t') is not null
--    drop table #t

------ keep only one month of data
--select from RmsAdmin.dbo.RMSTables_growth where dateInsert < DATEADD(day, -1, GETDATE())
 
select database_name,   
cast(substring(database_Data_Log,0,CHARINDEX(' ', database_Data_Log)) as float) [database_Data_Log_MB = CurrentSizeOnDisk],
convert(float,(substring(unallocated_space,0,CHARINDEX(' ', unallocated_space)))) unallocated_MB,
cast(substring(reserved,0,CHARINDEX(' ', reserved)) as float)/1000 [reserved_MB /*= data + Index + Unused*/],
cast(substring(data,0,CHARINDEX(' ', data)) as float)/1000 data_size_MB,
(cast(substring(data,0,CHARINDEX(' ', data)) as float)/1000/cast(substring(database_Data_Log,0,CHARINDEX(' ', database_Data_Log)) as float))*100 data_size_perc,
convert(float,(substring(index_size,0,CHARINDEX(' ', index_size))))/1000 index_size_MB,
(convert(float,(substring(index_size,0,CHARINDEX(' ', index_size))))/1000/cast(substring(database_Data_Log,0,CHARINDEX(' ', database_Data_Log)) as float))*100 index_size_perc,
cast(substring(unused,0,CHARINDEX(' ', unused)) as float)/1000 unused_MB, GETDATE() as Whe_n 
 from @t
 order by [database_Data_Log_MB = CurrentSizeOnDisk] desc


declare @fillUp table (
logic_name nvarchar(128), state_desc nvarchar(128), AvailableSpaceInMB decimal(18,2), UsedPercent float,
 UsedSpace decimal(18,2), max_size_MB decimal(18,2), CurrentSizeOnDik_MB_sum_equal_Available_Used decimal(18,2), growth_MB decimal(18,2),is_percent_growth bit, physical_name nvarchar(128)
)

-- https://www.mssqltips.com/sqlservertip/4345/understanding-how-sql-server-stores-data-in-data-files/
-- size of each data page is 8KB and eight continuous pages equals one extent, so the size of an extent would be approximately 64KB
-- size = # of 8 KB pages
-- DBCC showfilestats -- returns extent count
insert into @fillUp
EXEC sp_ineachdb @command = N'
 SELECT name , state_desc,size/128.0 /* ie (size * 8.0/1024) */ - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS int)/128.0 AS AvailableSpaceInMB,		  
		  ((CAST(FILEPROPERTY(name, ''SpaceUsed'') AS int)/128.0)/(size/128.0 ))*100 as UsedPercent,  
	   CAST(FILEPROPERTY(name, ''SpaceUsed'') AS int)/128.0 as UsedSpace,
	   max_size/128 as max_size_MB, 
	   size/128.0 AS CurrentSizeOnDik_MB_sum_eq_Available_Used,
	   case when is_percent_growth =1 then growth else growth/128 end as growth_MB, is_percent_growth, physical_name 
FROM sys.database_files
order by UsedPercent desc
;'
--select 'select * from @fillUp order by UsedPercent desc'
--select * from @fillUp order by UsedPercent desc
--select 'select * from @fillUp where logic_name like ''%log%'' order by UsedPercent desc'
--select * from @fillUp where logic_name like '%log%' order by UsedPercent desc
select 'select * from @fillUp order by logic_name asc'
select * from @fillUp order by logic_name asc
--select 'select * from @fillUp order by sizeondisk asc'
--select * from @fillUp where logic_name not like '%log%'  order by CurrentSizeOnDik_MB_sum_equal_Available_Used

--select '********************space of database DETAILS********************'
--SELECT 'per size', DB_NAME([database_id]) AS [Database Name], 
--       [file_id], [name], CONVERT(bigint, size/128.0) AS [Total Size in MB], physical_name, state_desc,
--	   is_percent_growth, growth, 
--	   CONVERT(bigint, growth/128.0) AS [Growth in MB], 
--        max_size, type, type_desc
--FROM sys.master_files WITH (NOLOCK)
--ORDER BY [Total Size in MB] OPTION (RECOMPILE);

SELECT 'per name', DB_NAME([database_id]) AS [Database Name], 
       [file_id], [name], CONVERT(bigint, size/128.0) AS [Total Size in MB], physical_name, state_desc,
	   is_percent_growth, growth, 
	   CONVERT(bigint, growth/128.0) AS [Growth in MB], 
        max_size
FROM sys.master_files WITH (NOLOCK)
ORDER BY DB_NAME([database_id]), [file_id] OPTION (RECOMPILE);

SELECT 'per size OLA', DB_NAME([database_id]) AS [Database Name], 
       sum(CONVERT(bigint, size/128.0)) AS [Total Size in MB]
FROM sys.master_files WITH (NOLOCK)
group by [database_id]
ORDER BY [Total Size in MB] desc OPTION (RECOMPILE);

--	-- where are my tables,  filegroup information
--SELECT OBJECT_NAME([si].[object_id]) AS [tablename]
--    ,[ds].[name] AS [filegroupname]
--    ,[df].[physical_name] AS [datafilename]
--    , df.name as FileLogicalName, index_id
--FROM [sys].[data_spaces] [ds]
----Contains a row per file of a database as stored = [database_files]
--INNER JOIN [sys].[database_files] [df] ON [ds].[data_space_id] = [df].[data_space_id]
--INNER JOIN [sys].[indexes] [si] ON [si].[data_space_id] = [ds].[data_space_id]
--    --AND [si].[index_id] < 2
--INNER JOIN [sys].[objects] [so] ON [si].[object_id] = [so].[object_id]
--WHERE [so].[type] = 'U' and OBJECT_NAME([si].[object_id]) like '%Orders%'
--    AND [so].[is_ms_shipped] = 0
--ORDER BY [tablename] ASC;


select '********************available space on physical disk - history query commented********************'
--EXEC MASTER..xp_fixeddrives

--SELECT fixed_drive_path
--    ,free_space_in_bytes / (1024 * 1024) 'Free Space'
--    ,drive_type_desc
--FROM sys.dm_os_enumerate_fixed_drives ---included mounted drive
-- limited version commented
--SELECT distinct volume_mount_point, 
--	   --another way to convert to GB
--	   total_bytes/1073741824.0 total_GB, available_bytes/1024/1024/1024.0 available_GB,
--	   --another way to convert to float *1.0
--	  convert(DECIMAL(18,2),available_bytes*1.0/total_bytes*1.0 *100)  Percent_Available
--FROM sys.master_files AS f  
--CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id)
--SELECT fixed_drive_path,'-' total_GB, 
--CONVERT(DECIMAL(18,2), free_space_in_bytes/1073741824.0) AS available_GB, '-' Percent_Available
--FROM sys.dm_os_enumerate_fixed_drives WITH (NOLOCK) OPTION (RECOMPILE)
-- https://www.mssqltips.com/sqlservertip/2444/script-to-get-available-and-free-disk-space-for-sql-server/#:~:text=SQL%20Script%20to%20check%20total%20and%20free%20disk,can%20be%20run%20from%20a%20SSMS%20query%20window.
declare @svrName varchar(255)
declare @sql varchar(400)
--by default it will take the current server name, we can the set the server name as well
set @svrName = @@SERVERNAME
set @sql = 'powershell.exe -c "Get-WmiObject -ComputerName ' + QUOTENAME(@svrName,'''') + ' -Class Win32_Volume -Filter ''DriveType = 3'' | select name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'
--creating a temporary table
IF OBJECT_ID('tempdb..#output') is not null 
    drop table #output
CREATE TABLE #output
(line varchar(255))
--inserting disk name, total space and free space value in to temporary table
insert #output
EXEC xp_cmdshell @sql
--script to retrieve the values in GB from PS Script output
;with cte as (
select rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as drivename
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
   (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,2) as total_GB
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
   (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024 ,2)as available_GB
from #output
where line like '[A-Z][:]%'  
)
--create table db_physicalSize(drivename varchar(18), total_GB float, available_GB float, Percent_Available float, TimeChecked datetime)
--insert into Maintenance.dbo.db_physicalSize
select drivename,  total_GB, available_GB, 
    convert(DECIMAL(18,2),available_GB*1.0/total_GB*1.0 *100)  Percent_Available
from cte
order by Percent_Available asc
--script to drop the temporary table
IF OBJECT_ID('tempdb..#output') is not null 
    drop table #output

----history space available
--use  rmsAdmin

--select Collection_Time, Drive, FreeSpace_GB, TotalSpace_GB,   
--convert(decimal(5,2),round(100*(FreeSpace_GB / TotalSpace_GB)*1.00,3)) as '% Free'     
--from [dbo].[RMSDaily_Storage] 
--where Collection_Time >= dateadd(yy,-1,getdate()) and drive = 'D:\'
--order by Collection_Time desc 


    select '********************available space on memory********************'
    select '********************available space on memory********************'
    select '********************available space on memory********************'

    SELECT available_physical_memory_kb/1024 as "Total Memory MB available_physical",
 available_physical_memory_kb/(total_physical_memory_kb*1.0)*100 AS "% Memory Free",
 total_physical_memory_kb/1024 AS [Physical Memory (MB)], 
       total_page_file_kb/1024 AS [Page File Commit Limit (MB)],
	   total_page_file_kb/1024 - total_physical_memory_kb/1024 AS [Physical Page File Size (MB)],
	   available_page_file_kb/1024 AS [Available Page File (MB)], 
	   system_cache_kb/1024 AS [System Cache (MB)],
       system_memory_state_desc AS [System Memory State]
FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);


select '********************where is your server log located********************'
SELECT SERVERPROPERTY('ErrorLogFileName') AS 'Error log file location';


select '********************Error & Fail from log file last 7 dayspart of security ********************'

--search using xp_readErrorLog
DECLARE @logFileType SMALLINT= 1;-- 1 – To read the SQL Server error log 2- To read SQL Agent logs
DECLARE @start DATETIME;
DECLARE @end DATETIME;
DECLARE @logno INT= 0; 
SET @start = dateadd(dd,-7,GETDATE())  ; -- between @date2  and  @date1
SET @end = dateadd(dd,1,GETDATE())  --'2021-11-07 09:00:00.000';
DECLARE @searchString1 NVARCHAR(256)= 'Login failed';
DECLARE @searchString2 NVARCHAR(256)= 'error';
DECLARE @searchString3 NVARCHAR(256)= 'warning';
DECLARE @searchString4 NVARCHAR(256)= 'Server is listening on';
DECLARE @searchString5 NVARCHAR(256)= '';

select  @start, @end


EXEC master.dbo.xp_readerrorlog 
     @logno, 
     @logFileType, 
     @searchString1, --fail
     null, 
     @start, 
     @end;

EXEC master.dbo.xp_readerrorlog 
     @logno, 
     @logFileType, 
     null, 
     @searchString2, --error
     @start, 
     @end;

EXEC master.dbo.xp_readerrorlog 
     @logno, 
     @logFileType, 
     null, 
     @searchString3, --warning
     @start, 
     @end;

EXEC master.dbo.xp_readerrorlog 
     @logno, 
     @logFileType, 
     null, 
     @searchString4, --Server is listening on
     @start, 
     @end;

EXEC master.dbo.xp_readerrorlog 
     @logno, 
     @logFileType, 
     null, 
     @searchString5, -- all
     @start, 
     @end;

select 'CHECK LAST BACKUP ON REMOTE SERVER IE SHORT TERM SERVER'

select '********************Go to Essentials.sql : included check lastest bottlenecks  ********************'

select '********************Go to Connected.sql :  ********************'

select '********************DBA checklist.sql : tell you if a check is missing ********************'

select '********************DBSUPPORT-2487 Free Space for Full Backup up to 3 TB at least better 6TB.sql ********************'

select '********************IndexFill_Up.sql ********************'

select '********************Blitz dashboard :CPU,Disk, Memory, Network: tabs CPU, IOPS, Files Speeds, Files sizes, Perform(databases, Latches, buffer, memory ....) ********************'

select '********************Blitz dashboard Performances TIPS here > SQL Server 2017 Query Performance Tuning Troubleshoot and Optimize 5th ed ********************'


--select '********************DBSUPPORT-2414.sql Tables growth - queries commented below instead of pbix file********************'
-- select 'Free storage on disk'
-- select Collection_Time, Drive, FreeSpace_GB, TotalSpace_GB,   
-- convert(decimal(5,2),round(100*(FreeSpace_GB / TotalSpace_GB)*1.00,3)) as '% Free'     
-- from RmsAdmin.dbo.[RMSDaily_Storage] where Collection_Time >= dateadd(yy,-1,getdate()) order by Collection_Time asc 
 
---- select 'Tablegrowth' 
-- select tableName, a.reserved [reserved_MB /*= data + Index + Unused*/], 
--  round(cast(a.rows - LAG(a.rows) OVER(PARTITION BY a.tableName ORDER BY dateInsert) as float)/cast(a.rows as float),4) AS rows_growth_Rate, 
-- a.data data_MB,
-- index_size index_size_MB, 
-- unused unused_MB, 
-- dateInsert, db_name,  
--  ISNULL(a.reserved - LAG(a.reserved) OVER(PARTITION BY a.tableName ORDER BY dateInsert) ,0) AS reserved_growth,
--  ISNULL(a.data - LAG(a.data) OVER(PARTITION BY a.tableName ORDER BY dateInsert) ,0) AS data_growth,
--  ISNULL(a.rows - LAG(a.rows) OVER(PARTITION BY a.tableName ORDER BY dateInsert) ,0) AS rows_growth,
-- round(cast(a.data - LAG(a.data) OVER(PARTITION BY a.tableName ORDER BY dateInsert) as float)/cast(iif(a.data=0,1,a.data) as float),4) AS data_growth_Rate, 
-- round(cast(a.reserved - LAG(a.reserved) OVER(PARTITION BY a.tableName ORDER BY dateInsert) as float)/cast(iif(a.reserved=0,1,a.reserved) as float),4) AS reserved_growth_Rate, 
-- round(cast(a.index_size - LAG(a.index_size) OVER(PARTITION BY a.tableName ORDER BY dateInsert) as float)/cast(iif(a.index_size=0,1,a.index_size) as float),4) AS index_size_growth_Rate, 
-- SCHEMA_NAME(schema_id) +'.'+ b.name as full_name
-- from
-- RmsAdmin.dbo.RMSTables_growth a
-- join MedRx.sys.tables b on a.tableName = b.name
-- where a.rows > 0 --and tableName='LoaderLog'
--  --and tableName like '%MasterPayerHistory%'
-- --order by a.dateInsert  desc, rows_growth_Rate desc, tableName desc 
-- --order by a.dateInsert  desc, data_growth_Rate desc, tableName desc 
-- order by a.dateInsert  desc, a.reserved desc, rows_growth_Rate desc  
