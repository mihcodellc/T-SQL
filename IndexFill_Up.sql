set nocount on;
set transaction isolation level read uncommitted

--I have to exclude column named SysProcessID
--I'm looking into only identity columns
--Return # unused values, last value to compare with maxNumber allowed for the identity column data type
--data types targeted here is bigint, int, smallint, tinyint
-- comment this line :
--	   where t.last_value >= u.maxNumber
-- to get all of identity columns
-- don't use @checkIdentityCol = 0 OR Remove "a.is_identity = @checkIdentityCol" unless you specify a @Mytable

-- identity column and how close to the max number
if object_id('tempdb..#FillUp') is not null
    drop table #FillUp

if object_id('tempdb..#FillUp2') is not null
    drop table #FillUp2

if object_id('tempdb..#temp') is not null
    drop table #temp

create table #temp( table_id_name nvarchar(128), last_value bigint, 
objName nvarchar(128), columnName nvarchar(128), MinValue bigint, objectid int, columnid int)

declare @Mytable nvarchar(128), @checkIdentityCol bit, @FillUpPercent tinyint
set @checkIdentityCol = 1
set @Mytable = 'LockBoxServiceLineDetailHistory'
set @FillUpPercent = 50


SELECT OBJECT_SCHEMA_NAME(a.object_id) as aschema, OBJECT_NAME(a.object_id) aTable, a.name aColumn,b.type_desc,  b.type, t.name as typeName
, (select sum(row_count) from sys.dm_db_partition_stats st where st.object_id = a.object_id and st.index_id < 2) as number_rows -- 0 heap 1 clustered >1 NonClustered
, case when t.name = 'bigint' then  9223372036854775807
	  when t.name = 'int' then  2147483647 
	  when t.name = 'smallint' then  32767
	  when t.name = 'tinyint' then  255 end maxNumber, a.object_id, a.column_id,
	  IDENT_CURRENT(OBJECT_NAME(a.object_id)) CurrentID 
into #FillUp
FROM sys.all_columns a 
JOIN sys.all_objects b on a.object_id = b.object_id
JOIN sys.types t on a.user_type_id = t.user_type_id
WHERE b.type ='U' and t.name in ('int','smallint', 'bigint', 'tinyint')
 and a.is_identity = @checkIdentityCol
 and a.name not in( 'SysProcessID')
 and ((len(@Mytable) > 0 and OBJECT_NAME(a.object_id) = @Mytable) or @Mytable='')

DECLARE @query NVARCHAR(3000), @obj_id int, @col_id int

select * into #FillUp2 from #FillUp

--select * from #FillUp

select top 1 
	    @obj_id = [object_id]
	   , @col_id = [column_id]
    FROM #FillUp  

--Loop thru all columns an insert into #temp
WHILE EXISTS(SELECT 1 FROM #FillUp)
BEGIN
    SELECT @query = 
	   'INSERT INTO #temp ' +
	   'SELECT ''[' + aColumn +']'' as col, isnull((SELECT MAX([' + aColumn + ']) FROM ' + aschema + '.[' + aTable + ']), 0) LastValue ' +
	   ', ''' + aTable + ''',''' + aColumn + ''',
	   isnull((SELECT MIN([' + aColumn + ']) FROM ' + aschema + '.[' + aTable + ']), 0) MinValue, ' +
	    convert(char(12), @obj_id) + ', ' +  convert(char(12), @col_id)  
	   , @obj_id = [object_id]
	   , @col_id = [column_id]
    FROM #FillUp   
    where object_id = @obj_id and column_id = @col_id
 
    EXEC sp_executesql @query
    --select @query
    DELETE FROM #FillUp 
    WHERE column_id = @col_id AND [object_id] = @obj_id

    select top 1 @obj_id = [object_id], @col_id = [column_id]
    FROM #FillUp  

END

--return #temp
SELECT u.aschema, u.aTable, t.table_id_name, u.typeName, u.CurrentID as [last-generated identity]
    , t.MinValue, t.last_value as MaxValueInserted, CAST(ic.last_value AS DECIMAL(38,0)) UnReliableLastValue, u.maxNumber
    , (u.maxNumber - u.number_rows)CountOfUnusedValues, u.number_rows
    , (number_rows/maxNumber * 100) as PercentageOfUse, u.object_id, u.column_id
FROM #temp t  
join #FillUp2 u 
    on t.objectid = u.object_id and t.columnid = u.column_id
    LEFT JOIN sys.identity_columns ic ON
                    u.object_id=ic.object_id and u.column_id=ic.column_id
where t.last_value >= u.maxNumber or (number_rows/maxNumber * 100) > @FillUpPercent
order by PercentageOfUse

--drop temp tables
if object_id('tempdb..#FillUp') is not null
    drop table #FillUp

if object_id('tempdb..#temp') is not null
    drop table #temp

if object_id('tempdb..#FillUp2') is not null
    drop table #FillUp2



--DBCC SHOW_STATISTICS ('dbo.LockboxClaimDetailArchive','PK_LockBoxDocumentClaimDetailArchive')
--DBCC SHOW_STATISTICS ('dbo.LockboxDocumentTrackingArchive','PK_LDTArchive')

--select (CountOfUnusedValues  - count(1)) as CountValuesAvailable from atable nolock
--where table_id > lastUsedValueID 

----update statistics atable with fullscan

--select count(1) from dbo.LockboxDocumentTrackingArchive nolock
--where [LbxHisId] = 1495426648 + 25963523 

--select 1495426648 + 25963422

----does exist a value between the range we find that is good to be used
--select count(1) from dbo.LockboxDocumentTrackingArchive nolock
--where [LbxHisId] between 1495426648 and (1521390070) -- = 1495426648 + 25963422

----LockboxDocumentTrackingArchive: between 1495426648 + 25963422  good 25963523 nope
----	   last used 1495426647 + 1 = 1495426648
----	   countOfUnUsedValues 72 862 335
----      not used values range: between 1495426648 and 1521389648 for a total of 25963000





----1 equal to a value above the last seed
----2 make a jump by adding 
----query if exist then reduce by a number till  find one doesn't exist
---- jump up and then if exist then jum back and query till if not exist
----doing till you reach of offset of 100 000 
--SELECT POWER(10, 7) AS Result1