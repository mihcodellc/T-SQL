--migrate message 17806 -- is just an example; yur msg id should be >= 50000
-- https://www.sqlservercentral.com/articles/exporting-custom-messages-from-sys-messages
SELECT 'EXEC master.sys.sp_addmessage @msgnum = ' + CAST(message_id AS VARCHAR(10)) + ', @severity = '
       + CAST(m.severity AS VARCHAR(10)) + ', @msgtext = ''' + m.text + '''' + ', @lang = ''' + s.name + ''''
       + ', @with_log = ''' + CASE
                                  WHEN m.is_event_logged = 1 THEN
                                      'True'
                                  ELSE
                                      'False'
                              END + ''''
FROM sys.messages AS m
    INNER JOIN sys.syslanguages AS s
        ON m.language_id = s.lcid
WHERE m.message_id = 17806 and language_id = 1033;


-- find a speciic sys message
SELECT *
FROM master.dbo.sysmessages 
where 
description like 'Login fail%' 
and 
error > 49999