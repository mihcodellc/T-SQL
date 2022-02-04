-- 3 tables: requiring locks, session/query of blocker if any, sp_WhoIsActive, not sleeping

--Query to return active locks and the duration of the locks being held
-- on main databases
SELECT  Locks.request_session_id AS SessionID ,
        Obj.Name AS LockedObjectName ,
        DATEDIFF(second, ActTra.Transaction_begin_time, GETDATE()) AS Duration ,
        ActTra.Transaction_begin_time ,
        COUNT(*) AS Locks, ExeSess.host_name, ExeSess.program_name
FROM    sys.dm_tran_locks Locks
        JOIN sys.partitions Parti ON Parti.hobt_id = Locks.resource_associated_entity_id
        JOIN sys.objects Obj ON Obj.object_id = Parti.object_id
        JOIN sys.dm_exec_sessions ExeSess ON ExeSess.session_id = Locks.request_session_id
        JOIN sys.dm_tran_session_transactions TranSess ON ExeSess.session_id = TranSess.session_id
        JOIN sys.dm_tran_active_transactions ActTra ON TranSess.transaction_id = ActTra.transaction_id
WHERE   db_name(resource_database_id) in ('MedRx', 'RMSOCR')--resource_database_id = DB_ID()
        AND Obj.Type = 'U'
GROUP BY ActTra.Transaction_begin_time ,
        Locks.request_session_id ,
        Obj.Name, ExeSess.host_name, ExeSess.program_name

 --sessions blocking other, active queries & sql text
; WITH cteBL (session_id, blocking_these) AS 
(SELECT s.session_id, blocking_these = x.blocking_these FROM sys.dm_exec_sessions s 
CROSS APPLY    (SELECT isnull(convert(varchar(6), er.session_id),'') + ', '  
                FROM sys.dm_exec_requests as er
                WHERE er.blocking_session_id = isnull(s.session_id ,0)
                AND er.blocking_session_id <> 0
                FOR XML PATH('') ) AS x (blocking_these)
)
SELECT s.session_id, blocked_by = r.blocking_session_id, bl.blocking_these
, batch_text = t.text, input_buffer = ib.event_info, s.host_name, db_name(s.database_id) dbName
FROM sys.dm_exec_sessions s 
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
INNER JOIN cteBL as bl on s.session_id = bl.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
--WHERE blocking_these is not null or r.blocking_session_id > 0
where s.status <> 'sleeping' and s.session_id <> @@SPID
ORDER BY len(bl.blocking_these) desc, r.blocking_session_id desc, r.session_id;

-- sp_WhoIsActive pay attention to the order paramter
exec [RmsAdmin].dbo.sp_WhoIsActive  
		    @show_own_spid = 0
		  , @get_task_info =2 /*task-based metrics*/
		  , @get_avg_time = 1
		  , @get_locks = 1
		  --, @get_transaction_info = 1
		  --, @delta_interval = 0
		  , @find_block_leaders =1
		  , @show_sleeping_spids = 0 --1 sleeping with open transaction
		  --, @get_plans = 1 
		  , @sort_order = '[blocked_session_count] desc, [Used_Memory] desc, [open_tran_count] desc, [CPU] desc' 
		  --, @destination_table = ''
		  --, @output_column_list = '[col1][col2]...'


--==============================================================================
-- See who is connected to the database.
-- Analyse what each spid is doing, reads and writes.
-- If safe you can copy and paste the killcommand - last column.
-- Marcelo Miorelli
-- 18-july-2017 - London (UK)
-- Tested on SQL Server 2016.
-- Monktar Bello's comment from here 
-- it run on current database; remove this part if looking for all dbs
-- I exclude status = SLEEPING
-- Complement exec sp_WhoIsActive
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

    SELECT DB_NAME(dbid) AS DatabaseName, OBJECT_NAME(objectid) AS ObjName, dbid ,
			COALESCE(
										(SELECT TEXT AS [processing-instruction(definition)] FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle) FOR XML PATH('')), '') AS Query, 
			text

    FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle)

) sdest
WHERE sdes.session_id <> @@SPID
  AND sdest.DatabaseName = db_name() and status not in ('sleeping')-- and sdest.dbid IS NOT NULL
ORDER BY status DESC
