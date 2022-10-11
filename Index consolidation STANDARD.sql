set transaction isolation level read uncommitted
set nocount on

-- no foreign key
	           select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('LockboxDocumentTracking'),1)
			 union all
			 select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('LockboxDocumentTracking'),1)

exec sp_SQLskills_ListIndexForConsolidation @ObjName = LockboxDocumentTracking, @expandGroup = 0
exec sp_SQLskills_helpindex @objname= LockboxDocumentTracking
exec sp_SQLskills_ListIndexForConsolidation @ObjName = LockboxDocumentTracking, @indnameKey ='[IX_LockboxDocumentTracking_GUIrecon_dteffective_paymentid_providerid_consolidated835filename_amtcheck_dd_MORE_inc_20220413]' , @isShowSampleQuery = 1

--hist, index isssue, read/write
EXEC RmsAdmin.dbo.sp_BlitzIndex_new     @DatabaseName='MedRx', @SchemaName='dbo', @TableName='Payments'

CREATE INDEX [IX_LockboxDocumentTracking_Lbxid_inc_20220427] ON [dbo].[LockboxDocumentTracking] ( [lbxId] ) INCLUDE ( [id]) WITH (FILLFACTOR=95, ONLINE=?, SORT_IN_TEMPDB=?, DATA_COMPRESSION=?);

set transaction isolation level read uncommitted
set nocount on
exec sp_SQLskills_ListIndexForConsolidation @ObjName = LockboxDocumentTracking, @indnameKey ='[IX_LockboxDocumentTracking_depositdetailid_lbxid_id]' , @isShowSampleQuery = 1


