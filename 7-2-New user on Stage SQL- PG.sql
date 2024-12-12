DataGrip: Set up PG Prod & SQL Prod: https://confluence.revmansolutions.com/pages/viewpage.action?pageId=119570503

--	execute as login in tsql equivalent
set role to mbello

--look permission on a table to know ACL then define waht to grant

ALTER ROLE mmiller NOLOGIN; --disable
ALTER ROLE mmiller CREATEROLE CREATEDB;

ALTER ROLE jnguyen RENAME TO jonguyen;
ALTER role jonguyen WITH PASSWORD 'sK!ZsCdm1_)21RM$23'

-- work too ***** create user tmalik with PASSWORD 'mE!UsRdm1_)20RM$22' valid until 'infinity';
create role tmalik with PASSWORD 'lmUJICqOS!g4ofp' LOGIN valid until 'infinity'; --- Xiugeap2YllTjZE  tmalik@rmsweb.com rcapps@rmsweb.com
COMMENT ON ROLE tmalik IS 'Ty Malik, DevOps ';
-- GRANT db_reader TO tmalik;
-- GRANT devops_rx TO tmalik; -- read and execute --prod
-- grant clientserv_ro to ctrowbridge; -- readonly
--GRANT medrx_rw TO tmalik; -- dev1
-- GRANT db_datawriter TO tmalik; --payer dev
GRANT pgdev TO tmalik; --payer dev, payer UAT -- pgdev can create/drop table, function, proc
-- GRANT db_datareader TO tmalik; --payer prod
-- GRANT pgdev_ro TO tmalik; --payer prod
-- GRANT db_datawriter TO dprober; --payer prod

create role ClientRelations with nologin
GRANT db_reader TO ClientRelations;

GRANT db_datawriter TO tmcmichael;
GRANT db_datareader TO tmcmichael;


ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT INSERT, DELETE, UPDATE ON TABLES TO db_datawriter;--payer prod
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT SELECT ON TABLES TO db_datareader;--payer prod
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT EXECUTE ON FUNCTIONS TO db_datareader;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT SELECT, USAGE ON SEQUENCES TO db_datareader;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT UPDATE ON SEQUENCES TO db_datawriter;

ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT INSERT, DELETE, UPDATE ON TABLES TO svc_payersolution;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT SELECT ON TABLES TO svc_payersolution;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT EXECUTE ON FUNCTIONS TO svc_payersolution;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT SELECT, USAGE ON SEQUENCES TO svc_payersolution;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT UPDATE ON SEQUENCES TO svc_payersolution;

ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT INSERT, DELETE, UPDATE ON TABLES TO pgdev_ro;--payer prod
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT SELECT ON TABLES TO pgdev_ro;--payer prod
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT EXECUTE ON FUNCTIONS TO pgdev_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT SELECT, USAGE ON SEQUENCES TO pgdev_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT UPDATE ON SEQUENCES TO pgdev_ro;

ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT INSERT, DELETE, UPDATE ON TABLES TO devops;--payer prod
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT SELECT ON TABLES TO devops;--payer prod
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT EXECUTE ON FUNCTIONS TO devops;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT SELECT, USAGE ON SEQUENCES TO devops;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT UPDATE ON SEQUENCES TO devops;




set role svc_payersolution --

select * from  audit_claimstatus_user limit 1;

GRANT db_datareader TO svc_payersolution;
GRANT db_datawriter TO svc_payersolution;


