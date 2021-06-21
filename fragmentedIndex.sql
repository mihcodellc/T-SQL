--aimed rebuild reorganize indexes.sql

select TableName, max(avg_fragmentation_in_percent) HigherPercentofFragmentation from (
SELECT a.object_id, object_name(a.object_id) AS TableName,
    a.index_id, b.name AS IndedxName, avg_fragmentation_in_percent,b.type_desc, b.fill_factor,   b.is_disabled
FROM sys.dm_db_index_physical_stats (DB_ID (db_name()) , NULL, NULL, NULL, NULL) AS a
INNER JOIN sys.indexes AS b
    ON a.object_id = b.object_id
    AND a.index_id = b.index_id
where b.name is not null
) a
group by TableName
order by HigherPercentofFragmentation desc
--order by avg_fragmentation_in_percent desc

SELECT a.object_id, object_name(a.object_id) AS TableName,
    a.index_id, b.name AS IndedxName, avg_fragmentation_in_percent,b.type_desc, b.fill_factor,   b.is_disabled
FROM sys.dm_db_index_physical_stats (DB_ID (db_name()) , NULL, NULL, NULL, NULL) AS a
INNER JOIN sys.indexes AS b
    ON a.object_id = b.object_id
    AND a.index_id = b.index_id
	where  b.name is not null
order by avg_fragmentation_in_percent desc


SELECT a.object_id, object_name(a.object_id) AS TableName,
    a.index_id, b.name AS IndedxName, avg_fragmentation_in_percent,b.type_desc, b.fill_factor,   b.is_disabled
FROM sys.dm_db_index_physical_stats (DB_ID (db_name()) , NULL, NULL, NULL, NULL) AS a
INNER JOIN sys.indexes AS b
    ON a.object_id = b.object_id
    AND a.index_id = b.index_id
where avg_fragmentation_in_percent > 80 and b.name is not null
order by avg_fragmentation_in_percent desc

SELECT a.object_id, object_name(a.object_id) AS TableName,
    a.index_id, b.name AS IndedxName, avg_fragmentation_in_percent,b.type_desc, b.fill_factor,   b.is_disabled
FROM sys.dm_db_index_physical_stats (DB_ID (db_name()) , NULL, NULL, NULL, NULL) AS a
INNER JOIN sys.indexes AS b
    ON a.object_id = b.object_id
    AND a.index_id = b.index_id
where avg_fragmentation_in_percent > 50 and b.name is not null
order by avg_fragmentation_in_percent desc

SELECT a.object_id, object_name(a.object_id) AS TableName,
    a.index_id, b.name AS IndedxName, avg_fragmentation_in_percent,b.type_desc, b.fill_factor,   b.is_disabled
FROM sys.dm_db_index_physical_stats (DB_ID (db_name()) , NULL, NULL, NULL, NULL) AS a
INNER JOIN sys.indexes AS b
    ON a.object_id = b.object_id
    AND a.index_id = b.index_id
where avg_fragmentation_in_percent > 30 and b.name is not null
order by avg_fragmentation_in_percent desc


SELECT a.object_id, object_name(a.object_id) AS TableName,
    a.index_id, b.name AS IndedxName, avg_fragmentation_in_percent,b.type_desc, b.fill_factor,   b.is_disabled
FROM sys.dm_db_index_physical_stats (DB_ID (db_name()) , NULL, NULL, NULL, NULL) AS a
INNER JOIN sys.indexes AS b
    ON a.object_id = b.object_id
    AND a.index_id = b.index_id
where avg_fragmentation_in_percent > 5 and b.name is not null
order by avg_fragmentation_in_percent desc


SELECT ddips.avg_fragmentation_in_percent,
 ddips.fragment_count,
 ddips.page_count,
 ddips.avg_page_space_used_in_percent,
 ddips.record_count,
 ddips.avg_record_size_in_bytes
FROM sys.dm_db_index_physical_stats(DB_ID('finmas'), OBJECT_ID(N'cuenta'),
NULL,
NULL,
'Sampled') AS ddips;


SELECT OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
       OBJECT_NAME(ips.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       ips.avg_fragmentation_in_percent,
       ips.avg_page_space_used_in_percent,
       ips.page_count,
       ips.alloc_unit_type_desc
FROM sys.dm_db_index_physical_stats(DB_ID(), default, default, default, 'SAMPLED') AS ips
INNER JOIN sys.indexes AS i 
ON ips.object_id = i.object_id
   AND
   ips.index_id = i.index_id
ORDER BY page_count DESC;

ALTER INDEX ALL ON Production.Product REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)

ALTER INDEX PK_Employee_BusinessEntityID ON HumanResources.Employee REBUILD;

ALTER INDEX ALL ON HumanResources.Employee REORGANIZE;