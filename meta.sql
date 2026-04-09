SELECT pg_size_pretty(pg_database_size('bcylce')) as db_size;

CREATE OR REPLACE VIEW v_relation_sizes AS
    SELECT
        table_schema,
        table_name,
        pg_size_pretty(pg_relation_size(format('%I.%I', table_schema, table_name), 'main')) AS heap_bytes,
        pg_size_pretty(pg_relation_size(format('%I.%I', table_schema, table_name), 'fsm')) AS fsm_bytes,
        pg_size_pretty(pg_relation_size(format('%I.%I', table_schema, table_name), 'vm')) AS vm_bytes,
        pg_size_pretty(pg_relation_size(format('%I.%I', table_schema, table_name), 'init')) AS init_bytes,
        pg_size_pretty(
            pg_total_relation_size(format('%I.%I', table_schema, table_name)) -
            pg_indexes_size(format('%I.%I', table_schema, table_name)) -
            pg_relation_size(format('%I.%I', table_schema, table_name), 'main')
        ) AS toast_bytes,
        pg_size_pretty(pg_table_size(format('%I.%I', table_schema, table_name))) AS tot_table_bytes,
        pg_size_pretty(pg_indexes_size(format('%I.%I', table_schema, table_name))) AS index_bytes,
        pg_size_pretty(pg_total_relation_size(format('%I.%I', table_schema, table_name))) AS tot_relation_bytes
    FROM information_schema.tables
    WHERE table_type = 'BASE TABLE' AND table_schema = 'public'
    ORDER BY tot_relation_bytes;

CREATE EXTENSION IF NOT EXISTS pageinspect;

CREATE OR REPLACE VIEW v_page_usage AS
    SELECT
        stat.relname AS table_name,
        pc.relpages AS full_pages,
        CASE
            WHEN pc.relpages > 0 THEN
                (SELECT count(*) FROM heap_page_items(get_raw_page(stat.relname, 0)))
        END AS real_max_tuples_in_page,
        CASE
            WHEN pc.relpages > 0 THEN NULL
            WHEN pc.relpages = 0 AND stat.n_live_tup > 0 THEN
                (SELECT FLOOR((current_setting('block_size')::int - 32) / (AVG(lp_len) + 8))
                    FROM heap_page_items(get_raw_page(stat.relname, 0)))
        END AS est_max_tuples_in_page,
        CASE
            WHEN stat.n_live_tup = 0 THEN NULL
            WHEN pc.relpages = 0 THEN
                stat.n_live_tup
            WHEN pc.relpages > 0 THEN
                stat.n_live_tup / pc.relpages
        END AS tuples_in_allocated_page,
        (pc.relpages > 0) AS has_full_page
    FROM pg_stat_user_tables stat
    LEFT JOIN pg_class pc ON stat.relname = pc.relname
        AND pc.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    WHERE stat.schemaname = 'public'
    ORDER BY stat.relname;

DROP VIEW IF EXISTS v_data_dict_tables;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_data_dict_tables AS
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
                         AND constraint_type = 'PRIMARY KEY') AS pk_count,
        (SELECT COUNT(*) FROM information_schema.table_constraints
                         WHERE table_schema = schemaname
                         AND table_name = relname
                         AND constraint_type = 'CHECK' AND constraint_name NOT LIKE '%not_null%') AS chk_count,
        pg_size_pretty(pg_total_relation_size(format('%I.%I', schemaname, relname))) AS tab_size
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_data_dict_tab_unique
    ON mv_data_dict_tables(tab_schema, tab_name);
