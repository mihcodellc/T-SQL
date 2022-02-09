-- dynamic views
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views?view=sql-server-ver15
SELECT OBJECTPROPERTY(OBJECT_ID(referencing_entity_name), 'IsTable') AS [IsTable], *  
FROM sys.dm_sql_referencing_entities ('dbo.E835ServiceLineDetail', 'OBJECT'); -- schema included in the name

SELECT DISTINCT referenced_schema_name, referenced_entity_name,is_updated, is_selected 
FROM sys.dm_sql_referenced_entities  ('dbo.E835ServiceLineDetail', 'OBJECT')  -- schema included in the name

SELECT OBJECTPROPERTY(object_id, 'IsTable') AS [IsTable],
OBJECTPROPERTY(object_id, 'IsPrimaryKey') AS [IsPrimaryKey],
OBJECTPROPERTY(object_id, 'IsForeignKey') AS [IsForeignKey],
OBJECTPROPERTY(object_id, 'IsTrigger') AS [IsTrigger],
OBJECTPROPERTY(object_id, 'IsView') AS [IsView],
OBJECTPROPERTY(object_id, 'IsProcedure') AS [IsProcedure],
OBJECT_NAME(object_id) obj,OBJECT_NAME(referenced_major_id) maj,is_updated, is_selected 
FROM  sys.sql_dependencies
where OBJECT_NAME(referenced_major_id)='E835ServiceLineDetail' --no schema in the name



select distinct OBJECT_NAME(object_id) nom,name  from sys.columns where name like '%patien%' order by nom
select distinct OBJECT_NAME(object_id) nom,name  from sys.columns where name like '%sign%' order by nom

-- search table or column through the database
EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME()  SELECT * FROM SYS.tables WHERE NAME LIKE ''%E835Claim%'' order by name;'

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME(); select distinct OBJECT_NAME(object_id) nom,name  
from sys.columns where name like ''%FacilityCodeId%'' order by nom'

-- https://dataedo.com/kb/query/sql-server/list-of-foreign-keys-with-columns
--Query below returns foreign key constrant columns defined in a database.
select schema_name(fk_tab.schema_id) + '.' + fk_tab.name as foreign_table,
    '>-' as rel,
    schema_name(pk_tab.schema_id) + '.' + pk_tab.name as primary_table,
    fk_cols.constraint_column_id as no, 
    fk_col.name as fk_column_name,
    ' = ' as [join],
    pk_col.name as pk_column_name,
    fk.name as fk_constraint_name
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


