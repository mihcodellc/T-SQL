--forward
declare @id bigint = 5000
declare @incr bigint = 5000
declare @init bigint = 0



while @id < 720000

begin



print @init
print @id

set @init = @id + 1
set @id = @id + @incr

end

--backward
declare @id bigint = 720000
declare @incr bigint = 5000
declare @init bigint = @id

set @id = @id - @incr

while @id > 0

begin


declare @text varchar(50) = 'between ' + cast(@init as varchar(25)) + ' and ' + cast(@id as varchar(25))
print @text
--print @init
--print @id

set @init = @id - 1
set @id = @id - @incr

end
