DECLARE @ToCreate varchar(1000) 
DECLARE @command varchar(2000) 
															 

SELECT @ToCreate = '
												  
 
					   

			
						  
			 
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
'

SET @command ='IF ''?'' LIKE (''%Archive%'')  AND ''?'' NOT LIKE (''%Archive_2%'')
BEGIN
			USE ?
			EXEC('' ' + @ToCreate + ' '')
END'

--SELECT @command

EXEC sp_MSforeachdb @command

					   