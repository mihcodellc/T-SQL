---- drop an user from all db on the instance
--exec sp_MSforeachdb N'use [?] ; 
--IF  EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''testbello'')
--    DROP USER [testbello];'

--Drop login [testbello]

--orphan in database ie user but no login
exec sp_change_users_login @Action='Report'

-- create role
CREATE APPLICATION ROLE app_MiseAjour WITH PASSWORD = 'Pa$$w0rd'
CREATE ROLE app_MiseAjour WITH PASSWORD = 'Pa$$w0rd'

--add to a role
if exists(select 1 from sys.database_principals where name = 'aUser')
    exec sp_addrolemember 'aRole', 'aUSer'



--login(server level) has to be existing login in sys.server_principals or sysadmin
--user(db level) has to be existing user in sys.database_principals or sysadmin
--EXECUTE AS login = 'mbello'  
EXECUTE AS user = 'obrown' -- an error to execute this is likely permission on current db
----db
--select * from sys.database_principals WHERE name LIKE '%mbello%'
----server and db
--select * FROM sys.server_principals WHERE name LIKE '%mbello%'
----check the user/login if the session
--select USER_NAME() dbUser, SUSER_SNAME() SeverUser

SELECT * FROM fn_my_permissions(null, 'SERVER') 
union
SELECT * FROM fn_my_permissions(null, 'database')
--where permission_name = 'CREATE DATABASE'
ORDER BY Permission_Name

select * from sys.database_principals 
WHERE  type  IN ('G','R', 'C') -- group, role, certificate
order by name
select * from sys.server_principals order by name



--Only server-level permissions can be added to user-defined server roles.
SELECT * FROM sys.fn_builtin_permissions('SERVER') ORDER BY permission_name; 

--members of a SQL Server fixed server role (list with EXEC sp_helpsrvrole)
EXEC sp_helpsrvrolemember 'sysadmin'; 
select IS_SRVROLEMEMBER('sysadmin','mbello') IsMemberOfSysAdmin

--Displays the permissions of a server-level role
EXEC sp_srvrolepermission 'securityadmin';  

--members of a database role (list with EXEC sp_helprole)  
EXEC sp_helprolemember 'db_owner'; 
select IS_ROLEMEMBER('db_owner','mbello') IsMemberOfDBOwner

--Displays the permissions of a db role
exec sp_dbfixedrolepermission 'db_datareader'

SELECT * FROM sys.fn_builtin_permissions('SERVER') ORDER BY permission_name; 
SELECT * FROM sys.fn_builtin_permissions('DATABASE') ORDER BY permission_name; 


select DISTINCT type, type_desc from sys.database_principals --order by name
select DISTINCT type, type_desc from sys.server_principals --order by name

    select USER_NAME() dbUser, SUSER_SNAME() ServerUser

 
select * from INFORMATION_SCHEMA.TABLE_PRIVILEGES order by GRANTEE
select * from INFORMATION_SCHEMA.ROUTINES


SELECT * FROM sys.fn_builtin_permissions(DEFAULT) order by permission_name; 
SELECT distinct class_desc FROM sys.fn_builtin_permissions(DEFAULT) order by permission_name; 

--sys.database_permissions
exec sp_helptext 'sp_dbfixedrolepermission'

select USER_NAME() dbUser, SUSER_SNAME() SeverUser
SELECT HAS_PERMS_BY_NAME('MedRx', 'database', 'SELECT'); 
SELECT HAS_PERMS_BY_NAME(null, null, 'CONTROL SERVER');
SELECT HAS_PERMS_BY_NAME(null, null, 'IMPERSONATE');

--****************************************************************
--LIMIT: NO IMPLICIT PERMISSIONS, NOT EXCLUDE DISABLED PRINCIPALS
--permissions of principals & members if any on server level 
select principals.name principalName, principal_id PrincipalID
    , permissionst.permission_name, permissionst.state_desc, permissionst.type, permissionst.class_desc
from sys.server_principals principals
join sys.server_permissions permissionst
    on permissionst.grantee_principal_id = principals.principal_id
WHERE principal_id > 0 AND permissionst.permission_name NOT LIKE  '%SELECT%'

--members and their principals on server level
select  principal_id PrincipalID, principals.name principalName,  members.member_principal_id memberID
from sys.server_principals principals
left join sys.server_role_members members 
    on principals.principal_id = members.role_principal_id


--permissions of principals & members if any on database level 
select principals.name principalName, principal_id PrincipalID
    , permissionst.permission_name, permissionst.state_desc, permissionst.type, permissionst.class_desc
from sys.database_principals principals
join sys.database_permissions permissionst
    on permissionst.grantee_principal_id = principals.principal_id
    WHERE principal_id > 0 AND permissionst.permission_name NOT LIKE  '%SELECT%'
    order by principalName

--members and their principals on database level
select  principal_id PrincipalID, principals.name principalName,  members.member_principal_id memberID
from sys.server_principals principals
left join sys.server_role_members members 
    on principals.principal_id = members.role_principal_id
