-- check status after Mail not queued. Database Mail is stopped
EXECUTE msdb.dbo.sysmail_help_status_sp;
-- sysmail_start_sp : This stored procedure does not activate Service Broker message delivery
-- start only the queues for Database Mail
-------EXECUTE msdb.dbo.sysmail_start_sp ;  

-- By Monktar Bello 3/29/2023: DBA: Restarted Mail If stopped
declare   @t table (avalue nvarchar(7))
insert into @t
EXECUTE msdb.dbo.sysmail_help_status_sp;

--debug
select * from @t

if (select top 1 avalue from @t) <> 'STARTED'
    EXECUTE msdb.dbo.sysmail_start_sp

--https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sysmail-help-queue-sp-transact-sql?view=sql-server-ver16
--two queues in Database Mail: the mail queue and status queue. 
--The mail queue stores mail items that are waiting to be sent. The status queue stores the status of items that have already been sent.
-- State = state of the monitor. 
exec msdb.dbo.sysmail_help_queue_sp  



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
