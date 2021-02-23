--sp_blitz @CheckUserDatabaseObjects=1;
--GO
--sp_blitz @Help=1; --read
--GO
--sp_blitz @IgnorePrioritiesBelow=50


--sp_blitz @SkipChecksDatabase ='TestBello' , @SkipChecksSchema='dbo', @SkipChecksTable='BlitzChecksToSkipBELLO'
--sp_blitz @OutputDatabaseName ='TestBello' , @OutputSchemaName='dbo', @OutputTableName='BlitzChecksToSkipBELLO'



--INSERT INTO #MyTempTable SELECT * FROM OPENROWSET ('SQLOLEDB','Server=(local);TRUSTED_CONNECTION=YES;','set fmtonly off EXEC dbo.[sp_Blitz] @OutputXMLasNVARCHAR = 1')
--SELECT * FROM BlitzChecksToSkipBELLO


----SELECT TOP 5 * INTO #MyTempTable FROM APPS.CallDetails
----select * from #MyTempTable

--SELECT TOP 5 * INTO #MyTempTable0 FROM OPENROWSET ('SQLOLEDB','Server=(local);TRUSTED_CONNECTION=YES;','set fmtonly off EXEC dbo.[sp_Blitz] @OutputXMLasNVARCHAR = 0')
--select * from #MyTempTable0

--sp_BlitzIndex
--GO
----SELECT  * INTO #BelloBlitzIndex FROM (EXEC sp_BlitzIndex @Mode=4);

----Create table dbo.BelloBlitzIndex (Priorit int, finding nvarchar(max),dbName nvarchar(max), details nvarchar(max), definition nvarchar(max), SecretColumns nvarchar(max),Usage nvarchar(max), size nvarchar(max), MoreInfo nvarchar(max), URL nvarchar(max), 
----			CreateTSQL nvarchar(max))

--DELETE  dbo.BelloBlitzIndex
--go
--sp_BlitzIndex @Mode=4, @OutputServerName='DEVELOPER16', @OutputDatabaseName='iThinkHealth', @OutputSchemaName ='dbo', @OutputTableName='BelloBlitzIndex'
--GO
--select * from dbo.BelloBlitzIndex B ORDER BY B.Priority ASC, B.Finding, B.Usage DESC, B.Size DESC --#BelloBlitzIndex

----EXEC dbo.sp_BlitzIndex @DatabaseName='iThinkHealth', @SchemaName='APPS', @TableName='PA_Main';

----EXEC dbo.sp_BlitzIndex @DatabaseName='iThinkHealth', @SchemaName='APPS', @TableName='BillingRef';





--EXEC dbo.sp_BlitzIndex  
--  @OutputDatabaseName = 'master', 
--  @OutputSchemaName = 'dbo', 
--  @OutputTableName = 'mbBlitzFirst',
--  @Mode=4

----meaning of 'Heap with a Nonclustered Primary Key'
--select *from sys.indexes i where type = 2 AND is_primary_key = 1 AND EXISTS 
--(
--SELECT 1/0 
--FROM sys.indexes AS isa
--WHERE 
--    i.object_id = isa.object_id
--AND   isa.index_id = 0
--)
--select * from sys.indexes where object_id in (374448558,445504916,618302554)


---from #BlitzIndexResults creation table
CREATE TABLE dbo.BelloBlitzIndex
            (
              blitz_result_id INT IDENTITY PRIMARY KEY,
              check_id INT NOT NULL,
              index_sanity_id INT NULL,
              Priority INT NULL,
              findings_group NVARCHAR(4000) NOT NULL,
              finding NVARCHAR(200) NOT NULL,
              [database_name] NVARCHAR(128) NULL,
              URL NVARCHAR(200) NOT NULL,
              details NVARCHAR(MAX) NOT NULL,
              index_definition NVARCHAR(MAX) NOT NULL,
              secret_columns NVARCHAR(MAX) NULL,
              index_usage_summary NVARCHAR(MAX) NULL,
              index_size_summary NVARCHAR(MAX) NULL,
              create_tsql NVARCHAR(MAX) NULL,
              more_info NVARCHAR(MAX)NULL
            );



--select distinct  ObjectName from dbo.suitTH where ObjectName is not null and SourceDatabaseID=46 and ObjectName like '%bill%'
--select distinct  ObjectName  from testBello.dbo.suitTH where ObjectName is not null and SourceDatabaseID=46 and textData like '%billing%' ORDER BY ObjectName
--SELECT ObjectName, COUNT(*) NbreOfExecution FROM testBello.dbo.suitTH where ObjectName is not null and SourceDatabaseID=46 and textData like '%billing%' GROUP BY ObjectName ORDER BY ObjectName

------exec APPS.sp_GetBillingAcctRecPaysourceByPatient @PatientID=1555


--print '5. Top 10 SQL statements with high Writes consumption'
--select top 100
--    qs.total_logical_writes,
--    st.dbid,
--    DB_NAME(st.dbid) as DbName,
--    st.text , OBJECT_NAME(st.objectid) AS [ObjectName]
--from sys.dm_exec_query_stats as qs
--cross apply sys.dm_exec_sql_text(sql_handle) st
--where text like '%billi%'
--order by total_logical_writes desc
--go


--select datediff(DAY,'2019-07-27', '2019-08-19')