-- https://www.mssqltips.com/sqlservertip/5832/move-sql-server-tables-to-different-filegroups/


-- where are my tables
SELECT OBJECT_NAME([si].[object_id]) AS [tablename]
    ,[ds].[name] AS [filegroupname]
    ,[df].[physical_name] AS [datafilename]
    , df.name as FileLogicalName
FROM [sys].[data_spaces] [ds]
--Contains a row per file of a database as stored = [database_files]
INNER JOIN [sys].[database_files] [df] ON [ds].[data_space_id] = [df].[data_space_id]
INNER JOIN [sys].[indexes] [si] ON [si].[data_space_id] = [ds].[data_space_id]
    AND [si].[index_id] < 2
INNER JOIN [sys].[objects] [so] ON [si].[object_id] = [so].[object_id]
WHERE [so].[type] = 'U' and OBJECT_NAME([si].[object_id]) like '%Orders%'
    AND [so].[is_ms_shipped] = 0
ORDER BY [tablename] ASC;

--OR

SELECT o.[name] AS TableName, i.[name] AS IndexName, fg.[name] AS FileGroupName
FROM sys.indexes i 
INNER JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
INNER JOIN sys.all_objects o ON i.[object_id] = o.[object_id]
WHERE i.data_space_id = fg.data_space_id AND o.type = 'U' and  OBJECT_NAME([i].[object_id]) like '%A_table_name%'


--objects left on datafile
SELECT [so].[type],so.type_desc,
    OBJECT_NAME(p.object_id) AS ObjectName,
    i.name AS IndexName,
    au.type_desc AS AllocationType,
    au.total_pages * 8 / 1024 AS TotalSizeMB,
	[df].[physical_name] AS [datafilename],
	df.name as FileLogicalName,
	[ds].[name] AS [filegroupname]
FROM 
    sys.partitions p
JOIN 
    sys.allocation_units au ON p.partition_id = au.container_id
JOIN 
    sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
JOIN [sys].[data_spaces] ds ON [i].[data_space_id] = [ds].[data_space_id]
JOIN [sys].[database_files] [df] ON [ds].[data_space_id] = [df].[data_space_id]
INNER JOIN [sys].[objects] [so] ON [i].[object_id] = [so].[object_id]
WHERE --df.name = 'logicFileName' --and 
		[so].[type] <> 'U'
--    au.data_space_id = (SELECT data_space_id FROM sys.filegroups WHERE name = '?')
ORDER BY 
    [filegroupname] DESC;

