--sql server 2017 compati 140
--should follow instrustions in Server_Level_permissions_To_DB.sql before continue

-- CREATE THE SERVER ROLE FOR DEVOPS
create server ROLE devops_new AUTHORIZATION sysadmin
create server ROLE devops_jr AUTHORIZATION sysadmin
CREATE server ROLE devops_sr AUTHORIZATION sysadmin

--Allow supervisor to do what his staff can do USING SERVER ROLE
 exec sp_addsrvrolemember 'devops_new', 'devops_jr'
 exec sp_addsrvrolemember 'devops_jr', 'devops_sr'

 -- USE THE DATABASE WHERE THE PROC EXISTS
use DBA_DB
-- CREATE THE DB ROLES FOR DEV SERVER ROLE
CREATE ROLE devops_new AUTHORIZATION [dbo]
CREATE ROLE devops_jr AUTHORIZATION [dbo]
CREATE ROLE devops_sr AUTHORIZATION [dbo]

-- ADD EXISTING DBUSER TO DB ROLE devops_new
--create user testbello for login testbello
 exec sp_addrolemember 'devops_new', 'testbello'

--Grant exec to DB ROLE devops_new
GRANT EXECUTE ON dbo.sp_WhoIsActive TO devops_new

-- TEST THE DEV USER CAN RUN THE SP THROUGH HIS MEMBERSHIP
use DBA_DB
exec as login = 'testbello'
--select * from fn_my_permissions(null,'database')
exec dbo.sp_WhoIsActive
revert; -- DON'T MISS THIS

---CLEANUP
USE DBA_DB
 exec sp_DROProlemember 'devops_new', 'testbello'
 exec sp_DROProlemember 'devops_new', 'MBELLO'
DROP ROLE devops_new 
DROP ROLE devops_jr 
DROP ROLE devops_sr 
exec sp_DROPsrvrolemember 'mbello', 'devops_new'
 exec sp_DROPsrvrolemember 'devops_new', 'devops_jr'
 exec sp_DROPsrvrolemember 'devops_jr', 'devops_sr'
DROP server ROLE devops_new
DROP server ROLE devops_jr 
DROP server ROLE devops_sr 

-- POST TEST expect error
use DBA_DB
exec as login = 'testbello'
--select * from fn_my_permissions(null,'database')
exec dbo.sp_WhoIsActive
revert; -- DON'T MISS THIS



--** check before and after for each role, principal
select principals.name principalName, principal_id PrincipalID
    , permissionst.permission_name, permissionst.state_desc, permissionst.class_desc
    ,  object_name( permissionst.major_id)
from sys.database_principals principals
join sys.database_permissions permissionst
    on permissionst.grantee_principal_id = principals.principal_id
    WHERE principal_id > 0 AND principals.name = 'devops_new'
    order by principalName


--members and their principals on database level
SELECT rol.name AS DatabaseRoleName,   
   isnull (us.name, '') AS UserMemberName, us.principal_id MemberID   
 FROM sys.database_principals AS rol    
 LEFT JOIN  sys.database_role_members AS mb
	   ON mb.role_principal_id = rol.principal_id  
 LEFT JOIN sys.database_principals AS us  
	   ON mb.member_principal_id = us.principal_id  
WHERE rol.type = 'R' and rol.name = 'devops_new'
ORDER BY  rol.name;  

--members and their principals on server level
SELECT rol.name AS ServerRoleName,   
   isnull (us.name, '') AS UserMemberName, us.principal_id MemberID   
 FROM sys.server_principals AS rol    
 LEFT JOIN  sys.server_role_members AS mb
	   ON mb.role_principal_id = rol.principal_id  
 LEFT JOIN sys.server_principals AS us  
	   ON mb.member_principal_id = us.principal_id  
WHERE rol.type = 'R' and rol.name = 'devops_new'
ORDER BY  rol.name;  


-- search permissions on the server and db
exec mydb.dbo.sp_help_permissions @principal ='mbello', @permission_list = 1, @permission = '%view server%' 
