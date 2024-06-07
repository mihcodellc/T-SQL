SELECT @@VERSION
-- study this to understand more: http://www.sql-server-performance.com/2009/identify-missing-indexes-using-sql-server-dmvs/

--BELLO
--just suggestions recommandations, the stats are based on the last time the server is restarted
--the select can return redundant create index. just be careful

--bello
--select * from sys.dm_db_missing_index_group_stats
--select * from sys.dm_db_missing_index_details
--select * from sys.dm_db_missing_index_groups
--select * from sys.databases order by database_id
--select DB_ID()
	
-- Monitor indexes size = their maintenance eat spaces make sure to get it back: log backup, skrink log file
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.index_id,
    (8.000/1024) * SUM(a.used_pages) AS IndexSizeMB
FROM 
    sys.indexes AS i
    JOIN sys.partitions AS p ON p.object_id = i.object_id AND p.index_id = i.index_id
    JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
GROUP BY 
    i.object_id, i.index_id, i.name
ORDER BY 
    IndexSizeMB DESC;

DBCC SQLPERF(LOGSPACE); -- Monitor transaction log size
	
--/****************************************************************************************************************************/
/**************************************** 1. Create Missing Index ***********************************************************/
/****************************************************************************************************************************/
--This routine will find missing indexes.
-- It has been written so that it will create the index statements for you.
-- The CreateIndexStatement column has what you want.
SELECT  
	[Impact] = (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans),  
	[Table] = [statement],
	[CreateIndexStatement] = ' idx_nc_' 
		+ REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,'')+ISNULL(mid.inequality_columns,''), '[', ''), ']',''), ', ','_')
		+ ' ON ' 
		+ [statement] 
		+ ' ( ' + IsNull(mid.equality_columns, '') 
		+ CASE WHEN mid.inequality_columns IS NULL THEN '' ELSE 
			CASE WHEN mid.equality_columns IS NULL THEN '' ELSE ',' END 
		+ mid.inequality_columns END + ' ) ' 
		+ CASE WHEN mid.included_columns IS NULL THEN '' ELSE 'INCLUDE (' + mid.included_columns + ')' END 
		+ ';', 
	mid.equality_columns,
	mid.inequality_columns,
	mid.included_columns
FROM sys.dm_db_missing_index_group_stats AS migs 
	INNER JOIN sys.dm_db_missing_index_groups AS mig ON migs.group_handle = mig.index_group_handle 
	INNER JOIN sys.dm_db_missing_index_details AS mid ON mig.index_handle = mid.index_handle 
	INNER JOIN sys.objects WITH (nolock) ON mid.OBJECT_ID = sys.objects.OBJECT_ID 
WHERE (migs.group_handle IN 
		(SELECT TOP (500) group_handle 
		FROM sys.dm_db_missing_index_group_stats WITH (nolock) 
		ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC))  
	AND OBJECTPROPERTY(sys.objects.OBJECT_ID, 'isusertable') = 1 
ORDER BY [Impact] DESC , [CreateIndexStatement] DESC



--https://www.sqlshack.com/collecting-aggregating-analyzing-missing-sql-server-index-stats/
SELECT
	databases.name AS [Database_Name],
	dm_db_missing_index_details.statement AS Table_Name,
	dm_db_missing_index_details.Equality_Columns,
	dm_db_missing_index_details.Inequality_Columns,
	dm_db_missing_index_details.Included_Columns AS Include_Columns,
	dm_db_missing_index_group_stats.Last_User_Seek,
	dm_db_missing_index_group_stats.Avg_Total_User_Cost,
	dm_db_missing_index_group_stats.Avg_User_Impact,
	dm_db_missing_index_group_stats.User_Seeks
FROM sys.dm_db_missing_index_groups
INNER JOIN sys.dm_db_missing_index_group_stats
ON dm_db_missing_index_group_stats.group_handle = dm_db_missing_index_groups.index_group_handle
INNER JOIN sys.dm_db_missing_index_details
ON dm_db_missing_index_groups.index_handle = dm_db_missing_index_details.index_handle
INNER JOIN sys.databases
ON databases.database_id = dm_db_missing_index_details.database_id
 --WHERE dm_db_missing_index_details.statement='apps.PatientCurrentEligibility'

/****************************************************************************************************************************/
/**************************************** 2. Get Active Lock and Duration ***************************************************/
/****************************************************************************************************************************/
--BELLO most important are user's object and the view dm_tran_locks  -- select * from sys.dm_tran_locks

--Query to return active locks and the duration of the locks being held
SELECT  Locks.request_session_id AS SessionID ,
        Obj.Name AS LockedObjectName ,
        DATEDIFF(second, ActTra.Transaction_begin_time, GETDATE()) AS Duration ,
        ActTra.Transaction_begin_time ,
        COUNT(*) AS Locks
FROM    sys.dm_tran_locks Locks
        JOIN sys.partitions Parti ON Parti.hobt_id = Locks.resource_associated_entity_id
        JOIN sys.objects Obj ON Obj.object_id = Parti.object_id
        JOIN sys.dm_exec_sessions ExeSess ON ExeSess.session_id = Locks.request_session_id
        JOIN sys.dm_tran_session_transactions TranSess ON ExeSess.session_id = TranSess.session_id
        JOIN sys.dm_tran_active_transactions ActTra ON TranSess.transaction_id = ActTra.transaction_id
WHERE   resource_database_id = DB_ID()
        AND Obj.Type = 'U'
GROUP BY ActTra.Transaction_begin_time ,
        Locks.request_session_id ,
        Obj.Name

/****************************************************************************************************************************/
/**************************************** 3. Find Table Scan ****************************************************************/
/****************************************************************************************************************************/
--BELLO : select distinct type, type_desc, index_id from sys.indexes
-- index_type: 0 for HEAP, 1 for CLUSTERED, 2 for NONCLUSTERED
-- https://blog.sqlauthority.com/2015/05/24/interview-question-of-the-week-021-difference-between-index-seek-and-index-scan-table-scan/

-- Find your worst scans
--
--An index scan may not be an issue so we’ll concentrate on table scans 
--A clustered index scan is a table scan so we’ll select on index id 0 and 1

select object_name(s.object_id) as TableName,isnull(i.name,'HEAP') as IndexName, 
case i.index_id
when 0 then 'HEAP'
when 1 then 'CLUS'
else 'NC'
end as IndexType,
user_seeks as Seeks, user_scans as Scans, user_lookups as Lookups
from sys.dm_db_index_usage_stats s join sys.indexes i on i.object_id = s.object_id
and i.index_id = s.index_id
where database_id = db_id() and objectproperty(s.object_id,'IsUserTable') = 1
and user_scans>0 and i.index_id<2
order by user_scans desc;  


