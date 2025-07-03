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
-- a agent job runs it every 2min or 1 min defined how much to catch
-- Last update: 5/9/2025 - Monktar Bello: adjust the @threshold to catch query (specially blitz queries) when over 10min; no need to wait 25min the current limit to avoid noises


IF OBJECT_ID('tempdb..#temp_requests') IS NOT NULL
	DROP TABLE #temp_requests;

IF OBJECT_ID('tempdb..#temp_onehour') IS NOT NULL
	DROP TABLE #temp_onehour;

IF OBJECT_ID('tempdb..#temp_killed') IS NOT NULL
DROP TABLE #temp_killed;


declare @threshold int = 120 -- 3min - less imply more emails
declare @threshold_long_run int = 1500 --1500=25min
declare @threshold_sisense int = 2700 --sisense query 45min

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
	OtherQuery_involved VARCHAR(8000),
	Query_involved_XML xml,
	Query_Exec_plan xml

)

CREATE TABLE #temp_killed 
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
	OtherQuery_involved VARCHAR(8000),
	Query_involved_XML xml,
	Query_Exec_plan xml
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
		OtherQuery_involved,
		Query_involved_XML,
		Query_Exec_plan
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
		  ,0,8000)AS statement_text
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
	   ,0,8000)       as OtherQuery_involved,
	   --4/24/2025
case when len(ib.event_info)> 1 
	then (SELECT RmsAdmin.dbo.StripInvalidXmlChars(ib.event_info) as event_info FOR XML PATH('Query'), TYPE) else NULL end AS Query_involved_XML,
	 derp.query_plan

FROM sys.dm_exec_sessions AS s
INNER JOIN sys.dm_exec_connections AS sdec  ON sdec.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r on r.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) st
OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
LEFT JOIN cteBL as bl on s.session_id = bl.session_id
OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS derp
WHERE r.session_id != @@SPID
	--AND r.blocking_session_id <> 0 -- blocked session
	AND ( --bloking over @threshold/7
		  (
			 (len(bl.blocking_these) > 0 OR r.blocking_session_id <> 0)-- blocked or blocking
			 and 
			 (
				r.total_elapsed_time / (1000.0)  >= @threshold/2 -- 1200=25*60
				or
				DATEDIFF(second, GETDATE(), r.start_time) >= @threshold/2
			 )
		  )
	       or 
		  --running over @threshold
		(
		  r.total_elapsed_time / (1000.0)  >= @threshold--1200=25*60
		  or
		  DATEDIFF(second, GETDATE(), r.start_time) >= @threshold
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




--elect query to kill
----blitz
INSERT #temp_killed (session_id, STATUS, blocking_session_id, blocking_these, wait_type, wait_resource, WaitSec, cpu_time, logical_reads, reads, writes, ElapsSec, statement_text, command_text, 
command, login_name, host_name, program_name, host_process_id, last_request_end_time, login_time, open_transaction_count, OtherQuery_involved, Query_involved_XML, Query_Exec_plan)
SELECT session_id, STATUS, blocking_session_id, blocking_these, wait_type, wait_resource, WaitSec,
cpu_time, logical_reads, reads, writes, ElapsSec, statement_text, command_text, command, login_name, 
host_name, program_name, host_process_id, last_request_end_time,
login_time, open_transaction_count, OtherQuery_involved, Query_involved_XML, Query_Exec_plan 
FROM #temp_requests
WHERE ElapsSec >= @threshold AND command_text LIKE '%sp_Blitz%' -- 600sec=10min

----sisense
INSERT #temp_killed (session_id, STATUS, blocking_session_id, blocking_these, wait_type, wait_resource, WaitSec,
cpu_time, logical_reads, reads, writes, ElapsSec, statement_text, command_text, command, login_name, 
host_name, program_name, host_process_id, last_request_end_time,
login_time, open_transaction_count, OtherQuery_involved, Query_involved_XML, Query_Exec_plan)
select session_id, STATUS, blocking_session_id, blocking_these, wait_type, wait_resource, WaitSec,
cpu_time, logical_reads, reads, writes, ElapsSec, statement_text, command_text, command, login_name, 
host_name, program_name, host_process_id, last_request_end_time,
login_time, open_transaction_count, OtherQuery_involved, Query_involved_XML,  Query_Exec_plan  from #temp_requests  
where ElapsSec >= @threshold_sisense and login_name ='svc-sisense' and session_id > 50 and session_id <> @@SPID --2700sec=45min




-- this is because at this date 1/18/2024 mbello don't have any indication that it is used and just pop up recemtly about 2 or 3 weeks ago
--**start kill
declare @tobekilled int
declare @query varchar(20)
select top 1 @tobekilled = session_id from #temp_requests
where program_name = 'mbx-realtime-performance' and OtherQuery_involved like '--ImageQC%' and  ElapsSec > @threshold -- 1500=25min 

if @tobekilled > 0
begin
    set @query = 'kill ' + cast(@tobekilled as varchar(5))
    exec (@query)
end

