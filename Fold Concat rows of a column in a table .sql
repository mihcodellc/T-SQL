-- by degree of certainty 
--create table names(id varchar(1))

--insert into names(id)
--values (1),(2),(3),(5),(7),(8),(9)

--- sql 17+
SELECT STRING_AGG (CONVERT(NVARCHAR(max),id), CHAR(13)) AS csv 
FROM names;

-- XML PATH 1
SELECT RTRIM(id) as ids
  FROM (
                SELECT isnull(id,'') + ', '  
                    FROM names
                    FOR XML PATH('')
             ) as  a (id)


-- for below https://stackoverflow.com/questions/4739519/concatenating-multiple-rows-fields-into-one-column-in-t-sql
-- another way 2
DECLARE @listStr VARCHAR(MAX)

SET @listStr = NULL

SELECT @listStr = COALESCE(@listStr+', ' ,'') + id
FROM names

select @listStr

-- another way 3
declare @result varchar(max) set @result = ''
select @result = @result + ','+id from names
select @result

