

BULK INSERT db_name.dbo.table_name FROM 'C:\Sample.csv'  
   WITH (  
      DATAFILETYPE = 'char',  -- 'char' | 'native' | 'widechar' | 'widenative'
      FIELDTERMINATOR = ',',  
      -- FIELDQUOTE = 'quote_characters'
      ROWTERMINATOR = '\n'  
);  

--TRUNCATE TABLE myFirstImport; -- (for testing)
BULK INSERT dbo.myFirstImport  
   FROM 'D:\BCP\myFirstImport.bcp'  
   WITH (FORMATFILE = 'D:\BCP\myFirstImport.xml');  
or
INSERT INTO dbo.myFirstImport
SELECT *
FROM OPENROWSET (BULK 'D:\BCP\myFirstImport.bcp', FORMATFILE = 'D:\BCP\myFirstImport.fmt') AS t1;	

-- -n, -c, -w, or -N
-- -c Performs the operation using a character data type
-- -n Performs the bulk-copy operation using the native (database) data types
-- -N Performs the bulk-copy operation using the native (database) data types of the data for noncharacter data, and Unicode characters for character data
-- -w Performs the bulk copy operation using Unicode characters. 
exec xp_cmdshell 'bcp db_name.dbo.table_name in G:\Sample.csv -c -t, -T -S asp-sql -U mbello -P xxxxx_password_xxxxx '
or
sqlcmd -S instance-name,1433 -Q "select * from db_B.schema.table1" –s "," –i "C:\Backups\doc1.csv" -E	
sqlcmd -S 127.0.0.1 -E -i AdventureWorksDW2012.sql
sqlcmd -S 127.0.0.1 -E -i AdventureWorksDW2012.sql -o QueryResults.txt -e -- bulk insert is used as it is in above statements
	
-- **************** BEGIN INSTRUCTIONS  ****************
-- activate  xp_cmdshell: you may use the script below to activate it. Please inactivate it at the end
-- To allow advanced options to be changed.  
--EXECUTE sp_configure 'show advanced options', 1;  
--GO  
---- To update the currently configured value for advanced options.  
--RECONFIGURE;  
--GO  
---- To enable the feature.  
--EXECUTE sp_configure 'xp_cmdshell', 1;  
--GO  
---- To update the currently configured value for this feature.  
--RECONFIGURE;  
--GO   
--distinguish first part "run on source DB" and second  part "run on Destination DB"

--activate SQLCMD Mode using SSMS -> Menu bar -> Query -> SQLCMD Mode.  Please inactivate it at the end
--replace CVS path: C:\Backups\ -- SQL Server should be able to write folder
--replace destination DB: db_A
--replace source DB: db_B
--replace the server SqlInstance. The script uses the same server for SOURCE DB and DESTINATION DB 
--3 tables are concerned mainly: table1, table2, table3
--please, at the end, remove doc1.csv, Curric.csv, CurriDoc.csv from the path C:\Backups\


-- **************** END INSTRUCTIONS  ****************

-- **************** run on Source DB ****************

--export csv file 
--doc1
exec xp_cmdshell 'bcp db_B.schema.table1 out C:\Backups\doc1.csv -n -T -S SqlInstance -U apps -P space15form3 ', no_output
or
sqlcmd -S instance-name,1433 -Q "select * from db_B.schema.table1" –s "," –o "C:\Backups\doc1.csv" -E	
	
--Curric
exec xp_cmdshell 'bcp db_B.schema.table3 out C:\Backups\Curric.csv -n -T -S SqlInstance -U apps -P space15form3 ', no_output
--CurriDoc
exec xp_cmdshell 'bcp db_B.schema.table2 out C:\Backups\CurriDoc.csv -n -T -S SqlInstance -U apps -P space15form3 ', no_output


-- **************** run on Destination DB ****************
USE db_A

--drop temp doc1 table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'doc1') AND type in (N'U'))
	DROP TABLE dbo.doc1

