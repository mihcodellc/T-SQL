-- SYSTEM-VERSIONED TEMPORAL TABLE
CREATE TABLE dbo.Org_T2  
    (  
    EmployeeId hierarchyid PRIMARY KEY
	, LastChild hierarchyid
    , EmployeeName nvarchar(50)
	------generated always as row start/end hidden NEEDED 
	--, sysStart datetime2 (0) generated always as row start hidden not null default GETUTCDATE()
	--, sysEnd datetime2 (0) generated always as row end hidden not null default GETUTCDATE(),
	--PERIOD FOR SYSTEM_TIME(sysStart,sysEnd)
    ) 
--WITH ( SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Org_T2_History))	
GO  


-- add temporal columns
ALTER TABLE dbo.Org_T2 ADD 
--generated always as row start/end hidden NEEDED 
	sysStart datetime2 (0) generated always as row start hidden not null default GETUTCDATE(),
	sysEnd datetime2 (0) generated always as row end hidden not null default GETUTCDATE(),
	PERIOD FOR SYSTEM_TIME(sysStart,sysEnd)
GO


/**Turn ON system-versioning with retention period */
ALTER TABLE dbo.Org_T2
SET (
	SYSTEM_VERSIONING = ON
	(
		HISTORY_TABLE = dbo.Org_T2_History
		, HISTORY_RETENTION_PERIOD = 365 DAYS -- SQL Server 14+ ie 2017
	)
)
GO

/*Turn OFF versioning  -1*/ 
ALTER TABLE dbo.Org_T2
SET (SYSTEM_VERSIONING = OFF)

--revert temporal table to a non-temporal --2
ALTER TABLE dbo.Org_T2
DROP PERIOD FOR SYSTEM_TIME

--now able to drop after turn off & DROP PERIOF SYSTEM_TIME
DROP TABLE dbo.Org_T2



-- query on all OR a date
DECLARE @t DATETIME2 = GETUTCDATE(), @t2 DATETIMEOFFSET 
SELECT * 
FROM dbo.Org_T2
--FOR SYSTEM_TIME AS OF @t
FOR SYSTEM_TIME ALL 



-- hierarchyid
DECLARE @hid hierarchyid = '/1/2/3'
SELECT @hid 'AS varbinary', @hid.ToString()


-- SQL Server Change Tracking
-- https://learn.microsoft.com/en-us/sql/relational-databases/track-changes/work-with-change-tracking-sql-server?view=sql-server-ver16
-- Enable snapshot isolation
ALTER DATABASE AdventureWorks
SET READ_COMMITTED_SNAPSHOT ON
GO
ALTER DATABASE AdventureWorks
SET ALLOW_SNAPSHOT_ISOLATION ON
GO
--enable tracking on DB
ALTER DATABASE AdventureWorks
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 5 DAYS, AUTO_CLEANUP = ON)
--To enable Change Tracking in SQL Server Management Studio
Right click the database in Object Explorer
Select Properties
Select the Change Tracking tab
--enable tracking on table
ALTER TABLE Person.Address
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON)
declare @synchronization_version bigint;
-- Obtain the current synchronization version. This will be used next time that changes are obtained.
SET @synchronization_version = CHANGE_TRACKING_CURRENT_VERSION();

-- Check all tables with change tracking enabled
IF EXISTS (
  SELECT 1 FROM sys.change_tracking_tables
  WHERE min_valid_version > @synchronization_version )
BEGIN
  -- Handle invalid version & do not enumerate changes
  -- Client must be reinitialized
  print 'hello'
END
-- Obtain incremental changes by using the synchronization version obtained the last time the data was synchronized.
SELECT
    CT.MyTableID, P.InsCoName,
    CT.SYS_CHANGE_OPERATION, CT.SYS_CHANGE_COLUMNS,
    CT.SYS_CHANGE_CONTEXT
FROM
    dbo.MyTable AS P
RIGHT OUTER JOIN
    CHANGETABLE(CHANGES dbo.LockBoxDocumentAnydoc, @synchronization_version) AS CT
ON
    P.MyTableID = CT.MyTableID
WHERE P.MyTableID in (168979638, 168989653) 


