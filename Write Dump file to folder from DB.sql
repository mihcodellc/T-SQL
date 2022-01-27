CREATE TABLE Pictures (
   pictureName NVARCHAR(40) PRIMARY KEY NOT NULL
   , picFileName NVARCHAR (100)
   , PictureData VARBINARY (max)
   )
GO

--https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-oacreate-transact-sql?view=sql-server-ver15
-- https://www.mssqltips.com/sqlservertip/4963/simple-image-import-and-export-using-tsql-for-sql-server/

-- Requires membership in the sysadmin fixed server role OR 
-- execute permission directly on this Stored Procedure. 
-- Ole Automation Procedures configuration must be enabled to use ANY system procedure related to OLE Automation.


-- activate advanced options to use sp_OACreate ....
EXEC sp_configure 'show advanced options', 1; 
GO 
RECONFIGURE; 
GO 
EXEC sp_configure 'Ole Automation Procedures', 1; 
GO 
RECONFIGURE; 
GO


---- deactivate advanced options to use sp_OACreate ....
--EXEC sp_configure 'Ole Automation Procedures', 0; 
--GO 
--RECONFIGURE; 
--EXECUTE sp_configure 'show advanced options', 0;  
--GO  
--RECONFIGURE;  
--GO



CREATE PROCEDURE dbo.usp_ImportImage (
     @PicName NVARCHAR (100)
   , @ImageFolderPath NVARCHAR (1000)
   , @Filename NVARCHAR (1000)
   )
AS
BEGIN
   DECLARE @Path2OutFile NVARCHAR (2000);
   DECLARE @tsql NVARCHAR (2000);
   SET NOCOUNT ON
   SET @Path2OutFile = CONCAT (
         @ImageFolderPath
         ,'\'
         , @Filename
         );
   SET @tsql = 'insert into Pictures (pictureName, picFileName, PictureData) ' +
               ' SELECT ' + '''' + @PicName + '''' + ',' + '''' + @Filename + '''' + ', * ' + 
               'FROM Openrowset( Bulk ' + '''' + @Path2OutFile + '''' + ', Single_Blob) as img'
   EXEC (@tsql)
   SET NOCOUNT OFF
END
GO


alter PROCEDURE ONSInternal.usp_ExportImage (
   @ImageFolderPath NVARCHAR(1000)
   )
AS
BEGIN
   DECLARE @ImageData VARBINARY (max);
   DECLARE @Path2OutFile NVARCHAR (2000), @Filename NVARCHAR(1000);
   DECLARE @Obj INT
 
   SET NOCOUNT ON
 
   SELECT @Filename=FileName,  @ImageData = convert (VARBINARY (max), FileContent, 1)
         FROM ONSInternal.ACPProofOfBenefit
         WHERE ACPProofOfBenefitId = 1

 --SELECT *FROM ONSInternal.ACPProofOfBenefit p

   SET @Path2OutFile = CONCAT (@ImageFolderPath,'\', @Filename);

    BEGIN TRY
     EXEC sp_OACreate 'ADODB.Stream' ,@Obj OUTPUT; -- manage a stream of bytes, blob,file, record
     EXEC sp_OASetProperty @Obj ,'Type',1;
     EXEC sp_OAMethod @Obj,'Open';
     EXEC sp_OAMethod @Obj,'Write', NULL, @ImageData;
     EXEC sp_OAMethod @Obj,'SaveToFile', NULL, @Path2OutFile, 2;
     EXEC sp_OAMethod @Obj,'Close';
     EXEC sp_OADestroy @Obj;
    END TRY
    
 BEGIN CATCH
  EXEC sp_OADestroy @Obj;
 END CATCH
 
   SET NOCOUNT OFF
END
GO


exec dbo.usp_ImportImage 'MyDoc','C:\Backups\back','MyDoc.doc' 
select * from Pictures
truncate table Pictures

exec dbo.usp_ExportImage 'MyDoc','C:\Backups\Destination','MyDoc.doc'




ALTER function ONSInternal.F_dumpfile
    (
    @FileContent VARBINARY (max),
    @FileName nvarchar(200),
    @DestinationFolder nvarchar(1000)
    ) returns int
begin 
	-- Last Changed: Date: 1/27/2022 -- By: Monktar Bello - initial version	
	-- Example Run: -- select onsinternal.f_dumpfile(FileContent, FileName, 'C:\ACP\Destination')

    DECLARE @Path2OutFile nVARCHAR (2000);
    DECLARE @Obj INT;
    DECLARE @OLEResult int;

    select @FileContent = convert (VARBINARY (max), @FileContent, 1)

    SET @Path2OutFile = CONCAT (@DestinationFolder,'\', @Filename);


    EXEC @OLEResult= sp_OACreate 'ADODB.Stream' ,@Obj OUTPUT;
    EXEC @OLEResult = sp_OASetProperty @Obj ,'Type',1;
    EXEC @OLEResult = sp_OAMethod @Obj,'Open';
    EXEC @OLEResult = sp_OAMethod @Obj,'Write', NULL, @FileContent;
    EXEC @OLEResult = sp_OAMethod @Obj,'SaveToFile', NULL, @Path2OutFile, 2;
    EXEC @OLEResult = sp_OAMethod @Obj,'Close';
    EXEC @OLEResult = sp_OADestroy @Obj;

    declare @return int
    if @@error <> 0 or @OLEResult <> 0
	   set @return = -1
    else
	   set @return = 0
    
    return @return
end

