restore database TestBello 
from disk = 'C:\Backup\testBello.bak'
with standby = 'C:\Backup\testBelloStandBy.tuf'

-- standby file is created by the restore command
-- standby file smaller in folder on your drive to be specify when restoring
-- !!! the norecovery deletes the standby .tuf. Save a copy of standby before try the restore
-- needs standby file to move from standby to norecovery or vice-versa
--


restore database TestBello with norecovery

restore database TestBello with standby = 'G:\MSSQL\Backup\testBelloStandBy.tuf'
