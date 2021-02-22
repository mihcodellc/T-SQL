declare @SearchText varchar(5000)=''

--remove known wilcard
	--remove known wilcard
	SET @TextSearch = REPLACE(@TextSearch,'+', '%'); SET @TextSearch = REPLACE(@TextSearch,'%', '%'); SET @TextSearch = REPLACE(@TextSearch,'[', '%')
	SET @TextSearch = REPLACE(@TextSearch,'@', '%'); SET @TextSearch = REPLACE(@TextSearch,'#', '%'); SET @TextSearch = REPLACE(@TextSearch,'!', '%')
	SET @TextSearch = REPLACE(@TextSearch,']', '%'); SET @TextSearch = REPLACE(@TextSearch,'^', '%'); SET @TextSearch = REPLACE(@TextSearch,'_', '%')
	SET @TextSearch = REPLACE(@TextSearch,'~', '%'); SET @TextSearch = REPLACE(@TextSearch,'''', '%');

	--Prepare the search parameter
	IF LEN(@SearchText) > 0 BEGIN
		--put in wilcard to search
		SET @SearchText = REPLACE(@SearchText,' ', '%')
		SET @SearchText = '%' + @SearchText + '%'
	END

	--it does replace the unwanted caracters, How? Nicholas on https://stackoverflow.com/questions/10037168/recursive-replace-from-a-table-of-characters
	--doesn't work on sql 2005
declare @target varchar(15)= 'oum~a!r a vue'
SELECT @target = REPLACE(@target, invalidChar, '-')
FROM (VALUES ('~',1),('''',2),('!',3),('@',4),('#',5)) AS T(invalidChar,pos)

select @target