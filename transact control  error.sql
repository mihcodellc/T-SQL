SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; 
--set transaction isolation level read uncommitted

-- SET LOCK_TIMEOUT 2000 -- in milliseconds -- If another query does not release the lock in 2000 => error msg 1222
-- SELECT @@LOCK_TIMEOUT

SET XACT_ABORT ON --rollback is certain
BEGIN TRY
    BEGIN TRAN
		  EXEC(@query)
    COMMIT TRAN
END TRY
BEGIN CATCH
    IF @@TRANCOUNT <> 0 
    BEGIN
	    DECLARE @ErrorMessage NVARCHAR(4000);  
            DECLARE @ErrorSeverity INT;  
            DECLARE @ErrorState INT;  

            SELECT @ErrorMessage = ERROR_MESSAGE(),  
                   @ErrorSeverity = ERROR_SEVERITY(),  
                   @ErrorState = ERROR_STATE();  
		--,ERROR_PROCEDURE() AS ErrorProcedure
                 --,ERROR_LINE() AS ErrorLine

	   -- https://learn.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql?view=sql-server-ver16
	   --statement before the THROW statement must be followed by the semicolon (;) statement terminator
	   ROLLBACK TRAN
	   --RAISERROR ( 'msg', 16, 1 ) WITH LOG; -- Logs the error in the error log and the application log for the instance of the Microsoft SQL Server Database
           --EXEC xp_logevent 60000, 'msg', informational; -- INFORMATIONAL, WARNING, or ERROR - Logs a user-defined message in the SQL Server log file and in the Windows Event log
	   THROW; -- re raise error from begin try
	   RETURN -1
    END
    ELSE
	   RETURN 0
END CATCH

SET XACT_ABORT OFF --auto rollback disabled
