status 12/10/2021
We have the following set to COMPATIBILITY 2008(100) :


Only ?? db has Query Store enabled. We need to turn on  Query Store on the others.
ALTER DATABASE <database_name>
	SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE); -- (with cleanup policy well define)
	
Safety issue: expose to lost of data, if you have recovery model is SIMPLE; it should be in full Recovery model
 	

https://docs.microsoft.com/en-us/sql/relational-databases/performance/best-practice-with-the-query-store?view=sql-server-ver15#Configure

according to the article on this page,
https://docs.microsoft.com/en-us/sql/relational-databases/performance/query-store-usage-scenarios?view=sql-server-ver15#CEUpgrade
these following steps has been done for hope db and others with compatibility level set to 100:
-upgrade to new SQL Server
-enable Query store (with cleanup policy well define) 
-collect data on the workload (over a sufficient period of time ideally business cycle). Running the known SPs with performance regressions could save you some times
We still need to apply the following:
-set db Compatibility to the latest (2017)
-collect data on the workload (over a sufficient period of time ideally business cycle)
-fix regressions by forcing last known good plan.
	refer to Regressed queries node and forced the plans used by the important queries before the db compatibility is set to latest compatibility.
	Execute : ALTER DATABASE ithinkhealth SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON ); 
	Doing that, Query Store will use the best plan using the history of performance. It's to be monitored.
	We can also look at the tuning recommandations: 	SELECT * FROM sys.dm_db_tuning_recommendations
https://docs.microsoft.com/en-us/sql/relational-databases/automatic-tuning/automatic-tuning?view=sql-server-ver15#automatic-plan-correction

Process to apply the last to steps:
- make sure that the most important queries or stored procedures or screen are gathered or let Query Store run enough time to ccapture the workload.
- a recent back up of recent Hope DB(included Query store's Data)
- restore it as test database on an instance
- run those important queries - your workload
- set db compatibility to SQL Server 2017 (140)
- run the same important queries
- Database > Query Store > Regressed Queries > Views Regressed queries 
- If found, you see for each regressed query, at least 2 different plans   
- select a query in queries chart > hit "Force Plan" > a pop up message "Do you want to force plan X1 for the query Y1"
- Hit "Yes" Button
-- overall resource consumption > standard grid > set "configure" 30 or 90 days, clear top 25 for all queries
-- overall resource consumption > standard grid > right click on the object name > track query
-- "view query" is in  the top toolbar  




suggestions to detect soon release issues:
have important queries in QUERY STORE tracked in 3 or 4 dbs representing the main workloads types in company's Agencies
get run these screens using them just before and after a deployment 
monitoring performance of these queries after the deployment using query store


-- Select statement with a hint to use legacy cardinality estimation
SELECT *
FROM YourTable
OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION'));
		




