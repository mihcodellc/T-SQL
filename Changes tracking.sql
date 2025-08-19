--https://learn.microsoft.com/en-us/sql/relational-databases/track-changes/track-data-changes-sql-server?view=sql-server-ver16

--https://learn.microsoft.com/en-us/sql/relational-databases/track-changes/work-with-change-tracking-sql-server?view=sql-server-ver16

--https://learn.microsoft.com/en-us/sql/relational-databases/system-functions/change-tracking-current-version-transact-sql?view=sql-server-ver17

--https://www.youtube.com/watch?v=XLMMDtOxDAA

--https://learn.microsoft.com/en-us/sql/relational-databases/track-changes/work-with-change-tracking-sql-server?view=sql-server-ver16

--ALTER DATABASE AdventureWorks2022  
--SET CHANGE_TRACKING = ON  
--(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON)

--***ATTENTION TO CHANGE_RETENTION = 2 DAYS IF NOT DONE ON TIME, YOU MAY LOOSE DATA OR BIGGER DB IF KEPT TOO LONG

ALTER DATABASE AdventureWorks2022  
SET CHANGE_TRACKING = OFF

--ALTER TABLE Person.Contact  
--ENABLE CHANGE_TRACKING  
--WITH (TRACK_COLUMNS_UPDATED = ON)


ALTER TABLE Person.Contact  
DISABLE CHANGE_TRACKING;

--Find the tracking/dDB tables
select OBJECT_NAME(object_id) tracking_table, OBJECT_NAME(parent_object_id) tracked_table, create_date, modify_date * from sys.internal_tables
where parent_object_id >=1

select OBJECT_NAME(object_id) [table], *  from sys.change_tracking_tables 

select db_name(database_id) [database], *  from sys.change_tracking_databases

--tracking history
select * from dbo.MSchange_tracking_history



--When an application obtains changes, it must use both CHANGETABLE(CHANGES...)
--and CHANGE_TRACKING_CURRENT_VERSION(), as shown in the following example.

--***1st get the change and update the destination
declare @last_synchronization_version bigint, @last_synchronization_version_next bigint;

SELECT
    CT.ProductID, 
    CT.SYS_CHANGE_OPERATION, CT.SYS_CHANGE_COLUMNS,
    CT.SYS_CHANGE_CONTEXT,
	P.* -- all column for action
FROM
    SalesLT.Product AS P
RIGHT OUTER JOIN -- account for deletion
    CHANGETABLE(CHANGES SalesLT.Product, @last_synchronization_version) AS CT
ON     P.ProductID = CT.ProductID;

-- Obtain the current synchronization version. This will be used the next time CHANGETABLE(CHANGES...) is called.
--save it for the nex time
SET @last_synchronization_version_next = CHANGE_TRACKING_CURRENT_VERSION();

--are @last_synchronization_version_next vs @last_synchronization_version are different? if so, what happen to the changes issued 
--between when both  are set?

--***2nd retrieve last @last_synchronization_version and used it in the following
-- Obtain incremental changes by using the synchronization version obtained the last time the data was synchronized.

--Validation before using it
-- Check all tables with change tracking enabled
IF EXISTS (
  SELECT 1 FROM sys.change_tracking_tables
  WHERE min_valid_version > @last_synchronization_version )
BEGIN
  -- Handle invalid version & do not enumerate changes
  print 'Client must be reinitialized'
  RAISERROR(N'Oops! No,  invalid version. Client must be reinitialized', 20, 1) WITH LOG;
  return 
END;

--if valid then check and use it to synch
SELECT
    CT.ProductID, P.Name, P.ListPrice,
    CT.SYS_CHANGE_OPERATION, CT.SYS_CHANGE_COLUMNS,
    CT.SYS_CHANGE_CONTEXT
FROM
    SalesLT.Product AS P
RIGHT OUTER JOIN
    CHANGETABLE(CHANGES SalesLT.Product, @last_synchronization_version) AS CT
ON
    P.ProductID = CT.ProductID;
