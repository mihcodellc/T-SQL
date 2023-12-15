USE [DBA_DB]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create    PROCEDURE [dbo].[LongRunningQueryAlert_DBA]
AS
BEGIN
SET NOCOUNT ON

-- Last update: 11/28/2023 - Monktar Bello: move from 20 min to 25 min for emails 


IF OBJECT_ID('tempdb..#temp_requests') IS NOT NULL
	DROP TABLE #temp_requests;

IF OBJECT_ID('tempdb..#temp_onehour') IS NOT NULL
	DROP TABLE #temp_onehour;


CREATE TABLE #temp_requests 
(
	ID INT IDENTITY(1,1),
	session_id SMALLINT,
     blocking_these NVARCHAR(500),
	[status] NVARCHAR(30),
	blocking_session_id SMALLINT,
	wait_type NVARCHAR(60),
	wait_resource NVARCHAR(256),
	WaitSec INT,
	cpu_time INT,
	logical_reads BIGINT,
	reads BIGINT,
	writes BIGINT,
	ElapsSec INT,
	statement_text VARCHAR(MAX),
	command_text VARCHAR(MAX),
	command NVARCHAR(32),
	login_name NVARCHAR(128),
	[host_name] NVARCHAR(128),
	[program_name] NVARCHAR(128),
	host_process_id INT,
	last_request_end_time DATETIME,
	login_time DATETIME,
	open_transaction_count INT,
	OtherQuery_involved VARCHAR(MAX)
)

-- Check for long-running queries and blocking in current requests
-- Put results to temp table
;WITH cteBL (session_id, blocking_these) AS 
(SELECT s.session_id, blocking_these = x.blocking_these FROM sys.dm_exec_sessions s 
CROSS APPLY    (SELECT isnull(convert(varchar(6), er.session_id),'') + ', '  
                FROM sys.dm_exec_requests as er
                WHERE er.blocking_session_id = isnull(s.session_id ,0)
                AND er.blocking_session_id <> 0
                FOR XML PATH('') ) AS x (blocking_these)
)
INSERT #temp_requests
        ( session_id ,
          status ,
          blocking_session_id /*blocked_by*/,
		blocking_these,
          wait_type ,
          wait_resource ,
          WaitSec ,
          cpu_time ,
          logical_reads ,
          reads ,
          writes ,
          ElapsSec ,
          statement_text ,
          command_text ,
          command ,
          login_name ,
          host_name ,
          program_name ,
          host_process_id ,
          last_request_end_time ,
          login_time ,
          open_transaction_count,
		OtherQuery_involved
        )
SELECT top 20 s.session_id
    ,r.[status]
    ,r.blocking_session_id
    ,bl.blocking_these
    ,r.wait_type
    ,r.wait_resource
    ,r.wait_time / (1000.0) AS 'WaitSec'
    ,r.cpu_time
    ,r.logical_reads
    ,r.reads
    ,r.writes
    ,r.total_elapsed_time / (1000.0) 'ElapsSec' -- Request not session
    ,substring(
    SUBSTRING(st.TEXT, (r.statement_start_offset / 2) + 1, (
            (
                CASE r.statement_end_offset
                    WHEN - 1
                        THEN DATALENGTH(st.TEXT)
                    ELSE r.statement_end_offset
                    END - r.statement_start_offset
                ) / 2
            ) + 1)
		  ,0,300)AS statement_text
    ,COALESCE(QUOTENAME(DB_NAME(st.dbid)) + N'.' + 
		QUOTENAME(OBJECT_SCHEMA_NAme(st.objectid, st.dbid)) + N'.' + 
		QUOTENAME(OBJECT_NAME(st.objectid, st.dbid)), '') AS command_text
    ,r.command
    ,s.login_name
    ,s.[host_name]
    ,s.[program_name]
    ,s.host_process_id
    ,s.last_request_end_time
    ,s.login_time
    ,r.open_transaction_count
    ,substring(
    case when len(ib.event_info)> 0 then ib.event_info else '' end
	   ,0,300)       as OtherQuery_involved
