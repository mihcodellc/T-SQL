Use master
go
PRINT 'Supprimer les connexions actives'
declare @databasename nvarchar(100)
declare @sess_id int
declare @kill_session varchar(20)
set @databasename = 'BDFINMASPADME'


DECLARE session_id_cursor CURSOR FOR
SELECT DISTINCT request_session_id FROM master.sys.dm_tran_locks WHERE resource_type = 'DATABASE' AND resource_database_id =
db_id(@databasename) and request_session_id<>@@spid
OPEN session_id_cursor
FETCH NEXT FROM session_id_cursor INTO @sess_id
WHILE @@FETCH_STATUS = 0
BEGIN
set @kill_session = 'kill '+ convert(varchar(10),@sess_id) + ';'

--select host_name,login_name,* from sys.dm_exec_sessions where session_id=@sess_id order by sys.dm_exec_sessions.login_name
if @sess_id=94
	begin 
		exec (@kill_session)
		print 'Supprimé ' + cast(@sess_id as varchar(10))
	end 
FETCH NEXT FROM session_id_cursor
INTO @sess_id
END
CLOSE session_id_cursor
DEALLOCATE session_id_cursor
go
