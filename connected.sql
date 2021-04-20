USE master;  
GO  
EXEC sp_who 'active';  
GO
SELECT 
    DB_NAME(dbid) as DBName, dbid,
    (dbid) as NumberOfConnections,
    loginame as LoginName, status
FROM
    sys.sysprocesses
--WHERE 
    --dbid =6 
GROUP BY 
    dbid, loginame, status


--==============================================================================
-- See who is connected to the database.
-- Analyse what each spid is doing, reads and writes.
-- If safe you can copy and paste the killcommand - last column.
-- Marcelo Miorelli
-- 18-july-2017 - London (UK)
-- Tested on SQL Server 2016.
--==============================================================================

SELECT
     sdes.session_id
    ,sdes.login_time
    ,sdes.last_request_start_time
    ,sdes.last_request_end_time
    ,sdes.is_user_process
    ,sdes.host_name
    ,sdes.program_name
    ,sdes.login_name
    ,sdes.status

    ,sdec.num_reads
    ,sdec.num_writes
    ,sdec.last_read
    ,sdec.last_write
    ,sdes.reads
    ,sdes.logical_reads
    ,sdes.writes

    ,sdest.DatabaseName
    ,sdest.ObjName
    ,sdes.client_interface_name
    ,sdes.nt_domain
    ,sdes.nt_user_name
    ,sdec.client_net_address
    ,sdec.local_net_address
    ,sdest.Query
	,sdest.text
    ,KillCommand  = 'Kill '+ CAST(sdes.session_id  AS VARCHAR)
FROM sys.dm_exec_sessions AS sdes

INNER JOIN sys.dm_exec_connections AS sdec
        ON sdec.session_id = sdes.session_id

CROSS APPLY (

    SELECT DB_NAME(dbid) AS DatabaseName, OBJECT_NAME(objectid) AS ObjName,
			COALESCE(
					(SELECT TEXT AS [processing-instruction(definition)] FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle) FOR XML PATH(''),TYPE), '') AS Query, 
			text

    FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle)

) sdest
WHERE sdes.session_id <> @@SPID
  AND sdest.DatabaseName ='ithinkhealth'
ORDER BY sdes.last_request_start_time DESC

select open_transaction_count, status, * FROM sys.dm_exec_sessions

--query
select q.text, st.execution_count, st.last_logical_reads, st.last_execution_time, st.last_logical_writes, last_physical_reads from sys.dm_exec_query_stats st
cross apply sys.dm_exec_sql_text(st.sql_handle) q

--sp
select q.text, st.execution_count, st.last_logical_reads, st.last_execution_time, st.last_logical_writes, last_physical_reads from sys.dm_exec_procedure_stats st
cross apply sys.dm_exec_sql_text (st.sql_handle) q

--sp
select q.query_plan, st.execution_count, st.last_logical_reads, st.last_execution_time, st.last_logical_writes, last_physical_reads from sys.dm_exec_procedure_stats st
cross apply sys.dm_exec_query_plan(st.sql_handle) q

exec sp_who 'active';  
-- active
 select spid , ecid, status  
              ,loginame=rtrim(loginame)  
       ,hostname ,blk=convert(char(5),blocked)  
       ,dbname = case  
      when dbid = 0 then null  
      when dbid <> 0 then db_name(dbid)  
     end  
    ,cmd  
    ,request_id  
 from  sys.sysprocesses  
 where upper(cmd) <> 'AWAITING COMMAND' -- ACTIVE excludes sessions that are waiting for the next command from the user.
 and spid  <> @@SPID
 order by status

dbcc opentran

SELECT conn.session_id, sess.host_name, sess.program_name,
    sess.nt_domain, sess.login_name, conn.connect_time, sess.last_request_end_time 
FROM sys.dm_exec_sessions AS sess
JOIN sys.dm_exec_connections AS conn
   ON sess.session_id = conn.session_id;

 select * from sys.dm_exec_connections


 --set transaction isolation level read uncommitted

--find lock esclation on a table

SELECT CASE WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id) else OBJECT_NAME(b.OBJECT_ID) end ObjectName, 
resource_type, request_mode, resource_description, request_session_id, partition_id, request_status, request_type 
--into #mylock
FROM sys.dm_tran_locks a
LEFT JOIN sys.partitions b ON b.hobt_id = a.resource_associated_entity_id
WHERE resource_type <> 'DATABASE' AND resource_database_id = DB_ID()