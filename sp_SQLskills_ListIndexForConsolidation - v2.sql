/*============================================================================
  File:     sp_SQLskills_ListIndexForConsolidation.sql

  Summary:  Run against a single database this procedure will list ALL
            indexes that could be combined!
		  IF @ObjName and @KeysFilter not null,it returns
		  for each candidate index, the last top 5 queries using it 
		  allowing to measure the impact of your consolidation
					
  Date:     February 2021

  Version:	SQL Server 2017
------------------------------------------------------------------------------
  Written by Monktar Bello

  Most variables are inspired by sp_SQLskills ... on http://www.SQLskills.com
============================================================================*/

USE [master];
GO

IF OBJECTPROPERTY(OBJECT_ID('sp_SQLskills_ListIndexForConsolidation'), 'IsProcedure') = 1
	DROP PROCEDURE [sp_SQLskills_ListIndexForConsolidation];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE [dbo].[sp_SQLskills_ListIndexForConsolidation]
(
    @ObjName nvarchar(776) = NULL,		-- the table to check for consolidation
                                        -- when NULL it will check ALL tables
    @KeysFilter nvarchar(2126) = NULL
)
AS

SET NOCOUNT ON;

-- Run example: exec sp_SQLskills_ListIndexForConsolidation 'TableName', '[AkeyInIndex]'


DECLARE @ObjID INT,			-- the object id of the table
		@DBName	sysname,
		@SchemaName sysname,
		@TableName sysname,
		@ExecStr NVARCHAR(4000);

DECLARE 		
    @indid smallint,		-- the index id of an index
    @type tinyint,			-- the index type
    @groupid int,  			-- the filegroup id of an index
    @indname sysname,
    @groupname sysname,
    @status int,
    @keys nvarchar(2126),	--Length (16*max_identifierLength)+(15*2)+(16*3)
    @inc_columns nvarchar(max),
    @inc_Count smallint,
    @loop_inc_Count smallint,
    @ignore_dup_key	bit,
    @is_unique bit,
    @is_hypothetical bit,
    @is_primary_key	bit,
    @is_unique_key bit,
    @is_disabled bit,
    @auto_created bit,
    @no_recompute bit,
    @filter_definition nvarchar(max),
    @index_keys nvarchar(2126)

-- Check to see that the object names are local to the current database.
SELECT @DBName = PARSENAME(@ObjName,3);

IF @DBName IS NULL
    SELECT @DBName = DB_NAME();
ELSE 
IF @DBName <> DB_NAME()
    BEGIN
	    RAISERROR(15250,-1,-1);
	    -- select * from sys.messages where message_id = 15250
	    RETURN (1);
    END;

IF @DBName = N'tempdb'
    BEGIN
	    RAISERROR('WARNING: This procedure cannot be run against tempdb. Skipping tempdb.', 10, 0);
	    RETURN (1);
    END;

-- Check to see the the table exists and initialize @ObjID.
SELECT @SchemaName = PARSENAME(@ObjName, 2);

IF @SchemaName IS NULL
    SELECT @SchemaName = SCHEMA_NAME();

---- Check to see the the table exists and initialize @ObjID.
--IF @ObjName IS NOT NULL
--BEGIN
--    SELECT @ObjID = OBJECT_ID(@ObjName);
	
--    IF @ObjID IS NULL
--    BEGIN
--        --RAISERROR(15009,-1,-1,@ObjName,@DBName);
--        -- select * from sys.messages where message_id = 15009
--        RETURN (1);
--    END;
--END;

CREATE TABLE #ListIndexInfo
	(
		index_id			int,
		is_disabled         bit,
		index_name			sysname	collate database_default NOT NULL,
		index_description nvarchar(2000),
		index_keys			nvarchar(2126)	collate database_default NULL, -- see @keys above for length descr
		inc_columns			nvarchar(max),
		filter_definition	nvarchar(max),
		cols_in_tree		nvarchar(2126),
		cols_in_leaf		nvarchar(max),
		create_date		datetime, 
		objname nvarchar(776),
		[type]	     		tinyint,
		TypeDescription	nvarchar(max),
	) ; 

CREATE TABLE #FindKeysToConsolidate
(
    ObjName NVARCHAR(776),
    IndId smallint,
    Indname sysname,
    Keys	nvarchar(2126),
    type tinyint,			-- the index type
    groupid int,  			-- the filegroup id of an index
    index_keys nvarchar(2126),
    inc_columns nvarchar(max)
);

CREATE TABLE #IndexesKeys
(
    ObjName NVARCHAR(776),
    IndId smallint,
    Indname sysname,
    Keys	nvarchar(2126),
    type tinyint,			-- the index type
    groupid int,  			-- the filegroup id of an index
);


-- OPEN CURSOR OVER TABLE(S)
IF @ObjName IS NOT NULL
    DECLARE TableCursor CURSOR LOCAL STATIC FOR
        SELECT @SchemaName, PARSENAME(@ObjName, 1);
ELSE
    DECLARE TableCursor CURSOR LOCAL STATIC FOR 		    
        SELECT SCHEMA_NAME(uid), name 
        FROM sysobjects 
        WHERE type = 'U' --USER TABLE
        ORDER BY SCHEMA_NAME(uid), name;
	    
OPEN TableCursor; 

FETCH TableCursor
    INTO @SchemaName, @TableName;

-- For each table, list the add the duplicate indexes and save 
-- the info in a temporary table that we'll print out at the end.

