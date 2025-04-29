--https://learn.microsoft.com/en-us/sql/relational-databases/database-mail/database-mail-general-troubleshooting?view=sql-server-ver16#are-users-properly-configured-to-send-mail
--https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-send-dbmail-transact-sql?view=sql-server-ver16

EXEC msdb.sys.sp_helprolemember 'DatabaseMailUserRole'; ---sysadmin included by default

EXEC msdb.dbo.sysmail_help_status_sp;

EXEC msdb.dbo.sysmail_help_queue_sp @queue_type = 'mail';

EXEC msdb.dbo.sysmail_stop_sp;
EXEC msdb.dbo.sysmail_start_sp;

--mail sent
SELECT sent_account_id, sent_date,* FROM msdb.dbo.sysmail_sentitems;
SELECT * FROM msdb.dbo.sysmail_event_log;

SELECT is_broker_enabled FROM sys.databases WHERE name = 'msdb' ; -- should be 1

--send test email
EXECUTE msdb.dbo.sp_send_dbmail
    @profile_name = 'dataServicesProfile',
    @recipients = 'mbello@mih.com',
    @body = 'The stored procedure finished successfully.',
    @subject = 'Test:Automated Success Message';

--send a query result as text
EXECUTE msdb.dbo.sp_send_dbmail
    @profile_name = 'dataServicesProfile',
    @recipients = 'mbello@mih.com',
		@query = 'select top 5 [col1], [col2], [col3] from MyDB.dbo.MyTable;',
    @subject = 'Work Order Count',
    @attach_query_result_as_file = 1;


--send a HTML 
DECLARE @tableHTML NVARCHAR(MAX);
SET @tableHTML = N'<H1>Work Order Report</H1>' + N'<table border="1">'
    + N'<tr>
			<th>[col1]</th>
			<th>[col2]</th>'
    + N'	<th>[col3]</th></tr>'
    + CAST((
            SELECT TOP 5 
        td = [col1], '', -- don't overlook td= & ,'',
        td = [col2], '',
        td = [col3]
		FROM MyDB.dbo.MyTable
            FOR XML PATH('tr'), TYPE
            ) AS NVARCHAR(MAX))
    + N'</table>';

EXEC msdb.dbo.sp_send_dbmail 
    @profile_name = 'dataServicesProfile',
    @recipients = 'mbello@mih.com',
    @subject = 'Work Order List',
    @body = @tableHTML,
    @body_format = 'HTML';
