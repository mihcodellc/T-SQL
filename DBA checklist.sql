-- https://cloud.ax3-systems.com/cloud-sql-for-sql-server-database-administration-best-practices/

Your SQL Database Maintenance Checklist

***Handy Acronyms
● SLA - Service Level Agreements
● RPO - Recovery Point Objective -- data loss
● RTO - Recovery Time Objective -- back online, back in business
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
● Corruption checks – run DBCC CHECKDB in SQL Server -- review how to solve this



Monitoring
SQL Server Health Check Daily : 
		exec dbaDB.dbo.sp_BLitz --@help=1
			  @CheckProcedureCache = 1 /*top 20-50 resource-intensive cache plans and analyze them for common performance issues*/, 
			  @CheckUserDatabaseObjects = 0,
			  @IgnorePrioritiesAbove = 50 /*if you want a daily bulletin of the most important warnings, set*/
			  --@CheckProcedureCacheFilter = 'CPU' --- | 'Reads' | 'Duration' | 'ExecCount'
			  ,@CheckServerInfo = 1 

****Service: missing Up 
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'MSSQLServer'
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'SQLServerAgent'
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'SQLBrowser'	
****Backup Data&Login/Permissions&Jobs : which DB with what types of backups
		     the duration exceeding 24 hours
			 number of jobs duration exceed 6 hours
			 The longest
			 duration over time
			 success/fail over time
****Disk Space: less 20%, growth day after day
****Free Memory less 20%, growth day after day -- memory free for OS, SQL server memory shuldn't be unlimited
SELECT available_physical_memory_kb/1024 as "Total Memory MB",
 available_physical_memory_kb/(total_physical_memory_kb*1.0)*100 AS "% Memory Free"
FROM sys.dm_os_sys_memory
****Free space for Transaction Log size: less 20%, growth day after day
DBCC SQLPERF(LOGSPACE)
****Index Fragmentation
****Query longer than 1 mn, 5mn, 20mn, 30mn 
****Fails(based on all jobs schedules) Jobs and date time, count of enable jobs, count of fails, count of DBCC success
****Offline DBs
****change to recovery mode of dbs prod
****DBs non candidates for point in time recovery
****Top waits daily-weekly-monthly
****Never restore and check DBs
****Security Logs
****Weekly Penetration Tests


https://confluence.revmansolutions.com/display/PT/SQL+Server+DBA+Checklist

This is a database reliability checklist. This applies to both PostgreSQL and MS SQL Server. For weekly checklist there need to be a task associated with the check performed.


Daily Checklist
****************************************

Check/fix corruption ???

Backups (MSSQL  | PostgreSQL)- Check your backups to validate that they were successfully created per your process.

Nightly Processing - Review the nightly or early morning processes.

SQL Server Error Log - Review the SQL Server/Agent/Services(SSIS, SSAS)/System log/logs for any message related 
				to error/Severity/warning/Performance Hardware-network-driver/information 
				or security issues (successful or failed logins) that are unexpected.
				set up for those or custom script ot third-party log manegement tolls
						***SQL log
						Startup Messages
						Database Issues: Errors during database startup, recovery, or consistency checks
						Backups and Restores:
						Deadlocks:
						Login Failures: misconfiguration or potential security threat.
						Replication or Availability Issues
						***Agent Log
						Job Failures
						Alerts and Notifications
						Agent Service Startup Issues:
						***SSIS Logs
						Package Execution Failures
						Validation Issues
						Performance Bottlenecks
						Connection Errors
Some of the hardware vendors write warnings to the Windows Event Log when they anticipate an error is going to occur, so this gives you the opportunity to be proactive and correct the problem during a scheduled down time, rather than having a mid day emergency.

SQL Server Agent Jobs - Review for failed SQL Server Agent Jobs.

HA or DR Logs - Check your high availability and/or disaster recovery process logs.  Depending on the solution (Log Shipping, Clustering, Replication, Database Mirroring, CDP, etc.) that you are using dictates what needs to be checked.

Performance Logs - Review the performance metrics to determine if your baseline was exceeded or if you had slow points during the day that need to be reviewed.

Security Logs - Review the security logs from a third party solution or from the SQL Server Error Logs to determine if you had a breach or a violation in one of your policies.

Centralized error handling - If you have an application, per SQL Server or enterprise level logging, then review those logs for any unexpected errors/warninf.

Storage - Validate you have sufficient storage on your drives to support your databases, backups, batch processes, etc. in the short term.

Service Broker - Check the transmission and user defined queues to make sure data is properly being processed in your applications.

Windows Event viewer: what to look for 
	SQL Server related in
		Application Logs
		System Logs
		Security Logs - if you play IT role
		
