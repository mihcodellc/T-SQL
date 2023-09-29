-- created 7/21/2022 by Monktar Bello

-- https://docs.microsoft.com/en-us/sql/database-engine/log-shipping/monitor-log-shipping-transact-sql?view=sql-server-ver16
-- report: 
-- -- -- Object Explorer > Reports > Standard Reports > Transaction Log Shipping Status.

-- ****Monitoring ON SECONDARY: 
use master
-- history of log shipping
SELECT top 10 message, log_time FROM [msdb].[dbo].[log_shipping_monitor_history_detail]
 order by log_time desc
-- Stores error detail for log shipping jobs.  
select * from msdb.dbo.log_shipping_monitor_error_detail
-- Stores one monitor record for each secondary database include last operation like restore
select * from msdb.dbo.log_shipping_monitor_secondary
-- alert job id
exec sp_help_log_shipping_alert_job  
-- mode, user, last restore
-- 	the delay for 4 hours as example: choose 4 hours on the restore tab then the restore job should be run frequently as possible accordingly how long the 
--	log backup take + the time to make it available in the copy directory	
SELECT secondary_database,restore_mode as [restore/*1 ie standby 0 no recovery*/],restore_delay,disconnect_users,last_restored_file, dateadd(minute,-restore_delay,last_restored_date) DataTill
 FROM msdb.dbo.log_shipping_secondary_databases



 --Last success of restore from job's message 
 ;with cte as  (
SELECT sj.name as job_name, 
	 substring(sh.message,1,23) + ' -- FileName: ' +substring(sh.message,PATINDEX('%LOGSHIPPING_COPY%', sh.message)+17, PATINDEX('%.trn%', sh.message)+4) as last_Restore,
	 	 row_number() over(partition by sj.name order by run_date desc, cast(substring(sh.message,1,19) as datetime) /*run_time leftover secs*/ desc) rnk
FROM msdb.dbo.sysjobs sj
JOIN msdb.dbo.sysjobhistory sh ON sj.job_id = sh.job_id
where  sj.name like 'LSRestore%' and sh.message like '%restored log%'
)
select top 14/* 14 ie # dbs in logshpping*/ job_name, last_Restore from cte where rnk = 1
order by job_name



-- ****Monitoring ON PRIMARY: 
-- Stores one monitor record for the primary database in each log shipping configuration
select * from msdb.dbo.log_shipping_monitor_primary 
--  information regarding all the secondary databases
use master
exec sp_help_log_shipping_primary_secondary   
	   @primary_database = 'TestBello'


--****Remove log shipping
-- https://docs.microsoft.com/en-us/sql/database-engine/log-shipping/remove-log-shipping-sql-server?view=sql-server-ver16
--SSMS
---- primary database > Properties > Select a page > Transaction Log Shipping 
----    > Clear "Enable this as a primary database in a log shipping configuration" > OK
--1 
use master -- *** ON PRIMARY ***
exec sp_delete_log_shipping_primary_secondary  
    @primary_database = 'TestBello',   
    @secondary_server = 'asp-sql-new3',   
    @secondary_database = 'TestBello' 
--2
use master -- *** ON SECONDARY ***
exec sp_delete_log_shipping_secondary_database  
    @secondary_database = 'TestBello'  
--3
use master -- *** ON PRIMARY ***
exec sp_delete_log_shipping_primary_database  
 @database = 'TestBello' 
 --4
 ----disable the backup job
 --5
 ----disable the copy and restore jobs
 --6
 ----delete secondary database


-- --****Note for you about log shipping
-- In standby mode, the secondary database can be read by existing user/login from the primary database.

--If the login doesn't exist on primary, you won't be able to read the secondary in standby mode. it is not to say in NORECOVERY mode, you won't read anything.

--You can also switch between NORECOVERY and STANDBY mode as you wish on log shipping.

