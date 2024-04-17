-- Fragmentation????
-- https://www.brentozar.com/?s=fragmentation
-- https://www.brentozar.com/archive/2016/01/should-i-worry-about-index-fragmentation/
-------rebuild indexes help THEN try to updating stats instead

--aimed rebuild reorganize indexes.sql

-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver16
--The modes are progressively slower from LIMITED to DETAILED, because more work is performed in each mode. 
--To quickly gauge the size or fragmentation level of a table or index, use the LIMITED mode. 
--It is the fastest and will not return a row for each nonleaf level in the IN_ROW_DATA allocation unit of the index.

--ola defragmentation
EXECUTE maintenance.dbo.IndexOptimize
@Databases = 'MyDB',
@FragmentationLow = NULL,
@FragmentationMedium = NULL,
@FragmentationHigh = 'INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@indexes = 'db.schema.table.ix_name',
@MaxDOP = 0,
@Resumable = 'Y', -- online index operation is resumable
@WaitAtLowPriorityMaxDuration = 2,  -- in minutes
@WaitAtLowPriorityAbortAfterWait = 'SELF', -- Abort the online index rebuild operation after 2min
@TimeLimit = 900, -- 15min  -- ie no commands are executed
@LogToTable = 'Y',
@Execute = 'Y'

--if above didn't work, use of the options below according to % of fragmentation and table or index
-- different ways to maintain index
ALTER INDEX ALL ON Production.Product REBUILD WITH (ONLINE=ON, FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)

ALTER INDEX index_name ON schema.table_name REBUILD WITH (ONLINE=ON, FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)

ALTER INDEX PK_Employee_BusinessEntityID ON HumanResources.Employee REBUILD;

ALTER INDEX ALL ON HumanResources.Employee REORGANIZE;

--truncate table maintenance.dbo.indexFragmentation

insert into maintenance.dbo.indexFragmentation
SELECT OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
       OBJECT_NAME(ips.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       ips.avg_fragmentation_in_percent,
       ips.avg_page_space_used_in_percent as 'Average_page_density', --  low, more pages are required to store the same amount of data
       ips.page_count,
       ips.alloc_unit_type_desc,
	   getdate()
FROM sys.dm_db_index_physical_stats(DB_ID(), default, default, default, 'LIMITED') AS ips --objectid, indID
INNER JOIN sys.indexes AS i 
ON ips.object_id = i.object_id
   AND
   ips.index_id = i.index_id
--where ips.avg_fragmentation_in_percent > 70
ORDER BY page_count DESC;

-- read before and after defragmentation 
--select ObjectName, index_name, avg_fragmentation_in_percent, TimeChecked,page_count,alloc_unit_type_desc,Average_page_density, 
--	   page_count * 8.0*0.00000095367432 as Size --1KB = 0.00000095367432 and a page = 8KB
--	   , (select sum(row_count) from sys.dm_db_partition_stats st where st.object_id = object_id('schema.table') and st.index_id < 2) numberOfRows
--from maintenance.dbo.indexFragmentation
--where index_name in('ix_name') --and alloc_unit_type_desc = 'IN_ROW_DATA'
--order by index_name, TimeChecked desc

--- syntax from the indexFragmentation
select 'alter index '+index_name + ' on ' + schemaName + '.'+ objectname + ' REBUILD with (ONLINE=ON) ' as 'rebuid statement',* 
from maintenance.dbo.indexFragmentation where timechecked > '20240414' and index_type<>'Heap'
 and avg_fragmentation_in_percent> 79
order by page_count desc,avg_fragmentation_in_percent desc

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
    
     SELECT OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
       OBJECT_NAME(ips.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       ips.avg_fragmentation_in_percent,
       ips.avg_page_space_used_in_percent as 'Average page density', --  low, more pages are required to store the same amount of data
       ips.page_count,
       ips.alloc_unit_type_desc
    FROM sys.dm_db_index_physical_stats(@db_id, @object_id, default, default, 'LIMITED') AS ips -- replaced 1829698412 by select OBJECT_ID('table_name')
    INNER JOIN sys.indexes AS i 
    ON ips.object_id = i.object_id
   AND
   ips.index_id = i.index_id 
--    SELECT OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
--       OBJECT_NAME(ips.object_id) AS object_name,
--       i.name AS index_name,
--       i.type_desc AS index_type,
--       ips.avg_fragmentation_in_percent,
--       ips.avg_page_space_used_in_percent as 'Average page density', --  low, more pages are required to store the same amount of data
--       ips.page_count,
--       ips.alloc_unit_type_desc
--    FROM sys.dm_db_index_physical_stats(DB_ID(), 1029630761, default, default, 'LIMITED') AS ips -- replaced 1829698412 by select OBJECT_ID('table_name')
--    INNER JOIN sys.indexes AS i 
--    ON ips.object_id = i.object_id
--   AND
--   ips.index_id = i.index_id
----where ips.object_id in (OBJECT_ID('table_name'
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
where avg_fragmentation_in_percent > 80 /* or 30, 50, 5*/ and b.name is not null
order by avg_fragmentation_in_percent desc



-- different ways to maintain index
ALTER INDEX ALL ON Production.Product REBUILD WITH (ONLINE=ON, FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)

ALTER INDEX PK_Employee_BusinessEntityID ON HumanResources.Employee REBUILD;

ALTER INDEX ALL ON HumanResources.Employee REORGANIZE;
