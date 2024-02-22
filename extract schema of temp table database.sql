-- extract db schema
--https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-clonedatabase-transact-sql?view=sql-server-ver16
DBCC CLONEDATABASE (AdventureWorks2022, AdventureWorks_Clone);
GO
-- use to extract the schema of temp table or simply into MyTable then extract with management studio

SELECT * INTO #table1 FROM TableQuery


SELECT char(9) + '[' + c.column_name + '] ' + c.data_type 
   + CASE 
        WHEN c.data_type IN ('decimal')
            THEN isnull('(' + convert(varchar, c.numeric_precision) + ', ' + convert(varchar, c.numeric_scale) + ')', '') 
        WHEN c.data_type IN ('varchar', 'nvarchar', 'char', 'nchar')
            THEN isnull('(' 
                + CASE WHEN c.character_maximum_length = -1
                    THEN 'max'
                    ELSE convert(varchar, c.character_maximum_length) 
                  END + ')', '')
        ELSE '' END
   + CASE WHEN c.IS_NULLABLE = 'YES' THEN ' NULL' ELSE '' END
   + ','
FROM tempdb.INFORMATION_SCHEMA.COLUMNS c 
WHERE TABLE_NAME LIKE '#table1%' 
ORDER BY c.ordinal_position


drop table #table1
