Your SQL Database Maintenance Checklist

***Handy Acronyms
● SLA - Service Level Agreements
● RPO - Recovery Point Objective
● RTO - Recovery Time Objective
● MTTI - Mean Time To Innocence 

***Daily Tasks
● Index maintenance – Run Database Maintenance Plans in SQL Server
● Update statistics – use sp_updatestats 
● Capture configuration details – For both the database and the server
	o Logins/users created or deleted
	o Permissions for those users
● Differential/incremental backups
● Hourly transaction log backups – during business hours

***Weekly
● Full backups – to meet RPO/RTO/SLA objectives
● Know how long it will take you to recover to yesterday, last week, last month, last 
year – YOUR JOB DEPENDS ON IT!

***Monthly
● Corruption checks – run DBCC CHECKDB in SQL Server


Monitoring
SQL Server Health Check Daily
****Service: missing Up 
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'MSSQLServer'
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'SQLServerAgent'
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'SQLBrowser'	
****Backup : which DB with what types of backups
		     the duration exceeding 24 hours
			 number of jobs duration exceed 6 hours
			 The longest
****Disk Space: less 20%, growth day after day
****Free Memory less 20%, growth day after day
SELECT available_physical_memory_kb/1024 as "Total Memory MB",
 available_physical_memory_kb/(total_physical_memory_kb*1.0)*100 AS "% Memory Free"
FROM sys.dm_os_sys_memory
****Free space for Transaction Log size: less 20%, growth day after day
DBCC SQLPERF(LOGSPACE)
****Index Fragmentation
****Query longer than 1 mn, 5mn, 20mn, 30mn 
****Fails Jobs and date time
****Offline DBs
****change to recovery mode of dbs prod
****DBs non candidates for point in time recovery
****Top waits daily-weekly-monthly
****Never restore and check DBs 
