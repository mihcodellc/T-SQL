--members and their principals on database level
SELECT rol.name AS DatabaseRoleName,   
   isnull (us.name, '') AS UserMemberName, us.principal_id MemberID   
 FROM sys.database_principals AS rol    
 LEFT JOIN  sys.database_role_members AS mb
	   ON mb.role_principal_id = rol.principal_id  
 LEFT JOIN sys.database_principals AS us  
	   ON mb.member_principal_id = us.principal_id  
WHERE us.name in('bmbello')
and rol.type = 'R'
ORDER BY  rol.name;  

--members and their principals on server level
SELECT rol.name AS ServerRoleName,   
   isnull (us.name, '') AS UserMemberName, us.principal_id MemberID   
 FROM sys.server_principals AS rol    
 LEFT JOIN  sys.server_role_members AS mb
	   ON mb.role_principal_id = rol.principal_id  
 LEFT JOIN sys.server_principals AS us  
	   ON mb.member_principal_id = us.principal_id  
WHERE rol.type = 'R' --and rol.name = 'svc-devops'
ORDER BY  rol.name;  



-- search permissions on the server and db
--exec RmsAdmin.dbo.sp_help_permissions @principal ='jhough', @permission_list = 1--, @permission = '%view server%' 

    IF OBJECT_ID('tempDB..#uROLES') IS NOT NULL
	   DROP TABLE #uROLES
    CREATE TABLE #uROLES ( RoleON VARCHAR(15), rolename SYSNAME,PrincipalName SYSNAME)

    INSERT INTO #uROLES
    exec sp_helpMemberOfRole 

    SELECT DISTINCT PrincipalName, RoleON, rolename 
    FROM #uROLES
    WHERE rolename in ('db_datareader','db_datawriter')
    ORDER BY  PrincipalName

--** list object with permissions for role, principal, 
select principals.name principalName, principal_id PrincipalID
    , permissionst.permission_name, permissionst.state_desc, permissionst.class_desc
    ,  object_name( permissionst.major_id) ObjName,
    OBJECTPROPERTY(permissionst.major_id, 'IsTable') AS [IsTable],
    OBJECTPROPERTY(permissionst.major_id, 'IsTrigger') AS [IsTrigger],
    OBJECTPROPERTY(permissionst.major_id, 'IsView') AS [IsView],
    OBJECTPROPERTY(permissionst.major_id, 'IsProcedure') AS [IsProcedure]
from sys.database_principals principals
join sys.database_permissions permissionst
    on permissionst.grantee_principal_id = principals.principal_id
    WHERE principal_id > 0 
    AND principals.name in ('sqldev_sr','sqldev_jr')
    --and permission_name ='UPDATE'
    order by principalName, permission_name

EXEC sp_helprolemember 'db_datareader';  --db_datawriter

--	 select * from INFORMATION_SCHEMA.TABLE_PRIVILEGES where GRANTEE in ('jhough', 'devops_sr', 'devops_jr', 'ODA','ODA_rw', 'devops_new')
--	 --select * from INFORMATION_SCHEMA.pri


----sp_helptext 'sp_helpMemberOfRole'

--exec sp_dbfixedrolepermission 'db_datareader'
--exec sp_dbfixedrolepermission 'db_datawriter'
--execute as user='mbello'
--select * from fn_my_permissions(null,'database')
--revert;



--GRANT	DELETE	sqldev_jr
--GRANT	EXECUTE	sqldev_jr
--GRANT	INSERT	sqldev_jr
--GRANT	SELECT	sqldev_jr
--GRANT	UPDATE	sqldev_jr
--GRANT	SELECT	sqldev_new
--GRANT	DELETE	sqldev_sr
--GRANT	EXECUTE	sqldev_sr
--GRANT	INSERT	sqldev_sr
--GRANT	REFERENCES	sqldev_sr
--GRANT	SELECT	sqldev_sr
--GRANT	UPDATE	sqldev_sr
--GRANT	VIEW DEFINITION	sqldev_sr



CREATE LOGIN mbello
    WITH PASSWORD = 'mbelo7256',
    --MUST_CHANGE, 
    CHECK_EXPIRATION = ON, CHECK_POLICY = ON, DEFAULT_DATABASE = MedRx 

USE master
GRANT VIEW ANY DATABASE TO rdraviam 

use MedRx;
CREATE USER rdraviam
exec sp_addrolemember sqldev_jr, 'mbello'
deny execute to rdraviam




exec as login = 'mbello'
select * from fn_my_permissions(null,'database')
union all
select * from fn_my_permissions(null,'server')
revert; -- DON'T MISS THIS