FROM sys.dm_exec_sessions AS s
INNER JOIN sys.dm_exec_connections AS sdec  ON sdec.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r on r.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) st
OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
LEFT JOIN cteBL as bl on s.session_id = bl.session_id
WHERE r.session_id != @@SPID
	--AND r.blocking_session_id <> 0 -- blocked session
	AND ( --bloking over 3min
		  (
			 (len(bl.blocking_these) > 0 OR r.blocking_session_id <> 0)-- blocked or blocking
			 and 
			 (
				r.total_elapsed_time / (1000.0)  > 1500 -- 1200=25*60
				or
				DATEDIFF(second, GETDATE(), r.start_time) > 1500
			 )
		  )
	       or 
		  --running over 20min
		(
		  r.total_elapsed_time / (1000.0)  > 1500--1200=25*60
		  or
		  DATEDIFF(second, GETDATE(), r.start_time) > 1500
		)  
	   )
ORDER BY ElapsSec desc, r.cpu_time DESC
    ,r.[status]
    ,r.blocking_session_id
    ,s.session_id

----debug 
--SELECT top 20 *
--	FROM #temp_requests

declare @maxElaps Bigint, @minElaps Bigint

--get the min and max of top 20
select @maxElaps= max(ElapsSec), @minElaps = min(ElapsSec) from #temp_requests

select * into #temp_onehour from #temp_requests
where ElapsSec > 3600 -- one hour

IF 
(
	SELECT COUNT(session_id)
	FROM #temp_requests
	WHERE statement_text NOT LIKE '%PrecomputedClassify%'
) > 0
BEGIN
    -- long running query found, send email. 
    DECLARE @tableHTML NVARCHAR(4000);
	DECLARE @Email_Body_Title VARCHAR(250);
	DECLARE @Email_Body VARCHAR(MAX);
	DECLARE @HTML_Header VARCHAR(150);
	DECLARE @HTML_Tail VARCHAR(20);
	DECLARE @Email_Subject VARCHAR(40);
	DECLARE @Email_Subject_Timing VARCHAR(40);

	DECLARE @ServerName VARCHAR(25);
	DECLARE @Row_Color VARCHAR(10);

	DECLARE @session_id NVARCHAR(15),
		@status NVARCHAR(30),
		@blocking_session_id NVARCHAR(15),
		@wait_type NVARCHAR(60),
		@wait_resource NVARCHAR(256),
		@WaitSec NVARCHAR(MAX),
		@cpu_time NVARCHAR(MAX),
		@logical_reads NVARCHAR(MAX),
		@reads NVARCHAR(MAX),
		@writes NVARCHAR(MAX),
		@ElapsSec NVARCHAR(MAX),
		@statement_text VARCHAR(MAX),
		@command_text VARCHAR(MAX),
		@OtherQuery_involved VARCHAR(MAX),
		@command NVARCHAR(32),
		@login_name NVARCHAR(128),
		@host_name NVARCHAR(128),
		@program_name NVARCHAR(128),
		@host_process_id NVARCHAR(15),
		@last_request_end_time VARCHAR(40),
		@login_time VARCHAR(40),
		@open_transaction_count NVARCHAR(256),
		@blocking_these NVARCHAR(128)

	DECLARE @ID INT
	DECLARE @MAX INT

	SET @tableHTML = '<body><table cellspacing=0><tr bgcolor=#B8DBFF><td>session_id</td><td>blocking_these_session</td>' + 
						 '<td>Status</td><td>blocking_session_id</td><td>wait_type</td><td>wait_resource</td>' + 
						 '<td>WaitSec</td>' + N'<td>cpu_time</td><td>logical_reads</td><td>reads</td>' +
						 '<td>writes</td><td>ElapsSec</td><td>statement_text</td><td>command_text</td><td>OtherQuery_involved</td>' + 
						 '<td>command</td><td>login_name</td><td>host_name</td><td>program_name</td>' + 
						 '<td>host_process_id</td><td>last_request_end_time</td><td>login_time</td>' + 
						 '<td>open_transaction_count</td></tr>'


	SELECT @MAX = MAX(ID) FROM #temp_requests 

	--select @MAX --debug


	SET @ID=1

	WHILE @ID <= @MAX
	BEGIN
		  
		SELECT 
			@session_id = CONVERT(NVARCHAR(15), session_id),
			@blocking_these = isnull(blocking_these,''),
			@status = [status],
			@blocking_session_id = CONVERT(NVARCHAR(15), blocking_session_id),
			@wait_type = isnull(wait_type,''),
			@wait_resource = wait_resource,
			@WaitSec = CONVERT(NVARCHAR(50), WaitSec),
			@cpu_time = CONVERT(NVARCHAR(50), cpu_time),
			@logical_reads = CONVERT(NVARCHAR(50), logical_reads),
			@reads = CONVERT(NVARCHAR(50), reads),
			@writes = CONVERT(NVARCHAR(50), writes),
			@ElapsSec = CONVERT(NVARCHAR(50), ElapsSec),
			@statement_text = statement_text, --substring(statement_text,0,10),
			@OtherQuery_involved = OtherQuery_involved, --substring(OtherQuery_involved,0,10) ,
			@command_text = command_text,
			@command = command,
			@login_name = login_name,
			@host_name = [host_name],
			@program_name = [program_name],
			@host_process_id = CONVERT(NVARCHAR(15), host_process_id),
			@last_request_end_time = last_request_end_time,
			@login_time = login_time,
			@open_transaction_count = CONVERT(NVARCHAR(256), open_transaction_count)
		FROM #temp_requests WHERE @ID = ID

		IF @ID % 2 = 0
			BEGIN
				SET @Row_Color = 'BDBDC2'
			END
		ELSE
			SET @Row_Color = 'White'

		
	     SET @tableHTML = @tableHTML+ '
		<tr bgcolor='+@Row_Color+'><td>'+@session_id+'</td><td>'+@blocking_these+'</td><td>'+@status+'</td><td>'+@blocking_session_id+'</td>		
		<td>'+@wait_type+'</td><td>'+@wait_resource+'</td><td>'+@WaitSec+'</td><td>'+@cpu_time+'</td><td>'+@logical_reads+'</td><td>'+@reads+'</td>
		<td>'+@writes+'</td><td>'+@ElapsSec+'</td><td>'+@statement_text+'</td><td>'+@command_text+'</td><td>'+@OtherQuery_involved+'</td><td>'+@command+'</td><td>'+@login_name+'</td>
		<td>'+@host_name+'</td><td>'+@program_name+'</td><td>'+@host_process_id+'</td><td>'+@last_request_end_time+'</td><td>'+@login_time+'</td>
		<td>'+@open_transaction_count+'</td></tr>'

  		SET @ID = @ID + 1
	END

	--select len(@tableHTML) as tableDebug

	SET @tableHTML = @tableHTML + '</table><br><br>'

	SET @ServerName = CAST((SELECT SERVERPROPERTY('MachineName') AS [ServerName]) AS VARCHAR(25))

	SET @HTML_Header = '<html><head>' + '<style>'
		+ 'td {border: solid black 1px;padding-left:3px;padding-right:3px;padding-top:2px;padding-bottom:2px;font-size:10pt;} '
		+ '</style>' + '</head>';
	
	SET @HTML_Tail = '</body></html>';

	SET @Email_Body_Title = '<body><center><h1>' + @ServerName
		+ ' Long-Running Query Report</h1></center></body>';

	SET @Email_Subject = @ServerName + ' Long-Running over an hour';
	SET @Email_Subject_Timing = cast((@maxElaps/60) as varchar(15)) +'mins, prevent blocking or too long query '

	SET @Email_Body = @HTML_Header + @Email_Body_Title + 
		+ '<br><br>' + @tableHTML + @HTML_Tail;

