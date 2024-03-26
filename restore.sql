--log shiiping and restore
--https://www.brentozar.com/archive/2015/01/reporting-log-shipping-secondary-standby-mode/

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

----To Restore an Entire Database from a Full database backup (a Complete Restore):
--RESTORE DATABASE { database_name | @database_name_var }
-- [ FROM <backup_device> [ ,...n ] ]
-- [ WITH
--   {
--    [ RECOVERY | NORECOVERY | STANDBY =
--        {standby_file_name | @standby_file_name_var }
--       ]
--   | ,  <general_WITH_options> [ ,...n ]
--   | , <replication_WITH_option>
--   | , <change_data_capture_WITH_option>
--   | , <FILESTREAM_WITH_option>
--   | , <service_broker_WITH options>
--   | , \<point_in_time_WITH_options-RESTORE_DATABASE>
--   } [ ,...n ]
-- ]
--[;]


--<general_WITH_options>
----Restore Operation Options
--   MOVE 'logical_file_name_in_backup' TO 'operating_system_file_name'
--          [ ,...n ]
-- | REPLACE
-- | RESTART
-- | RESTRICTED_USER | CREDENTIAL
--							SAMPLE: 
--WITH MOVE 'AdventureWorks2014_data' TO 'C:\DATA\AdventureWorks2014.mdf'


use master
-- https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/restore-a-differential-database-backup-sql-server?view=sql-server-ver16	
-- https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql?view=sql-server-ver16
-- https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql?view=sql-server-ver16#restoring_full_n_differential_db_backups	
--files in my backups
RESTORE FILELISTONLY FROM DISK = N'C:\AdventureWorks-FullBackup.bak'   
   WITH FILE=2;  
GO

-- info about the backup where Position = Position of the backup set in the volume (for use with the FILE = option).
RESTORE HEADERONLY FROM DISK = N'C:\AdventureWorks-FullBackup.bak'--N'C:\AdventureWorks-FullBackup.bak'; 
GO

-- Assume the database is lost, and restore full database,   
-- specifying the original FULL DATABASE BACKUP and NORECOVERY,   
-- which allows subsequent restore operations to proceed.  
RESTORE DATABASE MyAdvWorks  
   FROM MyAdvWorks_1  -- OR FROM DISK = N'C:\AdventureWorks-FullBackup.bak'
   WITH NORECOVERY,  STATS = 5;  
GO  
-- Now restore the DIFFERENTIAL DATABASE BACKUP, the second backup on   
-- the MyAdvWorks_1 backup device.  
----diff does restore all datafiles
RESTORE DATABASE MyAdvWorks  
   FROM MyAdvWorks_1  -- OR FROM DISK = N'C:\AdventureWorks-FullBackup.bak'
   WITH FILE = 2,  -- from Position returned by RESTORE HEADERONLY statement
   NORECOVERY,  NOUNLOAD,  STATS = 5 
GO

RESTORE LOG MyAdvWorks  
   FROM MyAdvWorks_log2  
   WITH NORECOVERY,  NOUNLOAD,  STATS = 5;  -- NOUNLOAD only on tape device otherwise it is ignored
GO  
--restore log in standy to read ONLY - 
RESTORE LOG MyAdvWorks FROM  MyAdvWorks_log2 
WITH  STANDBY = 'G:\undoStandy.bak' -- ANY NAME FILE NAME: To keep a "copy-on-write" pre-image for pages modified during the undo pass of a RESTORE WITH STANDBY