WHILE @@fetch_status >= 0
BEGIN
     TRUNCATE TABLE #IndexesKeys;
	TRUNCATE TABLE #ListIndexInfo;

     --get key in all indexes of this table
     SELECT @ExecStr = 'EXEC sp_SQLskills_ListIndex ''' 
                        + QUOTENAME(@SchemaName) 
                        + N'.' 
                        + QUOTENAME(@TableName)
                        + N'''';

    INSERT #IndexesKeys
    EXEC (@ExecStr);  --EXEC sp_SQLskills_ListIndex @TableName
    
    --skip table without index
    IF NOT EXISTS(SELECT 1 FROM #IndexesKeys) 
    BEGIN
	   FETCH TableCursor INTO @SchemaName, @TableName;
	   CONTINUE;
	   --PRINT @TableName;
    END

    --retrieve keys and included columns for current table
    SELECT @ExecStr = 'EXEC sp_SQLskills_helpindex ''' 
                        + QUOTENAME(@SchemaName) 
                        + N'.' 
                        + QUOTENAME(@TableName)
                        + N''', 1';

    INSERT INTO #ListIndexInfo
	    EXEC (@ExecStr);  --EXEC sp_SQLskills_helpindex @TableName

    -- column in different key
    IF @KeysFilter IS NULL
	   INSERT INTO #FindKeysToConsolidate
	   SELECT a.ObjName, a.IndId, a.Indname, a.Keys, a.type, a.groupid, inf.index_keys, inc_columns 
	   FROM #IndexesKeys a
	   JOIN #IndexesKeys b 
		  ON a.ObjName = b.ObjName and a.Keys = b.Keys
	   JOIN #ListIndexInfo inf 
		  ON a.ObjName = PARSENAME(inf.objname, 1) and a.IndId = inf.index_id
	   GROUP BY a.ObjName, a.Keys, a.IndId, a.type, a.Indname, a.groupid, inf.index_keys, inc_columns
	   HAVING COUNT(1) > 1
	   ORDER BY a.ObjName, a.Keys
    ELSE
	   INSERT INTO #FindKeysToConsolidate
	   SELECT a.ObjName, a.IndId, a.Indname, a.Keys, a.type, a.groupid, inf.index_keys, inc_columns 
	   FROM #IndexesKeys a
	   JOIN #IndexesKeys b 
		  ON a.ObjName = b.ObjName and a.Keys = b.Keys
	   JOIN #ListIndexInfo inf 
		  ON a.ObjName = PARSENAME(inf.objname, 1) and a.IndId = inf.index_id
	   WHERE a.Keys = @KeysFilter 
	   GROUP BY a.ObjName, a.Keys, a.IndId, a.type, a.Indname, a.groupid, inf.index_keys, inc_columns
	   HAVING COUNT(1) > 1
	   ORDER BY a.ObjName, a.Keys


    FETCH TableCursor
        INTO @SchemaName, @TableName;
END;
	
DEALLOCATE TableCursor;

-- DISPLAY THE RESULTS

IF (SELECT COUNT(*) FROM #FindKeysToConsolidate) = 0
	    RAISERROR('Database: %s has NO possible indexes'' consolidation .', 10, 0, @DBName);
ELSE
BEGIN
    SELECT ObjName, Keys, IndId, index_keys, inc_columns, PARSENAME(Indname, 1) Indname , type, groupid 
    FROM #FindKeysToConsolidate
    ORDER BY ObjName, Keys;

    IF @KeysFilter IS NOT NULL  AND @ObjName IS NOT NULL
    BEGIN
	   DECLARE itsQueryCursor CURSOR FOR
		  SELECT PARSENAME(Indname, 1) Indname, index_keys FROM #FindKeysToConsolidate
		  ORDER BY Indname;
	   OPEN itsQueryCursor;

	   FETCH NEXT FROM itsQueryCursor INTO  @indname, @index_keys
	   WHILE @@FETCH_STATUS = 0
	   BEGIN
			 SELECT TOP 5 @indname indname, @index_keys index_keys, querystats.last_execution_time , querystats.total_logical_reads , querystats.total_logical_writes,  
				SUBSTRING(sqltext.text, (querystats.statement_start_offset / 2) + 1, 
						  (CASE querystats.statement_end_offset 
							 WHEN -1 THEN DATALENGTH(sqltext.text) 
							 ELSE querystats.statement_end_offset 
						  END - querystats.statement_start_offset) / 2 + 1) AS sqltext 
			 FROM sys.dm_exec_query_stats as querystats
			 CROSS APPLY sys.dm_exec_text_query_plan
				(querystats.plan_handle, querystats.statement_start_offset, querystats.statement_end_offset) 
				as textplan
			 CROSS APPLY sys.dm_exec_sql_text(querystats.sql_handle) AS sqltext 
			 WHERE 
				textplan.query_plan like '%' + @indname + '%'
			 ORDER BY querystats.last_execution_time DESC, querystats.total_logical_reads DESC, querystats.total_logical_writes DESC 
			 OPTION (RECOMPILE);
		  FETCH NEXT FROM itsQueryCursor INTO @indname, @index_keys
	   END
	   DEALLOCATE itsQueryCursor;

    END
END
RETURN (0); 
GO

EXEC sys.sp_MS_marksystemobject 'sp_SQLskills_ListIndexForConsolidation';
GO