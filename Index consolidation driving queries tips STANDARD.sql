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
--0 optimizer uses all stats of existing indexes(user, sys stats prefixed *_WA_Sys_*) on the tables, even they are NOT marked as  seeked or scanned on you query plan
--	hence, some create index OR query maybe quicker because of those stats
--	hence, never assume that the index is not mentioned as USED for your query looking at query plan, you can drop it without drawbacks. Test, test, test
--1 create a solution index WITHOUT dropping or modifying (drop_existing=ON) an existing index
--2 deploying an index if it doesn't work we can drop later it. as long as space is enough to create it
--3 you can drop an index with rollback create statement ready; then plan for putting it back, if a db client starts bugging down
--4 no more 5 keys columns and 10 in includes
--5 test your script is error free and a gain in performance before deploying whenever is possible
--6 consider the cost/size of your new index versus the existing indexes having the columns needed by the query to optimize 
--7 may need to use hint of new index to see that it performs better then the default cost effective chose by the engine; if so, you can drop it but monitoring afterward	


--!!!Driving queries !!!!
	--use a tool(eg. OS_CPU usagePressure.ps1) to alert when the resources (CPU, Memmory ...) is under pressure
	--when alert comes in, use dbo.sp_BlitzCache @MinutesBack = 5, @Top = 10, @sortOrder = 'cpu'
	--then look for #executions - executions per minutes, total Resources(CPU, Memories) ..., warnings and queries' plan
	--work plan/warnings in plan explorer on Pre production db ie same volume of data


set transaction isolation level read uncommitted
set nocount on
exec sp_SQLskills_ListIndexForConsolidation @ObjName = LockboxDocumentTracking, @indnameKey ='[IX_LockboxDocumentTracking_depositdetailid_lbxid_id]' , @isShowSampleQuery = 1


