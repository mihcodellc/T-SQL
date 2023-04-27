Backup/restore scenarios under different status: Move to ONLINE
Stay in 'RESTORING': means it is expecting more files to be restored 
Solution: RESTORE DATABASE [My_Database] WITH RECOVERY
Stay in ' RECOVERING ': occurs for roll forward OR rollback process during the database shutting down.
Solution: 
Check the number of Virtual Log Files (VLFs): DBCC LOGINFO
Perform a transaction log backup on your database; 
shrink the transaction log as much as possible 
and finally set an initial size of the transaction log file large enough to handle the database workload.
Stay in 'EMERGENCY' = sysadmin user action put the db in this state in order to safely perform database maintenance or for troubleshooting purposes. User Mode has to be single_user in this status and set back to MULTI_USER once the maintenance is done.
Stay in RECOVERY PENDING = recovery process failed
OR Stay in SUSPECT = recovery process has started but not completed successfully.
	Solution: 
Check SQL Server error log for the cause
	perform tail-log backup of the database if it is possible.
	fix the cause IN Emergency status. 
To fix database corruption, run 
DBCC CHECKDB (MyDataBase, REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS
	and taking the database offline and bringing it online

