-- **************** BEGIN INSTRUCTIONS  ****************
-- activate  xp_cmdshell: you may use the script below to activate it. Please inactivate it at the end
-- To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  
--distinguish first part "run on source DB" and second  part "run on Destination DB"

--activate SQLCMD Mode using SSMS -> Menu bar -> Query -> SQLCMD Mode.  Please inactivate it at the end
--replace CVS path: C:\DatabaseBackups\ -- SQL Server should be able to write to folder
--replace destination DB: CompanyInformation_TestB
--replace source DB: CompanyInformation_Test
--replace the server QA5\SQL2012. The script uses the same server for SOURCE DB and DESTINATION DB
--3 tables are concerned mainly: DocumentInfo, TRN_CurriculumDocument, TRN_Curriculum
																							


-- **************** END INSTRUCTIONS  ****************

-- **************** run on Source DB ****************

--export csv file 
--docinfo
exec xp_cmdshell 'bcp CompanyInformation_Test.ONSInternal.DocumentInfo out C:\DatabaseBackups\DocInfo.csv -n -T -S QA5\SQL2012 -U apps -P space15form3 ', no_output
--Curric
exec xp_cmdshell 'bcp CompanyInformation_Test.ONSInternal.TRN_Curriculum out C:\DatabaseBackups\Curric.csv -n -T -S QA5\SQL2012 -U apps -P space15form3 ', no_output
--CurriDoc
exec xp_cmdshell 'bcp CompanyInformation_Test.ONSInternal.TRN_CurriculumDocument out C:\DatabaseBackups\CurriDoc.csv -n -T -S QA5\SQL2012 -U apps -P space15form3 ', no_output


-- **************** run on Destination DB ****************
USE CompanyInformation_TestB

--drop temp DocInfo table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'DocInfo') AND type in (N'U'))
	DROP TABLE dbo.DocInfo


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

--create DocInfo 
CREATE TABLE dbo.DocInfo (
	DocID int NOT NULL,Title varchar(100) NOT NULL,	Description varchar(5000) NOT NULL,	FileName varchar(175) NOT NULL,	LastUpdate datetime NOT NULL,
	DocType smallint NOT NULL,DocCategory int NOT NULL,	DocSize bigint NOT NULL,ProductID_FK int NOT NULL,	EmbedCode varchar(1500) NULL,	DateCreated datetime NOT NULL,
	SyncToProductHelp bit NOT NULL,	SearchKeys varchar(5000) NOT NULL,	Active bit NOT NULL,ClientDescription varchar(5000) NOT NULL,	ControlHelpKey varchar(100) NOT NULL,
	EntryStamp datetime NOT NULL
)
  



CREATE TABLE dbo.Curric(
	CurriculumID int NOT NULL,Title varchar(50) NOT NULL,
	LastChange datetime NOT NULL,Active bit NOT NULL,ExpireDate datetime NOT NULL,
	GroupLevel tinyint NOT NULL,SyncToProductHelp bit NOT NULL
 )
  


CREATE TABLE dbo.CurriDoc(
	[CurriculumID] [int] NOT NULL,[DocumentID] [int] NOT NULL,[DocumentPosition] [smallint] NOT NULL
)

go

--need them to be able to loop through all records in the dynamic query when I keep the insert id for use later on
CREATE TABLE dbo.NewIDInfo (DocID_New INT, DocID_ex INT)
CREATE TABLE dbo.NewIDCurri (CurriID_New INT, CurriID_ex INT)



--import natively
--DocInfo
exec xp_cmdshell 'bcp CompanyInformation_TestB.dbo.DocInfo in C:\DatabaseBackups\DocInfo.csv -n -T -S QA5\SQL2012 -U apps -P space15form3 ', no_output
go
--Curric
exec xp_cmdshell 'bcp CompanyInformation_TestB.dbo.Curric in C:\DatabaseBackups\Curric.csv -n -T -S QA5\SQL2012 -U apps -P space15form3 ', no_output
go
--CurriDoc
exec xp_cmdshell 'bcp CompanyInformation_TestB.dbo.CurriDoc in C:\DatabaseBackups\CurriDoc.csv -n -T -S QA5\SQL2012 -U apps -P space15form3 ', no_output
go

