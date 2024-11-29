https://www.mssqltips.com/sqlservertip/8124/calculate-a-moving-average-with-t-sql-windowing-functions/
-- mssqltips.com
SET STATISTICS TIME, IO ON;
SELECT t1.UserId,
       t1.DateRecorded,
       t1.Pounds,
       CASE
           WHEN ROW_NUMBER() OVER (PARTITION BY t1.UserId ORDER BY t1.DateRecorded) > 6 THEN
               AVG(t1.Pounds) OVER (PARTITION BY t1.UserId
                                    ORDER BY t1.DateRecorded
                                    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
                                   )
           ELSE
               NULL
       END AS [7DayMovingAverage]
FROM dbo.BigWeightTracker t1
ORDER BY t1.UserId,
         t1.DateRecorded;
SET STATISTICS TIME, IO OFF;
