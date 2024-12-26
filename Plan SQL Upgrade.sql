Pre-upgrade checklist
	https://learn.microsoft.com/en-us/sql/database-engine/install-windows/supported-version-and-edition-upgrades-2019?view=sql-server-ver16#pre-upgrade-checklist

	Before upgrading from one edition of SQL Server 2019 (15.x) to another, verify that the functionality you're currently using is supported in the edition to which you're moving.

	Verify supported hardware and software.
		https://learn.microsoft.com/en-us/sql/sql-server/install/hardware-and-software-requirements-for-installing-sql-server-2019?view=sql-server-ver16

	Before upgrading SQL Server, enable Windows Authentication for SQL Server Agent and verify the default configuration, that the SQL Server Agent service account is a member of the SQL Server sysadmin group.

	To upgrade to SQL Server 2019 (15.x), you must be running a supported operating system. For more information, see Hardware and Software Requirements for Installing SQL Server.

	Upgrade is blocked if there's a pending restart.

	Upgrade is blocked if the Windows Installer service isn't running.

	N.B: You can migrate databases from older versions of SQL Server to SQL Server 2019 (15.x), as long as the source database compatibility level is 90 or higher
	
	Specific to SSRS
		Back up your symmetric key. 
			ref: https://learn.microsoft.com/en-us/sql/reporting-services/install-windows/ssrs-encryption-keys-back-up-and-restore-encryption-keys?view=sql-server-ver16
		Back up your report server databases and configuration files. For more information, see Backup and Restore Operations for Reporting Services.
			ref: https://learn.microsoft.com/en-us/sql/reporting-services/install-windows/backup-and-restore-operations-for-reporting-services?view=sql-server-ver16
		Back up any customizations to existing Reporting Services virtual directories in IIS.
		Remove invalid TLS/SSL certificates: unaware of any at this time
	Specific to Log Shipping
		ref:https://learn.microsoft.com/en-us/sql/database-engine/log-shipping/upgrading-log-shipping-to-sql-server-2016-transact-sql?view=sql-server-ver16
		Have valid full backup of each DB(Restored or  DBCC CHECKDB)
		Have a nough space to hold the log backup copies for as long as the upgrade of the secondaries is expected to take.
		all DBs have to set for RESTORE WITH NORECOVERY; None set for RESTORE WITH STANDBY, if not, then transaction logs can no longer be restored after upgrade. 
		N.B:
			Always upgrade the secondary SQL Server instances first. Log shipping continues throughout the upgrade process
			While a secondary server instance is being upgraded, the log shipping copy and restore jobs do not run.
			alerts might be raised indicating restores have not been performed for longer than the configured interval
			the secondary database itself is not upgraded the new version. It will get upgraded only if it is brought online by initiating a failover of the log shipped database.
			failing over generally will not minimize downtime because system database objects will not be synchronized and enabling clients to easily locate 
				and connect to a promoted secondary can be an ordeal but doable. 

Database Security	
	while installing, upgrading follow https://learn.microsoft.com/en-us/sql/sql-server/install/security-considerations-for-a-sql-server-installation?view=sql-server-ver16
	Essentially, it comes down to 
		Enhance physical security
		Use firewalls: between server and internet
		Isolate services: limited to permission needed 
		Configure a secure file system: NTFS recommended
		Disable NetBIOS and server message block: unnecessary protocols disabled
		Installing SQL Server on a domain controller: not recommended
		
		
Upgrade: In-place upgrade for Native mode
	Run the SQL Server installation wizard
	SSIS get upgrade with SQL Engine if it wasn't standalone installation
	SSRS https://learn.microsoft.com/en-us/sql/reporting-services/install-windows/upgrade-and-migrate-reporting-services?view=sql-server-ver16#bkmk_native_scenarios		