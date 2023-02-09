-- https://learn.microsoft.com/en-us/sql/t-sql/functions/openquery-transact-sql?view=sql-server-ver16
-- https://learn.microsoft.com/en-us/sql/t-sql/functions/openrowset-transact-sql?view=sql-server-ver16

DECLARE @OpenQuery nvarchar(max)
DECLARE @output int
SET @OpenQuery = 'SELECT @output = incomingid FROM OpenQuery(POSTGRESQL, ''SELECT id From db1.schema1.table1 WHERE id = 33657702'')'
EXEC sp_executeSql @OpenQuery, N'@output BIGINT OUTPUT', @output OUTPUT
Select @output
