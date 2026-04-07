SELECT pg_size_pretty(pg_database_size('bcylce')) as db_size;

SELECT
  table_schema,
  table_name,
  pg_size_pretty(total_bytes - heap_bytes - indexes_bytes) AS toast_bytes,
  pg_size_pretty(heap_bytes) AS heap_size,
  pg_size_pretty(indexes_bytes) AS indexes_size,
  pg_size_pretty(total_bytes) AS total_size
FROM
(
  SELECT
    table_schema,
    table_name,
    pg_relation_size(format('%I.%I', table_schema, table_name)) AS heap_bytes,
    pg_indexes_size(format('%I.%I', table_schema, table_name)) AS indexes_bytes,
    pg_total_relation_size(format('%I.%I', table_schema, table_name)) AS total_bytes
  FROM information_schema.tables
  WHERE table_type = 'BASE TABLE' AND table_schema = 'public'
) AS relation_size
ORDER BY total_bytes DESC;

DROP VIEW IF EXISTS v_data_dict_tables;

CREATE OR REPLACE VIEW v_data_dict_tables AS
    SELECT
        schemaname AS tab_schema,
        relname AS tab_name,
    CASE
        WHEN relname LIKE '%program' THEN 'Bike-sharing programs in different cities'
        WHEN relname LIKE '%station' THEN 'Physical docking stations'
        WHEN relname LIKE '%dock' THEN 'Individual docking points'
        WHEN relname LIKE '%rider' THEN 'Registered system users'
        WHEN relname LIKE '%membership' THEN 'User membership records'
        WHEN relname LIKE '%bicycle' THEN 'Individual bikes in system'
        WHEN relname LIKE '%trip' THEN 'Individual bike rental trips'
        WHEN relname LIKE '%stationst%' THEN 'Historical station availability'
        WHEN relname LIKE '%bicyclest%' THEN 'Historical bicycle status'
        WHEN relname LIKE '%dock_%' THEN 'Audit log'
        ELSE 'No description'
    END AS tab_desc,
        (SELECT COUNT(*) FROM information_schema.columns
                         WHERE table_schema = schemaname
                         AND table_name = relname) AS col_count,
        n_live_tup AS row_count,
        (SELECT COUNT(*) FROM pg_indexes WHERE tablename = relname) AS idx_count,
        (SELECT COUNT(*) FROM information_schema.table_constraints
                         WHERE table_schema = schemaname
                         AND table_name = relname
                         AND constraint_type = 'FOREIGN KEY') AS fk_count,
        (SELECT COUNT(*) FROM information_schema.table_constraints
                         WHERE table_schema = schemaname
                         AND table_name = relname
                         AND constraint_type = 'CHECK') AS chk_count,
        pg_size_pretty(pg_total_relation_size(format('%I.%I', schemaname, relname))) AS tab_size
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname;