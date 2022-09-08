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
BACKUP DATABASE TestBello TO DISK = 'C:\Backups\TestBello.BAK' WITH COMPRESSION, CHECKSUM, COPY_ONLY, STATS = 10  -- FULL
BACKUP DATABASE TestBello TO DISK = 'C:\Backups\TestBello.DIF' WITH DIFFERENTIAL,COMPRESSION, CHECKSUM  --DIFF
BACKUP LOG TestBello TO DISK = 'C:\Backups\TestBello.TRN' WITH COMPRESSION, CHECKSUM --LOG

--ALTER DATABASE [TestBello] SET RECOVERY FULL


-- interesting part is the @BlockSize which induce error some operations of sql server
-- incrementation, increase of storage, drive, disk happens here by size of 64K ie 65536B
-- need to research more on effect of blocksize

EXECUTE [dbo].[DatabaseBackup]
@Databases = 'USER_DATABASES',
@Directory = N'G:\MSSQL\Backup',
@BackupType = 'FULL',

@BufferCount = 50,
@MaxTransferSize = 4194304,
@BlockSize = 65536,  -- 512,1024,2048,4096,8192,16384,32768,6553
@NumberOfFiles = 16,

@Verify = 'Y',
@CleanupTime = 336,
@CheckSum = 'Y',
@LogToTable = 'Y'
