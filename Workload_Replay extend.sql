--For replay
--S:\MSSQL\SQLOS-x86\140\Tools\DReplayController
--S:\MSSQL\SQLOS-x86\140\Tools\DReplayClient\Log
--install from sql installer Replay Controller then REplay client on each machien supposed to run the worload
--run Dcomcnfg services component and grant permissions to the domain account(DCOM Config > DREplay COntroller)
--start the services SQL Replay Controler, SQL Replay CLient
--run Lusrmgr.msc -- User & Group > Distributed Com Users
--netsh advfirewall firewall add rule name="allow dreplay controller" dir=in program="S:\MSSQL\SQLOS-x86\140\Tools\DReplayController\DReplayController.exe" action=allow
--netsh advfirewall firewall add rule name="allow dreplay client" dir=in program="S:\MSSQL\SQLOS-x86\140\Tools\DReplayClient\DReplayClient.exe" action=allow

--replay admin tools is included the last time in SSMS installation not SQL Server installation
--
dreplay.exe status -f 1 --status
  
Info DReplay    Usage:
 DReplay.exe {preprocess|replay|status|cancel} [options] [-?]}

Verbs:
 preprocess Apply filters and prepare trace data for intermediate file on controller.
 replay     Transfer the dispatch files to the clients, launch and synchronize replay.
 status     Query and display the current status of the controller.
 cancel     Cancel the current operation on the controller.
 -?         Display the command syntax summary.

Options:
 dreplay preprocess [-m controller] -i input_trace_file -d controller_working_dir [-c config_file] [-f status_interval]
 dreplay replay [-m controller] -d controller_working_dir [-o] [-s target_server] -w clients [-c config_file] [-f status_interval]
 dreplay status [-m controller] [-f status_interval]
 dreplay cancel [-m controller] [-q]
 Run dreplay <verb> -? for detailed help on each verb.
