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
ORDER BY total_bytes DESC ;