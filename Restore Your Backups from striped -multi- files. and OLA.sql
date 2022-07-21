


--- below inspired by https://social.msdn.microsoft.com/Forums/sqlserver/en-US/abf50e00-c9b0-4809-9e61-43ed8a53e968/the-media-set-has-2-media-families-but-only-1-are-provided?forum=sqltools
--full
RESTORE DATABASE MedRx FROM 
DISK = 'D:\FULL_20220708_221753_01.bak',
DISK = 'D:\FULL_20220708_221753_02.bak',
DISK = 'D:\FULL_20220708_221753_03.bak',
DISK = 'D:\FULL_20220708_221753_04.bak',
DISK = 'D:\FULL_20220708_221753_05.bak',
DISK = 'D:\FULL_20220708_221753_06.bak',
DISK = 'D:\FULL_20220708_221753_07.bak',
DISK = 'D:\FULL_20220708_221753_08.bak',
DISK = 'D:\FULL_20220708_221753_09.bak',
DISK = 'D:\FULL_20220708_221753_10.bak',
DISK = 'D:\FULL_20220708_221753_11.bak',
DISK = 'D:\FULL_20220708_221753_12.bak',
DISK = 'D:\FULL_20220708_221753_13.bak',
DISK = 'D:\FULL_20220708_221753_14.bak',
DISK = 'D:\FULL_20220708_221753_15.bak',
DISK = 'D:\FULL_20220708_221753_16.bak'
 WITH STATS = 10, REPLACE, NORECOVERY
 -- diff
set statistics profile on
RESTORE DATABASE MedRx FROM 
DISK = 'D:\DIFF_20220713_210646.bak'
 WITH STATS = 10, REPLACE, NORECOVERY


-- inspired by  https://www.datavail.com/blog/how-to-restore-your-backups-from-striped-backup-files/
need to work to combine with my ola-restore script. the latter care more a single file

-- Generate TSQL script to restore the single and multi-file backups

-- ****************************************************************************

-- Copyright © 2016 by JP Chen of DatAvail Corporation

-- This script is free for non-commercial purposes with no warranties.

-- ****************************************************************************

SELECT 
--SERVERPROPERTY('SERVERNAME') as InstanceName

--,bs.database_name as DatabaseName

--,bmf.physical_device_name as BackupPath

--,bs.backup_start_date as BackupStartDate

--,bs.backup_finish_date as BackupFinishDate

--,
bmf.physical_device_name, bs.backup_finish_date as BackupFinishDate,
CASE

       WHEN SUBSTRING(bmf.physical_device_name, LEN(REVERSE(bmf.physical_device_name)) - 5, 1) <> '_' THEN 'RESTORE DATABASE ' +bs.database_name+ ' FROM DISK = ''' + bmf.physical_device_name + ''' WITH STATS = 10, REPLACE, NORECOVERY'

       WHEN bmf.physical_device_name LIKE '%_01%.bak' THEN 'RESTORE DATABASE ' +bs.database_name+ ' FROM DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_2.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_3.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_4.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''' WITH STATS = 10, REPLACE, RECOVERY'

END AS RestoreTSQL

FROM msdb.dbo.backupset bs JOIN msdb.dbo.backupmediafamily bmf

       ON bs.media_set_id = bmf.media_set_id

WHERE bs.type = 'D' -- D = Full, I = Differential, L = Log, F = File or filegroup

AND bs.database_name IN('MedRx') -- specify your databases here

ORDER BY BackupFinishDate DESC


-- log

SELECT 
--SERVERPROPERTY('SERVERNAME') as InstanceName

--,bs.database_name as DatabaseName

--,bmf.physical_device_name as BackupPath

--,bs.backup_start_date as BackupStartDate

--,bs.backup_finish_date as BackupFinishDate

--,
bmf.physical_device_name, bs.backup_finish_date as BackupFinishDate,
CASE

       WHEN SUBSTRING(bmf.physical_device_name, LEN(REVERSE(bmf.physical_device_name)) - 5, 1) <> '_' THEN 'RESTORE DATABASE ' +bs.database_name+ ' FROM DISK = ''' + bmf.physical_device_name + ''' WITH STATS = 10, REPLACE, NORECOVERY'

       WHEN bmf.physical_device_name LIKE '%_01%.bak' THEN 'RESTORE DATABASE ' +bs.database_name+ ' FROM DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_2.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_3.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_4.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''' WITH STATS = 10, REPLACE, RECOVERY'

END AS RestoreTSQL

FROM msdb.dbo.backupset bs JOIN msdb.dbo.backupmediafamily bmf

       ON bs.media_set_id = bmf.media_set_id

WHERE bs.type = 'L' -- D = Full, I = Differential, L = Log, F = File or filegroup

AND bs.database_name IN('MedRx') -- specify your databases here

ORDER BY BackupFinishDate DESC

