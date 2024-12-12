SELECT create_date ' last time the server is restarted' FROM sys.databases WHERE name = 'tempdb';

exec [RmsAdmin].dbo.[sp_Blitz] 
	  @CheckProcedureCache = 1 /*top 20-50 resource-intensive cache plans and analyze them for common performance issues*/, 
	  @CheckUserDatabaseObjects = 0/* 1 if you control the db objects*/,
	  @IgnorePrioritiesAbove = 500 /*if you want a daily bulletin of the most important warnings, set 50 */,
	  --@CheckProcedureCacheFilter = 'CPU' --- | 'Reads' | 'Duration' | 'ExecCount'
	  @CheckServerInfo = 1 

--know your server
--exec [RmsAdmin].dbo.[sp_Blitz] @checkServerInfo = 1
