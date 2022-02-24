create procedure sys.sp_srvrolepermission  
 @srvrolename       sysname = NULL  
AS  
 if @srvrolename is not null  
 begin  
  -- VALIDATE GIVEN NAME  
  if not exists (select * from sys.server_principals  
    where name = @srvrolename and principal_id >= suser_id('sysadmin') and principal_id <= suser_id('bulkadmin'))  
  begin  
   raiserror(15412, -1, -1, @srvrolename)  
   return (1)  
  end  
  
  -- RESULT SET FOR SINGLE SERVER-ROLE  
  select distinct 'ServerRole' = l.name, 'Permission' = p.name collate catalog_default  
   from sys.server_principals l, sys.role_permissions p  
   where l.name = @srvrolename and p.low > 0 and  
      ((p.type = 'SRV' and (p.number = l.principal_id or l.principal_id = suser_id('sysadmin'))) or  
      (p.type = 'DBR' and l.principal_id = suser_id('sysadmin') and not (p.name like N'No %')))  
   order by l.name, p.name collate catalog_default  
 end  
 else  
 begin  
  -- RESULT SET FOR ALL SERVER-ROLES  
  select distinct 'ServerRole' = l.name, 'Permission' = p.name collate catalog_default  
   from sys.server_principals l, sys.role_permissions p  
   where p.low > 0 and  
    ((p.type = 'SRV' and (p.number = l.principal_id or l.principal_id = suser_id('sysadmin'))) or  
      (p.type = 'DBR' and l.principal_id = suser_id('sysadmin') and not (p.name like N'No %')))  
   order by l.name, p.name collate catalog_default  
 end  
  
    return (0) -- sp_srvrolepermission  