-- consider sp_help_permissions instead if don't have impersonate permission
/*
Last update 5/6/2022 : Monktar Bello - put a fix to @LoginUser and roles, certificates, explicit permissions.   
4/5/2022 : Monktar Bello - put in @UserDB and filtered with @LoginUser  

*/
/*============================================================================
  File:     UserPermission_DB_Server.sql
  Summary:  
	   Run without a specific permission, it returns 
		  -all single database principals with their permissions ?
		  -members of a role ?
		  -all logins ?
		  -sysadmin ?

		  !!!!!remember to set @UserDB, @LoginUser, @permission!!!!!!!
	   
	   it loop through all databases & current server

  	   Mainly, I'm using "fn_my_permissions" & "execute as" for each principal.
	   I need to work on implicit(inherit) permissions. one solution should be to customize "fn_my_permissions"

	   SET @permission IF you need to see ONLY EXPLICIT permission - wilcard is accepted.
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
---- the login should be different than yourself
--USE master
--GO
--GRANT IMPERSONATE ANY LOGIN TO [RMS-ASP\mbello]
--GO


--check execution context at begin and the end
--select USER_NAME() dbUser, SUSER_SNAME() ServerUser

set nocount on;
set transaction isolation level read uncommitted
go

declare @LoginUser sysname, @canImpersonate int, @permission sysname, @type char(1), @db sysname, @UserDB sysname; 
declare @query nvarchar(2000)
declare @clause nvarchar(2000)

set @query = ''

--SET @permission = 'execute';
--SET @LoginUser = 'testbello'
SET @UserDB = '?'

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
						    )
    CREATE TABLE #Principals(name sysname, isLoginUser nvarchar(15), type char(1), db sysname);
    CREATE TABLE #uROLES (
	RoleON VARCHAR(15)
	,rolename SYSNAME
	,PrincipalName SYSNAME
	)


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
	   INSERT INTO #Principals
	   SELECT name, 'USER', type, db_name() as db 
		  FROM sys.database_principals
		  WHERE NAME NOT IN ('public', 'INFORMATION_SCHEMA','sys') --
			   and name not like '##%' -- not sure some are SQL login and others are certificate 
			   and name not like 'NT %' -- network principal
			   and type not in ('G','R')
    END
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
			   and (name=''' + @LoginUser + ''' or 1=1 )
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
			 SELECT @name, entity_name, subentity_name, permission_name,  db_name() 
			 FROM fn_my_permissions(null, ''database'');
			 REVERT;
		  END
		  
		  INSERT INTO #UserPermissions
		  select  principals.name principalName,permissionst.class_desc, 
				coalesce(tp.table_schema +''.''+tp.table_name, 
						  cp.table_schema +''.''+cp.table_name, case when object_name( permissionst.major_id) is not null then object_name( permissionst.major_id) else '''' end) as subentity_name, --may need improvement also reliable schema is in sys.objects 
				coalesce(tp.PRIVILEGE_TYPE, cp.PRIVILEGE_TYPE
				, permissionst.permission_name)  COLLATE DATABASE_DEFAULT as permission_name
				,  db_name()
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
	set @clause = ' use [?];
    	INSERT INTO #UserPermissions
    select distinct principals.name principalName,permissionst.class_desc, 
		  coalesce(tp.table_schema +''.''+tp.table_name, 
						  cp.table_schema +''.''+cp.table_name, case when object_name( permissionst.major_id) is not null then object_name( permissionst.major_id) else '''' end) as subentity_name, --may need improvement also reliable schema is in sys.objects 
		  coalesce(tp.PRIVILEGE_TYPE, cp.PRIVILEGE_TYPE
		  , permissionst.permission_name)  COLLATE DATABASE_DEFAULT as permission_name
		  , db_name()
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
	   
    ';

	exec sp_MSforeachdb @clause
	END


    INSERT INTO #UserPermissions
    select principals.name principalName,permissionst.class_desc, '''', permissionst.permission_name COLLATE DATABASE_DEFAULT
		  , db_name()
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

		  SELECT 'Principals with an explicit permission: ' + @permission

		  SELECT DISTINCT [User/Login] --,Entity_Name, SubEntity_Name, Permission_Name
		  FROM #UserPermissions
		  WHERE Permission_Name LIKE @permission and  db=@UserDB 
		  ORDER BY [User/Login]	   
	   end
    ELSE 
    begin
	   SELECT DISTINCT [User/Login],Entity_Name, SubEntity_Name, Permission_Name, db as dbName
	   FROM #UserPermissions u
	   WHERE ([User/Login] = @LoginUser OR  @LoginUser IS NULL)  and db=@UserDB 
	   ORDER BY [User/Login]
    end

    --MEMBERS OF ROLES
    INSERT INTO #uROLES
    exec sp_helpMemberOfRole 
    --exec sp_helpMemberOfRole    @UserLogin = NULL,   @srvrolename  = NULL,  @rolename  =   'db_datawriter' 


    SELECT DISTINCT PrincipalName, RoleON, rolename 
    FROM #uROLES
    WHERE (PrincipalName = @LoginUser OR  @LoginUser IS NULL) 
    ORDER BY PrincipalName

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


    --select USER_NAME() dbUser, SUSER_SNAME() ServerUser
  
END

