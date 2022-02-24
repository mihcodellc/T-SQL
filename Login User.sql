
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

SELECT * FROM fn_my_permissions(null, 'database'); 


select * from INFORMATION_SCHEMA.TABLE_PRIVILEGES order by GRANTEE
select * from INFORMATION_SCHEMA.ROUTINES

--info on a principal
SELECT * 
FROM sys.server_principals
WHERE name = 'mbello'

-- names and IDs of the roles and their members
SELECT	roles.principal_id							AS RolePrincipalID
	,	roles.name									AS RolePrincipalName
	,	server_role_members.member_principal_id		AS MemberPrincipalID
	,	members.name								AS MemberPrincipalName
FROM sys.server_role_members AS server_role_members
INNER JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.server_principals AS members 
    ON server_role_members.member_principal_id = members.principal_id  
;

SELECT * FROM sys.fn_builtin_permissions(DEFAULT) order by permission_name; 
SELECT distinct class_desc FROM sys.fn_builtin_permissions(DEFAULT) order by permission_name; 


select USER_NAME() dbUser, SUSER_SNAME() SeverUser
SELECT HAS_PERMS_BY_NAME('Ps', 'LOGIN', 'IMPERSONATE'); 
SELECT HAS_PERMS_BY_NAME(null, null, 'CONTROL SERVER');
SELECT HAS_PERMS_BY_NAME(null, null, 'IMPERSONATE');

