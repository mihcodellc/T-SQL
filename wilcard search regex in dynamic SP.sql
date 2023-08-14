-- notepad++ regular expressions search
---- https://www.linguisticsweb.org/doku.php?id=linguisticsweb:tutorials:basics:regex:regex-notepad
---- https://www.exeideas.com/2020/08/guide-and-common-regex-with-notepad.html
---- https://npp-user-manual.org/docs/searching/#regular-expressions
	{N,P} ⇒ Matches N to P copies of the element
	. or \C ⇒ Matches any character
	* ⇒ This matches 0 or more instances of the previous character
	*? ⇒ Zero or more of the previous group, but minimally: the shortest matching string, rather than the longest string
	+ ⇒ This matches 1 or more instances of the previous character, as many as it can. 
	+? ⇒ One or more of the previous group, but minimally.
		some ANCHORS
	^ ⇒ This matches the start of a line (except when used inside a set).
	$ ⇒ This matches the end of a line. alternative \r\n in extended search mode in notepad++
	\s ⇒ space
	\b ⇒ Matches either the start or end of a word.
	\B ⇒ Not a word boundary. It represents any location between two word characters or between two non-word characters.
	\A or \` ⇒ Matches the start of the file.
	\z or \' ⇒ Matches the end of the file.
	Join/Split line > Ctrl+I / Ctrl+J 9Shortcut Mapper in NotePad++)  --end > shift +alt > begin > replace/insert then ctrl+a ctrl+j to joint line
	word wrap 
	all above are in "Multiplying operators", we do have others like: 
	          "Character Properties" or 
		  "Anchors" (match a zero-length position in the line)
		  "Assertions" consume no characters and , matching starts over where it left. 
		  "Substitutions"
		  ...
\//*\*\*  to find /**	
\*\s.*?Replace to find "* Replace"
---- https://docs.microsoft.com/en-us/sql/ssms/scripting/search-text-with-wildcards?view=sql-server-ver16
---- .* ?/storedprocedures/ => return everything before "/storedprocedures/"
---- @ClaimID.{1,15}int.{15,4000}?
----------look for @claimID any caracter within 1 to 15 range then match int then any caracter within 15 and 4000 range but keep it minimal
---- @.[a-z]{1,5}status.{10,50}?FileLoadStatus
----------look for text start with @ followed by alpha kracters in 5 range then status in range of 50 keep minimal THEN find bELLO in any range
---- copy text on webpage to notepad++ and search using regular expression
\//*\*\*.?.*?ALTER
matches

/** ****************************************************************************************************
    Move paid to prepaid on all service lines, except the one equaling the total paid footer.
    Rule task: BOA-13447
    
 */
ALTER
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
