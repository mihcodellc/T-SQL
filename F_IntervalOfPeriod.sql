USE [iThinkHealth]
GO

/****** Object:  UserDefinedFunction [APPS].[F_IntervalOfPeriod]    Script Date: 12/17/2020 12:03:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [APPS].[F_IntervalOfPeriod] (@Period smallint, @currentDate datetime)
RETURNS @table TABLE (val1 datetime, val2 datetime)
AS
BEGIN
	-- Last update: 12/18/2020 - Monktar Bello:  Initial version 
	--run example : SELECT * FROM apps.F_IntervalOfPeriod(23,'20200314')

	declare @n tinyint
	set @n=0

	IF @Period = 11 --'Last Month'
	insert into @table 
	select dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate)) 'val1'  ,
		dateadd(d,-1,dateadd(m,1, dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate)))) 'val2'

	IF @Period = 12 --'Month-To-Date'
	insert into @table 
	select dateadd(d,-datepart(d, @currentDate)+1,@currentDate) 'val1' , 
			@currentDate 'val2'

	IF @Period = 13 --'Year-To-Date'
	insert into @table 
    select dateadd(d,-datepart(d, dateadd(m,-datepart(m, @currentDate)+1,@currentDate))+1,dateadd(m,-datepart(m, @currentDate)+1,@currentDate)) 'val1', 
			@currentDate 'val2'

	IF @Period = 14 --'This Week'
	insert into @table 
	select dateadd(d,-(datepart(w,@currentDate))+1,@currentDate) 'val1', 
			dateadd(d,7-(datepart(w,@currentDate)),@currentDate) 'val2'
 
	IF @Period = 15 --'Week-To-Date'
	insert into @table 
	select dateadd(d,-(datepart(w,@currentDate))+1,@currentDate) 'val1', @currentDate 'val2' 

	IF @Period = 16 --'This Month'
	insert into @table 
	select dateadd(d,-datepart(d, @currentDate)+1,@currentDate) 'val1', 
		dateadd(d,-1,dateadd(m,1,dateadd(d,-datepart(d, @currentDate)+1,@currentDate)))	'val2'

	IF @Period = 17 --'Last Week'
	insert into @table 
	select dateadd(d,-7,dateadd(d,-(datepart(w,@currentDate))+1,@currentDate)) 'val1', 
			dateadd(d,-1,dateadd(d,-(datepart(w,@currentDate))+1,@currentDate)) 'val2' 

	IF @Period = 18 --'Last-Week-To-Date'
	insert into @table 
    select dateadd(d,-7,dateadd(d,-(datepart(w,@currentDate))+1,@currentDate)) 'val1', 
	@currentDate 'val2'

	IF @Period = 19 --'Last-Month-To-Date'
	insert into @table 
    select dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate)) 'val1' ,
    @currentDate 'val2'
 
	IF @Period = 20 --'Yesterday'
	insert into @table 
	select cast(convert(char(10), dateadd(d,-1,@currentDate), 101) + ' 00:00:00' as datetime) 'val1', 
	cast(convert(char(10), dateadd(d,-1,@currentDate), 101) + ' 23:59:59' as datetime) 'val2'

	IF @Period = 21 --'Last Pay Period'
	insert into @table 
	 select 
		cast(convert(char(10),
			case when datepart(w,@currentDate) = 5 then @currentDate
			when datepart(w,@currentDate) > 5 then dateadd(d, -(datepart(w,@currentDate) -5), @currentDate)
			else dateadd(d,-7,dateadd(d, -(datepart(w,@currentDate) -5), @currentDate))	end
		, 101) + ' 00:00:00' as datetime) 'val1',
		cast(convert(char(10),
			case when datepart(w,@currentDate) = 5 then @currentDate
			when datepart(w,@currentDate) > 5 then dateadd(d, -(datepart(w,@currentDate) -5), @currentDate)
			else dateadd(d,-7,dateadd(d, -(datepart(w,@currentDate) -5), @currentDate))	end
		, 101) + ' 23:59:59' as datetime) 'val2'

	IF @Period = 22 --'Last Two Pay Periods'
	insert into @table 
	select 
	dateadd(d,-7,
	case when datepart(w,@currentDate) = 5 then @currentDate
				when datepart(w,@currentDate) > 5 then dateadd(d, -(datepart(w,@currentDate) -5), @currentDate)
				else dateadd(d,-7,dateadd(d, -(datepart(w,@currentDate) -5), @currentDate))
				end) 'val1',
	case when datepart(w,@currentDate) = 5 then @currentDate
				when datepart(w,@currentDate) > 5 then dateadd(d, -(datepart(w,@currentDate) -5), @currentDate)
				else dateadd(d,-7,dateadd(d, -(datepart(w,@currentDate) -5), @currentDate))
				end 'val2'


	IF @Period = 23 --'Last Billing Period'
	insert into @table 
	select 
	cast(convert(char(10), 
		case when datepart(w,@currentDate) = 4 then @currentDate -- 4 for wednesday
				when datepart(w,@currentDate) > 4 then dateadd(d, -(datepart(w,@currentDate) -4), @currentDate)
				else dateadd(d,-7,dateadd(d, -(datepart(w,@currentDate) -4), @currentDate))
				end
	, 101) + ' 00:00:00' as datetime) 'val1',
	cast(convert(char(10), 
		case when datepart(w,@currentDate) = 4 then @currentDate -- 4 for wednesday
				when datepart(w,@currentDate) > 4 then dateadd(d, -(datepart(w,@currentDate) -4), @currentDate)
				else dateadd(d,-7,dateadd(d, -(datepart(w,@currentDate) -4), @currentDate))
				end
	, 101) + ' 23:59:59' as datetime) 'val2'

	IF @Period = 24 --'Last Two Billing Periods'
	insert into @table 
	select 
	dateadd(d,-7,
	case when datepart(w,@currentDate) = 4 then @currentDate -- 4 for wednesday
				when datepart(w,@currentDate) > 4 then dateadd(d, -(datepart(w,@currentDate) -4), @currentDate)
				else dateadd(d,-7,dateadd(d, -(datepart(w,@currentDate) -4), @currentDate))
				end) 'val1',
	case when datepart(w,@currentDate) = 4 then @currentDate -- 4 for wednesday
				when datepart(w,@currentDate) > 4 then dateadd(d, -(datepart(w,@currentDate) -4), @currentDate)
				else dateadd(d,-7,dateadd(d, -(datepart(w,@currentDate) -4), @currentDate))
				end 'val2'

	IF @Period = 25 --'Bi-Weekly' previous two weeks; not included current
	insert into @table 
	select dateadd(d,-14,dateadd(d,-(datepart(w,@currentDate))+1,@currentDate)) 'val1', 
			dateadd(d,-1,dateadd(d,-(datepart(w,@currentDate))+1,@currentDate)) 'val2' 

	IF @Period = 26 --'Bi-Monthly'
	insert into @table 
	select dateadd(d,-datepart(d, dateadd(m,-2, @currentDate))+1,dateadd(m,-2, @currentDate)) 'val1'  ,
			dateadd(d,-1,dateadd(m,1, dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate)))) 'val2'


	IF @Period = 27 --'Only Equal To'
	insert into @table 
	select cast(convert(char(10), @currentDate, 101) + ' 00:00:00' as datetime) , 
	cast(convert(char(10), @currentDate, 101) + ' 23:59:59' as datetime)

	IF @Period = 28 --'First Half of this Month'
	insert into @table 
	select dateadd(d,-datepart(d, @currentDate)+1,@currentDate) 'val1', 
	dateadd(d,
		CEILING(CONVERT(float,datediff(d,
			dateadd(d,-datepart(d, @currentDate)+1,@currentDate),
			dateadd(d,-1,dateadd(m,1,dateadd(d,-datepart(d, @currentDate)+1,@currentDate)))))/2)-1 ,
			dateadd(d,-datepart(d, @currentDate)+1,@currentDate)) 'val2'

	IF @Period = 29 --'Last Half of this Month'
	insert into @table 
	select 
	dateadd(d,
		CEILING(CONVERT(float,datediff(d,
		dateadd(d,-datepart(d, @currentDate)+1,@currentDate),
		dateadd(d,-1,dateadd(m,1,dateadd(d,-datepart(d, @currentDate)+1,@currentDate)))))/2) ,
		dateadd(d,-datepart(d, @currentDate)+1,@currentDate)) 'val1',
	dateadd(d,-1,dateadd(m,1,dateadd(d,-datepart(d, @currentDate)+1,@currentDate))) 'val2'

	IF @Period = 30 --'First Half of last Month'
	insert into @table 
	select dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate)) 'val1' ,
	dateadd(d,
		CEILING(CONVERT(float,datediff(d,dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate)), dateadd(d,-1,dateadd(m,1, dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate))))))/2)-1,
		dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate))) 'val2'

	IF @Period = 31 --'Last Half of last Month'
	insert into @table 
	select 
	dateadd(d,
		CEILING(CONVERT(float,datediff(d,dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate)), dateadd(d,-1,dateadd(m,1, dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate))))))/2),
		dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate))) 'val1',
	dateadd(d,-1,dateadd(m,1, dateadd(d,-datepart(d, dateadd(m,-1, @currentDate))+1,dateadd(m,-1, @currentDate)))) 'val2'

	--make sure to return the begin at 00:00:00 ant the end at 23:59
	UPDATE @table SET val1 = cast(convert(char(10), val1, 101) + ' 00:00:00' as datetime),
					  val2 = cast(convert(char(10), val2, 101) + ' 23:59:59' as datetime)

	RETURN
END
GO

