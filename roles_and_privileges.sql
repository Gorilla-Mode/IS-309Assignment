-- =========================================================
-- Required roles
-- This part focuses on the roles required for assignment 3
-- =========================================================


-- =========================================================
-- 1. CREATE GROUP ROLES
-- These roles represent job functions in the Bcycle system.
-- They are created only if they do not already exist.
-- =========================================================

DO $$
    DECLARE
        role_name TEXT;
    BEGIN
        FOREACH role_name IN ARRAY ARRAY[
            'insight_role',                 -- a
            'bcycle_administrative_role',   -- b
            'account_administrator_role'    -- c
        ]
            LOOP
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_roles
                    WHERE rolname = role_name
                ) THEN
                    EXECUTE format('CREATE ROLE %I', role_name);
                END IF;
            END LOOP;
    END
$$;


-- =========================================================
-- 2. GRANT SCHEMA ACCESS
-- Users need USAGE on the schema to access objects inside it.
-- =========================================================

GRANT USAGE ON SCHEMA public TO insight_role;
GRANT USAGE ON SCHEMA public TO bcycle_administrative_role;
GRANT USAGE ON SCHEMA public TO account_administrator_role;

-- =========================================================
-- 3. REVOKE DEFAULT EXE3CUTE ACCESS
-- Revoke default access on procedures and functions
-- =========================================================

REVOKE EXECUTE ON PROCEDURE add_dock_sp(INT, INT, BOOLEAN) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE purchase_membership_sp(INT, VARCHAR, INT) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE create_station_sp(VARCHAR, INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, INT, VARCHAR, VARCHAR, VARCHAR) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE create_bicycle_sp(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, INT) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE create_account_sp(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE start_trip_sp(INT, INT, INT, INT) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE end_trip_sp(INT, INT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION validate_record_exists_fn(TEXT, TEXT, INT) FROM PUBLIC;


-- =========================================================
-- 4A. TABLE PRIVILEGES: INSIGHT ROLE
-- Give read only access on tables to insight role.
-- =========================================================

GRANT SELECT ON Program, Station, Dock, Rider, Membership, Bicycle, Trip, StationStatus, BicycleStatus
TO insight_role;

-- =========================================================
-- 4B. TABLE PRIVILEGES: BCYCLE ADMINISTRATIVE ROLE
-- =========================================================

GRANT EXECUTE ON FUNCTION VALIDATE_RECORD_EXISTS_FN(TEXT, TEXT, INT) TO bcycle_administrative_role;
GRANT EXECUTE ON PROCEDURE ADD_DOCK_SP(INT, INT, BOOLEAN) TO bcycle_administrative_role;
GRANT EXECUTE ON PROCEDURE PURCHASE_MEMBERSHIP_SP(INT, VARCHAR(10), INT) TO bcycle_administrative_role;
GRANT EXECUTE ON PROCEDURE CREATE_STATION_SP(VARCHAR(80), INT, VARCHAR(120), VARCHAR(120), NUMERIC(9,6), NUMERIC(9,6),
    INT, VARCHAR(20), VARCHAR(30), VARCHAR(50)) TO bcycle_administrative_role;
GRANT EXECUTE ON PROCEDURE CREATE_BICYCLE_SP(VARCHAR(10), VARCHAR(50), VARCHAR(50), VARCHAR(30), INT, INT)
    TO bcycle_administrative_role;
GRANT EXECUTE ON PROCEDURE CREATE_ACCOUNT_SP(VARCHAR(50), VARCHAR(50), VARCHAR(50), VARCHAR(30), VARCHAR(120),
    VARCHAR(20), VARCHAR(60), VARCHAR(60), VARCHAR(20))   TO bcycle_administrative_role;
GRANT EXECUTE ON PROCEDURE START_TRIP_SP(INT, INT, INT, INT) TO bcycle_administrative_role;
GRANT EXECUTE ON PROCEDURE END_TRIP_SP(INT, INT) TO bcycle_administrative_role;

-- =========================================================
-- 4C. TABLE PRIVILEGES: ACCOUNT ADMINISTRATOR ROLE
-- =========================================================

GRANT EXECUTE ON PROCEDURE CREATE_ACCOUNT_SP(VARCHAR(50), VARCHAR(50), VARCHAR(50), VARCHAR(30), VARCHAR(120),
    VARCHAR(20), VARCHAR(60), VARCHAR(60), VARCHAR(20)) TO account_administrator_role;
GRANT EXECUTE ON PROCEDURE PURCHASE_MEMBERSHIP_SP(INT, VARCHAR(10), INT) TO account_administrator_role;
GRANT EXECUTE ON PROCEDURE START_TRIP_SP(INT, INT, INT, INT) TO account_administrator_role;



-- =========================================================
-- Bcycle Database: Additional Roles and Privileges
-- This script creates additional group and individual roles
-- for the Bcycle system and grants privileges based on job
-- responsibilities.
-- The script is written to be safe to run multiple times.
-- =========================================================


-- =========================================================
-- 1. CREATE GROUP ROLES
-- These roles represent job functions in the Bcycle system.
-- They are created only if they do not already exist.
-- =========================================================

DO $$
    DECLARE
        role_name TEXT;
    BEGIN
        FOREACH role_name IN ARRAY ARRAY[
            'maintenance_role',
            'customer_support_role',
            'station_manager_role',
            'auditor_role'
            ]
            LOOP
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_roles
                    WHERE rolname = role_name
                ) THEN
                    EXECUTE format('CREATE ROLE %I', role_name);
                END IF;
            END LOOP;
    END
$$;




-- =========================================================
-- 2. GRANT SCHEMA ACCESS
-- Users need USAGE on the schema to access objects inside it.
-- =========================================================

GRANT USAGE ON SCHEMA public TO maintenance_role;
GRANT USAGE ON SCHEMA public TO customer_support_role;
GRANT USAGE ON SCHEMA public TO station_manager_role;
GRANT USAGE ON SCHEMA public TO auditor_role;




-- =========================================================
-- 3A. TABLE PRIVILEGES: MAINTENANCE ROLE
-- Technical staff responsible for bicycles and operational
-- status information.
-- =========================================================

GRANT SELECT ON bicycle TO maintenance_role;
GRANT SELECT, UPDATE ON bicyclestatus TO maintenance_role;
GRANT SELECT ON dock TO maintenance_role;
GRANT SELECT ON station TO maintenance_role;
GRANT SELECT ON stationstatus TO maintenance_role;


-- =========================================================
-- 3B. TABLE PRIVILEGES: CUSTOMER SUPPORT ROLE
-- Customer support staff responsible for assisting riders
-- with memberships and trip-related questions.
-- =========================================================

GRANT SELECT ON rider TO customer_support_role;
GRANT SELECT ON membership TO customer_support_role;
GRANT SELECT ON trip TO customer_support_role;
GRANT SELECT ON program TO customer_support_role;


-- =========================================================
-- 3C. TABLE PRIVILEGES: STATION MANAGER ROLE
-- Staff responsible for managing stations, docks, and
-- station availability.
-- =========================================================

GRANT SELECT ON station TO station_manager_role;
GRANT SELECT ON dock TO station_manager_role;
GRANT SELECT, UPDATE ON stationstatus TO station_manager_role;


-- =========================================================
-- 3D. TABLE PRIVILEGES: AUDITOR ROLE
-- Audit and control role with read-only access to log and
-- selected operational data.
-- Access to dock_audit_log is granted only if the table
-- exists, since it is created in sp.sql.
-- =========================================================

DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_class c
                     JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relname = 'dock_audit_log'
              AND n.nspname = 'public'
        ) THEN
            GRANT SELECT ON public.dock_audit_log TO auditor_role;
        END IF;
    END
