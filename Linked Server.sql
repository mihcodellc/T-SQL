USE [master]
GO
/*
--Last Changed -- Date: 2/2/2021 -- By: Monktar Bello - Initial version
-- note: Enable Promotion of distributed Transaction in properties: True/false 
--      ie local transaction that can be automatically promoted to a fully distributable transaction as needed
--      if local or the existing connection, set it to false
--      this is just to avoid overhead of distributed transactions
 
***************INSTRUCTIONS - start
--it will link to a remote server specified in @datasrc

aliasDB is the alias I gave the remote server in @server
@datasrc has the sql instance name and port
@catalog is the default database on remote DB
@rmtpassword is the password to connect to the remote server. NEEDS TO BE CHANGED

all the statements to line 35 should be run. Then the queries below can be used to test
***************INSTRUCTIONS - end

*/
EXEC master.dbo.sp_addlinkedserver @server = N'aliasDB', @srvproduct=N'', @provider=N'SQLNCLI', @datasrc=N'InstanceName,port', @catalog=N'defaultDB'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'aliasDB',@useself=N'False',@locallogin=NULL,@rmtuser=N'a_schema',@rmtpassword='########'
GO
/* collation to be used on both */ 
EXEC master.dbo.sp_serveroption @server=N'aliasDB', @optname=N'collation compatible', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'aliasDB', @optname=N'use remote collation', @optvalue=N'true'
GO

/* enable access to remote */
EXEC master.dbo.sp_serveroption @server=N'aliasDB', @optname=N'data access', @optvalue=N'true'
GO
/* give access to stored procedure */ 
EXEC master.dbo.sp_serveroption @server=N'aliasDB', @optname=N'rpc', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'aliasDB', @optname=N'rpc out', @optvalue=N'true'
GO



--	query
-----on local
select dob from idefaultDB.a_schema.a_table where patientid = 660
declare @p4 bigint
set @p4=46
EXEC idefaultDB.a_schema.usp_StoredProcedure @WhereClause='', @PageSize=100000,@PageNo=1,@TotalRows=@p4 output
select @p4

-----on remote
select dob from aliasDB.defaultDB.a_schema.a_table where patientid = 660
declare @p4 bigint
set @p4=46
EXEC aliasDB.defaultDB.a_schema.usp_StoredProcedure @WhereClause='', @PageSize=100000,@PageNo=1,@TotalRows=@p4 output
select @p4

