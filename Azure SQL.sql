--details space used
declare @t table (database_name nvarchar(128), database_Data_Log nvarchar(128), unallocated_space nvarchar(128), reserved nvarchar(128), 
data nvarchar(128), index_size nvarchar(128), unused nvarchar(128))

insert into @t
EXEC sp_spaceused @oneresultset = 1 
select database_name,   
cast(substring(database_Data_Log,0,CHARINDEX(' ', database_Data_Log)) as float) [database_Data_Log_MB = CurrentSizeOnDisk],
convert(float,(substring(unallocated_space,0,CHARINDEX(' ', unallocated_space)))) unallocated_MB,
cast(substring(reserved,0,CHARINDEX(' ', reserved)) as float)/1000 [reserved_MB /*= data + Index + Unused*/],
cast(substring(data,0,CHARINDEX(' ', data)) as float)/1000 data_MB,
convert(float,(substring(index_size,0,CHARINDEX(' ', index_size))))/1000 index_size_MB,
cast(substring(unused,0,CHARINDEX(' ', unused)) as float)/1000 unused_MB, GETDATE() as Whe_n 
 from @t
 order by [database_Data_Log_MB = CurrentSizeOnDisk] desc


--db property
SELECT Edition = DATABASEPROPERTYEX('MyDatabase', 'EDITION'),
        ServiceObjective = DATABASEPROPERTYEX('MyDatabase', 'ServiceObjective'),
        MaxSizeInBytes =  DATABASEPROPERTYEX('MyDatabase', 'MaxSizeInBytes');

-- Modifies certain configuration options of a database.
--https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql?view=azuresqldb-current&preserve-view=true&tabs=sqlpool
--alter max_size not sure if size itself can be resize
--ALTER DATABASE [RemitHub_Production] MODIFY (EDITION = 'Standard', MAXSIZE = 1024GB, SERVICE_OBJECTIVE = 'S7');



--Resource limits for single databases using the DTU purchasing model
https://learn.microsoft.com/en-us/azure/azure-sql/database/resource-limits-dtu-single-databases?view=azuresql


--Run Scheduled Jobs in Azure SQL Databases
-- https://www.sqlservercentral.com/articles/how-to-run-scheduled-jobs-in-azure-sql-databases
1 - create the job in local instance and its SQL Agent
2 - use sqlcmd or powershell script
3 - sqlcmd - U daniel -d sqlcentralazure -S sqlservercentralserver.database.windows.net -P "YourAzurePassword" -i c:\script\todaysales.sql -o c:\script\azureoutput.txt

--automate tasks using elastic jobs
-- https://learn.microsoft.com/en-us/azure/azure-sql/database/job-automation-overview?view=azuresql
