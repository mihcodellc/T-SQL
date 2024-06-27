--https://michaeljswart.com/2014/09/take-care-when-scripting-batches/
--estimate using  logical reads for one row
--then try to use cluseted index to delete like here
--you can enclose all with try -begin tran -commit tran -end try catch -begin @@error > 0 rollback end catch

DECLARE @LargestKeyProcessed INT = - 1
	,@NextBatchMax INT
	,@RC INT = 1;

WHILE (@RC > 0)
BEGIN
	SELECT TOP (1000) @NextBatchMax = OnlineSalesKey
	FROM FactOnlineSales
	WHERE OnlineSalesKey > @LargestKeyProcessed
		AND CustomerKey = 19036
	ORDER BY OnlineSalesKey ASC;

	DELETE FactOnlineSales
	WHERE CustomerKey = 19036
		AND OnlineSalesKey > @LargestKeyProcessed
		AND OnlineSalesKey <= @NextBatchMax;

	SET @RC = @@ROWCOUNT;
	SET @LargestKeyProcessed = @NextBatchMax;
END


 --OR use ID loop below 
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
