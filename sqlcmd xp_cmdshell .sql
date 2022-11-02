-- https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility?view=sql-server-ver15

--sqlcmd -S developer15/sql2012

--sqlcmd -U apps -P space15form3 -S developer15\sql2012

--exit

--go

-- write output to file

	SET @cmd = CONCAT( 'sqlcmd.exe -d master -o ',@FileName,' -q "exec [dba_db].[dbo].[sp_help_revlogin]"' )

	EXEC master..xp_cmdshell @cmd
