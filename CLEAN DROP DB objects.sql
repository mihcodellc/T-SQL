--tables
SELECT 
 --'ALTER TABLE [' + s.name + '].[' + t.name + '] NOCHECK CONSTRAINT all;' + CHAR(13) + CHAR(10) FROM 
  'DROP TABLE IF exists [' + s.name + '].[' + t.name + '] ;' + CHAR(13) + CHAR(10) FROM 

sys.tables AS t --ON fk.parent_object_id = t.object_id
    INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
	where t.type='U'

	--views
SELECT 
 --'ALTER TABLE [' + s.name + '].[' + t.name + '] NOCHECK CONSTRAINT all;' + CHAR(13) + CHAR(10) FROM 
  'DROP VIEW IF exists [' + s.name + '].[' + t.name + '] ;' + CHAR(13) + CHAR(10) FROM 

sys.views AS t --ON fk.parent_object_id = t.object_id
    INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id


	--functions
	SELECT 
 --'ALTER TABLE [' + s.name + '].[' + t.name + '] NOCHECK CONSTRAINT all;' + CHAR(13) + CHAR(10) FROM 
  'DROP FUNCTION IF exists [' + s.name + '].[' + t.name + '] ;' + CHAR(13) + CHAR(10) FROM 

sys.objects AS t --ON fk.parent_object_id = t.object_id
    INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
	where t.type in ('FN','FS', 'IF', 'TF')


	--PROC
	SELECT 
 --'ALTER TABLE [' + s.name + '].[' + t.name + '] NOCHECK CONSTRAINT all;' + CHAR(13) + CHAR(10) FROM 
  'DROP PROC IF exists [' + s.name + '].[' + t.name + '] ;' + CHAR(13) + CHAR(10) FROM 

sys.objects AS t --ON fk.parent_object_id = t.object_id
    INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
	where t.type in ('P')

	select distinct type,type_desc from sys.objects where type_desc like '%proc%'
