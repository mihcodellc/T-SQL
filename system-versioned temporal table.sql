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
