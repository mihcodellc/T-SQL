-- --pg_lsclusters on ubuntu as postgres user
-- 9.3
-- main
-- 5444
-- postgres
-- data directory: /var/lib/postgresql/9.3/main
-- log file: pg_log/postgresql-%Y-%m-%d_%H%M%S.csv

--- /var/lib/postgresql/scripts/job_pgbadger.sh

--find the latest log file in log folder and pass it to pgbadger, it will generate in the current folder
--*********USE COMPTE AVEC ENOUGH PRIVILIGES TO FILES
-- man pgbadger: https://github.com/darold/pgbadger
-- pgbadger -f stderr /var/lib/postgresql/9.3/main/pg_log/postgresql-2023-11-0_000000.log -o /tmp/reports/out.html
-- pgbadger -f stderr /var/lib/postgresql/9.3/main/pg_log/postgresql-2023-10-*.log -o /tmp/reports/out.html
-- -b begin date and -e end date
-- pgbadger -b "2023-11-01 00:00:11" -e "2023-11-03 23:59:59"  -f stderr /var/lib/postgresql/9.3/main/pg_log/postgresql-2023-11-*.csv -o /tmp/reports/out.html
-- instead of stderr
--  pgbadger --prefix '%t [%p]: user=%u,db=%d,client=%h'   /var/lib/postgresql/9.3/main/pg_log/postgresql-2023-10-23_*.csv


--read log
cd /var/lib/postgresql/9.3/main/pg_log
grep -i  'error\|fatal\|warn' postgresql-2023-11-03_111725.csv | sort -k 1 | tail -n 1


--schema, object in catalog
SELECT relkind as type, n.nspname as schema, c.relname, c.relhastriggers, c.relpages, c.reltuples, c.relacl
FROM pg_class C
LEFT JOIN pg_namespace N
	ON (N.oid = C.relnamespace)
WHERE relname = 'clearinghouse_provider_clearinghouse_provider_id_seq';

-- Connection info
SELECT usename, count(*)
FROM pg_stat_activity
  GROUP by usename;

select pid, * from pg_stat_activity where usename like '%sisense%' and pid <> pg_backend_pid() order by client_hostname
--terminate
--select pg_terminate_backend(pid) from pg_stat_activity where usename like '%sisense%' and pid <> pg_backend_pid();


--kill session
--PG
select pid, query from pg_stat_activity where usename='mbello';  -- get PID -- pid = 3343, 12582
select pg_cancel_backend(3343); --Cancels the current query of the session
-- pg_terminate_backend: Does not rollback. 
-- if timeout not specified, returns true whether the process actually terminates or not. 
-- If the process is terminated, the function returns true.
select pg_terminate_backend(3343, <timeout bigint DEFAULT 0>); 
--rerun to confirm it s gone
select pid, query from pg_stat_activity where usename='mbello';


-- Long Running Queries
 SELECT pid,usename,
        now() - pg_stat_activity.query_start AS duration, -- or age(clock_timestamp(), query_start)
        query AS query
   FROM pg_stat_activity
  WHERE pg_stat_activity.query <> ''::text
    AND now() - pg_stat_activity.query_start > interval '30 seconds'
    AND usename not in ('claimresearch', 'enterprisedb')
  ORDER BY now() - pg_stat_activity.query_start DESC;
--ORDER BY age(clock_timestamp(), query_start)

SELECT usename, count(*)
   FROM pg_stat_activity
  WHERE pg_stat_activity.query <> ''::text
    AND now() - pg_stat_activity.query_start > interval '5 minutes'
 GROUP by usename
 
 -- session running a select statement except the ones involving a call to function
SELECT
    pid,
    usename AS username,
    datname AS database,
    client_addr AS client_address,
    application_name,
    state,
    query,
    query_start
FROM pg_stat_activity
WHERE state = 'active'
  AND query ILIKE 'SELECT%'
  AND  NOT EXISTS (
      SELECT 1
      FROM pg_proc
      WHERE position(proname IN query) > 0 -- Check if function name appears in the query text
        AND provolatile IN ('v') -- Only consider volatile functions (which can alter data)
  );


-- blocking queries
SELECT	bl.pid AS blocked_pid,
        a.query AS blocking_statement,
        now ( ) - ka.query_start AS blocking_duration,
        kl.pid AS blocking_pid,
        a.query AS blocked_statement,
        now ( ) - a.query_start AS blocked_duration
   FROM pg_catalog.pg_locks bl
   JOIN pg_catalog.pg_stat_activity a ON bl.pid = a.pid
   JOIN pg_catalog.pg_locks kl
   JOIN pg_catalog.pg_stat_activity ka
        ON kl.pid = ka.pid
        ON bl.transactionid = kl.transactionid
    AND bl.pid != kl.pid
  WHERE NOT bl.granted;


-- indexes
 SELECT pg_size_pretty(sum(relpages::bigint)) AS size
   FROM pg_class
  WHERE reltype=0;


SELECT *
FROM pg_stat_user_indexes


SELECT relname AS name,
        pg_size_pretty (sum (relpages::BIGINT * 8192)::BIGINT) AS SIZE
   FROM pg_class
  WHERE reltype = 0
  GROUP BY relname
  ORDER BY sum(relpages) DESC;


--- vacuum stats, rows
WITH table_opts AS
  (SELECT pg_class.oid,
          relname,
          nspname,
          array_to_string(reloptions, '') AS relopts
    FROM pg_class
   INNER JOIN pg_namespace ns ON relnamespace = ns.oid),
     vacuum_settings AS
   (SELECT oid,
           relname,
           nspname,
           CASE
               WHEN relopts LIKE '%autovacuum_vacuum_threshold%' THEN regexp_replace(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*', E'\\\\\\1')::integer
               ELSE current_setting('autovacuum_vacuum_threshold')::integer
           END AS autovacuum_vacuum_threshold,
           CASE
               WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%' THEN regexp_replace(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*', E'\\\\\\1')::real
               ELSE current_setting('autovacuum_vacuum_scale_factor')::real
           END AS autovacuum_vacuum_scale_factor
    FROM table_opts)
  SELECT vacuum_settings.nspname AS SCHEMA,
         vacuum_settings.relname AS TABLE,
         to_char(psut.last_vacuum, 'YYYY-MM-DD HH24:MI') AS last_vacuum,
         to_char(psut.last_autovacuum, 'YYYY-MM-DD HH24:MI') AS last_autovacuum,
         replace(replace(replace(to_char(pg_class.reltuples, '9G999G999G999'),',',''),' ',''),'##########','0')::bigint AS rowcount_bigint,
         to_char(pg_class.reltuples, '9G999G999G999') AS rowcount,
         to_char(psut.n_dead_tup, '9G999G999G999') AS dead_rowcount,
         to_char(autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples), '9G999G999G999') AS autovacuum_threshold,
         CASE
             WHEN autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) < psut.n_dead_tup THEN 'yes'
         END AS expect_autovacuum
  FROM pg_stat_user_tables psut
  INNER JOIN pg_class ON psut.relid = pg_class.oid
  INNER JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
  ORDER BY 1,
           2;

