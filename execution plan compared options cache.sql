--your execution plan attributes to know which settings is used by your execution plan
--this is beside comparing the graph in ssms

-- https://statisticsparser.com/

--ssms command windows: Tools.DiffFiles a.sql b.sql

--https://www.mssqltips.com/sqlservertip/4318/sql-server-stored-procedure-runs-fast-in-ssms-and-slow-in-application/

-- Get the full text of a long request
-- https://dba.stackexchange.com/questions/245590/get-the-full-text-of-a-long-request
declare @sql_handle   varbinary(64) = 0x02000000DD7D4A1A64B697EB08E3668D024EBEC76A6A8F510000000000000000000000000000000000000000;
select text from sys.dm_exec_sql_text(@sql_handle)
FOR XML RAW, ELEMENTS;


--get the plan_handle for next query OR better query the XML from "get the full text of long quey"
select DB_NAME(st.dbid) as DbName, qs.execution_count,  OBJECT_NAME(st.objectid) as obj--, st.* , creation_time, qp.query_plan, plan_handle
from sys.dm_exec_query_stats as qs 
cross apply sys.dm_exec_sql_text(qs.sql_handle) st
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp  
where OBJECT_NAME(st.objectid)='testDropCreate'
--where st.text like '%SELECT TOP 100%text%'


-- plan for query or object
select o.object_id, OBJECT_NAME(o.object_id),  cached_time, last_execution_time,execution_count, s.plan_handle,h.query_plan, s.* 
from sys.objects o 
inner join sys.dm_exec_procedure_stats s on o.object_id = s.object_id
cross apply sys.dm_exec_query_plan(s.plan_handle) h
where o.object_id = object_id('apps.testDropCreate')

SELECT st.text, memory_object_address, cp.objtype, refcounts, usecounts, 
    qs.query_plan_hash, qs.query_hash as '/* query_hash = query_plan_hash if not recompiled*/', qs.sql_handle as 'sql_handle same for a batch', qs.plan_handle,  p.query_plan
    , a.value AS set_options
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan (cp.plan_handle) p
cross apply sys.dm_exec_plan_attributes(cp.plan_handle) a
INNER JOIN sys.dm_exec_query_stats AS qs ON qs.plan_handle = cp.plan_handle
WHERE st.text LIKE '%usp_SalesByCustomer%' 
	   AND a.attribute = 'set_options'
order by qs.sql_handle, st.text

-- session link to a plan, execution count
SELECT st.text, c.sql_handle as '/* sql_handle uniq for a batch and 1,N with plan_handle */', p.plan_handle, db_name(st.dbid) databse, sdec.session_id, sdec.client_net_address,sdec.local_net_address    ,sdes.login_name
, sdes.host_name 
    ,sdes.program_name
    ,sdes.login_name, a.value AS set_options, p.size_in_bytes, p.usecounts
 --, p.
FROM sys.dm_exec_cached_plans p
join sys.dm_exec_query_stats c on c.plan_handle = p.plan_handle
join sys.dm_exec_connections sdec on sdec.most_recent_sql_handle = c.sql_handle
JOIN sys.dm_exec_sessions AS sdes on sdes.session_id = sdec.session_id
cross apply sys.dm_exec_sql_text(p.plan_handle) st
cross apply sys.dm_exec_plan_attributes(c.plan_handle) a
WHERE a.attribute = 'set_options'
group by c.sql_handle, st.text, p.plan_handle, db_name(st.dbid) , sdec.session_id, sdec.client_net_address,sdec.local_net_address    ,sdes.login_name
, sdes.host_name 
    ,sdes.program_name
    ,sdes.login_name, a.value , p.size_in_bytes, p.usecounts

select * FROM sys.dm_exec_cached_plans AS decp;

--https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-plan-attributes-transact-sql?redirectedfrom=MSDN&view=sql-server-ver15

--provide 2 differents plan_handle to see the aatributes particularly  'set_options'
select * from sys.dm_exec_plan_attributes (0x05000600D5E4C86610DE2F090200000001000000000000000000000000000000000000000000000000000000)
select * from sys.dm_exec_plan_attributes (0x05000600D5E4C8661095B5670200000001000000000000000000000000000000000000000000000000000000)

