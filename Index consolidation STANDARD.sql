set transaction isolation level read uncommitted
set nocount on

-- no foreign key
	           select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('Exceptions'),1)
			 union all
			 select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('Exceptions'),1)



exec sp_SQLskills_ListIndexForConsolidation @ObjName = LockboxDocumentTracking, @expandGroup = 0
exec sp_SQLskills_helpindex @objname= LockboxDocumentTracking
exec sp_SQLskills_ListIndexForConsolidation @ObjName = LockboxDocumentTracking, @indnameKey ='[IX_LockboxDocumentTracking_GUIrecon_dteffective_paymentid_providerid_consolidated835filename_amtcheck_dd_MORE_inc_20220413]' , @isShowSampleQuery = 1

--hist, index isssue, read/write
EXEC RmsAdmin.dbo.sp_BlitzIndex_new     @DatabaseName='MedRx', @SchemaName='dbo', @TableName='Payments'

select index_id id, run_datetime whe, index_usage_summary, reads_per_write, index_op_stats, * from rmsadmin.dbo.BlitzIndex
where table_name = 'Exceptions' 
--and run_datetime <='2023-07-19 19:25:00.000'
and index_id in(40,3)
order by run_datetime desc, index_id desc

--!!!Important!!!
--1 create a solution index WITHOUT dropping or modifying (drop_existing=ON) an existing index
--2 deploying an index if it doesn't work we can drop later it. as long as space is enough to create it
--3 you can remove an index with rollback statement ready; then plan for putting it back, if a db client starts bugging down
--4 no more 5 keys columns and 10 in includes
--5 test your script is error free and a gain in performance before deploying whenever is possible
	

CREATE INDEX [IX_LockboxDocumentTracking_Lbxid_inc_20220427] ON [dbo].[LockboxDocumentTracking] ( [lbxId] ) 
INCLUDE ( [id]) WITH (FILLFACTOR=95, ONLINE=ON, SORT_IN_TEMPDB=?, DATA_COMPRESSION=?);

set transaction isolation level read uncommitted
set nocount on
exec sp_SQLskills_ListIndexForConsolidation @ObjName = LockboxDocumentTracking, @indnameKey ='[IX_LockboxDocumentTracking_depositdetailid_lbxid_id]' , @isShowSampleQuery = 1