--drop temp Curric table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'Curric') AND type in (N'U'))
	DROP TABLE dbo.Curric

--drop temp CurriDoc table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'CurriDoc') AND type in (N'U'))
	DROP TABLE dbo.CurriDoc

--drop temp NewIDInfo table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'NewIDInfo') AND type in (N'U'))
	DROP TABLE dbo.NewIDInfo

--drop temp NewIDCurri table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'NewIDCurri') AND type in (N'U'))
	DROP TABLE dbo.NewIDCurri

--create doc1 
CREATE TABLE dbo.doc1 (
	DocID int NOT NULL,Title varchar(100) NOT NULL
)
go

CREATE TABLE dbo.Curric(
	CurriculumID int NOT NULL,Title varchar(50) NOT NULL
 )
go

CREATE TABLE dbo.CurriDoc(
	[CurriculumID] [int] NOT NULL,[DocumentID] [int] NOT NULL
)

go

--need them to be able to loop through all records in the dynamic query when I keep the insert id for use later on
CREATE TABLE dbo.NewIDInfo (DocID_New INT, DocID_ex INT)
CREATE TABLE dbo.NewIDCurri (CurriID_New INT, CurriID_ex INT)



--import natively
--doc1
exec xp_cmdshell 'bcp db_A.dbo.doc1 in C:\Backups\doc1.csv -n -T -S SqlInstance -U apps -P space15form3 ', no_output
go
--Curric
exec xp_cmdshell 'bcp db_A.dbo.Curric in C:\Backups\Curric.csv -n -T -S SqlInstance -U apps -P space15form3 ', no_output
go
--CurriDoc
exec xp_cmdshell 'bcp db_A.dbo.CurriDoc in C:\Backups\CurriDoc.csv -n -T -S SqlInstance -U apps -P space15form3 ', no_output
go

USE db_A

DECLARE @Cur INT, @docId INT

--staging table, no confusion with the one uses to import the data. bcp not allowed to add more column needed for later
declare  @doc1 TABLE (
	DocID int NOT NULL,Title varchar(100) NOT NULL,	
)

--debug let known if duplicated exists
SELECT a.filename 'duplicated doc not part of this script', a.doctype FROM @doc1  a 
group by a.filename, a.doctype
having count(a.filename)>1

-- remove duplicate doc
INSERT INTO @doc1 
SELECT a.DocID, a.Title from dbo.doc1 a where not exists 
(
SELECT b.filename, b.doctype FROM doc1  b 
where a.FileName = b.FileName and a.DocType = b.DocType
group by b.filename, b.doctype
having count(b.filename)>1
)

--select count(*) from @doc1


declare  @Curric TABLE(
	CurriculumID int NOT NULL,Title varchar(50) NOT NULL
	
 )

 --debug let known if duplicated exists
SELECT b.Title 'duplicated curriculum not part of this script' FROM dbo.Curric b 
group by b.Title
having count(b.Title)>1


INSERT INTO @Curric 
SELECT a.CurriculumID, a.Title from dbo.Curric a where not exists
(
SELECT b.Title FROM dbo.Curric b 
WHERE a.Title = b.Title
group by b.Title
having count(b.Title)>1
)


--select count(*) from @Curric

declare  @CurriDocSource TABLE(
	[CurriculumID] [int] NOT NULL,[DocumentID] [int] NOT NULL,[DocumentPosition] [smallint] NOT NULL,
	 TargetDocID int not null default 0,  TargetCurricID int default 0
)

declare  @CurriDocTarget TABLE(
	[CurriculumID] [int] NOT NULL,[DocumentID] [int] NOT NULL,[DocumentPosition] [smallint] NOT NULL, LastPosition smallint not null default 0
)

--get doc & curric which really exist
INSERT INTO @CurriDocSource 
SELECT  CurriculumID, DocumentID, DocumentPosition, 0, 0 from dbo.CurriDoc
where CurriculumID in (select CurriculumID from @Curric)
	and DocumentID in (select DocID from @doc1)

