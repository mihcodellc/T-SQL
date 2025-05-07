https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-rename-transact-sql?view=sql-server-ver16
  
Rename = COLUMN, 
        DATABASE, 
        INDEX, 
        OBJECT ---- objects including constraints (CHECK, FOREIGN KEY, PRIMARY/UNIQUE KEY), user tables, columns, stored procedures, inline table-valued functions, table-valued functions, and rules
        STATISTICS, 
        USERDATATYPE
  
/****** rename table ******/

EXEC sp_rename 'MySchema.MyTable', 'MyTable_OLD';

/****** rename table column ******/
EXEC sp_rename 'dbo.MyTable.MyCOlumn', 'NewNameForMycolumn', 'COLUMN'; --


-- Rename a foreign key constraint.
EXEC sp_rename @objname = 'HumanResources.FK_Employee_Person_BusinessEntityID', 
               @newname = 'FK_EmployeeID',
               @objtype =  'OBJECT'; 

/****** rename indexes ******/
EXEC sp_rename N'dbo.MyTable_OLD.IX_MyTable_clid_statusid_processruleid_slid_procedurecode', N'IX_MyTable_clid_statusid_processruleid_slid_procedurecode_old', N'INDEX';   
GO

  -- Rename the primary key constraint.
EXEC sp_rename 'MySchema.PK_Employee_BusinessEntityID', 'PK_EmployeeID','OBJECT';
GO

-- Rename a check constraint.
EXEC sp_rename 'HumanResources.CK_Employee_BirthDate', 'CK_BirthDate', 'OBJECT';
GO


-- Return the current Primary Key, Foreign Key and Check constraints for the Employee table.
SELECT name, SCHEMA_NAME(schema_id) AS schema_name, type_desc
FROM sys.objects
WHERE parent_object_id = (OBJECT_ID('HumanResources.Employee'))
AND type IN ('C','F', 'PK');
GO

  
/****** create new table ******/

GO
/****** Object:  Index **/

GO
/****** DROP AND RECREATE DEFAULT CONSTRAINT ******/

ALTER TABLE [dbo].[MyTable_OLD] DROP  CONSTRAINT [lbsldh_timestamp]  --DEFAULT (getdate()) FOR [timestamp]

ALTER TABLE [dbo].[MyTable] ADD  CONSTRAINT [lbsldh_timestamp]  DEFAULT (getdate()) FOR [timestamp]


/****** add DEFAULT CONSTRAINT FOR dba ******/
ALTER TABLE [dbo].[MyTable] ADD DateInsertDBA datetime2 not null -- DEFAULT (getdate()) FOR [timestamp]

ALTER TABLE [dbo].[MyTable] ADD  CONSTRAINT [df_DateInsert]  DEFAULT (getdate()) FOR DateInsert

GO


