CREATE PROCEDURE APPS.sp_GetYearCarsDomain
	( @SelectYear smallint)
AS
BEGIN

--Last Changed -- Date: -- 7/15/2019 -- By: Monktar BELLO -  on the last PA in quarter, find the previous value of Tx, Compare both for each patient; 
									 -- add them up and divide to determine the average on each quarter; combine with missing quarter; pivot column to row for each domain                                    
 
 --Example Run -- EXEC APPS.sp_GetYearCarsDomain @SelectYear=2012


SET NOCOUNT ON
--DECLARE  @SelectYear smallint 
--SET @SelectYear=2012

;WITH T1 AS ( -- LAG,LEAD solution to find PreviousValue on SQL Server version before 2012 based on the work of Geri Reshef 
	SELECT NoLastDate, PatientID_FK, RequestedStartDate, PAID, PAlevel
	, FMACurrentScore, TMPCurrentScore, SBUCurrentScore, MEPCurrentScore, FAMCurrentScore, INPCurrentScore, RLPCurrentScore, SCLCurrentScore, SCRCurrentScore   
	, ROW_NUMBER() OVER (PARTITION BY PatientID_FK ORDER BY RequestedStartDate) N -- define chronological order of field targeted and which apply to 
	, Kter, itsYear 
	FROM (
			SELECT  
				ROW_NUMBER() OVER (PARTITION BY PatientID_FK, DATEPART(YEAR, tx.RequestedStartDate), DATEPART(QUARTER, tx.RequestedStartDate) ORDER BY tx.RequestedStartDate DESC ) NoLastDate -- No BY PATIENT, YEAR, QUARTER
				,tx.PatientID_FK, tx.RequestedStartDate, txAss.PAID, tx.PAlevel
				--Domains score
				,ISNULL(FMACurrentScore,0) FMACurrentScore
				,ISNULL(TMPCurrentScore,0) TMPCurrentScore 
				,ISNULL(SBUCurrentScore,0) SBUCurrentScore 
				,ISNULL(MEPCurrentScore,0) MEPCurrentScore 
				,ISNULL(FAMCurrentScore,0) FAMCurrentScore 
				,ISNULL(INPCurrentScore,0) INPCurrentScore 
				,ISNULL(RLPCurrentScore,0) RLPCurrentScore 
				,ISNULL(SCLCurrentScore,0) SCLCurrentScore
				,ISNULL(SCRCurrentScore,0) SCRCurrentScore
				, DATEPART(QUARTER, tx.RequestedStartDate) Kter, DATEPART(YEAR, tx.RequestedStartDate) itsYear
			FROM APPS.PA_ClientAssessment txAss
			RIGHT JOIN APPS.PA_Main tx ON  txAss.PAID = tx.PAID
		) Result 
)

--The change between a recent PA on a quarter and its previous not necessarily on same quarter
SELECT NoLastDate, PatientID_FK, RequestedStartDate, PAID, PAlevel
, FMACurrentScore
--, (CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN FMACurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) ELSE MAX(CASE WHEN N%2=1 THEN FMACurrentScore END) OVER (Partition BY PatientID_FK, N/2) END)   NextScoreFMA -- computing  for each patient and its N... numbers
, ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN FMACurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN FMACurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0) FMAPreviousScore
, ISNULL
	( 
		(FMACurrentScore - ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN FMACurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN FMACurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0)), 
		0
	) FMAhowProgress
--
, TMPCurrentScore
, ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN TMPCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN TMPCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0) TMPPreviousScore -- computing  for each patient and its N... numbers
, ISNULL
	( 
		(TMPCurrentScore - (CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN TMPCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN TMPCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END)), 
		0
	) TMPhowProgress
--
, SBUCurrentScore
, ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN SBUCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN SBUCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0) SBUPreviousScore
, ISNULL
	( 
		(SBUCurrentScore - ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN SBUCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN SBUCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0)), 
		0
	) SBUhowProgress
--
, MEPCurrentScore
, ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN MEPCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN MEPCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0) MEPPreviousScore
, ISNULL
	( 
		(MEPCurrentScore - ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN MEPCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN MEPCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0)), 
		0
	) MEPhowProgress
--
, FAMCurrentScore
, ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN FAMCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN FAMCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0) FAMPreviousScore
, ISNULL
	( 
		(FAMCurrentScore - ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN FAMCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN FAMCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0)), 
		0
	) FAMhowProgress
--
, INPCurrentScore
, ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN INPCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN INPCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0) INPPreviousScore
, ISNULL
	( 
		(INPCurrentScore - ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN INPCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN INPCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0)), 
		0
	) INPhowProgress
