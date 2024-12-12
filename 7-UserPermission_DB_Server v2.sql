------ orphan user from all db on the instance' this can be error: 
	--Cannot execute as the database principal because the principal, this type of principal cannot be impersonated, or you do not have permission.


----permissions, privileges
--EXEC rmsAdmin.dbo.UserPermission_DB_Server 
--@LoginUser = [gsikes]
--,@UserDB = Master
----@permission = 'update' 


-- consider sp_help_permissions instead if don't have impersonate permission

--Last update 1/9/2022 : Monktar Bello - query all db for members of a role and link user role with its database for overview of user's role cross all databases
-- 11/01/2022 : Monktar Bello - added comment to get from public account not listed  because of principal_id > 0 /*0 ie public */
-- 10/31/2022 : Monktar Bello - a select for denied permission and and filter #objectPermission with @permission
-- 10/25/2022 : Monktar Bello - permissions attached to only database - sysname(schema,object) replaced with varchar because it doesn't allow null in #objectPermission
-- 10/19/2022 : Monktar Bello - fixed not return objects' permission on @userDB 
-- 4/5/2022 : Monktar Bello - put in @UserDB and filtered with @LoginUser  


/***

-- consider sp_help_permissions instead if don't have impersonate permission


/*============================================================================
  File:     UserPermission_DB_Server.sql
  Summary:  
	   Run without a specific permission, it returns 
		  -all single database principals with their permissions 4238
	   
	   it loop through all databases & current server

  	   Mainly, I'm using "fn_my_permissions" & "execute as" for each principal.
	   I need to work on implicit(inherit) permissions. one solution should be to customize "fn_my_permissions"

	   SET @permission IF you need to exclude an EXPLICIT permission DEFAULTED TO '%SELECT%'.
	   @permission prevails over @LoginUser
	   Get permissions on server need "execute as login" 
	   Get permissions on db need "execute as user".
	   
	   name like '##%' 
	   name like 'NT%'  
	   name of type IN ('G','R', 'C') are excluded -- group, role, certificate
		  details about the above 3 names come from : 
			 sys.server_principals, 
			 server_permissions,  
			 database_principals, 
			 database_permissions

	   name in 'public', 'INFORMATION_SCHEMA','sys' are excluded

				
  Date:     March 2021
  Version:	SQL Server 2017
------------------------------------------------------------------------------
  Written by Monktar Bello
============================================================================*/
**/
---- the login should be different than yourself
--USE master
--GO
--revoke IMPERSONATE ANY LOGIN TO [mbello]  -- REVOKE IMPERSONATE ON USER::[cross] TO [mbello] AS [cross]
--GO


--check execution context at begin and the end
--select USER_NAME() dbUser, SUSER_SNAME() ServerUser

set nocount on;
set transaction isolation level read uncommitted
go

--revoke execute on schema::billingrevamp to accounting
------grant execute on schema::billingrevamp to billing_new
--revoke execute on object::dbo.[Billing_UpdateBtrRecord] to billing_new


declare @LoginUser sysname, @canImpersonate int, @permission sysname, @type char(1), @db sysname, @UserDB sysname; 
declare @query nvarchar(2000)
declare @clause nvarchar(2000)

set @query = ''

--SET @permission = '%KILL%'; --apickens@rmsweb.com sfranco@rmsweb.com  codonnell@rmsweb.com
SET @LoginUser = 'codonnell'
--SET @UserDB = 'MedRx_test' 

--grant execute on database::MedRx_test to DOA
--create role DOA
--alter role DOA add member jfranco

--grant alter on schema::dbo to data_science
--CREATE USER zfesler FOR LOGIN zfesler
--EXEC sp_addrolemember 'devops_jr', 'zfesler'
--revoke select on database::RmsAdmin to gsikes

--use RMSOCR
--create role data_science
--EXEC sp_addrolemember 'data_science', 'zfesler'
--CREATE USER gsikes FOR LOGIN gsikes 
--EXEC sp_addrolemember 'data_science', 'gsikes'
--grant SHOWPLAN on database::RMSOCR to data_science

--EXEC sp_droprolemember 'devops_jr', 'zfesler' 
--EXEC sp_droprolemember 'devops_jr', 'gsikes' 
--use archive


