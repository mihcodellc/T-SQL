SET NOCOUNT ON 

--DBCC CLEANTABLE ('DB_LOCAL', 'tCaHistoricoSaldosConcepto', 0)

--DBCC UPDATEUSAGE(0) 

-- DB size.
EXEC sp_spaceused

-- Table row counts and sizes.
CREATE TABLE #t 
( 
    [name] NVARCHAR(128),
    [rows] CHAR(11),
    reserved VARCHAR(18), 
    data VARCHAR(18), 
    index_size VARCHAR(18),
    unused VARCHAR(18)
) 

INSERT #t EXEC sp_msForEachTable 'EXEC sp_spaceused ''?''' 

--SELECT *
--FROM   #t order by data
select name, cast(replace(data, ' KB','') as int)/1024 as TableDataSizeMB

from #t

order by cast(replace(data, ' KB','') as int) desc


-- # of rows.
SELECT SUM(CAST([rows] AS int)) AS [rows]
FROM   #t 
 
DROP TABLE #t 




--DBCC SHRINKDATABASE(0)

