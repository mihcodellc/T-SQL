DECLARE @BaseOUT varchar(75)
DECLARE @sql nvarchar(max)

SET @sql = '
USE ' + (select a_schema.[udf_ReturnAdbName2](1)) + ';

SELECT @Base = LTRIM(RTRIM(a_schema.[udf_ReturnAdbName](1)))

IF  EXISTS (SELECT 1 FROM sys.triggers WHERE object_id = OBJECT_ID(N''a_schema.[udt_Trigger]''))
	DROP TRIGGER a_schema.[udt_Trigger]
'

exec sp_executesql @sql, N'@Base varchar(75) OUTPUT', @Base = @BaseOUT OUTPUT


set @sql = '
declare @sql nvarchar(max)
set @sql = ''
	CREATE TRIGGER a_schema.[udt_Trigger] ON a_schema.[a_table] 
	FOR INSERT, DELETE
	AS 
	BEGIN
		/*-- Last Changed: -- Date: 11/17/2020 -- By: Monktar Bello - Initial version*/
		IF @@ROWCOUNT = 0 RETURN; 

		DECLARE @SPName varchar(50)
		DECLARE @OperationType char(6)
		DECLARE @UserActivityLogID bigint
		DECLARE @TableName varchar(30)
		DECLARE @ChangeDesc varchar(5000)
		DECLARE @FirstKey varchar(50)
		DECLARE @UserID INT
	
		SET	@UserActivityLogID = 0
		SET	@TableName = ''''a_table''''

		IF EXISTS(SELECT 1 FROM inserted) 
		BEGIN
			SET @OperationType = ''''Insert''''
			SELECT @FirstKey = CAST(a_pkColumn AS varchar(20)), @UserID = UserID_FK, 
				@ChangeDesc =''''a_pkColumn: '''' + CAST(a_pkColumn AS varchar(20)) 
			FROM inserted
		END	

		IF EXISTS(SELECT 1 FROM deleted) 
		BEGIN
			SET @OperationType = ''''Delete''''
			SELECT @FirstKey = CAST(a_pkColumn AS varchar(20)), @UserID = UserID_FK, 
				@ChangeDesc =''''a_pkColumn: '''' + CAST(a_pkColumn AS varchar(20))
			FROM deleted
		END

		SET @SPName = OBJECT_NAME(@@PROCID)	
	
		EXEC '' +  @BaseOUT  + ''.APPS.usp_LogSP
			@UserActivityLogID,
			@UserID,
			@OperationType,
			@TableName,
			@FirstKey,
			Null,
			Null,
			@ChangeDesc, NULL, @SPName
	END
''

exec ' + (select a_schema.[udf_ReturnAdbName2](1)) + '..sp_executesql  @sql'

exec sp_executesql @sql,N'@BaseOUT varchar(75) ', @BaseOUT = @BaseOUT

set @sql = '
USE ' + (select a_schema.[udf_ReturnAdbName2](1)) + ';

ALTER TABLE a_schema.[a_table] ENABLE TRIGGER [udt_Trigger];'

exec sp_executesql  @sql
