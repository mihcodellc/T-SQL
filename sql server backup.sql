-- last one of each backup types
SELECT ISNULL(d.[name], bs.[database_name]) AS [Database], d.recovery_model_desc AS [Recovery Model], 
       d.log_reuse_wait_desc AS [Log Reuse Wait Desc],
    MAX(CASE WHEN [type] = 'D' THEN bs.backup_finish_date ELSE NULL END) AS [Last Full Backup],
    MAX(CASE WHEN [type] = 'I' THEN bs.backup_finish_date ELSE NULL END) AS [Last Differential Backup],
    MAX(CASE WHEN [type] = 'L' THEN bs.backup_finish_date ELSE NULL END) AS [Last Log Backup],
	DATABASEPROPERTYEX ((d.[name]), 'LastGoodCheckDbTime') AS [Last Good CheckDB]
FROM sys.databases AS d WITH (NOLOCK)
LEFT OUTER JOIN msdb.dbo.backupset AS bs WITH (NOLOCK)
ON bs.[database_name] = d.[name]
AND bs.backup_finish_date > GETDATE()- 30
WHERE d.name <> N'tempdb'
GROUP BY ISNULL(d.[name], bs.[database_name]), d.recovery_model_desc, d.log_reuse_wait_desc, d.[name]
ORDER BY d.recovery_model_desc, d.[name] OPTION (RECOMPILE);

 --backups duration
select  bs.[database_name], 
    backup_start_date, backup_finish_date, 
	CONVERT(VARCHAR(12), DATEDIFF(SECOND,backup_start_date, backup_finish_date) /60/60/24) + ' - ' 
	 +                   CONVERT(VARCHAR(12), DATEDIFF(SECOND,backup_start_date, backup_finish_date) /60/60 % 24) 
	 + ':' + RIGHT('0' + CONVERT(VARCHAR(2),  DATEDIFF(SECOND,backup_start_date, backup_finish_date) /60 % 60), 2) 
	 + ':' + RIGHT('0' + CONVERT(VARCHAR(2),  DATEDIFF(SECOND,backup_start_date, backup_finish_date) % 60), 2)
    [Duration_Day - h:m:s] /*credit to Aaron Bertrand */,
    CASE WHEN [type] = 'D' then 'FULL'
	    WHEN [type] = 'I' then 'DIFF'
	    WHEN [type] = 'L' then 'LOG'
    ELSE 'OTHER' END as [Backup Type], DATENAME(dw, backup_finish_date) dayOfWeeks
from msdb.dbo.backupset bs
where bs.backup_finish_date > GETDATE()- 30
and [type] = 'D' and bs.[database_name] = 'MedRx'
order by backup_finish_date desc
