
CREATE TABLE [dbo].[FactProductInventory_ApexSQL](
	[ProductKey] [int] NOT NULL,
	[DateKey] [int] NOT NULL,
	[MovementDate] [date] NOT NULL,
	[UnitCost] [money] NOT NULL,
	[UnitsIn] [int] NOT NULL,
	[UnitsOut] [int] NOT NULL,
	[UnitsBalance] [int] NOT NULL,
 CONSTRAINT [PK_FactProductInventory_ApexSQL] PRIMARY KEY CLUSTERED 
(
	[ProductKey] ASC,
	[DateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[FactProductInventory]  WITH CHECK ADD  CONSTRAINT [FK_FactProductInventory_DimDate] FOREIGN KEY([DateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
GO

ALTER TABLE [dbo].[FactProductInventory] CHECK CONSTRAINT [FK_FactProductInventory_DimDate]
GO

ALTER TABLE [dbo].[FactProductInventory]  WITH CHECK ADD  CONSTRAINT [FK_FactProductInventory_DimProduct] FOREIGN KEY([ProductKey])
REFERENCES [dbo].[DimProduct] ([ProductKey])
GO

ALTER TABLE [dbo].[FactProductInventory] CHECK CONSTRAINT [FK_FactProductInventory_DimProduct]
GO


create nonclustered columnstore index [CIX_FactProductInventory_ApexSQL]
on dbo.FactProductInventory_ApexSQL
(
ProductKey,
UnitCost,
UnitsIn,
UnitsOut,
UnitsBalance
) WITH (DROP_EXISTING = OFF) ON [PRIMARY]
GO

SET STATISTICS IO ON

SELECT factProInv.ProductKey
	   ,sum(factProInv.UnitCost) unicost
	   ,sum(factProInv.UnitsIn) UnitsIn
	   ,sum(factProInv.UnitsOut) UnitsOut
	   ,sum(factProInv.UnitsBalance) UnitsBalance
FROM dbo.FactProductInventory factProInv
GROUP BY factProInv.ProductKey
ORDER BY factProInv.ProductKey