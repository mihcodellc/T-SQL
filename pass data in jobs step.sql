
USE [msdb]
GO

/****** Object:  Job [DoProceed]    Script Date: 7/1/2022 11:01:53 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/1/2022 11:01:53 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DoProceed', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'--Created by Monktar Bello 7/1/2022
--Options to run a job based on the previous step
--inspired by https://www.mssqltips.com/sqlservertip/5731/how-to-pass-data-between-sql-server-agent-job-steps/
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'mbello', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [check period]    Script Date: 7/1/2022 11:01:54 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'check period', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @proceed nchar(2) 

set @proceed = N''No''

if DATEPART(dd, getdate()) between 1 and 4
    set @proceed = N''Yes''

raiserror (''@proceed = %s'', 10, 1, @proceed) with log;

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Proceed]    Script Date: 7/1/2022 11:01:54 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Proceed', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'set nocount on;
declare @t table (LogDate datetime, ProcessInfo varchar(100), [text] varchar(300));

insert into @t (LogDate, ProcessInfo, [Text])
exec master.sys.sp_readerrorlog 0, 1, ''proceed'';

declare @proceed nchar(2)  

select top 1 @proceed = substring([text], charindex(''@proceed = '', [text])+len(''@proceed = '')+1, 128)
from @t
order by LogDate desc;

set nocount on;
declare @t table (LogDate datetime, ProcessInfo varchar(100), [text] varchar(300));

insert into @t (LogDate, ProcessInfo, [Text])
exec master.sys.sp_readerrorlog 0, 1, ''proceed'';

declare @proceed nchar(2)  

select top 1 @proceed = substring([text], charindex(''@proceed = '', [text])+len(''@proceed = '')+1, 128)
from @t
order by LogDate desc;

if  @proceed = ''Yes''
     EXECUTE msdb..sp_send_dbmail  @Profile_Name = ''DataServicesProfile'' , @From_Address = ''NoReply@revmansolutions.com'',  @Recipients = ''mbello@rmsweb.com'',  @BODY = ''Ready to proceed ?''


', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'@ 9am', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20220701, 
		@active_end_date=99991231, 
		@active_start_time=90000, 
		@active_end_time=235959, 
		@schedule_uid=N'134abe9c-866c-4e18-94b7-85da14016141'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


