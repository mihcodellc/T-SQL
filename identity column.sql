use MyDB

--check the last id used
SELECT IDENT_CURRENT('schema.mytable') AS LastIdentityValue;
--SELECT SCOPE_IDENTITY()
--select IDENT_CURRENT()
--select @@IDENTITY

-- https://learn.microsoft.com/en-us/sql/t-sql/functions/scope-identity-transact-sql?view=sql-server-ver16

IDENT_CURRENT is not limited by scope and session; it is limited to a specified table. 
  IDENT_CURRENT returns the value generated for a specific table in any session and any scope. For more information, see IDENT_CURRENT (Transact-SQL).

SCOPE_IDENTITY and @@IDENTITY return the last identity values that are generated in any table in the current session. 
  However, SCOPE_IDENTITY returns values inserted only within the current scope; @@IDENTITY is not limited to a specific scope.

begin tran
--SET IDENTITY_INSERT schema.mytable ON
INSERT INTO schema.mytable (col1,col2, ...)
SELECT val1, val2, ...
--SET IDENTITY_INSERT mytable OFF
rollback tran

-- check the insertion
SELECT * FROM schema.mytable WHERE Ccol1 in (val1)

--check the last id used
SELECT IDENT_CURRENT('schema.mytable') AS LastIdentityValue;

-- reseeed the table to a value
--DBCC CHECKIDENT ('schema.mytable', RESEED, 38); -- 38 = the last used
