-- notepad++ regular expressions search
---- https://www.exeideas.com/2020/08/guide-and-common-regex-with-notepad.html
---- https://npp-user-manual.org/docs/searching/#regular-expressions
---- https://docs.microsoft.com/en-us/sql/ssms/scripting/search-text-with-wildcards?view=sql-server-ver16
---- .* ?/storedprocedures/ => return everything before "/storedprocedures/"
---- copy text on webpage to notepad++ and search using regular expression
--notepad++ plugin: 
---- poor manTsql formatter - Compare Plugin

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
