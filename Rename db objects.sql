/****** rename table & PK ******/

EXEC sp_rename 'dbo.MyTable', 'MyTable_OLD';

EXEC sp_rename 'dbo.PK_MyTable', 'PK_MyTable_OLD';


/****** rename indexes ******/
EXEC sp_rename N'dbo.MyTable_OLD.IX_MyTable_clid_statusid_processruleid_slid_procedurecode', N'IX_MyTable_clid_statusid_processruleid_slid_procedurecode_old', N'INDEX';   
GO

EXEC sp_rename N'dbo.MyTable_OLD.ix_MyTable_lbxid_procedurecode_statusid_20230215', N'ix_MyTable_lbxid_procedurecode_statusid_20230215_old', N'INDEX';   
GO

EXEC sp_rename N'dbo.MyTable_OLD.IX_MyTable_lbxid_slhisid_02152023', N'IX_MyTable_lbxid_slhisid_02152023_old', N'INDEX';   
GO

EXEC sp_rename N'dbo.MyTable_OLD.IX_MyTable_slid_processruleid', N'IX_MyTable_slid_processruleid_old', N'INDEX';   
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


