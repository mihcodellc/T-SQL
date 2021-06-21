----------------------
-- Presetup
----------------------
-- install script sp_blocked_process_report_viewer to master so you can view it SQL management studio or 
-- you can view the tracer file in profiler

----------------------
-- make advance option
----------------------
--Make sure you don't have any pending changes
--SELECT *
--FROM sys.configurations
--WHERE value <> value_in_use;
--GO

-- sp_configure to Display or change global configuration settings in the view "sys.configurations"  for the current server.
-- the view "sys.configurations" tell us is_dynamic, is_advanced
-- exec sp_configure without paramters to show the options list
-- select * from sys.configurations
exec sp_configure 'show advanced options', 1; -- 
GO
RECONFIGURE
GO
--https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/blocked-process-threshold-server-configuration-option?view=sql-server-2017
exec sp_configure 'blocked process threshold (s)', 10;  -- 10 seconds  at which blocked process reports are generated
GO
RECONFIGURE
GO

----------------------
-- create traces
----------------------
-- Created by: SQL Server 2012  Profiler
-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
declare @DateTime datetime

---------Added a function here:
set @DateTime = DATEADD(mi,2,getdate());  /* Run for 2hr minutes */
set @maxfilesize = 40

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

-----------Set my filename here:
--https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-trace-create-transact-sql?view=sql-server-2017
-- return the TraceID
exec @rc = sp_trace_create @TraceID output, 0, N'C:\Samples\BlockedProcessReportDemo', @maxfilesize, @Datetime
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
--https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-trace-setevent-transact-sql?view=sql-server-2017
--sp_trace_setevent [ @traceid = ] trace_id   
--          , [ @eventid = ] event_id  
--          , [ @columnid = ] column_id  
--          , [ @on = ] on  
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 137, 1, @on -- 137 for Blocked Process Report, event ID, 1 for TextData 
exec sp_trace_setevent @TraceID, 137, 12, @on --12 for Server Process ID SPID

-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error:
select ErrorCode=@rc

finish:
go


C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\DATA
----------------------
-- check your trace id
----------------------
SELECT * from sys.traces;
GO


---------------------
-- check the report
----------------------
exec dbo.sp_blocked_process_report_viewer
	@Source='C:\Samples\BlockedProcessReportDemo.trc';
GO
--dbo.sp_blocked_process_report_viewer
--dbo.sp_blocked_process_report_viewer
--

-- there is 2 thing to pay attention. 
-- 1. is <blocked-process> describes the session that was blocked 
-- 2. <blocking-process> describes the session that currently holds the incompatible lock on the resource, on which the other session wants to acquire the lock. The most important part here is the XML element <inputbuf> which shows the SQL statement that acquired the incompatible lock

--------------------------------------
-- turn off the trace
-------------------------------------
--stop the trace
EXEC sp_trace_setstatus @traceid =2, @status = 0;
GO
--stop the trace
EXEC sp_trace_setstatus @traceid =2, @status = 2;
GO



--------------------------------
--clean the trace
--------------------------------
----Make sure your trace is gone
--SELECT * from sys.traces;
--GO

----Turn off the blocked process report when you're not using it.
----Make sure you don't have any pending changes
--SELECT *
--FROM sys.configurations
--WHERE value <> value_in_use;
--GO

exec sp_configure 'blocked process threshold (s)', 0;-- O second at which blocked process reports are generated
GO
RECONFIGURE
GO

exec sp_configure 'blocked process threshold (s)';
GO

--------------------------
-- turn off advance option
--------------------------

exec sp_configure 'show advanced options', 0;
GO
