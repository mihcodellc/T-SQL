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


-- partition switch table 
https://www.cathrinewilhelmsen.net/2015/04/19/table-partitioning-in-sql-server-partition-switching/
-- Create the Partition Function 
CREATE PARTITION FUNCTION pfSales (DATE) AS RANGE RIGHT FOR VALUES ('2013-01-01', '2014-01-01', '2015-01-01');
 
-- Create the Partition Scheme 
CREATE PARTITION SCHEME psSales AS PARTITION pfSales ALL TO ([Primary]);

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