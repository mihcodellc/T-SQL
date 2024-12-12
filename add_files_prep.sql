--run server trigger to prevent others logins to interfer

--stop sql server agent

--stop sql service

-- have IT do their work

--start sql service


--downsize to 96GB for existing datafiles

--**********prep the db files and locations
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

go



--**new datafile
USE [master]
GO
--ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_6', FILENAME = N'T:\MSSQL\tempdb_mssql_6.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
--GO
--ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_7', FILENAME = N'T:\MSSQL\tempdb_mssql_7.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
--GO
--ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_8', FILENAME = N'T:\MSSQL\tempdb_mssql_8.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
--GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_9', FILENAME = N'T:\MSSQL\tempdb_mssql_9.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_10', FILENAME = N'T:\MSSQL\tempdb_mssql_10.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_11', FILENAME = N'T:\MSSQL\tempdb_mssql_11.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_12', FILENAME = N'T:\MSSQL\tempdb_mssql_12.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_13', FILENAME = N'T:\MSSQL\tempdb_mssql_13.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_14', FILENAME = N'T:\MSSQL\tempdb_mssql_14.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_15', FILENAME = N'T:\MSSQL\tempdb_mssql_15.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_16', FILENAME = N'T:\MSSQL\tempdb_mssql_16.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_17', FILENAME = N'T:\MSSQL\tempdb_mssql_17.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_18', FILENAME = N'T:\MSSQL\tempdb_mssql_18.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_19', FILENAME = N'T:\MSSQL\tempdb_mssql_19.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb_mssql_20', FILENAME = N'T:\MSSQL\tempdb_mssql_20.ndf' , SIZE = 100663296KB , FILEGROWTH = 1048576KB )
GO


--check tempdb internal size close to zero 

--restart

--check tempdb internal size close to zero 

----7 drop the trigger
--drop TRIGGER connection_limit_trigger
--ON ALL SERVER --WITH EXECUTE AS 'login_test'


--8 enable SQL Agent

--other checks