USE CompanyInformation_TestB

DECLARE @Cur INT, @docId INT

--staging table, no confusion with the one uses to import the data. bcp not allowed to add more column needed for later
declare  @DocInfo TABLE (
	DocID int NOT NULL,Title varchar(100) NOT NULL,	Description varchar(5000) NOT NULL,	FileName varchar(175) NOT NULL,	LastUpdate datetime NOT NULL,
	DocType smallint NOT NULL,DocCategory int NOT NULL,	DocSize bigint NOT NULL,ProductID_FK int NOT NULL,	EmbedCode varchar(1500) NULL,	DateCreated datetime NOT NULL,
	SyncToProductHelp bit NOT NULL,	SearchKeys varchar(5000) NOT NULL,	Active bit NOT NULL,ClientDescription varchar(5000) NOT NULL,	ControlHelpKey varchar(100) NOT NULL,
	EntryStamp datetime NOT NULL, TargetID int Not Null Default 0
)

--debug let known if duplicated exists
SELECT a.filename 'duplicated doc not part of this script', a.doctype FROM @DocInfo  a 
group by a.filename, a.doctype
having count(a.filename)>1

-- remove duplicate doc
INSERT INTO @DocInfo 
SELECT a.DocID, a.Title, a.Description, a.FileName, a.LastUpdate, a.DocType, a.DocCategory, a.DocSize, a.ProductID_FK, isnull(a.EmbedCode,'')EmbedCode, a.DateCreated, a.SyncToProductHelp, a.SearchKeys, a.Active, a.ClientDescription, a.ControlHelpKey, a.EntryStamp,0 from dbo.DocInfo a where not exists 
(
SELECT b.filename, b.doctype FROM DocInfo  b 
where a.FileName = b.FileName and a.DocType = b.DocType
group by b.filename, b.doctype
having count(b.filename)>1
)


declare  @Curric TABLE(
	CurriculumID int NOT NULL,Title varchar(50) NOT NULL,
	LastChange datetime NOT NULL,Active bit NOT NULL,ExpireDate datetime NOT NULL,
	GroupLevel tinyint NOT NULL,SyncToProductHelp bit NOT NULL, TargetID int Not Null Default 0
 )

 --debug let known if duplicated exists
SELECT b.Title 'duplicated curriculum not part of this script' FROM dbo.Curric b 
group by b.Title
having count(b.Title)>1


INSERT INTO @Curric 
SELECT a.CurriculumID, a.Title, a.LastChange, a.Active, a.ExpireDate, a.GroupLevel, a.SyncToProductHelp, 0 from dbo.Curric a where not exists
(
SELECT b.Title FROM dbo.Curric b 
WHERE a.Title = b.Title
group by b.Title
having count(b.Title)>1
)


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
	and DocumentID in (select DocID from @DocInfo)

SELECT  CurriculumID, DocumentID, DocumentPosition,'orphan relation' from dbo.CurriDoc
where CurriculumID not in (select CurriculumID from @Curric)
or DocumentID not in (select DocID from @DocInfo)

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




--begin tran

DECLARE @query NVARCHAR(max) 
DECLARE @print NVARCHAR(max) 
SET @print = ' '
SET @query = '' + Char(13) 