SELECT  CurriculumID, DocumentID, DocumentPosition,'orphan relation' from dbo.CurriDoc
where CurriculumID not in (select CurriculumID from @Curric)
or DocumentID not in (select DocID from @doc1)

 --debug let known if duplicated exists
SELECT a.DocumentID 'duplicated Doc-Curric not part of this script', a.CurriculumID FROM @CurriDocSource  a 
group by a.DocumentID, a.CurriculumID
having count(1)>1

--remove duplicated CurriDoc ??need to be test
DELETE  a
FROM @CurriDocSource a
JOIN (
SELECT a.DocumentID, a.CurriculumID FROM @CurriDocSource  a 
group by a.DocumentID, a.CurriculumID
having count(1)>1
) b ON a.CurriculumID = b.CurriculumID and a.DocumentID=b.DocumentID





--INSERT INTO @CurriDocTarget 
--SELECT  CurriculumID, DocumentID, DocumentPosition, 0 from schema.table2
--where CurriculumID in (select CurriculumID from schema.table3)
--	and DocumentID in (select DocID from schema.table1)



----update @CurriDoc current last position of Curri&Doc
--;WITH CTE AS (
--SELECT CurriculumID, DocumentID, DocumentPosition, COUNT(1) OVER(PARTITION BY CurriculumID) AS Num FROM @CurriDocTarget
--)
--UPDATE a SET LastPosition= b.Num-1
--FROM CTE b JOIN @CurriDocTarget a 
--ON b.CurriculumID =  a.CurriculumID

--select count(*) from @CurriDocSource


set xact_abort on
set transaction isolation level serializable
begin tran

DECLARE @query NVARCHAR(max) 
DECLARE @print NVARCHAR(max) 
SET @print = ' '
SET @query = '' + Char(13) 

