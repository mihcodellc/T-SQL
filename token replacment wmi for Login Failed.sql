
-- https://www.mssqltips.com/sqlservertip/2595/get-alerts-for-specific-sql-server-login-failed-events/
-- WMI didn't work on office computer at this date 5/20/2022

-- Audit Login Failed Event Class
--https://docs.microsoft.com/en-us/sql/relational-databases/event-classes/audit-login-failed-event-class?view=sql-server-ver15

USE [msdb];
GO

DECLARE
   @job_id BINARY(16);

EXEC msdb.dbo.sp_add_job
   @job_name = N'Bello Mail on login failed : State 5',
   @enabled = 1,
   @description = N'Send e-mail on WMI event',
   @category_name = N'[Uncategorized (Local)]',
   @owner_login_name = N'sa',
   @job_id = @job_id OUTPUT;

-- WMI exposes several tokens we can take advantage of:
DECLARE @cmd NVARCHAR(MAX) = N'DECLARE @msg NVARCHAR(MAX) = '
   + '''From job: Login failed for $(ESCAPE_SQUOTE(WMI(LoginName)))'
   + '. Full error message follows:' + CHAR(13) + CHAR(10)
   + '$(ESCAPE_SQUOTE(WMI(TextData)))'';

 EXEC msdb.dbo.sp_send_dbmail
  @recipients = ''mbello@revmansolutions.com'',
  @profile_name = ''DataServicesProfile'',
  @body = @msg,
  @subject = ''There was a login failed event '
           + 'on $(ESCAPE_SQUOTE(A-SVR)).'';';

-- msdb is used as the database for the job step; this prevents 
-- any cross-database issues with executing sp_send_dbmail.
EXEC msdb.dbo.sp_add_jobstep
   @job_id = @job_id,
   @step_name = N'Step 1 - send e-mail',
   @step_id = 1,
   @on_success_action = 1,
   @on_fail_action = 2,
   @subsystem = N'TSQL',
   @database_name = N'msdb',
   @command = @cmd;

EXEC msdb.dbo.sp_update_job
   @job_id = @job_id,
   @start_step_id = 1;

EXEC msdb.dbo.sp_add_jobserver
   @job_id = @job_id,
   @server_name = N'(local)';

DECLARE @namespace NVARCHAR(255)
   = N'\\.\root\Microsoft\SqlServer\ServerEvents\' + COALESCE
   (
       CONVERT(NVARCHAR(32), SERVERPROPERTY('InstanceName')),
       N'MSSQLSERVER'
   );

EXEC msdb.dbo.sp_add_alert
   @name = N'TestBello_Login failed : State 5',
   @enabled = 1,
   @category_name = N'[Uncategorized]',
   @wmi_namespace = @namespace,
   @wmi_query = N'SELECT * FROM AUDIT_LOGIN_FAILED WHERE State = 5',
   @job_id = @job_id;