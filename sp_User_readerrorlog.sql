use master
go

create or alter proc sp_User_readerrorlog(
	@p1		int = 0,
	@p2		int = NULL,
	@p3		nvarchar(4000) = NULL,
	@p4		nvarchar(4000) = NULL,
	@date1		datetime = NULL,
	@date2 datetime = NULL)
as
begin

	IF (not is_srvrolemember(N'securityadmin') = 1) AND (not HAS_PERMS_BY_NAME(null, null, 'VIEW SERVER STATE') = 1)
	begin
		raiserror(27219,-1,-1)
		return (1)
	end
	
	if (@p2 is NULL)
		exec sys.xp_readerrorlog @p1
	else
		exec sys.xp_readerrorlog @p1,@p2,@p3,@p4,@date1,@date2
end

go
EXEC sys.sp_MS_marksystemobject 'sp_User_readerrorlog';
GO


