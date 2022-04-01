
-- ****** for the table
declare @table nvarchar(128), @index  nvarchar(128), 
@db nvarchar(128), @searchTable nvarchar(128), @tableSchema nvarchar(128),
@indexID int

-- set the variables
select @db = DB_NAME(), @searchTable = 'Mytable', @tableSchema = 'MySchema'

DECLARE MyStats CURSOR FOR   
	select distinct @tableSchema+'.'+OBJECT_NAME(st.object_id), ix.name, st.index_id --, st.* 
	from sys.dm_db_index_usage_stats st
	join sys.indexes ix on st.object_id = ix.object_id
	where DB_NAME(database_id) = @db 
	and OBJECT_NAME(st.object_id) = @searchTable
	and ix.name='x'

OPEN MyStats  
  
FETCH NEXT FROM MyStats INTO @table, @index, @indexID   
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
	--fragmentation
	SELECT [object_id], [index_id], [partition_number], [avg_fragmentation_in_percent], 
	[page_count], record_count, index_type_desc, alloc_unit_type_desc, avg_page_space_used_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(), object_id(@table), @@indexID, NULL, 'SAMPLED') nolock

	DBCC SHOW_STATISTICS (@table,@index) --with STAT_HEADER, DENSITY_VECTOR, HISTOGRAM         
	   SELECT '********************************************************************************************************************************************'
	   
   FETCH NEXT FROM MyStats INTO @table, @index    
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
