trace flag list  & query hint
--https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-traceon-transact-sql?view=sql-server-ver15
--https://docs.microsoft.com/en-US/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver15#examples
--https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-traceon-trace-flags-transact-sql?view=sql-server-ver15

  in services.msc, start the sql service an error should pop up with more details or continue reading the next step below:
  
-- server restart failed after patch/update
  --in cmd promt
  net start MSSQL$SQLEXPRESS /T902
  or 
  -T 902 -- in configuration manager
  --then back and forth between read the log and restart SQL server service to fix the errors from the last to the top
  --if the root cause is Account permission use this "Update grant_permiss_user_not_found.ps1"
  
--Enables the specified trace flags. on command line with -T 
--OR 
--DBCC TRACEON ( trace# [ ,...n ][ , -1 ] ) [ WITH NO_INFOMSGS  
--DBCC TRACEOFF ( trace# [ ,...n ] [ , -1 ] ) [ WITH NO_INFOMSGS ]
--OR
DBCC TRACEON (8606,3604)
DBCC TRACEOFF (8606,3604, -1) -- -1 glogally ie allsessions

SELECT * FROM Person.Address  
OPTION (QUERYTRACEON 8606, QUERYTRACEON 3604); 
--OPTION (MERGE JOIN);
--OPTION ( OPTIMIZE FOR (@city_name = 'Seattle', @postal_code UNKNOWN) );
--OPTION (MAXRECURSION 2); 

--display input tree passed to the optimizer using trace flag 8606
--redirect the output of some DBCC  to the result window using trace flag TF 3604

