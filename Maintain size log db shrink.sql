-- https://www.brentozar.com/archive/2017/12/whats-bad-shrinking-databases-dbcc-shrinkdatabase/
-- https://www.brentozar.com/blitz/transaction-log-larger-than-data-file/

-- Shrinking databases and rebuilding indexes is a vicious cycle.
	-- shrink => fragmentation
	-- rebuild => lot of empty space around
	
	-- normal to see transaction logs at 10-50% of the size of the data files.
	
-- DBCC SHRINKFILE instead of 	DBCC SHRINKDATABASE

-- Simply using REORGANIZE rather than REBUILD avoids the vicious circle of shrinking 
	-- and growing
	
	-- https://dba.stackexchange.com/questions/7917/how-to-determine-used-free-space-within-sql-database-files/7921#7921
SELECT 
    [TYPE] = A.TYPE_DESC
    ,[FILE_Name] = A.name
    ,[FILEGROUP_NAME] = fg.name
    ,[File_Location] = A.PHYSICAL_NAME
    ,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
    ,[USEDSPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0))
    ,[FREESPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)
    ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)/(A.SIZE/128.0))*100)
    ,[AutoGrow] = 'By ' + CASE is_percent_growth WHEN 0 THEN CAST(growth/128 AS VARCHAR(10)) + ' MB -' 
        WHEN 1 THEN CAST(growth AS VARCHAR(10)) + '% -' ELSE '' END 
        + CASE max_size WHEN 0 THEN 'DISABLED' WHEN -1 THEN ' Unrestricted' 
            ELSE ' Restricted to ' + CAST(max_size/(128*1024) AS VARCHAR(10)) + ' GB' END 
        + CASE is_percent_growth WHEN 1 THEN ' [autogrowth by percent, BAD setting!]' ELSE '' END
FROM sys.database_files A LEFT JOIN sys.filegroups fg ON A.data_space_id = fg.data_space_id 
order by A.TYPE desc, A.NAME;


-- why each database’s log file isn’t clearing out
SELECT name, log_reuse_wait_desc FROM sys.databases;	

USE dba_db;  
GO  
DBCC SHRINKFILE (dba_db, 20992); –- size it to 20GB
GO  

--truncate only with SHRINKFILE	
USE dba_db;  
GO 
DBCC SHRINKFILE (5, TRUNCATEONLY); -
