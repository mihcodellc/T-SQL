-- https://learn.microsoft.com/en-us/sql/database-engine/deprecated-database-engine-features-in-sql-server-2016?view=sql-server-ver16
-- https://learn.microsoft.com/en-us/sql/database-engine/discontinued-database-engine-functionality-in-sql-server?view=sql-server-ver16

SELECT * FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Deprecated Features';

-- Editions & Features 
https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2019?view=sql-server-ver16#Cross-BoxScaleLimits
-- capacity limit
https://learn.microsoft.com/en-us/sql/sql-server/maximum-capacity-specifications-for-sql-server?view=sql-server-ver16


Hard Disk	                           +6 GB of available hard-disk space
All Features	                       8030 MB
Database Engine and data files,        1480 MB
    Replication, Full-Text Search, 
    and Data Quality Services	
    
Memory *	Minimum: 
      Express Editions: 512 MB recommanded 1GB
      All other editions: 1 GB recommanded 4GB
      
Processor:   *   Minimum:      x64 Processor: 1.4 GHz recommanded 2.0 GHz   

https://learn.microsoft.com/en-us/sql/sql-server/compute-capacity-limits-by-edition-of-sql-server?view=sql-server-ver16
Developer:	Operating system maximum	Operating system maximum
Standard:	Limited to lesser of 4 sockets or 24 cores	Limited to lesser of 4 sockets or 24 cores
Express:	Limited to lesser of 1 socket or 4 cores	Limited to lesser of 1 socket or 4 cores
