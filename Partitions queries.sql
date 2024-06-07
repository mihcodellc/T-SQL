--https://learn.microsoft.com/en-us/sql/relational-databases/partitions/create-partitioned-tables-and-indexes?view=sql-server-ver16#query-metadata-of-partitioned-tables-and-indexes 
SELECT 
	PF.name AS PartitionFunction,
	ds.name AS PartitionScheme,
    OBJECT_SCHEMA_NAME(si.object_id) as SchemaName,
	OBJECT_NAME(si.object_id) AS PartitionedTable, 
	si.name as IndexName
FROM sys.indexes AS si
JOIN sys.data_spaces AS ds
	ON ds.data_space_id = si.data_space_id
JOIN sys.partition_schemes AS PS
	ON PS.data_space_id = si.data_space_id
JOIN sys.partition_functions AS PF
	ON PF.function_id = PS.function_id
WHERE ds.type = 'PS'
AND OBJECTPROPERTYEX(si.object_id, 'BaseType') = 'U'
ORDER BY PartitionFunction, PartitionScheme, SchemaName, PartitionedTable;


--Determine if a table is partitioned
SELECT SCHEMA_NAME(t.schema_id) AS SchemaName, *   
FROM sys.tables AS t   
JOIN sys.indexes AS i   
    ON t.[object_id] = i.[object_id]   
JOIN sys.partition_schemes ps   
    ON i.data_space_id = ps.data_space_id   
WHERE t.name in ( 'extractoutput', 'extractoutput_archive');   
GO



--Determine the boundary values for a partitioned table
SELECT SCHEMA_NAME(t.schema_id) AS SchemaName, t.name AS TableName, i.name AS IndexName, 
    p.partition_number, p.partition_id, i.data_space_id, f.function_id, f.type_desc, 
    r.boundary_id, r.value AS BoundaryValue   
FROM sys.tables AS t  
JOIN sys.indexes AS i  
    ON t.object_id = i.object_id  
JOIN sys.partitions AS p  
    ON i.object_id = p.object_id AND i.index_id = p.index_id   
JOIN  sys.partition_schemes AS s   
    ON i.data_space_id = s.data_space_id  
JOIN sys.partition_functions AS f   
    ON s.function_id = f.function_id  
LEFT JOIN sys.partition_range_values AS r   
    ON f.function_id = r.function_id and r.boundary_id = p.partition_number  
WHERE 
    t.name in ( 'extractoutput', 'extractoutput_archive') 
    --AND i.type <= 1  
ORDER BY SchemaName, t.name, i.name, p.partition_number;




--Determine the partition column for a partitioned table
SELECT   
    t.[object_id] AS ObjectID
    , SCHEMA_NAME(t.schema_id) AS SchemaName
    , t.name AS TableName   
    , ic.column_id AS PartitioningColumnID   
    , c.name AS PartitioningColumnName
    , i.name as IndexName
FROM sys.tables AS t   
JOIN sys.indexes AS i   
    ON t.[object_id] = i.[object_id]   
    AND i.[type] <= 1 -- clustered index or a heap   
JOIN sys.partition_schemes AS ps   
    ON ps.data_space_id = i.data_space_id   
JOIN sys.index_columns AS ic   
    ON ic.[object_id] = i.[object_id]   
    AND ic.index_id = i.index_id   
    AND ic.partition_ordinal >= 1 -- because 0 = non-partitioning column   
JOIN sys.columns AS c   
    ON t.[object_id] = c.[object_id]   
    AND ic.column_id = c.column_id   
WHERE t.name in ( 'extractoutput', 'extractoutput_archive')  
GO

-- Determine the rows describe the possible range of values in each partition
SELECT SCHEMA_NAME(t.schema_id) AS SchemaName, t.name AS TableName, i.name AS IndexName, 
    p.partition_number AS PartitionNumber, f.name AS PartitionFunctionName, p.rows AS Rows, rv.value AS BoundaryValue, 
CASE WHEN ISNULL(rv.value, rv2.value) IS NULL THEN 'N/A' 
ELSE
    CASE WHEN f.boundary_value_on_right = 0 AND rv2.value IS NULL THEN '>=' 
        WHEN f.boundary_value_on_right = 0 THEN '>' 
        ELSE '>=' 
    END + ' ' + ISNULL(CONVERT(varchar(64), rv2.value), 'Min Value') + ' ' + 
        CASE f.boundary_value_on_right WHEN 1 THEN 'and <' 
                ELSE 'and <=' END 
        + ' ' + ISNULL(CONVERT(varchar(64), rv.value), 'Max Value') 
END AS TextComparison
FROM sys.tables AS t  
JOIN sys.indexes AS i  
    ON t.object_id = i.object_id  
JOIN sys.partitions AS p  
    ON i.object_id = p.object_id AND i.index_id = p.index_id   
JOIN  sys.partition_schemes AS s   
    ON i.data_space_id = s.data_space_id  
JOIN sys.partition_functions AS f   
    ON s.function_id = f.function_id  
LEFT JOIN sys.partition_range_values AS r   
    ON f.function_id = r.function_id and r.boundary_id = p.partition_number  
LEFT JOIN sys.partition_range_values AS rv
    ON f.function_id = rv.function_id
    AND p.partition_number = rv.boundary_id     
LEFT JOIN sys.partition_range_values AS rv2
    ON f.function_id = rv2.function_id
    AND p.partition_number - 1= rv2.boundary_id
WHERE 
    t.name in ( 'extractoutput', 'extractoutput_archive') 
    --AND i.type <= 1 
ORDER BY t.name, p.partition_number;