----update table1 and get the id of existing doc
DECLARE UpdateExisting CURSOR FOR   
    SELECT  
	    'UPDATE schema.table1 ' +   Char(13) +
		'SET Title = ''' + replace(Title,'''','''''') + ''''+ Char(13) +
		'	 ,LastUpdate = getdate() ' +  Char(13) +
		'	 ,DocCategory = ' + CONVERT(VARCHAR(11), DocCategory) + Char(13) + 
		' 	 ,DocSize = ' + CONVERT(VARCHAR(20), DocSize)  + Char(13) +
		'    OUTPUT inserted.DocID, '+ CONVERT(VARCHAR(11), DocID) + ' INTO dbo.NewIDInfo '+
		'WHERE FileName = ''' + FileName + ''' AND DocType = ' + CONVERT(VARCHAR(11), DocType) + ' '+ Char(13)
	FROM @doc1  a
	WHERE EXISTS (select 1  from schema.table1 b where a.FileName = b.FileName and a.DocType = b.DocType) 
OPEN UpdateExisting  
FETCH NEXT FROM UpdateExisting INTO @query  
   
WHILE @@FETCH_STATUS = 0  
BEGIN  
	--print @query
	exec (@query)
    FETCH NEXT FROM UpdateExisting INTO @query  
END  
  
CLOSE UpdateExisting  
DEALLOCATE UpdateExisting  

--select *, 'bello' from dbo.NewIDInfo ORDER BY DocID_ex


--update table1 on columns to large to be updated  through the previous update
UPDATE schema.table1
			SET Description = s.Description, 
			ClientDescription = s.ClientDescription
FROM dbo.doc1 s WHERE schema.table1.FileName = s.FileName and schema.table1.DocType = s.DocType

	  --select * from dbo.NewIDInfo ORDER BY DocID_ex

--update table3
DECLARE UpdateExisting CURSOR FOR   
    SELECT  -- top one to avoid duplicated insert
	    'UPDATE  schema.table3 ' +   Char(13) +
		'	 SET LastChange = getdate() ' +  Char(13) +
		'    ,Active = ' + CONVERT(VARCHAR(1), Active) + Char(13) +
		'WHERE Title = ''' + Title + ''' '+ Char(13)
	FROM @Curric  a
	WHERE EXISTS (select 1  from schema.table3 b where a.Title = b.Title)
OPEN UpdateExisting  
FETCH NEXT FROM UpdateExisting INTO @query  
   
WHILE @@FETCH_STATUS = 0  
BEGIN  
	--print @query
	exec (@query)

    FETCH NEXT FROM UpdateExisting INTO @query  
END  
  
CLOSE UpdateExisting  
DEALLOCATE UpdateExisting  

  --select *, 'BELLO' from dbo.NewIDCurri ORDER BY CurriID_ex


--debug
print '***************************doc count before***************************'
select @print=count(filename)  from schema.table1 
print @print
set @print = '' 

--debug
--SELECT  a.filename, a.doctype, count(a.filename) 'duplicated count' FROM @doc1  a WHERE NOT EXISTS (select 1  from schema.table1 b where a.FileName = b.FileName and a.DocType = b.DocType) 
--group by a.filename, a.doctype
--having count(a.filename)>1

WHILE  EXISTS(
		SELECT 1 FROM @doc1  a WHERE NOT EXISTS (select 1  from schema.table1 b where a.FileName = b.FileName and a.DocType = b.DocType)
		)	 BEGIN
	--insert doc1 and get newid
	SELECT top 1 @query =  -- top one to avoid duplicated insert
	   'INSERT INTO schema.table1 ' +   Char(13) +
		'OUTPUT inserted.DocID, ' + CONVERT(VARCHAR(11), a.docID )  + ' INTO dbo.NewIDInfo ' + Char(13) +
		'SELECT  
		  ''' + Title + ''' 
		 , ''' + replace(Description,'''','''''') + '''  
		 , ''' + FileName + '''  
		, getdate() 
		, ' + CONVERT(VARCHAR(6), DocType) + ' 
		, ' + CONVERT(VARCHAR(11), DocCategory) + ' 
		, ' + CONVERT(VARCHAR(20), DocSize) + ' 
		, ' + CONVERT(VARCHAR(11), ProductID_FK) + ' 
		 , ''' + EmbedCode + '''  
		, ''' + CONVERT(VARCHAR(25), DateCreated) + ''' 
		, ' + CONVERT(VARCHAR(1), SyncToProductHelp) + ' 
		 , ''' + SearchKeys + '''  
		, ' + CONVERT(VARCHAR(1), Active) + ' 
		 , ''' + ClientDescription + '''  
		 , ''' + ControlHelpKey + '''  
		, getdate() '  + '  ' + Char(13)
	FROM @doc1  a
	WHERE NOT EXISTS (select 1  from schema.table1 b where a.FileName = b.FileName and a.DocType = b.DocType) order by a.DocID

	--print @query
	exec (@query)	
END

--debug
print '***************************doc count after***************************'
select @print=count(filename)  from schema.table1
print @print
set @print = '' 


--debug
print '***************************curri count before***************************'
select @print=count(Title)  from schema.table3 
print @print
set @print = '' 

----debug
--SELECT Title, count(a.Title) 'duplicated count' FROM dbo.Curric a WHERE NOT EXISTS (select 1  from schema.table3 b where a.Title = b.Title)
--group by a.Title
--having count(a.Title)>1

WHILE EXISTS(
		SELECT 1 FROM @Curric a WHERE NOT EXISTS (select 1  from schema.table3 b where a.Title = b.Title)
		)	 BEGIN
	--insert Curric and get newid
	SELECT top 1 @query =  
	'INSERT INTO schema.table3 ' +   Char(13) + 
	'OUTPUT inserted.CurriculumID, ' + CONVERT(VARCHAR(11), a.CurriculumID )  + ' INTO dbo.NewIDCurri ' + Char(13) +
	' SELECT  ''' + Title + ''' 
	, getdate() 
	, ' + CONVERT(VARCHAR(1), Active) + ' 
	, ''' + CONVERT(VARCHAR(25), ExpireDate) + ''' 
	, ' + CONVERT(VARCHAR(4), GroupLevel) + ' 
	, ' + CONVERT(VARCHAR(1), SyncToProductHelp) + '  ' + Char(13)
	FROM  @Curric a WHERE NOT EXISTS (select 1  from schema.table3 b where a.Title = b.Title)

	--print @query
	exec (@query)
END

--debug
print '**********************curri count after***************************'
select @print = count(Title)  from schema.table3
print @print
set @print = ''

  --select * from dbo.NewIDInfo ORDER BY DocID_ex
  --select * from dbo.NewIDCurri ORDER BY CurriID_ex

-- update the imported table with ID to be used in destination DB
--doc1
UPDATE a SET a.TargetID=b.DocID_New
FROM @doc1 a JOIN dbo.NewIDInfo b ON a.DocID = b.DocID_ex

--Curric
UPDATE a SET a.TargetID=b.CurriID_New
FROM @Curric a JOIN dbo.NewIDCurri b ON a.CurriculumID = b.CurriID_ex

--select docid, TargetID from @doc1 order by DocID
--select CurriculumID, TargetID from @Curric

--update DocCurric source
UPDATE a SET a.TargetCurricID = c.TargetID, a.TargetDocID = b.TargetID
FROM @CurriDocSource a
JOIN @doc1 b ON a.DocumentID = b.DocID
JOIN @Curric c ON a.CurriculumID = c.CurriculumID

--select a.CurriculumID, c.CurriculumID, c.TargetID 'curri', a.DocumentID, b.DocID, b.TargetID 'doc' 
--FROM @CurriDocSource a
--JOIN @doc1 b ON a.DocumentID = b.DocID
--JOIN @Curric c ON a.CurriculumID = c.CurriculumID order by a.DocumentID

--select * from dbo.NewIDCurri ORDER BY CurriID_ex
select * from @CurriDocSource order by CurriculumID
--select * from @CurriDocTarget order by CurriculumID
select * from schema.table2

--update DocCurric target
DECLARE UpdateExisting CURSOR FOR
	SELECT TargetCurricID, TargetDocID FROM @CurriDocSource
OPEN UpdateExisting
FETCH NEXT FROM UpdateExisting INTO @Cur, @docId

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS (SELECT 1 FROM schema.table2 WHERE DocumentID=@docId and CurriculumID= @Cur)
	BEGIN
			INSERT INTO schema.table2
			SELECT @Cur, @docId, (SELECT COUNT(1) FROM schema.table2  WHERE CurriculumID = @Cur)
	END
	FETCH NEXT FROM UpdateExisting INTO @Cur, @docId
END
CLOSE UpdateExisting
DEALLOCATE UpdateExisting

--select * from schema.table2
--select * from schema.table3 
--SELECT * FROM schema.table1 



rollback tran

--drop temp doc1 table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'doc1') AND type in (N'U'))
	DROP TABLE dbo.doc1


--drop temp Curric table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'Curric') AND type in (N'U'))
	DROP TABLE dbo.Curric

	--drop temp NewIDInfo table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'NewIDInfo') AND type in (N'U'))
	DROP TABLE dbo.NewIDInfo

--drop temp NewIDCurri table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'NewIDCurri') AND type in (N'U'))
	DROP TABLE dbo.NewIDCurri

  
---- To disable the feature.  
--EXECUTE sp_configure 'xp_cmdshell', 0;  
--GO  
---- To update the currently configured value for this feature.  
--RECONFIGURE;  
--GO 
---- To remove permission to change options.  
--EXECUTE sp_configure 'show advanced options', 0;  
--GO  
---- To update the currently configured value for advanced options.  
--RECONFIGURE;  
--GO  


