select  '********************space at database level SUMMARY********************'
--EXEC sp_helpdb; -- Show db sizes 

 --EXEC sp_spaceused @updateusage = N'TRUE'; 
declare @t table (database_name nvarchar(128), database_Data_Log nvarchar(128), unallocated_space nvarchar(128), reserved nvarchar(128), 
data nvarchar(128), index_size nvarchar(128), unused nvarchar(128))

insert into @t
--EXEC sp_spaceused @oneresultset = 1 
--db
EXEC sp_MSforeachdb N'USE [?]; EXEC sp_spaceused @oneresultset = 1'

select  '********************space at table level SUMMARY********************'

CREATE TABLE #t (
	[name_table] [nvarchar](128) NULL,	[rows] [bigint] NULL,[reserved] [bigint] NULL,
	[data] [bigint] NULL,[index_size] [bigint] NULL,	[unused] [bigint] NULL
)



declare @clause nvarchar(2000)
EXEC sp_MSforeachtable ' 
begin try
if ''?'' <> ''[dbo].[SysProcesses]''
insert into #t EXEC sp_spaceused_mbello @objname = ''?'' 
end try
begin catch
    select ''?'' as [Full Name]
end catch
'

select * from #t order by reserved desc 


Insert into RmsAdmin.dbo.RMSTables_growth
select name_table,
  rows,
reserved as reserved_MB,
data as data_MB,
index_size as index_size_MB,
unused as unused_MB, GETDATE(), DB_NAME() 
 from #t
where rows > 0 order by data_MB desc, name_table     

if object_id('tempdb..#t') is not null
    drop table #t


select  '********************space at table indexes level SUMMARY********************'


--once extracted with overnight because it may take long
SELECT OBJECT_NAME(ddips.object_id) AS TableName,
       i.name AS IndexName,
       ddips.index_type_desc,
       ddips.avg_fragmentation_in_percent,
       ddips.page_count,
	   (ddips.page_count *8.)/ 1024. / 1024. AS SizeGB,
       i.fill_factor
FROM   sys.dm_db_index_physical_stats(DB_ID(N'MyDB'), OBJECT_ID('dbo.MyTable'), NULL, NULL, 'LIMITED') AS ddips
JOIN   sys.tables AS t
    ON t.object_id = ddips.object_id
JOIN   sys.indexes AS i
    ON  i.object_id = ddips.object_id
    AND i.index_id = ddips.index_id;

--run

-- read before and after defragmentation 
select ObjectName, index_name, avg_fragmentation_in_percent, 
	TimeChecked ,
	(page_count *8.)/ 1024. / 1024. AS SizeGB,
	   (page_count * 8.0)*0.0009765625 as Size_MB --1KB = 0.0009765625 MB and a page = 8KB
	   , ((page_count * 8.0)*0.0009765625) - (avg_fragmentation_in_percent / 100 * (page_count * 8.0)*0.0009765625) AS Estimated_Ghost_Bloat_MB --size - (avg_frag/100*size) --not sure where this formula is from
	   , (select sum(row_count) from sys.dm_db_partition_stats st where st.object_id = object_id('dbo.'+objectName) and st.index_id < 2) numberOfRows
	   ,page_count,alloc_unit_type_desc,Average_page_density
from maintenance.dbo.indexFragmentation
--where index_name in('IX_E835DateTimeReference_E835ClaimId') --and alloc_unit_type_desc = 'IN_ROW_DATA'
where avg_fragmentation_in_percent > 60
and TimeChecked > '20250810' and ObjectName = 'MyTable'
order by index_name, TimeChecked desc --10308908

--match the following and 
--https://www.brentozar.com/archive/2015/12/does-index-fill-factor-affect-fragmentation/
--Diagnostic Information Queries: Get Schema names, Table names, object size, row counts, and compression status for clustered index or heap  (Query 69) (Table Sizes)

EXEC DBA_DB.dbo.sp_BlitzIndex    @DatabaseName='MyDB', @SchemaName='dbo', @TableName='MyTable'
