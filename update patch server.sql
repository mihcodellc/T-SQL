-- https://www.brentozar.com/archive/2021/06/how-to-patch-sql-server/

last patches are here 
  https://learn.microsoft.com/en-us/troubleshoot/sql/releases/download-and-install-latest-updates
  or
  The Most Recent Updates for Microsoft SQL Server - SQLServerUpdates.com

How to patch: 

>Design your actual rollout strategy

>Design your rollback strategy

>When applying the actual patch, here’s what I like to do, in order:

Verify that you have backups. Ideally, do a test restore, too: backup success messages don’t mean you have working backup files.
if applicable, take VM snapshot
takes note of status of SQL services (running, stopped ...)   
Stop or shut down client apps. You don’t want folks starting a transaction as your update begins.
Make sure there’s no activity happening on the server, especially long-running jobs like backups.
Apply the update – if you’re using PowerShell, check out how to automate patching with DBAtools.
Apply Windows updates since you’re down anyway. (Sometimes I find folks have been applying SQL updates, but not Windows updates – they’re both important.)
Confirm the SQL Server service is started, and check your monitoring tools for any unexpected failures.
Confirm the SQL Server Agent service is started again, and kick off your next log backup job.
make sure SQL Services' current status matched the status noted before applying the patch
Start client apps back up and make sure they function.

Over the coming days, keep a much closer eye than normal on monitoring tools looking for unexpected failures. 

***************************************************HOW-TO*****************************************************
patchSQLSERVER.ps1 
