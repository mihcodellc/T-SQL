exec as login = 'codonnell' -- cbuller@rmsweb.com

use Medrx
create proc bello
as 
select 1 'HI'
go
create table nettest(id int)
go
insert into nettest
select 1
go
update nettest set id=2
go
delete from nettest where id=4
go
drop table if exists testbello
go
drop table nettest
go
drop proc bello
go
--only dba
create schema dev
drop schema dev

select * from fn_my_permissions(null,'database')
union all
select * from fn_my_permissions(null,'server')
--select top 100 * from Medrx.dbo.loaderlog where id = 206194515
revert; -- DON'T MISS THIS

--know the execution context
select * from sys.sysusers
select * from sys.user_token --included every role on the db
select * from sys.login_token
select SUSER_SNAME() as [SUSER_SNAME_from_sid_param], SUSER_NAME() as [SUSER_NAME_from_LogIdNumber_param],  USER_NAME() as UserNameDB_fromIDnum, SYSTEM_USER as [LOGIN], user as [DBuser]


exec as login = [svc-datascientist]
select * from fn_my_permissions(null,'database') 
union all
select * from fn_my_permissions(null,'server') -- jjoseph@rmsweb.com
revert; -- DON'T MISS THIS

-- https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-login-transact-sql?view=sql-server-ver16#examples

--The database principal has granted or denied permissions to objects in the database and cannot be dropped
--runs this
--	   select * from sys.database_permissions where grantor_principal_id = user_id ('jfranco');
--it means that you will have to revoke some permissions like in the following statement 
--	   REVOKE IMPERSONATE ON USER::[jfranco] TO [mbello] AS [jfranco]

DataGrip: Set up PG Prod & SQL Prod: https://confluence.revmansolutions.com/pages/viewpage.action?pageId=119570503

jjoseph -- $dUaN1_)30RM$23    jjoseph@rmsweb.com
--jjoseph@rmsweb.com -- 'r!msEz1_)20RM$22'   jjoseph@rmsweb.com sfranco@rmsweb.com   jjoseph@rmsweb.com  jjoseph@rmsweb.com
--1
--Passwords must contain these in any order: 2 upper, 2 lower, 2 special, 2 numbers, 14 chars minimum rR?kkuR0e7Z09!DF
CREATE LOGIN jjoseph
    WITH PASSWORD = 'oK!Js0Jd1_)42RM$29',--'lmUJICqOS!g4ofp',
    --MUST_CHANGE, 
    CHECK_EXPIRATION = ON, CHECK_POLICY = ON, DEFAULT_DATABASE = MedRx 

    ALTER LOGIN dprober WITH default_database = MedRx ;

    ALTER LOGIN Mary5 WITH PASSWORD = '<enterStrongPasswordHere>' OLD_PASSWORD = '<oldWeakPasswordHere>';
    --unlock
    ALTER LOGIN [sfranco] WITH PASSWORD = 'sK!ZsCdm1_)21RM$23' UNLOCK; 
    or
    ALTER LOGIN [sfranco] WITH PASSWORD = 'oK!Ts0Td1_)12RM$23';
    ALTER LOGIN [sfranco] WITH CHECK_POLICY = OFF;
    ALTER LOGIN [sfranco] WITH CHECK_POLICY = ON;

    --rename the login
    alter login jrodrigue WITH NAME = jrodriguez;
    --disable/enable
    ALTER LOGIN [jjoseph] DISABLE;
    ALTER LOGIN sharris enable;
    --match login
    ALTER USER [tgorshing] WITH LOGIN = [tgorshing]

SELECT s.*, SCHEMA_NAME(schema_id)
FROM sys.schemas s where s.principal_id = USER_ID('sacquaye');

--2
USE master
GRANT VIEW ANY DATABASE TO jjoseph 


create server role read_server

alter server role read_server add member codonnell

USE master
grant VIEW SERVER STATE to read_server -- <> VIEW DATABASE STATE

use MedRxAnalytics;
grant VIEW DATABASE STATE to data_science
grant SHOWPLAN to data_science
grant VIEW DEFINITION to data_science



--3
use MedRx;
--create role billing_new
CREATE USER jjoseph FOR LOGIN jjoseph
EXEC sp_addrolemember 'DEVOPS', 'jjoseph'  -- sqldev_new on prod = select, execute
--EXEC sp_addrolemember 'devops_new', 'jjoseph'
--DEVOPS role for devOps
GRANT SHOWPLAN TO [jjoseph]; --db level permission


--staging
    alter role  db_datareader add member jjoseph
    alter role  db_datawriter drop member jjoseph


