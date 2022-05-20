-- enable token replacment
-- EXEC msdb.dbo.sp_set_sqlagent_properties @alert_replace_runtime_tokens = 1


-- from 
-- http://tomaslind.net/2016/11/04/sql-agent-logging-tokens/
-- and 
-- https://www.mssqltips.com/sqlservertip/5493/automated-wmi-alerts-for-sql-server-login-property-changes/

-- create a SQL Agent job that expands all tokens available except WMI 
-- please remember to clean if you test this in ur environment
-- https://docs.microsoft.com/en-us/sql/ssms/agent/use-tokens-in-job-steps?view=sql-server-ver15
USE msdb
GO

DECLARE @jobId BINARY(16)
EXEC msdb.dbo.sp_add_job
    @job_name = 'Print Tokens Job',
    @enabled = 1,
    @job_id = @jobId OUTPUT
 
EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = 'Print tokens step',
    @step_id = 1,
    @subsystem = N'TSQL', 
    @command = N'
    PRINT ''*********Alert Tokens*********''
    PRINT ''Database name: $(ESCAPE_SQUOTE(A-DBN))''
    PRINT ''Server name: $(ESCAPE_SQUOTE(A-SVR))''
    PRINT ''Error number: $(ESCAPE_SQUOTE(A-ERR))''
    PRINT ''Error severity: $(ESCAPE_SQUOTE(A-SEV))''
    PRINT ''Error message: $(ESCAPE_SQUOTE(A-MSG))''
 
    PRINT ''*********General Tokens*********''
    --PRINT ''Agent job name: $(ESCAPE_SQUOTE(AGENT_JOB_NAME))'' --Removed in SQL 2012?
    --PRINT ''Step name: $(ESCAPE_SQUOTE(AGENT_STEP_NAME))'' --Removed in SQL 2012?
    PRINT ''Current Date: $(ESCAPE_SQUOTE(DATE))''
    PRINT ''Instance: $(ESCAPE_SQUOTE(INST))''
    PRINT ''Job Id: $(ESCAPE_SQUOTE(JOBID))''
    PRINT ''Computer name: $(ESCAPE_SQUOTE(MACH))''
    PRINT ''Master SQLServerAgent service name: $(ESCAPE_SQUOTE(MSSA))''
    PRINT ''Prefix for the program used to run CmdExec job steps: $(ESCAPE_SQUOTE(OSCMD))''
    PRINT ''SQL Server installation directory: $(ESCAPE_SQUOTE(SQLDIR))''
    PRINT ''SQL Server error log directory: $(ESCAPE_SQUOTE(SQLLOGDIR))''
    PRINT ''No times the step has executed (ex retries): $(ESCAPE_SQUOTE(STEPCT))''
    PRINT ''Step Id: $(ESCAPE_SQUOTE(STEPID))''
    PRINT ''Computer name: $(ESCAPE_SQUOTE(SRVR))''
    PRINT ''Current Time: $(ESCAPE_SQUOTE(TIME))''

    PRINT ''Source Host Name: $(ESCAPE_SQUOTE(WMI(HostName)));''
    PRINT ''Source Login Name: $(ESCAPE_SQUOTE(WMI(LoginName)));''
    PRINT ''Source Session Login Name: $(ESCAPE_SQUOTE(WMI(SessionLoginName)));''
    PRINT ''EventSubClass: $(ESCAPE_SQUOTE(WMI(EventSubClass)));''
    PRINT ''Success: $(ESCAPE_SQUOTE(WMI(Success)));''

 
    PRINT ''*********Goodbye!*********''
    ', 
    @database_name = N'tempdb',
    @output_file_name = N'$(ESCAPE_SQUOTE(SQLLOGDIR))\Print_Tokens_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt'
 
EXEC msdb.dbo.sp_add_jobserver
    @job_id = @jobId,
    @server_name = N'(local)'