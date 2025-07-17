
use master;
go
create or alter PROCEDURE [dbo].[sp_table_cols]
(
    @ObjName nvarchar(776) = NULL		
 )                                      
AS
--exec dba.dbo.[sp_table_cols] @ObjName = 'dbo.PayerProvider'

begin

	--declare @ObjName nvarchar(776) = 'dbo.PayerProvider'

	SET NOCOUNT ON;


	--declare @ObjName nvarchar(776) = 'dbo.PayerProvider'
	declare @db nvarchar(128) = db_name(), @sql nvarchar(2000);

	--select 'return table''s columns info if it is a table' as info, PARSENAME(@ObjName, 1), PARSENAME(@ObjName, 2), PARSENAME(@ObjName, 3), PARSENAME(@ObjName, 4)
	set @sql = '

	SELECT 
		c.COLUMN_NAME,
		c.DATA_TYPE,
		c.CHARACTER_MAXIMUM_LENGTH,
		c.IS_NULLABLE,
		c.ORDINAL_POSITION
	FROM 
		' + @db +'.INFORMATION_SCHEMA.COLUMNS c
	WHERE 
		c.TABLE_NAME = ''' + PARSENAME(@ObjName, 1) + '''  
		AND c.TABLE_SCHEMA = ''' + iif(PARSENAME(@ObjName, 2) is null, 'dbo', PARSENAME(@ObjName, 2)) + ''' 
	ORDER BY 
		c.COLUMN_NAME;
	';

	select @sql

	exec sp_executesql @sql;


end


GO

EXEC sys.sp_MS_marksystemobject 'sp_table_cols';
GO
	
