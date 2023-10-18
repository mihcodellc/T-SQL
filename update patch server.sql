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
Stop or shut down client apps. You don’t want folks starting a transaction as your update begins.
Make sure there’s no activity happening on the server, especially long-running jobs like backups.
Apply the update – if you’re using PowerShell, check out how to automate patching with DBAtools.
Apply Windows updates since you’re down anyway. (Sometimes I find folks have been applying SQL updates, but not Windows updates – they’re both important.)
Confirm the SQL Server service is started, and check your monitoring tools for any unexpected failures.
Confirm the SQL Server Agent service is started again, and kick off your next log backup job.
Start client apps back up and make sure they function.

Over the coming days, keep a much closer eye than normal on monitoring tools looking for unexpected failures. 

***************************************************HOW-TO*****************************************************
## https://desertdba.com/how-i-applied-13-cumulative-updates-in-12-minutes/
##it will restart the physical box

$ServerName = "SQL-TEST001","SQL-TEST002" #remote servers won't work if Service Principal Names(SPN) for SQL Server is not set in Active Directory


$KeyPath = 'C:\DBA\'

$UserName = 'rms-asp\mbello'

$CredFile = $KeyPath+'mbello.cred'

##store password encrypted in file: it is OS specific. one created on os1 won't work on os2
#$Credential = Get-Credential -Message "Enter the Credentials:" -UserName $UserName
#$Credential.Password | ConvertFrom-SecureString | Out-File $CredFile -Force

#Get encrypted password from the file
$SecureString = Get-Content $CredFile | ConvertTo-SecureString # Unlike a secure string, an encrypted standard string can be saved in a file for later use
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecureString


#has to be shared folder accessable by all servers involved
$PathCU = '\\sql-test001\Sql_Backup\download'

#don't remane the download file
$VersionCU = 'SQLServer2017-KB5016884-x64'

#write-host "get build before" 
#Get-DbaInstanceProperty -SqlInstance "SQL-TEST001","SQL-TEST002"  -InstanceProperty BuildNumber, edition, ErrorLogPath 
Get-DbaInstanceProperty -SqlInstance "SQL-TEST001","SQL-TEST002"  -InstanceProperty BuildNumber #, edition, ErrorLogPath

#tested the update to CU31 - omit version will update to the lastest of files find in download folder
# can update different versions of sql server if CU is found in the downlad folder
#Update-DbaInstance -ComputerName $ServerName -Restart -Version CU31 -Path $PathCU -Credential $Credential -Confirm:$false -whatif 
#Update-DbaInstance -ComputerName $ServerName -Restart -Path $PathCU -Credential $Credential -Confirm:$false -whatif
Update-DbaInstance -ComputerName $ServerName -Restart -Path $PathCU -Credential $Credential -Confirm:$false -verbose | out-file sqlpatch.log -force

#write-host "get build after" 
Get-DbaInstanceProperty -SqlInstance "SQL-TEST001","SQL-TEST002"  -InstanceProperty BuildNumber #, edition, ErrorLogPath