if exists(select top 1 1 from #temp_killed)
begin

  DECLARE toBeKilled CURSOR LOCAL FORWARD_ONLY DYNAMIC READ_ONLY FOR
    SELECT session_id FROM #temp_killed 
    OPEN toBeKilled
    FETCH NEXT FROM toBeKilled INTO @tobekilled
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @query = 'KILL ' + CAST(@tobekilled AS char(30))
        EXEC (@query)
        FETCH NEXT FROM toBeKilled INTO @tobekilled
    END

	--send email about killed
	DECLARE @tableHTML NVARCHAR(MAX);
SET @tableHTML = N'<H1>ASP-SQL session(s) killed</H1>' + N'<table border="1">'
    + N'<tr bgcolor=#B8DBFF>
			<th>session_id</th>
			<th>Status</th>
			<th>blocking_these</th>
			<th>blocking_session_id</th>
			<th>wait_type</th>
			<th>wait_resource</th>
			<th>WaitSec</th>
			<th>cpu_time</th>
			<th>logical_reads</th>
			<th>reads</th>
			<th>writes</th>
			<th>ElapsSec</th>
			<th>statement_text</th>
			<th>OtherQuery_involved</th>
			<th>command_text</th>
			<th>command</th>
			<th>login_name</th>
			<th>host_name</th>
			<th>program_name</th>
			<th>host_process_id</th>
			<th>last_request_end_time</th>
			<th>login_time</th>
			<th>open_transaction_count</th>
			</tr>'
    + CAST((
            SELECT --TOP 5 
		td =	CONVERT(NVARCHAR(15), session_id), '',---- don't overlook td= & ,'',
		td =	isnull(blocking_these,''), '',
		td =	[status], '',
		td =	CONVERT(NVARCHAR(15), blocking_session_id), '',
		td =	isnull(wait_type,''), '',
		td =	wait_resource, '',
		td =	CONVERT(NVARCHAR(50), WaitSec), '',
		td =	CONVERT(NVARCHAR(50), cpu_time), '',
		td =	CONVERT(NVARCHAR(50), logical_reads), '',
		td =	CONVERT(NVARCHAR(50), reads), '',
		td =	CONVERT(NVARCHAR(50), writes), '',
		td =	CONVERT(NVARCHAR(50), ElapsSec), '',
		td =	substring(statement_text,0,300), '',
		td =	substring(OtherQuery_involved,0,300) , '',
		td =	command_text, '',
		td =	command, '',
		td =	login_name, '',
		td =	[host_name], '',
		td =	[program_name], '',
		td =	CONVERT(NVARCHAR(15), host_process_id), '',
		td =	last_request_end_time, '',
		td =	login_time, '',
		td =	CONVERT(NVARCHAR(256), open_transaction_count)
		FROM #temp_killed
            FOR XML PATH('tr'), TYPE
            ) AS NVARCHAR(MAX))
    + N'</table>';
       --log killed 
	   delete from RmsAdmin.dbo.temp_requests where [when] < dateadd(DD,-180,[when]) --older than 6 months
	   insert into  RmsAdmin.dbo.temp_requests
	   SELECT [session_id], [blocking_these], [status], [blocking_session_id], [wait_type], [wait_resource], [WaitSec], [cpu_time], [logical_reads], [reads], [writes], [ElapsSec],
	   [statement_text], [command_text], [command], [login_name], [host_name], [program_name], [host_process_id], [last_request_end_time], [login_time],
	   [open_transaction_count], GETDATE(), OtherQuery_involved, Query_involved_XML, Query_Exec_plan
	   FROM #temp_killed


EXEC msdb.dbo.sp_send_dbmail 
    @profile_name = 'DataServicesProfile',
    @recipients = 'db_maintenance@revmansolutions.com',
    @subject = 'ASP-SQL: Long-Running Sessions killed',
    @body = @tableHTML,
    @body_format = 'HTML';

end
--**end kill




IF 
(
	SELECT COUNT(session_id)
	FROM #temp_requests
	WHERE statement_text NOT LIKE '%PrecomputedClassify%'
) > 0
BEGIN
    -- long running query found, send email. 
    --DECLARE @tableHTML NVARCHAR(4000);
	set @tableHTML =N'';
	DECLARE @Email_Body_Title VARCHAR(250);
	DECLARE @Email_Body VARCHAR(MAX);
	DECLARE @HTML_Header VARCHAR(150);
	DECLARE @HTML_Tail VARCHAR(20);
	DECLARE @Email_Subject VARCHAR(40);
	DECLARE @Email_Subject_Timing VARCHAR(100);

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
		@statement_text VARCHAR(8000),
		@command_text VARCHAR(MAX),
		@OtherQuery_involved VARCHAR(8000),
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
			@statement_text = substring(statement_text,0,300),
			@OtherQuery_involved = substring(OtherQuery_involved,0,300) ,
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
		+ ' Long-Running Query Report</h1><br />'+ case when @tobekilled > 0 then  'session: ' + cast(@tobekilled as varchar(5))+ ' killed. ' else '' end+ '<br /></center></body>';

	SET @Email_Subject = @ServerName + ' Long-Running over an hour' 
	SET @Email_Subject_Timing = cast((@maxElaps/60) as varchar(15)) +'mins, prevent blocking or too long query '

	SET @Email_Body = @HTML_Header + @Email_Body_Title + 
		+ '<br><br>' + @tableHTML + @HTML_Tail;

-- preserve our findings
	   delete from RmsAdmin.dbo.temp_requests where [when] < dateadd(DD,-180,[when]) --older than 6 months
	   insert into  RmsAdmin.dbo.temp_requests
	   SELECT [session_id], [blocking_these], [status], [blocking_session_id], [wait_type], [wait_resource], [WaitSec], [cpu_time], [logical_reads], [reads], [writes], [ElapsSec], [statement_text],
	   [command_text], [command], [login_name], [host_name], [program_name], [host_process_id], [last_request_end_time], [login_time], [open_transaction_count], GETDATE(), 
	   OtherQuery_involved, Query_involved_XML,Query_Exec_plan 
	   FROM #temp_requests


	if len(@Email_Body) > 0
    begin 
	   --proactive measure for DBA Team 
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

