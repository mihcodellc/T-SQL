--***1.perform benchmark tests and determine the I/O capacity
-- disk performance:diskspd, Crystal Disk Mark, IOmeter
-- https://blog.purestorage.com/purely-technical/what-is-sql-servers-io-block-size/
--*****Operation -> IO Block size
-- ----log  -> 512bytes - 60 KB
-- ----checkpoint/Lazywriter -> 8K-1MB
-- ----Read-Ahead scans -> 128KB-512KB
-- ----Bulk Loads -> 256 KB
-- ----Backup/Restore -> 1MB
-- ----Columnstore Read-Ahead -> 8MB
-- ----File Initizialization -> 8MB
-- ----In memory checkpoint 1MB

--https://www.altaro.com/hyper-v/storage-performance-baseline-diskspd/#Example_%C2%A0SQL_Server_Performance%C2%A0Baselining
-- https://docs.microsoft.com/en-us/azure-stack/hci/manage/diskspd-overview
-- https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/dn894707(v=ws.11)
-- go to "Step 3: Run DiskSpd trial runs, and tune DiskSpd parameters" in above link to see action,meaning, how to decide
-- in powershell:  .\DiskSpd.exe /? #from its folder
-- in bat file, put : 
-- 	rem warm up 300 run for 30s
--	diskspd.exe -c100G -t24 -si64K -b64K -w70 -d600 -W300 -L -o12 -D -h u:\bello\testfile.dat > 64KB_Concurent_Write_24Threads_12OutstandingIO.txt
-- go look "diskPerformanceTested.ps1" in powershell directory

--***2.to perform reliability and integrity tests on disk subsystems
-- SQLIOSim (ex SQLIOStress) to perform reliability and integrity tests on disk subsystems


--***get block size in powershell 
-- https://social.technet.microsoft.com/wiki/contents/articles/33812.sql-server-storage-checking-volumes-block-sizes.aspx
$wmiQuery = "SELECT Name, Label, Blocksize FROM Win32_Volume WHERE FileSystem='NTFS'"
Get-WmiObject -Query $wmiQuery -ComputerName '.' | Sort-Object Name | Select-Object Name, Label, Blocksize