Database Security	(Weekly security checklist some below) 
	while installing, upgrading follow https://learn.microsoft.com/en-us/sql/sql-server/install/security-considerations-for-a-sql-server-installation?view=sql-server-ver16
	Enhance physical security
	Use firewalls: between server and internet
	Isolate services: limited to permission needed 
	Configure a secure file system: NTFS recommended
	Disable NetBIOS and server message block: unnecessary protocols disabled
	Installing SQL Server on a domain controller: not recommended
	


Weekly Checklist
****************************************

Backup Verification (Comprehensive)- Verify your backups and test on a regular basis to ensure the overall process works as expected.

Validate that sufficient storage is available to move the backup to the needed SQL Server
Validate that the SQL Server versions are compatible to restore the database
Validate that no error messages are generated during the restore process
Validate that the database is accurately restored and the application will function properly


Backup Verification (Simple) - Verify your backups on a regular basis.

Maintenance Tasks: Automating the RESTORE VERIFYONLY Process
Verifying Backups with the RESTORE VERIFYONLY Statement
Windows, SQL Server or Application Updates - Check for service packs/patches that need to be installed on your SQL Server from either a hardware, OS, DBMS or application perspective

Capacity Planning - Perform capacity planning to ensure you will have sufficient storage for a specific period of time such as for 6, 12 or 18 months.

Fragmentation - Review the fragmentation for your databases to determine if you particular indexes must be rebuilt based on analysis from a backup SQL Server.

Maintenance - Perform database maintenance on a weekly or monthly basis.

Security - Remove unneeded logins and users for individuals that have left the organization, had a change in position, etc.

Shrink databases - If databases or transaction logs are larger, than necessary shrink those files to free up disk space.

Privileges: who has sysadmin or SA priv


DBA Tasks
*************************************************************
1.Backup and Recovery
Regular Backups/Restore Testing/Disaster Recovery Planning
2. Performance Tuning
Index Maintenance: indexes fragmentation to improve query performance.
Query Optimization: Review and optimize slow-running queries.
Monitor Performance: CPU, memory, I/O, and storage usage.
Database Statistics up to date
3. Security Management
User Management/Data Encryption at rest and in transit.
Audit Logging: Enable and review audit logs to track changes or unauthorized access. how-to??
Patching: Apply security patches and updates to database software to prevent vulnerabilities.
4. Storage and Capacity Planning
Monitor Disk Space/Growth Projections/Partitioning: Use table partitioning to manage large datasets and improve performance.
5. Database Health Checks
Database Integrity Checks/Error Log Monitoring/Deadlock Detection
6. Automation of Routine Tasks
Automate Jobs/Alert Systems for critical events like failed jobs, low disk space, or slow queries.
7. Patch Management and Upgrades
Database Patching/Version Upgrades
8. Data Integrity and Consistency
Transaction Log Management/Data Validation
9. Replication and High Availability
Replication Monitoring(data consistency)/High Availability Monitoring(working failover)
10. Documentation and Reporting
Maintain detailed documentation on database configuration, policies, and procedures.
Regular Reports: database usage, performance, and potential issues.


miscellaneous  
******************************************************

PostgreSQL
I have created scripts and instructions for PG performance monitoring for the week I am gone. 
Recommend you keep an htop running each day to monitor CPU. 
The files explain more. They are at s:\dba\pgperf


********************************
restart SQL Prod
we need to be sure we stop/restart LSP when we are doing the restarts. job name: Loader: LoaderState Populate (YEAR AGO)
exec RmsAdmin.dbo.p_RMSSQLRestartControl  START
exec RmsAdmin.dbo.p_RMSSQLRestartControl



***************************
Backups checks on remote servers with Powershell
get-childitem -path O:\sqlprimary *full_2023092*_16.bak -recurse | sort-object name -descending | select-object Name, Length
get-childitem -path O:\sqlprimary *diff_20230925*.bak -recurse | sort-object length -descending | select-object Name, Length



for interview
admin script/dbatools from on-premise server targeting database on EC2, Azure database
use Azure Application Insights, Azure Diagnostics Logs, SQL Server Error Logs, Solarwinds DPA, RDS Database logs

I review all DDL/DML going to production. Part of my checklist:
do we have a 3rd normal form?
do we have indexes supporting the query? how often?
reads, CPU, data size ... in pre-prod database


run sp_BlitzWho(brentozar), custom queries, sql sentry explorer to examine the query plan looking for errors, waits stats, blocking/blocked sessions, scans vs seeks...

rollback plan, patching 77 servers at least once a year with cumulative updates, assign priv on role-based access and least priv, testing my backups, enable transparent data encryption services,

I work on the base of most urgent task while I keep an eye on a different screen displaying my monitoring tools, all alerts and emails 