
create table DBA_DB.dbo.RMSTables_growth (id int identity(1,1) primary key, tableName nvarchar(128) , rows bigint, reserved bigint, 
data bigint, index_size bigint, unused bigint, dateInsert datetime)
 
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

Insert into DBA_DB.dbo.RMSTables_growth
select name_table,
convert(bigint,rows)  rows,
convert(bigint,substring(reserved,0,CHARINDEX(' ', reserved)))/1024 reserved_MB,
convert(bigint,substring(data,0,CHARINDEX(' ', data)))/1024 data_MB,
convert(bigint,substring(index_size,0,CHARINDEX(' ', index_size)))/1024 index_size_MB,
convert(bigint,substring(unused,0,CHARINDEX(' ', unused)))/1024 unused_MB, GETDATE(), DB_NAME() 
 from #t
where rows > 0 order by data_MB desc, name_table     

if object_id('tempdb..#t') is not null
    drop table #t


 --previous version


use DBA_DB

select 'space use per table'

create table DBA_DB.dbo.RMSTables_growth (id int identity(1,1) primary key, tableName nvarchar(128) , rows bigint, reserved bigint, 
data bigint, index_size bigint, unused bigint, dateInsert datetime)

----to reseed
--DBCC CHECKIDENT('dbo.RMSTables_growth', RESEED, 1)

create nonclustered index ix_RMSTables_growth_name_table on dbo.RMSTables_growth (tableName)
create nonclustered index ix_RMSTables_growth_dateInsert on dbo.RMSTables_growth (dateInsert)

--Step 1
create table #t (name_table nvarchar(128), rows nvarchar(128), reserved nvarchar(128), 
data nvarchar(128), index_size nvarchar(128), unused nvarchar(128))
--truncate table #t
--Step 2
--run on db concerned the ouput excluding, if exist, this line insert into #t EXEC sp_spaceused @objname = [dbo.SysProcesses]
use MyDB
declare @clause nvarchar(2000)
select 'insert into #t EXEC sp_spaceused @objname = [' + SCHEMA_NAME(schema_id) +'.'+ name + ']'+char(9)+char(10)  from  
sys.tables 
where name not like '%SysProcesses%'
order by name
-- OUTPUT here
--*******************
--*******************
-- Step 3
Insert into DBA_DB.dbo.Tables_growth
select name_table,
cast(rows as bigint) rows,
cast(substring(reserved,0,CHARINDEX(' ', reserved)) as bigint)/128 reserved_MB,
cast(substring(data,0,CHARINDEX(' ', data)) as bigint)/128 data_MB,
cast(substring(index_size,0,CHARINDEX(' ', index_size))/128 as bigint) index_size_MB,
cast(substring(unused,0,CHARINDEX(' ', unused)) as bigint)/128 unused_MB, GETDATE() 
 from #t
where rows > 0 order by data_MB desc, name_table   
--Step 4
if object_id('tempdb..#t')> 0
    drop table #t

--Step 5 read
select a.*, SCHEMA_NAME(schema_id) +'.'+ b.name as full_name
from
DBA_DB.dbo.RMSTables_growth a
join MedRx.sys.tables b on a.tableName = b.name
order by a.data desc
