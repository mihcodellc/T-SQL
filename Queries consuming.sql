  --!!!!!! last_rows not avilble on DEV 2005
  SELECT create_date 'Server restarted since' FROM sys.databases WHERE name = 'tempdb';

with cteConsuming as (
--execution
  select top 50 'execution' lookat, OBJECT_NAME(st.objectid) objectname, sum(execution_count)executioncount, 
sum(total_elapsed_time)duration,(sum(total_elapsed_time)/sum(execution_count)/1000) InMillisecond, 
sum(total_worker_time) CPU, sum(total_logical_reads) reads, sum(total_logical_writes) writes, row_number() over (ORDER BY sum(execution_count) DESC ) objRank
--,st.text, qs.plan_handle,(sum(total_elapsed_time)/sum(execution_count)/1000000) InSecond 
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = DB_NAME()
group by  st.objectid--, qs.last_rows
--order by executioncount desc

UNION

--duration
 select top 50 'duration' lookat, OBJECT_NAME(st.objectid) objectname, sum(execution_count)executioncount, 
sum(total_elapsed_time)duration,(sum(total_elapsed_time)/sum(execution_count)/1000) InMillisecond, 
sum(total_worker_time) CPU, sum(total_logical_reads) reads, sum(total_logical_writes) writes, row_number() over (ORDER BY sum(total_elapsed_time) DESC ) objRank
--,qs.plan_handle--, qs.plan_handle,(sum(total_elapsed_time)/sum(execution_count)/1000000) InSecond
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = DB_NAME()
group by  st.objectid--, qs.last_rows
--order by  duration desc

UNION

--read 
 select top 50  'reads' lookat, OBJECT_NAME(st.objectid) objectname, sum(execution_count)executioncount, 
sum(total_elapsed_time)duration,(sum(total_elapsed_time)/sum(execution_count)/1000) InMillisecond, 
sum(total_worker_time) CPU, sum(total_logical_reads) reads, sum(total_logical_writes) writes,  row_number() over ( ORDER BY sum(total_logical_reads) DESC ) objRank
--,st.text, qs.plan_handle,(sum(total_elapsed_time)/sum(execution_count)/1000000) InSecond
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = DB_NAME()
group by  st.objectid--, qs.last_rows
--order by reads desc

UNION

--read 
 select top 50 'writes' lookat, OBJECT_NAME(st.objectid) objectname, sum(execution_count)executioncount, 
sum(total_elapsed_time)duration,(sum(total_elapsed_time)/sum(execution_count)/1000) InMillisecond, 
sum(total_worker_time) CPU, sum(total_logical_reads) reads, sum(total_logical_writes) writes, row_number() over (ORDER BY sum(total_logical_writes) DESC ) objRank
--,st.text, qs.plan_handle,(sum(total_elapsed_time)/sum(execution_count)/1000000) InSecond
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = DB_NAME()
group by  st.objectid--, qs.last_rows
--order by writes desc--, objectname
)

select *, 'hope' DB from cteConsuming
where objRank < 31
ORDER BY objectname

--REAL TIME REFER TO CONNECTED.SQL