CREATE INDEX IF NOT EXISTS idx_mv_data_dict_tab_name ON mv_data_dict_tables(tab_name);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_data_dict_columns AS
SELECT
    cols.table_schema AS tab_schema,
    cols.table_name AS tab_name,
    cols.column_name AS col_name,
    cols.data_type,
    cols.character_maximum_length AS char_max_len,
    cols.numeric_precision AS num_precision,
    cols.numeric_scale AS num_scale,
    cols.is_nullable,
    cols.column_default AS col_default_val,
    string_agg(tc.constraint_type, ', ' ORDER BY tc.constraint_type) AS cons_type,
    string_agg(tc.constraint_name, ', ' ORDER BY tc.constraint_type) AS cons_name,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM pg_indexes
            WHERE pg_indexes.tablename = cols.table_name
            AND pg_indexes.indexdef LIKE '%' || cols.column_name || '%'
        ) THEN TRUE
        ELSE FALSE
    END AS has_idx,
    CASE
        -- Column descriptions, AI used
        -- Program table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.programid' THEN 'Unique identifier for program'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.programcode' THEN 'Unique code for program (e.g., city code)'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.countrycode' THEN 'ISO 2-letter country code where program operates'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.name' THEN 'Full name of bike-sharing program'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.location' THEN 'Primary location/city of program headquarters'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.phone' THEN 'Contact phone number for program'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.email' THEN 'Contact email address for program'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.timezone' THEN 'Timezone where program operates'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.url' THEN 'Official website URL of program'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'program.shortname' THEN 'Abbreviated name for program display'

        -- Station table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.stationid' THEN 'Unique identifier for station'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.stationcode' THEN 'Unique code for station (e.g., station location code)'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.programid' THEN 'Foreign key to Program table'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.address' THEN 'Street address of station'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.name' THEN 'Display name of station'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.latitude' THEN 'Geographic latitude coordinate'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.longitude' THEN 'Geographic longitude coordinate'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.capacity' THEN 'Maximum number of bikes/docks station can hold'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.postalcode' THEN 'Postal/ZIP code of station location'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.contactphone' THEN 'Contact phone for station-specific issues'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'station.shortname' THEN 'Abbreviated station name for display'

        -- Dock table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'dock.dockid' THEN 'Unique identifier for individual docking point'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'dock.stationid' THEN 'Foreign key to Station table'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'dock.docknumber' THEN 'Sequential number of dock within station'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'dock.isoperational' THEN 'Boolean flag indicating if dock is currently operational'

        -- Rider table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.riderid' THEN 'Unique identifier for rider/user'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.firstname' THEN 'First name of rider'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.lastname' THEN 'Last name of rider'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.email' THEN 'Email address of rider (unique)'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.phone' THEN 'Phone number of rider'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.street' THEN 'Street address of rider'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.apt' THEN 'Apartment/unit number of rider'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.city' THEN 'City of rider residence'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.state' THEN 'State/province of rider residence'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'rider.zip' THEN 'Postal code of rider residence'

        -- Membership table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'membership.membershipid' THEN 'Unique identifier for membership record'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'membership.riderid' THEN 'Foreign key to Rider table'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'membership.membershiptype' THEN 'Type of membership: DAY, MONTH, or ANNUAL'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'membership.purchasedat' THEN 'Timestamp when membership was purchased'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'membership.expiresat' THEN 'Timestamp when membership expires'

        -- Bicycle table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicycle.bicycleid' THEN 'Unique identifier for bicycle'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicycle.bicycletype' THEN 'Type of bicycle: ELECTRIC, SMART, CLASSIC, or CARGO'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicycle.make' THEN 'Manufacturer/brand of bicycle'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicycle.model' THEN 'Model name/number of bicycle'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicycle.color' THEN 'Color description of bicycle'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicycle.yearacquired' THEN 'Year bicycle was acquired by the program'

        -- Trip table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.tripid' THEN 'Unique identifier for trip record'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.riderid' THEN 'Foreign key to Rider table'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.bicycleid' THEN 'Foreign key to Bicycle table'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.startstationid' THEN 'Foreign key to Station table (rental location)'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.endstationid' THEN 'Foreign key to Station table (return location)'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.starttime' THEN 'Timestamp when trip started'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.endtime' THEN 'Timestamp when trip ended (null if in progress)'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.totaldistance' THEN 'Distance traveled in kilometers (null if not available)'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.totalelapedseconds' THEN 'Duration of trip in seconds (null if not finished)'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.totalcost' THEN 'Total cost of trip in currency units'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.tripfinished' THEN 'Boolean flag indicating if trip is complete'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'trip.totalelapsedseconds' THEN 'Amount of time in seconds since start of trip'

        -- StationStatus table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.stationstatusid' THEN 'Unique identifier for status record'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.stationid' THEN 'Foreign key to Station table'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.reportedat' THEN 'Timestamp when status was recorded'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.bikesavailelectric' THEN 'Count of available electric bikes'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.bikesavailclassic' THEN 'Count of available classic bikes'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.bikesavailsmart' THEN 'Count of available smart bikes'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.bikesavailcargo' THEN 'Count of available cargo bikes'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.bikesavailtotal' THEN 'Total count of available bikes'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.docksavailtotal' THEN 'Total count of available docking points'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.acceptingreturns' THEN 'Boolean indicating if station accepts bike returns'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'stationstatus.isrenting' THEN 'Boolean indicating if station is currently renting bikes'

        -- BicycleStatus table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicyclestatus.bicyclestatusid' THEN 'Unique identifier for status record'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicyclestatus.bicycleid' THEN 'Foreign key to Bicycle table'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicyclestatus.recordedat' THEN 'Timestamp when status was recorded'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicyclestatus.status' THEN 'Current status: AVAILABLE, IN_USE, or NOT_AVAILABLE'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicyclestatus.latitude' THEN 'Geographic latitude of bicycle location'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicyclestatus.longitude' THEN 'Geographic longitude of bicycle location'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicyclestatus.batterypercent' THEN 'Battery percentage (0-100) for electric/smart bikes'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'bicyclestatus.remainingrange' THEN 'Estimated remaining range in kilometers for electric bikes'

        -- Dock Audit Log table
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'dock_audit_log.logid' THEN 'Unique identifier for audit log entry'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'dock_audit_log.action_type' THEN 'Type of action performed (INSERT, UPDATE, DELETE)'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'dock_audit_log.action_time' THEN 'Timestamp when audit action occurred'
        WHEN format('%I.%I', cols.table_name, cols.column_name) = 'dock_audit_log.table_name' THEN 'Name of table that was modified'

        ELSE 'No description'
    END AS col_desc
