-- https://www.red-gate.com/simple-talk/blogs/how-can-sql-server-developers-get-started-with-postgre-sql/#:~:text=HOW%20CAN%20SQL%20SERVER%20DEVELOPERS%20GET%20STARTED%20WITH,JOIN%20m%20...%20%2014%20more%20rows%20
--tsql
set showplan_xml on
go
set noexec on
go 
select * from TABLE

--pgsql
EXPLAIN select * from TABLE


--closest tsql
select datediff(mm,'20150101', '20210401')
select datediff(dd,'20150101', '20210401')	
select datediff(hh,'20150101', '20210401')
select datediff(MINUTE,'20150101', '20210401')

select datepart(yy,getdate())
select datepart(SECOND,getdate())

--pgsql
SET intervalstyle = 'postgres';
SELECT
	INTERVAL '6 years 5 months 4 days 3 hours 2 minutes 1 second';

SELECT EXTRACT (MINUTE FROM INTERVAL '5 hours 21 minutes');
select age(now(),'2022-04-27 12:11:50.029451-05')
SELECT current_date, AGE (timestamp '2001-10-10');-- age and current date
SELECT AGE (timestamp '2001-01-01', timestamp '2020-01-01'); -- 19 years