-- instructions 
-- replace @db_name, @Full_extension, @Diff_extension, @Log_extension
-- run the server where the @db_name

-- note
-- read header of backups file
RESTORE HEADERONLY FROM DISK = N'C:\MSSQL\Backup\MyDatabase_20230605124500.trn' -- of each set of backups in text output and searcch the LSN
or run
db backups overview below
	and supposed you have full, diff, logs available
or
when searching for log you can restore, go to section "find the log you can restore"

--The transaction log LSN chain is NOT AFFECTED by a full or differential database backup
-- When planning which transaction log backup to use to roll forward, the LastLSN + 1 of the Full/Diff database backup 
--		  will fall in between the FirstLSN and LastLSN of its subsequent transaction log backup
-- last LSN of log_backup_1 = First LSN of the next log_backup_2
-- after a full and diff restored, the log to restore is the one done just after the diff is done 	

-- need a version to read heads of backup files 

create or alter proc dbo.usp_RestoreListOfFiles
     @db_name VARCHAR(100)
as
begin
    -- 7/26/2022 - Inital version By : Monktar Bello
    -- Run example: exec DBADB.dbo.usp_RestoreListOfFiles 'MyDB'
    -- ****Description:*************************************
    -- it return the last full, diff,and the first log to be used to restore the database

    -- match full to diff to log 
    declare @full varchar(300)
    declare @Diff varchar(300) 
    declare @Log varchar(300)
    declare @Logbackup_set_id int
    declare @Fullbackup_set_id int
    declare @Full_extension varchar(7) = '_01.bak'
    declare @Diff_extension varchar(7) = '.bak'
    declare @Log_extension varchar(7) = '.trn'



    ;with cte_full as (
    select top 1 backup_set_id, backup_start_date, substring(m.physical_device_name,1, CHARINDEX(@Full_extension, m.physical_device_name,1)-1) CommonBackUpName--, physical_device_name
	   , last_lsn, checkpoint_lsn, physical_device_name
    FROM msdb.dbo.backupset d 
    INNER JOIN msdb.dbo.backupmediafamily m ON d.media_set_id = m.media_set_id
    where database_name = @db_name and d.[type] = 'D' and is_copy_only = 0
    order by backup_start_date desc
    ), cte_diff as (
    select top 1 d.backup_set_id, d.backup_start_date, substring(m.physical_device_name,1, CHARINDEX(@Diff_extension, m.physical_device_name,1)-1) CommonBackUpName --, physical_device_name
	   , d.last_lsn, d.database_backup_lsn, m.physical_device_name
    FROM msdb.dbo.backupset d 
    INNER JOIN msdb.dbo.backupmediafamily m ON d.media_set_id = m.media_set_id
    join cte_full f on f.checkpoint_lsn = d.database_backup_lsn -- compare to full
    where database_name = @db_name and d.[type] = 'I' and is_copy_only = 0
    order by backup_start_date desc
    )
    , cte_log as (
    select top 1 l.backup_set_id as Logbackup_set_id, l.backup_start_date, substring(m.physical_device_name,1, CHARINDEX(@Log_extension, m.physical_device_name,1)-1) CommonBackUpName  --, physical_device_name
    , f.physical_device_name as FullBackUpName, di.physical_device_name as DiffBackUp, m.physical_device_name as FirstLogBackUp,  f.backup_set_id as Fullbackup_set_id
    FROM msdb.dbo.backupset l 
    INNER JOIN msdb.dbo.backupmediafamily m ON l.media_set_id = m.media_set_id
    join cte_full f on f.checkpoint_lsn = l.database_backup_lsn
    join cte_diff di on f.checkpoint_lsn = di.database_backup_lsn and  di.last_lsn+1 between l.first_lsn and l.last_lsn  -- compare to diff
    where database_name = @db_name and l.[type] = 'L' and is_copy_only = 0
    order by l.backup_start_date desc
    )

    select @full = FullBackUpName, @Diff = DiffBackUp, @Log = FirstLogBackUp, @Logbackup_set_id = Logbackup_set_id, @Fullbackup_set_id = Fullbackup_set_id
    from cte_log 

    -- backup files to use
    select @full as FullBackUpName, @Diff as DiffBackUp, @Log as FirstLogBackUp 

    --list the last full's files to be used 
    -- RESTORE DATABASE @db_name FROM
    select 'DISK = '''+ m.physical_device_name + ''',' as [list the last full's files to be used] 
    FROM msdb.dbo.backupset l 
    INNER JOIN msdb.dbo.backupmediafamily m ON l.media_set_id = m.media_set_id 
    where l.backup_set_id  = @Fullbackup_set_id
    and l.database_name = @db_name and l.[type] = 'D' and l.is_copy_only = 0
    -- remove the last "," then add the line below to get the restore command
	-- WITH STATS = 10, REPLACE, NORECOVERY


    --list the last full's files to use 
    select 'RESTORE DATABASE ['+ @db_name + '] FROM DISK = '''+ @Diff + ''' WITH NORECOVERY' as [list the last Diff to be used] 

    --list the logs to use after restore the diff
    -- RESTORE LOG @db_name FROM
    select 'RESTORE LOG [' + @db_name+ '] FROM DISK = ''' + m.physical_device_name + ''' WITH NORECOVERY' as [list the logs to use after restore the diff] 
    FROM msdb.dbo.backupset l 
    INNER JOIN msdb.dbo.backupmediafamily m ON l.media_set_id = m.media_set_id 
    where l.backup_set_id > = @Logbackup_set_id
    and l.database_name = @db_name and l.[type] = 'L' and l.is_copy_only = 0


end



-- https://blog.sqlauthority.com/2015/08/10/sql-server-error-msg-4305-level-16-state-1-the-log-in-this-backup-set-terminates-at-lsn-which-is-too-early-to-apply-to-the-database/
-- https://www.mssqltips.com/sqlservertip/3209/understanding-sql-server-log-sequence-numbers-for-backups/


--db backups overview
-- Assign the database name to variable below
DECLARE @db_name VARCHAR(100)
SELECT @db_name = 'Archive'
-- query
SELECT TOP (30) s.database_name
,m.physical_device_name
,CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize
,CAST(DATEDIFF(second, s.backup_start_date, s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken
,s.backup_start_date
,CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn
,CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn
,CASE s.[type] WHEN 'D'
THEN 'Full'
WHEN 'I'
THEN 'Differential'
WHEN 'L'
THEN 'Transaction Log'
END AS BackupType
,s.server_name
,s.recovery_model
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE s.database_name = @db_name
ORDER BY backup_start_date DESC
,backup_finish_date

--get full info knowing physical_device_name
select l.backup_set_id as Logbackup_set_id, l.backup_start_date , m.physical_device_name as FirstLogBackUp, l.checkpoint_lsn 
FROM msdb.dbo.backupset l 
INNER JOIN msdb.dbo.backupmediafamily m ON l.media_set_id = m.media_set_id
where database_name = @db_name and l.[type] = 'D' and is_copy_only = 0
and m.physical_device_name = 'D:\FULL_20220715_222435_01.bak' 

--get diff info knowing physical_device_name
select top 1 l.backup_set_id as Logbackup_set_id, l.backup_start_date , m.physical_device_name as FirstLogBackUp, l.last_lsn 
FROM msdb.dbo.backupset l 
INNER JOIN msdb.dbo.backupmediafamily m ON l.media_set_id = m.media_set_id
where database_name = @db_name and l.[type] = 'I' and is_copy_only = 0
and m.physical_device_name = 'D:\DIFF_20220718_210311.bak' 

-- find the first log knowing the full and diff
select top 1 l.backup_set_id as Logbackup_set_id, l.backup_start_date , m.physical_device_name as FirstLogBackUp 
FROM msdb.dbo.backupset l 
INNER JOIN msdb.dbo.backupmediafamily m ON l.media_set_id = m.media_set_id
where database_name = @db_name and l.[type] = 'L' and is_copy_only = 0
and l.database_backup_lsn = 9133726000051979900492 -- compare to full checkpoint_lsn column
and 9135946000016147900001+1 between l.first_lsn and l.last_lsn  -- compare to diff last_lsn +1 
order by l.backup_start_date desc

-- find the first log knowing the full and diff
select  l.backup_set_id as Logbackup_set_id, l.backup_start_date , m.physical_device_name as FirstLogBackUp 
FROM msdb.dbo.backupset l 
INNER JOIN msdb.dbo.backupmediafamily m ON l.media_set_id = m.media_set_id
where database_name = @db_name and l.[type] = 'L' and is_copy_only = 0
and l.backup_set_id >= 914131 -- backup_set_id of  first log or the one you want 
order by l.backup_start_date asc


--DECLARE @db_name VARCHAR(100)
SELECT @db_name = 'MyDB'

----Get Backup History for required database
SELECT TOP (5) backup_set_id, s.database_name
,m.physical_device_name
,CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize
,CAST(DATEDIFF(second, s.backup_start_date, s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken
,s.backup_start_date
,CASE s.[type] WHEN 'D'
THEN 'Full'
WHEN 'I'
THEN 'Differential'
WHEN 'L'
THEN 'Transaction Log'
END AS BackupType
,CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn
,CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn
,s.database_backup_lsn as Linked_to_Full_checkpoint_lsn
,s.checkpoint_lsn as [LSN: redo must start here]
,s.differential_base_lsn
,s.backup_size as [size in bytes]
,s.compressed_backup_size as [compressed size]
,s.server_name
,s.recovery_model
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE s.database_name = @db_name and s.[type] = 'D'
ORDER BY backup_start_date DESC
,backup_finish_date


--Get Backup History for required database
SELECT TOP (20) backup_set_id, s.database_name
,m.physical_device_name
,CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize
,CAST(DATEDIFF(second, s.backup_start_date, s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken
,s.backup_start_date
,CASE s.[type] WHEN 'D'
THEN 'Full'
WHEN 'I'
THEN 'Differential'
WHEN 'L'
THEN 'Transaction Log'
END AS BackupType
,CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn
,CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn
,s.database_backup_lsn as Linked_to_Full_checkpoint_lsn
,s.checkpoint_lsn as [LSN: redo must start here]
,s.differential_base_lsn
,s.backup_size as [size in bytes]
,s.compressed_backup_size as [compressed size]
,s.server_name
,s.recovery_model
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE s.database_name = @db_name and s.[type] = 'I'
ORDER BY backup_start_date DESC
,backup_finish_date



--SELECT @db_name = 'MyDB'
----Get Backup History for required database
--SELECT TOP (5) backup_set_id, s.database_name
--,m.physical_device_name
--,CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize
--,CAST(DATEDIFF(second, s.backup_start_date, s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken
--,s.backup_start_date
--,CASE s.[type] WHEN 'D'
--THEN 'Full'
--WHEN 'I'
--THEN 'Differential'
--WHEN 'L'
--THEN 'Transaction Log'
--END AS BackupType
--,CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn
--,CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn
--,s.database_backup_lsn as Linked_to_Full_checkpoint_lsn
--,s.checkpoint_lsn as [LSN: redo must start here]
--,s.differential_base_lsn
--,s.backup_size as [size in bytes]
--,s.compressed_backup_size as [compressed size]
--,s.server_name
--,s.recovery_model
--FROM msdb.dbo.backupset s
--INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
--WHERE s.database_name = @db_name and s.[type] = 'L' and backup_start_date > '2022-07-25 20:59:55.000'
--ORDER BY backup_start_date 
--,backup_finish_date

--**** find the log you can restore when db reject a log and send LSN you can restore
DECLARE @TargetLSN NVARCHAR(50) = '9600401000047277700001'; -- Replace 'YourTargetLSN' with the LSN you're searching for
SELECT TOP 1
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.database_name,
    bs.type,
    bs.first_lsn,
    bs.last_lsn,
    bs.checkpoint_lsn,
    bs.database_backup_lsn
FROM
    msdb.dbo.backupset bs
WHERE
    bs.type = 'L' -- Log backup
    AND bs.last_lsn = @TargetLSN -- Check if the last LSN is greater than or equal to the target LSN
ORDER BY
    bs.backup_finish_date DESC; -- Get the most recent log backup first	