$$;

GRANT SELECT ON dock TO auditor_role;
GRANT SELECT ON station TO auditor_role;
GRANT SELECT ON stationstatus TO auditor_role;
GRANT SELECT ON trip TO auditor_role;



-- =========================================================
-- 3E. TABLE PRIVILEGES: INSIGHT ROLE
-- Audit and control role with read-only access to log and
-- selected operational data.
-- Access to dock_audit_log is granted only if the table
-- exists, since it is created in sp.sql.
-- =========================================================

GRANT SELECT ON ALL TABLES IN SCHEMA public TO insight_role;

-- =========================================================
-- 4. GRANT EXECUTE PRIVILEGES
-- The station manager may execute the dock creation procedure
-- when expanding or maintaining station capacity.
-- The privilege is granted only if the procedure exists,
-- since it is created in sp.sql.
-- =========================================================

DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_proc p
                     JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE p.proname = 'add_dock_sp'
              AND n.nspname = 'public'
              AND pg_get_function_identity_arguments(p.oid) = 'integer, integer, boolean'
        ) THEN
            GRANT EXECUTE ON PROCEDURE public.add_dock_sp(INTEGER, INTEGER, BOOLEAN) TO station_manager_role;
        END IF;
    END
$$;


-- =========================================================
-- 5. CREATE INDIVIDUAL ROLES
-- These are example employee accounts. Each role is created
-- if it does not already exist, and then ALTER ROLE is run
-- unconditionally to enforce the LOGIN attribute so that
-- rerunning the script always reconciles the desired state.
--
-- SECURITY NOTE: Passwords are NOT set here to avoid storing
-- credentials in version control. After running this script,
-- set each user's password securely using ALTER ROLE, for
-- example via a local script (see set_passwords_example.sql)
-- or by running the statements interactively:
--
--   ALTER ROLE ola_maintenance       PASSWORD '<strong-password>';
--   ALTER ROLE emma_support          PASSWORD '<strong-password>';
--   ALTER ROLE lars_station_manager  PASSWORD '<strong-password>';
--   ALTER ROLE nina_auditor          PASSWORD '<strong-password>';
-- =========================================================

DO $$
    DECLARE
        user_name TEXT;
    BEGIN
        FOREACH user_name IN ARRAY ARRAY[
            'ola_maintenance',
            'emma_support',
            'lars_station_manager',
            'nina_auditor'
            ]
            LOOP
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_roles
                    WHERE rolname = user_name
                ) THEN
                    EXECUTE format('CREATE ROLE %I LOGIN', user_name);
                END IF;
                -- Enforce LOGIN regardless of whether the role was just
                -- created or already existed, ensuring idempotency.
                EXECUTE format('ALTER ROLE %I LOGIN', user_name);
            END LOOP;
    END
$$;


-- =========================================================
-- 6. ASSIGN GROUP ROLES TO INDIVIDUAL USERS
-- Each individual user inherits privileges from the
-- corresponding group role.
-- =========================================================

GRANT maintenance_role TO ola_maintenance;
GRANT customer_support_role TO emma_support;
GRANT station_manager_role TO lars_station_manager;
GRANT auditor_role TO nina_auditor;

-- =========================================================
-- 7. UNIVERSAL PRIVILEGE
-- USAGE on the public schema is granted to PUBLIC so that
-- all current and future database users can navigate the
-- schema and benefit from any role-specific privileges
-- granted to them. Without this, no object-level grant
-- has any effect.
-- =========================================================

GRANT USAGE ON SCHEMA public TO PUBLIC;
