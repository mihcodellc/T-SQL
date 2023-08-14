USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_SQLskills_helpindex]    Script Date: 8/14/2023 2:06:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create or alter PROCEDURE [dbo].[sp_SQLskills_helpindex_short]
(
	@objname nvarchar(776)		-- the table to check for indexes
	, @IncludeListOrdered BIT = 0
)
AS
-- 2/17/2022: By Monktar Bello - added @@objname to the output table, Type
-- 11/19/2021: By Monktar Bello - added @create_date
--November 2021: Cleaned up and consolidated so only one helpindex for
--               usage AND for finddupes. Default is "unordered" which
--               means "as created." For dupes, we 'order' the INCLUDE
--               list so that we essentially normalize these lists.
--   March 2021: Ignore columnstore indexes, case-sensitive collation,
--               added semicolons, standardized formatting.
--               These mods are THANKS to Randolph West; they are so AWESOME!
--     June 2016: Support for clustered columnstore as well as removing
--                errors around other index types (hekaton, XML, spatial, etc.)
--September 2013: Correct the output for columnstore indexes.
-- November 2010: Added a column to show if an index is disabled.
--      May 2010: Added tree/leaf columns to the output - this requires the 
--                stored procedure: sp_SQLskills_ExposeColsInIndexLevels
--    March 2010: Added index_id to the output (ordered by index_id as well)
--   August 2008: Fixed a bug (missing begin/end block) AND I found
--                a few other issues that people hadn't noticed (yikes!)!
--    April 2008: Updated to add included columns to the output. 

