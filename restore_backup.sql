--log shipping and restore
--https://www.brentozar.com/archive/2015/01/reporting-log-shipping-secondary-standby-mode/

-- DatabaseRestore_OLA.sql part now of BrentOzar FirstResponderKit
-- https://www.brentozar.com/archive/2017/03/databaserestore-open-source-database-restore-stored-procedure/
-- "DatabaseRestore OK.sql" in orion repository a change to the above

USE [master]

RESTORE DATABASE AdventureWorks2014
FROM disk= 'C:\AdventureWorks2014.bak' 
WITH MOVE 'AdventureWorks2014' TO 'C:\DATA\AdventureWorks2014.mdf',
     MOVE 'AdventureWorks2014_log' TO 'C:\DATA\AdventureWorks2014_log.ldf' 
	 --MOVE 'AdventureWorks2014_Log' TO 'C:\DATA\AdventureWorks2014.ldf',REPLACE --REPLACE option overrides several important safety checks that restore normally performs

RESTORE DATABASE TestBello FROM disk= 'C:\Backups\TestBello.BAK' WITH MOVE 'TestBello_data' TO 'C:\Backups\TestBello.mdf' , MOVE 'TestBello_Log' TO 'C:\Backups\TestBello.ldf'
RESTORE DATABASE [TestBello] FROM  DISK = N'C:\Backups\TestBello.bak' WITH MOVE N'TestBello' TO N'C:\Backups\TestBello.mdf',  MOVE N'TestBello_log' TO N'C:\Backups\TestBello_log.ldf',



-- Ref
--https://docs.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql?view=sql-server-2017

--- restore Standy sample and good to know
restore database TestBello 
from disk = 'C:\Backup\testBello.bak'
with standby = 'C:\Backup\testBelloStandBy.tuf'

-- standby file is created by the restore command
-- standby file smaller in folder on your drive to be specify when restoring
-- !!! the norecovery deletes the standby .tuf. Save a copy of standby before try the restore
-- needs standby file to move from standby to norecovery or vice-versa
--

-- make available for user
restore database TestBello with norecovery

--return to standBy 
restore database TestBello with standby = 'G:\MSSQL\Backup\testBelloStandBy.tuf'
