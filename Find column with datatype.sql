-- columns, datatype, table from your database
SELECT OBJECT_SCHEMA_NAME(a.object_id), OBJECT_NAME(a.object_id), a.name,b.type_desc,  b.type 
FROM sys.all_columns a 
JOIN sys.all_objects b on a.object_id = b.object_id
JOIN sys.types t on a.user_type_id = t.user_type_id
WHERE a.name like '%lo%' and b.type ='U' and t.name in ('int','smallint', 'numeric', 'bigint')