-- See my blog for updates and/or additional information
-- http://www.SQLskills.com/blogs/Kimberly (Kimberly L. Tripp)

	set nocount on

	declare @objid int,				-- the object id of the table
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
			@dbname	sysname,
			@ignore_dup_key	bit,
			@is_unique bit,
			@is_hypothetical bit,
			@is_primary_key	bit,
			@is_unique_key bit,
			@is_disabled bit,
			@auto_created bit,
			@no_recompute bit,
			@filter_definition nvarchar(max),
			@ColsInTree nvarchar(2126),
			@ColsInLeaf nvarchar(max),
            @ExecStr nvarchar(max),
		  @create_date datetime

	-- Check to see that the object names are local to the current database.
	select @dbname = parsename(@objname,3)
	if @dbname is null
		select @dbname = db_name()
	else if @dbname <> db_name()
		begin
			raiserror(15250,-1,-1)
			return (1)
		end

	-- Check to see the the table exists and initialize @objid.
	select @objid = object_id(@objname)
	if @objid is NULL
	begin
		raiserror(15009,-1,-1,@objname,@dbname)
		return (1)
	end

	-- OPEN CURSOR OVER INDEXES (skip stats: bug shiloh_51196)
	declare ms_crs_ind cursor local static for
		select i.index_id, i.[type], i.data_space_id, QUOTENAME(i.name, N']') AS name,
			i.ignore_dup_key, i.is_unique, i.is_hypothetical, i.is_primary_key, i.is_unique_constraint,
			s.auto_created, s.no_recompute, i.filter_definition, i.is_disabled
		from sys.indexes as i 
			join sys.stats as s
				on i.object_id = s.object_id 
					and i.index_id = s.stats_id
		where i.object_id = @objid
	open ms_crs_ind
	fetch ms_crs_ind into @indid, @type, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
			@is_primary_key, @is_unique_key, @auto_created, @no_recompute, @filter_definition, @is_disabled

	-- IF NO INDEX, QUIT
	if @@fetch_status < 0
	begin
		deallocate ms_crs_ind
		raiserror(15472,-1,-1,@objname) -- Object does not have any indexes.
		return (0)
	end

	-- create temp tables
	CREATE TABLE #spindtab
	(
		index_name			sysname	collate database_default NOT NULL,
		index_id			int,
		[type]				tinyint,
		ignore_dup_key		bit,
		is_unique			bit,
		is_hypothetical		bit,
		is_primary_key		bit,
		is_unique_key		bit,
		is_disabled         bit,
		auto_created		bit,
		no_recompute		bit,
		groupname			sysname collate database_default NULL,
		index_keys			nvarchar(2126)	collate database_default NULL, -- see @keys above for length descr
		filter_definition	nvarchar(max),
		inc_Count			smallint,
		inc_columns			nvarchar(max),
		cols_in_tree		nvarchar(2126),
		cols_in_leaf		nvarchar(max),
		create_date		datetime, 
		objname nvarchar(776)
	)

	CREATE TABLE #IncludedColumns
	(	RowNumber	smallint,
		[Name]	nvarchar(128)
	)

	-- Now check out each index, figure out its type and keys and
	--	save the info in a temporary table that we'll print out at the end.
	while @@fetch_status >= 0
	begin
		-- First we'll figure out what the keys are.
		declare @i int, @thiskey nvarchar(131) -- 128+3

		select @keys = QUOTENAME(index_col(@objname, @indid, 1), N']'), @i = 2
		if (indexkey_property(@objid, @indid, 1, 'isdescending') = 1)
			select @keys = @keys  + '(-)'

		select @thiskey = QUOTENAME(index_col(@objname, @indid, @i), N']')
		if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))
			select @thiskey = @thiskey + '(-)'

		while (@thiskey is not null )
		begin
			select @keys = @keys + ', ' + @thiskey, @i = @i + 1
			select @thiskey = QUOTENAME(index_col(@objname, @indid, @i), N']')
			if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))
				select @thiskey = @thiskey + '(-)'
		end

		-- Second, we'll figure out what the included columns are.
		select @inc_columns = NULL
		
		SELECT @inc_Count = count(*)
		FROM sys.tables AS tbl
		INNER JOIN sys.indexes AS si 
			ON (si.index_id > 0 
				and si.is_hypothetical = 0) 
				AND (si.object_id=tbl.object_id)
		INNER JOIN sys.index_columns AS ic 
			ON (ic.column_id > 0 
				and (ic.key_ordinal > 0 or ic.partition_ordinal = 0 or ic.is_included_column != 0)) 
				AND (ic.index_id=CAST(si.index_id AS int) AND ic.object_id=si.object_id)
		INNER JOIN sys.columns AS clmns 
			ON clmns.object_id = ic.object_id 
			and clmns.column_id = ic.column_id
		WHERE ic.is_included_column = 1 and
			(si.index_id = @indid) and 
			(tbl.object_id= @objid)

		IF @inc_Count > 0
		BEGIN
			DELETE FROM #IncludedColumns
			INSERT #IncludedColumns
				SELECT ROW_NUMBER() OVER (ORDER BY clmns.column_id) 
				, clmns.name 
				FROM sys.tables AS tbl
				INNER JOIN sys.indexes AS si 
					ON (si.index_id > 0 
						AND si.is_hypothetical = 0) 
						AND (si.object_id=tbl.object_id)
				INNER JOIN sys.index_columns AS ic 
					ON (ic.column_id > 0 
						AND (ic.key_ordinal > 0 OR ic.partition_ordinal = 0 OR ic.is_included_column != 0)) 
						AND (ic.index_id=CAST(si.index_id AS int) AND ic.object_id=si.object_id)
				INNER JOIN sys.columns AS clmns 
					ON clmns.object_id = ic.object_id 
					AND clmns.column_id = ic.column_id
				WHERE ic.is_included_column = 1 AND
					(si.index_id = @indid) AND 
					(tbl.object_id= @objid)
			
			SELECT @inc_columns = QUOTENAME([Name], N']') 
            FROM #IncludedColumns 
            WHERE RowNumber = 1

			SET @loop_inc_Count = 1

			WHILE @loop_inc_Count < @inc_Count
			BEGIN
				SELECT @inc_columns = @inc_columns + ', ' + QUOTENAME([Name], N']') 
					FROM #IncludedColumns WHERE RowNumber = @loop_inc_Count + 1
				SET @loop_inc_Count = @loop_inc_Count + 1
			END
		END
	
		SELECT @groupname = null

		SELECT @groupname = name 
        FROM sys.data_spaces 
        WHERE data_space_id = @groupid

		-- Get the column list for the tree and leaf level, for all nonclustered indexes IF 
        -- the table has a clustered index

        -- Clustered index is non-unique
		IF @indid = 1 AND 
                (SELECT is_unique 
                    FROM sys.indexes 
                    WHERE index_id = 1 
                        AND object_id = @objid) = 0
			SELECT @ColsInTree = @keys + N', UNIQUIFIER', @ColsInLeaf = N'All columns "included" - the leaf level IS the data row, plus the UNIQUIFIER'
			
		-- Clustered index AND is unique
        IF @indid = 1 AND (SELECT is_unique FROM sys.indexes WHERE index_id = 1 AND object_id = @objid) = 1
			SELECT @ColsInTree = @keys, @ColsInLeaf = N'All columns "included" - the leaf level IS the data row.'
		
		-- Only run this for nonclustered indexes
        IF @indid > 1 
            EXEC [sp_SQLskills_ExposeColsInIndexLevels] @objid, @indid, @ColsInTree OUTPUT, @ColsInLeaf OUTPUT, @IncludeListOrdered
		
		-- Nonclustered, non-unique index with non-unique clustered ROWSTORE (type = 1) index
        IF @indid > 1 AND @is_unique = 0 
                AND (SELECT is_unique 
                    FROM sys.indexes 
                    WHERE index_id = 1 AND type = 1
                        AND object_id = @objid) = 0 
			SELECT @ColsInTree = @ColsInTree + N', UNIQUIFIER', @ColsInLeaf = @ColsInLeaf + N', UNIQUIFIER'
		
		-- Nonclustered, unique index with non-unique clustered ROWSTORE (type = 1) index
        IF @indid > 1 AND @is_unique = 1 
            AND (SELECT is_unique 
                    FROM sys.indexes 
                    WHERE index_id = 1 AND type = 1
                        AND object_id = @objid) = 0 
			SELECT @ColsInLeaf = @ColsInLeaf + N', UNIQUIFIER'
		
        -- Nonclustered rowstore on a heap
        IF (@indid > 1 AND @type = 2) 
                AND (SELECT COUNT(*) 
                     FROM sys.indexes 
                     WHERE index_id = 1 
                        AND object_id = @objid) = 0 -- table is a HEAP
		BEGIN
            IF (@is_unique_key = 0)
				SELECT @ColsInTree = @keys + N', RID'
					, @ColsInLeaf = @keys + N', RID' + CASE WHEN @inc_columns IS NOT NULL THEN N', ' + @inc_columns ELSE N'' END
		
			IF (@is_unique_key = 1)
				SELECT @ColsInTree = @keys
					, @ColsInLeaf = @keys + N', RID' + CASE WHEN @inc_columns IS NOT NULL THEN N', ' + @inc_columns ELSE N'' END
		END

		--creation date
		  SELECT @create_date = o.create_date
		  FROM     sys.indexes i
		  INNER JOIN  sys.objects o ON i.name = o.name
		  WHERE i.index_id = @indid

		-- INSERT ROW FOR INDEX
		
		insert into #spindtab values (@indname, @indid, @type, @ignore_dup_key, @is_unique, @is_hypothetical,
			@is_primary_key, @is_unique_key, @is_disabled, @auto_created, @no_recompute, @groupname, @keys, @filter_definition, @inc_Count, @inc_columns, @ColsInTree, @ColsInLeaf, @create_date, @objname)

		-- Next index
    	fetch ms_crs_ind into @indid, @type, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
			@is_primary_key, @is_unique_key, @auto_created, @no_recompute, @filter_definition, @is_disabled
	end
	deallocate ms_crs_ind

	-- DISPLAY THE RESULTS

