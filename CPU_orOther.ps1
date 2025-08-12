#https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-high-cpu-usage-issues

#If % User Time is consistently greater than 90 percent (% User Time is the sum of processor time on each processor, 
#its maximum value is 100% * (no of CPUs)), the SQL Server process is causing high CPU usage. 
#However, if % Privileged time is consistently greater than 90 percent, 
#your antivirus software, other drivers, or another OS component on the computer is contributing to high CPU usage.

$serverName = $env:COMPUTERNAME
$Counters = @(
    ("\\$serverName" + "\Process(sqlservr*)\% User Time"), ("\\$serverName" + "\Process(sqlservr*)\% Privileged Time")
)
Get-Counter -Counter $Counters -MaxSamples 30 | ForEach {
    $_.CounterSamples | ForEach {
        [pscustomobject]@{
            TimeStamp = $_.TimeStamp
            Path = $_.Path
            Value = ([Math]::Round($_.CookedValue, 3))
        }
        Start-Sleep -s 2
    }
}