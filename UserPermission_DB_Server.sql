

/*============================================================================
  File:     UserPermission_DB_Server.sql
  Summary:  
	   Run without a specific permission, it returns 
		  -all single database principals with their permissions
		  -members of a role
	   
	   it is specific to current database & server

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

				
  Date:     February 2021
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
SELECT @@SERVERNAME 'SQL Server Instance', DB_NAME() 'Database' 


declare @LoginUser sysname, @canImpersonate int, @permission sysname, @type char(1); 

--SET @permission = '%SELECT%';
--SET @LoginUser = 'jdoudican'

SELECT @canImpersonate = HAS_PERMS_BY_NAME(null, null, 'IMPERSONATE ANY LOGIN');

IF @canImpersonate = 0
    print 'the caller doesn''t the permission IMPERSONATE ANY LOGIN';


IF @canImpersonate = 1
BEGIN

    DECLARE @name sysname;
    CREATE TABLE #UserPermissions ([User/Login] sysname,Entity_Name sysname, SubEntity_Name sysname, Permission_Name sysname)
    CREATE TABLE #Principals(name sysname, isLoginUser nvarchar(15), type char(1));
    CREATE TABLE #uROLES (
	RoleON VARCHAR(15)
	,rolename SYSNAME
	,PrincipalName SYSNAME
	)


    INSERT INTO #Principals
    SELECT name, 'LOGIN',  type 
    FROM sys.server_principals
    WHERE NAME NOT IN ('public') --
		and name not like '##%' -- not sure some are SQL login and others are certificate
		and name not like 'NT %'
		and type not in ('G','R', 'C')
    
    INSERT INTO #Principals
    SELECT name, 'USER', type 
    FROM sys.database_principals
    WHERE NAME NOT IN ('public', 'INFORMATION_SCHEMA','sys') --
		and name not like '##%' -- not sure some are SQL login and others are certificate 
	     and name not like 'NT %' -- network principal
		and type not in ('G','R', 'C')
    ORDER BY NAME;


    --***CURSOR ON USER
    DECLARE UserCursor CURSOR FOR
	   SELECT name, type 
	   FROM #Principals
	   WHERE isLoginUser = 'USER' 

    OPEN UserCursor 
    FETCH NEXT FROM UserCursor INTO @name, @type
    --what about db user without login on the server OR Group
    --CREATE DATABASE 

    WHILE @@FETCH_STATUS = 0
    BEGIN
	   IF EXISTS(SELECT 1 FROM sys.server_principals WHERE name = @name) 
	   BEGIN
		  -- Set the execution context on user
		  EXECUTE AS user = @name;
		  -- permission on db
		  INSERT INTO #UserPermissions
		  SELECT @name, entity_name, subentity_name, permission_name 
			 FROM fn_my_permissions(null, 'database');
		  REVERT;
	   END
	   ELSE
	   BEGIN
	   INSERT INTO #UserPermissions
	   select  principals.name principalName,permissionst.class_desc, 
			 coalesce(tp.table_schema +'.'+tp.table_name, 
					   cp.table_schema +'.'+cp.table_name, '') as subentity_name, --may need improvement also reliable schema is in sys.objects 
			 coalesce(tp.PRIVILEGE_TYPE, cp.PRIVILEGE_TYPE, permissionst.permission_name)  COLLATE DATABASE_DEFAULT as permission_name
	   from sys.database_principals principals
	   join sys.database_permissions permissionst
		  on permissionst.grantee_principal_id = principals.principal_id
	   left join INFORMATION_SCHEMA.TABLE_PRIVILEGES tp
		  on tp.GRANTEE = principals.name 
	   left join INFORMATION_SCHEMA.COLUMN_PRIVILEGES cp
		  on cp.GRANTEE = principals.name	
		  WHERE principals.name = @name
	   END

	   FETCH NEXT FROM UserCursor INTO  @name, @type
    END
    CLOSE UserCursor
    DEALLOCATE UserCursor



    --***CURSOR ON LOGIN
    DECLARE UserCursor CURSOR FOR
	   SELECT name, type 
	   FROM #Principals
	   WHERE isLoginUser = 'LOGIN' 

    OPEN UserCursor 
    FETCH NEXT FROM UserCursor INTO @name, @type
    --what about db user without login on the server OR Group

    WHILE @@FETCH_STATUS = 0
    BEGIN
	   IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name = @name) 
	   BEGIN
		  -- Set the execution context on user
		  EXECUTE AS login = @name;
		  -- permission on server
		  INSERT INTO #UserPermissions
		  SELECT @name, entity_name, subentity_name, permission_name
			 FROM fn_my_permissions(null, 'server');
		  REVERT;
	   END
	   ELSE
	   BEGIN
		  INSERT INTO #UserPermissions
		  select principals.name principalName,permissionst.class_desc, '', permissionst.permission_name
		  from sys.server_principals principals
		  join sys.server_permissions permissionst
			 on permissionst.grantee_principal_id = principals.principal_id
			 WHERE principals.name = @name 
	   END

	   FETCH NEXT FROM UserCursor INTO  @name, @type
    END
    CLOSE UserCursor
    DEALLOCATE UserCursor

    	INSERT INTO #UserPermissions
    -- get other details in othose on which I can't run with "execute as"  
    select distinct principals.name principalName,permissionst.class_desc, 
		  coalesce(tp.table_schema +'.'+tp.table_name, 
				    cp.table_schema +'.'+cp.table_name, '') as subentity_name, --may need improvement also reliable schema is in sys.objects 
		  coalesce(tp.PRIVILEGE_TYPE, cp.PRIVILEGE_TYPE, permissionst.permission_name)  COLLATE DATABASE_DEFAULT as permission_name
    from sys.database_principals principals
    join sys.database_permissions permissionst
	   on permissionst.grantee_principal_id = principals.principal_id
    left join INFORMATION_SCHEMA.TABLE_PRIVILEGES tp
	   on tp.GRANTEE = principals.name 
    left join INFORMATION_SCHEMA.COLUMN_PRIVILEGES cp
	   on cp.GRANTEE = principals.name	
    WHERE principals.name NOT IN ('public') and --
	   ( principals.name  like '##%' -- not sure some are SQL login and others are certificate
	   or principals.name  like 'NT %'
	   or principals.type  in ('G', 'C','R')
	   )
    UNION
    select principals.name principalName,permissionst.class_desc, '', permissionst.permission_name
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

		  SELECT 'Principals without an explicit permission: ' + @permission

		  SELECT DISTINCT [User/Login] --,Entity_Name, SubEntity_Name, Permission_Name
		  FROM #UserPermissions
		  WHERE Permission_Name NOT LIKE @permission
		  ORDER BY [User/Login]	   
	   end
    ELSE 
    begin
	   SELECT DISTINCT [User/Login],Entity_Name, SubEntity_Name, Permission_Name
	   FROM #UserPermissions u
	   WHERE ([User/Login] = @LoginUser OR  @LoginUser IS NULL)
	   ORDER BY [User/Login]
    end

    --MEMBERS OF ROLES
    INSERT INTO #uROLES
    exec sp_helpMemberOfRole 

    SELECT DISTINCT PrincipalName, RoleON, rolename 
    FROM #uROLES
    WHERE (PrincipalName = @LoginUser OR  @LoginUser IS NULL)
    ORDER BY PrincipalName



    IF OBJECT_ID('tempDB..#UserPermissions') IS NOT NULL
	   DROP TABLE #UserPermissions

    IF OBJECT_ID('tempDB..#Principals') IS NOT NULL
	   DROP TABLE #Principals

    IF OBJECT_ID('tempDB..#uROLES') IS NOT NULL
	   DROP TABLE #uROLES


    --select USER_NAME() dbUser, SUSER_SNAME() ServerUser
  
END