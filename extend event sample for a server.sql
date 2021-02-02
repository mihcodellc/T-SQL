-- Last update: 12/18/2020 - Monktar Bello:  Initial version 

CREATE EVENT SESSION [BelloGeneral] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_data_stream=(1),collect_statement=(1)
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_pid,sqlserver.database_id,sqlserver.nt_username,sqlserver.query_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.sql_text)
    WHERE ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'a_server') AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%sp_Report_PatientDemographics%'))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_pid,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_principal_name,sqlserver.sql_text)
    WHERE ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'a_server') AND [sqlserver].[like_i_sql_unicode_string]([batch_text],N'%sp_Report_PatientDemographics%')))
ADD TARGET package0.histogram(SET filtering_event_name=N'sqlserver.rpc_completed',source=N'sqlserver.session_id')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

