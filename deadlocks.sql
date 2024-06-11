--Enable to allow deadlock to be captured in log

  
-- Enable trace flag 1222 globally
DBCC TRACEON (1222, -1);

-- Verify that the trace flag is enabled
DBCC TRACESTATUS (1222, -1);

-- Simulate some operations that might cause a deadlock (this step depends on your specific scenario)

-- Check the SQL Server error log for deadlock information
EXEC xp_readerrorlog 0, 1, N'Deadlock';

-- Optionally, disable the trace flag once done
DBCC TRACEOFF (1222, -1);
