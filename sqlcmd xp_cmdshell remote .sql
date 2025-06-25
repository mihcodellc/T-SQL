-- https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility?view=sql-server-ver15

--sqlcmd -S developer15/sql2012

--sqlcmd -U apps -P space15form3 -S developer15\sql2012

--exit

--go

-- write output to file

	SET @cmd = CONCAT( 'sqlcmd.exe -d master -o ',@FileName,' -q "exec [dba_db].[dbo].[sp_help_revlogin]"' )

	EXEC master..xp_cmdshell @cmd


exec xp_cmdshell 'C:\test.bat LOG';


--on remote
--***file
sqlcmd -U mbello -d MyDB -S MyAzure.database.windows.net -P "password" -i c:\DBA\maintenance\script.sql -o c:\DBA\maintenance\out.tmp  -h -1 
--***query
sqlcmd -U mbello -d MyDB -S MyAzure.database.windows.net -P "password" -q 'select top 1 * from mystable' -o c:\DBA\maintenance\out.tmp  -h -1
