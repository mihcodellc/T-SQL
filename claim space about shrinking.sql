more research after I saw the output of 

EXEC sp_spaceused @oneresultset = 1  
how can I reclaim the unallocated space? without using the shrink command.



I found that 

database_size is generally larger than the sum of reserved + unallocated space because it includes the size of log files, but reserved and unallocated_space consider only data pages. (ref. [#[sp_spaceused (Transact-SQL) - SQL Server | Microsoft Docs|https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-spaceused-transact-sql?view=sql-server-ver16]]



No other solution found except shrinking the file but

Shrinking files can lead to serious fragmentation issues at the OS level that are not easily fixed. 
ref: https://ask.sqlservercentral.com/questions/113796/how-to-reduce-unallocated-space.html

--***Remove the datafile  
--Empty the file
DBCC SHRINKFILE (Solutions2, EMPTYFILE);  
GO 
--Remove the file
ALTER DATABASE Solutions REMOVE FILE Solutions2;  
GO  

other solution maybe #[https://www.brentozar.com/blitz/transaction-log-larger-than-data-file/

https://www.brentozar.com/archive/2009/08/stop-shrinking-your-database-files-seriously-now/
