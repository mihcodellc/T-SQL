/*============================================================================
  File:     sp_SQLskills_ListIndex.sql

  Summary:  Run against a TABLE will list ALL
            KEYS IN indexes !
					
  Date:     February 2021

  Version:	SQL Server 2017
------------------------------------------------------------------------------
  Written by Monktar Bello

  Most variables are inspired by sp_SQLskills ... on http://www.SQLskills.com
============================================================================*/

USE [master];
GO

IF OBJECTPROPERTY(OBJECT_ID('sp_SQLskills_ListIndex'), 'IsProcedure') = 1
	DROP PROCEDURE sp_SQLskills_ListIndex;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE [dbo].[sp_SQLskills_ListIndex]
(
    @ObjName nvarchar(776) = NULL		-- the table to check for consolidation
                                        -- when NULL it will check ALL tables
)
AS

SET NOCOUNT ON;


DECLARE @ObjID INT,			-- the object id of the table
		@DBName	sysname,
		@SchemaName sysname,
		@TableName sysname,
		@ExecStr NVARCHAR(4000);

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

-- Check to see the the table exists and initialize @ObjID.
IF @ObjName IS NOT NULL
BEGIN
    SELECT @ObjID = OBJECT_ID(@ObjName);
	
    IF @ObjID IS NULL
    BEGIN
        RAISERROR(15009,-1,-1,@ObjName,@DBName);
        -- select * from sys.messages where message_id = 15009
        RETURN (1);
    END;
END;
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
    @filter_definition nvarchar(max)


CREATE TABLE #IndexesKeys
(
    ObjName NVARCHAR(776),
    IndId smallint,
    Indname sysname,
    Keys	nvarchar(2126),
    type tinyint,			-- the index type
    groupid int,  			-- the filegroup id of an index
);


SELECT @SchemaName = PARSENAME(@ObjName, 2), @TableName= PARSENAME(@ObjName, 1);

IF @SchemaName IS NULL
    SELECT @SchemaName = SCHEMA_NAME();

	    
TRUNCATE TABLE #IndexesKeys;
    
DECLARE ms_crs_ind cursor local static for
    select i.index_id, i.[type], i.data_space_id, QUOTENAME(i.name, N']') AS name,
	   i.ignore_dup_key, i.is_unique, i.is_hypothetical, i.is_primary_key, i.is_unique_constraint,
	   s.auto_created, s.no_recompute, i.filter_definition, i.is_disabled
    from sys.indexes as i 
	   join sys.stats as s
		  on i.object_id = s.object_id 
				and i.index_id = s.stats_id
    where i.object_id = @objid
OPEN ms_crs_ind
FETCH ms_crs_ind into @indid, @type, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
	   @is_primary_key, @is_unique_key, @auto_created, @no_recompute, @filter_definition, @is_disabled
	
-- IF NO INDEX, QUIT
IF @@fetch_status < 0
BEGIN
    deallocate ms_crs_ind
    raiserror(15472,-1,-1,@objname) -- Object does not have any indexes.
    return (0)
END


WHILE @@fetch_status >= 0
BEGIN

    -- First we'll figure out what the keys are.
    declare @i int = 1, @thiskey nvarchar(131) -- 128+3

    select @thiskey = QUOTENAME(index_col(@objname, @indid, @i), N']')

    while (@thiskey is not null )
    begin
	   INSERT INTO #IndexesKeys
	   select @TableName, @indid, @indname, QUOTENAME(index_col(@objname, @indid, @i), N']'), @type, @groupid

	   SET @i = @i + 1

	   select @thiskey = QUOTENAME(index_col(@objname, @indid, @i), N']')
    end

     	
    -- Next index
    fetch ms_crs_ind into @indid, @type, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
	   @is_primary_key, @is_unique_key, @auto_created, @no_recompute, @filter_definition, @is_disabled
END
DEALLOCATE ms_crs_ind
    

-- DISPLAY THE RESULTS

SELECT ObjName, IndId, Indname, Keys, type, groupid
FROM #IndexesKeys

IF OBJECT_ID('TempDB..#IndexesKeys') IS NOT NULL
    DROP TABLE #IndexesKeys

RETURN (0); 
GO

EXEC sys.sp_MS_marksystemobject 'sp_SQLskills_ListIndex';
GO