-- https://github.com/mcflyamorim/statisticsreview/tree/main/Presentation *** great resources


-- Returning all statistics properties for a table without fragmentation or full histogram  
SELECT sp.stats_id, name, filter_definition, last_updated, rows, rows_sampled, steps, unfiltered_rows, modification_counter
--, histo.* 
--, stat.*   
FROM sys.stats AS stat   
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp  
--CROSS APPLY sys.dm_db_stats_histogram(stat.[object_id], stat.stats_id) AS histo
WHERE stat.object_id = object_id('a_table')
 and name like '%index_name%'
	   and auto_created = 0


-- as above + columns involved 
select  distinct ix.index_id, keyColumns, sp.*, stat.name idx_name, stat.*
from sys.index_columns ix
join sys.stats AS stat on ix.index_id = stat.stats_id
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp 
cross apply (
	   select isnull(convert(varchar(128), c.name),'') + ', '
	   from sys.index_columns i
	   join sys.columns AS c on  c.object_id = i.object_id and c.column_id = i.column_id
	   where is_included_column = 0
		      and i.index_id = ix.index_id and stat.object_id = c.object_id
	   order by i.key_ordinal asc
    FOR XML PATH('') 
) AS li (keyColumns)
where  
stat.object_id = object_id('MySchema.Mytable')  
and 
auto_created = 0 -- keyColumns is not null
order by 2 

--stats' status
SELECT name AS stats_name,   
    STATS_DATE(object_id, stats_id) AS statistics_update_date  
FROM sys.stats   
WHERE object_id = OBJECT_ID('dbo.Payments') and name like 'IX%413' order by 1;  

DBCC SHOW_STATISTICS (@table,@index)

--fragmentation stat
-- read before and after defragmentation 
--select ObjectName, index_name, avg_fragmentation_in_percent, TimeChecked,page_count,alloc_unit_type_desc,Average_page_density, 
--	   page_count * 8.0*0.00000095367432 as Size --1KB = 0.00000095367432 and a page = 8KB
--	   , (select sum(row_count) from sys.dm_db_partition_stats st where st.object_id = object_id('schema.table') and st.index_id < 2) numberOfRows
--from maintenance.dbo.indexFragmentation
--where index_name in('ix_name') --and alloc_unit_type_desc = 'IN_ROW_DATA'
--order by index_name, TimeChecked desc

--create stats
--CREATE STATISTICS Products ON Production.Product ([Name], ProductNumber)  WITH SAMPLE 50 PERCENT


--Update Stats
--EXEC sp_updatestats; all stats
UPDATE STATISTICS Sales.SalesOrderDetail(Index_SalesOrderDetail_rowguid) WITH SAMPLE 1 PERCENT; 
UPDATE STATISTICS Sales.SalesOrderDetail(Index_SalesOrderDetail_rowguid) WITH FULLSCAN;
	--or
	--UPDATE STATISTICS Sales.SalesOrderDetail; 
	--UPDATE STATISTICS Sales.SalesOrderDetail Index_SalesOrderDetail_rowguid;  

-- alter index to update stats
ALTER INDEX [Index_SalesOrderDetail_rowguid] ON Sales.SalesOrderDetail rebuild with (ONLINE=ON)
--ALTER INDEX IX_anIndex_name ON dbo.ordersTable REBUILD; -- >70/80
--ALTER INDEX ALL ON dbo.ordersTable REORGANIZE; -- <30 and > 5 	



-- ****** for the table +  fragmentation + full histogram per index
declare @table nvarchar(128), @index  nvarchar(128), 
@db nvarchar(128), @searchTable nvarchar(128), @tableSchema nvarchar(128),
@indexID int

-- set the variables
select @db = DB_NAME(), @searchTable = 'Mytable', @tableSchema = 'MySchema'

DECLARE MyStats CURSOR FOR   
	select distinct @tableSchema+'.'+OBJECT_NAME(st.object_id), ix.name, st.index_id --, st.* 
	from sys.dm_db_index_usage_stats st
	join sys.indexes ix on st.object_id = ix.object_id and ix.index_id = st.index_id
	where DB_NAME(database_id) = @db 
	and OBJECT_NAME(st.object_id) = @searchTable
	--and ix.name='x'

OPEN MyStats  
  
FETCH NEXT FROM MyStats INTO @table, @index, @indexID   
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
	--fragmentation -- can be commented out if take too long
	SELECT [object_id], [index_id], [partition_number], [avg_fragmentation_in_percent], 
	[page_count], record_count, index_type_desc, alloc_unit_type_desc, avg_page_space_used_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(), object_id(@table), @indexID, NULL, 'LIMITED') nolock

	DBCC SHOW_STATISTICS (@table,@index) --with STAT_HEADER, DENSITY_VECTOR, HISTOGRAM         
	   SELECT '********************************************************************************************************************************************'
	   
   FETCH NEXT FROM MyStats INTO @table, @index, @indexID      
END   
CLOSE MyStats;  
DEALLOCATE MyStats;  

-- https://docs.microsoft.com/en-us/sql/relational-databases/indexes/reorganize-and-rebuild-indexes?view=sql-server-ver15
-- Monitor index fragmentation and page density over time to see if there is a correlation on performance

-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver15
-- check the fragmentation and page density of a "rowstore" index using Transact-SQL
SELECT OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
       OBJECT_NAME(ips.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       ips.avg_fragmentation_in_percent,
       ips.avg_page_space_used_in_percent,
       ips.page_count,
       ips.alloc_unit_type_desc
FROM  ---DEFAULT, NULL, LIMITED, SAMPLED, or DETAILED. The default (NULL) is LIMITED
sys.indexes AS i 
join sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('TableName'), null, null, 'SAMPLED') AS ips
ON ips.object_id = i.object_id  AND ips.index_id = i.index_id
   --and i.object_id = OBJECT_ID('LockboxClaimDetailArchive')
where i.is_disabled = 0
ORDER BY page_count DESC;



-- check the fragmentation of a "columnstore" index using Transact-SQL
SELECT OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
       OBJECT_NAME(i.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       100.0 * (ISNULL(SUM(rgs.deleted_rows), 0)) / NULLIF(SUM(rgs.total_rows), 0) AS avg_fragmentation_in_percent
FROM sys.indexes AS i
INNER JOIN sys.dm_db_column_store_row_group_physical_stats AS rgs
ON i.object_id = rgs.object_id
   AND
   i.index_id = rgs.index_id
WHERE rgs.state_desc = 'COMPRESSED'
GROUP BY i.object_id, i.index_id, i.name, i.type_desc
ORDER BY schema_name, object_name, index_name, index_type;
--https://www.virtual-dba.com/blog/sql-server-statistics/

-- ****** for a query
set statistics io, time on

SELECT 
       p.BusinessEntityID
      ,p.FirstName
      ,p.MiddleName
      ,p.LastName
      ,p.Suffix
      ,p.EmailPromotion
      ,e.EmailAddress
FROM [AdventureWorks2012].[Person].[Person] as p
JOIN [AdventureWorks2012].[Person].[EmailAddress] as e on p.BusinessEntityID = e.BusinessEntityID
OPTION (querytraceon 9292,querytraceon 9204,querytraceon 3604)