use Reconciliation;
--create role billing_new
CREATE USER jjoseph FOR LOGIN jjoseph
EXEC sp_addrolemember 'db_datareader', 'jjoseph'
--EXEC sp_addrolemember 'devdba', 'sacquaye'

    alter role  db_datareader add member jjoseph --dev
    alter role  db_datawriter add member jjoseph --dev


use Globalscape;
CREATE USER jjoseph FOR LOGIN jjoseph
EXEC sp_addrolemember 'db_datareader', 'jjoseph'
--deny execute on database::RMSOCR to [jjoseph] 


use MedRxAnalytics;
--create role billing_new
CREATE USER jjoseph FOR LOGIN jjoseph
EXEC sp_addrolemember 'data_science', 'jjoseph'
--EXEC sp_addrolemember 'data_science', 'zgeyser'

use RMSOCR;
CREATE USER jjoseph FOR LOGIN jjoseph
EXEC sp_addrolemember 'db_datareader', 'jjoseph'
EXEC sp_addrolemember 'db_datawriter', 'jjoseph'
--deny execute on database::RMSOCR to [jjoseph] 

--EXEC sp_addrolemember 'data_science', 'gsikes'
    alter role  db_datareader add member jjoseph --dev
    alter role  db_datawriter add member jjoseph --dev




--4
GRANT VIEW ANY COLUMN ENCRYPTION KEY DEFINITION, VIEW ANY COLUMN MASTER KEY DEFINITION,
--default once login created above
VIEW DEFINITION, REFERENCES, INSERT, UPDATE 
--explicity assigned above
ON DATABASE::RMSOCR TO DEVOPS 
grant update on object::dbo.ClpSegment to BOA
revoke create table, create type, create view ON DATABASE::RMSOCR TO DEVOPS 

grant SELECT, ALTER,DELETE, EXECUTE, INSERT, REFERENCES, UPDATE, VIEW DEFINITION to sqldev_new


grant CREATE PROCEDURE, CREATE FUNCTION, VIEW DEFINITION on database::MedRx to sqldev_jr

CONNECT
CREATE FUNCTION
CREATE PROCEDURE
CREATE TABLE
CREATE VIEW
SELECT
ALTER
DELETE
EXECUTE
INSERT
REFERENCES
SELECT
UPDATE
VIEW DEFINITION


grant ALTER ANY DATABASE DDL TRIGGER ON DATABASE::RMSOCR TO zgeyser
revoke alter on object::dbo.FileLoadDetail TO zgeyser
grant insert on object::sisense.CubeInfo TO devdba
grant alter on object::dbo.LockboxStatusSummaryByProductTypeV2 TO zgeyser
grant select ON DATABASE::RMSOCR TO fwalter
grant alter table ON DATABASE::MedRx TO fwalter

revoke alter ON schema::sisense TO devdba
grant insert,delete, update, select ON schema::sisense TO devdba




create role devdba


    alter role  db_ddladmin add member [data_science]
    alter role  db_datareader add member [data_science]
    alter role db_datawriter add member data_science

grant select ON DATABASE::Billing TO jjoseph
grant select ON DATABASE::MedRx TO jjoseph


--5
EXEC sp_helprolemember 'devops_sr';
EXEC sp_helprolemember 'devops_jr';
EXEC sp_helprolemember 'devops_new';
EXEC sp_helprolemember 'svc-devops';



-- remove ownership from schema
SELECT 'ALTER AUTHORIZATION ON SCHEMA::' + s.name + '  TO dbo;'
FROM sys.schemas s
WHERE s.principal_id = USER_ID(@userRole);

-- add he/she/it as member instead
alter role  db_ddladmin add member [data_science]
SELECT 'alter role ' + QUOTENAME (s.name) + '  add member ' + QUOTENAME (@userRole) + ';'
FROM sys.schemas s
WHERE s.principal_id = USER_ID(@userRole);


--asp-orbosql

CREATE LOGIN jjoseph
    WITH PASSWORD = 'sT!UfFre1_)20RM$22',
    CHECK_EXPIRATION = ON, CHECK_POLICY = ON, DEFAULT_DATABASE = [Hpac.Rms.Eor.Demo] -- jjoseph@rmsweb.com

use [Hpac.Rms.Eor.Demo];
CREATE USER jjoseph FOR LOGIN jjoseph
alter role sqldev_jr add member jjoseph

use [Hpac.Rms.HrcmApplication];
CREATE USER jjoseph FOR LOGIN jjoseph
alter role sqldev_jr add member jjoseph

use [Hrcm.Application];
CREATE USER jjoseph FOR LOGIN jjoseph
alter role sqldev_jr add member jjoseph

use [SSi];
CREATE USER jjoseph FOR LOGIN jjoseph
alter role sqldev_jr add member jjoseph
 

 grant select, update, delete, insert on ADOrgPdfs to mbello