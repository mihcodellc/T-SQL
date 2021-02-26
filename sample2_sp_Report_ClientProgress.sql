USE [iThinkHealth]
GO
/****** Object:  StoredProcedure [APPS].[sp_Report_ClientProgress]    Script Date: 4/6/2020 11:17:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [APPS].[sp_Report_ClientProgress]
(
	@PatSortingID	smallint = 1,
	@StaffSortingID	smallint = 1,
	@UserID int = 0,
	@WhereClause varchar(5000) = '',
	@StartDate varchar(30),
	@EndDate varchar(30)
)
  
  AS 
 BEGIN
	-- Last Changed: Date: 4/6/2020 -- By: Monktar Bello - put in Responsible MHP, BHRS, CM and FSP	columns
	-- Date: 12/19/2019 -- By: Monktar Bello - put in the order by on #RESULT and replace the * by columns names
	-- Date: 10/25/2019 -- By: Monktar Bello - put in Contrat source, service Count, and Enable the filter on User Credential
	-- Date: 8/14/2019 -- By: Jon Minton - Took out a join to Users that was not needed once I updated the code to search directly on pn.UserID_FK
    -- Date: 8/13/2019 -- By: Jon Minton - Added a clause to the where clause so all patients will show no matter what, then made sure it joined to the progress note table.
    -- Date: 8/6/2019 -- By: Monktar Bello - change the join condition ON apps.BillableUnits after apps.progressnotes - one PA & NoteID make an unique row. The join on UserdDetails' changed too
    --  6/28/2019 -- By: Monktar Bello - Client Progress whether they have billed notes or not on specified period and active at that time

	-- Example Run: -- exec APPS.sp_Report_ClientProgress @WhereClause=N'pn.UserID_FK = 341', @PatSortingID =1 , @StaffSortingID =1, @StartDate='20190101', @EndDate='20191231'
	
	SET NOCOUNT ON
	
	DECLARE @Billed FLOAT, @NonBilled FLOAT,  @WithData SMALLINT, @VeryGood SMALLINT, @Good SMALLINT, @Fair SMALLINT,  @Poor SMALLINT, @VeryPoor SMALLINT, @ActiveClients SMALLINT
	DECLARE @SelectClause nvarchar (max);


	IF (LEN(@WhereClause) > 0)
		SET @WhereClause = 'WHERE (' + RTRIM(@WhereClause) + ')'
		ELSE SET @WhereClause = ''

	-- CLIENT PROGRESS AND HOURS
	SET @SelectClause = 
	'DECLARE @ServiceAuth TABLE (NoteID BIGINT, patientID INT) ' +
	'INSERT INTO @ServiceAuth ' +
	'SELECT NoteID, patientID  FROM apps.progressnotes pn ' +
	'WHERE APPS.F_NotInNonAuthServiceList(SysRVUType, 1) = 1 AND PaymentSource not in (7,9) /*non billable*/ AND status <> 6 /*void*/  ' +
	'	  AND ServiceDate BETWEEN @StartDate AND @EndDate  ' +

	'SELECT pat.PatientID, apps.F_BuildName(pat.firstname,pat.middleint,pat.lastname,'''',@PatSortingID) as PatientName ' +
	', CASE WHEN ppr.Progress=1 THEN ''Very Good'' ' +
	'	  WHEN ppr.Progress=2 THEN ''Good'' ' +
	'	  WHEN ppr.Progress=3 THEN ''Fair'' ' +
	'	  WHEN ppr.Progress=4 THEN ''Poor'' ' +
	'	  WHEN ppr.Progress=5 THEN ''Very Poor'' ELSE ''No Data'' END ''Progress'' ' +
	',ROUND(SUM(ISNULL( CASE WHEN pn.Status = 3 THEN CONVERT(float, ISNULL(apps.F_RVU_Minutes(pn.SysRVUType, bu.Units, 0, paa.PAFormVersion, case when pno.RequestType = 0 then paa.PARequestType else pno.RequestType END, pn.TotalTime),0))/60 END, 0)),2) HourBilled ' + --in billing ie Status = 3 -- CONVERT TO HOUR
	',ROUND(SUM(ISNULL( CASE WHEN pn.Status not in (3,6) THEN CONVERT(float, ISNULL(pn.TotalTime,0))/60 END,0)),2) HourNonBilled ' + -- 3=approved, 6=void -- CONVERT TO HOUR
	', COUNT(DISTINCT pn.CountMe) ActNote, ISNULL(tsc.TotalNote,0) TotalNote ' + 
	'INTO #RESULT ' +
	'FROM apps.PatientInformation pat ' +
	--recent Client progress
	'LEFT JOIN (SELECT ProgressID,UserID_FK, PatientID_FK, Attitude,Progress,ProgCompletion,CompletionDate, ' +
	'			ROW_NUMBER() OVER (PARTITION BY PatientID_FK ORDER BY PeriodTo DESC) RecentPgOrder FROM apps.ClientProgress  ' +
	'			WHERE @StartDate <= PeriodFrom AND PeriodTo <= @EndDate ' +
	'		  ) ppr ON pat.PatientID = ppr.PatientID_FK AND ppr.RecentPgOrder=1 ' +
	'LEFT JOIN apps.PA_main paa on pat.PatientID=paa.PatientID_FK ' + --AND @SearchDate BETWEEN paa.RequestedStartDate AND DATEADD(MONTH, paa.AuthorizationPeriod,paa.RequestedStartDate) ' + -- progress when PA is not expired
	'LEFT JOIN ' +
	 '( ' +
	 '		SELECT DISTINCT pn.NoteID, pn.SysRvuType,pn.TotalTime, pn.PAID, pn.UserID_FK, pn.ServiceDate, pn.Status ' +
	 '			   , a.NoteID CountMe, pn.ContractSource ' +
	 '		FROM apps.ProgressNotes pn ' +
	 '		LEFT JOIN apps.UsersCredentials cr ON cr.UserID= pn.UserID_FK ' +
	 '		LEFT JOIN @ServiceAuth a ON  a.NoteID=pn.NoteID AND a.PatientID = pn.PatientID ' + -- both conditions needed
	 '		' +  @WhereClause + ' ' +
	 ') pn on pn.PAID = paa.PAID and pn.ServiceDate BETWEEN @StartDate AND @EndDate ' + 
	--Total service count
	'LEFT JOIN (SELECT PatientID, COUNT(NoteID) TotalNote FROM @ServiceAuth GROUP BY PatientID) tsc ON tsc.patientID = pat.PatientID ' +
	--hours billed or not
	'LEFT JOIN (Select Min(pno1.ObjID) ObjID, pno1.RequestType, pno1.NoteID_FK, pno1.ObjType from apps.ProgressNoteObjectives pno1 group by pno1.NoteID_FK, pno1.RequestType, pno1.ObjType) pno on pno.NoteID_FK = pn.NoteID ' +
	'LEFT JOIN apps.BillableUnits bu ON bu.PAID_FK = paa.PAID AND bu.noteID_FK=pn.NoteID ' + --here1
	--recent status when active
	'LEFT JOIN ( SELECT PatientID, StatusDate, EndStatusDate, Status, ' +
	'			ROW_NUMBER() OVER(PARTITION BY PatientID ORDER BY EndStatusDate DESC) as RecentStOrder FROM apps.vw_LastPatientStatus ' +
	'		  ) st ON pat.PatientID=st.PatientID  ' +
	' WHERE   st.Status IN (1,3,4,5,8,9,10) ' + -- active patient
	'		AND  st.StatusDate <= @EndDate ' + -- important is the status at the end of the period when looking in vw_LastPatientStatus
	'		AND st.RecentStOrder = 1 ' +
	'GROUP BY pat.PatientID, pat.firstname,pat.middleint,pat.lastname, ppr.Progress, tsc.TotalNote ' +
	'ORDER BY  PatientName, ppr.Progress ' +
	
	'SELECT src.patientID, PatientName, Progress, HourBilled, HourNonBilled, ActNote, TotalNote, ' +
	'isnull(apps.F_BuildName(ud.firstname,ud.middleinitial,ud.lastname,'''',@StaffSortingID), '''') as ResponsibleMHP, ' +
	'isnull(apps.F_BuildName(ud2.firstname,ud2.middleinitial,ud2.lastname,'''',@StaffSortingID), '''') as ResponsibleBHRS, ' +
	'isnull(apps.F_BuildName(ud3.firstname,ud3.middleinitial,ud3.lastname,'''',@StaffSortingID), '''') as ResponsibleCM, ' + 
	'isnull(apps.F_BuildName(ud4.firstname,ud4.middleinitial,ud4.lastname,'''',@StaffSortingID), '''') as ResponsibleFSP ' +
	'FROM #RESULT src ' + 
	'INNER JOIN apps.patientInformation pat ON src.patientID = pat.patientID '+
	'left join apps.UserDetails ud on pat.ResponsibleMHP = ud.UserID ' +
	'left join apps.UserDetails ud2 on pat.ResponsibleBHRS = ud2.UserID ' +
	'left join apps.UserDetails ud3 on pat.ResponsibleCM = ud3.UserID ' +
	'left join apps.UserDetails ud4 on pat.ResponsibleFSP = ud4.UserID ' +
	'ORDER BY  PatientName ' +
	
	-- Totals
	'SELECT @Billed = SUM(HourBilled) , @NonBilled= SUM(HourNonBilled)  FROM #RESULT  ' +

	'SELECT @ActiveClients = ISNULL(COUNT(distinct PatientID),0) FROM #RESULT  ' +
	'SELECT @WithData = ISNULL(COUNT(*),0)  FROM #RESULT WHERE Progress <> ''No Data'' ' +
	'SELECT @VeryGood = ISNULL(COUNT(*),0)  FROM #RESULT WHERE Progress=''Very Good'' ' +
	'SELECT @Good = ISNULL(COUNT(*),0)  FROM #RESULT WHERE Progress=''Good'' ' +
	'SELECT @Fair = ISNULL(COUNT(*),0)  FROM #RESULT WHERE Progress=''Fair'' ' +
	'SELECT @Poor = ISNULL(COUNT(*),0)  FROM #RESULT WHERE Progress=''Poor'' ' +
	'SELECT @VeryPoor = ISNULL(COUNT(*),0)  FROM #RESULT WHERE Progress=''Very Poor'' ' +


	'SELECT @ActiveClients ''ActiveClients'', @Billed ''Billed'', @NonBilled ''NonBilled'', @WithData ''WithData'', @VeryGood ''VeryGood'', @Good ''Good'', @Fair ''Fair'', @Poor ''Poor'', @VeryPoor ''VeryPoor'' ' +

	'IF OBJECT_ID(''tempdb..#RESULT'') IS NOT NULL ' +
	'	DROP TABLE #RESULT ' 

	--SELECT @SelectClause
	EXECUTE sp_executesql @SelectClause, N'@StaffSortingID SMALLINT, @PatSortingID smallint, @Billed FLOAT, @NonBilled FLOAT,  @WithData SMALLINT,@VeryGood SMALLINT, @Good SMALLINT, @Fair SMALLINT,  @Poor SMALLINT, @VeryPoor SMALLINT,  @StartDate varchar(30), @EndDate varchar(30), @ActiveClients SMALLINT '
										,@StaffSortingID=@StaffSortingID,  @PatSortingID=@PatSortingID, @Billed=@Billed, @NonBilled=@NonBilled, @WithData=@WithData,@VeryGood=@VeryGood, @Good=@Good, @Fair=@Fair,  @Poor=@Poor,@VeryPoor=@VeryPoor 
										, @StartDate=@StartDate, @EndDate = @EndDate, @ActiveClients=@ActiveClients
																														--
																														-- 
END
