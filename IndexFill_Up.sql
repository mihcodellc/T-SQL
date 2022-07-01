set nocount on;
set transaction isolation level read uncommitted

--I have to exclude column named SysProcessID
--I'm looking into only identity columns how close is it to the max number  or ValueAtWall(subjected to reseed of identity)
--Return # 
--------------schema	
--------------Table
--------------HasEarlyWall
--------------ValueAtWall
--------------last-generated identity
--------------CountBeforeWall -- default to 50 000 000
--------------IsMaxAllowedUsed
--------------table_id_name
--------------typeName
--------------MinValue
--------------MaxValueInserted
--------------maxNumber
--------------CountOfUnusedValues	
--------------number_rows	
--------------PercentageOfUse
-- when CountBeforeWall is less to default 50 000 000 rows with margin error 100000
-- looking at hist tables from a query within the script
-- data types targeted here is bigint, int, smallint, tinyint
-- use the section named "set variables" to define the output
-- to get all of identity columns
-- don't use @checkIdentityCol = 0 OR Remove "a.is_identity = @checkIdentityCol" unless you specify a @Mytable

-- identity column and how close to the max number
if object_id('tempdb..#FillUp') is not null
    drop table #FillUp

if object_id('tempdb..#FillUp2') is not null
    drop table #FillUp2

if object_id('tempdb..#temp') is not null
    drop table #temp

create table #temp( table_id_name nvarchar(500), last_value bigint, 
objName nvarchar(128), columnName nvarchar(128), MinValue bigint, objectid int, columnid int, HasEarlyWall bit,  ValueAtWall bigint)

declare @tableCurrent nvarchar(128), @IdTableCurrent nvarchar(128), @dateInsertCol nvarchar(128)
declare @ValCurrent bigint, @valMax bigint, @CountBeforeWall bigint


declare @Mytable nvarchar(128), @checkIdentityCol bit, @FillUpPercent tinyint

