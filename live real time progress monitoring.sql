-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-profiles-transact-sql?view=sql-server-ver15

-- run with before the query
SET STATISTICS PROFILE ON;  
GO  

-- run in other session

SELECT node_id,physical_operator_name, SUM(row_count) row_count, 
  SUM(estimate_row_count) AS estimate_row_count, 
  CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count)  
FROM sys.dm_exec_query_profiles   
WHERE session_id=1508
GROUP BY node_id,physical_operator_name  
ORDER BY node_id; 


SELECT session_id,
sp.cmd,
sp.hostname,
db.name,
sp.last_batch,
node_id,
physical_operator_name,
SUM(row_count) row_count,
SUM(estimate_row_count) AS estimate_row_count,
CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count) as EST_COMPLETE_PERCENT
FROM sys.dm_exec_query_profiles eqp
join sys.sysprocesses sp on sp.spid=eqp.session_id
join sys.databases db on db.database_id=sp.dbid
-- WHERE session_id in (select spid from sys.sysprocesses sp where sp.cmd like '%INDEX%') -- --select distinct cmd  from sys.sysprocesses order by cmd
WHERE session_id=1508
GROUP BY session_id, node_id, physical_operator_name, sp.cmd, sp.hostname, db.name, sp.last_batch
ORDER BY session_id, node_id desc;


-- other way of progress from dm_exec_requests
SELECT session_id AS SPID
	,command
	,a.TEXT AS Query
	,start_time
	,percent_complete
	,dateadd(second, estimated_completion_time / 1000, getdate()) AS estimated_completion_time
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
WHERE r.command IN ( -- /* SELECT distinct r.command FROM sys.dm_exec_requests r  */
		'BACKUP DATABASE'
		,'RESTORE DATABASE'
		,'BACKUP LOG'
		)

-- seems to track in auto running jobs. need to confirm
-- for sure for these
--ALTER INDEX REORGANIZE
--AUTO_SHRINK option with ALTER DATABASE
--BACKUP DATABASE
--DBCC CHECKDB
--DBCC CHECKFILEGROUP
--DBCC CHECKTABLE
--DBCC INDEXDEFRAG
--DBCC SHRINKDATABASE
--DBCC SHRINKFILE
--RECOVERY
--RESTORE DATABASE
--ROLLBACK
--TDE ENCRYPTION
SELECT session_id AS SPID
	,command
	,a.TEXT AS Query
	,start_time
	,percent_complete
	,dateadd(second, estimated_completion_time / 1000, getdate()) AS estimated_completion_time, r.reads, r.writes, r.logical_reads, r.cpu_time, r.blocking_session_id, total_elapsed_time, is_resumable
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
order by command		
