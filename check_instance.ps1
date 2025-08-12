##load to chatGPT if can't make sense of it

# https://www.mssqltips.com/sqlservertip/5114/sql-server-performance-troubleshooting-system-health-checklist/

write-host "**************CPU************"
Get-Counter '\Processor(*)\% Processor Time'


write-host "**************Memory************"

 Get-Counter '\Memory\Available MBytes'
 Get-Counter '\Memory\Page Faults/sec'
 Get-Counter '\Paging File(_Total)\% Usage'
 
 
 write-host "**************IO************"
Get-Counter '\PhysicalDisk(*)\Current Disk Queue Length'

Get-Counter '\PhysicalDisk(*)\Disk Reads/sec'

Get-Counter '\PhysicalDisk(*)\Disk Writes/sec'

Get-Counter '\PhysicalDisk(*)\Avg. Disk sec/Read'

Get-Counter '\PhysicalDisk(*)\Avg. Disk sec/Write'


 write-host "**************Network************"
 
 Get-Counter '\Network Interface(*)\Bytes Sent/sec'

 Get-Counter '\Network Interface(*)\Bytes Received/sec'
 
 
  write-host "**************Server************"
Get-Counter '\SQLServer:Buffer Manager\Buffer cache hit ratio'

Get-Counter '\SQLServer:Buffer Manager\Page Life Expectancy'

Get-Counter '\SQLServer:SQL Statistics\Batch Requests/sec'

Get-Counter '\SQLServer:SQL Statistics\SQL Compilations/sec'