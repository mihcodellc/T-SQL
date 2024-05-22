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



---***********implement
   create index ix_Daily_Jobs_duration_rundatetime
on Daily_Jobs_duration (rundatetime)

create index ix_RMSDaily_Jobs_duration_Collection_Time
on Daily_Jobs_duration ([Collection_Time])

   CREATE TABLE [dbo].[Daily_Jobs_duration](
	[jobName] [varchar](128) NULL,
	[step_id] [int] NULL,
	[step_name] [varchar](128) NULL,
	[RunDateTime] [datetime] NULL,
	[RunDurationTime] [time](7) NULL,
	[RunDurationHuman] [varchar](15) NULL,
	[runduration] [int] NULL,
	[ExcutionStatus] [varchar](128) NULL,
	[outcome_message] [nvarchar](4000) NULL,
	[Collection_Time] [datetime] NOT NULL
) ON [PRIMARY]
GO

   
create   proc [dbo].[p_Job_duration]
as 
begin
-- last update 9/11/2023 by Monktar Bello: DBSUPPORT-3416 - removed the try catch as the error during job execution is from conversion to time of value > 235959 ie day
--								   redesigned the table to insert with error
--  6/20/2023  by Monktar Bello: added try..catch to resolve DBSUPPORT-3234
--  6/15/2023 by Monktar Bello: Initial version - DBSUPPORT-3233
--run example: exec [dbo].p_Job_duration

--with the when column we know when the data are collected
--with the duration as time datatype we can order
--scheduled to run every 6 hours
--because all jobs don't have the same schedule, noticing that some jobs don't have their histories start the last run of Purge syspolicy_purge_history, it let the dupes happen in this collection 
-- it will be clean after 45 days
--looking at enabled jobs 

-- query: select * from RmsAdmin.dbo.RMSDaily_Jobs_duration where jobName = '???'

--**********Find the long duration on current date by job and step
-- declare @date1 datetime;
--    set @date1 = convert(datetime,replace(convert(CHAR(10), dateadd(dd,0,GETDATE()), 112),'-','')) --20220316
--    --select @date1  
--;with cte as(
--select  
--jobName, step_name, RunDuration,[RunDurationHuman],
--row_number() over (partition by jobName, step_name order by runduration desc) Max1, 
--RunDateTime
--,Collection_Time
--from rmsAdmin.[dbo].[RMSDaily_Jobs_duration]
--where 
----jobName = 'Loader: LoaderState Populate (YEAR AGO)'
-- Collection_Time >= @date1
--)

--select jobName, step_name, [RunDurationHuman], RunDateTime, Collection_Time  from cte
--where max1 =1



SET NOCOUNT ON;
--https://learn.microsoft.com/en-us/sql/relational-databases/system-tables/dbo-sysjobhistory-transact-sql?view=sql-server-ver16#example

    insert into dbo.RMSDaily_Jobs_duration
    SELECT sj.name AS [JobName],
	  sh.[step_id] AS [StepID],
	  sh.step_name AS [StepName],
	  DATETIMEFROMPARTS(
		 LEFT(padded_run_date, 4),         -- year
		 SUBSTRING(padded_run_date, 5, 2), -- month
		 RIGHT(padded_run_date, 2),        -- day
		 LEFT(padded_run_time, 2),         -- hour
		 SUBSTRING(padded_run_time, 3, 2), -- minute
		 RIGHT(padded_run_time, 2),        -- second
		 0) AS [LastRunDateTime],          -- millisecond
	  cast(CASE
		 WHEN sh.run_duration > 235959
			THEN NULL
		 ELSE STUFF(STUFF(RIGHT(REPLICATE('0', 6) + CAST(sh.run_duration AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
		 END as time) AS [RunDuration (d.HH:MM:SS)],
	  CASE
		 WHEN sh.run_duration > 235959
			THEN CAST((CAST(LEFT(CAST(sh.run_duration AS VARCHAR), LEN(CAST(sh.run_duration AS VARCHAR)) - 4) AS INT) / 24) AS VARCHAR) + '.' + RIGHT('00' + CAST(CAST(LEFT(CAST(sh.run_duration AS VARCHAR), LEN(CAST(sh.run_duration AS VARCHAR)) - 4) AS INT) % 24 AS VARCHAR), 2) + ':' + STUFF(CAST(RIGHT(CAST(sh.run_duration AS VARCHAR), 4) AS VARCHAR(6)), 3, 0, ':')
		 ELSE STUFF(STUFF(RIGHT(REPLICATE('0', 6) + CAST(sh.run_duration AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
		 END as RunDurationINT, sh.run_duration,
		 CASE [sh].[run_status] 
	   WHEN 0 THEN 'Failed'
	   WHEN 1 THEN 'Succeeded' 
	   WHEN 2 THEN 'Retry' 
	   WHEN 3 THEN 'Cancelled' 
	   WHEN 4 THEN 'In Progress' 
	 END AS [ExecutionStatus],
	 [sh].[message] AS [MessageGenerated] ,
	 getdate() atWhen
    FROM msdb.dbo.sysjobs sj
    INNER JOIN msdb.dbo.sysjobhistory sh
	  ON sj.job_id = sh.job_id
    CROSS APPLY (
	  SELECT RIGHT('000000' + CAST(sh.run_time AS VARCHAR(6)), 6),
		 RIGHT('00000000' + CAST(sh.run_date AS VARCHAR(8)), 8)
	  ) AS shp(padded_run_time, padded_run_date)
	  where 
	  sj.enabled = 1
	  --and [sj].[name] = 'Loader: LoaderState Populate (YEAR AGO)'
    --order by [JobName], [StepID], [LastRunDateTime] desc

    --clean the table
    delete from RmsAdmin.dbo.[RMSDaily_Jobs_duration] where [Collection_Time] < DATEADD(day, -45, GETDATE())
	--truncate table [dbo].[RMSDaily_Jobs_duration]

    ----**read Example
    --select distinct jobName, step_name, step_id, rundatetime, RunDurationHuman  from RmsAdmin.dbo.RMSDaily_Jobs_duration
    --where jobname = 'Loader: LoaderState Populate (YEAR AGO)-ERA'
    --and step_id = 1 and RunDurationHuman not like  '00:00:00'
    --order by rundatetime


end