--
, RLPCurrentScore
, ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN RLPCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN RLPCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0) RLPPreviousScore
, ISNULL
	( 
		(RLPCurrentScore - ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN RLPCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN RLPCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0)), 
		0
	) RLPhowProgress
--
, SCLCurrentScore
, ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN SCLCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN SCLCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0) SCLPreviousScore
, ISNULL
	( 
		(SCLCurrentScore - ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN SCLCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN SCLCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0)), 
		0
	) SCLhowProgress
--
, SCRCurrentScore
, ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN SCRCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN SCRCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0) SCRPreviousScore
, ISNULL
	( 
		(SCRCurrentScore - ISNULL((CASE WHEN N%2=1 THEN MAX(CASE WHEN N%2=0 THEN SCRCurrentScore END) OVER (Partition BY PatientID_FK, N/2) ELSE MAX(CASE WHEN N%2=1 THEN SCRCurrentScore END) OVER (Partition BY PatientID_FK, (N+1)/2) END),0)), 
		0
	) SCRhowProgress
, N, Kter, itsYear INTO #KterYear
FROM T1
ORDER BY PatientID_FK, RequestedStartDate, Kter


------ Number of patients
----SELECT itsYear, Kter, COUNT(*) NoOfPatients
----FROM #KterYear WHERE NoLastDate =1 AND itsYear=@SelectYear--- NoLastDate =1 FOR the most recent PA in the quarter, one row by patient
----GROUP BY  itsYear, Kter


--missing quarter 
DECLARE @YEARS TABLE (itsYear INT, Kter INT, FMAProgress INT, TMPProgress INT, SBUProgress INT,MEPProgress INT,FAMProgress INT,INPProgress INT,RLPProgress INT,SCLProgress INT,SCRProgress INT)
INSERT INTO @YEARS
	SELECT DISTINCT itsYear,1,0,0,0,0,0,0,0,0,0 FROM #KterYear 
INSERT INTO @YEARS
	SELECT DISTINCT itsYear,2,0,0,0,0,0,0,0,0,0 FROM #KterYear 
INSERT INTO @YEARS
	SELECT DISTINCT itsYear,3,0,0,0,0,0,0,0,0,0 FROM #KterYear 
INSERT INTO @YEARS
	SELECT DISTINCT itsYear,4,0,0,0,0,0,0,0,0,0 FROM #KterYear 


-- AVERAGE BY QUARTER insert into #CarsDomainTemp
SELECT * INTO #CarsDomainTemp FROM  (
SELECT * FROM @YEARS A where NOT EXISTS (SELECT itsYear, Kter FROM #KterYear B WHERE A.itsYear=B.itsYear AND A.Kter=B.Kter) AND itsYear=@SelectYear --QUARTERS WITHOUT VALUE
UNION
SELECT B.itsYear, B.Kter
, ROUND(FMASumProgress/convert(float,A.NoOfPatients),2) FMA_AVG --
, ROUND(TMPSumProgress/convert(float,A.NoOfPatients),2) TMP_AVG
, ROUND(SBUSumProgress/convert(float,A.NoOfPatients),2) SBU_AVG
, ROUND(MEPSumProgress/convert(float,A.NoOfPatients),2) MEP_AVG
, ROUND(FAMSumProgress/convert(float,A.NoOfPatients),2) FAM_AVG
, ROUND(INPSumProgress/convert(float,A.NoOfPatients),2) INP_AVG
, ROUND(RLPSumProgress/convert(float,A.NoOfPatients),2) RLP_AVG
, ROUND(SCLSumProgress/convert(float,A.NoOfPatients),2) SCL_AVG
, ROUND(SCRSumProgress/convert(float,A.NoOfPatients),2) SCR_AVG
FROM 
(SELECT itsYear, Kter, COUNT(*) NoOfPatients
FROM #KterYear WHERE NoLastDate =1 AND itsYear=@SelectYear--- NoLastDate =1 FOR the most recent PA in the quarter, one row by patient
GROUP BY  itsYear, Kter) A
INNER JOIN 
(SELECT itsYear, Kter
, SUM(FMAhowProgress) FMASumProgress
, SUM(TMPhowProgress) TMPSumProgress
, SUM(SBUhowProgress) SBUSumProgress
, SUM(MEPhowProgress) MEPSumProgress
, SUM(FAMhowProgress) FAMSumProgress
, SUM(INPhowProgress) INPSumProgress
, SUM(RLPhowProgress) RLPSumProgress
, SUM(SCLhowProgress) SCLSumProgress
, SUM(SCRhowProgress) SCRSumProgress
FROM #KterYear WHERE NoLastDate =1 AND itsYear=@SelectYear--- NoLastDate =1 FOR the most recent PA in the quarter
GROUP BY  itsYear, Kter
) B ON A.itsYear=B.itsYear AND A.Kter=B.Kter
) A


