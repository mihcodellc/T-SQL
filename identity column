begin tran
--SET IDENTITY_INSERT mytable ON
INSERT INTO mytable (
--
)
--SET IDENTITY_INSERT mytable OFF
rollback tran

--check the last id used
SELECT IDENT_CURRENT('mytable') AS LastIdentityValue;
--DBCC CHECKIDENT ('mytable', RESEED, 38);
