declare @sql nvarchar(max)
set @sql = '
USE ' + (select [APPS].[F_GetThinkHealthArchiveName](1)) + ';

IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''[APPS].[F_GetThinkHealthBaseName]'') AND type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
			DROP FUNCTION [APPS].[F_GetThinkHealthBaseName]
'
exec sp_executesql @sql

set @sql = '
declare @sql nvarchar(max)
set @sql = ''
CREATE FUNCTION [APPS].[F_GetThinkHealthBaseName](@ArchiveType int)
RETURNS VARCHAR(75)	
AS
BEGIN
	/*--Last Changed -- Date: 11/16/2020 -- By: Monktar Bello - initial version - get the Thinkhealth database from archive db s name*/
	/*--Example Run --  select [APPS].[F_GetThinkHealthBaseName](1)*/

	DECLARE @ArchiveDBName varchar(100)
	DECLARE @BaseName varchar(75)
	
	SELECT @ArchiveDBName = DB_NAME()

	IF (@ArchiveType = 1) /*This is the normal Archive database*/
		SET @BaseName = REPLACE(@ArchiveDBName,''''_Archive'''','''''''') 
	ELSE IF (@ArchiveType = 2) /*--This is the Archive 2 database*/
		SET @BaseName =  REPLACE(@ArchiveDBName,''''_Archive_2'''','''''''') 
		
	RETURN @BaseName

END
''
exec ' + (select [APPS].[F_GetThinkHealthArchiveName](1)) + '..sp_executesql  @sql'

exec sp_executesql @sql