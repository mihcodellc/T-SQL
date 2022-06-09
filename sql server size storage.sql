--** OS memory state included free
SELECT available_physical_memory_kb/1024 as "Total Memory MB",
 available_physical_memory_kb/(total_physical_memory_kb*1.0)*100 AS "% Memory Free",
 total_physical_memory_kb/1024 AS [Physical Memory (MB)], 
       total_page_file_kb/1024 AS [Page File Commit Limit (MB)],
	   total_page_file_kb/1024 - total_physical_memory_kb/1024 AS [Physical Page File Size (MB)],
	   available_page_file_kb/1024 AS [Available Page File (MB)], 
	   system_cache_kb/1024 AS [System Cache (MB)],
       system_memory_state_desc AS [System Memory State]
FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);

select 'log size on disk'
DBCC SQLPERF(LOGSPACE)

--** space of database SUMMARY
--EXEC sp_spaceused @updateusage = N'TRUE'; 
--declare @t table (database_name nvarchar(128), database_Data_Log nvarchar(128), unallocated_space nvarchar(128), reserved nvarchar(128), 
--data nvarchar(128), index_size nvarchar(128), unused nvarchar(128))

--insert into @t
EXEC sp_spaceused @oneresultset = 1 
--EXEC sp_MSforeachdb N'USE [?]; EXEC sp_spaceused @oneresultset = 1'

-- space of object
--EXEC sp_spaceused @objname = N'Banks',@updateusage = 'FALSE',@mode = 'ALL', @oneresultset = '0'--, @include_total_xtp_storage = '1';

--select * from @t

select 'space of database DETAILS'
SELECT DB_NAME([database_id]) AS [Database Name], 
       [file_id], [name], physical_name, [type_desc], state_desc,
	   is_percent_growth, growth, 
	   CONVERT(bigint, growth/128.0) AS [Growth in MB], 
       CONVERT(bigint, size/128.0) AS [Total Size in MB], max_size
FROM sys.master_files WITH (NOLOCK)
ORDER BY DB_NAME([database_id]), [file_id] OPTION (RECOMPILE);

select 'available space on physical disk'
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
select drivename,  total_GB, available_GB, 
    convert(DECIMAL(18,2),available_GB*1.0/total_GB*1.0 *100)  Percent_Available
from cte
order by Percent_Available asc
--script to drop the temporary table
IF OBJECT_ID('tempdb..#output') is not null 
    drop table #output


select ' current db file info'
--exec sp_helpfile;
----exec sp_MSforeachdb N' use ?
----exec sp_helpfile;
----'
-- https://dba.stackexchange.com/questions/7917/how-to-determine-used-free-space-within-sql-database-files/7921#7921
 declare @clause nvarchar(2000)

 set @clause = '
	   use [?]
SELECT 
    [TYPE] = A.TYPE_DESC
    ,[FILE_Name] = A.name
    ,[FILEGROUP_NAME] = fg.name
    ,[File_Location] = A.PHYSICAL_NAME
    ,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
    ,[USEDSPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(A.NAME, ''SPACEUSED'') AS INT)/128.0))
    ,[FREESPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, ''SPACEUSED'') AS INT)/128.0)
    ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, ''SPACEUSED'') AS INT)/128.0)/(A.SIZE/128.0))*100)
    ,[AutoGrow] = ''By '' + CASE is_percent_growth WHEN 0 THEN CAST(growth/128 AS VARCHAR(10)) + '' MB -'' 
        WHEN 1 THEN CAST(growth AS VARCHAR(10)) + ''% -'' ELSE '''' END 
        + CASE max_size WHEN 0 THEN ''DISABLED'' WHEN -1 THEN '' Unrestricted'' 
            ELSE '' Restricted to '' + CAST(max_size/(128*1024) AS VARCHAR(10)) + '' GB'' END 
        + CASE is_percent_growth WHEN 1 THEN '' [autogrowth by percent, BAD setting!]'' ELSE '''' END
FROM sys.database_files A LEFT JOIN sys.filegroups fg ON A.data_space_id = fg.data_space_id 
order by A.TYPE desc, A.NAME;
	   '
	    exec sp_MSforeachdb @clause
--SELECT 
--    [TYPE] = A.TYPE_DESC
--    ,[FILE_Name] = A.name
--    ,[FILEGROUP_NAME] = fg.name
--    ,[File_Location] = A.PHYSICAL_NAME
--    ,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
--    ,[USEDSPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0))
--    ,[FREESPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)
--    ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)/(A.SIZE/128.0))*100)
--    ,[AutoGrow] = 'By ' + CASE is_percent_growth WHEN 0 THEN CAST(growth/128 AS VARCHAR(10)) + ' MB -' 
--        WHEN 1 THEN CAST(growth AS VARCHAR(10)) + '% -' ELSE '' END 
--        + CASE max_size WHEN 0 THEN 'DISABLED' WHEN -1 THEN ' Unrestricted' 
--            ELSE ' Restricted to ' + CAST(max_size/(128*1024) AS VARCHAR(10)) + ' GB' END 
--        + CASE is_percent_growth WHEN 1 THEN ' [autogrowth by percent, BAD setting!]' ELSE '' END
--FROM sys.database_files A LEFT JOIN sys.filegroups fg ON A.data_space_id = fg.data_space_id 
--order by A.TYPE desc, A.NAME;

 

--SELECT a.object_id, object_name(a.object_id) AS TableName,
--    a.index_id, b.name AS IndedxName, avg_fragmentation_in_percent,b.type_desc, b.fill_factor,   b.is_disabled
--FROM sys.dm_db_index_physical_stats (DB_ID (db_name()) , NULL, NULL, NULL, NULL) AS a
--INNER JOIN sys.indexes AS b
--    ON a.object_id = b.object_id
--    AND a.index_id = b.index_id
--where avg_fragmentation_in_percent > 80 and b.name is not null
--order by avg_fragmentation_in_percent desc

----RmsAdmin
--object_id	TableName	index_id	IndedxName	avg_fragmentation_in_percent	type_desc	fill_factor	is_disabled
--1213247377	BlitzFirst_WaitStats_History	2	IX_BlitzFirst_WaitStats_History_Svr_Wait_Date	99.6789727126806	NONCLUSTERED	95	0
--884198200	BlitzFirst_WaitStats	2	IX_ServerName_wait_type_CheckDate_Includes	98.5716935633463	NONCLUSTERED	95	0
--2080726465	LDTH_idlist_temp_DELETE_ME	2	LDTH_idlist_temp_LbxHisId_idx	95.2365703306381	NONCLUSTERED	95	0
--1213247377	BlitzFirst_WaitStats_History	1	PK_BlitzFirst_WaitStats_History	92.1827411167513	CLUSTERED	95	0

--SELECT [name] AS 'Database Name',
--COUNT(li.database_id) AS 'VLF Count',
--SUM(li.vlf_size_mb) AS 'VLF Size (MB)',
--SUM(CAST(li.vlf_active AS INT)) AS 'Active VLF',
--SUM(li.vlf_active*li.vlf_size_mb) AS 'Active VLF Size (MB)',
--COUNT(li.database_id)-SUM(CAST(li.vlf_active AS INT)) AS 'Inactive VLF',
--SUM(li.vlf_size_mb)-SUM(li.vlf_active*li.vlf_size_mb) AS 'Inactive VLF Size (MB)'
--FROM sys.databases s
--CROSS APPLY sys.dm_db_log_info(s.database_id) li
--GROUP BY [name]
--ORDER BY COUNT(li.database_id) DESC;

--DBCC LOGINFO
