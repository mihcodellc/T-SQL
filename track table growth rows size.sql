-- Created 7/8/2022 by Monktar Bello



--CREATE TABLE [dbo].[Tables_growth](
--	[id] [int] IDENTITY(1,1) NOT NULL,
--	[tableName] [nvarchar](128) NULL,
--	[rows] [bigint] NULL,
--	[reserved] [bigint] NULL,
--	[data] [bigint] NULL,
--	[index_size] [bigint] NULL,
--	[unused] [bigint] NULL,
--	[dateInsert] [datetime] NULL,
--	[db_name] [nvarchar](100) NULL,
--PRIMARY KEY CLUSTERED 
--(
--	[id] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95) ON [PRIMARY]
--) ON [PRIMARY]
--GO

--ALTER AUTHORIZATION ON [dbo].[Tables_growth] TO  SCHEMA OWNER 
--GO

--/****** Object:  Index [ix_Tables_growth_dateInsert]    Script Date: 8/17/2022 11:21:46 AM ******/
--CREATE NONCLUSTERED INDEX [ix_Tables_growth_dateInsert] ON [dbo].[Tables_growth]
--(
--	[dateInsert] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95) ON [PRIMARY]
--GO

--SET ANSI_PADDING ON
--GO

--/****** Object:  Index [ix_Tables_growth_name_table]    Script Date: 8/17/2022 11:21:46 AM ******/
--CREATE NONCLUSTERED INDEX [ix_Tables_growth_name_table] ON [dbo].[Tables_growth]
--(
--	[tableName] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95) ON [PRIMARY]
--GO



create table #t (name_table nvarchar(128), rows nvarchar(128), reserved nvarchar(128), 
data nvarchar(128), index_size nvarchar(128), unused nvarchar(128))

use UserDB
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

Insert into DBA_DB.dbo.Tables_growth
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

-- keep only one month of data
delete from DBA_DB.dbo.Tables_growth where dateInsert < DATEADD(day, -31, GETDATE())