 --stop and run a job
EXEC msdb.dbo.sp_stop_job    N'Loader: LoaderState Populate (YEAR AGO)' ;  
GO
WAITFOR DELAY '00:00:05'; -- delay 5 seconds 
EXEC msdb.dbo.sp_start_job   N'Loader: LoaderState Populate (YEAR AGO)' ;  
GO

 -- https://sqlperformance.com/2014/12/sql-maintenance/proactive-sql-server-health-checks-2

 select ' emails not set properly '
SELECT [Name], [Description], notify_email_operator_id
  FROM [dbo].[sysjobs] 
  WHERE [enabled] = 1
  AND [notify_level_email]  IN (0, 1)
  --0 = Never 1 = When the job succeeds 2 = When the job fails 3 = Whenever the job completes (regardless of the job outcome)
  ORDER BY [Name];



  select ' job duration '
  SELECT
  [j].[name] AS [JobName],
  [h].[step_id] AS [StepID],
  [h].[step_name] AS [StepName],
  CONVERT(CHAR(10), CAST(STR([h].[run_date],8, 0) AS DATETIME), 121) AS [RunDate],
  STUFF(STUFF(RIGHT('000000' + CAST ( [h].[run_time] AS VARCHAR(6 ) ) ,6),5,0,':'),3,0,':') 
    AS [RunTime],
  (([run_duration]/10000*3600 + ([run_duration]/100)%100*60 + [run_duration]%100 + 31 ) / 60) 
    AS [RunDuration_Minutes],
  CASE [h].[run_status] 
    WHEN 0 THEN 'Failed'
    WHEN 1 THEN 'Succeeded' 
    WHEN 2 THEN 'Retry' 
    WHEN 3 THEN 'Cancelled' 
    WHEN 4 THEN 'In Progress' 
  END AS [ExecutionStatus],
  [h].[message] AS [MessageGenerated]  
FROM [msdb].[dbo].[sysjobhistory] [h]
INNER JOIN [msdb].[dbo].[sysjobs] [j] 
ON [h].[job_id] = [j].[job_id]
WHERE 
--[j].[name] = 'LDT_SetPartOf835BuildForStatus9and11 (noon)'
--AND
[step_id] = 0
ORDER BY [RunDate], [RunDuration_Minutes] desc, JobName

select 'This query lists jobs that took 25% longer than the average.'
SELECT
  [j].[name] AS [JobName],
  [h].[step_id] AS [StepID],
  [h].[step_name] AS [StepName],
  CONVERT(CHAR(10), CAST(STR([h].[run_date],8, 0) AS DATETIME), 121) AS [RunDate],
  STUFF(STUFF(RIGHT('000000' + CAST ( [h].[run_time] AS VARCHAR(6 ) ) ,6),5,0,':'),3,0,':') 
    AS [RunTime],
  (([run_duration]/10000*3600 + ([run_duration]/100)%100*60 + [run_duration]%100 + 31 ) / 60) 
    AS [RunDuration_Minutes],
  [avdur].[Avg_RunDuration_Minutes] 
FROM [dbo].[sysjobhistory] [h]
INNER JOIN [dbo].[sysjobs] [j] 
ON [h].[job_id] = [j].[job_id]
INNER JOIN 
(
  SELECT
    [j].[name] AS [JobName],
    AVG((([run_duration]/10000*3600 + ([run_duration]/100)%100*60 + [run_duration]%100 + 31 ) / 60)) 
      AS [Avg_RunDuration_Minutes]
  FROM [dbo].[sysjobhistory] [h]
  INNER JOIN [dbo].[sysjobs] [j] 
  ON [h].[job_id] = [j].[job_id]
  WHERE [step_id] = 0
  AND CONVERT(DATE, RTRIM(h.run_date)) >= DATEADD(DAY, -60, GETDATE())
  GROUP BY [j].[name]
) AS [avdur] 
ON [avdur].[JobName] = [j].[name]
WHERE [step_id] = 0
AND (([run_duration]/10000*3600 + ([run_duration]/100)%100*60 + [run_duration]%100 + 31 ) / 60) 
    > ([avdur].[Avg_RunDuration_Minutes] + ([avdur].[Avg_RunDuration_Minutes] * .25))
ORDER BY [RunDate], [RunDuration_Minutes] desc
