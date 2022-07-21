
-- ***sp_FindStringInTable By: Greg Robidoux
-- https://www.mssqltips.com/sqlservertip/1522/searching-and-finding-a-string-value-in-all-columns-in-a-sql-server-table/?utm_source=dailynewsletter&utm_medium=email&utm_content=headline&utm_campaign=20220721

CREATE PROCEDURE dbo.sp_FindStringInTable @stringToFind VARCHAR(max), @schema sysname, @table sysname 
AS

SET NOCOUNT ON

--run example: EXEC sp_FindStringInTable 'Irv%', 'Person', 'Address'

BEGIN TRY
   DECLARE @sqlCommand varchar(max) = 'SELECT * FROM [' + @schema + '].[' + @table + '] WHERE ' 
	   
   SELECT @sqlCommand = @sqlCommand + '[' + COLUMN_NAME + '] LIKE ''' + @stringToFind + ''' OR '
   FROM INFORMATION_SCHEMA.COLUMNS 
   WHERE TABLE_SCHEMA = @schema
   AND TABLE_NAME = @table 
   AND DATA_TYPE IN ('char','nchar','ntext','nvarchar','text','varchar')

   SET @sqlCommand = left(@sqlCommand,len(@sqlCommand)-3)
   EXEC (@sqlCommand)
   PRINT @sqlCommand
END TRY

BEGIN CATCH 
   PRINT 'There was an error. Check to make sure object exists.'
   PRINT error_message()
END CATCH 


-- ***find in value
select PATINDEX('%stringToFindAge%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance')
select SUBSTRING('je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance',PATINDEX('%stringToFindAge%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance')+16,2) -- 10 ie len(stringToFindAge = ) -- 2 is enough to hold the comparison operator

select SUBSTRING('je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance',PATINDEX('%stringToFindAge%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance')+18,5) -- 18 = 16 + 2 -- start point for the age's digits

--select SUBSTRING('je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance',PATINDEX('%stringToFindAge%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance')+PATINDEX('%stringToFindAge%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance'),5)

--select CHARINDEX(' ',SUBSTRING('je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance',PATINDEX('%stringToFindAge%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance')+18,5),1)-1

select CHARINDEX(' ',SUBSTRING('je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance',PATINDEX('%stringToFindAge%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance')+18,5),1)-1

select SUBSTRING('je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance',patindex('%'+SUBSTRING('je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance',PATINDEX('%stringToFindAge%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance')+18,5)+'%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance'),
 CHARINDEX(' ',SUBSTRING('je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance',PATINDEX('%stringToFindAge%','je viendrai chercher mon enfant a 20il a voulu stringToFindAge = 29 est la. je t en prie ne pose pas  de resistance')+18,5),1)-1)

 -- with variable 
 DECLARE @age tinyint, @operator varchar(2), @StringWithAge VARCHAR(500)= ''

 --any 5 as integer is used because the age of human won't go beyond 5 digits
SELECT @age = LTRIM(RTRIM(
	CASE WHEN PATINDEX('%stringToFindAge%',@StringWithAge)> 0 THEN
		SUBSTRING(@StringWithAge,
							patindex('%'+SUBSTRING(@StringWithAge,PATINDEX('%stringToFindAge%',@StringWithAge)+18,5)+'%',@StringWithAge), 
								CASE WHEN CHARINDEX(' ',SUBSTRING(@StringWithAge,PATINDEX('%stringToFindAge%',@StringWithAge)+18,5),1)>1 THEN CHARINDEX(' ',SUBSTRING(@StringWithAge,PATINDEX('%stringToFindAge%',@StringWithAge)+18,5),1)-1 ELSE 3 END) -- 3 ehough to hold the age's digits
	ELSE '' END))

SELECT @operator = RTRIM(
	CASE WHEN PATINDEX('%stringToFindAge%',@StringWithAge)> 0 THEN
		 SUBSTRING(@StringWithAge,PATINDEX('%stringToFindAge%',@StringWithAge)+10,2) 	-- 16 ie len(stringToFindAge = ) -- 2 is enough to hold the comparison operator
	ELSE '' END
)
