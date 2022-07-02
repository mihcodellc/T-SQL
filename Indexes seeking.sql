--seeks, scans, lookups
select * from sys.dm_db_index_usage_stats


--Identifying Fragmented Indexes
SELECT OBJECT_NAME(OBJECT_ID), index_id,index_type_desc,
avg_fragmentation_in_percent,page_count
FROM sys.dm_db_index_physical_stats
(DB_ID(N'AdventureWorks2016'), NULL, NULL, NULL , 'SAMPLED')
ORDER BY avg_fragmentation_in_percent DESC

--Identifying Unused Indexes
SELECT OBJECT_SCHEMA_NAME(I.OBJECT_ID) AS SchemaName,
OBJECT_NAME(I.OBJECT_ID) AS ObjectName,
I.NAME AS IndexName
FROM    sys.indexes I
WHERE
-- find out the indexes for user created tables
OBJECTPROPERTY(I.OBJECT_ID, 'IsUserTable') = 1
-- find out unused indexes
AND NOT EXISTS (
SELECT  index_id
FROM    sys.dm_db_index_usage_stats
WHERE   OBJECT_ID = I.OBJECT_ID
AND I.index_id = index_id
-- limit our query only for the current db
AND database_id = DB_ID())
ORDER BY SchemaName, ObjectName, IndexName

