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
