Identify the wait resource

  --https://www.sqlservercentral.com/blogs/sql-server-deciphering-wait-resource

--->>>>>>>>>>>>>>find Page Wait Resource
  
--sys.dm_exec_requests.wait_resource: 10:1:1838184834
-- ie Db_ID:FileID:PageID
-- Step 1: Identify the Database
SELECT name AS DatabaseName, database_id 
FROM sys.databases 
WHERE database_id = 10;

-- Step 2: Identify the File within the Database
USE [YourDatabaseName];  -- Replace with the actual database name found in step 1
GO

SELECT name AS FileName, file_id 
FROM sys.database_files 
WHERE file_id = 9;

-- Step 3: Identify the Object using DBCC PAGE
DBCC TRACEON(3604);
GO
DBCC PAGE(10, 1, 1838184834, 3);
GO
DBCC TRACEOFF(3604);

-- Step 4: Analyze the Output to find the Object Name
-- Replace [ObjectID] with the actual object ID found in the DBCC PAGE output
SELECT OBJECT_NAME(849490155) AS ObjectName, * 
FROM sys.objects 
WHERE object_id = 849490155;



--->>>>>>>>>>>>>>find Key Wait Resource 
SELECT 
 o.name AS TableName, 
i.name AS IndexName,
SCHEMA_NAME(o.schema_id) AS SchemaName
FROM sys.partitions p JOIN sys.objects o ON p.OBJECT_ID = o.OBJECT_ID 
JOIN sys.indexes i ON p.OBJECT_ID = i.OBJECT_ID  AND p.index_id = i.index_id 
WHERE p.hobt_id = 72057594040811520
