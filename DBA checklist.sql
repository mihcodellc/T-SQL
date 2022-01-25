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