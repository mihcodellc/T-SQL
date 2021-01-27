  SELECT create_date 'Server restarted since' FROM sys.databases WHERE name = 'tempdb';

--execution
  select top 50 'execution' lookat, OBJECT_NAME(st.objectid) objectname, sum(execution_count)executioncount, 
sum(total_elapsed_time)duration,(sum(total_elapsed_time)/sum(execution_count)/1000) InMillisecond, 
sum(total_worker_time) CPU, sum(total_logical_reads) reads, sum(total_logical_writes) writes, qs.last_rows, row_number() over (PARTITION BY 1 ORDER BY sum(execution_count) DESC ) objRank
--,st.text, qs.plan_handle,(sum(total_elapsed_time)/sum(execution_count)/1000000) InSecond 
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = DB_NAME()
group by qs.plan_handle, st.text, st.objectid, qs.last_rows
order by executioncount desc, objectname

--duration
 select top 50 'duration' lookat, OBJECT_NAME(st.objectid) objectname, sum(execution_count)executioncount, 
sum(total_elapsed_time)duration,(sum(total_elapsed_time)/sum(execution_count)/1000) InMillisecond, 
sum(total_worker_time) CPU, sum(total_logical_reads) reads, sum(total_logical_writes) writes, qs.last_rows, row_number() over (PARTITION BY 1 ORDER BY sum(total_elapsed_time) DESC ) objRank
--,st.text, qs.plan_handle,(sum(total_elapsed_time)/sum(execution_count)/1000000) InSecond
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = DB_NAME()
group by qs.plan_handle, st.text, st.objectid, qs.last_rows
order by duration desc, objectname

--read 
 select top 50  'reads' lookat, OBJECT_NAME(st.objectid) objectname, sum(execution_count)executioncount, 
sum(total_elapsed_time)duration,(sum(total_elapsed_time)/sum(execution_count)/1000) InMillisecond, 
sum(total_worker_time) CPU, sum(total_logical_reads) reads, sum(total_logical_writes) writes, qs.last_rows, row_number() over (PARTITION BY 1 ORDER BY sum(total_logical_reads) DESC ) objRank
--,st.text, qs.plan_handle,(sum(total_elapsed_time)/sum(execution_count)/1000000) InSecond
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = DB_NAME()
group by qs.plan_handle, st.text, st.objectid, qs.last_rows
order by reads desc, objectname


--read 
 select top 50 'writes' lookat, OBJECT_NAME(st.objectid) objectname, sum(execution_count)executioncount, 
sum(total_elapsed_time)duration,(sum(total_elapsed_time)/sum(execution_count)/1000) InMillisecond, 
sum(total_worker_time) CPU, sum(total_logical_reads) reads, sum(total_logical_writes) writes, qs.last_rows, row_number() over (PARTITION BY 1 ORDER BY sum(total_logical_writes) DESC ) objRank
--,st.text, qs.plan_handle,(sum(total_elapsed_time)/sum(execution_count)/1000000) InSecond
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = DB_NAME()
group by qs.plan_handle, st.text, st.objectid, qs.last_rows
order by writes desc, objectname

