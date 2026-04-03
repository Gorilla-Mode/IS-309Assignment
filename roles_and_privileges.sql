-- =========================================================
-- Bcycle Database: Additional Roles and Privileges
-- This script creates additional group and individual roles
-- for the Bcycle system and grants privileges based on job
-- responsibilities.
-- Prerequisite: run this script only after the base schema
-- and stored procedures have been created by db.sql/sp.sql,
-- since later GRANT statements may reference existing schema
-- objects such as tables, procedures, and the audit log.
-- Once those prerequisite objects exist, this script is safe
-- to run multiple times.
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
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = role_name) THEN
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
-- =========================================================

GRANT SELECT ON dock_audit_log TO auditor_role;
GRANT SELECT ON dock TO auditor_role;
GRANT SELECT ON station TO auditor_role;
GRANT SELECT ON stationstatus TO auditor_role;
GRANT SELECT ON trip TO auditor_role;


-- =========================================================
-- 4. GRANT EXECUTE PRIVILEGES
-- The station manager may execute the dock creation procedure
-- when expanding or maintaining station capacity.
-- =========================================================

GRANT EXECUTE ON PROCEDURE add_dock_sp(INTEGER, INTEGER, BOOLEAN) TO station_manager_role;


-- =========================================================
-- 5. CREATE INDIVIDUAL ROLES
-- These are example employee accounts. They are created only
-- if they do not already exist.
-- =========================================================

DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ola_maintenance') THEN
            CREATE ROLE ola_maintenance LOGIN PASSWORD 'Ola123!';
        END IF;
    END
$$;

DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'emma_support') THEN
            CREATE ROLE emma_support LOGIN PASSWORD 'Emma123!';
        END IF;
    END
$$;

DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lars_station_manager') THEN
            CREATE ROLE lars_station_manager LOGIN PASSWORD 'Lars123!';
        END IF;
    END
$$;

DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nina_auditor') THEN
            CREATE ROLE nina_auditor LOGIN PASSWORD 'Nina123!';
        END IF;
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
