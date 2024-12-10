--found the table knowing FK name
SELECT o.name, fk.name, fk.is_not_trusted, fk.is_disabled
FROM sys.foreign_keys AS fk
INNER JOIN sys.objects AS o ON fk.parent_object_id = o.object_id
WHERE fk.name in ('FK_tablename_column') ;
GO

--replace MyTable

select  name FK_name, object_name(fk.parent_object_id) tableColReferTo, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) referTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('MyTable'),1)
			 union all
			 select  name FK_name, object_name(fk.parent_object_id) tableColReferTo, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) referTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('MyTable'),1)

OR
	--all of them
select  name FK_name, object_name(fk.parent_object_id) tableColReferTo, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) referTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action, fk.type_desc 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 order by tableColReferTo


select
			'Table is referenced by foreign key' =
				db_name() + '.'
					+ rtrim(schema_name(ObjectProperty(parent_object_id,'schemaid')))
					+ '.' + object_name(parent_object_id)
					+ ': ' + object_name(object_id)
			from sys.foreign_keys where referenced_object_id = 1929266128  


-- drop foreign keys
select  distinct 'ALTER TABLE ' + 
 rtrim(schema_name(ObjectProperty(t.object_id,'schemaid')))	+ '.' + '['+ object_name(t.object_id) + ']'+ ' DROP  CONSTRAINT if exists ' + fk.name 
from sys.objects t
join sys.foreign_keys fk on t.object_id  = fk.parent_object_id
where fk.referenced_object_id in (select object_id from sys.objects where type ='U' ) 
