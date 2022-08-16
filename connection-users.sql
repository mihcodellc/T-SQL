-- connection-users
ALTER USER mbello
WITH NAME = mbello
, LOGIN = mbello
, DEFAULT_SCHEMA = dbo
, PASSWORD = 'W1r77TT98%ab@#' OLD_PASSWORD = 'New Devel0per'
, DEFAULT_LANGUAGE= English ;
GO

--data compression or estimate with sp_estimate_data_compression_savings 
ALTER TABLE MyTable 
	REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ROW); -- row, page OR sparse column(null values)
	
-- SQL Agent in failover	
--Windows Cluster Administrator WCA
--brought online SQL Server Agent IN failover cluster configuration	