--#CarsDomainTemp: pivot column to row for each domain
--SELECT * FROM #CarsDomainTemp
CREATE TABLE #CarsDomain (Cars_Domain VARCHAR(25), Q1 DECIMAL(4,2), Q2 float,Q3 float, Q4 float) --create # give the choice on column's name instead of into #

;WITH 
	CTE_FMA AS (SELECT Kter, FMAProgress FROM #CarsDomainTemp),
	CTE_TMP AS (SELECT Kter, TMPProgress FROM #CarsDomainTemp),
	CTE_SBU AS (SELECT Kter, SBUProgress FROM #CarsDomainTemp),
	CTE_MEP AS (SELECT Kter, MEPProgress FROM #CarsDomainTemp),
	CTE_FAM AS (SELECT Kter, FAMProgress FROM #CarsDomainTemp),
	CTE_INP AS (SELECT Kter, INPProgress FROM #CarsDomainTemp),
	CTE_RLP AS (SELECT Kter, RLPProgress FROM #CarsDomainTemp),
	CTE_SCL AS (SELECT Kter, SCLProgress FROM #CarsDomainTemp),
	CTE_SCR AS (SELECT Kter, SCRProgress FROM #CarsDomainTemp)
INSERT INTO #CarsDomain
	SELECT 'Feeling/Mood/Affect' FMAProgress, [1] , [2] , [3] , [4]   FROM CTE_FMA  PIVOT( SUM(FMAProgress) FOR Kter IN ([1], [2], [3], [4] ) ) AS P1 UNION
	SELECT 'Thinking/Mental Processs' TMPProgress, [1] , [2] , [3] , [4]   FROM CTE_TMP  PIVOT( SUM(TMPProgress) FOR Kter IN ([1], [2], [3], [4] ) ) AS P2 UNION
	SELECT 'Substance Use' SBUProgress, [1] , [2] , [3] , [4]   FROM CTE_SBU  PIVOT( SUM(SBUProgress) FOR Kter IN ([1], [2], [3], [4] ) ) AS P3 UNION
	SELECT 'Medical/Physical' MEPProgress, [1] , [2] , [3] , [4]   FROM CTE_MEP  PIVOT( SUM(MEPProgress) FOR Kter IN ([1], [2], [3], [4] ) ) AS P4 UNION
	SELECT 'Family' FAMProgress, [1] , [2] , [3] , [4]   FROM CTE_FAM  PIVOT( SUM(FAMProgress) FOR Kter IN ([1], [2], [3], [4] ) ) AS P5 UNION
	SELECT 'Interpersonal' INPProgress, [1] , [2] , [3] , [4]   FROM CTE_INP  PIVOT( SUM(INPProgress) FOR Kter IN ([1], [2], [3], [4] ) ) AS P6 UNION
	SELECT 'Role Performance' RLPProgress, [1] , [2] , [3] , [4]   FROM CTE_RLP  PIVOT( SUM(RLPProgress) FOR Kter IN ([1], [2], [3], [4] ) ) AS P7 UNION
	SELECT 'Socio-Legal' SCLProgress, [1] , [2] , [3] , [4]   FROM CTE_SCL  PIVOT( SUM(SCLProgress) FOR Kter IN ([1], [2], [3], [4] ) ) AS P8 UNION
	SELECT 'Self Care/Basic Needs' SCRProgress, [1] , [2] , [3] , [4]   FROM CTE_SCR  PIVOT( SUM(SCRProgress) FOR Kter IN ([1], [2], [3], [4] ) ) AS P9 

SELECT Cars_Domain, Q1, Q2, Q3, Q4 FROM #CarsDomain

IF OBJECT_ID('tempdb..#KterYear') IS NOT NULL  
		DROP TABLE #KterYear
IF OBJECT_ID('tempdb..#CarsDomainTemp') IS NOT NULL  
		DROP TABLE #CarsDomainTemp 
IF OBJECT_ID('tempdb..#CarsDomain') IS NOT NULL  
		DROP TABLE #CarsDomain


END

GO

--EXEC APPS.sp_GetYearCarsDomain @SelectYear=2012

--GO

--DROP PROCEDURE APPS.sp_GetYearCarsDomain