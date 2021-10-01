--SQL CRUD Generator

--***************************************
-- How to Use, go down and find @GenerateProcsFor around line 50 and set it to the table name you want to generate SPs for
-- If the @DatabaseName is different then you can go change it, around line 59
-- the @SchemeName and @TablePrefix as setup for how OrionNet Systems does it
--***************************************

-- #########################################################
-- Author:	www.sqlbook.com
-- Copyright:	(c) www.sqlbook.com. You are free to use and redistribute
--		this script as long as this comments section with the 
--		author and copyright details are not altered.
-- Purpose:	For a specified user defined table (or all user defined
--		tables) in the database this script generates 4 Stored 
--		Procedure definitions with different Procedure name 
--		suffixes:
--		1) List all records in the table (suffix of  _lst)
--		2) Get a specific record from the table (suffix of _sel)
--		3) UPDATE or INSERT (UPSERT) - (suffix of _ups)
--		4) DELETE a specified row - (suffix of _del)
--		e.g. For a table called location the script will create
--		procedure definitions for the following procedures:
--		dbo.udp_Location_lst
--		dbo.udp_Location_sel
--		dbo.udp_Location_ups
--		dbo.udp_Location_del
-- Notes: 	The stored procedure definitions can either be printed
--		to the screen or executed using EXEC sp_ExecuteSQL.
--		The stored proc names are prefixed with udp_ to avoid 
--		conflicts with system stored procs.
-- Assumptions:	- This script assumes that the primary key is the first
--		column in the table and that if the primary key is
--		an integer then it is an IDENTITY (autonumber) field.
--		- This script is not suitable for the link tables
--		in the middle of a many to many relationship.
--		- After the script has run you will need to add
--		an ORDER BY clause into the '_lst' procedures
--		according to your needs / required sort order.
--		- Assumes you have set valid values for the 
--		config variables in the section immediately below
-- #########################################################

-- ##########################################################
/* SET CONFIG VARIABLES THAT ARE USED IN SCRIPT */
-- ##########################################################

-- Do we want to generate the SP definitions for every user defined
-- table in the database or just a single specified table?
-- Assign a blank string - '' for all tables or the table name for
-- a single table.
DECLARE @GenerateProcsFor varchar(100)
SET @GenerateProcsFor = 'PatientReleaseDates'
--SET @GenerateProcsFor = ''

-- which database do we want to create the procs for?
-- Change both the USE and SET lines below to set the datbase name
-- to the required database.
--USE [iThinkHealth]
DECLARE @DatabaseName varchar(100)
SET @DatabaseName = 'ithinkHealth'

-- do we want the script to print out the CREATE PROC statements
-- or do we want to execute them to actually create the procs?
-- Assign a value of either 'Print' or 'Execute'
DECLARE @PrintOrExecute varchar(10)
SET @PrintOrExecute = 'Print'

DECLARE @SchemeName varchar(15)
SET @SchemeName = 'apps.'

-- Is there a table name prefix i.e. 'tbl_' which we don't want
-- to include in our stored proc names?
DECLARE @TablePrefix varchar(10)
SET @TablePrefix = 'sp_'

-- For our '_lst' and '_sel' procedures do we want to 
-- do SELECT * or SELECT [ColumnName,]...
-- Assign a value of either 1 or 0
DECLARE @UseSelectWildCard bit
SET @UseSelectWildCard = 0

-- ##########################################################
/* END SETTING OF CONFIG VARIABLE 
-- do not edit below this line */
-- ##########################################################


-- DECLARE CURSOR containing all columns from user defined tables
-- in the database
DECLARE TableCol Cursor FOR 
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME, c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.Columns c INNER JOIN
	INFORMATION_SCHEMA.Tables t ON c.TABLE_NAME = t.TABLE_NAME
WHERE t.Table_Catalog = @DatabaseName
	AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION

-- Declare variables which will hold values from cursor rows
DECLARE @TableSchema varchar(100), @TableName varchar(100)
DECLARE @ColumnName varchar(100), @DataType varchar(30)
DECLARE @CharLength int

