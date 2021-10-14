
-- ****** for the table
declare @table nvarchar(128), @index  nvarchar(128), @db nvarchar(128), @searchTable nvarchar(128), @tableSchema nvarchar(128)

-- set the variables
select @db = DB_NAME(), @searchTable = 'BillableUnits', @tableSchema = 'apps'

DECLARE MyStats CURSOR FOR   
	select distinct @tableSchema+'.'+OBJECT_NAME(st.object_id), ix.name --, st.* 
	from sys.dm_db_index_usage_stats st
	join sys.indexes ix on st.object_id = ix.object_id
	where DB_NAME(database_id) = @db 
	and OBJECT_NAME(st.object_id) = @searchTable

OPEN MyStats  
  
FETCH NEXT FROM MyStats INTO @table, @index  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
   DBCC SHOW_STATISTICS (@table,@index) --with STAT_HEADER, DENSITY_VECTOR, HISTOGRAM         
   SELECT '********************************************************************************************************************************************'
   FETCH NEXT FROM MyStats INTO @table, @index    
END   
CLOSE MyStats;  
DEALLOCATE MyStats;  


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