/****************************************************************************************************************************/
/**************************************** 4. Find Table scan w/proportion ***************************************************/
/****************************************************************************************************************************/


--Add a calculation and sort by proportion of scans to seeks
-- run in database to be analysed

select object_name(s.object_id) as TableName,isnull(i.name,'HEAP') as IndexName, 
case i.index_id
when 0 then 'HEAP'
when 1 then 'CLUS'
else 'NC'
end as IndexType,
user_seeks as Seeks, user_scans as Scans, user_lookups as Lookups
,cast((user_scans*1.0/(user_seeks+user_scans))*100 as numeric(5,2)) as '%age'
from sys.dm_db_index_usage_stats s join sys.indexes i on i.object_id = s.object_id
and i.index_id = s.index_id
where database_id = db_id() and objectproperty(s.object_id,'IsUserTable') = 1
and user_scans>0 and i.index_id<2 
order by '%age' desc;
 
 
 
/****************************************************************************************************************************/
/**************************************** 5. Find missing Index *************************************************************/
/****************************************************************************************************************************/

SELECT	object_name(object_id), d.*, s.*
FROM	sys.dm_db_missing_index_details d 
INNER JOIN sys.dm_db_missing_index_groups g
	ON	d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats s
	ON	g.index_group_handle = s.group_handle
WHERE	database_id = db_id()
ORDER BY  object_id


/****************************************************************************************************************************/
/**************************************** 6. Full Index review doesn't return everything  ************************************************************/
/****************************************************************************************************************************/
--bello wide view on indexes: what is used, how often, overlap, heap or cluster, size in memory, is_primary, foreignKey

--Full Index review
DECLARE @ObjectName sysname 
SET @ObjectName = NULL

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

DECLARE @SQL nvarchar(max)
    ,@DB_ID int
    ,@ObjectID int
    ,@DatabaseName nvarchar(max)
    ,@DefaultFillFactor tinyint
    ,@DefaultFileGroup nvarchar(max)

