SELECT DISTINCT DB_NAME(vol.database_id) DB_Name,
m.physical_name FilePath,
CONVERT(INT,(m.size/1024)*8) as CurrentFileSizeMB,
CONVERT(INT,vol.available_bytes/1048578) as AvailableVolSizeMB 
FROM sys.master_files m 
CROSS APPLY sys.dm_os_volume_stats(m.database_id,m.FILE_ID) vol 
ORDER BY DB_Name;
