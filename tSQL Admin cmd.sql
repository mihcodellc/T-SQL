--ONLINE OPERATION
ALTER INDEX ALL ON Person.Address REORGANIZE

ALTER DATABASE AdventureWorks2016 
SET AUTO_UPDATE_STATISTICS ON, AUTO_UPDATE_STATISTICS_ASYNC ON

EXEC sp_autostats 'Person.Address' -- ,'ON'

DBCC SHOW_STATISTICS ("Person.Address", AK_Address_rowguid); 

--RECOMMAND FOR OFFLINE
DBCC DBREINDEX('Person.Address','',70);

--LOG space usage
DBCC SQLPERF (LOGSPACE)

-- Import & Export
--bcp "SELECT * FROM AdventureWorks2012.Person.Person WHERE FirstName='Jarrod' AND LastName='Rana' "  queryout "Jarrod Rana.dat" -T -c
--bcp AdventureWorks2016.Sales.Currency format nul -T -c -x -f Currency.xml
BULK INSERT AdventureWorks2016.Sales.SalesOrderDetail FROM 'c:\data\test.txt'
GO