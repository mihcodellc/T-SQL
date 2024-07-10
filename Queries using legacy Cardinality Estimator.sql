--CREATE TABLE #checkversion (
--version nvarchar(128),
--maj_version AS SUBSTRING(version, 1,CHARINDEX('.', version) + 1 ),
--build AS PARSENAME(CONVERT(varchar(32), version), 2)
--);
delete #checkversion
DECLARE @v DECIMAL(6,2);

INSERT INTO #checkversion (version)
SELECT CAST(SERVERPROPERTY('ProductVersion') as nvarchar(128))
OPTION (RECOMPILE);

SELECT @v = maj_version
FROM #checkversion
OPTION (RECOMPILE);

select #checkversion

SELECT st.text,
qp.query_plan
FROM (
SELECT TOP 50 *
FROM sys.dm_exec_query_stats
ORDER BY total_worker_time DESC
) AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan"; min(//p:StmtSimple/@CardinalityEstimationModelVersion)', 'int') < @v * 10
OPTION (RECOMPILE) ;

-- Select statement with a hint to use legacy cardinality estimation
SELECT *
FROM YourTable
OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION'));
