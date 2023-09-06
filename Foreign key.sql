select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('DepositDetail'),1)
			 union all
			 select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('DepositDetail'),1)
