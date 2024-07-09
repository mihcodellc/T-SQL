https://blog.purestorage.com/purely-technical/what-is-sql-servers-io-block-size/


-- disk peformance:diskspd, Crystal Mark, IOmeter
-- https://blog.purestorage.com/purely-technical/what-is-sql-servers-io-block-size/
--*****Operation -> IO Block size
-- ----log 512bytes  -> 60 KB
-- ----checkpoint/Lazywriter -> 8K-1MB
-- ----Read-Ahead scans -> 128KB-512KB
-- ----Bulk Loads -> 256 KB
-- ----Backup/Restore -> 1MB
-- ----Columnstore Read-Ahead -> 8MB
-- ----File Initizialization -> 8MB
-- ----In memory checkpoint 1MB

-- https://docs.microsoft.com/en-us/azure-stack/hci/manage/diskspd-overview
-- https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/dn894707(v=ws.11)
-- go to "Step 3: Run DiskSpd trial runs, and tune DiskSpd parameters" in above link to see action,meaning, how to decide
-- in powershell:  .\DiskSpd.exe /? #from its folder
-- in bat file, put : 
-- 	rem warm up 300 run for 30s
--	diskspd.exe -c100G -t24 -si64K -b64K -w70 -d600 -W300 -L -o12 -D -h u:\bello\testfile.dat > 64KB_Concurent_Write_24Threads_12OutstandingIO.txt
-- go look "diskPerformanceTested.ps1" in powershell directory


run sp_BlitzCache from brentozar can give an idea of IO: remember the @top (how many queries) and @sortOrder 
at specific time or @Top10 saved every 15min for instance
Blitz dashboard gives you more insights when blitz scripts are run and saved to tables periodically 
