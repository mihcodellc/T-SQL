CREATE RESOURCE POOL [RPool_Bello] WITH(
min_cpu_percent=50, 
		max_cpu_percent=100, 
		min_memory_percent=50, 
		max_memory_percent=100, 
		AFFINITY SCHEDULER = AUTO
)
 
GO
 
CREATE WORKLOAD GROUP [ServiceGroup] 
USING [RPool_Bello]
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO


 
SELECT * FROM sys.resource_governor_resource_pools
 
USE master;
GO
 
CREATE FUNCTION Class_funct() RETURNS SYSNAME WITH SCHEMABINDING
AS
BEGIN
  DECLARE @workload_group sysname;
 
  IF ( SUSER_SNAME() = 'mbello')
      SET @workload_group = 'UserGroup';
  --IF ( SUSER_SNAME() = 'SQLShackDemoUser')
  --    SET @workload_group = 'ServiceGroup';
     
  RETURN @workload_group;
END;



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