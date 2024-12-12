
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @SQLServerProductVersion NVARCHAR(128);
SELECT @SQLServerProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));


                SELECT   
                        so.object_id, 
                        si.index_id, 
                        si.type,
                        COALESCE(sc.name, 'Unknown') AS [schema_name],
                        COALESCE(so.name, 'Unknown') AS [object_name], 
                        COALESCE(si.name, 'Unknown') AS [index_name],
 --                       CASE    WHEN so.[type] = CAST('V' AS CHAR(2)) THEN 1 ELSE 0 END, 
                        si.is_unique, 
                        si.is_primary_key, 
						si.is_unique_constraint,
						ISNULL(us.user_seeks, 0) user_seeks,
                        ISNULL(us.user_scans, 0) user_scans,
                        ISNULL(us.user_lookups, 0) user_lookups,
                        ISNULL(us.user_updates, 0) user_lookups,
                        us.last_user_seek,
                        us.last_user_scan,
                        us.last_user_lookup,
                        us.last_user_update,
                        so.create_date,
                        so.modify_date,
						                        si.fill_factor,
						CASE when si.type = 3 THEN 1 ELSE 0 END AS is_XML,
                        CASE when si.type = 4 THEN 1 ELSE 0 END AS is_spatial,
                        CASE when si.type = 6 THEN 1 ELSE 0 END AS is_NC_columnstore,
                        CASE when si.type = 5 then 1 else 0 end as is_CX_columnstore,
                        CASE when si.data_space_id = 0 then 1 else 0 end as is_in_memory_oltp,
                        si.is_disabled,
                        si.is_hypothetical, 
                        si.is_padded 
                FROM    sys.indexes AS si WITH (NOLOCK)
                        JOIN sys.objects AS so WITH (NOLOCK) ON si.object_id = so.object_id
                                               AND so.is_ms_shipped = 0 /*Exclude objects shipped by Microsoft*/
                                               AND so.type <> 'TF' /*Exclude table valued functions*/
                        JOIN sys.schemas sc ON so.schema_id = sc.schema_id
                        LEFT JOIN sys.dm_db_index_usage_stats AS us WITH (NOLOCK) ON si.[object_id] = us.[object_id]
                                                                       AND si.index_id = us.index_id
                WHERE    --si.[type] IN ( 0, 1, 2, 3, 4, 5, 6 ) 
                /* Heaps, clustered, nonclustered, XML, spatial, Cluster Columnstore, NC Columnstore */ 
 --AND
    us.user_lookups = 0
    AND
    us.user_seeks = 0
    AND
    us.user_scans = 0  
	and
	si.is_primary_key = 0 -- This condition excludes primary key constarint
    AND
    si.is_unique = 0 -- This condition excludes unique key constarint
	AND 
    us.user_updates <> 0 -- This line excludes indexes SQL Server hasn’t done any work with
	OPTION    ( RECOMPILE );
        



--		SELECT top 100 [table_name], [index_name], [Create_Tsql], [index_id],  [object_type], 
--		[index_definition], 
-- SUBSTRING(index_size_summary, 
--		CHARINDEX('Writes:', index_size_summary) + 7, 20) AS TotalWrites, total_rows, total_reserved_MB
--FROM RmsAdmin.dbo.BlitzIndex
--WHERE 
--index_size_summary <> 'Reads: 0 Writes:0'
--ORDER BY [table_name],[index_name],run_datetime DESC