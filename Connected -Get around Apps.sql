--0 make sure you have the green light of DevOps stating apps are down

--1 create the trigger

CREATE or alter TRIGGER connection_limit_trigger
ON ALL SERVER --WITH EXECUTE AS 'login_test'
FOR LOGON
AS
BEGIN
IF ORIGINAL_LOGIN() in ('testbello', 'sa') 
--AND
--    (SELECT COUNT(*) FROM sys.dm_exec_sessions
--            WHERE is_user_process = 1 AND
--                original_login_name = 'login_test') > 3
    ROLLBACK;
END;

ENABLE TRIGGER connection_limit_trigger -- { | ALL }
ON ALL SERVER -- { object_name | DATABASE | ALL SERVER }


go

--DISABLE TRIGGER MySchema.MyTrigger ON MyTable;
DISABLE TRIGGER connection_limit_trigger -- { | ALL }
ON ALL SERVER -- { object_name | DATABASE | ALL SERVER }

go

--ENABLE TRIGGER connection_limit_trigger -- { | ALL }
--ON ALL SERVER -- { object_name | DATABASE | ALL SERVER }


--2 make sure the trigger is enabled in previous statements 

--3 disable SQL Agent

--4 restart the server

--5 login with not exclude account

--6 run your DBA query

--7 drop the trigger

--8 enable SQL Agent
