Get-Command -Name *name* -Module dbatools -Type Function

#update dbatools 
#use existing version or folder -- add to existing path
#validate command with existing folder
$Env:PSModulePath = $Env:PSModulePath+";S:\DBA\dbatools"


$cred = Get-Credential rms-asp\mbello


Copy-DbaSpConfigure -Source sql-test001 -SourceSqlCredential $cred  -Destination sql-test002 -DestinationSqlCredential $cred | out-file -FilePath C:\Users\mbello\Documents\DbatoolsExport\copylog.txt
Copy-DbaDbMail -Source sql-test001 -SourceSqlCredential $cred  -Destination sql-test002 -DestinationSqlCredential $cred | out-file -FilePath C:\Users\mbello\Documents\DbatoolsExport\copylog.txt
Copy-DbaLinkedServer -Source sql-test001 -SourceSqlCredential $cred  -Destination sql-test002 -DestinationSqlCredential $cred | out-file -FilePath C:\Users\mbello\Documents\DbatoolsExport\copylog.txt

$cred = Get-Credential rms-asp\mbello

# need domain user running sql engine, sqlagent - the sharedPath is used to backup then from there restore
Copy-DbaDatabase -Source sql-test001 -SourceSqlCredential $cred  -Destination sql-test002 -DestinationSqlCredential $cred -database WideWorldImporters,testBello -backupRestore -SharedPath \\sql-test001\Sql_Backup  | out-file -FilePath C:\Users\mbello\Documents\DbatoolsExport\copylog.txt


# migrate everything except Databases, Logins, Jobs
#using this command, if jobs copying is not exclude(ie AgentServer); it is a mess, what else is a mess. I cannot create some jobs like one named as "DD69B1C1-9BC3-4CC9-97CC-446ED6FF6497"
Start-DbaMigration -Verbose -Source sql-test001  -SourceSqlCredential $cred -Destination sql-test002  -DestinationSqlCredential $cred -Exclude Databases, Logins, AgentServer | out-file -FilePath C:\Users\mbello\Documents\copylog.txt

#existing ones are drop and recreate
Copy-DbaLogin -Source sql-test001 -SourceSqlCredential $cred  -Destination sql-test002 -DestinationSqlCredential $cred -Force | out-file -FilePath C:\Users\mbello\Documents\DbatoolsExport\copylog.txt

#existing ones are drop and recreate
Copy-DbaAgentJob -Source sql-test001 -SourceSqlCredential $cred  -Destination sql-test002 -DestinationSqlCredential $cred -Force | out-file -FilePath C:\Users\mbello\Documents\DbatoolsExport\copylog.txt


#rename the instance
#https://docs.microsoft.com/en-us/sql/database-engine/install-windows/rename-a-computer-that-hosts-a-stand-alone-instance-of-sql-server?view=sql-server-ver16
EXEC sp_dropserver '<old_name>';  
GO  
EXEC sp_addserver '<new_name>', local;  
GO  
restart machine/server



# Check out our export/backup commands
Get-Command -Name Export-DbaScript -Module dbatools -Type Function
Get-Command -Name *export* -Module dbatools -Type Function
Get-Command -Name *backup* -Module dbatools -Type Function
Get-Command -Name *dbadac* -Module dbatools -Type Function

# Let's examine the commands a little more. First up! Export-DbaScript

# Start with something simple
Get-DbaAgentJob -SqlInstance workstation\sql2016 | Select -First 1 | Export-DbaScript

# Now let's look inside
Get-DbaAgentJob -SqlInstance workstation\sql2016 | Select -First 1 | Export-DbaScript | Invoke-Item

# Raw output and add a batch separator
Get-DbaAgentJob -SqlInstance workstation\sql2016 | Export-DbaScript -Passthru -BatchSeparator GO

# Get crazy
#Set Scripting Options
$options = New-DbaScriptingOption
$options.ScriptSchema = $true
$options.IncludeDatabaseContext  = $true
$options.IncludeHeaders = $false
$Options.NoCommandTerminator = $false
$Options.ScriptBatchTerminator = $true
$Options.AnsiFile = $true

# The next command will use SQL authentication
# first, pipe the password to clipboard as an example
'Zjady7$$$fxzy(&*($1' | clip
Get-DbaDbMailProfile -SqlInstance workstation\sql2016 -SqlCredential sqladmin | 
Export-DbaScript -Path C:\temp\export.sql -ScriptingOptionsObject $options -NoPrefix | Invoke-Item

# Now for a few special commands that SMO didn't quite do justice to
Export-DbaSpConfigure -SqlInstance workstation\sql2016 -Path C:\temp\sp_configure.sql
# Warning, this will write clear-text passwords to disk
Export-DbaLinkedServer -SqlInstance workstation\sql2016 -Path C:\temp\linkedserver.sql | Invoke-Item
# This will write hashed passwords to disk
Export-DbaLogin -SqlInstance workstation\sql2016 -Path C:\temp\logins.sql | Invoke-Item

