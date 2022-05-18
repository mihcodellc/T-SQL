--your execution plan attributes to know which settings is used by your execution plan
--this is beside comparing the graph in ssms


--https://www.mssqltips.com/sqlservertip/4318/sql-server-stored-procedure-runs-fast-in-ssms-and-slow-in-application/


--get the plan_handle for next query
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

-- session running on adhoc plan
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
WHERE p.objtype = 'Adhoc' AND  p.usecounts = 1  AND a.attribute = 'set_options'
group by c.sql_handle, st.text, p.plan_handle, db_name(st.dbid) , sdec.session_id, sdec.client_net_address,sdec.local_net_address    ,sdes.login_name
, sdes.host_name 
    ,sdes.program_name
    ,sdes.login_name, a.value , p.size_in_bytes, p.usecounts


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
-- https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-freeproccache-transact-sql?view=sql-server-ver15
SELECT UseCounts,RefCounts, plan_handle, Cacheobjtype, Objtype, 
DB_NAME(DB_ID()) AS DatabaseName, TEXT AS SQL 
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE objtype='Proc'
ORDER BY dbid,usecounts DESC

dbcc freeproccache(0x05000100EC74AB106027BD060200000001000000000000000000000000000000000000000000000000000000)
