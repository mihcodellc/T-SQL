--make sure to replace tables in the where clause. Use Notepad++ to format the table names : '[schema1].[name1]',  '[schema2].[name2]', '[schema3].[name3]' ...
--replace the fileGroup's name  FG_MedRx_...
--make sure that management studio is set to allow enough characters in a column: Options > Query results > Result to text > max # of characters display in each column
--run query with output as "result to Text" not grid or file
-- up to date to not miss new objects
 
set nocount on
 
drop table if exists #temp
create table
 #temp (
        objname nvarchar(776),
        index_name          sysname collate database_default NOT NULL,
        is_primary bit,
        index_keys          nvarchar(2126)  collate database_default NULL, -- see @keys above for length descr
        inc_columns         nvarchar(max),
        objid int,
        is_unique_key bit,
        type tinyint
)
 
exec sp_msforeachtable 'insert into #temp exec [sp_SQLskills_helpindex_short] [?]'  

 -- don't forget: SET QUOTED_IDENTIFIER ON; -- to avoid error when building index
--fix (-) = DESC in the index definition
 
select 'insert into dba_db.dbo.trackIndex_rebuild (objname,index_name) select ''' + objname + ''','''+index_name+'''; ' +
case when is_primary = 1 then 'CREATE UNIQUE CLUSTERED INDEX ' + index_name + ' ON ' + objname + ' ('+ index_keys + ') WITH (ONLINE=OFF, DROP_EXISTING = ON, FILLFACTOR = 90) '  +  ' ON [FG_Db_Destination] ' + char(10)+ 'GO' 
     WHEN is_primary = 0 and is_unique_key = 1  THEN
     --'CREATE UNIQUE NONCLUSTERED INDEX '  +  index_name + ' ON ' + objname + ' ('+ index_keys + ')'
     'CREATE UNIQUE ' + iif(type=2,' NONCLUSTERED ',' CLUSTERED ') + ' INDEX '  +  index_name + ' ON ' + objname + ' ('+ index_keys + ')'
            + IIF(LEN(inc_columns) > 0, ' INCLUDE (' + inc_columns + ')', '')  + ' WITH (ONLINE=OFF, DROP_EXISTING = ON, FILLFACTOR = 90) ' +  ' ON [FG_Db_Destination] ' + char(10) + 'GO' 
     WHEN is_primary = 0 and is_unique_key = 0 THEN
     'CREATE ' + iif(type=2,' NONCLUSTERED ',' CLUSTERED ') + ' INDEX '  +  index_name + ' ON ' + objname + ' ('+ index_keys + ')'
     +  IIF(LEN(inc_columns) > 0, ' INCLUDE (' + inc_columns + ')', '')  + ' WITH (ONLINE=OFF, DROP_EXISTING = ON, FILLFACTOR = 90) ' +  ' ON [FG_Db_Destination] ' + char(10) + 'GO' 
else '' end saveAndRebuilt -- Filegroup's name = FG_Db_Destination
from #temp where objname in (
'[dbo].[A_Table]'
)
