-- https://sqlperformance.com/2015/02/system-configuration/proactive-sql-server-health-checks-3


-- CREATE TABLE 
IF OBJECT_ID(N'dbo.SQLskills_ConfigData', N'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[SQLskills_ConfigData] 
  (
    [ConfigurationID] [int] NOT NULL ,
    [Name] [nvarchar](35) NOT NULL ,
    [Value] [sql_variant] NULL ,
    [ValueInUse] [sql_variant] NULL ,
    [CaptureDate] [datetime] NOT NULL DEFAULT SYSDATETIME()
  ) ON [PRIMARY];

 
CREATE CLUSTERED INDEX [CI_SQLskills_ConfigData] 
  ON [dbo].[SQLskills_ConfigData] ([CaptureDate],[ConfigurationID]);
END
 
IF OBJECT_ID(N'dbo.SQLskills_DBData', N'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[SQLskills_DBData] (
	[name] [sysname] NOT NULL, [database_id] [int] NOT NULL, [source_database_id] [int] NULL, [owner_sid] [varbinary](85) NULL, [create_date] [datetime] NOT NULL, [compatibility_level] [tinyint] NOT NULL, [collation_name] [sysname] NULL, [user_access] [tinyint] NULL, [user_access_desc] [nvarchar](60) NULL, [is_read_only] [bit] NULL, [is_auto_close_on] [bit] NOT NULL, [is_auto_shrink_on] [bit] NULL, [state] [tinyint] NULL, [state_desc] [nvarchar](60) NULL, [is_in_standby] [bit] NULL, [is_cleanly_shutdown] [bit] NULL, [is_supplemental_logging_enabled] [bit] NULL, [snapshot_isolation_state] [tinyint] NULL, [snapshot_isolation_state_desc] [nvarchar](60) NULL, [is_read_committed_snapshot_on] [bit] NULL, [recovery_model] [tinyint] NULL, [recovery_model_desc] [nvarchar](60) NULL, [page_verify_option] [tinyint] NULL, [page_verify_option_desc] [nvarchar](60) NULL, [is_auto_create_stats_on] [bit] NULL, [is_auto_update_stats_on] [bit] NULL, [is_auto_update_stats_async_on] [bit] NULL, [is_ansi_null_default_on] [bit] NULL, [is_ansi_nulls_on] [bit] NULL, [is_ansi_padding_on] [bit] NULL, 
	[is_ansi_warnings_on] [bit] NULL, [is_arithabort_on] [bit] NULL, [is_concat_null_yields_null_on] [bit] NULL, [is_numeric_roundabort_on] [bit] NULL, [is_quoted_identifier_on] [bit] NULL, [is_recursive_triggers_on] [bit] NULL, [is_cursor_close_on_commit_on] [bit] NULL, [is_local_cursor_default] [bit] NULL, [is_fulltext_enabled] [bit] NULL, [is_trustworthy_on] [bit] NULL, [is_db_chaining_on] [bit] NULL, [is_parameterization_forced] [bit] NULL, [is_master_key_encrypted_by_server] [bit] NOT NULL, [is_published] [bit] NOT NULL, [is_subscribed] [bit] NOT NULL, [is_merge_published] [bit] NOT NULL, [is_distributor] [bit] NOT NULL, [is_sync_with_backup] [bit] NOT NULL, [service_broker_guid] [uniqueidentifier] NOT NULL, [is_broker_enabled] [bit] NOT NULL, [log_reuse_wait] [tinyint] NULL, [log_reuse_wait_desc] [nvarchar](60) NULL, [is_date_correlation_on] [bit] NOT NULL, [is_cdc_enabled] [bit] NOT NULL, [is_encrypted] [bit] NULL, [is_honor_broker_priority_on] [bit] NULL, [replica_id] [uniqueidentifier] NULL, [group_database_id] [uniqueidentifier] NULL, [default_language_lcid] 
	[smallint] NULL, [default_language_name] [nvarchar](128) NULL, [default_fulltext_language_lcid] [int] NULL, [default_fulltext_language_name] [nvarchar](128) NULL, [is_nested_triggers_on] [bit] NULL, [is_transform_noise_words_on] [bit] NULL, [two_digit_year_cutoff] [smallint] NULL, [containment] [tinyint] NULL, [containment_desc] [nvarchar](60) NULL, [target_recovery_time_in_seconds] [int] NULL, [CaptureDate] [datetime] NOT NULL DEFAULT SYSDATETIME()
	) ON [PRIMARY];

 
CREATE CLUSTERED INDEX [CI_SQLskills_DBData] 
  ON [dbo].[SQLskills_DBData] ([CaptureDate],[database_id])

END

/* Statements to use in scheduled job */
INSERT INTO [dbo].[SQLskills_ConfigData] ([ConfigurationID], [Name], [Value], [ValueInUse])
SELECT [configuration_id], [name], [value], [value_in_use]
FROM [sys].[configurations];
GO

INSERT INTO [dbo].[SQLskills_DBData] (
	[name], [database_id], [source_database_id], [owner_sid], [create_date], [compatibility_level], [collation_name], [user_access], [user_access_desc], [is_read_only], [is_auto_close_on], [is_auto_shrink_on], [state], [state_desc], [is_in_standby], [is_cleanly_shutdown], [is_supplemental_logging_enabled], [snapshot_isolation_state], [snapshot_isolation_state_desc], [is_read_committed_snapshot_on], [recovery_model], [recovery_model_desc], [page_verify_option], [page_verify_option_desc], [is_auto_create_stats_on], [is_auto_update_stats_on], [is_auto_update_stats_async_on], [is_ansi_null_default_on], [is_ansi_nulls_on], [is_ansi_padding_on], [is_ansi_warnings_on], [is_arithabort_on], [is_concat_null_yields_null_on], [is_numeric_roundabort_on], [is_quoted_identifier_on], [is_recursive_triggers_on], [is_cursor_close_on_commit_on], [is_local_cursor_default], [is_fulltext_enabled], [is_trustworthy_on], [is_db_chaining_on], [is_parameterization_forced], [is_master_key_encrypted_by_server], [is_published], [is_subscribed], 
	[is_merge_published], [is_distributor], [is_sync_with_backup], [service_broker_guid], [is_broker_enabled], [log_reuse_wait], [log_reuse_wait_desc], [is_date_correlation_on], [is_cdc_enabled], [is_encrypted], [is_honor_broker_priority_on], [replica_id], [group_database_id], [default_language_lcid], [default_language_name], [default_fulltext_language_lcid], [default_fulltext_language_name], [is_nested_triggers_on], [is_transform_noise_words_on], [two_digit_year_cutoff], [containment], [containment_desc], [target_recovery_time_in_seconds]
	)
SELECT [name], [database_id], [source_database_id], [owner_sid], [create_date], [compatibility_level], [collation_name], [user_access], [user_access_desc], [is_read_only], [is_auto_close_on], [is_auto_shrink_on], [state], [state_desc], [is_in_standby], [is_cleanly_shutdown], [is_supplemental_logging_enabled], [snapshot_isolation_state], [snapshot_isolation_state_desc], [is_read_committed_snapshot_on], [recovery_model], [recovery_model_desc], [page_verify_option], [page_verify_option_desc], [is_auto_create_stats_on], [is_auto_update_stats_on], [is_auto_update_stats_async_on], [is_ansi_null_default_on], [is_ansi_nulls_on], [is_ansi_padding_on], [is_ansi_warnings_on], [is_arithabort_on], [is_concat_null_yields_null_on], [is_numeric_roundabort_on], [is_quoted_identifier_on], [is_recursive_triggers_on], [is_cursor_close_on_commit_on], [is_local_cursor_default], [is_fulltext_enabled], [is_trustworthy_on], [is_db_chaining_on], [is_parameterization_forced], [is_master_key_encrypted_by_server], [is_published], [is_subscribed], 
	[is_merge_published], [is_distributor], [is_sync_with_backup], [service_broker_guid], [is_broker_enabled], [log_reuse_wait], [log_reuse_wait_desc], [is_date_correlation_on], [is_cdc_enabled], [is_encrypted], [is_honor_broker_priority_on], [replica_id], [group_database_id], [default_language_lcid], [default_language_name], [default_fulltext_language_lcid], [default_fulltext_language_name], [is_nested_triggers_on], [is_transform_noise_words_on], [two_digit_year_cutoff], [containment], [containment_desc], [target_recovery_time_in_seconds]
FROM [sys].[databases];
GO




-- **** check for the changes on server level
;WITH [f] AS 
(
	SELECT ROW_NUMBER() OVER (
			PARTITION BY [ConfigurationID] ORDER BY [CaptureDate] ASC
			) AS [RowNumber], [ConfigurationID] AS [ConfigurationID], [Name] AS [Name], [Value] AS [Value], [ValueInUse] AS [ValueInUse], [CaptureDate] AS [CaptureDate]
	FROM [Baselines].[dbo].[ConfigData]
)
SELECT [f].[Name] AS [Setting], [f].[CaptureDate] AS [Date], [f].[Value] AS [Previous Value], [f].[ValueInUse] AS [Previous Value In Use], [n].[CaptureDate] AS [Date Changed],
    [n].[Value] AS [New Value], [n].[ValueInUse] AS [New Value In Use]
FROM [f]
LEFT OUTER JOIN [f] AS [n] ON [f].[ConfigurationID] = [n].[ConfigurationID] 	AND [f].[RowNumber] + 1 = [n].[RowNumber]
WHERE (
		[f].[Value] <> [n].[Value]
		OR [f].[ValueInUse] <> [n].[ValueInUse]
		);

-- **** CHECK THE CHANGES ON DATABASE LEVEL
/*============================================================================
  File:     Create_usp_FindDBSettingChanges.sql

  SQL Server Versions: 2014 onwards
------------------------------------------------------------------------------
  Written by Erin Stellato, SQLskills.com
  
  (c) 2015, SQLskills.com. All rights reserved.

  For more scripts and sample code, check out 
    http://www.SQLskills.com

  You may alter this code for your own *non-commercial* purposes. You may
  republish altered code as long as you include this copyright and give due
  credit, but you must obtain prior permission before blogging this code.
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

CREATE PROCEDURE [dbo].[usp_FindDBSettingChanges]
AS
BEGIN
;WITH f AS 
(
 SELECT ROW_NUMBER() OVER (
		PARTITION BY database_id ORDER BY CaptureDate ASC
		) AS RowNumber, [name], [database_id], [source_database_id], [owner_sid], [create_date], [compatibility_level], [collation_name], [user_access], [user_access_desc], [is_read_only], [is_auto_close_on], [is_auto_shrink_on], [state], [state_desc], [is_in_standby], [is_cleanly_shutdown], [is_supplemental_logging_enabled], [snapshot_isolation_state], [snapshot_isolation_state_desc], [is_read_committed_snapshot_on], [recovery_model], [recovery_model_desc], [page_verify_option], [page_verify_option_desc], [is_auto_create_stats_on], [is_auto_update_stats_on], [is_auto_update_stats_async_on], [is_ansi_null_default_on], [is_ansi_nulls_on], [is_ansi_padding_on], [is_ansi_warnings_on], [is_arithabort_on], [is_concat_null_yields_null_on], [is_numeric_roundabort_on], [is_quoted_identifier_on], [is_recursive_triggers_on], [is_cursor_close_on_commit_on], [is_local_cursor_default], [is_fulltext_enabled], [is_trustworthy_on], [is_db_chaining_on], [is_parameterization_forced], [is_master_key_encrypted_by_server], [is_published], 
	[is_subscribed], [is_merge_published], [is_distributor], [is_sync_with_backup], [service_broker_guid], [is_broker_enabled], [log_reuse_wait], [log_reuse_wait_desc], [is_date_correlation_on], [is_cdc_enabled], [is_encrypted], [is_honor_broker_priority_on], [replica_id], [group_database_id], [default_language_lcid], [default_language_name], [default_fulltext_language_lcid], [default_fulltext_language_name], [is_nested_triggers_on], [is_transform_noise_words_on], [two_digit_year_cutoff], [containment], [containment_desc], [target_recovery_time_in_seconds], [CaptureDate]
FROM [dbo].[SQLskills_DBData]
)
SELECT 
	f.database_id,
	f.name,
	CASE
	WHEN [f].[owner_sid] <> [n].[owner_sid] THEN '[owner_sid] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[owner_sid] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[owner_sid] AS NVARCHAR(255))
	WHEN [f].[create_date] <> [n].[create_date] THEN '[create_date] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[create_date] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[create_date] AS NVARCHAR(255))
	WHEN [f].[compatibility_level] <> [n].[compatibility_level] THEN '[compatibility_level] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[compatibility_level] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[compatibility_level] AS NVARCHAR(255))
	WHEN [f].[collation_name] <> [n].[collation_name] THEN '[collation_name] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[collation_name] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[collation_name] AS NVARCHAR(255))
	WHEN [f].[user_access] <> [n].[user_access] THEN '[user_access] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[user_access] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[user_access] AS NVARCHAR(255))
	WHEN [f].[is_read_only] <> [n].[is_read_only] THEN '[is_read_only] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_read_only] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_read_only] AS NVARCHAR(255))
	WHEN [f].[is_auto_close_on] <> [n].[is_auto_close_on] THEN '[is_auto_close_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_auto_close_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_auto_close_on] AS NVARCHAR(255))
	WHEN [f].[is_auto_shrink_on] <> [n].[is_auto_shrink_on] THEN '[is_auto_shrink_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_auto_shrink_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_auto_shrink_on] AS NVARCHAR(255))
	WHEN [f].[state] <> [n].[state] THEN '[state] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[state] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[state] AS NVARCHAR(255))
	WHEN [f].[is_in_standby] <> [n].[is_in_standby] THEN '[is_in_standby] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_in_standby] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_in_standby] AS NVARCHAR(255))
	WHEN [f].[is_cleanly_shutdown] <> [n].[is_cleanly_shutdown] THEN '[is_cleanly_shutdown] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_cleanly_shutdown] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_cleanly_shutdown] AS NVARCHAR(255))
	WHEN [f].[is_supplemental_logging_enabled] <> [n].[is_supplemental_logging_enabled] THEN '[is_supplemental_logging_enabled] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_supplemental_logging_enabled] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_supplemental_logging_enabled] AS NVARCHAR(255))
	WHEN [f].[snapshot_isolation_state] <> [n].[snapshot_isolation_state] THEN '[snapshot_isolation_state] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[snapshot_isolation_state] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[snapshot_isolation_state] AS NVARCHAR(255))
	WHEN [f].[is_read_committed_snapshot_on] <> [n].[is_read_committed_snapshot_on] THEN '[is_read_committed_snapshot_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_read_committed_snapshot_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_read_committed_snapshot_on] AS NVARCHAR(255))
	WHEN [f].[recovery_model] <> [n].[recovery_model] THEN '[recovery_model] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[recovery_model] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[recovery_model] AS NVARCHAR(255))
	WHEN [f].[page_verify_option] <> [n].[page_verify_option] THEN '[page_verify_option] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[page_verify_option] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[page_verify_option] AS NVARCHAR(255))
	WHEN [f].[is_auto_create_stats_on] <> [n].[is_auto_create_stats_on] THEN '[is_auto_create_stats_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_auto_create_stats_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_auto_create_stats_on] AS NVARCHAR(255))
	WHEN [f].[is_auto_update_stats_on] <> [n].[is_auto_update_stats_on] THEN '[is_auto_update_stats_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_auto_update_stats_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_auto_update_stats_on] AS NVARCHAR(255))
	WHEN [f].[is_auto_update_stats_async_on] <> [n].[is_auto_update_stats_async_on] THEN '[is_auto_update_stats_async_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[compatibility_level] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[compatibility_level] AS NVARCHAR(255))
	WHEN [f].[is_ansi_null_default_on] <> [n].[is_ansi_null_default_on] THEN '[is_ansi_null_default_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_ansi_null_default_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_ansi_null_default_on] AS NVARCHAR(255))
	WHEN [f].[is_ansi_nulls_on] <> [n].[is_ansi_nulls_on] THEN '[is_ansi_nulls_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_ansi_nulls_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_ansi_nulls_on] AS NVARCHAR(255))
	WHEN [f].[is_ansi_padding_on] <> [n].[is_ansi_padding_on] THEN '[is_ansi_padding_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_ansi_padding_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_ansi_padding_on] AS NVARCHAR(255))
	WHEN [f].[is_ansi_warnings_on] <> [n].[is_ansi_warnings_on] THEN '[is_ansi_warnings_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_ansi_warnings_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_ansi_warnings_on] AS NVARCHAR(255))
	WHEN [f].[is_arithabort_on] <> [n].[is_arithabort_on] THEN '[is_arithabort_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_arithabort_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_arithabort_on] AS NVARCHAR(255))
	WHEN [f].[is_concat_null_yields_null_on] <> [n].[is_concat_null_yields_null_on] THEN '[is_concat_null_yields_null_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_concat_null_yields_null_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_concat_null_yields_null_on] AS NVARCHAR(255))
	WHEN [f].[is_numeric_roundabort_on] <> [n].[is_numeric_roundabort_on] THEN '[is_numeric_roundabort_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_numeric_roundabort_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_numeric_roundabort_on] AS NVARCHAR(255))
	WHEN [f].[is_quoted_identifier_on] <> [n].[is_quoted_identifier_on] THEN '[is_quoted_identifier_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_quoted_identifier_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_quoted_identifier_on] AS NVARCHAR(255))
	WHEN [f].[is_recursive_triggers_on] <> [n].[is_recursive_triggers_on] THEN '[is_recursive_triggers_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_recursive_triggers_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_recursive_triggers_on] AS NVARCHAR(255))
	WHEN [f].[is_cursor_close_on_commit_on] <> [n].[is_cursor_close_on_commit_on] THEN '[is_cursor_close_on_commit_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_cursor_close_on_commit_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_cursor_close_on_commit_on] AS NVARCHAR(255))
	WHEN [f].[is_local_cursor_default] <> [n].[is_local_cursor_default] THEN '[is_local_cursor_default] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_local_cursor_default] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_local_cursor_default] AS NVARCHAR(255))
	WHEN [f].[is_fulltext_enabled] <> [n].[is_fulltext_enabled] THEN '[is_fulltext_enabled] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_fulltext_enabled] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_fulltext_enabled] AS NVARCHAR(255))
	WHEN [f].[is_trustworthy_on] <> [n].[is_trustworthy_on] THEN '[is_trustworthy_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_trustworthy_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_trustworthy_on] AS NVARCHAR(255))
	WHEN [f].[is_db_chaining_on] <> [n].[is_db_chaining_on] THEN '[is_db_chaining_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_db_chaining_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_db_chaining_on] AS NVARCHAR(255))
	WHEN [f].[is_parameterization_forced] <> [n].[is_parameterization_forced] THEN '[is_parameterization_forced] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_parameterization_forced] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_parameterization_forced] AS NVARCHAR(255))
	WHEN [f].[is_master_key_encrypted_by_server] <> [n].[is_master_key_encrypted_by_server] THEN '[is_master_key_encrypted_by_server] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_master_key_encrypted_by_server] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_master_key_encrypted_by_server] AS NVARCHAR(255))
	WHEN [f].[is_published] <> [n].[is_published] THEN '[is_published] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_published] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_published] AS NVARCHAR(255))
	WHEN [f].[is_subscribed] <> [n].[is_subscribed] THEN '[is_subscribed] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_subscribed] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_subscribed] AS NVARCHAR(255))
	WHEN [f].[is_merge_published] <> [n].[is_merge_published] THEN '[is_merge_published] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_merge_published] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_merge_published] AS NVARCHAR(255))
	WHEN [f].[is_distributor] <> [n].[is_distributor] THEN '[is_distributor] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_distributor] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_distributor] AS NVARCHAR(255))
	WHEN [f].[is_sync_with_backup] <> [n].[is_sync_with_backup] THEN '[is_sync_with_backup] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_sync_with_backup] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_sync_with_backup] AS NVARCHAR(255))
	WHEN [f].[service_broker_guid] <> [n].[service_broker_guid] THEN '[service_broker_guid] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[service_broker_guid] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[service_broker_guid] AS NVARCHAR(255))
	WHEN [f].[is_broker_enabled] <> [n].[is_broker_enabled] THEN '[is_broker_enabled] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_broker_enabled] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_broker_enabled] AS NVARCHAR(255))
	WHEN [f].[is_date_correlation_on] <> [n].[is_date_correlation_on] THEN '[is_date_correlation_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_date_correlation_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_date_correlation_on] AS NVARCHAR(255))
	WHEN [f].[is_cdc_enabled] <> [n].[is_cdc_enabled] THEN '[is_cdc_enabled] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_cdc_enabled] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_cdc_enabled] AS NVARCHAR(255))
	WHEN [f].[is_encrypted] <> [n].[is_encrypted] THEN '[is_encrypted] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_encrypted] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_encrypted] AS NVARCHAR(255))
	WHEN [f].[is_honor_broker_priority_on] <> [n].[is_honor_broker_priority_on] THEN '[is_honor_broker_priority_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_honor_broker_priority_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_honor_broker_priority_on] AS NVARCHAR(255))
	WHEN [f].[replica_id] <> [n].[replica_id] THEN '[replica_id] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[replica_id] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[replica_id] AS NVARCHAR(255))
	WHEN [f].[group_database_id] <> [n].[group_database_id] THEN '[group_database_id] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[group_database_id] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[group_database_id] AS NVARCHAR(255))
	WHEN [f].[default_language_lcid] <> [n].[default_language_lcid] THEN '[default_language_lcid] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[default_language_lcid] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[default_language_lcid] AS NVARCHAR(255))
	WHEN [f].[default_fulltext_language_lcid] <> [n].[default_fulltext_language_lcid] THEN '[default_fulltext_language_lcid] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[default_fulltext_language_lcid] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[default_fulltext_language_lcid] AS NVARCHAR(255))
	WHEN [f].[is_nested_triggers_on] <> [n].[is_nested_triggers_on] THEN '[is_nested_triggers_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_nested_triggers_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_nested_triggers_on] AS NVARCHAR(255))
	WHEN [f].[is_transform_noise_words_on] <> [n].[is_transform_noise_words_on] THEN '[is_transform_noise_words_on] - [is_transform_noise_words_on] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[is_transform_noise_words_on] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[is_transform_noise_words_on] AS NVARCHAR(255))
	WHEN [f].[two_digit_year_cutoff] <> [n].[two_digit_year_cutoff] THEN '[two_digit_year_cutoff] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[two_digit_year_cutoff] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[two_digit_year_cutoff] AS NVARCHAR(255))
	WHEN [f].[containment] <> [n].[containment] THEN '[containment] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[containment] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[containment] AS NVARCHAR(255))
	WHEN [f].[target_recovery_time_in_seconds] <> [n].[target_recovery_time_in_seconds] THEN '[target_recovery_time_in_seconds] - Original value from ' + CAST([f].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([f].[target_recovery_time_in_seconds] AS NVARCHAR(255)) + ' ' + ', Changed value from ' + CAST([n].[CaptureDate] AS NVARCHAR(255)) + ': ' + CAST([n].[target_recovery_time_in_seconds] AS NVARCHAR(255))
 END
FROM f
LEFT OUTER JOIN f AS n
ON f.database_id = n.database_id
AND f.RowNumber + 1 = n.RowNumber
WHERE (
	[f].owner_sid <> [n].owner_sid 
	OR [f].create_date <> [n].create_date
	OR [f].[compatibility_level] <> [n].[compatibility_level]
    OR [f].[collation_name] <> [n].[collation_name]
    OR [f].[user_access] <> [n].[user_access]
    OR [f].[is_read_only] <> [n].[is_read_only]
    OR [f].[is_auto_close_on] <> [n].[is_auto_close_on]
    OR [f].[is_auto_shrink_on] <> [n].[is_auto_shrink_on]
    OR [f].[state] <> [n].[state]
    OR [f].[is_in_standby] <> [n].[is_in_standby]
    OR [f].[is_cleanly_shutdown] <> [n].[is_cleanly_shutdown]
    OR [f].[is_supplemental_logging_enabled] <> [n].[is_supplemental_logging_enabled]
    OR [f].[snapshot_isolation_state] <> [n].[snapshot_isolation_state]
    OR [f].[is_read_committed_snapshot_on] <> [n].[is_read_committed_snapshot_on]
    OR [f].[recovery_model] <> [n].[recovery_model]
    OR [f].[page_verify_option] <> [n].[page_verify_option]
    OR [f].[is_auto_create_stats_on] <> [n].[is_auto_create_stats_on]
    OR [f].[is_auto_update_stats_on] <> [n].[is_auto_update_stats_on]
    OR [f].[is_auto_update_stats_async_on] <> [n].[is_auto_update_stats_async_on]
    OR [f].[is_ansi_null_default_on] <> [n].[is_ansi_null_default_on]
    OR [f].[is_ansi_nulls_on] <> [n].[is_ansi_nulls_on]
    OR [f].[is_ansi_padding_on] <> [n].[is_ansi_padding_on]
    OR [f].[is_ansi_warnings_on] <> [n].[is_ansi_warnings_on]
    OR [f].[is_arithabort_on] <> [n].[is_arithabort_on]
    OR [f].[is_concat_null_yields_null_on] <> [n].[is_concat_null_yields_null_on]
    OR [f].[is_numeric_roundabort_on] <> [n].[is_numeric_roundabort_on]
    OR [f].[is_quoted_identifier_on] <> [n].[is_quoted_identifier_on]
    OR [f].[is_recursive_triggers_on] <> [n].[is_recursive_triggers_on]
    OR [f].[is_cursor_close_on_commit_on] <> [n].[is_cursor_close_on_commit_on]
    OR [f].[is_local_cursor_default] <> [n].[is_local_cursor_default]
    OR [f].[is_fulltext_enabled] <> [n].[is_fulltext_enabled]
    OR [f].[is_trustworthy_on] <> [n].[is_trustworthy_on]
    OR [f].[is_db_chaining_on] <> [n].[is_db_chaining_on]
    OR [f].[is_parameterization_forced] <> [n].[is_parameterization_forced]
    OR [f].[is_master_key_encrypted_by_server] <> [n].[is_master_key_encrypted_by_server]
    OR [f].[is_published] <> [n].[is_published]
    OR [f].[is_subscribed] <> [n].[is_subscribed]
    OR [f].[is_merge_published] <> [n].[is_merge_published]
    OR [f].[is_distributor] <> [n].[is_distributor]
    OR [f].[is_sync_with_backup] <> [n].[is_sync_with_backup]
    OR [f].[service_broker_guid] <> [n].[service_broker_guid]
    OR [f].[is_broker_enabled] <> [n].[is_broker_enabled]
    OR [f].[is_date_correlation_on] <> [n].[is_date_correlation_on]
    OR [f].[is_cdc_enabled] <> [n].[is_cdc_enabled]
    OR [f].[is_encrypted] <> [n].[is_encrypted]
    OR [f].[is_honor_broker_priority_on] <> [n].[is_honor_broker_priority_on]
    OR [f].[replica_id] <> [n].[replica_id]
    OR [f].[group_database_id] <> [n].[group_database_id]
    OR [f].[default_language_lcid] <> [n].[default_language_lcid]
    OR [f].[default_fulltext_language_lcid] <> [n].[default_fulltext_language_lcid]
    OR [f].[is_nested_triggers_on] <> [n].[is_nested_triggers_on]
    OR [f].[is_transform_noise_words_on] <> [n].[is_transform_noise_words_on]
    OR [f].[two_digit_year_cutoff] <> [n].[two_digit_year_cutoff]
    OR [f].[containment] <> [n].[containment]
    OR [f].[target_recovery_time_in_seconds] <> [n].[target_recovery_time_in_seconds]
	);

END
