--make sure to replace tables and the FileGroup's name
--make sure that managemet studio is set to allow enough characters in a column: Options > Query results > Result to text > max # of characters display in each column
--run query with output as "result to Text" not grid or file
--it does return table without index ie heap at top in message tab

set nocount on

drop table if exists #temp
create table
 #temp (
		objname nvarchar(776),
		index_name			sysname	collate database_default NOT NULL,
		is_primary bit,
		index_keys			nvarchar(2126)	collate database_default NULL, -- see @keys above for length descr
		inc_columns			nvarchar(max),
		objid int, 
		is_unique_key bit,
		type tinyint
)

exec sp_msforeachtable 'insert into #temp exec [sp_SQLskills_helpindex_short] [?]' 
--exec [sp_SQLskills_helpindex_short] '[billingoverhaul].[billingtransactioncode]'
--exec [sp_SQLskills_helpindex_short] '[dbo].[FileLoadSummary]'
--exec [sp_SQLskills_helpindex_short] '[dbo].[ConfigKeySetup]'
--select is_unique_constraint, name from sys.indexes where name = 'UQ_billingcode'
--insert into @temp exec [sp_SQLskills_helpindex_short] 'dbo.PaymentPosting'
--insert into @temp exec [sp_SQLskills_helpindex_short] 'dbo.E835DateTimeReference'
--insert into @temp exec [sp_SQLskills_helpindex_short] 'dbo.MatchingResults'

--fix (-) = DESC in the index definition

select 'insert into rmsadmin.dbo.trackIndex_rebuild (objname,index_name) select ''' + objname + ''','''+index_name+'''; ' +
case when is_primary = 1 then 'CREATE UNIQUE CLUSTERED INDEX ' + index_name + ' ON ' + objname + ' ('+ index_keys + ') WITH (SORT_IN_TEMPDB = ON,ONLINE=OFF, DROP_EXISTING = ON, FILLFACTOR = 90) '  +  ' ON [FG_MedRx_Data] ' + char(10)+ 'GO'  
     WHEN is_primary = 0 and is_unique_key = 1  THEN 
	 --'CREATE UNIQUE NONCLUSTERED INDEX '  +  index_name + ' ON ' + objname + ' ('+ index_keys + ')' 
	 'CREATE UNIQUE ' + iif(type=2,' NONCLUSTERED ',' CLUSTERED ') + ' INDEX '  +  index_name + ' ON ' + objname + ' ('+ index_keys + ')' 
			+ IIF(LEN(inc_columns) > 0, ' INCLUDE (' + inc_columns + ')', '')  + ' WITH (SORT_IN_TEMPDB = ON, ONLINE=OFF, DROP_EXISTING = ON, FILLFACTOR = 90) ' +  ' ON [FG_MedRx_Data] ' + char(10) + 'GO'  
	 WHEN is_primary = 0 and is_unique_key = 0 THEN
	 'CREATE ' + iif(type=2,' NONCLUSTERED ',' CLUSTERED ') + ' INDEX '  +  index_name + ' ON ' + objname + ' ('+ index_keys + ')' 
	 + 	IIF(LEN(inc_columns) > 0, ' INCLUDE (' + inc_columns + ')', '')  + ' WITH (SORT_IN_TEMPDB = ON,ONLINE=OFF, DROP_EXISTING = ON, FILLFACTOR = 90) ' +  ' ON [FG_MedRx_Data] ' + char(10) + 'GO'  
else '' end saveAndRebuilt -- Filegroup's name = FG_MedRx_Data
from #temp where is_primary = 1

