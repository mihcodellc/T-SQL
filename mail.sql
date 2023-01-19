-- check status after Mail not queued. Database Mail is stopped
------ EXECUTE msdb.dbo.sysmail_help_status_sp;
-- sysmail_start_sp : This stored procedure does not activate Service Broker message delivery
-- start only the queues for Database Mail
EXECUTE msdb.dbo.sysmail_start_sp ;  


USE msdb ;  
GO  
  
-- Show the subject, the time that the mail item row was last  
-- modified, and the log information.  
-- Join sysmail_faileditems to sysmail_event_log   
-- on the mailitem_id column.  
-- In the WHERE clause list items where danw was in the recipients,  
-- copy_recipients, or blind_copy_recipients.  
-- These are the items that would have been sent  
-- to danw.  
  
SELECT items.subject,  
    items.last_mod_date  
    ,l.description FROM dbo.sysmail_faileditems as items  
INNER JOIN dbo.sysmail_event_log AS l  
    ON items.mailitem_id = l.mailitem_id  
WHERE items.recipients LIKE '%danw%'    
    OR items.copy_recipients LIKE '%danw%'   
    OR items.blind_copy_recipients LIKE '%danw%'  
GO  

select * from dbo.sysmail_allitems
where subject like '%job%'
and sent_date > '20220308'
