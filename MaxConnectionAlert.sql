--7/25/2025 By Monktar Bello: Initial version 
 --Run Example: exec DBA.dbo.[ups_MaxConnectionAlert]


 	---***e-mail
    DECLARE @ServerName VARCHAR(128);
    DECLARE @Email_Body VARCHAR(400);
    DECLARE @Email_subject VARCHAR(100);
	DECLARE @recipients_local VARCHAR(MAX) ;


SET NOCOUNT ON

DECLARE @conn_max INT, @conn_found INT,  @conn_found_percent float, @Threshold float = 74.99
		, @Threshold_dba_desk float = 49.99

SELECT @servername = @@SERVERNAME 
	, @conn_found = COUNT(ec.session_id)
	, @conn_max = @@MAX_CONNECTIONS 
FROM sys.dm_exec_sessions AS es WITH (NOLOCK) 
INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK) 
ON es.session_id = ec.session_id 

--debug
--SELECT @servername serv, @conn_found fnd, @conn_max maxc

set @conn_found_percent = round((@conn_found/cast(@conn_max as float))*100,2)

--select case when @conn_found_percent > @Threshold then 1 else 0 end 

-- check to see  
IF case when @conn_found_percent > @Threshold_dba_desk then 1 else 0 end = 1

	begin

	SET @recipients_local = case when @conn_found_percent < @Threshold then N'db_maintenance@mih.com'
							    else  N'dba@mih.com' end 

    SET @ServerName = CAST((SELECT SERVERPROPERTY('MachineName') AS [ServerName]) AS VARCHAR(128))
    SET @Email_subject = 'DBA: !!! Close to max connections allowed:  action needed soon !!! ' +  cast(@conn_found_percent as varchar(5)) +
						 ' % used '

    --SET @Email_subject = 'DBA: !!! TESTING: count connections on ASP: action needed soon !!! ' +  cast(@conn_found_percent as varchar(5)) +
				--		 ' % used '

    SET @Email_Body =  @ServerName + ': Count of connections ' + cast(@conn_found as varchar(5)) + ' out of '  + cast(@conn_max as varchar(5)) 

    EXEC msdb.dbo.sp_send_dbmail 
			  @body = @Email_Body
			 ,@body_format = 'TEXT'
			 ,@profile_name = N'DataServicesProfile'
			 ,@recipients = @recipients_local
			 --,@recipients = N'mbello@mih.com'
			 ,@Subject = @Email_subject
			 ,@importance = 'High' 

    end
