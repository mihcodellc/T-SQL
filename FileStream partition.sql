EXEC sp_configure filestream_access_level,2
RECONFIGURE

USE master
GO
ALTER DATABASE AdventureWorks2016 
ADD FILEGROUP FileStreamFileGroup CONTAINS FILESTREAM;
GO

CREATE DATABASE FileTableDB ON PRIMARY
(Name = FileTableDB, FILENAME = 'c:\test\FTDB.mdf'), FILEGROUP FTFG CONTAINS FILESTREAM
(NAME = FileTableFS, FILENAME='c:\test\FS')
LOG ON (Name = FileTableDBLog, FILENAME = 'c:\test\FTDBLog.ldf')
WITH FILESTREAM (NON_TRANSACTED_ACCESS = FULL,DIRECTORY_NAME = N'FileTableDB');
GO

-- data on partition
SELECT partition_id, index_id, partition_number, Rows, OBJECT_NAME(OBJECT_ID) 
FROM sys.partitions
WHERE OBJECT_NAME(OBJECT_ID)='Orders_P' -- source table
GO

	-- where are my tables
SELECT OBJECT_NAME([si].[object_id]) AS [tablename]
    ,[ds].[name] AS [filegroupname]
    ,[df].[physical_name] AS [datafilename]
    , df.name as FileLogicalName
FROM [sys].[data_spaces] [ds]
--Contains a row per file of a database as stored = [database_files]
INNER JOIN [sys].[database_files] [df] ON [ds].[data_space_id] = [df].[data_space_id]
INNER JOIN [sys].[indexes] [si] ON [si].[data_space_id] = [ds].[data_space_id]
    AND [si].[index_id] < 2
INNER JOIN [sys].[objects] [so] ON [si].[object_id] = [so].[object_id]
WHERE [so].[type] = 'U' and OBJECT_NAME([si].[object_id]) ='Orders'
    AND [so].[is_ms_shipped] = 0
ORDER BY [tablename] ASC;


SELECT partition_id, index_id, partition_number, Rows, OBJECT_NAME(OBJECT_ID) 
FROM sys.partitions
WHERE OBJECT_NAME(OBJECT_ID)='Orders' -- target table
GO

 -- CREATE FILEGROUP > PARTITION FUNCTION > PARTITION SCHEME(partition to filegroup ) 	> INDEX OR TABLE.
 -- requirements
 -- https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms191160(v=sql.105)
 
-- partition switch table 
https://www.cathrinewilhelmsen.net/2015/04/19/table-partitioning-in-sql-server-partition-switching/
-- Create the Partition Function : col1 <= '2013-01-01' 
--								   col1 > '2013-01-01' AND col1 <= '2014-01-01' 
--								   col1 > '2014-01-01'
-- for range right the strict '<' will be on right
CREATE PARTITION FUNCTION pfSales (DATE) AS RANGE LEFT FOR VALUES ('2013-01-01', '2014-01-01');
 
-- Create the Partition Scheme : partition to filegroup
CREATE PARTITION SCHEME psSales AS PARTITION pfSales ALL TO ([Primary]);
 -- or
CREATE PARTITION SCHEME psSales AS PARTITION pfSales TO (test1fg, test2fg, test3fg, test4fg); -- test1fg ... are filegroups 

--ALTER TABLE Source SWITCH PARTITON 1 TO Target PARTITION 1

--ALTER PARTITION FUNCTION fctionPart2 SPLIT RANGE (datLastYear)
--ALTER TABLE Source SWITCH PARTITON 1 TO Target PARTITION 3
--ALTER PARTITION FUNCTION fctionPart1() MERGE RANGE (datLastYear) --delete partition/move data
--ALTER PARTITION FUNCTION fctionPart2() MERGE RANGE (datOldestMoved) --delete partition/move data
--ALTER PARTITION FUNCTION fctionPart1() SPLIT RANGE (datLastMonth)

use msdb 
exec dbo.sp_help_proxy

-- owner of securables
ALTER AUTHORIZATION ON OBJECT::Parts.Sprockets TO MichikoOsada;
GO


-- 
SELECT s.group_id, CAST(g.name as nvarchar(20)), s.session_id, s.login_time, 
    CAST(s.host_name as nvarchar(20)), CAST(s.program_name AS nvarchar(20))  
FROM sys.dm_exec_sessions AS s  
INNER JOIN sys.dm_resource_governor_workload_groups AS g  
    ON g.group_id = s.group_id  
ORDER BY g.name; 


SELECT * FROM sys.dm_resource_governor_resource_pools;  
SELECT * FROM sys.dm_resource_governor_workload_groups;

-- assigning permissions
Use AdventureWorks2016 GRANT SELECT, INSERT, UPDATE ON Person.Address
TO "PRACTICELABS\Rebecca"