-- Query by version
    IF CONVERT(smallint, SUBSTRING(CONVERT(varchar(50), SERVERPROPERTY('ProductVersion')), 1, 2)) < 16
    
        select @ExecStr = 
	
	        N'select objname, ' 
		        + N'''index_name'' = index_name,  is_primary_key,        '
		        + N'''index_keys'' = 
			          case when type IN (5, 6) then ''n/a, see columns_in_leaf for details''
			          else index_keys end,
		           ''included_columns'' = 
			          case when type IN (5, 6) then ''n/a, columnstore index''
                           when type = 7 then ''n/a, HASH''
			          else inc_columns end
	        from #spindtab
	        order by index_keys, included_columns, index_id '
            
    IF CONVERT(smallint, SUBSTRING(CONVERT(varchar(50), SERVERPROPERTY('ProductVersion')), 1, 2)) >= 16
        
        select @ExecStr = 
	
	        N'select objname, ' 
		        + N'''index_name'' = index_name,  is_primary_key,        '
		        + N'''index_keys'' = 
			          case when type IN (5, 6) then ''n/a, see columns_in_leaf for details''
			          else index_keys end,
		           ''included_columns'' = 
			          case when type IN (5, 6) then ''n/a, columnstore index''
                           when type = 7 then ''n/a, HASH''
			          else inc_columns end
	        from #spindtab
	        order by index_keys, included_columns, index_id '

    --SELECT (@ExecStr)
    EXEC (@ExecStr)

	return (0) -- sp_SQLskills_helpindex
go

EXEC sys.sp_MS_marksystemobject 'sp_SQLskills_helpindex_short';
GO
