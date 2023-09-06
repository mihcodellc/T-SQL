--replace MyTable

select  name FK_name, object_name(fk.parent_object_id) src_table, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('MyTable'),1)
			 union all
			 select  name FK_name, object_name(fk.parent_object_id) src_table, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('MyTable'),1)


select
			'Table is referenced by foreign key' =
				db_name() + '.'
					+ rtrim(schema_name(ObjectProperty(parent_object_id,'schemaid')))
					+ '.' + object_name(parent_object_id)
					+ ': ' + object_name(object_id)
			from sys.foreign_keys where referenced_object_id = 1929266128  