--Evaluating 'set_options' set options @@options, Cursor Options with which a plan has been compiled with
--use the table in 
--https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-plan-attributes-transact-sql?redirectedfrom=MSDN&view=sql-server-ver15
--To translate the value returned in set_options to the options with which the plan was compiled, 
--subtract the values from the set_options value, starting with the largest possible value, until you reach 0. 
--Each value you subtract corresponds to an option that was used in the query plan. 
--For example, if the value in set_options is 251, the options the plan was compiled with are 
--ANSI_NULL_DFLT_ON (128), QUOTED_IDENTIFIER (64), ANSI_NULLS(32), ANSI_WARNINGS (16), CONCAT_NULL_YIELDS_NULL (8), Parallel Plan(2) and ANSI_PADDING (1).
-- compare the set below with recommandations 
with OPTION_VALUES as (
select
optionValues.id,
optionValues.name,
optionValues.description,
row_number() over (partition by 1 order by id) as bitNum
from (values
-- https://learn.microsoft.com/en-us/sql/t-sql/functions/options-transact-sql?view=sql-server-ver16
(1, 'DISABLE_DEF_CNST_CHK', 'Controls interim or deferred constraint checking.'),
(2, 'IMPLICIT_TRANSACTIONS', 'For dblib network library connections, controls whether a transaction is started implicitly when a statement is executed. The IMPLICIT_TRANSACTIONS setting has no effect on ODBC or OLEDB connections.'),
(4, 'CURSOR_CLOSE_ON_COMMIT', 'Controls behavior of cursors after a commit operation has been performed.'),
(8, 'ANSI_WARNINGS', 'Controls truncation and NULL in aggregate warnings.'),
(16, 'ANSI_PADDING', 'Controls padding of fixed-length variables.'),
(32, 'ANSI_NULLS', 'Controls NULL handling when using equality operators.'),
(64, 'ARITHABORT', 'Terminates a query when an overflow or divide-by-zero error occurs during query execution.'),
(128, 'ARITHIGNORE', 'Returns NULL when an overflow or divide-by-zero error occurs during a query.'),
(256, 'QUOTED_IDENTIFIER', 'Differentiates between single and double quotation marks when evaluating an expression.'),
(512, 'NOCOUNT', 'Turns off the message returned at the end of each statement that states how many rows were affected.'),
(1024, 'ANSI_NULL_DFLT_ON', 'Alters the session'+char(39)+'s behavior to use ANSI compatibility for nullability. New columns defined without explicit nullability are defined to allow nulls.'),
(2048, 'ANSI_NULL_DFLT_OFF', 'Alters the session'+char(39)+'s behavior not to use ANSI compatibility for nullability. New columns defined without explicit nullability do not allow nulls.'),
(4096, 'CONCAT_NULL_YIELDS_NULL', 'Returns NULL when concatenating a NULL value with a string.'),
(8192, 'NUMERIC_ROUNDABORT', 'Generates an error when a loss of precision occurs in an expression.'),
(16384, 'XACT_ABORT', 'Rolls back a transaction if a Transact-SQL statement raises a run-time error.')
) as optionValues(id, name, description)
)
select *, case when (@@options & id) = id then 1 else 0 end as setting
from OPTION_VALUES; -- from https://www.mssqltips.com/sqlservertip/1415/determining-set-options-for-a-current-session-in-sql-server/

--paramter sniffing solutions
-- https://docs.microsoft.com/en-us/azure/azure-sql/identify-query-performance-issues?view=azuresql#ParamSniffing

DECLARE @options INT
SELECT @options = 262395
PRINT @options
IF ( (1 & @options) = 1 ) PRINT 'DISABLE_DEF_CNST_CHK'
IF ( (2 & @options) = 2 ) PRINT 'IMPLICIT_TRANSACTIONS'
IF ( (4 & @options) = 4 ) PRINT 'CURSOR_CLOSE_ON_COMMIT'
IF ( (8 & @options) = 8 ) PRINT 'ANSI_WARNINGS'
IF ( (16 & @options) = 16 ) PRINT 'ANSI_PADDING'
IF ( (32 & @options) = 32 ) PRINT 'ANSI_NULLS'
IF ( (64 & @options) = 64 ) PRINT 'ARITHABORT'
IF ( (128 & @options) = 128 ) PRINT 'ARITHIGNORE'
IF ( (256 & @options) = 256 ) PRINT 'QUOTED_IDENTIFIER'
IF ( (512 & @options) = 512 ) PRINT 'NOCOUNT'
IF ( (1024 & @options) = 1024 ) PRINT 'ANSI_NULL_DFLT_ON'
IF ( (2048 & @options) = 2048 ) PRINT 'ANSI_NULL_DFLT_OFF'
IF ( (4096 & @options) = 4096 ) PRINT 'CONCAT_NULL_YIELDS_NULL'
IF ( (8192 & @options) = 8192 ) PRINT 'NUMERIC_ROUNDABORT'
IF ( (16384 & @options) = 16384 ) PRINT 'XACT_ABORT'


