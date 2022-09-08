-- https://callihandata.com/2022/09/03/use-sp_ineachdb-instead-of-sp_msforeachdb/

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME()  SELECT * FROM SYS.tables WHERE NAME LIKE ''%RecordTypes%'' order by name;'

--preferred sp_ineachdb developed by Aaron Bertrand as an alternative to sp_MSforeachdb.
EXEC sp_ineachdb @command = N'SELECT DB_NAME()  SELECT * FROM SYS.tables WHERE NAME LIKE ''%RecordTypes%'' order by name;'
