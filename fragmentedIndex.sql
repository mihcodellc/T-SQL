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

