#Monktar Bello 8/12/2025 - initial verison: check or others on Windows servers

#https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-high-cpu-usage-issues

#If % User Time is consistently greater than 90 percent (% User Time is the sum of processor time on each processor, 
#its maximum value is 100% * (no of CPUs)), the SQL Server process is causing high CPU usage. 
#However, if % Privileged time is consistently greater than 90 percent, 
#your antivirus software, other drivers, or another OS component on the computer is contributing to high CPU usage.

#if execute from powershell windows adjust the "-MaxSamples 3"
#on remote with admin priv & WinRM enabled, set on time: Enable-PSRemoting -Force then run step 2 OR
			## Step 1: Copy script to remote
			#$session = New-PSSession -ComputerName RemotePCName -Credential (Get-Credential)
			#Copy-Item "G:\xfer\powershell\CPU_orOther.ps1" -Destination "C:\Temp\" -ToSession $session

			## Step 2: Run script remotely
			#Invoke-Command -Session $session -ScriptBlock { 
			#	powershell.exe -ExecutionPolicy Bypass -File "C:\Temp\CPU_orOther.ps1"
			#}

			## Step 3: Close session
			#Remove-PSSession $session


#if psexec is setable for you
#psexec \\RemotePCName -u DOMAIN\User -p Password powershell.exe -ExecutionPolicy Bypass -File "G:\xfer\powershell\CPU_orOther.ps1"


$serverName = $env:COMPUTERNAME

# Get total number of logical CPU cores on this machine
$cpuCount = (Get-WmiObject Win32_Processor | Measure-Object NumberOfLogicalProcessors -Sum).Sum

# Define counters
$counters = @(
    "\\$serverName\Process(sqlservr*)\% User Time",
    "\\$serverName\Process(sqlservr*)\% Privileged Time"
)

# Collect samples
Get-Counter -Counter $counters -MaxSamples 3 | ForEach-Object {
    $_.CounterSamples | ForEach-Object {
        [pscustomobject]@{
            TimeStamp = $_.TimeStamp
            Path      = $_.Path
            # Divide by core count to get true % CPU usage
            Value     = [Math]::Round(($_.CookedValue / $cpuCount), 3)
        }
        Start-Sleep -Seconds 2
    }
}