----update DocumentInfo and get the id of existing doc
DECLARE UpdateExisting CURSOR FOR   
    SELECT  
	    'UPDATE ONSInternal.DocumentInfo ' +   Char(13) +
		'SET Title = ''' + replace(Title,'''','''''') + ''''+ Char(13) +
		'	 ,LastUpdate = getdate() ' +  Char(13) +
		'	 ,DocCategory = ' + CONVERT(VARCHAR(11), DocCategory) + Char(13) + 
		' 	 ,DocSize = ' + CONVERT(VARCHAR(20), DocSize)  + Char(13) +
		' 	 ,ProductID_FK = ' + CONVERT(VARCHAR(11), ProductID_FK) + Char(13) + 
		' 	 ,EmbedCode = ''' + ISNULL(EmbedCode,'') +  ''' ' + Char(13) +
		'    ,DateCreated = ''' + CONVERT(VARCHAR(25), DateCreated) + ''' ' + Char(13) +
		'    ,SyncToProductHelp = ' + CONVERT(VARCHAR(1), SyncToProductHelp)  + Char(13) +
		'    ,SearchKeys =  ''' + SearchKeys + '''  ' +  Char(13) +
		'    ,Active = ' + CONVERT(VARCHAR(1), Active) + Char(13) +
		'    ,ControlHelpKey = '''+ replace(ControlHelpKey,'''','''''') + ''' '+ Char(13) +
		'    ,EntryStamp = getdate() '  + '  ' + Char(13) +
		'    OUTPUT inserted.DocID, '+ CONVERT(VARCHAR(11), DocID) + ' INTO dbo.NewIDInfo '+
		'WHERE FileName = ''' + FileName + ''' AND DocType = ' + CONVERT(VARCHAR(11), DocType) + ' '+ Char(13)
	FROM @DocInfo  a
	WHERE EXISTS (select 1  from ONSInternal.DocumentInfo b where a.FileName = b.FileName and a.DocType = b.DocType) 
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


--update documentInfo on columns too large to be updated  through the previous update
UPDATE ONSInternal.DocumentInfo
			SET Description = s.Description, 
			ClientDescription = s.ClientDescription
FROM dbo.DocInfo s WHERE ONSInternal.DocumentInfo.FileName = s.FileName and ONSInternal.DocumentInfo.DocType = s.DocType
																													
	 

--update TRN_Curriculum
DECLARE UpdateExisting CURSOR FOR   
    SELECT  -- top one to avoid duplicated insert
	    'UPDATE  ONSInternal.TRN_Curriculum ' +   Char(13) +
		'	 SET LastChange = getdate() ' +  Char(13) +
		'    ,Active = ' + CONVERT(VARCHAR(1), Active) + Char(13) +
		'    ,ExpireDate = ''' + CONVERT(VARCHAR(25), ExpireDate) + ''' ' + Char(13) +
		'    ,GroupLevel = ' + CONVERT(VARCHAR(4), GroupLevel) + Char(13) +
		'    ,SyncToProductHelp = ' + CONVERT(VARCHAR(1), SyncToProductHelp)  + Char(13) +
		'    OUTPUT inserted.CurriculumID, '+ CONVERT(VARCHAR(11), CurriculumID) + ' INTO dbo.NewIDCurri '+
		'WHERE Title = ''' + Title + ''' '+ Char(13)
	FROM @Curric  a
	WHERE EXISTS (select 1  from ONSInternal.TRN_Curriculum b where a.Title = b.Title)
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

 

--debug
print '***************************doc count before***************************'
select @print=count(filename)  from ONSInternal.DocumentInfo 
print @print
set @print = '' 


WHILE  EXISTS(
		SELECT 1 FROM @DocInfo  a WHERE NOT EXISTS (select 1  from ONSInternal.DocumentInfo b where a.FileName = b.FileName and a.DocType = b.DocType)
		)	 BEGIN
	--insert DocInfo and get newid
	SELECT top 1 @query =  -- top one to avoid duplicated insert
	   'INSERT INTO ONSInternal.DocumentInfo ' +   Char(13) +
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
	FROM @DocInfo  a
	WHERE NOT EXISTS (select 1  from ONSInternal.DocumentInfo b where a.FileName = b.FileName and a.DocType = b.DocType) order by a.DocID

	--print @query
	exec (@query)	
END

--debug
print '***************************doc count after***************************'
select @print=count(filename)  from ONSInternal.DocumentInfo
print @print
set @print = '' 


--debug
print '***************************curri count before***************************'
select @print=count(Title)  from ONSInternal.TRN_Curriculum 
print @print
set @print = '' 


WHILE EXISTS(
		SELECT 1 FROM @Curric a WHERE NOT EXISTS (select 1  from ONSInternal.TRN_Curriculum b where a.Title = b.Title)
		)	 BEGIN
	--insert Curric and get newid
	SELECT top 1 @query =  
	'INSERT INTO ONSInternal.TRN_Curriculum ' +   Char(13) + 
	'OUTPUT inserted.CurriculumID, ' + CONVERT(VARCHAR(11), a.CurriculumID )  + ' INTO dbo.NewIDCurri ' + Char(13) +
	' SELECT  ''' + Title + ''' 
	, getdate() 
	, ' + CONVERT(VARCHAR(1), Active) + ' 
	, ''' + CONVERT(VARCHAR(25), ExpireDate) + ''' 
	, ' + CONVERT(VARCHAR(4), GroupLevel) + ' 
	, ' + CONVERT(VARCHAR(1), SyncToProductHelp) + '  ' + Char(13)
	FROM  @Curric a WHERE NOT EXISTS (select 1  from ONSInternal.TRN_Curriculum b where a.Title = b.Title)
																					  

	--print @query
	exec (@query)
END

--debug
print '**********************curri count after***************************'
select @print = count(Title)  from ONSInternal.TRN_Curriculum
print @print
set @print = ''

  
-- update the imported table with ID to be used in destination DB
--docInfo
UPDATE a SET a.TargetID=b.DocID_New
FROM @docinfo a JOIN dbo.NewIDInfo b ON a.DocID = b.DocID_ex

--Curric
UPDATE a SET a.TargetID=b.CurriID_New
FROM @Curric a JOIN dbo.NewIDCurri b ON a.CurriculumID = b.CurriID_ex


--update DocCurric source
UPDATE a SET a.TargetCurricID = c.TargetID, a.TargetDocID = b.TargetID
FROM @CurriDocSource a
JOIN @DocInfo b ON a.DocumentID = b.DocID
JOIN @Curric c ON a.CurriculumID = c.CurriculumID


--update DocCurric target
DECLARE UpdateExisting CURSOR FOR
	SELECT TargetCurricID, TargetDocID FROM @CurriDocSource
OPEN UpdateExisting
FETCH NEXT FROM UpdateExisting INTO @Cur, @docId

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS (SELECT 1 FROM ONSInternal.TRN_CurriculumDocument WHERE DocumentID=@docId and CurriculumID= @Cur)
	BEGIN
			INSERT INTO ONSInternal.TRN_CurriculumDocument
			SELECT @Cur, @docId, (SELECT COUNT(1) FROM ONSInternal.TRN_CurriculumDocument  WHERE CurriculumID = @Cur)
	END
	FETCH NEXT FROM UpdateExisting INTO @Cur, @docId
END
CLOSE UpdateExisting
DEALLOCATE UpdateExisting

--select * from ONSInternal.TRN_CurriculumDocument
--select * from ONSInternal.TRN_Curriculum 
--SELECT * FROM ONSInternal.DocumentInfo 



--rollback tran

--drop temp DocInfo table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'DocInfo') AND type in (N'U'))
	DROP TABLE dbo.DocInfo


--drop temp Curric table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'Curric') AND type in (N'U'))
	DROP TABLE dbo.Curric

	--drop temp NewIDInfo table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'NewIDInfo') AND type in (N'U'))
	DROP TABLE dbo.NewIDInfo

--drop temp NewIDCurri table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'NewIDCurri') AND type in (N'U'))
	DROP TABLE dbo.NewIDCurri

  
-- To disable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 0;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO 
-- To remove permission to change options.  
EXECUTE sp_configure 'show advanced options', 0;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO

