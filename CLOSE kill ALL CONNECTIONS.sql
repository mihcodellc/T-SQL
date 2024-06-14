--before restore disconnect every body
--https://thesitedoctor.co.uk/blog/dropkill-all-connections-to-a-sql-database/

--user still connected
SELECT 'kill ' +cast(session_id as varchar(25))
FROM sys.dm_exec_sessions
WHERE login_name = 'mbello'
	
-- owner of a job
SELECT name,* 
FROM msdb..sysjobs
WHERE owner_sid = SUSER_SID('mbello')

-- **********CLOSE ALL CONNECTIONS ON THE DATABASE  
DECLARE @dbid INT, @KillStatement char(30), @SysProcId smallint
--define the targeted database 
SELECT @dbid = dbid FROM sys.sysdatabases WHERE name = 'MydataBase' 
IF EXISTS (SELECT spid FROM sys.sysprocesses WHERE dbid = @dbid)
  BEGIN
    PRINT '*********CREATE WOULD FAIL -DROPPING ALL CONNECTIONS*********'
    PRINT '----These processes are blocking the restore from occurring----'
    SELECT spid, hostname, loginame, status, last_batch FROM sys.sysprocesses WHERE dbid = @dbid 
    --Kill any connections while you are on master
	USE master
    DECLARE SysProc CURSOR LOCAL FORWARD_ONLY DYNAMIC READ_ONLY FOR
    SELECT spid FROM master.dbo.sysprocesses WHERE dbid = @dbid and spid <> @@SPID
    OPEN SysProc
    FETCH NEXT FROM SysProc INTO @SysProcId
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @KillStatement = 'KILL ' + CAST(@SysProcId AS char(30))
        EXEC (@KillStatement)
        FETCH NEXT FROM SysProc INTO @SysProcId
    END
END
