#instructions
#1. install dbatools for my user: Install-Module dbatools -Scope CurrentUser
#2. Import-Module dbatools
#3. replace sps' list for parameter name in export_db_script.ps1
#4. if needed, replace the out file destination and name

#This drop then create script


########## export_db_script.ps1 content#########################################################

# https://docs.dbatools.io/Export-DbaScript
# https://docs.dbatools.io/New-DbaScriptingOption 
# # all Microsoft.SqlServer.Management.Smo.ScriptingOptions 
# https://learn.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.scriptingoptions?redirectedfrom=MSDN&view=sql-smo-160

#Note: don't split the 3rd line
#create export file for each options then compare. ScriptForCreateDrop only script Create in my environment
#connection's credentials are omited because the account running this is sysadmin in sql server
#Name all procedures separated by comma
#did get dupes from the script generated. the errors receive when run make sense.

# $options = New-DbaScriptingOption
# $options.ScriptDrops = $true
# #without $options # Get-DbaDbStoredProcedure -SqlInstance instanceName -Database DbName -Name <list all SPs with comma as seperator> | Export-DbaScript -FilePath G:\export.sql -Append
# #with $options #Get-DbaDbStoredProcedure -SqlInstance instanceName -Database DbName -Name <list all SPs with comma as seperator> | | Export-DbaScript -ScriptingOptionsObject $options -FilePath G:\export_drop.sql -Append

#Stored proc
$options = New-DbaScriptingOption
$options.ScriptDrops = $true # OR $options.ScriptForCreateDrop OR $options.ScriptForAlter
Get-DbaDbStoredProcedure -SqlInstance MySQLServerName -Database MyDB -Name sp1, sp2 | Export-DbaScript -ScriptingOptionsObject $options -FilePath G:\export_drop.sql -Append

#views
$options = New-DbaScriptingOption
$options.ScriptDrops = $true # OR $options.ScriptForCreateDrop OR $options.ScriptForAlter
 Get-DbaDbView  -SqlInstance MySQLServerName -Database MyDB -View view1, view2 | Export-DbaScript -ScriptingOptionsObject $options -FilePath G:\export_drop.sql -Append




