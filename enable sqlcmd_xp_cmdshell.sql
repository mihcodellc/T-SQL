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

--create an proxy account to run xp_cmdshell instead of sqladmin login
--1. Create a login from an Active Directory account that is a domain user
--2. Execute sp_xp_cmdshell_proxy_account using the login's credentials you just created	
-- exec sp_xp_cmdshell_proxy_account [ NULL | { 'account_name' , 'password' } ]	
EXEC sp_xp_cmdshell_proxy_account 'fake_domain\shellProxyUser','reallystrongpassword'	
--3. Create a database role and grant execute rights to xp_cmdshell to that database role
--4. Add the necessary members to that role for anyone you are going to allow to run xp_cmdshell
--5. ensure the proxy account has all necessary rights for running the code
	
--export csv file 
--MyTable
exec xp_cmdshell 'bcp MyDB.MySchema.MyTable out C:\DatabaseBackups\DocInfo.csv -n -T -S MySQL_Instance_Name -U apps -P space15form3 ', no_output


-- **************** run on Destination DB ****************
USE CompanyInformation_TestB

--drop temp DocInfo table
IF  EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'MyTable') AND type in (N'U'))
	DROP TABLE dbo.MyTable


CREATE TABLE dbo.MyTable(
	[CurriculumID] [int] NOT NULL,[DocumentID] [int] NOT NULL,[DocumentPosition] [smallint] NOT NULL
)

go

--need them to be able to loop through all records in the dynamic query when I keep the insert id for use later on
CREATE TABLE dbo.NewIDInfo (DocID_New INT, DocID_ex INT)
CREATE TABLE dbo.NewIDCurri (CurriID_New INT, CurriID_ex INT)



--import natively
--MyTable
exec xp_cmdshell 'bcp MyDB.MySchema.MyTable in C:\DatabaseBackups\DocInfo.csv -n -T -S QA5\SQL2012 -U apps -P space15form3 ', no_output
go


	---your code for the server/datbase ....
  
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