BEGIN TRY
    SELECT @DB_ID = DB_ID()
        ,@ObjectID = OBJECT_ID(DB_NAME(DB_ID()) + '.' + @ObjectName)
        ,@DatabaseName = QUOTENAME(DB_NAME(DB_ID()))

    -- Obtain Default Fill Factor
    SET @SQL = 'SELECT @DefaultFillFactor = CAST(value AS tinyint) '
        + 'FROM '+@DatabaseName+'.sys.configurations WHERE configuration_id = 109'

    EXEC sp_ExecuteSQL @SQL, N'@DefaultFillFactor tinyint OUTPUT', @DefaultFillFactor = @DefaultFillFactor OUTPUT

    -- Obtain Default File Group
    SET @SQL = 'SELECT @DefaultFileGroup = name '
        + 'FROM '+@DatabaseName+'.sys.data_spaces WHERE is_default = 1'

    EXEC sp_ExecuteSQL @SQL, N'@DefaultFileGroup sysname OUTPUT', @DefaultFileGroup = @DefaultFileGroup OUTPUT

    -- Obtain memory buffer information on database objects
    IF OBJECT_ID('tempdb..#MemoryBuffer') IS NOT NULL
        DROP TABLE #MemoryBuffer

    CREATE TABLE #MemoryBuffer 
        (
        object_id int
        ,index_id int
        ,partition_number int
        ,buffered_page_count int
        ,buffer_mb decimal(12, 2)
        )

    SET @SQL = 'WITH AllocationUnits
    AS (
        SELECT p.object_id
            ,p.index_id
            ,p.partition_number 
            ,au.allocation_unit_id
        FROM '+@DatabaseName+'.sys.allocation_units AS au
            INNER JOIN '+@DatabaseName+'.sys.partitions AS p ON au.container_id = p.hobt_id AND (au.type = 1 OR au.type = 3)
        UNION ALL
        SELECT p.object_id
            ,p.index_id
            ,p.partition_number 
            ,au.allocation_unit_id
        FROM '+@DatabaseName+'.sys.allocation_units AS au
            INNER JOIN '+@DatabaseName+'.sys.partitions AS p ON au.container_id = p.partition_id AND au.type = 2
    )
    SELECT au.object_id
        ,au.index_id
        ,au.partition_number
        ,COUNT(*)AS buffered_page_count
        ,CONVERT(decimal(12,2), CAST(COUNT(*) as bigint)*CAST(8 as float)/1024) as buffer_mb
    FROM '+@DatabaseName+'.sys.dm_os_buffer_descriptors AS bd 
        INNER JOIN AllocationUnits au ON bd.allocation_unit_id = au.allocation_unit_id
    WHERE bd.database_id = db_id() and (au.object_id = @ObjectID or  @ObjectID is null)
    GROUP BY au.object_id, au.index_id, au.partition_number'


    INSERT INTO #MemoryBuffer
    EXEC sp_ExecuteSQL @SQL,N'@ObjectID int', @ObjectID = @ObjectID


    -- Create Main Temporary Tables
    IF OBJECT_ID('tempdb..#IndexBaseLine') IS NOT NULL
        DROP TABLE #IndexBaseLine

    CREATE TABLE #IndexBaseLine
        (
        row_id int IDENTITY(1,1)
        ,index_action varchar(10)
        ,pros varchar(25)
        ,cons varchar(25)
        ,filegroup nvarchar(128)
        ,schema_id int
        ,schema_name sysname
        ,object_id int
        ,table_name sysname
        ,index_id int
        ,index_name nvarchar(128)
        ,is_primary_key bit DEFAULT(0)
        ,is_unique bit DEFAULT(0)
        ,has_unique bit DEFAULT(0)
        ,type_desc nvarchar(67)
        ,partition_number int
        ,fill_factor tinyint
       ,is_padded bit
        ,reserved_page_count bigint
        ,size_in_mb decimal(12, 2)
        ,buffered_page_count int
        ,buffer_mb decimal(12, 2)
        ,pct_in_buffer decimal(12, 2)
        ,table_buffer_mb decimal(12, 2)
        ,row_count bigint
        ,impact int
        ,existing_ranking bigint
        ,user_total bigint
        ,user_total_pct decimal(6, 2)
        ,estimated_user_total_pct decimal(6, 2)
        ,user_seeks bigint
        ,user_scans bigint
        ,user_lookups bigint
        ,user_updates bigint
        ,read_to_update_ratio nvarchar(30)
        ,read_to_update numeric
        ,update_to_read numeric
        ,row_lock_count bigint
        ,row_lock_wait_count bigint
        ,row_lock_wait_in_ms bigint
        ,row_block_pct decimal(6, 2)
        ,avg_row_lock_waits_ms bigint
        ,page_latch_wait_count bigint
        ,avg_page_latch_wait_ms bigint
        ,page_io_latch_wait_count bigint
        ,avg_page_io_latch_wait_ms bigint
        ,tree_page_latch_wait_count bigint
        ,avg_tree_page_latch_wait_ms bigint
        ,tree_page_io_latch_wait_count bigint
        ,avg_tree_page_io_latch_wait_ms bigint    
        ,read_operations bigint
        ,leaf_writes bigint
        ,leaf_page_allocations bigint    
        ,leaf_page_merges bigint    
        ,nonleaf_writes bigint
        ,nonleaf_page_allocations bigint
        ,nonleaf_page_merges bigint    
        ,indexed_columns nvarchar(max)
        ,included_columns nvarchar(max)
        ,indexed_columns_compare nvarchar(max)
        ,included_columns_compare nvarchar(max)
        ,duplicate_indexes nvarchar(max)
        ,overlapping_indexes nvarchar(max)
        ,related_foreign_keys nvarchar(max)
        ,related_foreign_keys_xml xml
        )
     
     -- Populate stats on existing indexes.
     SET @SQL = N'SELECT 
        filegroup = ds.name
        , schema_id =  s.schema_id
        , schema_name = s.name
        , object_id = t.object_id
        , table_name = t.name
        , index_id = i.index_id
        , index_name = COALESCE(i.name, ''N/A'')
        , is_primary_key = i.is_primary_key
       , is_unique = i.is_unique
        , type_desc = CASE WHEN i.is_unique = 1 THEN ''UNIQUE '' ELSE '''' END + i.type_desc
        , partition_number = ps.partition_number
        , fill_factor = i.fill_factor
        , is_padded = i.is_padded
        , reserved_page_count = ps.reserved_page_count
        , size_in_mb = CAST(reserved_page_count * CAST(8 as float) / 1024 as decimal(12,2)) 
        , buffered_page_count = mb.buffered_page_count
        , buffer_mb = mb.buffer_mb
        , pct_in_buffer = CAST(100*buffer_mb/NULLIF(CAST(reserved_page_count * CAST(8 as float) / 1024 as decimal(12,2)),0) AS decimal(12,2)) 
        , row_count = row_count
        , existing_ranking = ROW_NUMBER() 
            OVER (PARTITION BY i.object_id ORDER BY i.is_primary_key desc, ius.user_seeks + ius.user_scans + ius.user_lookups desc) 
        , user_total = ius.user_seeks + ius.user_scans + ius.user_lookups
       , user_total_pct = COALESCE(CAST(100 * (ius.user_seeks + ius.user_scans + ius.user_lookups)
            /(NULLIF(SUM(ius.user_seeks + ius.user_scans + ius.user_lookups) 
            OVER(PARTITION BY i.object_id), 0) * 1.) as decimal(6,2)),0)
        , user_seeks = ius.user_seeks
        , user_scans = ius.user_scans
        , user_lookups = ius.user_lookups
        , user_updates = ius.user_updates
        , read_to_update_ratio = (1.*(ius.user_seeks + ius.user_scans + ius.user_lookups))/NULLIF(ius.user_updates,0)
        , read_to_update = CASE WHEN ius.user_seeks + ius.user_scans + ius.user_lookups >= ius.user_updates
            THEN CEILING(1.*(ius.user_seeks + ius.user_scans + ius.user_lookups)/COALESCE(NULLIF(ius.user_seeks,0),1)) 
            ELSE 0 END 
        , update_to_read = CASE WHEN ius.user_seeks + ius.user_scans + ius.user_lookups <= ius.user_updates
            THEN CEILING(1.*(ius.user_updates)/COALESCE(NULLIF(ius.user_seeks + ius.user_scans + ius.user_lookups,0),1)) 
            ELSE 0 END
        , row_lock_count = ios.row_lock_count
        , row_lock_wait_count = ios.row_lock_wait_count
        , row_lock_wait_in_ms = ios.row_lock_wait_in_ms
        , row_block_pct = CAST(100.0 * ios.row_lock_wait_count/NULLIF(ios.row_lock_count, 0) AS decimal(12,2)) 
        , avg_row_lock_waits_ms = CAST(1. * ios.row_lock_wait_in_ms /NULLIF(ios.row_lock_wait_count, 0) AS decimal(12,2))
        , page_latch_wait_count = ios.page_latch_wait_count
        , avg_page_latch_wait_ms = CAST(1. * page_latch_wait_in_ms / NULLIF(ios.page_io_latch_wait_count,0) AS decimal(12,2)) 
        , page_io_latch_wait_count = ios.page_io_latch_wait_count
        , avg_page_io_latch_wait_ms = CAST(1. * ios.page_io_latch_wait_in_ms / NULLIF(ios.page_io_latch_wait_count,0) AS decimal(12,2))
        , tree_page_latch_wait_count = NULL --ios.tree_page_latch_wait_count
        , avg_tree_page_latch_wait_ms = NULL --CAST(1. * tree_page_latch_wait_in_ms / NULLIF(ios.tree_page_io_latch_wait_count,0) AS decimal(12,2)) 
        , tree_page_io_latch_wait_count = NULL --ios.tree_page_io_latch_wait_count
        , avg_tree_page_io_latch_wait_ms = NULL --CAST(1. * ios.tree_page_io_latch_wait_in_ms / NULLIF(ios.tree_page_io_latch_wait_count,0) AS decimal(12,2)) 
        , read_operations = range_scan_count + singleton_lookup_count
        , leaf_writes = ios.leaf_insert_count + ios.leaf_update_count + ios.leaf_delete_count + ios.leaf_ghost_count
        , leaf_page_allocations = leaf_allocation_count
        , leaf_page_merges = ios.leaf_page_merge_count
        , nonleaf_writes = ios.nonleaf_insert_count + ios.nonleaf_update_count + ios.nonleaf_delete_count
        , nonleaf_page_allocations = ios.nonleaf_allocation_count
        , nonleaf_page_merges = ios.nonleaf_page_merge_count' +
    '    , indexed_columns = STUFF((
                SELECT '', '' + QUOTENAME(c.name)
                FROM '+@DatabaseName+'.sys.index_columns ic
                    INNER JOIN '+@DatabaseName+'.sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE i.object_id = ic.object_id
                AND i.index_id = ic.index_id
                AND is_included_column = 0
                ORDER BY key_ordinal ASC
                FOR XML PATH('''')), 1, 2, '''')
        , included_columns = STUFF((
                SELECT '', '' + QUOTENAME(c.name)
                FROM '+@DatabaseName+'.sys.index_columns ic
                    INNER JOIN '+@DatabaseName+'.sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE i.object_id = ic.object_id
                AND i.index_id = ic.index_id
                AND is_included_column = 1
                ORDER BY key_ordinal ASC
               FOR XML PATH('''')), 1, 2, '''') 
        , indexed_columns_compare = (SELECT QUOTENAME(ic.column_id,''('')
                FROM '+@DatabaseName+'.sys.index_columns ic
                WHERE i.object_id = ic.object_id
                AND i.index_id = ic.index_id
                AND is_included_column = 0
                ORDER BY key_ordinal ASC
                FOR XML PATH(''''))
        , included_columns_compare = COALESCE((
                SELECT QUOTENAME(ic.column_id, ''('')
                FROM '+@DatabaseName+'.sys.index_columns ic
                WHERE i.object_id = ic.object_id
                AND i.index_id = ic.index_id
                AND is_included_column = 1
               ORDER BY key_ordinal ASC
                FOR XML PATH('''')), SPACE(0)) 
    FROM '+@DatabaseName+'.sys.tables t
        INNER JOIN '+@DatabaseName+'.sys.schemas s ON t.schema_id = s.schema_id
        INNER JOIN '+@DatabaseName+'.sys.indexes i ON t.object_id = i.object_id
        INNER JOIN '+@DatabaseName+'.sys.data_spaces ds ON i.data_space_id = ds.data_space_id
        INNER JOIN '+@DatabaseName+'.sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
        LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = db_id()
        LEFT OUTER JOIN sys.dm_db_index_operational_stats(@DB_ID, NULL, NULL, NULL) ios ON ps.object_id = ios.object_id AND ps.index_id = ios.index_id AND ps.partition_number = ios.partition_number
        LEFT OUTER JOIN #MemoryBuffer mb ON ps.object_id = mb.object_id AND ps.index_id = mb.index_id AND ps.partition_number = mb.partition_number'

    IF @ObjectID IS NOT NULL
        SET @SQL = @SQL + CHAR(13) + 'WHERE t.object_id = @ObjectID '

    INSERT INTO #IndexBaseLine
        (
        filegroup, schema_id, schema_name, object_id, table_name, index_id, index_name, is_primary_key, is_unique, type_desc, partition_number, fill_factor
        , is_padded, reserved_page_count, size_in_mb, buffered_page_count, buffer_mb, pct_in_buffer, row_count, existing_ranking, user_total
        , user_total_pct, user_seeks, user_scans, user_lookups, user_updates, read_to_update_ratio, read_to_update, update_to_read, row_lock_count
        , row_lock_wait_count, row_lock_wait_in_ms, row_block_pct, avg_row_lock_waits_ms, page_latch_wait_count, avg_page_latch_wait_ms
        , page_io_latch_wait_count, avg_page_io_latch_wait_ms, tree_page_latch_wait_count, avg_tree_page_latch_wait_ms, tree_page_io_latch_wait_count
        , avg_tree_page_io_latch_wait_ms, read_operations, leaf_writes, leaf_page_allocations, leaf_page_merges, nonleaf_writes
        , nonleaf_page_allocations, nonleaf_page_merges, indexed_columns, included_columns, indexed_columns_compare, included_columns_compare
        )   
    EXEC sp_ExecuteSQL @SQL, N'@DB_ID int, @ObjectID int', @DB_ID = @DB_ID, @ObjectID = @ObjectID

    -- Populate stats on missing indexes.
     SET @SQL = N'SELECT s.schema_id
        ,s.name AS schema_name
        ,t.object_id
        ,t.name AS table_name
        ,''--MISSING--'' AS index_name
        ,''--NONCLUSTERED--'' AS type_desc
        ,(migs.user_seeks + migs.user_scans) * migs.avg_user_impact as impact
        ,0 AS existing_ranking
        ,migs.user_seeks + migs.user_scans as user_total
        ,migs.user_seeks 
        ,migs.user_scans
        ,0 as user_lookups
        ,COALESCE(equality_columns + CASE WHEN inequality_columns IS NOT NULL THEN '', '' ELSE SPACE(0) END, SPACE(0)) + COALESCE(inequality_columns, SPACE(0)) as indexed_columns
        ,included_columns
    FROM '+@DatabaseName+'.sys.tables t
        INNER JOIN '+@DatabaseName+'.sys.schemas s ON t.schema_id = s.schema_id
        INNER JOIN sys.dm_db_missing_index_details mid ON t.object_id = mid.object_id
        INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
        INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
    WHERE mid.database_id = @DB_ID'

    IF @ObjectID IS NOT NULL
        SET @SQL = @SQL + CHAR(13) + 'AND t.object_id = @ObjectID '

    INSERT INTO #IndexBaseLine
        (schema_id, schema_name, object_id, table_name, index_name, type_desc, impact, existing_ranking, user_total, user_seeks, user_scans, user_lookups, indexed_columns, included_columns)
    EXEC sp_ExecuteSQL @SQL, N'@DB_ID int, @ObjectID int', @DB_ID = @DB_ID, @ObjectID = @ObjectID

    -- Collect foreign key information.
    IF OBJECT_ID('tempdb..#ForeignKeys') IS NOT NULL
        DROP TABLE #ForeignKeys

    CREATE TABLE #ForeignKeys
        (
        foreign_key_name sysname
        ,object_id int
        ,fk_columns nvarchar(max)
        ,fk_columns_compare nvarchar(max)
        )
            
     SET @SQL = N'SELECT fk.name + ''|PARENT'' AS foreign_key_name
        ,fkc.parent_object_id AS object_id
        ,STUFF((SELECT '', '' + QUOTENAME(c.name)
            FROM '+@DatabaseName+'.sys.foreign_key_columns ifkc
                INNER JOIN '+@DatabaseName+'.sys.columns c ON ifkc.parent_object_id = c.object_id AND ifkc.parent_column_id = c.column_id
            WHERE fk.object_id = ifkc.constraint_object_id
            ORDER BY ifkc.constraint_column_id
            FOR XML PATH('''')), 1, 2, '''') AS fk_columns
        ,(SELECT QUOTENAME(ifkc.parent_column_id,''('')
            FROM '+@DatabaseName+'.sys.foreign_key_columns ifkc
            WHERE fk.object_id = ifkc.constraint_object_id
            ORDER BY ifkc.constraint_column_id
            FOR XML PATH('''')) AS fk_columns_compare
    FROM '+@DatabaseName+'.sys.foreign_keys fk
        INNER JOIN '+@DatabaseName+'.sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    WHERE fkc.constraint_column_id = 1
    AND (fkc.parent_object_id = @ObjectID OR @ObjectID IS NULL)
    UNION ALL
    SELECT fk.name + ''|REFERENCED'' as foreign_key_name
        ,fkc.referenced_object_id AS object_id
       ,STUFF((SELECT '', '' + QUOTENAME(c.name)
            FROM '+@DatabaseName+'.sys.foreign_key_columns ifkc
                INNER JOIN '+@DatabaseName+'.sys.columns c ON ifkc.referenced_object_id = c.object_id AND ifkc.referenced_column_id = c.column_id
            WHERE fk.object_id = ifkc.constraint_object_id
            ORDER BY ifkc.constraint_column_id
            FOR XML PATH('''')), 1, 2, '''') AS fk_columns
        ,(SELECT QUOTENAME(ifkc.referenced_column_id,''('')
            FROM '+@DatabaseName+'.sys.foreign_key_columns ifkc
            WHERE fk.object_id = ifkc.constraint_object_id
            ORDER BY ifkc.constraint_column_id
            FOR XML PATH('''')) AS fk_columns_compare
    FROM '+@DatabaseName+'.sys.foreign_keys fk
        INNER JOIN '+@DatabaseName+'.sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    WHERE fkc.constraint_column_id = 1
    AND (fkc.referenced_object_id = @ObjectID OR @ObjectID IS NULL)'

    INSERT INTO #ForeignKeys
        (foreign_key_name, object_id, fk_columns, fk_columns_compare)
    EXEC sp_ExecuteSQL @SQL, N'@DB_ID int, @ObjectID int', @DB_ID = @DB_ID, @ObjectID = @ObjectID

    -- Determine duplicate, overlapping, and foreign key index information
    UPDATE ibl
    SET duplicate_indexes = STUFF((SELECT ', ' + index_name AS [data()]
            FROM #IndexBaseLine iibl
            WHERE ibl.object_id = iibl.object_id
            AND ibl.index_id > iibl.index_id
            AND ibl.indexed_columns_compare = iibl.indexed_columns_compare
            AND ibl.included_columns_compare = iibl.included_columns_compare
            FOR XML PATH('')), 1, 2, '')
        ,overlapping_indexes = STUFF((SELECT ', ' + index_name AS [data()]
            FROM #IndexBaseLine iibl
            WHERE ibl.object_id = iibl.object_id
            AND ibl.index_id <> iibl.index_id
            AND (ibl.indexed_columns_compare LIKE iibl.indexed_columns_compare + '%' 
                OR iibl.indexed_columns_compare LIKE ibl.indexed_columns_compare + '%')
            AND ibl.indexed_columns_compare <> iibl.indexed_columns_compare 
            FOR XML PATH('')), 1, 2, '')
        ,related_foreign_keys = STUFF((SELECT ', ' + foreign_key_name AS [data()]
            FROM #ForeignKeys ifk
            WHERE ifk.object_id = ibl.object_id
            AND ibl.indexed_columns_compare LIKE ifk.fk_columns_compare + '%'
            FOR XML PATH('')), 1, 2, '')
        ,related_foreign_keys_xml = CAST((SELECT foreign_key_name
            FROM #ForeignKeys ForeignKeys
            WHERE ForeignKeys.object_id = ibl.object_id
            AND ibl.indexed_columns_compare LIKE ForeignKeys.fk_columns_compare + '%'
            FOR XML AUTO) as xml)  
    FROM #IndexBaseLine ibl


     -- Populate stats on missing foreign key indexes
    SET @SQL = N'SELECT s.schema_id
        ,s.name AS schema_name
        ,t.object_id
        ,t.name AS table_name
        ,fk.foreign_key_name AS index_name
        ,''--MISSING FOREIGN KEY--'' as type_desc
        ,9999
        ,fk.fk_columns
        ,t.name AS related_foreign_keys
    FROM '+@DatabaseName+'.sys.tables t
        INNER JOIN '+@DatabaseName+'.sys.schemas s ON t.schema_id = s.schema_id
        INNER JOIN #ForeignKeys fk ON t.object_id = fk.object_id
        LEFT OUTER JOIN #IndexBaseLine ia ON fk.object_id = ia.object_id AND ia.indexed_columns_compare LIKE fk.fk_columns_compare + ''%''
    WHERE ia.index_name IS NULL'

    INSERT INTO #IndexBaseLine
        (schema_id, schema_name, object_id, table_name, index_name, type_desc, existing_ranking, indexed_columns, related_foreign_keys)
    EXEC sp_ExecuteSQL @SQL, N'@DB_ID int, @ObjectID int', @DB_ID = @DB_ID, @ObjectID = @ObjectID

    -- Determine whether tables have unique indexes
    SET @SQL = N'UPDATE ibl
    SET has_unique = 1
    FROM #IndexBaseLine ibl
        INNER JOIN (SELECT DISTINCT object_id FROM '+@DatabaseName+'.sys.indexes i WHERE i.is_unique = 1) x ON ibl.object_id = x.object_id'
        
    EXEC sp_ExecuteSQL @SQL

    -- Calculate estimated user total for each index.
    ;WITH Aggregation
    AS (
        SELECT row_id
            ,CAST(100. * (user_seeks + user_scans + user_lookups)
                /(NULLIF(SUM(user_seeks + user_scans + user_lookups) 
                OVER(PARTITION BY schema_name, table_name), 0) * 1.) as decimal(12,2)) AS estimated_user_total_pct
            ,SUM(buffer_mb) OVER(PARTITION BY schema_name, table_name) as table_buffer_mb
        FROM #IndexBaseLine 
    )
    UPDATE ibl
    SET estimated_user_total_pct = COALESCE(a.estimated_user_total_pct, 0)
        ,table_buffer_mb = a.table_buffer_mb
    FROM #IndexBaseLine ibl
        INNER JOIN Aggregation a ON ibl.row_id = a.row_id

    -- Update Index Action information
    ;WITH IndexAction
    AS (
        SELECT row_id
            ,CASE WHEN user_lookups > user_seeks AND type_desc IN ('CLUSTERED', 'HEAP', 'UNIQUE CLUSTERED') THEN 'REALIGN'
                WHEN duplicate_indexes IS NOT NULL THEN 'DROP' 
                WHEN type_desc = '--MISSING FOREIGN KEY--' THEN 'CREATE'
                WHEN type_desc = 'XML' THEN '---'
                WHEN is_unique = 1 THEN '---'
                WHEN related_foreign_keys IS NOT NULL THEN '---'
                WHEN type_desc = '--NONCLUSTERED--' AND ROW_NUMBER() OVER (PARTITION BY table_name ORDER BY user_total desc) <= 10 AND estimated_user_total_pct > 1 THEN 'CREATE'
                WHEN type_desc = '--NONCLUSTERED--' THEN 'BLEND'
                WHEN ROW_NUMBER() OVER (PARTITION BY table_name ORDER BY user_total desc, existing_ranking) > 10 THEN 'DROP' 
                WHEN user_total = 0 THEN 'DROP' 
                ELSE '---' END AS index_action
        FROM #IndexBaseLine
    )
    UPDATE ibl
    SET index_action = ia.index_action
    FROM #IndexBaseLine ibl INNER JOIN IndexAction ia
    ON ibl.row_id = ia.row_id

    -- Update Pro/Con statuses
    UPDATE #IndexBaseLine
    SET Pros = COALESCE(STUFF(CASE WHEN related_foreign_keys IS NOT NULL THEN ', FK' ELSE '' END
            + CASE WHEN is_unique = 1 THEN ', UQ' ELSE '' END
            + COALESCE(', ' + CASE WHEN read_to_update BETWEEN 1 AND 9 THEN '$'
                WHEN read_to_update BETWEEN 10 AND 99 THEN '$$'
                WHEN read_to_update BETWEEN 100 AND 999 THEN '$$$'
                WHEN read_to_update > 999 THEN '$$$+' END, '')
            ,1,2,''),'')
        ,Cons = COALESCE(STUFF(CASE WHEN user_seeks / NULLIF(user_scans,0) < 1000 THEN ', SCN' ELSE '' END
            + CASE WHEN duplicate_indexes IS NOT NULL THEN ', DP' ELSE '' END
            + CASE WHEN overlapping_indexes IS NOT NULL THEN ', OV' ELSE '' END
            + COALESCE(', ' + CASE WHEN update_to_read BETWEEN 1 AND 9 THEN '$'
                WHEN update_to_read BETWEEN 10 AND 99 THEN '$$'
                WHEN update_to_read BETWEEN 100 AND 999 THEN '$$$'
                WHEN update_to_read > 999 THEN '$$$+' END, '')
            ,1,2,''),'')

    --Final Output
    SELECT
        index_action
        , pros
        , cons
        , QUOTENAME(schema_name) + '.' + QUOTENAME(table_name) as object_name
        , index_name
        , type_desc
        , indexed_columns
        , included_columns
        , is_primary_key
        , is_unique
        , has_unique
        , partition_number
        , fill_factor
        , is_padded
        , size_in_mb
        , buffer_mb
        , table_buffer_mb
        , pct_in_buffer
        , row_count
        , user_total_pct
        , estimated_user_total_pct
        , impact
        , user_total
        , user_seeks
        , user_scans
        , user_lookups
        , user_updates
        , read_to_update_ratio
        , read_to_update
        , update_to_read
        , row_lock_count
        , row_lock_wait_count
        , row_lock_wait_in_ms
        , row_block_pct
        , avg_row_lock_waits_ms
        , page_latch_wait_count
        , avg_page_latch_wait_ms
        , page_io_latch_wait_count
        , avg_page_io_latch_wait_ms
        , tree_page_latch_wait_count
        , avg_tree_page_latch_wait_ms
        , tree_page_io_latch_wait_count
        , avg_tree_page_io_latch_wait_ms
        , read_operations
        , leaf_writes
        , leaf_page_allocations
        , leaf_page_merges
        , nonleaf_writes
        , nonleaf_page_allocations
        , nonleaf_page_merges
        , duplicate_indexes
        , overlapping_indexes
        , related_foreign_keys
        , related_foreign_keys_xml
        ,CAST('<?query --' + CHAR(13)
            + CASE WHEN is_primary_key = 1 OR is_unique = 1 THEN  '-- !! WARNING !! Drop statement will fail if there are dependent objects.' + CHAR(13) + CHAR(13) ELSE SPACE(0) END
            + CASE WHEN index_id = 0 THEN NULL
                WHEN is_primary_key = 1 THEN
                    'IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + QUOTENAME(schema_name) + '.' + QUOTENAME(table_name) + ''') AND name = N''' + index_name + ''')' + CHAR(13)
                    + '    ALTER TABLE '+QUOTENAME(schema_name) + '.' + QUOTENAME(table_name)+' DROP CONSTRAINT ' + QUOTENAME(index_name) + CHAR(13)
                ELSE 
                    'IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + QUOTENAME(schema_name) + '.' + QUOTENAME(table_name) + ''') AND name = N''' 
                    + CASE WHEN index_id IS NULL THEN '<index_name, sysname, ind_test>' ELSE index_name END + ''')' + CHAR(13)
                    + '    DROP INDEX ' + CASE WHEN index_id IS NULL THEN '<index_name, sysname, ind_test>' ELSE index_name END 
                    + ' ON ' + QUOTENAME(schema_name) + '.' + QUOTENAME(table_name) + CHAR(13)
                END
            + CHAR(13) + '--?>' AS xml) as ddl_drop
       ,CAST('<?query --' + CHAR(13)
            + CASE WHEN index_id = 0 THEN NULL
                WHEN is_primary_key = 1 THEN
                    'ALTER TABLE '+QUOTENAME(schema_name) + '.' + QUOTENAME(table_name)+' ADD  CONSTRAINT ' + QUOTENAME(index_name) + ' PRIMARY KEY ' 
                    + CASE WHEN index_id = 1 THEN 'CLUSTERED ' ELSE 'NONCLUSTERED ' END + CHAR(13)
                    + '     ('+indexed_columns+')' + CHAR(13)
                    + CASE WHEN included_columns IS NOT NULL THEN ' INCLUDE ('+included_columns+')' ELSE '' END
                ELSE 'CREATE ' 
                    + CASE WHEN is_unique = 1 THEN 'UNIQUE ' ELSE '' END
                    + CASE WHEN index_id = 1 THEN 'CLUSTERED ' ELSE 'NONCLUSTERED ' END 
                    + 'INDEX ' + CASE WHEN index_id IS NULL THEN '<index_name, sysname, ind_test>' ELSE index_name END
                    + ' ON ' + QUOTENAME(schema_name) + '.' + QUOTENAME(table_name) + CHAR(13)
                    + '     ('+indexed_columns+')' + CHAR(13)
                    + CASE WHEN included_columns IS NOT NULL THEN ' INCLUDE ('+included_columns+')' ELSE '' END
                END
            + ' WITH (PAD_INDEX  = ' + CASE WHEN is_padded = 1 THEN 'ON' ELSE 'OFF' END
            + ', STATISTICS_NORECOMPUTE  = OFF'
            + ', SORT_IN_TEMPDB = OFF'
            + ', IGNORE_DUP_KEY = OFF'
            + ', ONLINE = OFF'
            + ', ALLOW_ROW_LOCKS  = ON'
            + ', ALLOW_PAGE_LOCKS  = ON'
            + ', FILLFACTOR = ' 
            + CONVERT(varchar(3), CASE WHEN COALESCE(fill_factor, @DefaultFillFactor) = 0 THEN 100 ELSE COALESCE(fill_factor, @DefaultFillFactor) END)       
            + ') ON ' + QUOTENAME(COALESCE(filegroup, @DefaultFileGroup))
            + CHAR(13) + '--?>' AS xml) as ddl_create
    FROM #IndexBaseLine
    WHERE --index_name = '--MISSING--'
     --AND type_desc = '--NONCLUSTERED--'
     --AND 
       ((estimated_user_total_pct > 0.01 AND index_id IS NULL)
    OR related_foreign_keys IS NOT NULL
    OR index_id IS NOT NULL)
    AND estimated_user_total_pct > 5.00
    --ORDER BY table_buffer_mb DESC, object_id, user_total DESC
    ORDER BY QUOTENAME(table_name), index_name, index_action
    --ORDER BY impact DESC
END TRY
BEGIN CATCH
    DECLARE @ERROR_MESSAGE nvarchar(2048)
        ,@ERROR_SEVERITY int
        ,@ERROR_STATE INT
        
    SELECT @ERROR_MESSAGE  = ERROR_MESSAGE()
        ,@ERROR_SEVERITY = ERROR_SEVERITY()
        ,@ERROR_STATE = ERROR_STATE()
    
    RAISERROR(@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE)
END CATCH
GO

    IF OBJECT_ID('tempdb..#IndexBaseLine') IS NOT NULL
        DROP TABLE #IndexBaseLine

/****************************************************************************************************************************/
/**************************************** 6. Find Tables Without Primary Keys  **********************************************/
/****************************************************************************************************************************/
--bello: 'in heap' here means without primary care otherwise without a Clustered Index
 
--Find Tables Without Primary Keys
SELECT  SCHEMA_NAME(o.schema_id) AS [schema] ,
        OBJECT_NAME(i.object_id) AS [table] ,
        p.rows ,
        user_seeks ,
        user_scans ,
        user_lookups ,
        user_updates ,
        last_user_seek ,
        last_user_scan ,
        last_user_lookup
FROM    sys.indexes i
        INNER JOIN sys.objects o ON i.object_id = o.object_id
        INNER JOIN sys.partitions p ON i.object_id = p.object_id
                                       AND i.index_id = p.index_id
        LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id
                                                           AND i.index_id = ius.index_id
WHERE   i.type_desc = 'HEAP'
ORDER BY rows DESC

/****************************************************************************************************************************/
/**************************************** 7. Get Fillfactor *****************************************************************/
/****************************************************************************************************************************/
-- bello for quick insert an slow read,
--Fill factor  
SELECT *
FROM sys.configurations

--index-level 0verride
SELECT *
FROM sys.indexes
ORDER BY fill_factor

/****************************************************************************************************************************/
/**************************************** 8. Drop unused indexes ************************************************************/
/****************************************************************************************************************************/
--bello -  for a better maintenace 
--Drop unused indexes
SELECT 
o.name
, indexname=i.name
, i.index_id   
, reads=user_seeks + user_scans + user_lookups   
, writes =  user_updates   
, rows = (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id)
, CASE
      WHEN s.user_updates < 1 THEN 100
      ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
  END AS reads_per_write
, 'DROP INDEX ' + QUOTENAME(i.name) 
+ ' ON ' + QUOTENAME(c.name) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) as 'drop statement'
FROM sys.dm_db_index_usage_stats s  
INNER JOIN sys.indexes i ON i.index_id = s.index_id AND s.object_id = i.object_id   
INNER JOIN sys.objects o on s.object_id = o.object_id
INNER JOIN sys.schemas c on o.schema_id = c.schema_id
WHERE OBJECTPROPERTY(s.object_id,'IsUserTable') = 1
AND s.database_id = DB_ID()   
AND i.type_desc = 'nonclustered'
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
AND (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id) > 10000
ORDER BY reads

/****************************************************************************************************************************/
/**************************************** 9. Get Missing Index in Plan Cache ************************************************/
/****************************************************************************************************************************/

--Queries in the Plan Cache That Are Missing an Index
SELECT  qp.query_plan ,
        total_worker_time / execution_count AS AvgCPU ,
        total_elapsed_time / execution_count AS AvgDuration ,
        ( total_logical_reads + total_physical_reads ) / execution_count AS AvgReads ,
        execution_count ,
        SUBSTRING(st.TEXT, ( qs.statement_start_offset / 2 ) + 1,
                  ( ( CASE qs.statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.TEXT)
                        ELSE qs.statement_end_offset
                      END - qs.statement_start_offset ) / 2 ) + 1) AS txt ,
        qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]',
                            'decimal(18,4)') * execution_count AS TotalImpact ,
        qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]',
                            'varchar(100)') AS [DATABASE] ,
        qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]',
                            'varchar(100)') AS [TABLE]
FROM    sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
        CROSS APPLY sys.dm_exec_query_plan(plan_handle) qp
WHERE   qp.query_plan.exist('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan";/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex[@Database!="m"]') = 1
ORDER BY TotalImpact DESC

/****************************************************************************************************************************/
/********************************************** 10. Check index Fragmentation for all index (Shaw Script) *******************/
/****************************************************************************************************************************/
--bello avg_fragmentation_in_percent pour toutes les tables, rebuil those in need for sake of log
--https://blog.sqlauthority.com/2010/01/12/sql-server-fragmentation-detect-fragmentation-and-eliminate-fragmentation/
--avg_fragmentation_in_percent: is higher than 10%, some corrective /// > 5% and < 30%, then use ALTER INDEX REORGANIZE /// avg_fragmentation_in_percent > 30%, then use ALTER INDEX REBUILD:
--avg_page_space_used_in_percent : is lower than 75%, some corrective

-- Check index Fragmentation for all index
SELECT dbschemas.[name] as 'Schema', 
dbtables.[name] as 'Table', 
dbindexes.[name] as 'Index',
indexstats.avg_fragmentation_in_percent,
indexstats.page_count
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
--ORDER by dbtables.[name] 
ORDER by avg_fragmentation_in_percent DESC




/****************************************************************************************************************************/
/**************************************** 11. Potentially inefficent non-clustered indexes (writes > reads) *****************/
/****************************************************************************************************************************/
-- Potentially inefficent non-clustered indexes (writes > reads)
-- https://www.simple-talk.com/sql/performance/tune-your-indexing-strategy-with-sql-server-dmvs/

--bello user_updates > ( user_seeks + user_scans + user_lookups )

SELECT  OBJECT_NAME(ddius.[object_id]) AS [Table Name] ,
        i.name AS [Index Name] ,
        i.index_id ,
        user_updates AS [Total Writes] ,
        user_seeks + user_scans + user_lookups AS [Total Reads] ,
        user_updates - ( user_seeks + user_scans + user_lookups )
            AS [Difference]
FROM    sys.dm_db_index_usage_stats AS ddius WITH ( NOLOCK )
        INNER JOIN sys.indexes AS i WITH ( NOLOCK )
            ON ddius.[object_id] = i.[object_id]
            AND i.index_id = ddius.index_id
WHERE   OBJECTPROPERTY(ddius.[object_id], 'IsUserTable') = 1
        AND ddius.database_id = DB_ID()
        AND user_updates > ( user_seeks + user_scans + user_lookups )
        AND i.index_id > 1
ORDER BY [Difference] DESC ,
        [Total Writes] DESC ,
        [Total Reads] ASC ;
        
        


/****************************************************************************************************************************/
/**************************************** 12. Detailed activity information for indexes not used for user reads *************/
/****************************************************************************************************************************/        
 /*The script in Listing 6 isolates just those indexes that are not being used for user reads, courtesy of sys.dm_db_index_usage_stats, 
 and then provides detailed information on the type of writes still being incurred, using the leaf_*_count and nonleaf_*_count columns of sys.dm_db_index_operational_stats. 
 In this way, you gain a deep feel for how indexes are being used, and just exactly how much the index is costing you.  */  
 
 --bello [user_seeks] + [user_scans] + [user_lookups] = 0
    
-- https://www.simple-talk.com/sql/performance/tune-your-indexing-strategy-with-sql-server-dmvs/

        SELECT  '[' + DB_NAME() + '].[' + su.[name] + '].[' + o.[name] + ']'
                                                       AS [statement] ,
        i.[name] AS [index_name] ,
        ddius.[user_seeks] + ddius.[user_scans] + ddius.[user_lookups]
            AS [user_reads] ,
        ddius.[user_updates] AS [user_writes] ,
        ddios.[leaf_insert_count] ,
        ddios.[leaf_delete_count] ,
        ddios.[leaf_update_count] ,
        ddios.[nonleaf_insert_count] ,
        ddios.[nonleaf_delete_count] ,
        ddios.[nonleaf_update_count]
FROM    sys.dm_db_index_usage_stats ddius
        INNER JOIN sys.indexes i ON ddius.[object_id] = i.[object_id]
                                     AND i.[index_id] = ddius.[index_id]
        INNER JOIN sys.partitions SP ON ddius.[object_id] = SP.[object_id]
                                        AND SP.[index_id] = ddius.[index_id]
        INNER JOIN sys.objects o ON ddius.[object_id] = o.[object_id]
        INNER JOIN sys.sysusers su ON o.[schema_id] = su.[UID]
        INNER JOIN sys.[dm_db_index_operational_stats](DB_ID(), NULL, NULL,
                                                       NULL)
                  AS ddios
                      ON ddius.[index_id] = ddios.[index_id]
                         AND ddius.[object_id] = ddios.[object_id]
                         AND SP.[partition_number] = ddios.[partition_number]
                         AND ddius.[database_id] = ddios.[database_id]
WHERE OBJECTPROPERTY(ddius.[object_id], 'IsUserTable') = 1
      AND ddius.[index_id] > 0
      AND ddius.[user_seeks] + ddius.[user_scans] + ddius.[user_lookups] = 0
ORDER BY ddius.[user_updates] DESC ,
        su.[name] ,
        o.[name] ,
        i.[name ] 
        
        


/****************************************************************************************************************************/
/**************************** 13. Identify lock escalations *****************************************************************/
/****************************************************************************************************************************/        
 -- https://www.simple-talk.com/sql/performance/tune-your-indexing-strategy-with-sql-server-dmvs/
 
 --bello: change lock level see 'index_lock_promotion_count' > 0

        SELECT  OBJECT_NAME(ddios.[object_id], ddios.database_id) AS [object_name] ,
        i.name AS index_name ,
        ddios.index_id ,
        ddios.partition_number ,
        ddios.index_lock_promotion_attempt_count ,
        ddios.index_lock_promotion_count ,
        ( ddios.index_lock_promotion_attempt_count
          / ddios.index_lock_promotion_count ) AS percent_success
FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
        INNER JOIN sys.indexes i ON ddios.OBJECT_ID = i.OBJECT_ID
                                    AND ddios.index_id = i.index_id
WHERE   ddios.index_lock_promotion_count > 0 



/****************************************************************************************************************************/
/**************************** 1.2 Create Missing Index - thinkhealth version ************************************************/
/****************************************************************************************************************************/        
	SELECT  [statement] as TableName, 'CREATE NONCLUSTERED INDEX IX_' 
				+ OBJECT_NAME(mid.object_id)
				+ '_' 
				+ REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,'')+ISNULL(mid.inequality_columns,''), '[', ''), ']',''), ', ','_')
				+ ' ON ' 
				+ [statement] 
				+ ' ( ' + IsNull(mid.equality_columns, '') 
				+ CASE WHEN mid.inequality_columns IS NULL THEN '' ELSE 
					CASE WHEN mid.equality_columns IS NULL THEN '' ELSE ',' END 
				+ mid.inequality_columns END + ' ) ' 
				+ CASE WHEN mid.included_columns IS NULL THEN '' ELSE 'INCLUDE (' + mid.included_columns + ')' END 
				+ ';' as IndexNeeded, 
			floor(round((avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans),0)) as ImpactLevel,
			Getdate() as AlertDate, 
			DB_NAME([database_id]) as DbName,
			  migs.avg_system_impact,
			  migs.avg_user_impact,
			  migs.last_user_seek,
			  migs.unique_compiles ,
			  migs.user_seeks ,
              migs.avg_total_user_cost,
              migs.avg_total_system_cost, 	
              mid.equality_columns ,
			  mid.inequality_columns ,
              mid.included_columns
		FROM sys.dm_db_missing_index_group_stats AS migs 
		INNER JOIN sys.dm_db_missing_index_groups AS mig ON migs.group_handle = mig.index_group_handle 
		INNER JOIN sys.dm_db_missing_index_details AS mid ON mig.index_handle = mid.index_handle 
		INNER JOIN sys.objects WITH (nolock) ON mid.OBJECT_ID = sys.objects.OBJECT_ID 
		WHERE (migs.group_handle IN 
			(SELECT TOP 500 group_handle 
			 FROM sys.dm_db_missing_index_group_stats WITH (nolock) 
			 ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC))  
			 AND OBJECTPROPERTY(sys.objects.OBJECT_ID, 'isusertable') = 1 
			 AND (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) > 250000		
		ORDER BY ImpactLevel DESC , IndexNeeded DESC
