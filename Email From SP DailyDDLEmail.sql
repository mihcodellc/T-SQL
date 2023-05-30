
create PROCEDURE [dbo].[DailyDDLEmail]

AS

SET NOCOUNT ON;
DECLARE @Date DATE = GETDATE() - 1;
DECLARE @Results TABLE
    (
      idx INT IDENTITY(1, 1) ,
      DBName VARCHAR(128) ,
      Cmd NVARCHAR(128) ,
      HostName NVARCHAR(128) ,
	 object_type NVARCHAR(128),
      ObjectName NVARCHAR(128) ,
      LoginName VARCHAR(50),
	 time_stamp datetime, num int
    ); 

-- create a temp table for DDL Events captured
IF OBJECT_ID('tempdb..#temp_event') IS NOT NULL
	DROP TABLE #temp_event

CREATE TABLE #temp_event (
	time_stamp DATETIME
	,dbId INT
	,dbname NVARCHAR(128)
	,object_type NVARCHAR(128)
	,object_id INT
	,object_name NVARCHAR(128)
	,session_id INT
	,server_principal_name NVARCHAR(128)
	,client_hostname NVARCHAR(128)
	,client_app_name NVARCHAR(128)
	,sql_text NVARCHAR(200)
	,ddl_phase NVARCHAR(30)
	)

DECLARE @today DATETIME,@db INT;

SELECT @today = convert(DATETIME, convert(CHAR(10), GETDATE(), 110), 110)


--delete old than one month
DELETE [dbo].[RMSDDLTracker]
WHERE [InsertedOn] < DATEADD(MM, -1, @today)


--insert the DDL events committed
INSERT INTO @Results
    SELECT DISTINCT
            [DBName] ,
            SUBSTRING([Command],1,127),
            [WorkStation] ,
            [Object],
		  [ObjectType],
            [Login],
            [Captured], ROW_NUMBER() OVER (ORDER BY [Captured] DESC) as num 
    FROM [dbo].[RMSDDLTracker]
    WHERE Captured > DATEADD(ww, -1, @today) and Captured < @today
    ORDER BY num


DECLARE @idx INT ,
    --@ServerName VARCHAR(25) ,
    @DBName VARCHAR(25) ,
    @Cmd NVARCHAR(128) ,
    @objectType NVARCHAR(128),
    @hostname VARCHAR(100) ,
    @ObjectName VARCHAR(128) ,
    @Who VARCHAR(100) ,
    @Subject VARCHAR(250) ,
    @Body VARCHAR(MAX),
    @count INT,
    @DDLTableHTML VARCHAR(MAX),
    @captured varchar(50);

--SET @Subject = 'DDL Events Logged for ' + CONVERT(VARCHAR(10), @Date, 110);

SET @DDLTableHTML = '<body><b>DDL changes which ocurred in the past 7 days</b><table cellspacing=0><tr bgcolor=#B8DBFF>
								  <td>Database</td><td>Command</td><td>Object Type</td><td>Object Name</td><td>DB User</td><td>Host Name</td><td>Occured on</td></tr>'

--SET @Body = '<div style="font-size:12px;font-family:Verdana">
--			<strong>DDL changes which ocurred in the past 24 hours</strong>
--			<div style="height:20px;background: #fff url(aa010307.gif) no-repeat scroll center;">
--			<hr style="display:none;" /></div></div>';

DECLARE @ID INT
DECLARE @MAX INT
DECLARE @Row_Color VARCHAR(10)
DECLARE @Email_Body_Title VARCHAR(250);
DECLARE @Email_Body VARCHAR(MAX);
DECLARE @HTML_Header VARCHAR(150);
DECLARE @HTML_Tail VARCHAR(20);
DECLARE @Email_Subject VARCHAR(75);
DECLARE @ServerName VARCHAR(25);

SELECT @MAX = MAX(num) FROM @Results

SET @ID=1

WHILE @ID <= @MAX

	BEGIN

		SELECT @DBName = DBName 
		, @Cmd = Cmd 
		, @hostname = HostName 
		, @Who = LoginName
		, @ObjectName = ObjectName
		,@objectType = object_type
		,@captured = convert(varchar(50),time_stamp,100)
		FROM @Results WHERE @ID = idx

		IF @ID % 2 = 0
			BEGIN
				SET @Row_Color = 'BDBDC2'
			END
		ELSE
			SET @Row_Color = 'White'

	
	
		SET @DDLTableHTML = @DDLTableHTML + '

		<tr bgcolor='+@Row_Color+'>
		    <td>'+@DBName+'</td>
		    <td>'+@Cmd+'</td>
		    <td>'+@ObjectName+'</td>
		    <td>'+@objectType+'</td>
		    <td>'+@Who+'</td>
		    <td>'+@hostname+'</td>
		    <td>'+@captured+'</td>
		</tr>'

  		SET @ID = @ID + 1
	
	END

SET @DDLTableHTML = @DDLTableHTML + '</table><br><br>'

SET @ServerName = CAST((SELECT SERVERPROPERTY('MachineName') AS [ServerName]) AS VARCHAR(25))

SET @HTML_Header = '<html><head>' + '<style>'
	+ 'td {border: solid black 1px;padding-left:3px;padding-right:3px;padding-top:2px;padding-bottom:2px;font-size:10pt;} '
	+ '</style>' + '</head>';
	
SET @HTML_Tail = '</body></html>';

SET @Email_Body_Title = '<body><center><h1>' + @ServerName
	+ ' DDL Tracking Report</h1></center></body>';

SET @Email_Subject = @ServerName + ' DDL Events Logged from ' + CONVERT(VARCHAR(10), DATEADD(ww, -1, @today), 110) + ' to ' + CONVERT(VARCHAR(10),@Date, 110)

SET @Email_Body = @HTML_Header + @Email_Body_Title + 
	+ '<br><br>' + @DDLTableHTML + @HTML_Tail;

EXEC msdb.dbo.sp_send_dbmail 
	@body = @Email_Body
    ,@body_format = 'HTML'
    ,@profile_name = N'DataServicesProfile'
    ,@recipients = N'db_maintenance@mitiriitshere.com'
    ,@Subject = @Email_Subject
	--,@importance = 'High'



