--dbcc checkdb with all_errormsgs, no_infomsgs, tableresults
select * from msdb.dbo.suspect_pages
  
-- check important alerts are created. used "Add_important_SQL_Agent _Alerts.sql" to create them
-- check alert scheduled.
Select 'SQL Agent Alerts'
SELECT name, severity, enabled, delay_between_responses, database_name FROM msdb.dbo.sysalerts
