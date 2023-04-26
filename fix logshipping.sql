--instructions
--context: it happens that once create on primary server some configs don't make their ways to a secondary server
--		   here, i tried to insert the missing rows in 2 tables
	
--1- the following provides the secondary_id created from the primary 
--reference 
  select * from msdb.dbo.log_shipping_secondary --where primary_database ='MedRx'
--delete from msdb.dbo.log_shipping_secondary where primary_database ='MedRx'

--2-a if missing here
  select * from [msdb].[dbo].[log_shipping_secondary_databases] 
--2-b replace secondary_database and secondary_id in below insert accordingly to step 1  
--insert into msdb.dbo.log_shipping_secondary_databases
-- SELECT 'RMSOCR'
--      ,'5703DFAD-35AA-4FD3-A5BB-B29179F70E2C' 
--      ,[restore_delay]
--      ,[restore_all]
--      ,[restore_mode]
--      ,[disconnect_users]
--      ,[block_size]
--      ,[buffer_count]
--      ,[max_transfer_size]
--      ,[last_restored_file]
--      ,[last_restored_date]
--  FROM [msdb].[dbo].[log_shipping_secondary_databases]
--   where secondary_database ='reconciliation'

  

--3-a if missing here
	select * from msdb.dbo.log_shipping_monitor_secondary
--3-b replace secondary_database and secondary_id, and primary database in below insert accordingly to step 1  
--insert into [msdb].[dbo].[log_shipping_monitor_secondary]
--SELECT [secondary_server]
--      ,'RMSOCR'
--      ,'5703DFAD-35AA-4FD3-A5BB-B29179F70E2C'
--      ,[primary_server]
--      ,'RMSOCR'
--      ,[restore_threshold]
--      ,[threshold_alert]
--      ,[threshold_alert_enabled]
--      ,[last_copied_file]
--      ,[last_copied_date]
--      ,[last_copied_date_utc]
--      ,[last_restored_file]
--      ,[last_restored_date]
--      ,[last_restored_date_utc]
--      ,[last_restored_latency]
--      ,[history_retention_period]
--  FROM [msdb].[dbo].[log_shipping_monitor_secondary]
--  where secondary_database = 'reconciliation'


--4- make sure the others columns in query 2 and 3 have values,if they exist, matching the query 1