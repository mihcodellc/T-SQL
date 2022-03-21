-- you can still use the report(all executions and drill down or filter) on ssisdb
-- OR 
--change the @mydate and 
-- replace execution_id on 2nd table by the one to investigate from table 1 
--then on the 4th table use the event_message_id on 3rd - 3
declare @mydate datetime = '20220301'

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT distinct inf.[execution_id]
      ,[folder_name]
      ,[project_name]
      ,inf.[package_name]
      ,[operation_type]
      ,[created_time]
      ,[status]
      ,inf.[start_time]
      ,inf.[end_time]
      ,[caller_name]
      ,[process_id]
      ,[stopped_by_name]
  FROM SSISDB.internal.execution_info inf
  join [SSISDB].[catalog].[executable_statistics] stat 
    on inf.execution_id = stat.execution_id
  where folder_name = 'merlin' and inf.start_time  > @mydate --and inf.start_time  < '20220317' --and  inf.execution_id  = 1772073
  and stat.execution_result in (1,2,3) -- 1 Failure,  2 Completion 3 Cancelled
  --convert(DATETIME, convert(CHAR(10), GETDATE(), 110), 110)


  /****** packages steps  ******/
SELECT TOP (1000) [statistics_id]
      ,[execution_id]
      ,[executable_id]
      ,[execution_path]
      ,[start_time]
      ,[end_time]
      ,[execution_duration]
      ,[execution_result]
      ,[execution_value]
  FROM [SSISDB].[catalog].[executable_statistics]
  where start_time > @mydate and execution_id  = 1772004


  --- packages events
  SELECT [event_message_id]
      ,[operation_id]
      ,[message_time]
      ,[message_type]
      ,[message_source_type]
      ,[message]
      ,[extended_info_id]
      ,[package_name]
      ,[event_name]
      ,[message_source_name]
      ,[message_source_id]
      ,[subcomponent_name]
      ,[package_path]
      ,[execution_path]
      ,[threadID]
      ,[message_code]
      ,[event_message_guid]
  FROM [SSISDB].[catalog].[event_messages]
   where  operation_id in(1772004)
   and event_name in ('OnTaskFailed')


   --packages events prior to the fail
   SELECT [event_message_id]
      ,[operation_id]
      ,[message_time]
      ,[message_type]
      ,[message_source_type]
      ,[message]
      ,[extended_info_id]
      ,[package_name]
      ,[event_name]
      ,[message_source_name]
      ,[message_source_id]
      ,[subcomponent_name]
      ,[package_path]
      ,[execution_path]
      ,[threadID]
      ,[message_code]
      ,[event_message_guid]
  FROM [SSISDB].[catalog].[event_messages]
   where  event_message_id > 124576172 and operation_id in(1772004)