--if @UserDB is not null and @LoginUser is not null
--begin
--    SELECT 'Please, use @LoginUser or @UserDB ' AS REQUIREMENT
--    return
--end

SELECT @canImpersonate = HAS_PERMS_BY_NAME(null, null, 'IMPERSONATE ANY LOGIN');

IF @canImpersonate = 0
    print 'the caller doesn''t the permission IMPERSONATE ANY LOGIN';


IF @canImpersonate = 1
BEGIN

    DECLARE @name sysname;
    if object_id('tempdb..#UserPermissions') is not null
	   drop table #UserPermissions
    if object_id('tempdb..#Principals') is not null
	   drop table #Principals
    if object_id('tempdb..#uROLES') is not null
	   drop table #uROLES
    CREATE TABLE #UserPermissions ([User/Login] sysname
							 ,Entity_Name sysname
							 , SubEntity_Name sysname
							 , Permission_Name sysname
							 , db sysname
							 , state_desc nvarchar(50)
						    )
    CREATE TABLE #Principals(name sysname, isLoginUser nvarchar(15), type char(1), db sysname);
    CREATE TABLE #uROLES (
	RoleON VARCHAR(15)
	,rolename SYSNAME
	,PrincipalName SYSNAME
	,CurrentDB SYSNAME
	)

 drop table if exists #members
 create table #members (RoleName sysname, DBUser sysname, MemberID int, CurrentDB SYSNAME)


    INSERT INTO #Principals
    SELECT name, 'LOGIN',  type, '' 
    FROM sys.server_principals
    WHERE NAME NOT IN ('public') --
		and name not like '##%' -- not sure some are SQL login and others are certificate
		and name not like 'NT %'
		and type not in ('G','R', 'C')
		and (name=@LoginUser or @LoginUser is null )

    IF LEN(@UserDB) > 0
    BEGIN
	   set @clause = '
	   use [' + @UserDB + '];
	   INSERT INTO #Principals
	   SELECT name, ''USER'', type, db_name() as db 
		  FROM sys.database_principals
		  WHERE NAME NOT IN (''public'', ''INFORMATION_SCHEMA'',''sys'') --
			   and name not like ''##%'' -- not sure some are SQL login and others are certificate 
			   and name not like ''NT %'' -- network principal
			   and type not in (''G'',''R'')
		  ORDER BY NAME;
	   '
	    exec (@clause)    END
    ELSE
    BEGIN
	   set @clause = '
	   use [?]
	   INSERT INTO #Principals
	   SELECT name, ''USER'', type, db_name() as db 
		  FROM sys.database_principals
		  WHERE NAME NOT IN (''public'', ''INFORMATION_SCHEMA'',''sys'') --
			   and name not like ''##%'' -- not sure some are SQL login and others are certificate 
			   and name not like ''NT %'' -- network principal
			   and type not in (''G'',''R'')
		  ORDER BY NAME;
	   '
	    exec sp_MSforeachdb @clause
     END
   
    --***CURSOR ON USER
    DECLARE UserCursor CURSOR FOR
	   SELECT distinct name, db  
	   FROM #Principals
	   WHERE isLoginUser = 'USER'  AND (db = @UserDB OR  @UserDB IS NULL)

    OPEN UserCursor 
    FETCH NEXT FROM UserCursor INTO @name,  @db
    --what about db user without login on the server OR Group
    --CREATE DATABASE 

    WHILE @@FETCH_STATUS = 0
    BEGIN
	   IF DB_ID(@db) IS NOT NULL
	   begin
		  set @query = '
		  use [' + @db + '];
	  
		  IF EXISTS(SELECT 1 FROM sys.server_principals WHERE name = @name) 
		  BEGIN
			 -- Set the execution context on user
			 EXECUTE AS user = @name;
			 -- permission on db
			 INSERT INTO #UserPermissions
			 SELECT @name, entity_name, subentity_name, permission_name,  db_name(), '''' 
			 FROM fn_my_permissions(null, ''database'');
			 REVERT;
		  END
		  
		  INSERT INTO #UserPermissions
		  select  principals.name principalName,permissionst.class_desc, 
				coalesce(tp.table_schema +''.''+tp.table_name, 
						  cp.table_schema +''.''+cp.table_name, case when object_name( permissionst.major_id) is not null then object_name( permissionst.major_id) else '''' end) as subentity_name, --may need improvement also reliable schema is in sys.objects 
				coalesce(tp.PRIVILEGE_TYPE, cp.PRIVILEGE_TYPE
				, permissionst.permission_name)  COLLATE DATABASE_DEFAULT as permission_name
				,  db_name(), permissionst.state_desc
		  from sys.database_principals principals
		  join sys.database_permissions permissionst
			 on permissionst.grantee_principal_id = principals.principal_id
		  left join INFORMATION_SCHEMA.TABLE_PRIVILEGES tp
			 on tp.GRANTEE = principals.name 
		  left join INFORMATION_SCHEMA.COLUMN_PRIVILEGES cp
			 on cp.GRANTEE = principals.name	
			 WHERE principals.name = @name
		  
		  '
	   
		  exec sp_executesql @query, N'@name sysname, @db sysname', @name = @name, @db = @db
	   end

	   FETCH NEXT FROM UserCursor INTO  @name, @db
    END
    CLOSE UserCursor
    DEALLOCATE UserCursor




    --***CURSOR ON LOGIN
    DECLARE UserCursor CURSOR FOR
	   SELECT name 
	   FROM #Principals
	   WHERE isLoginUser = 'LOGIN' 
	   		and (name=@LoginUser or @LoginUser is null )


    OPEN UserCursor 
    FETCH NEXT FROM UserCursor INTO @name

    WHILE @@FETCH_STATUS = 0
    BEGIN
	  
		  INSERT INTO #UserPermissions
		  select principals.name principalName
			    ,permissionst.class_desc
			    , ''''
			    , permissionst.permission_name
			    , db_name()
			    , permissionst.state_desc
		  from sys.server_principals principals
		  join sys.server_permissions permissionst
			 on permissionst.grantee_principal_id = principals.principal_id
			 WHERE principals.name =  @name  
	   FETCH NEXT FROM UserCursor INTO  @name
    END
    CLOSE UserCursor
    DEALLOCATE UserCursor



    -- get other details on those I can''t run with "execute as"  
    IF @UserDB IS NOT NULL
    BEGIN
	    set @clause = ' use [' + @UserDB + '];
    	    INSERT INTO #UserPermissions
	   select distinct principals.name principalName,permissionst.class_desc, 
			 coalesce(tp.table_schema +''.''+tp.table_name, 
					   cp.table_schema +''.''+cp.table_name, case when object_name( permissionst.major_id) is not null then object_name( permissionst.major_id) else '''' end) as subentity_name, --may need improvement also reliable schema is in sys.objects 
			 coalesce(tp.PRIVILEGE_TYPE, cp.PRIVILEGE_TYPE
			 , permissionst.permission_name)  COLLATE DATABASE_DEFAULT as permission_name
			 , db_name(), permissionst.state_desc
	   from sys.database_principals principals
	   join sys.database_permissions permissionst
		  on permissionst.grantee_principal_id = principals.principal_id
	   left join INFORMATION_SCHEMA.TABLE_PRIVILEGES tp
		  on tp.GRANTEE = principals.name 
	   left join INFORMATION_SCHEMA.COLUMN_PRIVILEGES cp
		  on cp.GRANTEE = principals.name	
	   WHERE principals.name NOT IN (''public'') and --
		  ( principals.name  like ''##%'' -- not sure some are SQL login and others are certificate
		  or principals.name  like ''NT %''
		  or principals.type  in (''G'', ''C'',''R'')
		  )
		  and (name=''' + @LoginUser + ''' or 1=1 )
	   ';

	    exec (@clause)
	END


    INSERT INTO #UserPermissions
    select principals.name principalName,permissionst.class_desc, '''', permissionst.permission_name COLLATE DATABASE_DEFAULT
		  , db_name(), permissionst.state_desc
    from sys.server_principals principals
    join sys.server_permissions permissionst
	   on permissionst.grantee_principal_id = principals.principal_id
    WHERE principals.NAME NOT IN ('public') and --
		  ( principals.name  like '##%' -- not sure some are SQL login and others are certificate
		  or principals.name  like 'NT %'
		  or principals.type  in ('G', 'C','R')
		  )
    

    IF LEN(@permission) > 0
	   begin
		  declare @title sysname;

		  SELECT 'Principals an explicit permission: ' + @permission

		  SELECT DISTINCT [User/Login] --,Entity_Name, SubEntity_Name, Permission_Name
		  FROM #UserPermissions
		  WHERE Permission_Name LIKE @permission
		  ORDER BY [User/Login]	   
	   end
    ELSE 
    begin
	   SELECT DISTINCT [User/Login],Entity_Name, SubEntity_Name, Permission_Name, case when Entity_Name='SERVER' THEN '' ELSE  db END as dbName, state_desc
	   FROM #UserPermissions u
	   WHERE ([User/Login] = @LoginUser OR  @LoginUser IS NULL) and (db = @UserDB OR  @UserDB IS NULL)
	   ORDER BY Entity_Name, dbName, [User/Login],  Permission_Name
    end

    --MEMBERS OF ROLES
    set @clause = '
	   INSERT INTO #uROLES
	   exec sp_helpMemberOfRole 
    '
    EXEC sp_ineachdb @command = @clause

    --exec sp_helpMemberOfRole    @UserLogin = dkarake ,   @srvrolename  = NULL,  @rolename  =   'db_datawriter' 
    ---- EXEC sp_helprolemember 'devops_sr';
    ---- or
    ----    --members and their principals on database level
    --SELECT rol.name AS DatabaseRoleName,   
    --   isnull (us.name, '') AS UserMemberName, us.principal_id MemberID   
    -- FROM sys.database_principals AS rol    
    -- LEFT JOIN  sys.database_role_members AS mb
    --	   ON mb.role_principal_id = rol.principal_id  
    -- LEFT JOIN sys.database_principals AS us  
    --	   ON mb.member_principal_id = us.principal_id  
    --WHERE rol.type = 'R' and rol.name = 'devdba'
    --ORDER BY  rol.name;  

    SELECT DISTINCT PrincipalName,  rolename, RoleON, CurrentDB
    FROM #uROLES
    WHERE (PrincipalName = @LoginUser OR  @LoginUser IS NULL) 
    ORDER BY CurrentDB, PrincipalName

    SELECT DISTINCT PrincipalName,  rolename
    FROM #uROLES
    WHERE (PrincipalName = @LoginUser OR  @LoginUser IS NULL) 
    ORDER BY PrincipalName


    set @clause = '
    insert into #members
     SELECT rol.name AS DatabaseRoleName,  
       isnull (us.name, '''') AS UserMemberName, us.principal_id MemberID, db_name() CurrentDB  
     FROM sys.database_principals AS rol    
     LEFT JOIN  sys.database_role_members AS mb
    	   ON mb.role_principal_id = rol.principal_id  
     LEFT JOIN sys.database_principals AS us  
    	   ON mb.member_principal_id = us.principal_id  
    WHERE rol.type = ''R'' and 
		exists( select 1/0 from #uROLES r where r.rolename = rol.name and ' + case when @LoginUser is null then ' 1= 1 ' else ' (r.PrincipalName = ''' + @LoginUser   + ''' )' end + ' ) 
    order by 1, CurrentDB
    '

    EXEC sp_ineachdb @command = @clause

    --if @LoginUser is not null
	   --delete from #members where DBUser <> @LoginUser

    select ' on DB level, members of the roles to which @LoginUser belongs to'
    select * from #members order by CurrentDB, RoleName

    select ' on Server level, members of the roles to which @LoginUser belongs to'
    --server role and member
    SELECT rol.name AS ServerRoleName,   
       isnull (us.name, '') AS UserMemberName,SUSER_ID(us.loginname) server_principal_id   
     FROM sys.server_principals AS rol    
     LEFT JOIN  sys.server_role_members AS mb
    	   ON mb.role_principal_id = rol.principal_id  
     LEFT JOIN sys.syslogins AS us  
    	   ON mb.member_principal_id = SUSER_ID(us.loginname)  
    WHERE rol.type = 'R' --and rol.name = 'rmsadmin_user'
    and (us.name = @LoginUser OR  @LoginUser IS NULL)
    ORDER BY  rol.name;  

    ----server/db ids and names
    --select *, SUSER_NAME(member_principal_id) as login_id_or_principal_id from sys.server_role_members where member_principal_id = 789
    --select name , denylogin, sysadmin, SUSER_SID(loginname) as security_id_or_sid, 
		  --SUSER_ID (loginname) as server_principal_id, 
		  --DATABASE_PRINCIPAL_ID(loginname) as db_principal_id  from sys.syslogins where loginname = 'mbello'
    --select * from sys.server_role_members 

    select ' on Server level, permissions granted to its group '
    select principals.name principalName,permissionst.class_desc, permissionst.permission_name COLLATE DATABASE_DEFAULT as 'permission'
		  , permissionst.state_desc
    from sys.server_principals principals
    join sys.server_permissions permissionst
	   on permissionst.grantee_principal_id = principals.principal_id
    WHERE principals.NAME in (
		  SELECT rol.name AS ServerRoleName   
			--,isnull (us.name, '') AS UserMemberName,SUSER_ID(us.loginname) server_principal_id   
		   FROM sys.server_principals AS rol    
		   LEFT JOIN  sys.server_role_members AS mb
    			 ON mb.role_principal_id = rol.principal_id  
		   LEFT JOIN sys.syslogins AS us  
    			 ON mb.member_principal_id = SUSER_ID(us.loginname)  
		  WHERE rol.type = 'R' --and rol.name = 'rmsadmin_user'
		  and (us.name = @LoginUser OR  @LoginUser IS NULL)
    )


     select '*********permissions get from being member of a role **********'
    -- permissions get from being member of a role
    create table #objectPermission (
    principalName sysname,	PrincipalID int,	permission_name sysname,	state_desc varchar(128),	
    class_desc varchar(128),	SchemaName varchar(128),	ObjName varchar(128),	IsTable bit,	IsTrigger bit,	IsView bit,	IsProcedure bit,	CurrentDatabase sysname
    )

    	   set @clause = '
        insert into #objectPermission
	   select principals.name principalName, principal_id PrincipalID
	   , permissionst.permission_name COLLATE DATABASE_DEFAULT
	   , permissionst.state_desc 
	   , permissionst.class_desc 
	   , OBJECT_SCHEMA_NAME(permissionst.major_id) SchemaName 
	   ,  object_name( permissionst.major_id) ObjName ,
	   OBJECTPROPERTY(permissionst.major_id, ''IsTable'') AS [IsTable],
	   OBJECTPROPERTY(permissionst.major_id, ''IsTrigger'') AS [IsTrigger],
	   OBJECTPROPERTY(permissionst.major_id, ''IsView'') AS [IsView],
	   OBJECTPROPERTY(permissionst.major_id, ''IsProcedure'') AS [IsProcedure]
	   , DB_NAME() CurrentDatabase 
	   from sys.database_principals principals
	   join sys.database_permissions permissionst
	   on permissionst.grantee_principal_id = principals.principal_id
	   WHERE  EXISTS(SELECT 1 FROM #uROLES r where r.rolename = principals.name COLLATE DATABASE_DEFAULT and ' + case when @LoginUser is null then ' 1= 1 ' else ' (PrincipalName = ''' + @LoginUser   + ''' )' end + ' )
	   --and OBJECT_SCHEMA_NAME(permissionst.major_id) is not null
	   order by principalName, permission_name
	   '
	   EXEC sp_ineachdb @command = @clause


    -- permissions to a role
    --select principals.name principalName, principal_id PrincipalID
    --, permissionst.permission_name, permissionst.state_desc, permissionst.class_desc
    --, OBJECT_SCHEMA_NAME(permissionst.major_id) SchemaName
    --,  object_name( permissionst.major_id) ObjName,
    --OBJECTPROPERTY(permissionst.major_id, 'IsTable') AS [IsTable],
    --OBJECTPROPERTY(permissionst.major_id, 'IsTrigger') AS [IsTrigger],
    --OBJECTPROPERTY(permissionst.major_id, 'IsView') AS [IsView],
    --OBJECTPROPERTY(permissionst.major_id, 'IsProcedure') AS [IsProcedure], DB_NAME() CurrentDatabase
    --from sys.database_principals principals
    --join sys.database_permissions permissionst
    --on permissionst.grantee_principal_id = principals.principal_id
    --where principal_id > 0 /*0 ie public */ --AND EXISTS(SELECT 1 FROM #uROLES r where r.rolename = principals.name and (r.PrincipalName = @LoginUser OR  @LoginUser IS NULL))
    --AND principals.name in ('devdba')
    ------and permission_name ='UPDATE'
    ----order by principalName, permission_name

    select '********* all or specific permissions **********'
    select * from  #objectPermission
    where (permission_name like '%'+@permission+'%' OR  @permission IS NULL) and (CurrentDatabase = @UserDB OR  @UserDB IS NULL)
	order by principalName

    select '*********denied permission **********'
    --select * from  #objectPermission
    --where (permission_name like '%'+@permission+'%' OR  @permission IS NULL) and (CurrentDatabase = @UserDB OR  @UserDB IS NULL)
		  --and state_desc like '%DENY%'
    --order by principalName

     SELECT DISTINCT [User/Login],Entity_Name, SubEntity_Name, Permission_Name, case when Entity_Name='SERVER' THEN '' ELSE  db END as dbName, state_desc
	   FROM #UserPermissions u
	   WHERE state_desc like '%DENY%' and ([User/Login] = @LoginUser OR  @LoginUser IS NULL) and (db = @UserDB OR  @UserDB IS NULL)
	   ORDER BY Entity_Name, dbName, [User/Login],  Permission_Name


select '*********hidden permission from public commented **********'
---- https://www.mssqltips.com/sqlservertip/4228/sql-server-permissions-granted-to-all-users-by-default/
--    select principals.name principalName, principal_id PrincipalID
--, permissionst.permission_name, permissionst.state_desc, permissionst.class_desc
--,  object_name( permissionst.major_id) ObjName,
--OBJECTPROPERTY(permissionst.major_id, 'IsTable') AS [IsTable],
--OBJECTPROPERTY(permissionst.major_id, 'IsTrigger') AS [IsTrigger],
--OBJECTPROPERTY(permissionst.major_id, 'IsView') AS [IsView],
--OBJECTPROPERTY(permissionst.major_id, 'IsProcedure') AS [IsProcedure], DB_NAME() CurrentDatabase
--from sys.database_principals principals
--right join sys.database_permissions permissionst on permissionst.grantee_principal_id = principals.principal_id
--WHERE 
-- principals.name in ('public') and permissionst.permission_name = 'Execute'
----and permission_name ='UPDATE'
--order by principalName, permission_name

    --all logins
    if @LoginUser is null
    begin
        --all logins
	   select name as [SQL_Logins] from sys.server_principals order by name

	   --sysadmins : sp_helpsrvrolemember 'sysadmin' isnot ordered
	   SELECT DISTINCT PrincipalName as isSysAdmin 
	   FROM #uROLES
	   WHERE (PrincipalName = @LoginUser OR  @LoginUser IS NULL) and rolename = 'sysadmin'
	   ORDER BY PrincipalName
    end

    IF OBJECT_ID('tempDB..#UserPermissions') IS NOT NULL
	   DROP TABLE #UserPermissions

    IF OBJECT_ID('tempDB..#Principals') IS NOT NULL
	   DROP TABLE #Principals

    IF OBJECT_ID('tempDB..#uROLES') IS NOT NULL
	   DROP TABLE #uROLES

    IF OBJECT_ID('tempDB..#members') IS NOT NULL
	   DROP TABLE #members

    IF OBJECT_ID('tempDB..#objectPermission') IS NOT NULL
    DROP TABLE #objectPermission

    --select USER_NAME() dbUser, SUSER_SNAME() ServerUser /* a login name*/, SYSTEM_USER /* login whether windows or sql authentif*/
  
END


--know the execution context
select * from sys.sysusers
select * from sys.user_token --included every role on the db
select * from sys.login_token
select SUSER_SNAME() as [SUSER_SNAME_from_sid_param], SUSER_NAME() as [SUSER_NAME_from_LogIdNumber_param],  USER_NAME() as UserNameDB_fromIDnum, SYSTEM_USER as [LOGIN], user as [DBuser]

