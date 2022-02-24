
---- the login should be different than yourself
--USE master
--GO
--GRANT IMPERSONATE ANY LOGIN TO [RMS-ASP\mbello]
--GO

--it is specific to current database
--SET @permission IF you need to exclude a permission DEFAULTED TO '%SELECT%'
-- Run without a specific permission, it returns all single database principals with their permissions

--check execution context at begin and the end
select USER_NAME() dbUser, SUSER_SNAME() SeverUser

DECLARE @canImpersonate int, @permission sysname; 

--SET @permission = '%SELECT%';

SELECT @canImpersonate = HAS_PERMS_BY_NAME(null, null, 'IMPERSONATE ANY LOGIN');

IF @canImpersonate = 0
    print 'the caller doesn''t the permission';


IF @canImpersonate = 1
BEGIN

    DECLARE @name sysname;
    CREATE TABLE #UserPermissions ([User/Login] sysname,Entity_Name sysname, SubEntity_Name sysname, Permission_Name sysname)

    DECLARE UserCursor CURSOR FOR
	   SELECT name 
	   FROM sys.server_principals
	   WHERE NAME NOT IN ('public') and type not in('G') -- G exclude because "execute as" doesn't allow it 
	   ORDER BY NAME;

    OPEN UserCursor 
    FETCH NEXT FROM UserCursor INTO @name
    --what about db user without login on the server OR Group

    WHILE @@FETCH_STATUS = 0
    BEGIN
	   IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name = @name)
	   BEGIN
		  -- Set the execution context on user
		  EXECUTE AS user = @name;
		  -- permission on db
		  INSERT INTO #UserPermissions
		  SELECT @name, entity_name, subentity_name, permission_name 
			 FROM fn_my_permissions(null, 'database');
		  -- permission on server
		  INSERT INTO #UserPermissions
		  SELECT @name, entity_name, subentity_name, permission_name
			 FROM fn_my_permissions(null, 'server');
		  REVERT;
	   END
	   FETCH NEXT FROM UserCursor INTO  @name
    END
    CLOSE UserCursor
    DEALLOCATE UserCursor

    
    IF LEN(@permission) > 0
	   SELECT DISTINCT [User/Login] --,Entity_Name, SubEntity_Name, Permission_Name
	   FROM #UserPermissions
	   WHERE Permission_Name NOT LIKE @permission
	   ORDER BY [User/Login]
    ELSE
	   SELECT [User/Login],Entity_Name, SubEntity_Name, Permission_Name
	   FROM #UserPermissions 
	   ORDER BY Permission_Name


    IF OBJECT_ID('tempDB..#UserPermissions') IS NOT NULL
	   DROP TABLE #UserPermissions

    select USER_NAME() dbUser, SUSER_SNAME() SeverUser

END