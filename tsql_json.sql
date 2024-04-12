declare @compatibility_level int
select @compatibility_level = compatibility_level from sys.databases where name = 'testbello'

select @compatibility_level

if (@compatibility_level >= 130 and @compatibility_level is not null)
begin

DECLARE @json NVARCHAR(MAX)
--notice the '[' then '{}' to  put together the many records
SET @json = '[
{ "id": 1, "name": "John Doe", "email": "johndoe_mail" },
{ "id": 2, "name": "Jane Smith", "email": "janesmith_mail" }
]'

SELECT *
FROM OPENJSON(@json)
WITH (id INT, name VARCHAR(50),email VARCHAR(50)
)

-- https://learn.microsoft.com/en-us/sql/t-sql/functions/json-value-transact-sql?view=sql-server-ver16
-- Validate, Query, and Change JSON Data with Built-in Functions (SQL Server)
-- https://learn.microsoft.com/en-us/sql/relational-databases/json/validate-query-and-change-json-data-with-built-in-functions-sql-server?view=sql-server-ver16#JSONCompare
-- PATH lax or strict for json functions
-- https://learn.microsoft.com/en-us/sql/relational-databases/json/json-path-expressions-sql-server?view=sql-server-ver16
declare @jsoninfo nvarchar(max)
-- notice the object
--    1- "info" with attributs: type, address
--    2- "type" with attributs: type     
set @jsoninfo=N'{  
     "info":{    
       "type":1,  
       "address":{    
         "town":"bristol",  
         "county":"avon",  
         "country":"england"  
       },  
       "tags":["sport", "water polo"]  
    },  
    "type":"basic"  
 }'  

select 
json_value(@jsoninfo,'lax $.info.address.town')  as town,
json_value(@jsoninfo,'strict $.info.type')  as type,
json_value(@jsoninfo,'lax $.info.tags')  as tags,
json_value(@jsoninfo,'lax $.info.tags[0]')  as tags_val_1


end
else
    SELECT 'JSON not supported'
