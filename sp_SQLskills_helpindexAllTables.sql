SET NOCOUNT ON;  
  
DECLARE @table nvarchar(200);  

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
	)  
  
DECLARE vendor_cursor CURSOR FOR  
	SELECT  [name] FROM sys.tables
OPEN vendor_cursor  
  
FETCH NEXT FROM vendor_cursor INTO @table  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  

    INSERT INTO #ListIndexInfo
	EXEC sp_SQLskills_helpindex @table 

	-- who is using the index 
    FETCH NEXT FROM vendor_cursor INTO @table  
END   
CLOSE vendor_cursor;  
DEALLOCATE vendor_cursor;  

SELECT * FROM #ListIndexInfo

IF OBJECT_ID('TempDB..#ListIndexInfo') IS NOT NULL
	DROP TABLE #ListIndexInfo


