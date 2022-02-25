USE [master];
GO


IF OBJECTPROPERTY(OBJECT_ID(N'sp_helpMemberOfRole')
		, N'IsProcedure') = 1
	DROP PROCEDURE [dbo].[sp_helpMemberOfRole];

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE sp_helpMemberOfRole 
	  @UserLogin sysname = NULL
	 ,@srvrolename SYSNAME = NULL
	 ,@rolename SYSNAME = NULL

AS
begin
CREATE TABLE #ROLES (
	RoleON VARCHAR(15)
	,rolename SYSNAME
	,PrincipalName SYSNAME
	)

IF @srvrolename IS NOT NULL
BEGIN
	-- VALIDATE GIVEN NAME  
	IF NOT EXISTS (
			SELECT *
			FROM sys.server_principals
			WHERE name = @srvrolename
				AND principal_id >= suser_id('sysadmin')
				AND principal_id <= suser_id('bulkadmin')
			)
	BEGIN
		RAISERROR (
				15412
				,- 1
				,- 1
				,@srvrolename
				)

		RETURN (1)
	END

	INSERT INTO #ROLES
	-- RESULT SET FOR SINGLE SERVER-ROLE  
	SELECT 'server' AS RoleON
		,'ServerRole' = SUSER_NAME(rm.role_principal_id)
		,'MemberName' = lgn.name --, 'MemberSID' = lgn.sid  
	FROM sys.server_role_members rm
		,sys.server_principals lgn
	WHERE rm.role_principal_id = SUSER_ID(@srvrolename)
		AND rm.member_principal_id = lgn.principal_id
		AND  (lgn.name = @UserLogin OR @UserLogin IS NULL)

END
ELSE
BEGIN
	INSERT INTO #ROLES
	-- RESULT SET FOR ALL FIXED SERVER-ROLES  
	SELECT  'server' AS RoleON
		  ,'ServerRole' = SUSER_NAME(rm.role_principal_id)
		,'MemberName' = lgn.name
		--,'MemberSID' = lgn.sid
	FROM sys.server_role_members rm
		,sys.server_principals lgn
	WHERE rm.role_principal_id >= 3
		AND rm.role_principal_id <= 10
		AND rm.member_principal_id = lgn.principal_id
		AND  (lgn.name = @UserLogin OR @UserLogin IS NULL)

END

IF @rolename IS NOT NULL
BEGIN
	-- VALIDATE GIVEN NAME  
	IF NOT EXISTS (
			SELECT *
			FROM sysusers
			WHERE name = @rolename
				AND issqlrole = 1
			)
	BEGIN
		RAISERROR (
				15409
				,- 1
				,- 1
				,@rolename
				)

		RETURN (1)
	END

	INSERT INTO #ROLES
	-- RESULT SET FOR SINGLE ROLE  
	SELECT 'database' AS RoleON
		,DbRole = g.name
		,MemberName = u.name --, MemberSID = u.sid  
	FROM sys.database_principals u
		,sys.database_principals g
		,sys.database_role_members m
	WHERE g.name = @rolename
		AND g.principal_id = m.role_principal_id
		AND u.principal_id = m.member_principal_id
		AND  (U.name = @UserLogin OR @UserLogin IS NULL)
	ORDER BY 1,2

END
ELSE
BEGIN
	INSERT INTO #ROLES
	-- RESULT SET FOR ALL ROLES  
	SELECT 'database' AS RoleON
		,DbRole = g.name
		,MemberName = u.name --, MemberSID = u.sid  
	FROM sys.database_principals u
		,sys.database_principals g
		,sys.database_role_members m
	WHERE g.principal_id = m.role_principal_id
		AND u.principal_id = m.member_principal_id
		AND  (U.name = @UserLogin OR @UserLogin IS NULL)
	ORDER BY 1,2
END

SELECT RoleON, rolename, PrincipalName
FROM #ROLES
ORDER BY 3, 1

RETURN (0) -- sp_helpMemberOfRole  

end

go

exec [sys].[sp_MS_marksystemobject] 'sp_helpMemberOfRole'
go