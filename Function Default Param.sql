--@myName varchar(25) NULL = '' doesn't make it optional for function when it gets call 
--SP makes it optional
--look the call requiring "default" to make optional
-- A default value for the parameter. If a default value is defined, 
-- the function can be executed without specifying a value for that parameter.

CREATE or alter FUNCTION dbo.ISOweek (@DATE DATETIME, @myName varchar(25) NULL = '')
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN
    DECLARE @ISOweek INT;

    SET @ISOweek = DATEPART(wk, @DATE) + 1 -
        DATEPART(wk, CAST(DATEPART(yy, @DATE) AS CHAR(4)) + '0104');

    --Special cases: Jan 1-3 may belong to the previous year
    IF (@ISOweek = 0)
        SET @ISOweek = dbo.ISOweek(CAST(DATEPART(yy, @DATE) - 1 AS CHAR(4))
           + '12' + CAST(24 + DATEPART(DAY, @DATE) AS CHAR(2)), default) + 1;

    --Special case: Dec 29-31 may belong to the next year
    IF ((DATEPART(mm, @DATE) = 12)
        AND ((DATEPART(dd, @DATE) - DATEPART(dw, @DATE)) >= 28))
    SET @ISOweek = 1;

    RETURN (@ISOweek);
END;
GO

--call
SET DATEFIRST 1;

--paramter name can't be used
SELECT dbo.ISOweek(CONVERT(DATETIME, '12/26/2004', 101), default) AS 'ISO Week';
