--select timestamp, TablePKid from MyTable where TablePKid = 728989829 order by TablePKid desc

--Instructions 
-- run the following to find the ID older than 3 months then replace the values in OUPUT section

-- assuming that 
-- SET IDENTITY_INSERT is not used to insert manually some TablePKid
-- reseeding to ID between the current TablePKid and 3 months ago didn't occur
select dateadd(dd,-90, getdate()) asstopDate


declare @TablePKid int = IDENT_CURRENT('schema.MyTable'),
@increment int = 50000,
@whn datetime2, 
@i smallint = 0,  
@limit smallint = 3800, --control max loop
@TablePKid_init int,
@nb_Day_back smallint = 92

set @TablePKid_init = @TablePKid

drop table if exists #temp
create table #temp (TablePKid int, whn datetime2)


select @whn = timestamp, @TablePKid = TablePKid from MyTable where TablePKid = @TablePKid

print @TablePKid

while @whn > dateadd(dd,-@nb_Day_back, getdate()) and @i<@limit 
begin
    insert into #temp (TablePKid, whn)
    select top 1  TablePKid, timestamp from MyTable where TablePKid < @TablePKid order by TablePKid desc

    print 'before'
    print @TablePKid

    set @TablePKid = @TablePKid - @increment
    
     print 'after'
     print @TablePKid

    set @i += 1

    if exists(select 1 from MyTable where TablePKid = @TablePKid) 
	   select @whn = timestamp from MyTable where TablePKid = @TablePKid

    print @i
    print @whn
    --print @TablePKid

end

select *, @TablePKid_init TablePKid_init, @TablePKid_init - TablePKid as num_id, 2075214732 current_rows_num from #temp order by whn asc
select distinct whn from #temp order by whn
select distinct TablePKid, whn from #temp order by TablePKid


---OUTPUT
-- return 131 515 486 rows versus what that should be 133 750 001 
select count(TablePKid) from MyTable where TablePKid between 590875320/*id on 20231025*/ and 724625321 /* id on 20240125*/