# Other specials, relative to the server itself
Backup-DbaDbMasterKey -SqlInstance workstation\sql2016
Backup-DbaDbMasterKey -SqlInstance workstation\sql2016 -Path \\localhost\backups

# What if you just want to script out your restore? Invoke Backup-DbaDatabase or your Maintenance Solution job
# Let's create a FULL, DIFF, LOG, LOG, LOG
Start-DbaAgentJob -SqlInstance localhost\sql2016 -Job 'DatabaseBackup - SYSTEM_DATABASES - FULL','DatabaseBackup - USER_DATABASES - FULL'
Get-DbaRunningJob -SqlInstance localhost\sql2016

Start-DbaAgentJob -SqlInstance localhost\sql2016 -Job 'DatabaseBackup - USER_DATABASES - DIFF'
Get-DbaRunningJob -SqlInstance localhost\sql2016

Start-DbaAgentJob -SqlInstance localhost\sql2016 -Job 'DatabaseBackup - USER_DATABASES - LOG'
Get-DbaRunningJob -SqlInstance localhost\sql2016

Start-DbaAgentJob -SqlInstance localhost\sql2016 -Job 'DatabaseBackup - USER_DATABASES - LOG'
Get-DbaRunningJob -SqlInstance localhost\sql2016

Start-DbaAgentJob -SqlInstance localhost\sql2016 -Job 'DatabaseBackup - USER_DATABASES - LOG'
Get-DbaRunningJob -SqlInstance localhost\sql2016

# Now export the restores to disk
Get-ChildItem -Directory '\\localhost\backups\WORKSTATION$SQL2016' | Restore-DbaDatabase -SqlInstance localhost\sql2017 -OutputScriptOnly -WithReplace | Out-File -Filepath c:\temp\restore.sql

Invoke-Item c:\temp\restore.sql

# Speaking of Ola, use his backup script? We can restore an *ENTIRE INSTANCE* with just one line
Get-ChildItem -Directory \\workstation\backups\sql2012 | Restore-DbaDatabase -SqlInstance localhost\sql2017 -WithReplace

# Log shipping, what's up - dbatools.io/logshipping
# Also supports multiple destinations!
 $params = @{
    Source = 'localhost\sql2016'
    Destination = 'localhost\sql2017'
    Database = 'shipped'
    BackupNetworkPath= '\\localhost\backups'
    PrimaryMonitorServer = 'localhost\sql2017'
    SecondaryMonitorServer = 'localhost\sql2017'
    BackupScheduleFrequencyType = 'Daily'
    BackupScheduleFrequencyInterval = 1
    CompressBackup = $true
    CopyScheduleFrequencyType = 'Daily'
    CopyScheduleFrequencyInterval = 1
    GenerateFullBackup = $true
    Force = $true
}

Invoke-DbaDbLogShipping @params

# And now, failover to secondary
Invoke-DbaDbLogShipRecovery -SqlInstance localhost\sql2017 -Database shipped

# Introducing Export-DbaInstance
# Written for #SQLGLA!
# Get Pester and drop code at sqlps.io/doomsday

# Check that everything exists prior to export
Invoke-Pester C:\github\community-presentations\chrissy-lemaire\doomsday.Tests.ps1

# Do it all at once
Export-DbaInstance -SqlInstance workstation\sql2016 -Path \\workstation\backups\DR
Invoke-Item \\workstation\backups\DR

# It ain't a DR plan without testing
Test-DbaLastBackup -SqlInstance workstation\sql2016

# Now let's test the output scripts. 
# This will also kill SSMS so that I'm forced to refresh, and open it back up
. C:\github\community-presentations\chrissy-lemaire\doomsday-dropeverything.ps1

# Check that everything has been dropped
Invoke-Pester C:\github\community-presentations\chrissy-lemaire\doomsday.Tests.ps1

# Prep
Stop-DbaService -ComputerName localhost -InstanceName sql2016 -Type Agent
Get-DbaProcess -SqlInstance localhost\sql2016 -Database msdb | Stop-DbaProcess


# Perform restores and restart SQL Agent
$files = Get-ChildItem -Path \\workstation\backups\DR -Exclude *agent* | Sort-Object LastWriteTime
$files | ForEach-Object {
    Write-Output "Running $psitem"
    Invoke-DbaQuery -File $PSItem -SqlInstance workstation\sql2016 -ErrorAction Ignore -Verbose
}

Start-DbaService -ComputerName localhost -InstanceName sql2016 -Type Agent

# Check if everything is back
Invoke-Pester C:\github\community-presentations\chrissy-lemaire\doomsday.Tests.ps1