--User Permissions
WITH acl AS (
             SELECT relname,relacl,reltuples,
                    (aclexplode(relacl)).grantor,
                    (aclexplode(relacl)).grantee,
                    (aclexplode(relacl)).privilege_type,
                    CASE relkind
			    WHEN 'r' THEN 'ordinary table'
			    WHEN 'v' THEN 'view'
			    WHEN 'm' THEN 'materialized view'
			    WHEN 'S' THEN 'sequence'
			    WHEN 'f' THEN 'foreign table'
			    when 'c' then 'composite type'
			    when 't' then 'TOAST table'
			    when 'p' then 'partitioned table'
			    when 'i' then 'index'
			    when 'I' then 'partitioned index'
		    else cast(C.relkind as char(1)) -- 'o' refers to other
		    END as Type, n.nspname as  schema_name, n.nspacl as namespace_priv_list, C.relowner, C.relkind
            FROM pg_class C
LEFT JOIN pg_namespace N
	ON (N.oid = C.relnamespace)
)
         SELECT CURRENT_CATALOG,schema_name, acl.relname, g.rolname AS grantee,
                acl.privilege_type AS permission,
                gg.rolname AS grantor, acl.relacl, acl.reltuples, acl.Type, o.rolname
         FROM acl
         JOIN pg_roles g ON g.oid = acl.grantee
         JOIN pg_roles gg ON gg.oid = acl.grantor
	 JOIN pg_roles o on acl.relowner = o.oid
         where g.rolname = 'pgdev' and schema_name = 'prod' order by acl.relname
           --  (acl.privilege_type = 'USAGE' and acl.schema_name = 'dbo')
		--	or (cast(acl.namespace_priv_list as varchar(200)) ~ 'mbello')
		--	or (acl.relname = 'domain')
	-- and acl.relkind::char(1) = 'v'
        -- order by g.rolname

	SELECT r.rolname, g.rolname AS group, m.admin_option AS is_admin
          FROM pg_auth_members m
               JOIN pg_roles r ON r.oid = m.member
               JOIN pg_roles g ON g.oid = m.roleid
          where g.rolname in ('db_datawriter')
          ORDER BY r.rolname;


set role to svc_payersolution;

ALTER TABLE prod.audit_claimstatus_user   OWNER TO postgres;

select * from prod.audit_claimstatus_user;
insert into prod.audit_claimstatus_user(first_name, last_name, tax_id_number, description, email)
select 'Tes1', 'Test_name', 7, 'this is a test','email@email.com';
update prod.audit_claimstatus_user set tax_id_number=7 where audit_claimstatus_user_id = 1;









create role fduverseau with password 'xxxxxxxxxx' login valid until 'infinity' ;
comment on role fduverseau is 'Fabienne Duverseau, Manager of Relationship Managers - Client Relations';
grant ClientRelations to fduverseau


--on dev1
create user rngem with PASSWORD 'z6JEE97R6bENBAd8wPhV' valid until 'infinity';
COMMENT ON ROLE rngem IS 'Rithsek Ngem, Software Engineer';
GRANT medrx_rw TO rngem;


--on prod1
create user rngem with PASSWORD 'c!UsUbm1_)20RM$22' valid until 'infinity';
COMMENT ON ROLE rngem IS 'Rithsek Ngem, Software Engineer';
GRANT db_reader TO rngem;
GRANT devops_rx TO rngem; -- read and execute

create user nvu with PASSWORD 'n!UsVb01_)20RM$23' valid until 'infinity';
COMMENT ON ROLE nvu IS 'Nhu Vu, Customer Support Rep';
GRANT clientserv_ro TO nvu; --READ ONLY

--read and execute role on prod1
create role devops_rx;
grant execute on all functions in schema public to devops_rx;
grant select  on all tables in schema public to devops_rx;

--priv on a view in prod1 ie owner is "postgres" or "mbx1"  or "claimresearch" and in Dev: medrx_rw or postgres
ALTER TABLE public.document_view
  OWNER TO postgres;
GRANT ALL ON TABLE public.document_view TO postgres;

GRANT SELECT ON TABLE public.document_view TO medrxdev_ro;
GRANT ALL ON TABLE public.document_view TO medrxdev_rw;
GRANT ALL ON TABLE public.document_view TO devdba;
GRANT ALL ON TABLE public.document_view TO db_reader;
GRANT ALL ON TABLE public.document_view TO enterprisedb;
GRANT ALL ON TABLE public.document_view TO devops_jr;
GRANT ALL ON TABLE public.document_view TO svc_pgdump;
GRANT ALL ON TABLE public.document_view TO devops_rx;