-- set_options ON in string
SELECT p.plan_handle, p.usecounts, p.size_in_bytes, 
  case when (1 & cast(MAX(a.value) as int)) = 1  then 'DISABLE_DEF_CNST_CHK, ' else ', ' end +
  case when (2 & cast(MAX(a.value) as int)) = 2  then 'IMPLICIT_TRANSACTIONS, ' else ', ' end  +
  case when (4 & cast(MAX(a.value) as int)) = 4  then 'CURSOR_CLOSE_ON_COMMIT, ' else ', ' end  +
  case when (8 & cast(MAX(a.value) as int)) = 8  then 'ANSI_WARNINGS, ' else ', ' end  +
  case when (16 & cast(MAX(a.value) as int)) = 16  then 'ANSI_PADDING, ' else ', ' end +
  case when (32 & cast(MAX(a.value) as int)) = 32  then 'ANSI_NULLS, ' else ', ' end  +
  case when (64 & cast(MAX(a.value) as int)) = 64  then 'ARITHABORT, ' else ', ' end  +
  case when (128 & cast(MAX(a.value) as int)) = 128  then 'ARITHIGNORE, ' else ', ' end  +
  case when (256 & cast(MAX(a.value) as int)) = 256  then 'QUOTED_IDENTIFIER, ' else ', ' end +
  case when (512 & cast(MAX(a.value) as int)) = 512  then 'NOCOUNT, ' else ', ' end  +
  case when (1024 & cast(MAX(a.value) as int)) = 1024  then 'ANSI_NULL_DFLT_ON, ' else ', ' end  +
  case when (2048 & cast(MAX(a.value) as int)) = 2048  then 'ANSI_NULL_DFLT_OFF, ' else ', ' end  +
  case when (4096 & cast(MAX(a.value) as int)) = 4096  then 'CONCAT_NULL_YIELDS_NULL, ' else ', ' end  +
  case when (8196 & cast(MAX(a.value) as int)) = 8192  then 'NUMERIC_ROUNDABORT, ' else ', ' end  +
  case when (16384 & cast(MAX(a.value) as int)) = 16384  then 'XACT_ABORT, ' else ', ' end
  itsoptions
  ,MAX(a.value) itsValue, object_name(t.objectid) name
FROM sys.dm_exec_cached_plans AS p
CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) AS t
CROSS APPLY sys.dm_exec_plan_attributes(p.plan_handle) AS a
WHERE p.objtype = 'Adhoc' AND p.usecounts = 1  --t.objectid = OBJECT_ID(N'SLID_Hist')
 and a.attribute = N'set_options'
GROUP BY p.plan_handle, p.usecounts, p.size_in_bytes, t.objectid

--**** causes of multiples plans for a query 
-- ###causes -- https://www.brentozar.com/archive/2018/03/why-multiple-plans-for-one-query-are-bad/
--    literal of 8Kilobytes or more in the query
--non full qualified named names where referring to an object SP, tables ...
--the query is not the same due to the white space, literals used, or different size(KB) of the query 
--the batch of the queries (sql_handle) is different
--partial parameterization(markers) of the query

--**** solution if developers won't make the changes
--  is to turn on "Forced Parameterization" on the Databse level
USE master;
GO
ALTER DATABASE MyDatabase
SET PARAMETERIZATION FORCED; -- SIMPLE
GO 


-- https://sqlperformance.com/2014/11/t-sql-queries/multiple-plans-identical-query
-- https://www.red-gate.com/hub/product-learning/sql-monitor/investigating-problems-ad-hoc-queries-using-sql-monitor
-- https://www.brentozar.com/blitz/forced-parameterization/
-- https://www.brentozar.com/archive/2018/03/why-multiple-plans-for-one-query-are-bad/




--**** determining the ratio between the multi-use and single-use query execution plans cached
SELECT --Db_Name(QueryText.dbid) AS database_name,
ExecPlans.objtype, ExecPlans.cacheobjtype,
  Sum(CASE WHEN ExecPlans.usecounts = 1 THEN 1 ELSE 0 END) AS Single,
  Sum(CASE WHEN ExecPlans.usecounts > 1 THEN 1 ELSE 0 END) AS Reused,
  --Sum(ExecPlans.size_in_bytes) / (1024) AS KB -- Arithmetic overflow error converting expression to data type int.
  -- https://database.guide/fix-arithmetic-overflow-error-converting-expression-to-data-type-int-in-sql-server/
  Sum(CAST(ExecPlans.size_in_bytes AS BIGINT)) / (1024) AS KB
   FROM sys.dm_exec_cached_plans AS ExecPlans
    CROSS APPLY sys.dm_exec_sql_text(ExecPlans.plan_handle) AS QueryText
   WHERE 
   --ExecPlans.cacheobjtype = 'Compiled Plan' AND 
   QueryText.dbid IS NOT NULL 
     GROUP BY --QueryText.dbid,
	objtype,
    cacheobjtype
    order by 1
    
