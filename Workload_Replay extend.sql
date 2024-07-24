--give a try with https://github.com/spaghettidba/CodeSamples/tree/master/UsingWorkloadToolsToModernize
CREATE EVENT SESSION [WorkloadCapture] ON SERVER 
ADD EVENT sqlserver.attention(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.cursor_close(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.cursor_execute(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.cursor_open(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.cursor_prepare(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.cursor_unprepare(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.exec_prepared_sql(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.existing_connection(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.login(SET collect_options_text=(1)
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.logout(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.prepare_sql(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.rpc_completed(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.rpc_starting(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id)),
ADD EVENT sqlserver.sql_batch_starting(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.request_id,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id))
ADD TARGET package0.event_file(SET filename=N'G:\Replay\WorkloadCapture.xel',max_file_size=(50),max_rollover_files=(10))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO




ALTER EVENT SESSION [WorkloadCapture] ON SERVER STATE = START;



set statistics io,time on
select * from v_sisense_ProdWatch


ALTER EVENT SESSION [WorkloadCapture] ON SERVER STATE = STOP;

--You can export and analyze this data using various tools, such as SSMS, PowerShell, or custom scripts.

--***Configure Distributed Replay for Database Experimentation Assistant 
-- https://learn.microsoft.com/en-us/sql/dea/database-experimentation-assistant-configure-replay?view=sql-server-ver16


--For replay
--https://learn.microsoft.com/en-us/sql/tools/distributed-replay/sql-server-distributed-replay?view=sql-server-ver16
The Distributed Replay Controller has been removed from SQL Server 2022 (16.x) Setup, and 
    the Distributed Replay Client is no longer available in SQL Server Management Studio (SSMS) starting with version 18. 
    To obtain the Distributed Replay Controller, you must install SQL Server 2019 (15.x) or an earlier version. 
    To obtain the Distributed Replay Client, you must install SSMS 17.9.1.
    New way for replay: use Replay Markup Language (RML) Utilities, which includes ostress, to replay a workload.
    >>https://learn.microsoft.com/en-us/troubleshoot/sql/tools/replay-markup-language-utility
    to download and details
    once install go to C:\Program Files\Microsoft Corporation\RMLUtils
--S:\MSSQL\SQLOS-x86\140\Tools\DReplayController
--S:\MSSQL\SQLOS-x86\140\Tools\DReplayClient\Log
--install from sql installer Replay Controller then REplay client on each machien supposed to run the worload
--run Dcomcnfg services component and grant permissions to the domain account(DCOM Config > DREplay COntroller)
--start the services SQL Replay Controler, SQL Replay CLient
--run Lusrmgr.msc -- User & Group > Distributed Com Users
--netsh advfirewall firewall add rule name="allow dreplay controller" dir=in program="S:\MSSQL\SQLOS-x86\140\Tools\DReplayController\DReplayController.exe" action=allow
--netsh advfirewall firewall add rule name="allow dreplay client" dir=in program="S:\MSSQL\SQLOS-x86\140\Tools\DReplayClient\DReplayClient.exe" action=allow

--make sure the config file are properly set for client and controller
--in client config file, <Controller> is 
--     "localhost" or "." to refer to the local computer
-- OR
--    computer name if not local
https://learn.microsoft.com/en-us/sql/tools/distributed-replay/configure-distributed-replay?view=sql-server-ver16#DReplayController

--restart SQL Replay Controler, SQL Replay CLient then read the log of client 
--    or dreplay.exe status -f 1 --status
-- locate here : S:\MSSQL\SQLOS-x86\140\Tools\Binn\DReplay.exe once SSMS is installed
dreplay.exe status -f 1 --status
  
Info DReplay    Usage:
 DReplay.exe {preprocess|replay|status|cancel} [options] [-?]}

Verbs:
 preprocess Apply filters and prepare trace data for intermediate file on controller.
 replay     Transfer the dispatch files to the clients, launch and synchronize replay.
 status     Query and display the current status of the controller.
 cancel     Cancel the current operation on the controller.
 -?         Display the command syntax summary.

Options examples:
 dreplay preprocess [-m controller] -i input_trace_file -d controller_working_dir [-c config_file] [-f status_interval]
 dreplay replay [-m controller] -d controller_working_dir [-o] [-s target_server] -w clients [-c config_file] [-f status_interval]
 dreplay status [-m controller] [-f status_interval]
 dreplay cancel [-m controller] [-q]
 Run dreplay <verb> -? for detailed help on each verb.

  
