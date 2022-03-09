

--events for a trigger
select  *from sys.trigger_event_types order by type_name

-- https://docs.microsoft.com/en-us/sql/relational-databases/triggers/ddl-event-groups?view=sql-server-ver15
--trigger event hierarchies
;WITH DirectReports(name, parent_type, type, level, sort) AS   
(  
    SELECT CONVERT(varchar(255),type_name), parent_type, type, 1, CONVERT(varchar(255),type_name)  
    FROM sys.trigger_event_types   
    WHERE parent_type IS NULL  
    UNION ALL  
    SELECT  CONVERT(varchar(255), REPLICATE ('|   ' , level) + e.type_name),  
        e.parent_type, e.type, level + 1,  
    CONVERT (varchar(255), RTRIM(sort) + '|   ' + e.type_name)  
    FROM sys.trigger_event_types AS e  
        INNER JOIN DirectReports AS d  
        ON e.parent_type = d.type   
)  
SELECT level,parent_type, type, name  
FROM DirectReports  
where parent_type = 10016
ORDER BY sort;


select name from sys.objects
where type ='tr' order by name



--DATABASE
-- event related to existing trigger
select distinct type, type_desc from sys.trigger_events 
-- info about trigger
select name, object_id
	   , case when parent_class = 0 then 'Database, for the DDL triggers' 
		  when parent_class = 1 then ' Object or column for the DML triggers'
	   end as parent
	   , parent_class_desc, type_desc, create_date as 'TR created the ', modify_date as 'TR modified'
	   , is_disabled,is_instead_of_trigger, is_ms_shipped
from sys.triggers

--SERVER
-- event related to existing trigger
select * from sys.server_trigger_events
-- Info about trigger
select * from sys.server_triggers


--sp_helptext 'tr_MScdc_db_ddl_event' 
select * from sys.server_sql_modules


 