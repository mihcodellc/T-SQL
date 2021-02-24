-- SQL Server Agent jobs have been created to automate the execution frequecy of the backups:
-- [ThinkHealth Backup: FULL - System databases]		-- -- 2 days per week		SUNDAY	23:00	-- Files will endure 2 weeks from the current week
-- [ThinkHealth Backup: FULL - User Databases]			-- -- 1 day per week		SUNDAY	23:30	-- Files will endure 2 weeks from the current week
-- [ThinkHealth Backup: DIFFERENTIAL - User Databases]	-- -- Every day						00:00	-- Files will endure 2 weeks from the current week
-- [ThinkHealth Backup: LOG - User Databases]			-- -- Every 15 minutes				01:00	-- Files will endure 1 week from the current week
-- [ThinkHealth Logs: Command Log Cleanup]				-- -- 1 day per week		FRIDAY	23:00	-- Will be purged if more than 2 weeks
-- [ThinkHealth Logs: Delete Backup History]			-- -- Every month			FRIDAY	23:00	-- Will be purged if more than 1 month
-- [ThinkHealth Logs: Delete Job History]				-- -- Every 2 weeks			FRIDAY	23:00	-- Will be purged if more than 2 weeks
-- [ThinkHealth Logs: Output File Cleanup]				-- -- 1 day per week		FRIDAY	23:00	-- Will be purged if more than 1 month

---- Run the above jobs with the UI or the following TSQL:
EXEC msdb.dbo.sp_start_job 'ThinkHealth Backup: FULL - System databases'
EXEC msdb.dbo.sp_start_job 'ThinkHealth Backup: FULL - User Databases'
EXEC msdb.dbo.sp_start_job 'ThinkHealth Backup: LOG - User Databases'

---- Check for information on the previously created jobs with:
EXEC msdb.dbo.sp_help_job @Job_name = 'ThinkHealth Backup: FULL - User Databases'
EXEC msdb.dbo.sp_help_job @Job_name = 'ThinkHealth Backup: FULL - System databases'

 ----You can check running jobs with the following query:
SELECT sj.name, sj.description, sja.*
FROM msdb.dbo.sysjobactivity AS sja
INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
WHERE sja.start_execution_date IS NOT NULL
   AND sja.stop_execution_date IS NULL
   AND enabled = 1
   AND sj.name LIKE '%ThinkHealth%'
