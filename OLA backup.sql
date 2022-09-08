--create backups: Full, Diff, Log


--Using https://ola.hallengren.com/sql-server-backup.html
--Full
EXEC [dbo].[DatabaseBackup] @Databases='TestBello', @Directory='C:\Backups', @BackupType='Full', @Verify='N', @Compress='Y', @ChangeBackupType='Y'
-- Full verify 
EXEC [dbo].[DatabaseBackup] @Databases='TestBello', @Directory='C:\Backups', @BackupType='Full', @Verify='Y', @Compress='Y', @ChangeBackupType='Y'
-- Diff verify 
EXEC [dbo].[DatabaseBackup] @Databases='TestBello', @Directory='C:\Backups', @BackupType='DIFF', @Verify='Y', @Compress='Y', @ChangeBackupType='Y'
-- Log verify not on SIMPLE recovery model  
EXEC [dbo].[DatabaseBackup] @Databases='TestBello', @Directory='C:\Backups', @BackupType='LOG', @Verify='Y', @Compress='Y', @ChangeBackupType='Y'


--Using SQL statement 
BACKUP DATABASE TestBello TO DISK = 'C:\Backups\TestBello.BAK' WITH COMPRESSION, CHECKSUM, COPY_ONLY  -- FULL
BACKUP DATABASE TestBello TO DISK = 'C:\Backups\TestBello.DIF' WITH DIFFERENTIAL,COMPRESSION, CHECKSUM  --DIFF
BACKUP LOG TestBello TO DISK = 'C:\Backups\TestBello.TRN' WITH COMPRESSION, CHECKSUM --LOG

--ALTER DATABASE [TestBello] SET RECOVERY FULL
