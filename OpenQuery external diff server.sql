-- https://learn.microsoft.com/en-us/sql/t-sql/functions/openquery-transact-sql?view=sql-server-ver16
-- https://learn.microsoft.com/en-us/sql/t-sql/functions/openrowset-transact-sql?view=sql-server-ver16

-- create linked server
EXEC sp_addlinkedserver 
    @server = 'YourLinkedServerName',
    @provider = 'MSDASQL',
    @datasrc = 'YourPostgreSQLServer',
    @location = '',
    @provstr = 'Driver={PostgreSQL ODBC Driver(UNICODE)};Server=YourPostgreSQLServer;Port=5432;Database=YourDatabase;UID=YourUsername;PWD=YourPassword;';


DECLARE @OpenQuery nvarchar(max)
DECLARE @output int
SET @OpenQuery = 'SELECT @output = incomingid FROM OpenQuery(POSTGRESQL, ''SELECT id From db1.schema1.table1 WHERE id = 33657702'')'
EXEC sp_executeSql @OpenQuery, N'@output BIGINT OUTPUT', @output OUTPUT
Select @output


-- insert into postgres
INSERT INTO OPENQUERY(YourLinkedServerName, 'SELECT column1, column2 FROM YourPostgreSQLTable')
SELECT column1, column2 FROM YourSQLServerTable;

--insert into SQL Server
INSERT INTO YourSQLServerTable (Column1, Column2, Column3)
SELECT Column1, Column2, Column3
FROM OPENQUERY(POSTGRESQL, 'select Column1, Column2, Column3 FROM YourPostgreSQLTable');


-- update postgres
update namedTable_PG
    set namedTable_PG.col1 = namedTable_SQL.col1
from namedTable_SQL 
    join OPENQUERY(POSTGRESQL, 'select Column1, Column2, Column3 FROM YourPostgreSQLTable') namedTable_PG 
        on namedTable_PG.colid = namedTable_SQL.colid
where namedTable_PG.colid  = X  
