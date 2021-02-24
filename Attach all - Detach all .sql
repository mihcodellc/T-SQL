---- MUST Capture datatbase details before move forward. You may need 
--USE DBNAME
--GO
--sp_helpfile
--GO

------------------https://blog.sqlauthority.com/2019/01/13/how-to-move-log-file-or-mdf-file-in-sql-server-interview-question-of-the-week-208/

--****************************Detach your listed DBs************************-----------
USE MASTER;
GO
 
DECLARE @DBList CHAR(256)='testBEllo1' -- list the DBs to detach ; separated by comma 
DECLARE @CurrentDB CHAR(50)
DECLARE @CurrentComma SMALLINT
DECLARE @SQLQuery AS NVARCHAR(500)

SET @DBList= REPLACE(@DBList, ' ','')+',F_N'

	
WHILE @DBList<>'F_N'-- F_N is the end of DB's list
BEGIN
	SET @CurrentComma=CHARINDEX(',', @DBList)
	SET @CurrentDB=SUBSTRING(@DBList,0,@CurrentComma)
	SET @DBList=REPLACE(@DBList,RTRIM(@CurrentDB)+',','') --REMOVE A STRING DB + A COMMA
		---- Take database in single user mode -- if you are facing errors
		---- This may terminate your active transactions for database
		--SET @SQLQuery = 'ALTER DATABASE ' + RTRIM(@CurrentDB) + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;'	
		--EXECUTE(@SQLQuery) 
	---- Detach Database
	SET @SQLQuery= 'EXEC MASTER.dbo.sp_detach_db @dbname = '+ RTRIM(@CurrentDB)
	EXECUTE(@SQLQuery)
END

GO

--****************************Attach for all found databases in a folder*******************
--LIMITATION: Only 2 types files of database are expected: .mdf & .ldf
DECLARE @pathDBfiles VARCHAR(256)='' -- path where find backup files  
DECLARE @isThere INT=0
DECLARE @DB_Name VARCHAR(50) -- database name 
DECLARE @LDF_Path VARCHAR(256)='' -- path + name of data file
DECLARE @MDF_Path VARCHAR(256)='' -- path + name of log file
DECLARE @SQLQuery AS NVARCHAR(500)

IF OBJECT_ID('tempdb..#DirTree') IS NOT NULL
    DROP TABLE #DirTree

CREATE TABLE #DirTree (
	Id int identity(1,1),
	SubDirectory nvarchar(255),
	Depth smallint,
	FileFlag bit,
	ParentDirectoryID int
)

-- specify database files' directory
SET @pathDBfiles = 'C:\Backups\'  

 -- insert the list of files on first level in the directory
INSERT INTO #DirTree (SubDirectory, Depth, FileFlag)
   EXEC master..xp_dirtree @pathDBfiles, 1, 1 -- undocumented stored procedures to retrieve a list of child directories under a specified parent directory

DECLARE db_cursor CURSOR READ_ONLY FOR  
   	SELECT Substring(SubDirectory,1,len(SubDirectory)-4) FROM #DirTree WHERE SubDirectory LIKE '%.mdf' -- SELECT ONLY THE.mdf FILES without the extension -- 4 for lenght of ".mdf" 

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @DB_Name   
 
WHILE @@FETCH_STATUS = 0    -- until there is no more backup file
BEGIN   
		--Set the complete path for data
		SET @LDF_Path = @pathDBfiles + @DB_Name + '.LDF'
		SET @MDF_Path = @pathDBfiles + @DB_Name + '.mdf'
		-- check a .ldf exists in the folder
		EXEC master.dbo.xp_fileexist @LDF_Path, @isThere OUTPUT -- xp_fileexist accept only INT as output
	 
	  --script out if the files exist or pop up the requirements
	  IF @isThere=1 BEGIN
		SET @SQLQuery = 'CREATE DATABASE ' + @DB_Name + ' ON (FILENAME = '''+ @pathDBfiles + @DB_Name +'.mdf''),(FILENAME = '''+ @pathDBfiles + @DB_Name +'.ldf'') FOR ATTACH; ';	/* ATTACH | ATTACH_REBUILD_LOG */
		EXECUTE(@SQLQuery)
		PRINT @DB_Name + ' successfully attached.'
	  END
	  ELSE
		PRINT 'Please, review the data and log files'' names for '+@DB_Name+'. It should look like myDB.mdf and myDB.ldf';

	   FETCH NEXT FROM db_cursor INTO @DB_Name   --next database
