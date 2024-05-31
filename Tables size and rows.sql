--Tables size and rows
--instructions:
--replace FileGroupName in   where FileGroupName = 'FG_MedRx_E'
-- remember to check the number of datafiles in Primary FileGroup and make sure it matches the the ln 58
 
if object_id('tempdb..#t') is not null
    drop table #t
go
 
create table #t (name_table nvarchar(128), rows nvarchar(128), reserved nvarchar(128),
data nvarchar(128), index_size nvarchar(128), unused nvarchar(128))
 
use MedRx
declare @clause nvarchar(2000)
EXEC sp_MSforeachtable '
begin try
if ''?'' <> ''[dbo].[SysProcesses]''
insert into #t EXEC sp_spaceused @objname = ''?''
end try
begin catch
    select ''?'' as [Full Name]
end catch
'
 
 
select *,  sum(tt_size) over (partition by FileGroupName) as FG_Size_inMB from (
select distinct full_name , 1 DiskNum, rows, tt_size, FileGroupName
from (
 --same filegroup
 select full_name, datafilename, pk_name, rows, num_ind, reserved_MB as tt_size ,      
    'FG_MedRx_E'  FileGroupName
 from
 (select  '['+SCHEMA_NAME(schema_id) +'].['+ name_table+']' as full_name ,
convert(bigint,rows)  [rows],
convert(bigint,substring(reserved,0,CHARINDEX(' ', reserved)))/1024 reserved_MB, -- [reserved_MB = data_MB + index_size_MB + unused_MB ]
convert(bigint,substring(data,0,CHARINDEX(' ', data)))/1024 data_MB,
convert(bigint,substring(index_size,0,CHARINDEX(' ', index_size)))/1024 index_size_MB,
convert(bigint,substring(unused,0,CHARINDEX(' ', unused)))/1024 unused_MB, GETDATE() dateInsert , DB_NAME() [db_name], name_table tableName
 from #t a
join MedRx.sys.tables b on a.name_table = b.name
) a
join
 --exclude table with pk
 (SELECT OBJECT_NAME([si].[object_id]) AS [tablename]
    ,[ds].[name] AS [filegroupname]
    ,[df].[physical_name] AS [datafilename]
    , df.name as FileLogicalName, si.name pk_name, ni.num_ind
FROM [sys].[data_spaces] [ds]
--Contains a row per file of a database as stored = [database_files]
INNER JOIN [sys].[database_files] [df] ON [ds].[data_space_id] = [df].[data_space_id]
INNER JOIN [sys].[indexes] [si] ON [si].[data_space_id] = [ds].[data_space_id]
    AND [si].[index_id] < 2
INNER JOIN [sys].[objects] [so] ON [si].[object_id] = [so].[object_id]
inner join (
select [so].[object_id], count([si].[index_id]) num_ind from [sys].[objects] [so]
join [sys].[indexes] [si] ON [si].[object_id] = [so].[object_id]
group by [so].[object_id]
) as ni  ON [si].[object_id] = [ni].[object_id]
WHERE [so].[type] = 'U' and  df.name in ('MedRx_Data','MedRx_Data_2', 'MedRx_Data_3') -- Datafiles in FileGroup named Primary
    AND [so].[is_ms_shipped] = 0 and si.name is not null
--ORDER BY [tablename] ASC;
) b on a.tableName = b.tablename
 
) tout
--where FileGroupName = 'FG_MedRx_E' and rows > 0 
) b
order by  full_name, FileGroupName, DiskNum asc
