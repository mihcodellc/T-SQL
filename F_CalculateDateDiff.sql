CREATE FUNCTION [APPS].F_CalculateDateDiff(@CurrentDate datetime, @PastDate datetime) RETURNS int
AS
BEGIN
	--Last Changed -- Date: 2/2/2021 -- By: Monktar Bello - Initial version
	RETURN (SELECT DateDiff(year,@PastDate,@CurrentDate) - 
				CASE 
				WHEN DateAdd(year, DateDiff(year,@PastDate,@CurrentDate), @PastDate) > @CurrentDate THEN 1 
				ELSE 0 END
			)
END
