-- take a log backup; it will reduce the size of indexes while the full operation is going on
 
 --or
--change the recovery model from to full to simple then back to full

-- switch the database’s recovery model to simple as 
-- shown in Books Online.  
-- This empties out the transaction log, 
-- thereby letting the DBA run a DBCC SHRINKFILE

----or
-- ***DB size: 
EXEC sp_helpdb;
---- https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-shrinkfile-transact-sql?redirectedfrom=MSDN&view=sql-server-ver16
--SELECT file_id, name  
--FROM sys.database_files;  
--GO  
-- DBCC SHRINKFILE reduces to the file creation size.
--use TestBello
--DBCC SHRINKFILE (4, NOTRUNCATE); -- move pages but not returned to OS
--DBCC SHRINKFILE (4, TRUNCATEONLY); ---- return to OS but not moving pages
--DBCC SHRINKFILE (4, TRUNCATEONLY); ---- return to OS but not moving pages
-- DBCC SHRINKFILE (data_fiel_name, <target_size>); --size in megabyte 

CHECKPOINT 
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE



-- No confusion with 
-- BACKUP LOG dbname WITH TRUNCATE_ONLY -- details here https://www.brentozar.com/archive/2009/08/backup-log-with-truncate-only-in-sql-server-2008/
-- the above will break the log chain
-- in simple recovery mode, no log is taken

--or
--shrink log if not enough shrink data
--DBCC SHRINKFILE (data_fiel_name, 148736);  --size in megabyte 
