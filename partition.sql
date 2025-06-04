
-- https://callihandata.com/2021/08/22/moving-data-to-a-new-filegroup/

ALTER DATABASE WideWorldImporters
ADD FILEGROUP Test1FG1;

ALTER DATABASE WideWorldImporters
ADD FILE
(
    NAME = test1dat1,
    FILENAME = 'E:\MSSQL\t1dat2.ndf',
    SIZE = 50MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP Test1FG1;
GO

--check the filegroup
SELECT * FROM sys.filegroups;


-- Coping Data From PRIMARY Starting with SQL 2016 SP2
-- no need to create Sales.Orders_Archive
SELECT * INTO Sales.Orders_Archive ON Test1FG1
FROM sales.Orders
where OrderID > 50000

--Check
SELECT * FROM Sales.Orders_Archive;
SELECT * FROM Sales.Orders;
GO

	-- where are my tables,  filegroup information
SELECT OBJECT_NAME([si].[object_id]) AS [tablename]
    ,[ds].[name] AS [filegroupname]
    ,[df].[physical_name] AS [datafilename]
    , df.name as FileLogicalName, index_id
FROM [sys].[data_spaces] [ds]
--Contains a row per file of a database as stored = [database_files]
INNER JOIN [sys].[database_files] [df] ON [ds].[data_space_id] = [df].[data_space_id]
INNER JOIN [sys].[indexes] [si] ON [si].[data_space_id] = [ds].[data_space_id]
    AND [si].[index_id] < 2
INNER JOIN [sys].[objects] [so] ON [si].[object_id] = [so].[object_id]
WHERE [so].[type] = 'U' and OBJECT_NAME([si].[object_id]) like '%Orders%'
    AND [so].[is_ms_shipped] = 0
ORDER BY [tablename] ASC;

--ALTER DATABASE WideWorldImporters
--ADD FILEGROUP Test1FG2;

--ALTER DATABASE WideWorldImporters
--ADD FILE
--(
--    NAME = test1dat2,
--    FILENAME = 'E:\MSSQL\t1dat1.ndf',
--    SIZE = 50MB,
--    MAXSIZE = 100MB,
--    FILEGROWTH = 5MB
--)
--TO FILEGROUP Test1FG1;
--GO

--************************start
-- add new date column 
--Create a partition function. ? column unsure at this time? can we alter the function in future to accomodate the change in this table
--Create a partition scheme.
--Create a new partitioned table.
--Move data to the new partitioned table. ? just is needed at this time 6months
--Drop any foreign key constraints on the existing table.
--Switch the existing table to the new partitioned table.? what switch is doing ?
--Rename the tables.
--Recreate foreign key constraints.
--Drop the old table.

--check who is using my partition scheme extractoutput_archive_PartitionScheme
SELECT 
    s.name AS SchemaName,
    o.name AS ObjectName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ps.name AS PartitionSchemeName
FROM 
    sys.indexes i
JOIN 
    sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
JOIN 
    sys.objects o ON i.object_id = o.object_id
JOIN 
    sys.schemas s ON o.schema_id = s.schema_id
WHERE 
    ps.name = 'extractoutput_archive_PartitionScheme';

--DROP PARTITION order
DROP INDEX ix_ExtractOutput_datecreated ON extractoutput
GO
drop PARTITION SCHEME extractoutput_PartitionScheme
GO
DROP PARTITION FUNCTION pf_extractoutput 



--drop PARTITION FUNCTION pf_salesYearPartitions 
create PARTITION FUNCTION pf_salesYearPartitions (int)
AS RANGE RIGHT FOR VALUES ( '40000')
GO

--drop PARTITION SCHEME Test_PartitionScheme
create PARTITION SCHEME Test_PartitionScheme
AS PARTITION pf_salesYearPartitions
--TO (Test1FG1, Test1FG2)
ALL TO (Test1FG1)
--ALL TO (USERDATA)

--create the partitioning version with the partition scheme
CREATE TABLE [dbo].[MyTable_partioning](
	id, col1, col2
 CONSTRAINT [PK_MyTable_partioning] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
) ON MyTable_PartitionScheme ([id]);

CREATE NONCLUSTERED INDEX IX_MyTable_recordtype ON [dbo].MyTable ( col2 ) 
WITH (FILLFACTOR=95, ONLINE=ON, DROP_EXISTING = ON) ON LoaderRecordType_PartitionScheme(RecordType); 


CREATE UNIQUE CLUSTERED INDEX PK_MyTable ON [dbo].MyTable 
( [id] ) WITH (FILLFACTOR=90, ONLINE=ON, DROP_EXISTING = ON) ON MyTable_Id_PartitionScheme(id); --55min

--check the partition
SELECT ps.name,pf.name,boundary_id,value
FROM sys.partition_schemes ps
INNER JOIN sys.partition_functions pf ON pf.function_id=ps.function_id
INNER JOIN sys.partition_range_values prf ON pf.function_id=prf.function_id

-- data on partition
SELECT partition_id, index_id, partition_number, Rows, OBJECT_NAME(OBJECT_ID) 
FROM sys.partitions
WHERE OBJECT_NAME(OBJECT_ID)='Orders_P'
GO

SELECT partition_id, index_id, partition_number, Rows, OBJECT_NAME(OBJECT_ID)
FROM sys.partitions
WHERE OBJECT_NAME(OBJECT_ID)='Orders' 
GO


--move data to new table
SET IDENTITY_INSERT dbo.MyTable ON
INSERT INTO [MyTable_partioning] (col1, col2, ...)
SELECT col1, col2, ...
FROM MyTable b
where ID > 357079933

SET IDENTITY_INSERT dbo.MyTable OFF

SELECT * INTO UserLogHistory FROM UserLog

--Drop Foreign Key Constraints (If Any)

--Switch the Existing Table to the New Partitioned Table
ALTER TABLE Sales SWITCH TO NewSales;
ALTER TABLE Sales.Orders SWITCH TO Sales.Orders_P PARTITION 1

--Rename the Tables
EXEC sp_rename 'Sales', 'OldSales';
EXEC sp_rename 'NewSales', 'Sales';

--Recreate foreign key constraints.

--Drop the old table.



	-- where are my tables,  filegroup information
SELECT OBJECT_NAME([si].[object_id]) AS [tablename]
    ,[ds].[name] AS [filegroupname]
    ,[df].[physical_name] AS [datafilename]
    , df.name as FileLogicalName, index_id
FROM [sys].[data_spaces] [ds]
--Contains a row per file of a database as stored = [database_files]
INNER JOIN [sys].[database_files] [df] ON [ds].[data_space_id] = [df].[data_space_id]
INNER JOIN [sys].[indexes] [si] ON [si].[data_space_id] = [ds].[data_space_id]
    --AND [si].[index_id] < 2
INNER JOIN [sys].[objects] [so] ON [si].[object_id] = [so].[object_id]
WHERE [so].[type] = 'U' and OBJECT_NAME([si].[object_id]) like '%Orders%'
    AND [so].[is_ms_shipped] = 0
ORDER BY [tablename] ASC;