-- set variables 
select  @Mytable = ''
	   , @dateInsertCol = 'TimeStamp'
	   --, @CountBeforeWall = 50000000
	   , @checkIdentityCol = 1
	   , @FillUpPercent = 85


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
 --and OBJECT_NAME(a.object_id) not in (xxx', 'xxxx')
 
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
	   'SELECT ''[' + aColumn +']'' as col, isnull((SELECT MAX([' + aColumn + ']) FROM ' + aschema + '.[' + aTable + ']), 0) last_value ' +
	   ', ''' + aTable + ''',''' + aColumn + ''',
	   isnull((SELECT MIN([' + aColumn + ']) FROM ' + aschema + '.[' + aTable + ']), 0) MinValue, ' +
	    convert(char(100), @obj_id) + ', ' +  convert(char(100), @col_id) 
	    + ', case when exists(select 1 from ' + aschema + '.[' + aTable + '] where ' + aColumn + ' between  '+ convert(char(38),CurrentID)+' + 100000 and '+ convert(char(38),maxNumber)+' ) then 1 else 0 end as hasWall ' 
	    + ', (select top 1 ' + aColumn + ' from ' + aschema + '.[' + aTable + '] where ' + aColumn + ' >  '+ convert(char(38),CurrentID)+' + 100000 order by '+ aColumn +' asc) as ValueAtWall ' 
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
;with cte as (
SELECT u.aschema, u.aTable, t.HasEarlyWall, t.ValueAtWall, u.CurrentID as [last-generated identity] 
    , case when t.HasEarlyWall =1 then (t.ValueAtWall -  u.CurrentID)
		 else (u.maxNumber - u.CurrentID) end  as CountBeforeWall
    , case when (t.last_value = u.maxNumber) then 1 else 0 end IsMaxAllowedUsed
    , t.table_id_name, u.typeName
    , t.MinValue, t.last_value as MaxValueInserted, u.maxNumber, CAST(ic.last_value AS DECIMAL(38,0)) UnReliableLastValue
    , (u.maxNumber - u.number_rows)CountOfUnusedValues, u.number_rows
    , (number_rows/maxNumber * 100) as PercentageOfUse, getdate() EntryStamp  --u.object_id, u.column_id
FROM #temp t  
join #FillUp2 u 
    on t.objectid = u.object_id and t.columnid = u.column_id
    LEFT JOIN sys.identity_columns ic ON
                    u.object_id=ic.object_id and u.column_id=ic.column_id
--where (number_rows/maxNumber * 100) > @FillUpPercent
)
select top 10 aschema, aTable, case when HasEarlyWall =1 and ValueAtWall > 0  then (CountBeforeWall/ValueAtWall) else (CountBeforeWall/maxNumber) end * 100 PercentLeft, PercentageOfUse,
	   CountBeforeWall, ValueAtWall, MinValue,maxNumber,  HasEarlyWall, [last-generated identity], IsMaxAllowedUsed, table_id_name, typeName, CountOfUnusedValues, number_rows
from cte
order by PercentLeft asc
--where   
--	   HasEarlyWall = 1 or 
--	   --PercentageOfUse> @FillUpPercent or 
--	   ValueAtWall is not null or 
--	  --case when HasEarlyWall =1 then (CountBeforeWall/ValueAtWall) else (CountBeforeWall/maxNumber) end * 100 <= (100-@FillUpPercent)
--order by aTable --PercentageOfUse
 
  

if LEN(@Mytable) > 2
    SELECT @ValCurrent = u.CurrentID, @valMax = u.maxNumber, @IdTableCurrent = aColumn
    FROM #FillUp2 u 


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

--will query for days remaining to slam the wall if reseed gooes wrong

--set transaction isolation level read uncommitted
--set nocount on

--declare @tableCurrent nvarchar(128), @IdTableCurrent nvarchar(128), @dateInsertCol nvarchar(128)
--declare @ValCurrent bigint, @valMax bigint

--declare @query nvarchar(2000)

----set the table and its identity col, dateInsertCol
--select @tableCurrent = 'dbo.LockBoxServiceLineDetailHistory', @IdTableCurrent = '[SLHisID]'
--, @dateInsertCol = 'DateUpdated'
--, @ValCurrent = 521966884
--, @valMax = 2147483647
----**do we have a wall?

--set @query = '
--declare @ValWall bigint, @CountOfIdRemain bigint, @avgPerDay bigint, @DaysLeftToWall bigint
--if exists(select 1 from ' + @tableCurrent + ' where ' + @IdTableCurrent + ' between  @ValCurrent and @valMax )
--begin
--    select 1
--    /*save the table''s name */
--    /*insert into #ReseedWrongTable */
--    select ''' + @tableCurrent + ''' as ReseedWrongTable  into #ReseedWrongTable
--    /*get @ValWall */
--    select top 1 @ValWall = ' + @IdTableCurrent + '
--    from ' + @tableCurrent + '
--    where ' + @IdTableCurrent + ' > @ValCurrent order by ' + @IdTableCurrent + ' asc
--    /*get the count of id remaining */
--    set @CountOfIdRemain = @ValWall - @ValCurrent
--    /* return #ReseedWrongTable */
--    select * from #ReseedWrongTable
--end
--else /* compute day left */
--begin
--    /*get the count of id remaining */
--    set @CountOfIdRemain = @valMax - @ValCurrent
--end

--/*determine avgPerDay over last 60 days */
--select @avgPerDay = (count(1))/60 
--from ' + @tableCurrent + ' 
--where ' + @dateInsertCol + ' >= dateadd(dd,-60, getdate())
--/*determine DaysLeftToWall */
--set @DaysLeftToWall = @CountOfIdRemain/@avgPerDay 
--/*return the findings */
--select ''' + @tableCurrent + ''' as tableCurrent, @DaysLeftToWall as DaysLeftToWall , @avgPerDay as avgPerDay, @CountOfIdRemain as CountOfIdRemain 
--'
----select @query
--exec sp_executesql @query, 
--			    N' @ValCurrent bigint, @valMax bigint',
--			      	@ValCurrent = @ValCurrent, @valMax = @valMax


--******part 2
--set transaction isolation level read uncommitted
--set nocount on


--declare @query2 nvarchar(2000)

----set the table and its identity col, dateInsertCol
--select @tableCurrent = @Mytable
--, @ValCurrent = @ValCurrent+100000
----**do we have a wall?

--set @query2 = '
--declare @ValWall bigint, @CountOfIdRemain bigint, @avgPerDay bigint, @DaysLeftToWall bigint
--if exists(select 1 from ' + @tableCurrent + ' where ' + @IdTableCurrent + ' between  @ValCurrent and @valMax )
--begin
--    /*select ''EARLY WALL <> max OF DATA TYPE''*/
--    /*save the table''s name */
--    /*insert into #ReseedWrongTable */
--    select ''' + @tableCurrent + ''' as ReseedWrongTable  into #ReseedWrongTable
--    /*get @ValWall */
--    select top 1 @ValWall = ' + @IdTableCurrent + '
--    from ' + @tableCurrent + '
--    where ' + @IdTableCurrent + ' > @ValCurrent order by ' + @IdTableCurrent + ' asc
--    /*get the count of id remaining */
--    set @CountOfIdRemain = @ValWall - @ValCurrent
--    /* return #ReseedWrongTable */
--    select * from #ReseedWrongTable
--end
--else
--begin
--    /*select ''EARLY WALL = max OF DATA TYPE ''*/
--    /*get the count of id remaining */
--    set @CountOfIdRemain = @valMax - @ValCurrent
--end



--/*return the findings */
--select ''' + @tableCurrent + ''' as tableCurrent, @ValWall as ValWall
--, @DaysLeftToWall as HourLeftToWall , @avgPerDay as avgPerHour, @CountOfIdRemain as CountOfIdRemain 
--'
----select @query
--exec sp_executesql @query2, 
--			    N' @ValCurrent bigint, @valMax bigint',
--			      	@ValCurrent = @ValCurrent, @valMax = @valMax
