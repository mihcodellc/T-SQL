[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null
$serverInstance = "ServerName"
 
$server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $serverInstance
 
$jobs = $server.JobServer.Jobs 
 
if ($jobs -ne $null)
{
	 foreach ($i in $jobs)
	{
		$jobName = $i.Name
		$jobName = $jobName.Replace(":", "-")
		$jobName = $jobName.Replace(" ", "_")
		 
		$FileName = "D:\MSSQL\JOB_" + $jobName + ".sql"
		Set-Location c:
		$i.Script() | Out-File -filepath $FileName
	}
}