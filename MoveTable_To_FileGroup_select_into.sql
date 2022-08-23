-- https://docs.microsoft.com/en-us/sql/relational-databases/indexes/move-an-existing-index-to-a-different-filegroup?view=sql-server-ver16
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
    --AND [si].[index_id] < 2
INNER JOIN [sys].[objects] [so] ON [si].[object_id] = [so].[object_id]
WHERE [so].[type] = 'U' and OBJECT_NAME([si].[object_id]) like '%Orders%'
    AND [so].[is_ms_shipped] = 0
ORDER BY [tablename] ASC;