--indexes non used
select a.name as tablename , b.name as indexname
from sys.indexes b inner join
sys.dm_db_index_usage_stats s
on s.object_id=b.object_id and s.index_id=b.index_id
inner join sys.tables a on b.object_id=a.object_id
where ((user_seeks=0 and user_scans=0 and user_lookups=0) or s.object_id is null) 

--use by session
select * from sys.dm_exec_sessions

--
select * from Sys.dm_exec_connections


--memory used by process
SELECT SUM (pages_in_bytes) as 'Bytes Used', type
FROM sys.dm_os_memory_objects
GROUP BY type 
ORDER BY 'Bytes Used' DESC;