--on prod payer solution
alter user mmiller with PASSWORD 'L1t3immTm$2012' valid until 'infinity';
COMMENT ON ROLE sstauffer IS 'Matt Weers, QA';
GRANT db_datawriter TO sstauffer;
-- READONLY > GRANT db_datareader TO mmiller;

grant select ON ALL TABLES IN SCHEMA public to medrx_ro;
grant EXECUTE ON ALL FUNCTIONS /*depend version PROCEDURES | ROUTINES*/ IN SCHEMA public to medrx_ro; --
grant select on that new/altered view to pgdev and pgdev_ro and svc_payersolution.

Solution UAT 11.60
alter table remittance_query_view owner to postgres;
grant select on remittance_query_view to pgdev_ro;
grant delete, insert, references, select, update on remittance_query_view to svc_payersolution;
grant select on remittance_query_view to db_datareader;
grant delete, insert, select, update on remittance_query_view to db_datawriter;

Prod Payer SOlution
alter table remittance_query_view owner to postgres;
grant select on remittance_query_view to pgdev_ro;
grant select on remittance_query_view to pgdev;
grant select on remittance_query_view to svc_payersolution;
grant select on remittance_query_view to db_datareader;
grant select on remittance_query_view to db_datawriter;

alter USER mbello WITH PASSWORD 'xxxxxxxxxxxxxxxxxxxxxx' VALID UNTIL '2022-10-31';

grant medrx_rw to mbello;

grant db_reader to mbello;

comment on role mbello is 'Monktar Bello, DBA';

drop user mbello;


create user mbellotest;

alter role mbellotest with nosuperuser;

alter role mbellotest with createdb;

alter role mbellotest with createrole;


SELECT * FROM information_schema.role_routine_grants

    SELECT * FROM information_schema.table_privileges

	alter role mbello with superuser

	alter role mbello with nosuperuser -- superuser, password, createdb, createrole, inherit, login, nologin...
	SELECT * FROM pg_authid /*pg_roles*/ WHERE rolname = 'luca'
	SELECT r.rolname, g.rolname AS group, m.admin_option AS is_admin
          FROM pg_auth_members m
               JOIN pg_roles r ON r.oid = m.member
               JOIN pg_roles g ON g.oid = m.roleid
          ORDER BY r.rolname;



--inspect privileges on different objects of databases
	SELECT distinct privilege_type FROM information_schema.table_privileges where grantee = 'casharc_ro';
SELECT distinct privilege_type FROM information_schema.role_table_grants where table_name not like 'pg_%' and grantee = 'casharc_ro'; --included views
SELECT * FROM information_schema.role_routine_grants where grantee = 'casharc_ro';
SELECT * FROM information_schema.role_udt_grants where grantee = 'casharc_ro';
select * from information_schema.role_usage_grants where grantee = 'casharc_ro';
select * from information_schema.views where table_name not like 'pg_%'; --included system views


For Postgres, and only for cases where privs were assigned directly to their account instead of via a role...
--tables, sequences, functions in each schema
replace functions with in
SELECT concat('revoke all privileges on all functions in schema  ', n.nspname , ' from pmcaskill; ')
FROM pg_class C
LEFT JOIN pg_namespace N
	ON (N.oid = C.relnamespace)
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
GROUP BY nspname;

--revoke all privileges on all tables in schema public from myUser;;
--revoke all privileges on all sequences in schema public from myUser;
--revoke all privileges on all functions in schema public from myUser;

----sequence & Table share the same owner
alter table prod.host_prefs_base owner to postgres;
alter sequence prod.host_prefs_base owner to postgres;
or simply
REASSIGN OWNED BY zgeyser TO postgres;
--then
drop role myUser;

