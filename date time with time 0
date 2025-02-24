select CONVERT(date,getdate(),101) ,  CONVERT(VARCHAR(10), getdate(), 101)  , convert(datetime,convert(char(10),GETDATE(),110),110)


--To determine the offset dynamically and apply it to GETDATE():
SELECT TODATETIMEOFFSET(GETDATE(), DATEPART(TZOFFSET, SYSDATETIMEOFFSET())) AS LocalDateTimeOffset;

--To convert GETDATE() to a datetimeoffset in SQL Server, use the TODATETIMEOFFSET function
--Replace +00:00 with your desired time zone offset (e.g., -05:00 for Eastern Time).
SELECT TODATETIMEOFFSET(GETDATE(), '+00:00') AS DateTimeOffsetUTC;

--example in a query
select top 10 * from dbo.BlitzCache
where 
queryType not like '%DatabaseBackup%'
and
CheckDate between TODATETIMEOFFSET(dateadd(mi,-30, getdate()), '-06:00') and  TODATETIMEOFFSET(GETDATE(), '-06:00')
--and QueryText like '%xxx%' 
order by averageCPU desc, averageReads desc, executionsPerMinute desc


SELECT 'SYSDATETIME()      ', SYSDATETIME();  
SELECT 'SYSDATETIMEOFFSET()', SYSDATETIMEOFFSET();  
SELECT 'SYSUTCDATETIME()   ', SYSUTCDATETIME();  
SELECT 'CURRENT_TIMESTAMP  ', CURRENT_TIMESTAMP;  
SELECT 'GETDATE()          ', GETDATE();  
SELECT 'GETUTCDATE()       ', GETUTCDATE();
