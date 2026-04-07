-- =========================================================
-- Bcycle Database: Set User Passwords (LOCAL USE ONLY)
-- =========================================================
-- This file is a template showing how to set passwords for
-- the example login roles created by roles_and_privileges.sql.
--
-- DO NOT commit a copy of this file with real passwords.
-- Save your local copy as set_passwords_local.sql, which is
-- excluded from version control via .gitignore.
--
-- Replace every <strong-password> placeholder with a real,
-- unique password before running.
-- =========================================================

ALTER ROLE ola_maintenance       PASSWORD '<strong-password>';
ALTER ROLE emma_support          PASSWORD '<strong-password>';
ALTER ROLE lars_station_manager  PASSWORD '<strong-password>';
ALTER ROLE nina_auditor          PASSWORD '<strong-password>';
