-- https://www.mssqltips.com/sqlservertip/5832/move-sql-server-tables-to-different-filegroups/
-- https://docs.microsoft.com/en-us/sql/relational-databases/indexes/move-an-existing-index-to-a-different-filegroup?view=sql-server-ver16

--add file group
ALTER DATABASE WideWorldImporters ADD FILEGROUP [FG_Orders]
GO


--add file
ALTER DATABASE WideWorldImporters ADD FILE (
	NAME = N'FG_File_Orders'
	,FILENAME = N'E:\MSSQL\Data\Order_File.mdf'
	,SIZE = 100MB
	,FILEGROWTH = 10MB
	,MAXSIZE = 100MB
	) TO FILEGROUP [FG_Orders]
GO

USE WideWorldImporters
GO
SET STATISTICS PROFILE ON
GO

--Moving table with a clustered index 
--description:
--https://docs.microsoft.com/en-us/sql/t-sql/statements/create-index-transact-sql?view=sql-server-ver16
--this portion
--Because the leaf level of a clustered index and the data pages are the same by definition, creating a clustered index and using the ON partition_scheme_name or ON filegroup_name clause effectively moves a table from the filegroup on which the table was created to the new partition scheme or filegroup. Before creating tables or indexes on specific filegroups, verify which filegroups are available and that they have enough empty space for the index.
CREATE UNIQUE CLUSTERED INDEX PK_Sales_Orders ON Sales.Orders (OrderID)
	WITH (DROP_EXISTING = ON, ONLINE = ON, FILLFACTOR = 90) ON [FG_Orders]