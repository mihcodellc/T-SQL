--credit to https://www.bing.com/ck/a?!&&p=e70e27c2fdd939659a1fdc9eede224abd01681ce7c79c1d31cae530e37ffcae9JmltdHM9MTY1Nzg5MzE4NCZpZ3VpZD1hNWEwYjI1Ni02ZjZkLTQxZGItOTI2ZC1kNzJhY2Y0NmZlOTUmaW5zaWQ9NTQzNA&ptn=3&fclid=7249e168-0445-11ed-bf21-dd44c22f8d01&u=a1aHR0cHM6Ly96YXJlei5uZXQvP3A9MzA0MCM6fjp0ZXh0PVNFTEVDVCUyMCUyN0VYRUMlMjBzcF9jb25maWd1cmUlMjAlMjclMjclMjclMjAlMkIlMjBuYW1lJTIwJTJCJTIwJTI3JTI3JTI3JTJDLHRoZSUyMGNvZGUlM0ElMjBFWEVDJTIwc3BfY29uZmlndXJlJTIwJTI3c2hvdyUyMGFkdmFuY2VkJTIwb3B0aW9ucyUyNyUyQyUyMDE&ntb=1

-- date 7/15/2022

-- To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  

--SELECT 'EXEC sp_configure ''' + name + ''', ' + CAST(value AS VARCHAR(100))
--FROM sys.configurations
--ORDER BY name

--PASTE THE RESULTS of above queries HERE

EXEC sp_configure 'show advanced options', 0
GO
RECONFIGURE
GO
