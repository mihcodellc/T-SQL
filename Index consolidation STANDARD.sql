--https://sqlperformance.com/2020/04/sql-indexes/an-approach-to-index-tuning-part-2
-- https://sqlperformance.com/2020/03/sql-indexes/an-approach-to-index-tuning-part-1
-- https://www.sqlskills.com/blogs/jonathan/finding-what-queries-in-the-plan-cache-use-a-specific-index/

--One way to test the consolidated index is to use hint to force its use and compare to the existing
-- you still need to find relevant queries to test with
-- disable current - test new -  drop current OR new depending of benefits (duration, reads/write, user's queries, CPU, memories ...)

set transaction isolation level read uncommitted
set nocount on

-- no foreign key
	           select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('PayerProvider'),1)
			 union all
			 select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('PayerProvider'),1)

exec sp_SQLskills_helpindex @objname= PayerProvider
exec sp_SQLskills_ListIndexForConsolidation @ObjName = PayerProvider, @expandGroup = 0
exec sp_SQLskills_ListIndexForConsolidation @ObjName = PayerProvider,  @KeysFilter = '[ProviderId]', @expandGroup = 0
exec sp_SQLskills_ListIndexForConsolidation @ObjName = PayerProvider,  @KeysFilter = '[DtOfDemandDeposit]', @expandGroup = 0

exec sp_SQLskills_ListIndexForConsolidation @ObjName = PayerProvider, @indnameKey ='[IX_PayerProvider]' , @isShowSampleQuery = 1

--hist, index isssue, read/write
EXEC RmsAdmin.dbo.sp_BlitzIndex_new     @DatabaseName='MedRx', @SchemaName='dbo', @TableName='Payments'

CREATE INDEX [IX_PayerProvider_Lbxid_inc_20220427] ON [dbo].[PayerProvider] ( [lbxId] ) INCLUDE ( [id]) WITH (FILLFACTOR=95, ONLINE=?, SORT_IN_TEMPDB=?, DATA_COMPRESSION=?);

set transaction isolation level read uncommitted
set nocount on
exec sp_SQLskills_ListIndexForConsolidation @ObjName = PayerProvider, @indnameKey ='[IX_PayerProvider_depositdetailid_lbxid_id]' , @isShowSampleQuery = 1