--- rate ad hoc queries in your db
    SELECT Convert(INT,Sum
        (
        CASE a.objtype 
        WHEN 'Adhoc' 
        THEN 1 ELSE 0 END)
        * 1.00/ Count(*) * 100
              ) as 'Ad-hoc query %'
  FROM sys.dm_exec_cached_plans AS a

 --session running on adhoc plan
SELECT st.text
, sdes.login_name 
, sdes.host_name 
,sdes.program_name
,c.creation_time
,c.query_hash /*query_hash ie with similar logic, may differ by literal */, 
c.sql_handle as '/* sql_handle uniq for a batch and 1,N with plan_handle */', p.plan_handle, db_name(st.dbid) databse, 
sdec.session_id, sdec.client_net_address,sdec.local_net_address    
, a.value AS set_options, p.size_in_bytes, p.usecounts
 --, p.
FROM sys.dm_exec_cached_plans p
join sys.dm_exec_query_stats c on c.plan_handle = p.plan_handle
join sys.dm_exec_connections sdec on sdec.most_recent_sql_handle = c.sql_handle
JOIN sys.dm_exec_sessions AS sdes on sdes.session_id = sdec.session_id
cross apply sys.dm_exec_sql_text(p.plan_handle) st
cross apply sys.dm_exec_plan_attributes(c.plan_handle) a
WHERE p.objtype = 'Adhoc' 
AND  p.usecounts = 1  
AND a.attribute = 'set_options'
group by c.sql_handle, st.text, p.plan_handle, db_name(st.dbid) , sdec.session_id, sdec.client_net_address,sdec.local_net_address    ,sdes.login_name, c.query_hash
, sdes.host_name 
    ,sdes.program_name
    ,sdes.login_name, a.value , p.size_in_bytes, p.usecounts, c.creation_time
order by query_hash


SELECT st.text, memory_object_address, cp.objtype, refcounts, usecounts, 
    qs.query_plan_hash, qs.query_hash as '/* query_hash = query_plan_hash if not recompiled*/', qs.sql_handle as 'sql_handle same for a batch', qs.plan_handle,  p.query_plan
    , a.value AS set_options
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan (cp.plan_handle) p
cross apply sys.dm_exec_plan_attributes(cp.plan_handle) a
INNER JOIN sys.dm_exec_query_stats AS qs ON qs.plan_handle = cp.plan_handle
WHERE cp.objtype = 'Adhoc' AND  cp.usecounts = 1  -- text LIKE '%usp_SalesByCustomer%'
	   AND a.attribute = 'set_options'
order by qs.sql_handle, st.text
    

--Free PRoc cache
CHECKPOINT 
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
	    
DBCC FREPROCACHE; instead use
DECLARE @PlanHandle VARBINARY(64);
SELECT @PlanHandle = deps.plan_handle
FROM sys.dm_exec_procedure_stats AS deps WHERE deps.object_id = OBJECT_ID('dbo.AddressByCity');
IF @PlanHandle IS NOT NULL
BEGIN
    DBCC FREEPROCCACHE(@PlanHandle);
END

-- https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-freeproccache-transact-sql?view=sql-server-ver15
SELECT UseCounts,RefCounts, plan_handle, Cacheobjtype, Objtype, 
DB_NAME(DB_ID()) AS DatabaseName, TEXT AS SQL 
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE objtype='Proc'
ORDER BY dbid,usecounts DESC

-- Avoid DBCC FREPROCACHE; instead use
dbcc freeproccache(0x05000100EC74AB106027BD060200000001000000000000000000000000000000000000000000000000000000)
--OR
DECLARE @PlanHandle VARBINARY(64);
SELECT @PlanHandle = deps.plan_handle
FROM sys.dm_exec_procedure_stats AS deps
WHERE deps.object_id = OBJECT_ID('dbo.AddressByCity');

IF @PlanHandle IS NOT NULL
BEGIN
	DBCC FREEPROCCACHE (@PlanHandle);
END
