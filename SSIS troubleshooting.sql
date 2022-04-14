-- you can still use the report(all executions and drill down or filter) on ssisdb
-- OR 
--change the @mydate using the first query 
--then on the 4th table use the event_message_id on 3rd - 3
declare @mydate datetime = convert(DATETIME, convert(CHAR(10), dateadd(dd,-1,GETDATE()), 110), 110)

select @mydate as [start], dateadd(dd,2,@mydate) [end]

/****** info if no rows ie succeed ******/
SELECT  inf.[execution_id]
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
  join [SSISDB].catalog.executable_statistics stat 
    on inf.execution_id = stat.execution_id
  where folder_name = 'merlin' and inf.start_time between @mydate and dateadd(dd,2,@mydate) 
  and stat.execution_result in (1,2,3) -- 1 Failure,  2 Completion 3 Cancelled, 0 Success
  --convert(DATETIME, convert(CHAR(10), GETDATE(), 110), 110)
  order by inf.start_time desc

  /****** statistics  ******/
SELECT [statistics_id]
      ,[execution_id]
      ,[executable_id]
      ,[execution_path]
      ,[start_time]
      ,[end_time]
      ,[execution_duration]
      ,[execution_result]
      ,[execution_value]
  FROM [SSISDB].[catalog].[executable_statistics] st
  where start_time between @mydate and dateadd(dd,1,@mydate)
	   and exists (select 1 from SSISDB.internal.execution_info inf where inf.execution_id  = st.execution_id and inf.start_time between @mydate and dateadd(dd,2,@mydate))
  order by start_time desc

 /****** event_messages  ******/
  SELECT  [event_name]
       ,[package_name]
       ,[message_source_name]
	  ,[execution_path]
      ,[operation_id]
      ,[message_time]
      ,[message_type]
      ,[message_source_type]
      ,[message]
      ,[extended_info_id]
      ,[message_source_id]
      ,[subcomponent_name]
      ,[package_path]
      ,[threadID]
      ,[message_code]
      ,[event_message_guid]
	 ,[event_message_id]
  FROM [SSISDB].[catalog].[event_messages] msg
   where  
   event_name in ('OnTaskFailed', 'OnError', 'OnWarning') 
   and  
   exists (select 1 from SSISDB.internal.execution_info inf 
		  where inf.execution_id  = msg.operation_id and inf.start_time between @mydate and dateadd(dd,2,@mydate))
order by message_time desc