DECLARE @ColumnNameCleaned varchar(100)

-- Declare variables which will track what table we are
-- creating Stored Procs for
DECLARE @CurrentTable varchar(100)
DECLARE @FirstTable bit
DECLARE @FirstColumnName varchar(100)
DECLARE @FirstColumnDataType varchar(30)
DECLARE @ObjectName varchar(100) -- this is the tablename with the 
				-- specified tableprefix lopped off.
DECLARE @TablePrefixLength int

-- init vars
SET @CurrentTable = ''
SET @FirstTable = 1
SET @TablePrefixLength = Len(@TablePrefix)

-- Declare variables which will hold the queries we are building use unicode
-- data types so that can execute using sp_ExecuteSQL
DECLARE @LIST nvarchar(4000), @UPSERT VARCHAR(8000)
DECLARE @SELECT nvarchar(4000), @INSERT nvarchar(4000), @INSERTVALUES varchar(4000)
DECLARE @UPDATE nvarchar(4000), @DELETE nvarchar(4000)


-- open the cursor
OPEN TableCol

-- get the first row of cursor into variables
FETCH NEXT FROM TableCol INTO @TableSchema, @TableName, @ColumnName, @DataType, @CharLength

-- loop through the rows of the cursor
WHILE @@FETCH_STATUS = 0 BEGIN

	SET @ColumnNameCleaned = Replace(@ColumnName, ' ', '')

	-- is this a new table?
	IF @TableName <> @CurrentTable BEGIN
		
		-- if is the end of the last table
		IF @CurrentTable <> '' BEGIN
			IF @GenerateProcsFor = '' OR @GenerateProcsFor = @CurrentTable BEGIN

				-- first add any syntax to end the statement
				
				-- _lst
				SET @LIST = @List + Char(13) + 'FROM ' + @SchemeName + @CurrentTable + Char(13)
				--SET @LIST = @LIST + Char(13) + Char(13) + 'SET NOCOUNT OFF' + Char(13) + Char(13)
				SET @LIST = @LIST + Char(13)
				
				-- _sel
				SET @SELECT = @SELECT + Char(13) + 'FROM ' + @SchemeName + @CurrentTable + Char(13)
				SET @SELECT = @SELECT + 'WHERE [' + @FirstColumnName + '] = @' + Replace(@FirstColumnName, ' ', '') + Char(13)
				SET @SELECT = @SELECT + Char(13) + Char(13) + 'END ' + Char(13) + Char(13) --END GET WITH PARAMETER
				SET @SELECT = @SELECT + Char(13)
	
	
				-- UPDATE (remove trailing comma and append the WHERE clause)
				SET @UPDATE = SUBSTRING(@UPDATE, 0, LEN(@UPDATE)- 1) + Char(13) + Char(9) + 'WHERE [' + @FirstColumnName + '] = @' + Replace(@FirstColumnName, ' ', '') + Char(13)
				
				-- INSERT
				SET @INSERT = SUBSTRING(@INSERT, 0, LEN(@INSERT) - 1) + Char(13) + Char(9) + ')' + Char(13)
				SET @INSERTVALUES = SUBSTRING(@INSERTVALUES, 0, LEN(@INSERTVALUES) -1) + Char(13) + Char(9) + + Char(9) +')'
				SET @INSERT = @INSERT + @INSERTVALUES
				
				-- _ups
				SET @UPSERT = @UPSERT + Char(13) + 'AS' + Char(13)
				SET @UPSERT = @UPSERT + 'BEGIN' + Char(13) + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + '-- Last Changed: Date: ' + CONVERT(varchar(50), GETDATE(), 101) + ' -- By: <Name> - ' + Char(13) + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @SPName varchar(50)' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @OperationType char(6)' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'DECLARE  @Error int ' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'SET @SPName = OBJECT_NAME(@@PROCID)' + Char(13) 
				SET @UPSERT = @UPSERT + Char(9) + 'SET @OperationType = '''' ' + Char(13) + Char(13)

				IF @FirstColumnDataType IN ('int', 'bigint', 'smallint', 'tinyint', 'float', 'decimal')
				BEGIN
					SET @UPSERT = @UPSERT + Char(9) + 'IF @' + Replace(@FirstColumnName, ' ', '') + ' = 0 BEGIN' + Char(13)
				END ELSE BEGIN
					SET @UPSERT = @UPSERT + Char(9) + 'IF @' + Replace(@FirstColumnName, ' ', '') + ' = '''' BEGIN' + Char(13)	
				END
				SET @UPSERT = @UPSERT + Char(9) + Char(9) + 'SET @OperationType = ''Insert'' ' + Char(13) + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + ISNULL(@INSERT, '') + Char(13) + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + Char(9) + 'SET @' + Replace(@FirstColumnName, ' ', '') + ' = SCOPE_IDENTITY()' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'END' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'ELSE BEGIN' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + Char(9) + 'SET @OperationType = ''Update'' ' + Char(13) + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + ISNULL(@UPDATE, '') + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'END' + Char(13) + Char(13)
				
				SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @UserActivityLogID bigint' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @TableName varchar(30)' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @FirstKey varchar(50)' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @SecondKey varchar(50)' + Char(13) 
				SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @ChangeDesc varchar(255) -- Money 17, smallmoney 10, INT 11, SMALLINT 6, TINYINT 4, BIGINT 20, FLOAT<(53)> DATETIME 25: +1MAX ' + Char(13)+ Char(13)

				SET @UPSERT = @UPSERT + Char(9) + 'SET	@UserActivityLogID = 0' + Char(13) 
				SET @UPSERT = @UPSERT + Char(9) + 'SET	@TableName = ''' + @CurrentTable + '''' + Char(13) 
				SET @UPSERT = @UPSERT + Char(9) + 'SET @FirstKey = CAST(<@aVariable> AS varchar(50))' + Char(13) + Char(13)

				SET @UPSERT = @UPSERT + Char(9) + 'SELECT @ChangeDesc =''<A column> ID: ''+ Convert (varchar(50),@) ' + Char(13)+ Char(13)
				SET @UPSERT = @UPSERT + Char(9) + 'EXEC ' + @SchemeName + 'sp_RecordLog' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + '	@UserActivityLogID,' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + '	@UserID_FK,' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + '	@OperationType,' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + '	@TableName,' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + '	@FirstKey,' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + '	@SecondKey,' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + '	Null,' + Char(13)
				SET @UPSERT = @UPSERT + Char(9) + '	@ChangeDesc, NULL, @SPName' + Char(13) + Char(13)
				
				SET @UPSERT = @UPSERT + 'END' + Char(13) + Char(13) --END FOR UPDATE
				SET @UPSERT = @UPSERT + Char(13)
	
				-- _del
				-- delete proc completed already
	
				-- --------------------------------------------------
				-- now either print the SP definitions or 
				-- execute the statements to create the procs
				-- --------------------------------------------------
				IF @PrintOrExecute <> 'Execute' BEGIN
					PRINT @LIST
					PRINT @SELECT
					PRINT @UPSERT
					PRINT @DELETE
				END ELSE BEGIN
					EXEC sp_Executesql @LIST
					EXEC sp_Executesql @SELECT
					EXEC sp_Executesql @UPSERT
					EXEC sp_Executesql @DELETE
				END
			END -- end @GenerateProcsFor = '' OR @GenerateProcsFor = @CurrentTable
		END
		
		-- update the value held in @CurrentTable
		SET @CurrentTable = @TableName
		SET @FirstColumnName = @ColumnName
		SET @FirstColumnDataType = @DataType
		
		IF @TablePrefixLength > 0 BEGIN
			IF SUBSTRING(@CurrentTable, 1, @TablePrefixLength) = @TablePrefix BEGIN
				--PRINT Char(13) + 'DEBUG: OBJ NAME: ' + RIGHT(@CurrentTable, LEN(@CurrentTable) - @TablePrefixLength)
				SET @ObjectName = RIGHT(@CurrentTable, LEN(@CurrentTable) - @TablePrefixLength)
			END ELSE BEGIN
				SET @ObjectName = @CurrentTable
			END
		END ELSE BEGIN
			SET @ObjectName = @CurrentTable
		END
		
		IF @GenerateProcsFor = '' OR @GenerateProcsFor = @CurrentTable BEGIN
		
			-- ----------------------------------------------------
			-- now start building the procedures for the next table
			-- ----------------------------------------------------
			
			-- _lst
			SET @LIST = 'CREATE PROC ' + @SchemeName + '[' + @TablePrefix + 'Get' + @ObjectName + ']' + Char(13)
			SET @LIST = @LIST + 'AS' + Char(13)
			--SET @LIST = @LIST + 'BEGIN' + Char(13)
			IF @UseSelectWildcard = 1 BEGIN
				SET @LIST = @LIST + Char(13) + 'SELECT * '
			END 
			ELSE BEGIN
				SET @LIST = @LIST + Char(13) + 'SELECT [' + @ColumnName + ']'
			END
	
			-- _sel
			SET @SELECT = 'CREATE PROC ' + @SchemeName + '[' + @TablePrefix + 'Get' + @ObjectName + ']' + Char(13)
			SET @SELECT = @SELECT + Char(9) + '@' + @ColumnNameCleaned + ' ' + @DataType
			IF @DataType IN ('varchar', 'nvarchar', 'char', 'nchar') BEGIN
				SET @SELECT = @SELECT + '(' + CAST(@CharLength As varchar(10)) + ')'
			END
			SET @SELECT = @SELECT + Char(13) + 'AS' + Char(13)
			SET @SELECT = @SELECT + 'BEGIN' + Char(13)

			
			SET @SELECT = @SELECT + Char(13) + Char(9) + '-- Last Changed: Date: ' + CONVERT(varchar(50), GETDATE(), 101) + ' -- By: <Name> - '
			SET @SELECT = @SELECT + Char(13) + Char(9) + '-- Example Run: -- exec ' + @SchemeName + '[' + @TablePrefix + 'Get' + @ObjectName + ']' + ' <param> ' + Char(13)

			IF @UseSelectWildcard = 1 BEGIN
				SET @SELECT = @SELECT + Char(13) + Char(9) + 'SELECT * '
			END 
			ELSE BEGIN
				SET @SELECT = @SELECT + Char(13) + Char(9) + 'SELECT [' + @ColumnName + ']'
			END
	
			-- _ups
			SET @UPSERT = 'CREATE PROC ' + @SchemeName + '[' + @TablePrefix + 'Update' + @ObjectName + ']' + Char(13)
					SET @UPSERT = @UPSERT + Char(13) + Char(9) + 
					CASE WHEN @ColumnNameCleaned = 'EntryStamp' THEN '' ELSE  '@' + @ColumnNameCleaned + ' ' + @DataType END
			IF @DataType IN ('varchar', 'nvarchar', 'char', 'nchar') BEGIN
				SET @UPSERT = @UPSERT + '(' + CAST(@CharLength As Varchar(10)) + ')'
			END
	
			-- UPDATE
			SET @UPDATE = Char(9) + 'UPDATE ' + @SchemeName + @TableName + ' SET ' + Char(13)
			
			-- INSERT -- don't add first column to insert if it is an
			--	     integer (assume autonumber)
			SET @INSERT = Char(9) + 'INSERT INTO ' + @SchemeName + @TableName + ' (' + Char(13)
			SET @INSERTVALUES = Char(9) + Char(9) + 'VALUES (' + Char(13)
			
			IF @FirstColumnDataType NOT IN ('int', 'bigint', 'smallint', 'tinyint')
			BEGIN
				SET @INSERT = @INSERT + Char(9) + Char(9) + '[' + @ColumnName + '],' + Char(13)
				SET @INSERTVALUES = @INSERTVALUES + Char(9) + Char(9) + '@' + @ColumnNameCleaned + ',' + Char(13)
			END
	
			-- _del
			SET @DELETE = 'CREATE PROC ' + @SchemeName + '[' + @TablePrefix + 'Delete' + @ObjectName + ']' + Char(13)
			SET @DELETE = @DELETE + Char(9) + '@' + @ColumnNameCleaned + ' ' + @DataType
			IF @DataType IN ('varchar', 'nvarchar', 'char', 'nchar') BEGIN
				SET @DELETE = @DELETE + '(' + CAST(@CharLength As Varchar(10)) + ')'
			END
			SET @DELETE = @DELETE + Char(13) + 'AS' + Char(13)
			SET @DELETE = @DELETE + 'BEGIN' + Char(13) + Char(13)
			SET @DELETE = @DELETE + Char(9) + '-- Last Changed: Date: ' + CONVERT(varchar(50), GETDATE(), 101) + ' -- By: <Name> - *************if foreign key presnt here, make sure to take care the cascade delete in the other sp delete this key************' + Char(13) + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'DECLARE @SPName varchar(50)' + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'DECLARE @OperationType char(6)' + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'DECLARE  @Error int ' + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'SET	@OperationType = ''Delete''' + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'SET @SPName = OBJECT_NAME(@@PROCID)' + Char(13) + Char(13)

			SET @DELETE = @DELETE + Char(9) + 'DELETE FROM ' + @SchemeName + @TableName + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'WHERE [' + @ColumnName + '] = @' + @ColumnNameCleaned + Char(13) + Char(13)
			
			SET @DELETE = @DELETE + Char(9) + 'DECLARE @UserActivityLogID bigint' + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'DECLARE @TableName varchar(30)' + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'DECLARE @FirstKey varchar(50)' + Char(13) 
			SET @DELETE = @DELETE + Char(9) + 'DECLARE @SecondKey varchar(50)' + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'DECLARE @ChangeDesc varchar(255)' + Char(13)+ Char(13)

			SET @DELETE = @DELETE + Char(9) + 'SET	@UserActivityLogID = 0' + Char(13) 
			SET @DELETE = @DELETE + Char(9) + 'SET	@TableName = ''' + @CurrentTable + '''' + Char(13)
			SET @DELETE = @DELETE + Char(9) + 'SET @FirstKey = CAST(@ AS varchar(50))' + Char(13) + Char(13)

			SET @DELETE = @DELETE + Char(9) + 'SELECT @ChangeDesc =''<A column> ID: ''+ Convert (varchar(50),@) + ''  has been deleted!'' ' + Char(13)+ Char(13)

			SET @DELETE = @DELETE + Char(9) + 'EXEC ' + @SchemeName + 'sp_RecordLog' + Char(13)
			SET @DELETE = @DELETE + Char(9) + '	@UserActivityLogID,' + Char(13)
			SET @DELETE = @DELETE + Char(9) + '	@UserID_FK,' + Char(13)
			SET @DELETE = @DELETE + Char(9) + '	@OperationType,' + Char(13)
			SET @DELETE = @DELETE + Char(9) + '	@TableName,' + Char(13)
			SET @DELETE = @DELETE + Char(9) + '	@FirstKey,' + Char(13)
			SET @DELETE = @DELETE + Char(9) + '	@SecondKey,' + Char(13)
			SET @DELETE = @DELETE + Char(9) + '	Null,' + Char(13)
			SET @DELETE = @DELETE + Char(9) + '	@ChangeDesc, NULL, @SPName' + Char(13) + Char(13)
			SET @DELETE = @DELETE + Char(13) + Char(13) + Char(9) + 

					'--	 ' + Char(13) + Char(9) +					'SET @error = @@Error ' + Char(13) + Char(9) +  Char(13) + Char(9) +
					'If (@error <> 0)' + Char(13) +
					'BEGIN' + Char(13) + Char(9) + Char(9) +
					'	--Raise the error message to the calling object ' + Char(13) + Char(9) + Char(9) +
					'	RAISERROR (''Deleting from the <> table failed'', 16, 1 )' + Char(13) + Char(9) + Char(9) +
					'	RETURN -2 ' + Char(13) + Char(9) +
					'END' + Char(13) +  Char(13) 

			
			SET @DELETE = @DELETE + Char(13) + 'END ' + Char(13) --END FOR DELETE
			SET @DELETE = @DELETE + Char(13) 

		END	-- end @GenerateProcsFor = '' OR @GenerateProcsFor = @CurrentTable
	END
	ELSE BEGIN
		IF @GenerateProcsFor = '' OR @GenerateProcsFor = @CurrentTable BEGIN
		
			-- is the same table as the last row of the cursor
			-- just append the column
			
			-- _lst
			IF @UseSelectWildCard = 0 BEGIN
				SET @LIST = @LIST + ', ' + Char(13) + Char(9) + '[' + @ColumnName + ']'
			END
	
			-- _sel
			IF @UseSelectWildCard = 0 BEGIN
				SET @SELECT = @SELECT + ', ' + Char(13) + Char(9) + '[' + @ColumnName + ']'
			END
	
			-- _ups
			SET @UPSERT = @UPSERT + 
					   CASE WHEN @ColumnNameCleaned = 'EntryStamp' THEN '' 
					   ELSE ',' + Char(13) + Char(9) + '@' + @ColumnNameCleaned + ' ' + @DataType END

			IF @DataType IN ('varchar', 'nvarchar', 'char', 'nchar') BEGIN
				SET @UPSERT = @UPSERT + '(' + CAST(@CharLength As varchar(10)) + ')'
			END
	
			-- UPDATE
			SET @UPDATE = @UPDATE + Char(9) + Char(9) + 
			 CASE WHEN @ColumnName = 'EntryStamp' THEN  '[' + @ColumnName + '] = GETDATE() ,' + Char(13)
			 ELSE  '[' + @ColumnName + '] = @' + @ColumnNameCleaned + ',' + Char(13) END
	
			-- INSERT
			SET @INSERT = @INSERT + Char(9) + Char(9) + '[' + @ColumnName + '],' + Char(13)
			SET @INSERTVALUES = @INSERTVALUES + Char(9) + Char(9) + '@' + @ColumnNameCleaned + ',' + Char(13)
	
			-- _del
			-- delete proc completed already
		END -- end @GenerateProcsFor = '' OR @GenerateProcsFor = @CurrentTable'
	END

	-- fetch next row of cursor into variables
	FETCH NEXT FROM TableCol INTO @TableSchema, @TableName, @ColumnName, @DataType, @CharLength
END

-- ----------------
-- clean up cursor
-- ----------------
CLOSE TableCol
DEALLOCATE TableCol

-- ------------------------------------------------
-- repeat the block of code from within the cursor
-- So that the last table has its procs completed
-- and printed / executed
-- ------------------------------------------------
--SELECT @UPDATE

-- if is the end of the last table
IF @CurrentTable <> '' BEGIN
	IF @GenerateProcsFor = '' OR @GenerateProcsFor = @CurrentTable BEGIN

		-- first add any syntax to end the statement
		
		-- _lst
		SET @LIST = @List + Char(13) + 'FROM ' + @CurrentTable + Char(13)
		SET @LIST = @LIST + Char(13) + Char(13) + 'END' + Char(13)
		SET @LIST = @LIST + Char(13)
		
		-- _sel
		SET @SELECT = @SELECT + Char(13) + 'FROM ' + @CurrentTable + Char(13)
		SET @SELECT = @SELECT + 'WHERE [' + @FirstColumnName + '] = @' + Replace(@FirstColumnName, ' ', '') + Char(13)
		SET @SELECT = @SELECT + Char(13) + Char(13) + 'SET NOCOUNT OFF' + Char(13)
		SET @SELECT = @SELECT + Char(13)


		-- UPDATE (remove trailing comma and append the WHERE clause)
		SET @UPDATE = SUBSTRING(@UPDATE, 0, LEN(@UPDATE)- 1) + Char(13) + Char(9) + 'WHERE [' + @FirstColumnName + '] = @' + Replace(@FirstColumnName, ' ', '') + Char(13)
		
		-- INSERT
		SET @INSERT = SUBSTRING(@INSERT, 0, LEN(@INSERT) - 1) + Char(13) + Char(9) + ')' + Char(13)
		SET @INSERTVALUES = SUBSTRING(@INSERTVALUES, 0, LEN(@INSERTVALUES) -1) + Char(13) + Char(9) + ')'
		SET @INSERT = @INSERT + @INSERTVALUES
		
		-- _ups
		SET @UPSERT = @UPSERT + Char(13) + 'AS' + Char(13) + Char(13)
		SET @UPSERT = @UPSERT + 'BEGIN' + Char(13) + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + '-- Last Changed: Date: ' + CONVERT(varchar(50), GETDATE(), 101) + ' -- By: <Name> - ' + Char(13) + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @SPName varchar(50)' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @OperationType char(6)' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'set @SPName = OBJECT_NAME(@@PROCID)' + Char(13) + Char(13)
		
		IF @FirstColumnDataType IN ('int', 'bigint', 'smallint', 'tinyint', 'float', 'decimal')
		BEGIN
			SET @UPSERT = @UPSERT + Char(9) + 'IF @' + Replace(@FirstColumnName, ' ', '') + ' = 0 BEGIN' + Char(13)
		END ELSE BEGIN
			SET @UPSERT = @UPSERT + Char(9) + 'IF @' + Replace(@FirstColumnName, ' ', '') + ' = '''' BEGIN' + Char(13)	
		END
		SET @UPSERT = @UPSERT + Char(9) + Char(9) + ISNULL(@INSERT, '') + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + Char(9) + 'SET @' + Replace(@FirstColumnName, ' ', '') + ' = SCOPE_IDENTITY()' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'END' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'ELSE BEGIN' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + Char(9) + ISNULL(@UPDATE, '') + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'END' + Char(13) + Char(13)

		SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @UserActivityLogID bigint' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'SET	@UserActivityLogID = 0' + Char(13) + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @TableName varchar(30)' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'SET	@TableName = ''' + @CurrentTable + '''' + Char(13) + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @FirstKey varchar(50)' + Char(13) + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @SecondKey varchar(50)' + Char(13) + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'DECLARE @ChangeDesc varchar(255)' + Char(13)+ Char(13)
		SET @UPSERT = @UPSERT + Char(9) + 'EXEC ' + @SchemeName + 'sp_RecordLog' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + '	@UserActivityLogID,' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + '	@UserID_FK,' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + '	@OperationType,' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + '	@TableName,' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + '	@FirstKey,' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + '	@SecondKey,' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + '	Null,' + Char(13)
		SET @UPSERT = @UPSERT + Char(9) + '	@ChangeDesc, NULL, @SPName' + Char(13) + Char(13)

		SET @UPSERT = @UPSERT + 'SET NOCOUNT OFF' + Char(13)
		SET @UPSERT = @UPSERT + Char(13)

		-- _del
		-- delete proc completed already

		-- --------------------------------------------------
		-- now either print the SP definitions or 
		-- execute the statements to create the procs
		-- --------------------------------------------------
		IF @PrintOrExecute <> 'Execute' BEGIN
			PRINT @LIST
			PRINT @SELECT
			PRINT @UPSERT
			PRINT @DELETE
		END ELSE BEGIN
			EXEC sp_Executesql @LIST
			EXEC sp_Executesql @SELECT
			EXEC sp_Executesql @UPSERT
			EXEC sp_Executesql @DELETE
		END
	END -- end @GenerateProcsFor = '' OR @GenerateProcsFor = @CurrentTable
END
