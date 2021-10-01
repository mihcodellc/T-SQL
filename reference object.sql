SELECT *  FROM sys.dm_sql_referencing_entities ('Apps.Annoucements', 'OBJECT'); 
SELECT DISTINCT referenced_schema_name, referenced_entity_name,is_updated, is_selected /*, referenced_minor_name 'Columns'*/ FROM sys.dm_sql_referenced_entities  ('Apps.Annoucements', 'OBJECT') 
--SELECT * FROM  sys.objects where name='sp_Report_AgencyStatistic' 
SELECT OBJECT_NAME(object_id),* FROM  sys.sql_dependencies where OBJECT_NAME(object_id)='Apps.Annoucements' 
SELECT * FROM sys.dm_sql_referenced_entities  ('Apps.Annoucements', 'OBJECT') 


select distinct OBJECT_NAME(object_id) nom,name  from sys.columns where name like '%patien%' order by nom
select distinct OBJECT_NAME(object_id) nom,name  from sys.columns where name like '%sign%' order by nom