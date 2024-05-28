--select  distinct FindingsGroup from BlitzFirst

--[sp_Blitz]

SELECT 
'Performance' AS FindingsGroup,
'High Number of Cached Plans' AS Finding,
'https://www.brentozar.com/go/planlimits' AS URL,
 CAST(ht.buckets_count * 4 AS VARCHAR(20)) ServerPlanLimits,  ht.name ,  CAST(cc.entries_count AS VARCHAR(20))  AS currently_caching
FROM sys.dm_os_memory_cache_hash_tables ht
INNER JOIN sys.dm_os_memory_cache_counters cc ON ht.name = cc.name AND ht.type = cc.type
where ht.name IN ( 'SQL Plans')
AND cc.entries_count >= (3 * ht.buckets_count) --OPTION (RECOMPILE)
UNION ALL
SELECT 
'Performance' AS FindingsGroup,
'High Number of Cached Plans' AS Finding,
'https://www.brentozar.com/go/planlimits' AS URL,
 CAST(ht.buckets_count * 4 AS VARCHAR(20)) ServerPlanLimits,  ht.name ,  CAST(cc.entries_count AS VARCHAR(20))  AS currently_caching
FROM sys.dm_os_memory_cache_hash_tables ht
INNER JOIN sys.dm_os_memory_cache_counters cc ON ht.name = cc.name AND ht.type = cc.type
where ht.name IN ( 'Object Plans' )
AND cc.entries_count >= (3 * ht.buckets_count) --OPTION (RECOMPILE)
UNION ALL
SELECT 
'Performance' AS FindingsGroup,
'High Number of Cached Plans' AS Finding,
'https://www.brentozar.com/go/planlimits' AS URL,
 CAST(ht.buckets_count * 4 AS VARCHAR(20)) ServerPlanLimits,  ht.name ,  CAST(cc.entries_count AS VARCHAR(20))  AS currently_caching
FROM sys.dm_os_memory_cache_hash_tables ht
INNER JOIN sys.dm_os_memory_cache_counters cc ON ht.name = cc.name AND ht.type = cc.type
where ht.name IN ( 'Bound Trees')
AND cc.entries_count >= (3 * ht.buckets_count) OPTION (RECOMPILE)






 -- single used plan stats
SELECT 'single used plan stats' as About,
    cp.objtype AS ObjectType,
    cp.cacheobjtype AS PlanType, 
    COUNT(*) AS PlanCount --, sum(usecounts) over (partition by cp.cacheobjtype, cp.objtype order by 1) 
    ,sum(refcounts) as RefCount
    ,SUM(cp.size_in_bytes*1.00) / 1024/1024 AS TotalSizeInMB
FROM 
    sys.dm_exec_cached_plans AS cp
    where cp.usecounts = 1
GROUP BY 
    cp.objtype,
    cp.cacheobjtype
ORDER BY 
    PlanCount DESC;

    --******************


-- inspired by https://www.sqlskills.com/blogs/kimberly/plan-cache-and-optimizing-for-adhoc-workloads/
SELECT 'single used plan VS all plans stats' as About,
objtype AS ObjectType
	,cacheobjtype AS [CacheType]
	,SUM(CASE 
			WHEN usecounts = 1
				THEN 1
			ELSE 0
			END) AS [Count: Single Use Plans]

	,SUM(CAST((
				CASE 
					WHEN usecounts = 1
						THEN size_in_bytes
					ELSE 0
					END
				) AS DECIMAL(18, 2))) / 1024 / 1024 AS [MB: Single Use Plans]
	,COUNT_BIG(*) AS [Count: All Plans]
	,SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [MB - All Plans]
	,AVG(usecounts) AS [Avg Use Count]
FROM sys.dm_exec_cached_plans
GROUP BY 
    objtype,
    cacheobjtype
ORDER BY [MB: Single Use Plans] DESC
GO


SELECT 
    COUNT(*) AS NumberOfPlans
FROM 
    sys.dm_exec_cached_plans;


--INSERT INTO QueryPlanStats
SELECT 
objtype AS ObjectType
	,cacheobjtype AS [CacheType]
	,SUM(CASE 
			WHEN usecounts = 1
				THEN 1
			ELSE 0
			END) AS [Count: Single Use Plans]

	,SUM(CAST((
				CASE 
					WHEN usecounts = 1
						THEN size_in_bytes
					ELSE 0
					END
				) AS DECIMAL(18, 2))) / 1024 / 1024 AS [MB: Single Use Plans]
	,COUNT_BIG(*) AS [Count: All Plans]
	,SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [MB - All Plans]
	,AVG(usecounts) AS [Avg Use Count]
	,datepart(hour, getdate()) as itsHour
	,convert(date,getdate(),112) as itsDay
	-- into QueryPlanStats
FROM sys.dm_exec_cached_plans
GROUP BY 
    objtype,
    cacheobjtype
ORDER BY [MB: Single Use Plans] DESC
GO

--CREATE INDEX IX_QueryPlanStats_ItsDay ON QueryPlanStats(itsDay)
--CREATE INDEX IX_QueryPlanStats_itsHour ON QueryPlanStats(itsHour)

--select * from QueryPlanStats
----truncate table QueryPlanStats
