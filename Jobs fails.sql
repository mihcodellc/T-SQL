--  fail jobs based on scheduled period covering all your current jobs
--must worry when table 2 is not empty

--1
  declare @date1 int, @date2 int;
    set @date1 = convert(int,replace(convert(CHAR(10), GETDATE(), 112),'-','')) --20220316
    set @date2 = convert(int,replace(convert(CHAR(10), dateadd(dd,-45,GETDATE()), 112),'-','')) --20220316

    select @date1 'start date', @date2 'end date'
 SELECT job.name, his.step_name, his.run_status , his.run_time, his.run_date,
			CASE WHEN his.run_status = 1 THEN 'Success'  
		     WHEN his.run_status = 0 THEN 'Failure'
			WHEN his.run_status = 2 THEN 'Retried'
			WHEN his.run_status = 3 THEN 'Cancelled'
			WHEN his.run_status = 4 THEN 'Check its steps'
			ELSE 'Unknown' END   AS outcome_message,  
			his.run_duration as 'Duration HHMMSS', his.[message],
 his.sql_severity, his.retries_attempted
	    , job.notify_email_operator_id,  his.[server]
  FROM [msdb].[dbo].[sysjobhistory] as his
  JOIN [msdb].[dbo].[sysjobs] as job on job.job_id = his.job_id
  WHERE run_date between @date2  and  @date1
  AND run_status IN (0/*FAILED*/,2/*RETRY*/, 3/*CANCELED*/, 4/*In Progress*/, 5 /*unknown*/) --1 Succeeded
  order by run_date desc, run_time desc


  ---2 steps outcome on last run
  select step_name, command, last_run_outcome,last_run_date, last_run_time, step_id,  database_name, output_file_name from msdb.dbo.sysjobsteps
  where last_run_date  between @date2  and  @date1
  and last_run_outcome <> 1-- (0/*FAILED*/,2/*RETRY*/, 3/*CANCELED*/, 5/*Unknown*/) --1 Succeeded 
  order by last_run_date desc, last_run_time desc


  --3 for jobs managed by OLA script
  SELECT 
      [DatabaseName]
      ,[SchemaName]     
      ,[ErrorNumber]
      ,[ErrorMessage]
  FROM [maintenance].[dbo].[CommandLog]
  where StartTime between dateadd(dd,-45,GETDATE())  and  GETDATE() and ErrorNumber >0