FROM information_schema.columns AS cols
LEFT JOIN (
    SELECT table_schema, table_name, column_name, constraint_name FROM information_schema.key_column_usage
    UNION
    SELECT table_schema, table_name, column_name, constraint_name FROM information_schema.constraint_column_usage
) AS combined ON cols.table_schema = combined.table_schema
    AND cols.table_name = combined.table_name
    AND cols.column_name = combined.column_name
LEFT JOIN information_schema.table_constraints AS tc
    ON combined.table_schema = tc.table_schema
    AND combined.table_name = tc.table_name
    AND combined.constraint_name = tc.constraint_name
WHERE cols.table_schema = 'public' AND cols.table_name NOT LIKE '%v_%'
GROUP BY cols.table_schema, cols.table_name, cols.column_name, cols.data_type,
         cols.character_maximum_length, cols.numeric_precision, cols.numeric_scale,
         cols.is_nullable, cols.column_default
ORDER BY cols.table_name, cols.column_name
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_data_dict_cols_unique
    ON mv_data_dict_columns(tab_schema, tab_name, col_name);
CREATE INDEX IF NOT EXISTS idx_mv_data_dict_cols_tab_name ON mv_data_dict_columns(tab_name);
CREATE INDEX IF NOT EXISTS idx_mv_data_dict_cols_col_name ON mv_data_dict_columns(col_name);

CREATE OR REPLACE VIEW v_data_dict_program AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'program' ORDER BY col_name;

CREATE OR REPLACE VIEW v_data_dict_station AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'station' ORDER BY col_name;

CREATE OR REPLACE VIEW v_data_dict_dock AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'dock' ORDER BY col_name;

CREATE OR REPLACE VIEW v_data_dict_rider AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'rider' ORDER BY col_name;

CREATE OR REPLACE VIEW v_data_dict_membership AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'membership' ORDER BY col_name;

CREATE OR REPLACE VIEW v_data_dict_bicycle AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'bicycle' ORDER BY col_name;

CREATE OR REPLACE VIEW v_data_dict_trip AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'trip' ORDER BY col_name;

CREATE OR REPLACE VIEW v_data_dict_stationstatus AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'stationstatus' ORDER BY col_name;

CREATE OR REPLACE VIEW v_data_dict_bicyclestatus AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'bicyclestatus' ORDER BY col_name;

CREATE OR REPLACE VIEW v_data_dict_dock_audit_log AS
SELECT * FROM mv_data_dict_columns WHERE tab_name = 'dock_audit_log' ORDER BY col_name;

CREATE OR REPLACE PROCEDURE refresh_materialized_views()
    LANGUAGE plpgsql
AS $$
BEGIN
    LOOP
        RAISE NOTICE 'Refreshing materialized views at %', NOW();
        REFRESH MATERIALIZED VIEW CONCURRENTLY mv_data_dict_columns;
        REFRESH MATERIALIZED VIEW CONCURRENTLY mv_data_dict_tables;

        RAISE NOTICE 'Refresh completed at %', NOW();

        PERFORM pg_sleep(3600);
    END LOOP;
END;
$$;

CALL refresh_materialized_views();