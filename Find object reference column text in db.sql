-- dynamic views
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views?view=sql-server-ver15
SELECT OBJECTPROPERTY(OBJECT_ID(referencing_entity_name), 'IsTable') AS [IsTable], *  
FROM sys.dm_sql_referencing_entities ('dbo.AnObject', 'OBJECT'); -- schema included in the name

SELECT DISTINCT referenced_schema_name, referenced_entity_name,is_updated, is_selected 
FROM sys.dm_sql_referenced_entities  ('dbo.AnObject', 'OBJECT')  -- schema included in the name

-- more here https://www.mssqltips.com/sqlservertip/2999/different-ways-to-find-sql-server-object-dependencies/
--- ***objects referenced by other databases:	
SELECT OBJECT_NAME (referencing_id),
              referenced_database_name, 
       referenced_schema_name, referenced_entity_name
FROM sys.sql_expression_dependencies d
WHERE OBJECT_NAME(d.referenced_id) = 'TableName'
      AND OBJECT_DEFINITION (referencing_id)  LIKE '%ColumnName%'
ORDER BY OBJECT_NAME(referencing_id);	

SELECT  OBJECT_NAME (referencing_id) AS referencing_object, referenced_database_name, 
     referenced_schema_name, referenced_entity_name
FROM sys.sql_expression_dependencies
WHERE referenced_database_name IS NOT NULL
      AND is_ambiguous = 0
order by 4

SELECT OBJECTPROPERTY(object_id, 'IsTable') AS [IsTable],
OBJECTPROPERTY(object_id, 'IsPrimaryKey') AS [IsPrimaryKey],
OBJECTPROPERTY(object_id, 'IsForeignKey') AS [IsForeignKey],
OBJECTPROPERTY(object_id, 'IsTrigger') AS [IsTrigger],
OBJECTPROPERTY(object_id, 'IsView') AS [IsView],
OBJECTPROPERTY(object_id, 'IsProcedure') AS [IsProcedure],
OBJECT_NAME(object_id) obj,OBJECT_NAME(referenced_major_id) maj,is_updated, is_selected 
FROM  sys.sql_dependencies
where OBJECT_NAME(referenced_major_id)='AnObject' --no schema in the name



select distinct OBJECT_NAME(object_id) nom,name  from sys.columns where name like '%patien%' order by nom
select distinct OBJECT_NAME(object_id) nom,name  from sys.columns where name like '%sign%' order by nom

-- search table or column through the database
-- better used sp_ineachdb instead of sp_MSforeachdb
EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME()  SELECT * FROM SYS.tables WHERE NAME LIKE ''%E835Claim%'' order by name;'

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME(); select distinct OBJECT_NAME(object_id) nom,name  
from sys.columns where name like ''%CodeId%'' order by nom'

-- search object in schema information
EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME(); SELECT ROUTINE_SCHEMA, ROUTINE_NAME
FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = ''PROCEDURE'' and ROUTINE_NAME = ''IndexOptimize''; '

--link servers
EXEC sp_linkedservers

-- FIND text in SP OR use management studio to script out the object and search with notepad++/regex
SELECT DB=DB_NAME(), [schema] = OBJECT_SCHEMA_NAME(o.[object_id]), o.name,o.type, o.type_desc, m.definition
FROM sys.objects AS o
INNER JOIN sys.sql_modules AS m
ON o.[object_id] = m.[object_id]
WHERE 
--m.[definition] LIKE '%OPENQUERY%'
--AND 
o.[type] IN ('V')
ORDER BY O.name

--all object types
select distinct  o.type, o.type_desc from sys.objects o
order by o.type
-- all data types
SELECT TYPEPROPERTY(SCHEMA_NAME(schema_id) + '.' + name, 'OwnerId') AS owner_id,
 name, system_type_id, user_type_id, schema_id  
FROM sys.types;
	

--FORMAT VERSION OF THE BODY OF THE OBJECT 
exec sp_helptext 'syncobj_0x4537354141434343'

-- FKs and tables refrencing, referenced
	           select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('MyTable'),1)
			 union all
			 select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('MyTable'),1)

-- https://dataedo.com/kb/query/sql-server/list-of-foreign-keys-with-columns
--Query below returns foreign key constrant columns defined in a database.
select schema_name(fk_tab.schema_id) + '.' + fk_tab.name as foreign_table,
    '>-' as rel,
    schema_name(pk_tab.schema_id) + '.' + pk_tab.name as primary_table,
    fk_cols.constraint_column_id as no, 
    fk_col.name as fk_column_name,
    ' = ' as [join],
    pk_col.name as pk_column_name,
    fk.name as fk_constraint_name, fk.create_date
from sys.foreign_keys fk
    inner join sys.tables fk_tab
        on fk_tab.object_id = fk.parent_object_id
    inner join sys.tables pk_tab
        on pk_tab.object_id = fk.referenced_object_id
    inner join sys.foreign_key_columns fk_cols
        on fk_cols.constraint_object_id = fk.object_id
    inner join sys.columns fk_col
        on fk_col.column_id = fk_cols.parent_column_id
        and fk_col.object_id = fk_tab.object_id
    inner join sys.columns pk_col
        on pk_col.column_id = fk_cols.referenced_column_id
        and pk_col.object_id = pk_tab.object_id
order by schema_name(fk_tab.schema_id) + '.' + fk_tab.name,
    schema_name(pk_tab.schema_id) + '.' + pk_tab.name, 
    fk_cols.constraint_column_id


-- columns, datatype, table from your database
SELECT OBJECT_SCHEMA_NAME(a.object_id), OBJECT_NAME(a.object_id), a.name,b.type_desc,  b.type 
FROM sys.all_columns a 
JOIN sys.all_objects b on a.object_id = b.object_id
JOIN sys.types t on a.user_type_id = t.user_type_id
WHERE a.name like '%lo%' and b.type ='U' and t.name in ('int','smallint', 'numeric', 'bigint')

--order table columns and get column data type
SELECT OBJECT_SCHEMA_NAME(a.object_id) schema_, OBJECT_NAME(a.object_id) table_, a.name ColName,b.type_desc, a.max_length, b.type, t. name ColtypeName, a.is_nullable, is_identity, is_computed
FROM sys.all_columns a 
JOIN sys.all_objects b on a.object_id = b.object_id
JOIN sys.types t on a.user_type_id = t.user_type_id
WHERE b.type ='U' and  OBJECT_NAME(a.object_id) = 'myTable'
order by ColName


-- identity column and how close to the max number. PERHAPS BETTER USE IndexFill_Up.sql
;with cte as(
SELECT OBJECT_SCHEMA_NAME(a.object_id) as aschema, OBJECT_NAME(a.object_id) aTable, a.name aColumn,b.type_desc,  b.type, t.name as typeName
, (select sum(row_count) from sys.dm_db_partition_stats st where st.object_id = a.object_id and st.index_id < 2) as number_rows
, case when t.name = 'bigint' then  9223372036854775807
	  when t.name = 'int' then  2147483647 
	  when t.name = 'smallint' then  32767
	  when t.name = 'tinyint' then  255 end maxNumber
FROM sys.all_columns a 
JOIN sys.all_objects b on a.object_id = b.object_id
JOIN sys.types t on a.user_type_id = t.user_type_id
WHERE b.type ='U' and t.name in ('int','smallint', 'bigint', 'tinyint ') and a.is_identity = 1
)
select *, number_rows/maxNumber * 100 as his_percentage from cte
where number_rows/maxNumber * 100 > 33
order by his_percentage desc
