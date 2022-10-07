--  -- https://database.guide/fix-arithmetic-overflow-error-converting-expression-to-data-type-int-in-sql-server/
SELECT Db_Name(QueryText.dbid) AS database_name,
  Sum(CASE WHEN ExecPlans.usecounts = 1 THEN 1 ELSE 0 END) AS Single,
  Sum(CASE WHEN ExecPlans.usecounts > 1 THEN 1 ELSE 0 END) AS Reused,
  --Sum(ExecPlans.size_in_bytes) / (1024) AS KB -- Arithmetic overflow error converting expression to data type int.
  -- https://database.guide/fix-arithmetic-overflow-error-converting-expression-to-data-type-int-in-sql-server/
  Sum(CAST(ExecPlans.size_in_bytes AS BIGINT)) / (1024) AS KB
   FROM sys.dm_exec_cached_plans AS ExecPlans
    CROSS APPLY sys.dm_exec_sql_text(ExecPlans.plan_handle) AS QueryText
   WHERE ExecPlans.cacheobjtype = 'Compiled Plan' AND QueryText.dbid IS NOT NULL 
     GROUP BY QueryText.dbid;
