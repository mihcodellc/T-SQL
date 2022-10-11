--use MedRx
--SELECT name ,size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS AvailableSpaceInMB, CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 as UsedSpace,
--size/128.0 AS OriginalSizeMB, getdate()
--FROM sys.database_files
--where type <> 1 -- exclude log
--and name like 'MedRx_Data%' 

exec msdb.dbo.sp_help_job @execution_status = 1

Use MedRx
Insert into maintenance.dbo.dbSize_datasplit
SELECT name ,size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS AvailableSpaceInMB, CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 as UsedSpace,
size/128.0 AS OriginalSizeMB, getdate()
FROM sys.database_files
where type <> 1 -- exclude log
and name like 'MedRx_Data%' 
go

select top 5 * from maintenance.dbo.dbSize_datasplit
where name like 'MedRx_Data_Split_1%' 
order by TimeChecked desc 

--SELECT 'per size', DB_NAME([database_id]) AS [Database Name], 
--       [file_id], [name], CONVERT(bigint, size/128.0) AS [Total Size in MB], physical_name, state_desc,
--	   is_percent_growth, growth, 
--	   CONVERT(bigint, growth/128.0) AS [Growth in MB], 
--        max_size
--FROM sys.master_files WITH (NOLOCK)
--where DB_NAME([database_id]) = 'MedRx'
--ORDER BY [Total Size in MB] OPTION (RECOMPILE);
