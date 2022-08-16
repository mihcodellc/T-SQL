-- STEPS: RESOURCE POOL > WORKLOAD > RECONFIGURE RG > CLASSIFIER FUNCTION CF (return workload based on current user) >
--				> REGISTER CF TO RG
-- CREATE RESOURCE POOL
--1
CREATE RESOURCE POOL [RPool_Bello] WITH(
min_cpu_percent=50, 
		max_cpu_percent=100, 
		min_memory_percent=50, 
		max_memory_percent=100, 
		AFFINITY SCHEDULER = AUTO
)
GO
--2
CREATE RESOURCE POOL SSUsers WITH (
MAX_CPU_PERCENT = 2, MAX_MEMORY_PERCENT = 2
);
go

-- CREATE WORKLOAD 
--1
CREATE WORKLOAD GROUP [ServiceGroup] 
USING [RPool_Bello]
GO
--2
CREATE WORKLOAD GROUP WG_SSUsers
USING SSUsers;
go

-- RECONFIGURE
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO


 
SELECT * FROM sys.resource_governor_resource_pools
 
USE master;
GO

-- CREATE CLASSIFIER FUNCTION 
CREATE FUNCTION Class_funct() RETURNS SYSNAME WITH SCHEMABINDING
AS
BEGIN
  DECLARE @workload_group sysname;
  SET @workload_group = N'DEFAULT'
  
  IF ( SUSER_NAME() = N'mbello')
      SET @workload_group = N'WG_SSUsers';
  --IF ( SUSER_SNAME() = 'SQLShackDemoUser')
  --    SET @workload_group = 'ServiceGroup';
     
  RETURN @workload_group;
END;

GO

-- REGISTER CLASSIFIER FUNCTION TO RESOURCE GOVERNOR
USE master
GO
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.Class_funct);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;


SELECT * FROM sys.resource_governor_configuration
 
 USE master
GO
SELECT ConSess.session_id, ConSess.login_name,  WorLoGroName.name
  FROM sys.dm_exec_sessions AS ConSess
  JOIN sys.dm_resource_governor_workload_groups AS WorLoGroName
      ON ConSess.group_id = WorLoGroName.group_id
  WHERE session_id > 60;