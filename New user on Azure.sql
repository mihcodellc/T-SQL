
exec as user = 'sacquaye'
select * from fn_my_permissions(null,'database')
union all
select * from fn_my_permissions(null,'server') -- not useful on azure database 
revert; -- DON'T MISS THIS

--sacquaye@rmsweb.com
exec as user = 'mmiller'
select top 1 * from dbo.BdCcdFiles
revert; -- DON'T MISS THIS



--know the execution context
select * from sys.sysusers order by name --where name = 'mmiller'
select * from sys.user_token
select * from sys.sql_logins
where name = 'mmiller'

--1
--Passwords must contain these in any order: 2 upper, 2 lower, 2 special, 2 numbers, 14 chars minimum
use master
CREATE LOGIN sacquaye 
    WITH PASSWORD = 'sRsiky@1e20RM$22'

        --unlock
    ALTER LOGIN sacquaye WITH PASSWORD = 'sRsiky@1e20RM$22'-- UNLOCK, DEFAULT_DATABASE -- not supported
    ALTER LOGIN [ttovar] DISABLE;
    --match login
    ALTER USER [sacquaye] WITH LOGIN = [sacquaye]



--2
use RemitHub_Production;
CREATE USER sacquaye
EXEC sp_addrolemember 'db_datareader', 'sacquaye'
--EXEC sp_addrolemember 'devops_jr', 'JButcher'

EXEC sp_droprolemember 'devops_new', 'JButcher'

use Operations;
CREATE USER smiller
EXEC sp_addrolemember 'devdba', 'sacquaye'




--permission for role, principal
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
    AND principals.name in ('devdba')
    --and permission_name ='UPDATE'
    order by ObjName,principalName, permission_name


select  principals.name principalName,permissionst.class_desc, 
	   coalesce(tp.table_schema +'.'+tp.table_name, 
				cp.table_schema +'.'+cp.table_name, case when object_name( permissionst.major_id) is not null then object_name( permissionst.major_id) else '''' end) as subentity_name, --may need improvement also reliable schema is in sys.objects 
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
    WHERE principals.name = 'jhough'


--members and their principals on server level 
-- USEFULL ON MANAGED INSTANCE/ SQL ON VM
SELECT rol.name AS ServerRoleName,   
   isnull (us.name, '') AS UserMemberName, us.principal_id MemberID   
 FROM sys.database_principals AS rol    
 LEFT JOIN  sys.server_role_members AS mb
	   ON mb.role_principal_id = rol.principal_id  
 LEFT JOIN sys.server_principals AS us  
	   ON mb.member_principal_id = us.principal_id  
WHERE rol.type = 'R' and rol.name = 'devdba'
ORDER BY  rol.name;  


--3
--members and their principals on database level
SELECT rol.name AS DatabaseRoleName,   
   isnull (us.name, '') AS UserMemberName, us.principal_id MemberID   
 FROM sys.database_principals AS rol    
 LEFT JOIN  sys.database_role_members AS mb
	   ON mb.role_principal_id = rol.principal_id  
 LEFT JOIN sys.database_principals AS us  
	   ON mb.member_principal_id = us.principal_id  
WHERE rol.type = 'R' and rol.name = 'devdba'
ORDER BY  rol.name;  

