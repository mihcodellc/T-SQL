--  fail jobs based on scheduled period covering all your current jobs
--must worry when table 2 is not empty



--1 
  declare @date1 int, @date2 int;
    set @date1 = convert(int,replace(convert(CHAR(10), GETDATE(), 112),'-','')) --20220316
    set @date2 = convert(int,replace(convert(CHAR(10), dateadd(dd,-7,GETDATE()), 112),'-','')) --20220316

    select @date2 'start date', @date1 'end date'
 SELECT job.name, his.step_name, his.run_status , his.run_time, his.run_date,
			CASE WHEN his.run_status = 1 THEN 'Success'  
		     WHEN his.run_status = 0 THEN 'Failure'
			WHEN his.run_status = 2 THEN 'Retried'
			WHEN his.run_status = 3 THEN 'Cancelled'
			WHEN his.run_status = 4 THEN 'Check its steps'
			ELSE 'Unknown' END   AS outcome_message,  
			his.run_duration as 'Duration HHMMSS', his.[message],
 his.sql_severity, his.retries_attempted, job.job_id 
	    , job.notify_email_operator_id,  his.[server]
  FROM [msdb].[dbo].[sysjobhistory] as his
  JOIN [msdb].[dbo].[sysjobs] as job on job.job_id = his.job_id
  WHERE run_date between @date2  and  @date1
  AND run_status IN (0/*FAILED*/,2/*RETRY*/, 3/*CANCELED*/, 4/*In Progress*/, 5 /*unknown*/) --1 Succeeded
  order by run_date desc, run_time desc

    ---2 steps outcome on last run
  select step_name, command, last_run_outcome,last_run_date, last_run_time, step_id,  database_name, output_file_name 
  from msdb.dbo.sysjobsteps
  where last_run_date  between @date2  and  @date1
  and last_run_outcome <> 1-- (0/*FAILED*/,2/*RETRY*/, 3/*CANCELED*/, 5/*Unknown*/) --1 Succeeded 
  order by last_run_date desc, last_run_time desc


  --3 for jobs managed by OLA script
  SELECT 
      [DatabaseName]
      ,[SchemaName]     
      ,[ErrorNumber]
      ,[ErrorMessage]
	 , StartTime, Command
  FROM [maintenance].[dbo].[CommandLog]
  where StartTime between dateadd(dd,-45,GETDATE())  and  GETDATE() and ErrorNumber >0

   

 ---- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-help-job-transact-sql?view=sql-server-ver16
---- session running included active job will show on Connected 3.0.sql beneath the label: select 'sessions running but asleep'

select '*******a job info and status : uncomment the lines below **************'
---- job info -- current status column named current_execution_status
--exec msdb.dbo.sp_help_job @job_name= 'Billing : Monthly_Invoices' 

---- job Executing
--exec msdb.dbo.sp_help_job @execution_status=1 --- running

--EXEC msdb.dbo.sp_help_jobactivity 

--EXEC sp_help_jobhistory @job_name = 'BackupKrankyKranesDB', @mode = 'FULL';


-- delete all disabled jobs
SELECT 'EXEC sp_delete_job @job_name = N'' ' + job.name + ''' '
  from [msdb].[dbo].[sysjobs] as job 
  WHERE  enabled = 0

-- delete all report server jobs
  SELECT 'EXEC sp_delete_job @job_name = N'' ' + job.name + ''' '
  from [msdb].[dbo].[sysjobs] as job 
  WHERE description like 'This job is owned by a report server process%' --category_id = 100