-- preserve our findings
	   insert into  DBA_DB.dbo.temp_requests
	   SELECT [session_id], [blocking_these], [status], [blocking_session_id], [wait_type], [wait_resource], [WaitSec], [cpu_time], [logical_reads], [reads], [writes], [ElapsSec], [statement_text], [command_text], [command], [login_name], [host_name], [program_name], [host_process_id], [last_request_end_time], [login_time], [open_transaction_count], GETDATE(), OtherQuery_involved
	   FROM #temp_requests

    if len(@Email_Body) > 0
    begin 
	   --proactive measure for mbello 
	   EXEC msdb.dbo.sp_send_dbmail 
		   @body = @Email_Body
		  ,@body_format = 'HTML'
		  ,@profile_name = N'MyProfile'
		  ,@recipients = N'mbello@mih.com' 
		  ,@Subject = @Email_Subject_Timing
		    ,@importance = 'High'
    end
    if len(@Email_Body) > 0 and (select count(1) from #temp_onehour) > 0 --DBA group get informed
    begin 
	   --select len(@Email_Body) as bodydebug --debug
	   EXEC msdb.dbo.sp_send_dbmail 
		    @body = @Email_Body
		  ,@body_format = 'HTML'
		  ,@profile_name = N'MyProfile'
		  ,@recipients = N'db_maintenance@mih.com' -- N'db_maintenance@revmansolutions.com'
		  ,@Subject = @Email_Subject
		    ,@importance = 'High'
    end
END


DROP TABLE #temp_requests


END

