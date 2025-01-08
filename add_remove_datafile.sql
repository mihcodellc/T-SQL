--**********prep the db files and locations
--**check datafile
--check 
 SELECT 'ALTER DATABASE [' + db_name() +'] MODIFY FILE ( NAME = N''' + name +''', SIZE = 100663296KB , FILEGROWTH = 1048576KB );' ,  is_percent_growth, physical_name 
 FROM sys.database_files

--**emptyfile
 SELECT 'DBCC SHRINKFILE (''' + name +''',EMPTYFILE);' ,  is_percent_growth, physical_name 
FROM sys.database_files
--**remove file
 SELECT 'ALTER DATABASE [tempdb] remove file ' + name ,  is_percent_growth, physical_name 
FROM sys.database_files

USE [master]
GO
----**resize file
 SELECT 'ALTER DATABASE [' + db_name() +'] MODIFY FILE ( NAME = N''' + name +''', SIZE = 100663296KB , FILEGROWTH = 1048576KB );' ,  is_percent_growth, physical_name 
 FROM sys.database_files

 -- 26214400KB -- 25GB
 -- 100663296KB -- 96GB
 -- 67108864KB  --64GB
 --1048576KB  --1024MB

--***add datafile
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_25', FILENAME = N'T:\MSSQL\tempdb_mssql_20.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
