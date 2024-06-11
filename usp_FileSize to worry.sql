 --6/11/2024: initial version: Monktar Bello 
 --Run Example: exec DBA_DB.dbo.usp_FileSize


	declare @WorryThreshold_perc tinyint = 85 
	declare @WorryThreshold_size_inMB int =  400000 --400GB

	declare @WorryFileList varchar(1000)= 'Size greater than ' + cast(@WorryThreshold_size_inMB as varchar(7)) 
	+ 'MB and has consumed more than  ' + cast(@WorryThreshold_perc as varchar(7)) + '% of current size.' +char(10)+char(13) 
	+'Data files filling up, it can be an issue soon. DBA needs to worry about !!!' +char(10)+char(13)
	+'The following files need your attention: '+char(10)+char(13)
	declare @WorryFileList_Draft varchar(1000) =''



	DECLARE @fillUp TABLE ([dbname] [nvarchar](128) NULL,
	[physical_name] [nvarchar](260) NULL,
	[logic_name] [sysname] NOT NULL,
	FileGroup [sysname] NOT NULL,
	[size_MB] [numeric](17, 6) NULL,
	[InternalUsedSpace] [numeric](17, 6) NULL,
	[max_size_MB] [numeric](17, 6) NULL,
	[growth_MB] [numeric](17, 6) NULL,
	[is_percent_growth] [bit] NOT NULL,
	[HowCloseToSizeonDisk_perc] [numeric](38, 17) NULL,
	[dateinsert] [datetime] NOT NULL,
	[HowCloseToDesireMaxOnDisk_perc] [numeric](32, 17) NULL)

	INSERT INTO @fillUp
	EXEC sp_ineachdb @command = 
		N'
    declare @DesireMax int = 512000 -- ie =512GB before creating a new datafile
    -- don''t let go beyond "HowCloseToDesireMaxOnDisk"
    -- when HowCloseToDesireMaxOnDisk ~ 100%, make sure to create a new datafile before HowCloseToSizeonDisk reached 100% then max ie limit the one close to 100%

    select DB_NAME() as dbname, df.physical_name, df.name as logic_name,Isnull(ds.name,''N/A'') as FileGroup, df.size/128.0 as size_MB, CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0 as InternalUsedSpace, 
    case when df.max_size > 0 then df.max_size/128.0 else df.max_size end as max_size_MB, df.growth/128.0 growth_MB, df.is_percent_growth, 
    -- useSpace out of current size / current size 
    (CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0/(df.size/128.0))*100 as HowCloseToSizeonDisk_perc, getdate() as dateinsert
    ,(df.size/128.0/@DesireMax)*100 as HowCloseToDesireMaxOnDisk_perc 
    FROM sys.database_files [df]
    left JOIN [sys].[data_spaces] [ds] ON [ds].[data_space_id] = [df].[data_space_id]
    ORDER BY logic_name, df.size
	;'

     SELECT @WorryFileList_Draft = STRING_AGG (CONVERT(VARCHAR(1000),physical_name), CHAR(13)+CHAR(10)) 
	FROM(
	select top 100 physical_name, logic_name from @fillUp
	where dateinsert > convert(datetime2,replace(convert(CHAR(10), GETDATE(), 112),'-',''))
	and [HowCloseToSizeonDisk_perc] > @WorryThreshold_perc and size_MB > @WorryThreshold_size_inMB
	and logic_name not in (
	--the exceptions have already an additional datafile and likely unlimited
    'Archive',
    'MedRx_Data',
    'MedRx_Data_2',
    'MedRx_Data_3',
    'MedRx_Data_4',
    'LockBoxData_1'
	    )
	    order by logic_name
	    ) ft


	set @WorryFileList= @WorryFileList + @WorryFileList_Draft

	--debug
	--select @WorryFileList



	---***e-mail
    DECLARE @ServerName VARCHAR(25);
    DECLARE @Email_Body VARCHAR(400);
    DECLARE @Email_subject VARCHAR(100);

    DECLARE @dbid INT, @KillStatement char(30), @SysProcId smallint, @DB char(50) = db_name()

    SET @ServerName = CAST((SELECT SERVERPROPERTY('MachineName') AS [ServerName]) AS VARCHAR(25))
    SET @Email_subject = 'DBA: DataFiles'' sizes in need of action soon!!! ' 

    SET @Email_Body = @WorryFileList

    EXEC msdb.dbo.sp_send_dbmail 
			  @body = @Email_Body
			 ,@body_format = 'TEXT'
			 ,@profile_name = N'AProfile'
			 ,@recipients = N'db_maintenance@mih.com'
			 --,@recipients = N'mbello@mih.com'
			 ,@Subject = @Email_subject
			 ,@importance = 'High' 
