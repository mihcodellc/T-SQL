--sys.dm_exec_requests.wait_resource: 10:1:1838184834
-- ie Db_ID:FileID:PageID
-- Step 1: Identify the Database
SELECT name AS DatabaseName, database_id 
FROM sys.databases 
WHERE database_id = 10;

-- Step 2: Identify the File within the Database
USE [YourDatabaseName];  -- Replace with the actual database name found in step 1
GO
10:1:373074200
10:10:264653301
10:12:11972442
SELECT name AS FileName, file_id 
FROM sys.database_files 
WHERE file_id = 10;

-- Step 3: Identify the Object using DBCC PAGE : in messages
DBCC TRACEON(3604);
GO
DBCC PAGE(10, 12, 11972442, 3); -- syntax below
GO
DBCC TRACEOFF(3604);

DBCC PAGE
(
['database name'|database id], -- can be the actual name or id of the database
file number, -- the file number where the page is found
page number, -- the page number within the file 
print option = [0|1|2|3] -- display option; each option provides differing levels of information
)

-- Step 4: Analyze the Output to find the Object Name
-- Replace [ObjectID] with the actual object ID found in the DBCC PAGE output
SELECT OBJECT_NAME(1778886200) AS ObjectName, * 
FROM sys.objects 
WHERE object_id = 1778886200;


select  name FK_name, object_name(fk.parent_object_id) tableColReferTo, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) referTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('extractoutput'),1)
			 union all
			 select  name FK_name, object_name(fk.parent_object_id) tableColReferTo, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) referTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('extractoutput'),1)
