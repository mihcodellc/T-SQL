-- https://www.mssqltips.com/sqlservertip/6057/sql-server-trigger-best-practices/#:~:text=SQL%20Server%20Trigger%20Best%20Practices%201%201%20-,Perform%20Validations%20First%20for%20SQL%20Server%20Triggers%20
create TRIGGER [dbo].[Tr_History]
ON [dbo].[LockboxDocumentTracking]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	------------------------------------------------------------------------------------------
	

	-- Prevent recursively calling yourself.
	IF trigger_nestlevel() > 1 RETURN;

        -- prevent unnecessary trip 
	IF (@@ROWCOUNT = 0)  RETURN;
	
	/**YOUR statements**/
end
GO
--Specifies the AFTER triggers that are fired first or last after @stmttype
EXEC sp_settriggerorder @triggername=N'[dbo].[Tr_History]', @order=N'Last', @stmttype=N'DELETE'
GO
EXEC sp_settriggerorder @triggername=N'[dbo].[Tr_History]', @order=N'Last', @stmttype=N'INSERT'
GO
EXEC sp_settriggerorder @triggername=N'[dbo].[Tr_History]', @order=N'Last', @stmttype=N'UPDATE'

