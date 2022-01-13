
sp_JobClearLockedUsers
sp_JobAlerts
sp_dbmaint
sp_JobEmailQueue
sp_JobUpdatePAStatus
sp_who_is_locking

Data Host Backup.Subplan_1
Index Reorganization.Subplan_1
Purge Job.Subplan_1
Output File Cleanup
BACKUP DATABASE [myDB] TO  DISK = N'C:\myDB Backup.BAK' WITH  INIT ,  NOUNLOAD ,  NAME = N'myDB backup',  STATS = 10,  FORMAT, COMPRESSION

Ola Hallengren
	CommandLog Cleanup : 
			DELETE FROM [dbo].[CommandLog] WHERE StartTime < DATEADD(dd,-30,GETDATE())

syspolicy_purge_history			
	-Verify that automation is enabled.
		IF (msdb.dbo.fn_syspolicy_is_automation_enabled() != 1)
			BEGIN
				RAISERROR(34022, 16, 1)
			END	

	-Purge history.	
			EXEC msdb.dbo.sp_syspolicy_purge_history
			
	-Erase Phantom System Health Records. (powershell)		
		if ('$(ESCAPE_SQUOTE(INST))' -eq 'MSSQLSERVER') {$a = '\DEFAULT'} ELSE {$a = ''};
		(Get-Item SQLSERVER:\SQLPolicy\$(ESCAPE_NONE(SRVR))$a).EraseSystemHealthPhantomRecords()