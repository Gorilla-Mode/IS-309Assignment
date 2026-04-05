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

CREATE OR REPLACE VIEW v_data_dict_tables AS
    SELECT
        schemaname AS table_schema,
        relname AS table_name,
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
    END AS table_description,
        (SELECT COUNT(*) FROM information_schema.columns
                         WHERE table_schema = schemaname
                         AND table_name = relname) AS column_count,
        n_live_tup AS row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname;