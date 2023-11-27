--use IndexOptimize.sql from
-- https://ola.hallengren.com/downloads.html


-- https://docs.microsoft.com/en-us/sql/relational-databases/indexes/reorganize-and-rebuild-indexes?view=sql-server-ver16#index-maintenance-strategy
-- If you observe that rebuilding indexes improves performance, try replacing it with updating statistics
-- In that case, you may not need to rebuild indexes as frequently, or at all

--get status of fragmentation USE [maintenance]
GO

/****** Object:  Table [dbo].[indexFragmentation]    Script Date: 3/27/2023 2:28:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[indexFragmentation](
	[schemaName] [nvarchar](128) NULL,
	[ObjectName] [nvarchar](128) NULL,
	[index_name] [nvarchar](128) NULL,
	[index_type] [nvarchar](128) NULL,
	[avg_fragmentation_in_percent] [float] NULL,
	[Average_page_density] [float] NULL,
	[page_count] [bigint] NULL,
	[alloc_unit_type_desc] [nvarchar](128) NULL,
	[TimeChecked] [datetime] NULL
) ON [PRIMARY]
GO

ALTER AUTHORIZATION ON [dbo].[indexFragmentation] TO  SCHEMA OWNER 
GO


--insert into maintenance.dbo.indexFragmentation -- rebuid statement at the end of columns' list
SELECT OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
       OBJECT_NAME(ips.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       ips.avg_fragmentation_in_percent,
       ips.avg_page_space_used_in_percent as 'Average_page_density', --  low, more pages are required to store the same amount of data
       ips.page_count,
       ips.alloc_unit_type_desc,
	   getdate(),
  'alter index '+i.name + ' on ' + OBJECT_SCHEMA_NAME(ips.object_id) + '.'+ OBJECT_NAME(ips.object_id) + ' REBUILD' as 'rebuid statement',
FROM sys.dm_db_index_physical_stats(DB_ID(), default, default, default, 'LIMITED') AS ips
INNER JOIN sys.indexes AS i 
ON ips.object_id = i.object_id
   AND
   ips.index_id = i.index_id
where ips.avg_fragmentation_in_percent > 70
ORDER BY page_count DESC;

---- read before and after defragmentation 
select ObjectName, index_name, avg_fragmentation_in_percent, TimeChecked ,
	   page_count * 8.0*0.00000095367432 as Size --1KB = 0.00000095367432 and a page = 8KB
	   , (select sum(row_count) from sys.dm_db_partition_stats st where st.object_id = object_id('dbo.table1') and st.index_id < 2) numberOfRows
	   ,page_count,alloc_unit_type_desc,Average_page_density
from maintenance.dbo.indexFragmentation
--where index_name in('IX_table1') --and alloc_unit_type_desc = 'IN_ROW_DATA'
order by index_name, TimeChecked desc


-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver16
--The modes are progressively slower from LIMITED to DETAILED, because more work is performed in each mode. 
--To quickly gauge the size or fragmentation level of a table or index, use the LIMITED mode. 
--It is the fastest and will not return a row for each nonleaf level in the IN_ROW_DATA allocation unit of the index.
EXECUTE maintenance.dbo.IndexOptimize
@Databases = 'Sales',
@FragmentationLow = NULL,
@FragmentationMedium = NULL,
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@indexes = 'Sales.dbo.Table1,
Sales.dbo.Table2,
Sales.dbo.Table3
',
@MaxDOP = 4,
--@FillFactor - fill factor in sys.indexes is used.
--@UpdateStatistics - Do not perform statistics maintenance.
@Resumable = 'Y', -- online index operation is resumable
@WaitAtLowPriorityMaxDuration = 5,  -- in minutes 
@WaitAtLowPriorityAbortAfterWait = 'SELF', -- Abort the online index rebuild operation after 5min
@TimeLimit = 4000, -- in seconds ie  1350s = 45min -- ie no commands are executed
@LogToTable = 'Y',
@Execute = 'Y'
--or
--ALTER INDEX IX_anIndex_name ON dbo.ordersTable REBUILD;
--ALTER INDEX ALL ON dbo.ordersTable REORGANIZE;




-- instead of the one below








-- http://www.sqlmusings.com
USE SUSDB  -- <databasename> statement has been executed first.
GO

--CREATE NONCLUSTERED INDEX [IX_20220427] ON [dbo].[table1]
--(
--[keyx] ASC
--)
--WITH (ONLINE = ON, FILLFACTOR = 95) ON [PRIMAR

SET NOCOUNT ON

-- adapted from "Rebuild or reorganize indexes (with configuration)" from MSDN Books Online 
-- (http://msdn.microsoft.com/en-us/library/ms188917.aspx)
 
-- =======================================================
-- || Configuration variables:
-- || - 10 is an arbitrary decision point at which to
-- || reorganize indexes.
-- || - 30 is an arbitrary decision point at which to
-- || switch from reorganizing, to rebuilding.
-- || - 0 is the default fill factor. Set this to a
-- || a value from 1 to 99, if needed.
-- =======================================================
DECLARE @reorg_frag_thresh   float		SET @reorg_frag_thresh   = 10.0
DECLARE @rebuild_frag_thresh float		SET @rebuild_frag_thresh = 30.0
DECLARE @fill_factor         tinyint	SET @fill_factor         = 80
DECLARE @report_only         bit		SET @report_only         = 0

-- added (DS) : page_count_thresh is used to check how many pages the current table uses
DECLARE @page_count_thresh	 smallint	SET @page_count_thresh   = 1000
 
-- Variables required for processing.
DECLARE @objectid       int
DECLARE @indexid        int
DECLARE @partitioncount bigint
DECLARE @schemaname     nvarchar(130) 
DECLARE @objectname     nvarchar(130) 
DECLARE @indexname      nvarchar(130) 
DECLARE @partitionnum   bigint
DECLARE @partitions     bigint
DECLARE @frag           float
DECLARE @page_count     int
DECLARE @command        nvarchar(4000)
DECLARE @intentions     nvarchar(4000)
DECLARE @table_var      TABLE(
                          objectid     int,
                          indexid      int,
                          partitionnum int,
                          frag         float,
						  page_count   int
                        )
 
-- Conditionally select tables and indexes from the
-- sys.dm_db_index_physical_stats function and
-- convert object and index IDs to names.
INSERT INTO
    @table_var
SELECT
    [object_id]                    AS objectid,
    [index_id]                     AS indexid,
    [partition_number]             AS partitionnum,
    [avg_fragmentation_in_percent] AS frag,
	[page_count]				   AS page_count
FROM
    sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'LIMITED')
WHERE
    [avg_fragmentation_in_percent] > @reorg_frag_thresh 
	AND
	page_count > @page_count_thresh
	AND
    index_id > 0
	
 
-- Declare the cursor for the list of partitions to be processed.
DECLARE partitions CURSOR FOR
    SELECT * FROM @table_var
 
-- Open the cursor.
OPEN partitions
 
-- Loop through the partitions.
WHILE (1=1) BEGIN
    FETCH NEXT
        FROM partitions
        INTO @objectid, @indexid, @partitionnum, @frag, @page_count
 
    IF @@FETCH_STATUS < 0 BREAK
 
    SELECT
        @objectname = QUOTENAME(o.[name]),
        @schemaname = QUOTENAME(s.[name])
    FROM
        sys.objects AS o WITH (NOLOCK)
        JOIN sys.schemas as s WITH (NOLOCK)
        ON s.[schema_id] = o.[schema_id]
    WHERE
        o.[object_id] = @objectid
 
    SELECT
        @indexname = QUOTENAME([name])
    FROM
        sys.indexes WITH (NOLOCK)
    WHERE
        [object_id] = @objectid AND
        [index_id] = @indexid
 
    SELECT
        @partitioncount = count (*)
    FROM
        sys.partitions WITH (NOLOCK)
    WHERE
        [object_id] = @objectid AND
        [index_id] = @indexid
 
    -- Build the required statement dynamically based on options and index stats.
    SET @intentions =
        @schemaname + N'.' +
        @objectname + N'.' +
        @indexname + N':' + CHAR(13) + CHAR(10)
    SET @intentions =
        REPLACE(SPACE(LEN(@intentions)), ' ', '=') + CHAR(13) + CHAR(10) +
        @intentions
    SET @intentions = @intentions +
        N' FRAGMENTATION: ' + CAST(@frag AS nvarchar) + N'%' + CHAR(13) + CHAR(10) +
        N' PAGE COUNT: '    + CAST(@page_count AS nvarchar) + CHAR(13) + CHAR(10)
 
    IF @frag < @rebuild_frag_thresh BEGIN
        SET @intentions = @intentions +
            N' OPERATION: REORGANIZE' + CHAR(13) + CHAR(10)
        SET @command =
            N'ALTER INDEX ' + @indexname +
            N' ON ' + @schemaname + N'.' + @objectname +
            N' REORGANIZE; ' + 
            N' UPDATE STATISTICS ' + @schemaname + N'.' + @objectname + 
            N' ' + @indexname + ';'

    END
    IF @frag >= @rebuild_frag_thresh BEGIN
        SET @intentions = @intentions +
            N' OPERATION: REBUILD' + CHAR(13) + CHAR(10)
        SET @command =
            N'ALTER INDEX ' + @indexname +
            N' ON ' + @schemaname + N'.' +     @objectname +
            N' REBUILD'
    END
    IF @partitioncount > 1 BEGIN
        SET @intentions = @intentions +
            N' PARTITION: ' + CAST(@partitionnum AS nvarchar(10)) + CHAR(13) + CHAR(10)
        SET @command = @command +
            N' PARTITION=' + CAST(@partitionnum AS nvarchar(10))
    END
    IF @frag >= @rebuild_frag_thresh AND @fill_factor > 0 AND @fill_factor < 100 BEGIN
        SET @intentions = @intentions +
            N' FILL FACTOR: ' + CAST(@fill_factor AS nvarchar) + CHAR(13) + CHAR(10)
        SET @command = @command +
            N' WITH (FILLFACTOR = ' + CAST(@fill_factor AS nvarchar) + ')'
    END
 
    -- Execute determined operation, or report intentions
    IF @report_only = 0 BEGIN
        SET @intentions = @intentions + N' EXECUTING: ' + @command
        PRINT @intentions	    
        EXEC (@command)
    END ELSE BEGIN
        PRINT @intentions
    END
	PRINT @command

END
 
-- Close and deallocate the cursor.
CLOSE partitions
DEALLOCATE partitions
 
GO
