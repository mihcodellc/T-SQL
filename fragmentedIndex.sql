-- Fragmentation????
-- https://www.brentozar.com/?s=fragmentation
-- https://www.brentozar.com/archive/2016/01/should-i-worry-about-index-fragmentation/
-------rebuild indexes help THEN try to updating stats instead

--aimed rebuild reorganize indexes.sql

-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver16
--The modes are progressively slower from LIMITED to DETAILED, because more work is performed in each mode. 
--To quickly gauge the size or fragmentation level of a table or index, use the LIMITED mode. 
--It is the fastest and will not return a row for each nonleaf level in the IN_ROW_DATA allocation unit of the index.

set transaction isolation level read uncommitted
set nocount on

--get  index id
exec sp_SQLskills_helpindex @objname= TableName

-- replace <TableName> and <index id>
SELECT a.object_id, object_name(a.object_id) AS TableName,
    a.index_id, b.name AS IndedxName, avg_fragmentation_in_percent,b.type_desc, b.fill_factor,   b.is_disabled
FROM sys.dm_db_index_physical_stats (DB_ID (db_name()) , OBJECT_ID('<TableName>'), <index id>, NULL, NULL) AS a -- 1 ie index id
INNER JOIN sys.indexes AS b
    ON a.object_id = b.object_id
    AND a.index_id = b.index_id

-- Returning information about a specified table
DECLARE @db_id SMALLINT;  
DECLARE @object_id INT;  
  
SET @db_id = DB_ID(N'AdventureWorks2012');  
SET @object_id = OBJECT_ID(N'AdventureWorks2012.Person.Address');  
  
IF @db_id IS NULL  
BEGIN;  
    PRINT N'Invalid database';  
END;  
ELSE IF @object_id IS NULL  
BEGIN;  
    PRINT N'Invalid object';  
END;  
ELSE  
BEGIN;  
    SELECT * FROM sys.dm_db_index_physical_stats(@db_id, @object_id, NULL, NULL , 'LIMITED');  
END;  
GO      

-- fragmetation per % for the current database

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

-- different ways to maintain index
ALTER INDEX ALL ON Production.Product REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)

ALTER INDEX PK_Employee_BusinessEntityID ON HumanResources.Employee REBUILD;

ALTER INDEX ALL ON HumanResources.Employee REORGANIZE;
