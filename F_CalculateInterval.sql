

create FUNCTION F_CalculateInterval(@CurrentDate datetime, @PastDate datetime, @interval char(5))
RETURNS int
AS
BEGIN
    --4/23/2021 - interval on date precision whether day, month or year
    DECLARE @ret INT
    SET @ret = 0

    IF @interval = 'year'
	  SET @ret =	( SELECT DATEDIFF(year, @PastDate, @CurrentDate) - 
						  CASE WHEN DATEADD(year, DATEDIFF(year, @PastDate, @CurrentDate), @PastDate) > @CurrentDate THEN 1 ELSE 0 END)
    IF @interval = 'day'
	  SET @ret =	( SELECT DATEDIFF(day, @PastDate, @CurrentDate) - 
						  CASE WHEN DATEADD(day, DATEDIFF(day, @PastDate, @CurrentDate), @PastDate) > @CurrentDate THEN 1 ELSE 0 END)
    IF @interval = 'month'
	  SET @ret =	( SELECT DATEDIFF(month, @PastDate, @CurrentDate) - 
						  CASE WHEN DATEADD(month, DATEDIFF(month, @PastDate, @CurrentDate), @PastDate) > @CurrentDate THEN 1 ELSE 0 END)
    RETURN @ret;
END

go

--example

--day
select [APPS].[F_CalculateInterval]('2021-04-23 12:10:01.000','2021-04-22 12:10:01.000','day')
select [APPS].[F_CalculateInterval]('2021-04-23 12:10:00.000','2021-04-22 12:10:01.000','day')
--year
select [APPS].[F_CalculateInterval]('2021-03-26 07:30:00.000','1984-03-26 07:30:00.000','year')
select [APPS].[F_CalculateInterval]('2021-03-26 07:29:00.000','1984-03-26 07:30:00.000','year')
--month
select [APPS].[F_CalculateInterval]('2021-03-25 23:59:00.000','1984-03-26 07:30:00.000','month')


