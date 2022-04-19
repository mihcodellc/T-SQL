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

--** log size on disk
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

--** space of database DETAILS
SELECT DB_NAME([database_id]) AS [Database Name], 
       [file_id], [name], physical_name, [type_desc], state_desc,
	   is_percent_growth, growth, 
	   CONVERT(bigint, growth/128.0) AS [Growth in MB], 
       CONVERT(bigint, size/128.0) AS [Total Size in MB], max_size
FROM sys.master_files WITH (NOLOCK)
ORDER BY DB_NAME([database_id]), [file_id] OPTION (RECOMPILE);

-- available space on physical disk
SELECT fixed_drive_path, drive_type_desc, 
CONVERT(DECIMAL(18,2), free_space_in_bytes/1073741824.0) AS [Available Space (GB)], free_space_in_bytes
FROM sys.dm_os_enumerate_fixed_drives WITH (NOLOCK) OPTION (RECOMPILE);

select ' current db file info'
exec sp_helpfile;
--exec sp_MSforeachdb N' use ?
--exec sp_helpfile;
--'