END   
 
CLOSE db_cursor   
DEALLOCATE db_cursor




------------------ Correct Way to Attach Database
----------------USE [master]
----------------GO
----------------CREATE DATABASE [AdventureWorks2014_new] ON
----------------( FILENAME = 'E:\AdventureWorks2012_Data_new.mdf'),
----------------( FILENAME = 'E:\AdventureWorks2012_log_new.ldf')
----------------FOR ATTACH
----------------GO
---------------------- Deprecated Way to Attach Database
--------------------USE [master]
--------------------GO
--------------------EXEC MASTER.dbo.sp_attach_db 'AdventureWorks2014_new',
--------------------'E:\AdventureWorks2012_Data_new.mdf',
--------------------'E:\AdventureWorks2012_log_new.ldf'
--------------------GO


-------------------https://blog.sqlauthority.com/2014/06/11/sql-server-attach-or-detach-database-sql-in-sixty-seconds-068/
-------------------https://blog.sqlauthority.com/2012/10/28/sql-server-move-database-files-mdf-and-ldf-to-another-location/
------------------https://blog.sqlauthority.com/2019/01/13/how-to-move-log-file-or-mdf-file-in-sql-server-interview-question-of-the-week-208/

----***************************************--How to Move SQL Server MDF and LDF Files?
----https://blog.sqlauthority.com/2018/09/02/how-to-move-sql-server-mdf-and-ldf-files-interview-question-of-the-week-189/
----Original Location
--SELECT name, physical_name AS CurrentLocation, state_desc
--FROM sys.master_files
--WHERE database_id = DB_ID(N'TestBello');
----result of above query
--------AdventureWorks2014		C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\AdventureWorks2014.mdf	ONLINE
--------AdventureWorks2014_log	C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\AdventureWorks2014_log.LDF	ONLINE

----Take Database Offline
--USE master --Important otherwise a failure
--ALTER DATABASE TestBello SET OFFLINE;
----Change the file location inside SQL Server
--ALTER DATABASE TestBello
--MODIFY FILE ( NAME = AdventureWorks2014, FILENAME = 'C:\Backups\TestBello.mdf' ); -- proof that you can change DB files' names 
--ALTER DATABASE TestBello
--MODIFY FILE ( NAME = AdventureWorks2014_log, FILENAME = 'C:\Backups\TestBello_Logs.ldf' );---- proof that you can change DB files' names 
--GO
----Bring Database Online
--ALTER DATABASE TestBello SET ONLINE;





--DECLARE @DatabaseName AS VARCHAR(255)
--DECLARE @Filepath AS VARCHAR(255)
 
--SET @Filepath = 'C:\SQLDATA\'
 
--DECLARE CurAttach CURSOR FOR
--  SELECT name
--  FROM   MASTER.sys.databases
--  WHERE  owner_sid > 1;
 
--OPEN CurAttach
--FETCH Next FROM CurAttach INTO @DatabaseName
--WHILE @@FETCH_STATUS = 0
--  BEGIN      
--	  PRINT 
--		'CREATE DATABASE ' + @DatabaseName + ' ON
--		(FILENAME = '+ @Filepath + @DatabaseName +'.mdf)
--		,(FILENAME = '+ @Filepath + @DatabaseName +'.ldf)
--		FOR ATTACH
--		GO
 
--		ALTER DATABASE '+ @DatabaseName +' SET MULTI_USER WITH ROLLBACK IMMEDIATE
--		GO'
--      FETCH NEXT FROM CurAttach INTO @DatabaseName
--  END
 
--CLOSE CurAttach
--DEALLOCATE CurAttach