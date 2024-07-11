
--******drop
SET XACT_ABORT ON

ALTER TABLE dbo.orderDetails ADD UnikID  UNIQUEIDENTIFIER CONSTRAINT DF_UnikID DEFAULT NEWID() NOT NULL
--COMPARE TO
ALTER TABLE dbo.orderDetails ADD UnikID  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_UnikID DEFAULT '00000000-0000-0000-0000-000000000000' 

GO -- drop constraint before the column itself
ALTER TABLE dbo.orderDetails DROP CONSTRAINT DF_UnikID
GO
ALTER TABLE dbo.orderDetails DROP COLUMN UnikID  

-- drop without knowing constraint name
BEGIN TRAN
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'orderDetails' AND COLUMN_NAME = 'UnikID')
BEGIN
	DECLARE @ConstraintName nvarchar(50),  @table nvarchar(50), @schema nvarchar(50), @column nvarchar(50)
	-- set the variables
	SET @schema = 'dbo'; SET @table = 'orderDetails'; SET @column = 'UnikID';
	DECLARE @Query nvarchar(200)
	-- get the constraint Name
	SELECT @ConstraintName = default_constraints.name FROM Sys.all_columns INNER JOIN sys.tables ON all_columns.object_id = tables.object_id INNER JOIN sys.schemas ON tables.schema_id = schemas.schema_id INNER JOIN sys.default_constraints ON all_columns.default_object_id = default_constraints.object_id WHERE schemas.name = @schema AND tables.name = @table AND all_columns.name = @column
	-- prepare the query and drop the UNPREDICTABLE name
	IF  @ConstraintName IS NOT NULL BEGIN
		SET @Query = 'ALTER TABLE dbo.orderDetails DROP CONSTRAINT ' + @ConstraintName
		EXEC sp_executesql @Query
	END
	-- ALTER the column
      ALTER TABLE dbo.orderDetails ALTER COLUMN UnikID UNIQUEIDENTIFIER NOT NULL -- won't accept clause DEFAULT 
    	-- DROP the column
      ALTER TABLE dbo.orderDetails DROP COLUMN UnikID 

END

COMMIT TRAN


--enable/disable
-- Disable all table constraints
ALTER TABLE YourTableName NOCHECK CONSTRAINT ALL
-- Enable all table constraints
ALTER TABLE YourTableName CHECK CONSTRAINT ALL
-- ----------
-- Disable single constraint
ALTER TABLE YourTableName NOCHECK CONSTRAINT YourConstraint
-- Enable single constraint
ALTER TABLE YourTableName CHECK CONSTRAINT YourConstraint
-- ----------
-- Disable all constraints for database
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
-- Enable all constraints for database
EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
EXEC sp_msforeachtable "ALTER TABLE ? WITH NOCHECK CHECK CONSTRAINT all" --if previous failed 		


--disable FK 
select  distinct 'ALTER TABLE ' + Object_name(fk.parent_object_id) + ' NOCHECK CONSTRAINT ' + fk.name 
from sys.objects t
join sys.foreign_keys fk on t.object_id = fk.parent_object_id
where t.type ='U' and object_name(fk.referenced_object_id) in ('MyTable') 
UNION
select  distinct 'ALTER TABLE ' + Object_name(fk.parent_object_id) + ' NOCHECK CONSTRAINT ' + fk.name 
from sys.objects t
join sys.foreign_keys fk on t.object_id = fk.parent_object_id
where t.type ='U' and object_name(fk.parent_object_id) in ('MyTable') 

