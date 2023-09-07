 error: CREATE INDEX failed because the following SET options have incorrect settings: 'QUOTED_IDENTIFIER'. 

Fix: add "SET QUOTED_IDENTIFIER ON;" before run the query

Quoted identifier settings are stored against each stored procedure, and sp_MSforeachtable has it defined as OFF. However, you can work around this - by setting it to ON before it executes the re-index:

MedRx status:  Empty tables

test rebuilt of all PK : succeeded
