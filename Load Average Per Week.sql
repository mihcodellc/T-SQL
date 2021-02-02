		/*-- Last Changed: -- Date: 2/2/2021 -- By: Monktar Bello - Initial version*/

SELECT ModuleName,BeginDateOfWeek,EndDateOfWeek, 
	   min(loadtime)mi,
	   max(loadtime)ma,
	   avg(loadtime)av, 
	   count(loadtime)cn 
FROM (
SELECT ModuleName, 
	   CONVERT(DATETIME,CONVERT(CHAR(10),CONVERT(datetime,dateadd(day,7-DATEPART(weekday,AccessDate), AccessDate)),101)) EndDateOfWeek,
	   CONVERT(DATETIME,CONVERT(CHAR(10),CONVERT(datetime,dateadd(day,-(DATEPART(weekday,AccessDate)-1), AccessDate)),101)) BeginDateOfWeek,
	   loadtime
FROM a_schema.a_table
where loadtime > 0
) A 
GROUP BY ModuleName,BeginDateOfWeek,EndDateOfWeek
ORDER BY ModuleName,BeginDateOfWeek DESC
