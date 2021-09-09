-- code error Timeout expired. The timeout period elapsed 
-- prior to obtaining a connection from the pool. This may have occurred because all pooled connections were in use and max pool size was reached.
-- https://sqlperformance.com/2017/07/sql-performance/find-database-connection-leaks

-- session by host
select count(*) as sessions,
         s.host_name,
         s.host_process_id,
         s.program_name,
         db_name(s.database_id) as database_name
   from sys.dm_exec_sessions s
   where is_user_process = 1 and host_name = 'DEVELOPER15'
   group by host_name, host_process_id, program_name, database_id
   order by count(*) desc;

-- sleeping session can be an issue, check the query used and closed them, of no longer needed close or kill it
-- there are using the TempDB
  select datediff(minute, s.last_request_end_time, getdate()) as minutes_asleep,
         s.session_id,
         db_name(s.database_id) as database_name,
         s.host_name,
         s.host_process_id,
         t.text as last_sql,
         s.program_name
    from sys.dm_exec_connections c
    join sys.dm_exec_sessions s
         on c.session_id = s.session_id
   cross apply sys.dm_exec_sql_text(c.most_recent_sql_handle) t
   where s.is_user_process = 1
         and s.status = 'sleeping'

-- maximum number of simultaneous user connections allowed
SELECT @@MAX_CONNECTIONS AS 'Max Connections';  

USE master;  
GO  
EXEC sp_who 'active';  
GO
SELECT 
    DB_NAME(dbid) as DBName, dbid,
    (dbid) as NumberOfConnections,
    loginame as LoginName, status
FROM  sys.sysprocesses
--WHERE 
    --dbid =6 
GROUP BY dbid, loginame, status




--Query to return active locks and the duration of the locks being held
SELECT  Locks.request_session_id AS SessionID ,
        Obj.Name AS LockedObjectName ,
        DATEDIFF(second, ActTra.Transaction_begin_time, GETDATE()) AS Duration ,
        ActTra.Transaction_begin_time ,
        COUNT(*) AS Locks
FROM    sys.dm_tran_locks Locks
        JOIN sys.partitions Parti ON Parti.hobt_id = Locks.resource_associated_entity_id
        JOIN sys.objects Obj ON Obj.object_id = Parti.object_id
        JOIN sys.dm_exec_sessions ExeSess ON ExeSess.session_id = Locks.request_session_id
        JOIN sys.dm_tran_session_transactions TranSess ON ExeSess.session_id = TranSess.session_id
        JOIN sys.dm_tran_active_transactions ActTra ON TranSess.transaction_id = ActTra.transaction_id
WHERE   resource_database_id = DB_ID()
        AND Obj.Type = 'U'
GROUP BY ActTra.Transaction_begin_time ,
        Locks.request_session_id ,
        Obj.Name


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
    ,KillCommand  = 'Kill '+ CAST(sdes.session_id  AS VARCHAR) + ' WITH STATUSONLY ' --WITH STATUSONLY clause provides progress reports, the time remaining until the blocking is resolved
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
 
 --sessions blocking other, active queries & sql text
 WITH cteBL (session_id, blocking_these) AS 
(SELECT s.session_id, blocking_these = x.blocking_these FROM sys.dm_exec_sessions s 
CROSS APPLY    (SELECT isnull(convert(varchar(6), er.session_id),'') + ', '  
                FROM sys.dm_exec_requests as er
                WHERE er.blocking_session_id = isnull(s.session_id ,0)
                AND er.blocking_session_id <> 0
                FOR XML PATH('') ) AS x (blocking_these)
)
SELECT s.session_id, blocked_by = r.blocking_session_id, bl.blocking_these
, batch_text = t.text, input_buffer = ib.event_info, * 
FROM sys.dm_exec_sessions s 
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
INNER JOIN cteBL as bl on s.session_id = bl.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
WHERE blocking_these is not null or r.blocking_session_id > 0
ORDER BY len(bl.blocking_these) desc, r.blocking_session_id desc, r.session_id;

 --open transaction
dbcc opentran

-- connection and session info
SELECT conn.session_id, sess.host_name, sess.program_name,
    sess.nt_domain, sess.login_name, conn.connect_time, sess.last_request_end_time 
FROM sys.dm_exec_sessions AS sess
JOIN sys.dm_exec_connections AS conn
   ON sess.session_id = conn.session_id;

 select * from sys.dm_exec_connections

 --last statement that was submitted by a session
    DBCC INPUTBUFFER(<session_id>)
    --OR
    SELECT * FROM sys.dm_exec_input_buffer (66,0);


select open_transaction_count, status, * FROM sys.dm_exec_sessions


 --set transaction isolation level read uncommitted

--find lock esclation on a table 
SELECT CASE WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id) else OBJECT_NAME(b.OBJECT_ID) end ObjectName, 
resource_type, request_mode, resource_description, request_session_id, partition_id, request_status, request_type 
--into #mylock
FROM sys.dm_tran_locks a
LEFT JOIN sys.partitions b ON b.hobt_id = a.resource_associated_entity_id
WHERE resource_type <> 'DATABASE' AND resource_database_id = DB_ID() -- and request_session_id = @@spid;

--Determine Which Queries Are Holding Locks using extend events
--https://docs.microsoft.com/en-us/sql/relational-databases/extended-events/determine-which-queries-are-holding-locks?view=sql-server-ver15