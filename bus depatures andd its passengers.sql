--BUSES' DEPATURES ANDD ITS PASSENGERS

--create table buses (
--      id integer primary key,
--      origin varchar(50) not null,
--      destination varchar(50) not null,
--      ttime varchar(50) not null,
--      unique (origin, destination, ttime)
--  );

--  create table passengers (
--      id integer primary key,
--      origin varchar(50) not null,
--      destination varchar(50) not null,
--      ttime varchar(50) not null
--  );
--insert into buses values (10, 'Warsaw', 'Berlin', '10:55');
--insert into buses values (20, 'Berlin', 'Paris', '06:20');
--insert into buses values (21, 'Berlin', 'Paris', '14:00');
--insert into buses values (22, 'Berlin', 'Paris', '21:40');
--insert into buses values (30, 'Paris', 'Madrid', '13:30');
--insert into passengers values (1, 'Paris', 'Madrid', '13:30');
--insert into passengers values (2, 'Paris', 'Madrid', '13:31');
--insert into passengers values (10, 'Warsaw', 'Paris', '10:00');
--insert into passengers values (11, 'Warsaw', 'Berlin', '22:31');
--insert into passengers values (40, 'Berlin', 'Paris', '06:15');
--insert into passengers values (41, 'Berlin', 'Paris', '06:50');
--insert into passengers values (42, 'Berlin', 'Paris', '07:12');
--insert into passengers values (43, 'Berlin', 'Paris', '12:03');
--insert into passengers values (44, 'Berlin', 'Paris', '20:00');

create table #temp ( id integer, p_id int);

create table #temp_buses (
      id integer primary key,
      origin varchar(50) not null,
      destination varchar(50) not null,
      ttime varchar(50) not null,
      unique (origin, destination, ttime)
  );


  create table #temp_passengers (
      id integer primary key,
      origin varchar(50) not null,
      destination varchar(50) not null,
      ttime varchar(50) not null
  );

--bus by departures
insert into #temp_buses
select * from buses order by convert(time,ttime); 

--passengers in temp table
insert into #temp_passengers
select * from passengers 

declare @var_id int;
declare @var_time time;

--first bus based on the departures
select top 1 @var_id = id, @var_time = ttime  from #temp_buses 

while exists (select 1 from #temp_buses) 
begin
	--passenger ready for a bus
    insert into #temp
    SELECT b.id, p.id 
    FROM buses AS b
    LEFT JOIN #temp_passengers AS p  ON b.origin = p.origin AND b.destination  = p.destination AND  convert(time,b.ttime) >= convert(time,p.ttime)
    WHERE b.id = @var_id;

	SELECT b.id, p.id 
    FROM buses AS b
    LEFT JOIN #temp_passengers AS p  ON b.origin = p.origin AND b.destination  = p.destination AND  convert(time,b.ttime) >= convert(time,p.ttime)
    WHERE b.id = @var_id;


	--a bus left
    delete from #temp_buses where id = @var_id

	--a bus passenger left
	delete from #temp_passengers where id in (
	SELECT p.id 
    FROM buses AS b
    LEFT JOIN #temp_passengers AS p  ON b.origin = p.origin AND b.destination  = p.destination AND b.ttime >= p.ttime 
    WHERE b.id = @var_id
	)

	--next bus arrives
	select top 1 @var_id = id, @var_time = ttime  from #temp_buses 
end

select id , count(p_id) as passengers_on_board 
from #temp
group by id

drop table #temp
drop table #temp_buses
drop table #temp_passengers