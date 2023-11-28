use MyDB

--check the last id used
SELECT IDENT_CURRENT('schema.mytable') AS LastIdentityValue;

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
