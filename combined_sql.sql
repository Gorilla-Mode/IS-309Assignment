-- =========================================================
-- FULL DATABASE SETUP SCRIPT
-- Project: Bicycle Sharing Database
-- Description: Creates schema, procedures, roles, seed data,
--              and metadata objects.
-- =========================================================



-- =========================================================
-- SECTION 1: DATABASE STRUCTURE
-- Tables, constraints, indexes
-- =========================================================

CREATE TABLE IF NOT EXISTS Program (
                         ProgramID   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         ProgramCode VARCHAR(50) NOT NULL UNIQUE,
                         CountryCode CHAR(2) NOT NULL,
                         Name        VARCHAR(100) NOT NULL,
                         Location    VARCHAR(100),
                         Phone       VARCHAR(30),
                         Email       VARCHAR(100),
                         Timezone    VARCHAR(64),
                         URL         VARCHAR(100),
                         ShortName   VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Station (
                         StationID     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         StationCode   VARCHAR(80) NOT NULL UNIQUE,
                         ProgramID     INT NOT NULL REFERENCES Program(ProgramID),
                         Address       VARCHAR(120) NOT NULL,
                         Name          VARCHAR(120) NOT NULL,
                         Latitude      DOUBLE PRECISION NOT NULL,
                         Longitude     DOUBLE PRECISION NOT NULL,
                         Capacity      SMALLINT NOT NULL CHECK (Capacity >= 1),
                         PostalCode    VARCHAR(20),
                         ContactPhone  VARCHAR(30),
                         ShortName     VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Dock (
                      DockID        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                      StationID     INT NOT NULL REFERENCES Station(StationID) ON DELETE CASCADE,
                      DockNumber    INT NOT NULL CHECK (DockNumber >= 1),
                      IsOperational BOOLEAN NOT NULL DEFAULT TRUE,
                      UNIQUE (StationID, DockNumber)
);

CREATE TABLE IF NOT EXISTS Rider (
                       RiderID    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                       FirstName  VARCHAR(50) NOT NULL,
                       LastName   VARCHAR(50) NOT NULL,
                       Email      VARCHAR(100) NOT NULL UNIQUE,
                       Phone      VARCHAR(30),
                       Street     VARCHAR(120),
                       Apt        VARCHAR(20),
                       City       VARCHAR(60),
                       State      VARCHAR(60),
                       Zip        VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Membership (
                            MembershipID   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                            RiderID        INT NOT NULL REFERENCES Rider(RiderID) ON DELETE CASCADE,
                            MembershipType VARCHAR(10) NOT NULL CHECK (MembershipType IN ('DAY','MONTH','ANNUAL')),
                            PurchasedAt    TIMESTAMP NOT NULL,
                            ExpiresAt      TIMESTAMP NOT NULL,
                            CHECK (ExpiresAt > PurchasedAt)
);

CREATE TABLE IF NOT EXISTS Bicycle (
                         BicycleID    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         BicycleType  VARCHAR(10) NOT NULL CHECK (BicycleType IN ('ELECTRIC','SMART','CLASSIC','CARGO')),
                         Make         VARCHAR(50),
                         Model        VARCHAR(50),
                         Color        VARCHAR(30),
                         YearAcquired SMALLINT CHECK (YearAcquired IS NULL OR (YearAcquired >= 1900 AND YearAcquired <= 2100))
);

CREATE TABLE IF NOT EXISTS Trip (
                      TripID              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                      RiderID             INT NOT NULL REFERENCES Rider(RiderID),
                      BicycleID           INT NOT NULL REFERENCES Bicycle(BicycleID),
                      StartStationID      INT NOT NULL REFERENCES Station(StationID),
                      EndStationID        INT NOT NULL REFERENCES Station(StationID),
                      StartTime           TIMESTAMP NOT NULL,
                      EndTime             TIMESTAMP,
                      TotalDistance       NUMERIC(8,2) CHECK (TotalDistance IS NULL OR TotalDistance >= 0),
                      TotalElapsedSeconds INT CHECK (TotalElapsedSeconds IS NULL OR TotalElapsedSeconds >= 0),
                      TotalCost           NUMERIC(10,2) CHECK (TotalCost IS NULL OR TotalCost >= 0),
                      TripFinished        BOOLEAN NOT NULL DEFAULT TRUE
);

create index idx_trip_riderid
    on trip (riderid);

create index idx_trip_bicycleid
    on trip (bicycleid);

create index idx_trip_startstationid
    on trip (startstationid);

create index idx_trip_endstationid
    on trip (endstationid);

CREATE TABLE IF NOT EXISTS StationStatus (
                               StationStatusID     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                               StationID           INT NOT NULL REFERENCES Station(StationID) ON DELETE CASCADE,
                               ReportedAt          TIMESTAMP NOT NULL,
                               BikesAvailElectric  SMALLINT NOT NULL DEFAULT 0 CHECK (BikesAvailElectric >= 0),
                               BikesAvailClassic   SMALLINT NOT NULL DEFAULT 0 CHECK (BikesAvailClassic >= 0),
                               BikesAvailSmart     SMALLINT NOT NULL DEFAULT 0 CHECK (BikesAvailSmart >= 0),
                               BikesAvailCargo     SMALLINT NOT NULL DEFAULT 0 CHECK (BikesAvailCargo >= 0),
                               BikesAvailTotal     SMALLINT NOT NULL DEFAULT 0 CHECK (BikesAvailTotal >= 0),
                               DocksAvailTotal     SMALLINT NOT NULL DEFAULT 0 CHECK (DocksAvailTotal >= 0),
                               AcceptingReturns    BOOLEAN NOT NULL DEFAULT TRUE,
                               IsRenting           BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS BicycleStatus (
                               BicycleStatusID  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                               BicycleID        INT NOT NULL REFERENCES Bicycle(BicycleID) ON DELETE CASCADE,
                               RecordedAt       TIMESTAMP NOT NULL,
                               Status           VARCHAR(15) NOT NULL CHECK (Status IN ('AVAILABLE','IN_USE','NOT_AVAILABLE')),
                               Latitude      DOUBLE PRECISION,
                               Longitude     DOUBLE PRECISION,
                               BatteryPercent   SMALLINT CHECK (BatteryPercent IS NULL OR (BatteryPercent >= 0 AND BatteryPercent <= 100)),
                               RemainingRange   NUMERIC(6,2) CHECK (RemainingRange IS NULL OR RemainingRange >= 0)
);

-- =========================================================
-- SECTION 2: STORED PROCEDURES AND FUNCTIONS
-- Includes triggers and procedural logic
-- =========================================================

/* =====================================================
   FUNCTION
   VALIDATE_RECORD_EXISTS_FN
   Purpose:
   Verify that a record exists.
   ===================================================== */
CREATE OR REPLACE FUNCTION VALIDATE_RECORD_EXISTS_FN(
    p_table_name TEXT,
    p_column_name TEXT,
    p_value INT
)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $$
DECLARE
    v_query TEXT;
    v_result BOOLEAN;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_name = p_table_name
    ) THEN
        RAISE EXCEPTION 'Table % does not exist.', p_table_name;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE column_name = p_column_name
            AND table_name = p_table_name
    ) THEN
        RAISE EXCEPTION 'Column % does not exist in table %.', p_column_name, p_table_name;
    END IF;

    v_query := format('SELECT EXISTS (SELECT 1 FROM %I WHERE %I = $1)', p_table_name, p_column_name);
    EXECUTE v_query INTO v_result USING p_value;
    RETURN v_result;
END;
$$;

/* =====================================================
   STORED PROCEDURE
   ADD_DOCK_SP
   Purpose:
   Adds a new dock to the Dock table after verifying
   that the station exists.
   ===================================================== */
CREATE OR REPLACE PROCEDURE ADD_DOCK_SP(
    IN p_station_id INT,
    IN p_dock_number INT,
    IN p_is_operational BOOLEAN DEFAULT TRUE
)
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $$
BEGIN
    IF NOT VALIDATE_RECORD_EXISTS_FN('station', 'stationid', p_station_id) THEN
        RAISE EXCEPTION 'Station with StationID % does not exist.', p_station_id;
    END IF;

    INSERT INTO Dock (StationID, DockNumber, IsOperational)
    VALUES (p_station_id, p_dock_number, p_is_operational);

    RAISE NOTICE 'Dock added successfully for StationID %, DockNumber %.',
        p_station_id, p_dock_number;
END;
$$;

/* =====================================================
   STORED PROCEDURE
   PURCHASE_MEMBERSHIP_SP
   Purpose:
   Purchase a membership for a rider.
   ===================================================== */

CREATE OR REPLACE PROCEDURE PURCHASE_MEMBERSHIP_SP(
    IN p_rider_id INT,
    IN p_membership_type VARCHAR(10),
    OUT p_membership_id INT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_purchased_at TIMESTAMP;
    v_expires_at TIMESTAMP;
    v_existing_membership_id INT;
    v_existing_expires_at TIMESTAMP;
BEGIN
    IF NOT VALIDATE_RECORD_EXISTS_FN('rider', 'riderid', p_rider_id) THEN
        RAISE EXCEPTION 'ERR: Rider with RiderID % does not exist', p_rider_id;
    END IF;

    SELECT membershipid, expiresat
    INTO v_existing_membership_id, v_existing_expires_at
    FROM membership
    WHERE riderid = p_rider_id
      AND expiresat > CURRENT_TIMESTAMP
    LIMIT 1;

    IF p_membership_type NOT IN ('DAY', 'MONTH', 'ANNUAL') THEN
        RAISE EXCEPTION 'ERR: Invalid membership type %. Must be DAY, MONTH, or ANNUAL.', p_membership_type;
    END IF;

    v_purchased_at := CURRENT_TIMESTAMP;
    v_expires_at := CASE
        WHEN p_membership_type = 'DAY' THEN v_purchased_at + INTERVAL '1 DAY'
        WHEN p_membership_type = 'MONTH' THEN v_purchased_at + INTERVAL '1 MONTH'
        WHEN p_membership_type = 'ANNUAL' THEN v_purchased_at + INTERVAL '1 YEAR'
    END;

    IF v_existing_membership_id IS NOT NULL THEN
        UPDATE membership
        SET expiresat = v_existing_expires_at + (v_expires_at - v_purchased_at),
            membershiptype = p_membership_type
        WHERE membershipid = v_existing_membership_id
        RETURNING membershipid INTO p_membership_id;

        RAISE NOTICE 'Membership extended for riderid: %. membershipid: %. membershiptype: %.  New expiry: %', p_rider_id,
            p_membership_id, p_membership_type ,v_existing_expires_at + (v_expires_at - v_purchased_at);
    ELSE
        INSERT INTO membership (riderid, membershiptype, purchasedat, expiresat)
        VALUES (p_rider_id, p_membership_type, v_purchased_at, v_expires_at)
        RETURNING membershipid INTO p_membership_id;

        RAISE NOTICE 'New membership for riderid: %. membershipid: %. expiry: %', p_rider_id, p_membership_id,
        v_expires_at;
    END IF;
END;
$$;

/* =====================================================
   STORED PROCEDURE
   CREATE_STATION_SP
   Purpose:
   Create a new station.
   ===================================================== */


CREATE OR REPLACE PROCEDURE CREATE_STATION_SP(
    IN p_station_code VARCHAR(80),
    IN p_program_id INT,
    IN p_address VARCHAR(120),
    IN p_name VARCHAR(120),
    IN p_latitude NUMERIC(9,6),
    IN p_longitude NUMERIC(9,6),
    IN p_capacity INT,
    IN p_postalcode VARCHAR(20) DEFAULT NULL,
    IN p_contactphone VARCHAR(30) DEFAULT NULL,
    IN p_shortname VARCHAR(50) DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_station_id INT;
BEGIN
    IF NOT VALIDATE_RECORD_EXISTS_FN('program', 'programid', p_program_id) THEN
        RAISE EXCEPTION 'ERR: Program with ProgramID % does not exist', p_program_id;
    END IF;

    INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
    VALUES (p_station_code, p_program_id, p_address, p_name, p_latitude,
            p_longitude, p_capacity, p_postalcode, p_contactphone, p_shortname);

    SELECT stationid INTO v_station_id
    FROM station
    WHERE stationcode = p_station_code;

    RAISE NOTICE 'Station created successfully. StationID: %, Name: %, Code: %', v_station_id, p_name, p_station_code;
END;
$$;

/* =====================================================
   STORED PROCEDURE
   CREATE_BICYCLE_SP
   Purpose:
   Create a new bicycle.
   ===================================================== */


CREATE OR REPLACE PROCEDURE CREATE_BICYCLE_SP(
    IN p_bicycle_type VARCHAR(10),
    IN p_make VARCHAR(50),
    IN p_model VARCHAR(50),
    IN p_color VARCHAR(30),
    IN p_year_acquired INT,
    OUT p_bicycle_id INT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF p_bicycle_type IS NULL THEN
        RAISE EXCEPTION 'ERR: p_bicycle_type cannot be NULL';
    END IF;

    IF p_bicycle_type NOT IN ('ELECTRIC', 'SMART', 'CLASSIC', 'CARGO') THEN
        RAISE EXCEPTION 'ERR: Invalid bicycle type %. Must be ELECTRIC, SMART, CLASSIC, or CARGO.', p_bicycle_type;
    END IF;

    INSERT INTO bicycle (bicycletype, make, model, color, yearacquired)
    VALUES (p_bicycle_type, p_make, p_model, p_color, p_year_acquired)
    RETURNING bicycleid INTO p_bicycle_id;

    RAISE NOTICE 'Bicycle created successfully. BicycleID: %', p_bicycle_id;
END;
$$;

/* =====================================================
   STORED PROCEDURE
   CREATE_ACCOUNT_SP
   Purpose:
   Create a new account.
   ===================================================== */

CREATE OR REPLACE PROCEDURE CREATE_ACCOUNT_SP(
    IN p_first_name VARCHAR(50),
    IN p_last_name  VARCHAR(50),
    IN p_email      VARCHAR(50),
    IN p_phone      VARCHAR(30),
    IN p_street     VARCHAR(120),
    IN p_apt        VARCHAR(20),
    IN p_city       VARCHAR(60),
    IN p_state      VARCHAR(60),
    IN p_zip        VARCHAR(20),
    OUT p_account_id INT
) LANGUAGE plpgsql
    SECURITY DEFINER
AS $$
DECLARE
    v_existing_email INT;
BEGIN
    IF p_first_name IS NULL OR p_last_name IS NULL OR p_email IS NULL THEN
        RAISE EXCEPTION 'Parameters p_first_name, p_last_name, p_email can not be NULL';
    end if;

    SELECT count(*) INTO v_existing_email FROM rider where email = p_email;
    IF v_existing_email != 0 THEN
        RAISE EXCEPTION 'Account already exist with email address %', v_existing_email;
    end if;

    INSERT INTO rider (firstname, lastname, email, phone, street, apt, city, state, zip) VALUES
        (p_first_name, p_last_name, p_email, p_phone, p_street, p_apt,
         p_city, p_state, p_zip)
    RETURNING riderid INTO p_account_id;
END;
$$;

/* =====================================================
   STORED PROCEDURE
   START_TRIP_SP
   Purpose:
   Adds a new Trip to the Trip table after checking the rider, bicycle and station is verified
   Returns: The identifier of the new trip
   ===================================================== */
CREATE OR REPLACE PROCEDURE START_TRIP_SP(
    IN p_rider_id INT,
    IN p_start_station_id INT,
    IN p_start_station_dock_id INT,
    IN p_bicycle_id INT
)
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $$
    DECLARE
        latest_status TEXT;
        bicycle_type TEXT;
        p_trip_id INT;
-- region START_TRIP_SP validations

/* Checks if the station exists, not just a random station */
BEGIN
    IF (NOT VALIDATE_RECORD_EXISTS_FN('station', 'stationid', p_start_station_id)) THEN
        RAISE EXCEPTION 'Station with StationID % does not exist.', p_start_station_id;
END IF;

    /* Checks if the dock exists, not just a random dock */

        IF NOT EXISTS (
            SELECT 1
            FROM dock
            WHERE stationid = p_start_station_id
            AND docknumber = p_start_station_dock_id
            ) THEN
        RAISE EXCEPTION 'Dock % does not belong to StationID %.',
            p_start_station_dock_id, p_start_station_id;
    END IF;

/* Checks if the Bicycle exists */

    IF (NOT VALIDATE_RECORD_EXISTS_FN('bicycle', 'bicycleid', p_bicycle_id)) THEN
        RAISE EXCEPTION 'Bicycle with BicycleID % does not exist.', p_bicycle_id;
END IF;
/* Checks if the Bicycle is AVAILABLE */
    BEGIN
        SELECT status INTO latest_status
        FROM bicyclestatus
        WHERE bicycleid = p_bicycle_id
        ORDER BY recordedat DESC
        LIMIT 1;

        IF latest_status IS DISTINCT FROM 'AVAILABLE' THEN
            RAISE EXCEPTION 'BicycleID % is not AVAILABLE in the newest record', p_bicycle_id;
        END IF;
    END;
/* Checks if the rider exists */

    IF NOT VALIDATE_RECORD_EXISTS_FN('rider', 'riderid', p_rider_id) THEN
        RAISE EXCEPTION 'Rider with RiderID % does not exist.', p_start_station_id;
    END IF;

/* Checks if the stationstatus is renting bicycles */

    IF NOT (SELECT isrenting
       FROM stationstatus
       WHERE stationstatusid = p_start_station_id) THEN
       RAISE EXCEPTION 'Station with StationID % is not renting bicycles.', p_start_station_id;
    END IF;

/* Checks if the specified dock of that station is operational */

    IF NOT (
    SELECT isoperational
    FROM dock
    WHERE stationid = p_start_station_id
      AND docknumber = p_start_station_dock_id
    ) THEN
    RAISE EXCEPTION 'Dock % at station % is not operational.', p_start_station_dock_id, p_start_station_id;
    END IF;

/* Checks if the bicycle classic is available at the specified station */

-- Get selected bike type once
    SELECT bicycletype
    INTO bicycle_type
    FROM bicycle
    WHERE bicycleid = p_bicycle_id;

    -- Check availability based on bike type
    CASE bicycle_type
        WHEN 'CLASSIC' THEN
            IF (SELECT bikesavailclassic FROM stationstatus WHERE stationstatusid = p_start_station_id) <= 0 THEN
                RAISE EXCEPTION 'No CLASSIC bikes available at station %.', p_start_station_id;
            END IF;
        WHEN 'ELECTRIC' THEN
            IF (SELECT bikesavailelectric FROM stationstatus WHERE stationstatusid = p_start_station_id) <= 0 THEN
                RAISE EXCEPTION 'No ELECTRIC bikes available at station %.', p_start_station_id;
            END IF;
        WHEN 'SMART' THEN
            IF (SELECT bikesavailsmart FROM stationstatus WHERE stationstatusid = p_start_station_id) <= 0 THEN
                RAISE EXCEPTION 'No SMART bikes available at station %.', p_start_station_id;
            END IF;
        WHEN 'CARGO' THEN
            IF (SELECT bikesavailcargo FROM stationstatus WHERE stationstatusid = p_start_station_id) <= 0 THEN
                RAISE EXCEPTION 'No CARGO bikes available at station %.', p_start_station_id;
            END IF;
        ELSE
            RAISE EXCEPTION 'Unsupported bicycle type: %', bicycle_type;
        END CASE;
-- endregion

    /* Removes one of the available bikes from stationstatus since you will be using it (Based on the category of bike you chose) */
    BEGIN
        IF bicycle_type = 'CLASSIC' THEN
            UPDATE stationstatus
            SET bikesavailclassic = bikesavailclassic - 1
            WHERE stationstatusid = p_start_station_id;
        ELSIF bicycle_type = 'ELECTRIC' THEN
            UPDATE stationstatus
            SET bikesavailelectric = bikesavailelectric - 1
            WHERE stationstatusid = p_start_station_id;
        ELSIF bicycle_type = 'SMART' THEN
            UPDATE stationstatus
            SET bikesavailsmart = bikesavailsmart - 1
            WHERE stationstatusid = p_start_station_id;
        ELSIF bicycle_type = 'CARGO' THEN
            UPDATE stationstatus
            SET bikesavailcargo = bikesavailcargo - 1
            WHERE stationstatusid = p_start_station_id;
        END IF;
    END;

    -- Insert into the TRIP table (Main Task)
INSERT INTO trip (
    riderid,
    bicycleid,
    startstationid,
    starttime,
    tripfinished,
    endstationid
)
VALUES (p_rider_id,
        p_bicycle_id,
        p_start_station_id,
        CURRENT_TIMESTAMP,
        FALSE,
        p_start_station_id) -- Placeholder for endstationid since the trip is just starting
        RETURNING tripid INTO p_trip_id;

    RAISE NOTICE 'Trip started successfully. TripID: %', p_trip_id;

        -- Create a new bicyclestatus record to mark the bike as IN_USE
        INSERT INTO bicyclestatus (bicycleid, recordedat, status)
        VALUES (p_bicycle_id, CURRENT_TIMESTAMP, 'IN_USE');

END;
$$;

/* =====================================================
   STORED PROCEDURE
   END_TRIP_SP
   Purpose:
   Updates an existing Trip in the Trip table after checking the trip is valid and calculating the total distance, elapsed time and cost.
   Returns: ###
   ===================================================== */
CREATE OR REPLACE PROCEDURE END_TRIP_SP(
    IN p_trip_id INT,
    IN p_end_station_id INT
)
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $$
DECLARE
    v_bicycle_id INT;
    v_start_station_id INT;
    v_bicycle_type TEXT;
BEGIN
    -- Check trip exists
    IF NOT VALIDATE_RECORD_EXISTS_FN('trip', 'tripid', p_trip_id) THEN
        RAISE EXCEPTION 'Trip with TripID % does not exist.', p_trip_id;
    END IF;

    -- Check destination station exists
    IF NOT VALIDATE_RECORD_EXISTS_FN('station', 'stationid', p_end_station_id) THEN
        RAISE EXCEPTION 'Station with StationID % does not exist.', p_end_station_id;
    END IF;

    -- Check trip not already finished
    IF (SELECT tripfinished FROM trip WHERE tripid = p_trip_id) THEN
        RAISE EXCEPTION 'Trip with TripID % is already finished.', p_trip_id;
    END IF;

    -- Get bike and original start station from trip
    SELECT bicycleid, startstationid
    INTO v_bicycle_id, v_start_station_id
    FROM trip
    WHERE tripid = p_trip_id;

    -- Check destination station accepts returns
    IF NOT (SELECT acceptingreturns
            FROM stationstatus
            WHERE stationstatusid = p_end_station_id) THEN
        RAISE EXCEPTION 'Station with StationID % is not accepting returns.', p_end_station_id;
    END IF;

    -- Finish trip
    UPDATE trip
    SET endtime = CURRENT_TIMESTAMP,
        tripfinished = TRUE,
        endstationid = p_end_station_id
    WHERE tripid = p_trip_id;

    RAISE NOTICE 'Trip with TripID % has been marked as finished.', p_trip_id;

    -- Get bike type
    SELECT bicycletype
    INTO v_bicycle_type
    FROM bicycle
    WHERE bicycleid = v_bicycle_id;

    -- Add returned bike to END station availability (not start station)
    IF v_bicycle_type = 'CLASSIC' THEN
        UPDATE stationstatus
        SET bikesavailclassic = bikesavailclassic + 1
        WHERE stationstatusid = p_end_station_id;
    ELSIF v_bicycle_type = 'ELECTRIC' THEN
        UPDATE stationstatus
        SET bikesavailelectric = bikesavailelectric + 1
        WHERE stationstatusid = p_end_station_id;
    ELSIF v_bicycle_type = 'SMART' THEN
        UPDATE stationstatus
        SET bikesavailsmart = bikesavailsmart + 1
        WHERE stationstatusid = p_end_station_id;
    ELSIF v_bicycle_type = 'CARGO' THEN
        UPDATE stationstatus
        SET bikesavailcargo = bikesavailcargo + 1
        WHERE stationstatusid = p_end_station_id;
    END IF;

    -- Mark bike available
    INSERT INTO bicyclestatus (bicycleid, recordedat, status)
    VALUES (v_bicycle_id, CURRENT_TIMESTAMP, 'AVAILABLE');
END;
$$;

/* =====================================================
   ROW-LEVEL TRIGGER FUNCTION
   check_dock_capacity_fn
   Purpose:
   Prevents inserting more docks for a station than
   the station's defined capacity.
   ===================================================== */
CREATE OR REPLACE FUNCTION check_dock_capacity_fn()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $$
DECLARE
    v_capacity INT;
    v_current_docks INT;
BEGIN
    SELECT capacity
    INTO v_capacity
    FROM public.station
    WHERE stationid = NEW.stationid;

    IF v_capacity IS NULL THEN
        RAISE EXCEPTION 'Station with StationID % does not exist.', NEW.stationid;
    END IF;

    SELECT COUNT(*)
    INTO v_current_docks
    FROM public.dock
    WHERE stationid = NEW.stationid;

    IF v_current_docks >= v_capacity THEN
        RAISE EXCEPTION 'Cannot add dock. StationID % already has maximum number of docks (%).',
            NEW.stationid, v_capacity;
    END IF;

    RETURN NEW;
END;
$$;

/* =====================================================
   ROW-LEVEL TRIGGER
   trg_check_dock_capacity
   Executes the capacity check for every inserted row.
   ===================================================== */
CREATE OR REPLACE TRIGGER trg_check_dock_capacity
    BEFORE INSERT ON public.dock
    FOR EACH ROW
EXECUTE FUNCTION check_dock_capacity_fn();


CREATE TABLE IF NOT EXISTS public.dock_audit_log (
                                                     logid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                                     action_type VARCHAR(10) NOT NULL,
                                                     action_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                     table_name VARCHAR(50) NOT NULL
);

CREATE OR REPLACE FUNCTION log_dock_statement_fn()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.dock_audit_log (action_type, action_time, table_name)
    VALUES (TG_OP, CURRENT_TIMESTAMP, 'dock');

    RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER trg_log_dock_statement
    AFTER INSERT OR UPDATE OR DELETE ON public.dock
    FOR EACH STATEMENT
EXECUTE FUNCTION log_dock_statement_fn();

-- Docs
COMMENT ON FUNCTION VALIDATE_RECORD_EXISTS_FN(p_table_name TEXT, p_column_name TEXT, p_value INT) IS
'Checks if a given value exists in a given column of a given table.
Params:
    p_table_name: The name of the table to check.
    p_column_name: The name of the column to check.
    p_value: The value to check against.
Raises:
    Exception: If the table not exist.
    Exception: If the column does not exist in the table.
Returns:
    TRUE if the record exists, FALSE otherwise.
';


COMMENT ON PROCEDURE ADD_DOCK_SP(p_station_id INT, p_dock_number INT, p_is_operational BOOLEAN) IS
'Checks if a given value exists in a given column of a given table.
Params:
    p_station_id: The station of the dock.
    p_dock_number: The number of the dock.
    p_is_operational: If the dock is operational or not. True by default.
Raises:
    Exception: If the station doesn''t exist
    Notice: If the dock was successfully added to the station.
Returns:
    TRUE if the record exists, FALSE otherwise.';



COMMENT ON PROCEDURE PURCHASE_MEMBERSHIP_SP(INT, VARCHAR, INT) IS
'Purchases or extends a membership for a rider, if the rider selects a new membership type it is updated.
Params:
    p_rider_id: The ID of the rider to purchase membership for.
    p_membership_type: The type of membership to purchase. Must be DAY, MONTH, or ANNUAL.
Returns:
    p_membership_id: The ID of the membership that was purchased or extended.
Raises:
    Exception: If the rider does not exist.
    Exception: If the membership type is invalid.
    ';


COMMENT ON PROCEDURE CREATE_STATION_SP(VARCHAR, INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, INT, VARCHAR, VARCHAR, VARCHAR) IS
'Creates a new station.
Params:
    p_station_code: The unique code for the station.
    p_program_id: The ID of the program the station belongs to.
    p_address: The address of the station.
    p_name: The name of the station.
    p_latitude: The latitude of the station.
    p_longitude: The longitude of the station.
    p_capacity: The maximum number of docks the station can hold.
    p_postalcode: The postal code of the station.
    p_contactphone: The contact phone number of the station.
    p_shortname: The short name of the station.
 Raises:
    Exception: If the program does not exist.
';


COMMENT ON PROCEDURE CREATE_BICYCLE_SP(p_bicycle_type VARCHAR(10), p_make VARCHAR(50), p_model VARCHAR(50), p_color VARCHAR(30), p_year_acquired INT, p_bicycle_id INT) IS
'Creates a new bicycle.
Params:
    p_bicycle_type: The type of bicycle of the bike.
    p_make: The maker of the bike.
    p_model: The model of the bike.
    p_color: The color of the bike.
    p_year_acquired: The year the bike was acquired.
 Raises:
    Exception: If the bicycle type does not exist, or is not one of the allowed ones.
';


COMMENT ON PROCEDURE CREATE_ACCOUNT_SP(p_first_name VARCHAR(50), p_last_name VARCHAR(50), p_email VARCHAR(50),
    p_phone VARCHAR(30), p_street VARCHAR(120), p_apt VARCHAR(20), p_city VARCHAR(60), p_state VARCHAR(60), p_zip VARCHAR(20), p_account_id INT) IS
'Creates a new rider account.
Params:
    p_first_name: The first name of the rider.
    p_last_name: The last name of the rider.
    p_email: The email of the rider. Has to be unique.
    p_phone: The phone number of the rider.
    p_street: The street of the rider.
    p_apt: The apartment number of the rider.
    p_city: The city of the rider.
    p_state: The state of residency of the rider.
    p_zip: The zip code of residency of the rider.
 Raises:
    Exception: If no p_first_name, p_last_name, or p_email was provided, or if an account already exists with the given email address.
';


COMMENT ON PROCEDURE START_TRIP_SP(p_rider_id INT, p_start_station_id INT, p_start_station_dock_id INT, p_bicycle_id INT) IS
'Starts a new trip
Params:
    p_rider_id: The id of the rider doing the trip.
    p_start_station_id: The id of the starting station of the trip.
    p_start_station_dock_id: THe id of the dock at starting starting station.
    p_bicycle_id: The id of the bicycle to start the trip with.
 Raises:
    Exception:
        - if the given station id refers to a non-existing station
        - if the given dock id refers to a non-existing dock
        - if the given bicycle refers to a non-existing, or unavailable bicycle
        - if the given rider id refers to a non-existing rider
        - if the given station''s status is accepting renting right now
        - if the given dock is not operation
        - if the type of the given bicycle is not available at the start station
';

COMMENT ON PROCEDURE END_TRIP_SP(p_trip_id INT, p_end_station_id INT) IS
'Ends a started trip.
Params:
    p_trip_id: The id of the trip to end.
    p_end_station_id: The id of the station at which the trip is ending.

 Raises:
    Exception:
        - if the given trip id doesn''t exist, or the trip is already finished
        - if the given end station doesn''t exist, or doesn''t accept returns
';


COMMENT ON FUNCTION check_dock_capacity_fn() IS
'Trigger function to check that a station''s capacity for docks is respected
Params:
    row that is about to be inserted in table dock

 Raises:
    Exception:
        - if the station in which the row was to be inserted doesn''t exist
        - if adding one more dock would exceed the station''s capacity';


COMMENT ON FUNCTION log_dock_statement_fn() IS
'Trigger function to log actions made on table dock
Params:
    row that is about to be inserted in table dock

 Raises:
    nothing';



-- =========================================================
-- SECTION 3: ROLES AND PRIVILEGES
-- User roles and access permissions
-- =========================================================

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


-- =========================================================
-- SECTION 4: SEED DATA
-- Initial test data
-- =========================================================

-- AI has been used to duplicate inserts with different values, based on the first insert into a table which has been written by hand.

INSERT INTO program (programcode, countrycode, name, location, phone, email, timezone, url, shortname)
VALUES ('KRS', 'NO', 'Kristiansand Sykkel & Co', 'Kristiansand', '+47 67767670',
        'Krs-Sykkeco@Gmail.com', 'UTC+1', 'https://www.krs.no', 'KrsSC')
ON CONFLICT (programcode) DO NOTHING;

INSERT INTO program (programcode, countrycode, name, location, phone, email, timezone, url, shortname)
VALUES ('OSL', 'NO', 'Oslo Bike Share', 'Oslo', '+47 22113300', 'info@oslobikeShare.no',
        'UTC+1', 'httsp://www.oslobikeShare.no', 'OSBS')
ON CONFLICT (programcode) DO NOTHING;

INSERT INTO program (programcode, countrycode, name, location, phone, email, timezone, url, shortname)
VALUES ('STO', 'SE', 'Stockholm Cycling Network', 'Stockholm', '+46 850808000',
        'support@stockholmcycling.se', 'UTC+1', 'https://www.stockholmcycling.se', 'SCN')
ON CONFLICT (programcode) DO NOTHING;

INSERT INTO program (programcode, countrycode, name, location, phone, email, timezone, url, shortname)
VALUES ('CPH', 'DK', 'Copenhagen Bike Hub', 'Copenhagen', '+45 33335555',
        'contact@copenhagenBikeHub.dk', 'UTC+1', 'https://www.copenhagenBikeHub.dk', 'CBH')
ON CONFLICT (programcode) DO NOTHING;



-- ProgramId assumes that the first program, KRS, is 1, and so on...
-- Kristiansand stations
INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('KRS001', 1, 'Dronningens Gate 12', 'Dronningens Gate' , 58.148889,
        8.273889, 100, '4608', '+47 67767670', 'Dronningens')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('KRS002', 1, 'Markens Gate 45', 'Markens Gate', 58.149500, 8.275500,
        85, '4610', '+47 67767670', 'Markens')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('KRS003', 1, 'Tollbodgaten 8', 'Tollbodgaten', 58.151200, 8.280000,
        120, '4605', '+47 67767670', 'Tollbod')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('KRS004', 1, 'Valørveien 22', 'Valørveien', 58.147500, 8.268500,
        95, '4620', '+47 67767670', 'Valørveien')
ON CONFLICT (stationcode) DO NOTHING;


-- Oslo stations
INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('OSL001', 2, 'Karl Johans Gate 31', 'Karl Johans Gate', 59.914453, 10.735857,
        110, '0160', '+47 22113300', 'KarlJohans')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('OSL002', 2, 'Jernbanetorget 1', 'Jernbanetorget', 59.911265, 10.750890,
        130, '0154', '+47 22113300', 'Jernbanetorget')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('OSL003', 2, 'Ferner Jacobsens Plass 5', 'Ferner Jacobsens Plass', 59.916244,
        10.752158, 100, '0161', '+47 22113300', 'FernerJacobsens')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('OSL004', 2, 'Stortinget 18', 'Stortinget', 59.915720, 10.734480,
        105, '0161', '+47 22113300', 'Stortinget')
ON CONFLICT (stationcode) DO NOTHING;


-- Stockholm stations
INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('STO001', 3, 'Sergels Torg 12', 'Sergels Torg', 59.332889, 18.063889,
        115, '10010', '+46 850808000', 'SergelsTorg')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('STO002', 3, 'Gamla Stan 3', 'Gamla Stan', 59.326389, 18.070278,
        90, '10130', '+46 850808000', 'GamlaStan')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('STO003', 3, 'Norrmalm Street 45', 'Norrmalm', 59.334722, 18.073611,
        125, '10220', '+46 850808000', 'Norrmalm')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('STO004', 3, 'Kungsträdgården 7', 'Kungsträdgården', 59.330556, 18.076389,
        100, '10020', '+46 850808000', 'Kungtradgarden')
ON CONFLICT (stationcode) DO NOTHING;


-- Copenhagen stations
INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('CPH001', 4, 'Nyhavn 2', 'Nyhavn', 55.679722, 12.591667, 120,
        '1051', '+45 33335555', 'Nyhavn')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('CPH002', 4, 'Strøget 50', 'Strøget', 55.682222, 12.573611, 135,
        '1001', '+45 33335555', 'Stroget')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('CPH003', 4, 'Kongens Nytorv 8', 'Kongens Nytorv', 55.679444, 12.584722,
        105, '1050', '+45 33335555', 'KongeNytorv')
ON CONFLICT (stationcode) DO NOTHING;

INSERT INTO station (stationcode, programid, address, name, latitude, longitude, capacity, postalcode, contactphone, shortname)
VALUES ('CPH004', 4, 'Amagertorv 15', 'Amagertorv', 55.681944, 12.575556, 110,
        '1160', '+45 33335555', 'Amagertorv')
ON CONFLICT (stationcode) DO NOTHING;


-- Kristiansand docks
INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (1, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (1, 2, false)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (2, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (3, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (3, 2, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (3, 3, false)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (4, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

-- Oslo docks
INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (5, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (5, 2, false)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (6, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (6, 2, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (6, 3, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (7, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (8, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (8, 2, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

-- Stockholm docks
INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (9, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (10, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (10, 2, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (11, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (11, 2, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (11, 3, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (12, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

-- Copenhagen docks
INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (13, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (13, 2, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (14, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (15, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (15, 2, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (15, 3, false)
ON CONFLICT (stationid, docknumber) DO NOTHING;

INSERT INTO dock (stationid, docknumber, isoperational)
VALUES (16, 1, true)
ON CONFLICT (stationid, docknumber) DO NOTHING;



start transaction;
    -- Available set as 0 initally, calculated before commit, because I don't wanna do it myself.
    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                               bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
    VALUES (1, now(), 5, 3, 0, 5, 0,
            20, true, false)
    ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (2, now(), 4, 10, 2, 8, 0,
                40, true, false)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (3, now(), 6, 4, 2, 6, 0,
                30, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (4, now(), 3, 2, 0, 4, 0,
                15, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (5, now(), 5, 3, 1, 4, 0,
                22, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (6, now(), 7, 5, 2, 6, 0,
                35, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (7, now(), 4, 2, 1, 3, 0,
                18, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (8, now(), 5, 3, 0, 5, 0,
                25, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (9, now(), 5, 4, 1, 5, 0,
                28, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (10, now(), 4, 3, 1, 4, 0,
                20, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (11, now(), 6, 5, 2, 6, 0,
                38, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (12, now(), 4, 2, 0, 4, 0,
                16, true, false)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (13, now(), 5, 4, 1, 5, 0,
                24, false, false)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (14, now(), 6, 5, 2, 6, 0,
                32, false, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (15, now(), 5, 3, 1, 5, 0,
                26, true, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    INSERT INTO stationstatus (stationid, reportedat, bikesavailelectric, bikesavailclassic, bikesavailsmart, bikesavailcargo,
                                   bikesavailtotal, docksavailtotal, acceptingreturns, isrenting)
        VALUES (16, now(), 3, 2, 0, 3, 0,
                14, false, true)
        ON CONFLICT (stationstatusid) DO NOTHING;

    UPDATE stationstatus SET bikesavailtotal = (bikesavailclassic + bikesavailsmart + bikesavailcargo + bikesavailelectric)
    WHERE TRUE; --DGAF do it on all rows
commit;


INSERT INTO rider (firstname, lastname, email, phone, street, apt, city, state, zip)
VALUES ('Gandalf', 'the Grey', 'GandalfBeast@gmail.com', '+47 12345678', 'Glamdring Gate 1',
        '', 'Hobbiton', 'The Shire', 0000)
ON CONFLICT (email) DO NOTHING;

INSERT INTO rider (firstname, lastname, email, phone, street, apt, city, state, zip)
VALUES ('Aragorn', 'Strider', 'AragornKing@gmail.com', '+47 98765432', 'Ranger Road 42',
        'Apt 5', 'Rivendell', 'Elves', 1234)
ON CONFLICT (email) DO NOTHING;

INSERT INTO rider (firstname, lastname, email, phone, street, apt, city, state, zip)
VALUES ('Legolas', 'Greenleaf', 'LegolasArcher@gmail.com', '+46 87654321', 'Mirkwood Street 15',
        '12b', 'Minas Tirith', 'SE', 1111)
ON CONFLICT (email) DO NOTHING;

INSERT INTO rider (firstname, lastname, email, phone, street, apt, city, state, zip)
VALUES ('Gimli', 'Lockbearer', 'GimliAxe@gmail.com', '+45 55443322', 'Dwarven Mine Lane 88',
        'Hall 3', 'Helms Deep', 'DK', 2020)
ON CONFLICT (email) DO NOTHING;

INSERT INTO rider (firstname, lastname, email, phone, street, apt, city, state, zip)
VALUES ('Frodo', 'Baggins', 'FrodoBaggins@gmail.com', '+47 44556677', 'Bag End Lane 99',
        '', 'Oslo', 'NO', 3333)
ON CONFLICT (email) DO NOTHING;


INSERT INTO membership (riderid, membershiptype, purchasedat, expiresat)
VALUES (1, 'MONTH', now(), now() + INTERVAL '1 month')
ON CONFLICT (membershipid) DO NOTHING;

INSERT INTO membership (riderid, membershiptype, purchasedat, expiresat)
VALUES (2, 'ANNUAL', now(), now() + INTERVAL '1 year')
ON CONFLICT (membershipid) DO NOTHING;

INSERT INTO membership (riderid, membershiptype, purchasedat, expiresat)
VALUES (3, 'DAY', now(), now() + INTERVAL '1 day')
ON CONFLICT (membershipid) DO NOTHING;

INSERT INTO membership (riderid, membershiptype, purchasedat, expiresat)
VALUES (4, 'MONTH', now(), now() + INTERVAL '1 month')
ON CONFLICT (membershipid) DO NOTHING;

INSERT INTO membership (riderid, membershiptype, purchasedat, expiresat)
VALUES (5, 'ANNUAL', now(), now() + INTERVAL '1 year')
ON CONFLICT (membershipid) DO NOTHING;



INSERT INTO bicycle (bicycletype, make, model, color, yearacquired)
VALUES ('ELECTRIC', 'Beast Bikes', 'Mega Beast 67', 'Black', 2025)
ON CONFLICT (bicycleid) DO NOTHING;

INSERT INTO bicycle (bicycletype, make, model, color, yearacquired)
VALUES ('SMART', 'Tech Cycles', 'SmartRide Pro', 'Silver', 2025)
ON CONFLICT (bicycleid) DO NOTHING;

INSERT INTO bicycle (bicycletype, make, model, color, yearacquired)
VALUES ('CLASSIC', 'Heritage Bikes', 'Vintage Cruiser', 'Red', 2024)
ON CONFLICT (bicycleid) DO NOTHING;

INSERT INTO bicycle (bicycletype, make, model, color, yearacquired)
VALUES ('CARGO', 'LoadMaster', 'CargoMax 3000', 'Blue', 2025)
ON CONFLICT (bicycleid) DO NOTHING;


INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (1, now() - INTERVAL '1 day', 'AVAILABLE', 59.938043, 10.752216,
        67, 6.7)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (1, now() - INTERVAL '12 hours', 'IN_USE', 59.920000, 10.760000,
        45, 4.5)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (1, now() - INTERVAL '2 hours', 'AVAILABLE', 59.925000, 10.755000,
        85, 8.5)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (2, now() - INTERVAL '20 hours', 'AVAILABLE', 59.911265, 10.750890,
        null, NULL)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (2, now() - INTERVAL '8 hours', 'NOT_AVAILABLE', 59.915720, 10.734480,
        NULL, NULL)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (2, now() - INTERVAL '1 hour', 'AVAILABLE', 59.914453, 10.735857,
        NULL, NULL)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (3, now() - INTERVAL '18 hours', 'AVAILABLE', 59.326389, 18.070278,
        NULL, NULL)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (3, now() - INTERVAL '6 hours', 'IN_USE', 59.332889, 18.063889,
        NULL, NULL)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (3, now() - INTERVAL '30 minutes', 'AVAILABLE', 59.330556, 18.076389,
        NULL, NULL)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (4, now() - INTERVAL '16 hours', 'AVAILABLE', 55.679722, 12.591667,
        NULL, NULL)
ON CONFLICT (bicyclestatusid) DO NOTHING;

INSERT INTO bicyclestatus (bicycleid, recordedat, status, latitude, longitude, batterypercent, remainingrange)
VALUES (4, now() - INTERVAL '5 hours', 'NOT_AVAILABLE', 55.682222, 12.573611,
        NULL, NULL)
ON CONFLICT (bicyclestatusid) DO NOTHING;



start transaction;
    INSERT INTO trip (riderid, bicycleid, startstationid, endstationid, starttime, endtime, totaldistance, totalelapsedseconds,
                      totalcost)
    VALUES (1, 1, 1, 2, now() - INTERVAL '2 hours', now() - INTERVAL '1 hour',
            1500, 0, 1000)
    ON CONFLICT (tripid) DO NOTHING;

    INSERT INTO trip (riderid, bicycleid, startstationid, endstationid, starttime, endtime, totaldistance, totalelapsedseconds,
                      totalcost)
    VALUES (2, 2, 1, 3, now() - INTERVAL '3 hours', now() - INTERVAL '2.75 hours',
            2500, 0, 1500)
    ON CONFLICT (tripid) DO NOTHING;

    INSERT INTO trip (riderid, bicycleid, startstationid, endstationid, starttime, endtime, totaldistance, totalelapsedseconds,
                      totalcost)
    VALUES (3, 3, 5, 7, now() - INTERVAL '4 hours', now() - INTERVAL '3.5 hours',
            3000, 0, 1800)
    ON CONFLICT (tripid) DO NOTHING;

    INSERT INTO trip (riderid, bicycleid, startstationid, endstationid, starttime, endtime, totaldistance, totalelapsedseconds,
                      totalcost)
    VALUES (4, 1, 9, 11, now() - INTERVAL '5 hours', now() - INTERVAL '4.5 hours',
            2200, 0, 1400)
    ON CONFLICT (tripid) DO NOTHING;

    INSERT INTO trip (riderid, bicycleid, startstationid, endstationid, starttime, endtime, totaldistance, totalelapsedseconds,
                      totalcost)
    VALUES (5, 4, 13, 15, now() - INTERVAL '6 hours', now() - INTERVAL '5.75 hours',
            1800, 0, 1200)
    ON CONFLICT (tripid) DO NOTHING;

    UPDATE trip SET totalelapsedseconds = EXTRACT(EPOCH FROM (endtime - starttime)) where TRUE; --still DGAF do it on all rows
commit;

/* If you want more data for the trip table
 INSERT INTO trip (
    riderid, bicycleid, startstationid, endstationid,
    starttime, endtime, totaldistance, totalelapsedseconds, totalcost
)
SELECT
    r.riderid,
    b.bicycleid,
    s1.stationid AS startstationid,
    s2.stationid AS endstationid,
    now() - (random() * interval '10 hours') AS starttime,
    now() - (random() * interval '5 hours') AS endtime,
    (random() * 5000)::int AS totaldistance,
    0 AS totalelapsedseconds,
    (random() * 2000)::int AS totalcost
FROM generate_series(1, 1000) g
         CROSS JOIN LATERAL (
    SELECT riderid FROM rider ORDER BY random() LIMIT 1
    ) r
         CROSS JOIN LATERAL (
    SELECT bicycleid FROM bicycle ORDER BY random() LIMIT 1
    ) b
         CROSS JOIN LATERAL (
    SELECT stationid FROM station ORDER BY random() LIMIT 1
    ) s1
         CROSS JOIN LATERAL (
    SELECT stationid FROM station ORDER BY random() LIMIT 1
    ) s2;
 */


-- =========================================================
-- SECTION 5: METADATA AND VIEWS
-- Dictionary views, metadata queries
-- =========================================================

SELECT pg_size_pretty(pg_database_size('bcycle')) as db_size;
SELECT current_setting('block_size') as block_size;


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

CREATE OR REPLACE FUNCTION get_exact_row_count(p_schema text, p_rel text)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    v_count bigint;
BEGIN
    EXECUTE format('SELECT count(*) FROM %I.%I', p_schema, p_rel) INTO v_count;
    RETURN v_count;
END;
$$;

CREATE OR REPLACE VIEW v_page_usage_table AS
    SELECT
        stat.relname AS table_name,
        CASE
            WHEN pc.relpages > 0 THEN pc.relpages + 1
            ELSE 1::double precision
        END AS allocated_pages,
        stat.n_live_tup AS tot_tups,
        CASE
            WHEN pc.relpages > 0 THEN
                (SELECT count(*) FROM heap_page_items(get_raw_page(stat.relname, 0)))
        END AS real_max_tups_in_page,
        CASE
            WHEN pc.relpages > 0 THEN NULL
            WHEN pc.relpages = 0 AND stat.n_live_tup > 0 THEN
                (SELECT FLOOR((current_setting('block_size')::int - 32) / (AVG(lp_len) + 8))
                    FROM heap_page_items(get_raw_page(stat.relname, 0)))
        END AS est_max_tups_in_page,
        CASE
            WHEN stat.n_live_tup = 0 THEN NULL
            WHEN pc.relpages = 0 THEN stat.n_live_tup
            WHEN pc.relpages > 0 THEN
                stat.n_live_tup % (SELECT count(*) FROM heap_page_items(get_raw_page(stat.relname, 0)))
        END AS tups_in_allocated_page,
        CASE
            WHEN pc.relpages > 0 THEN
                ROUND((1 /
                    (SELECT count(*) FROM heap_page_items(get_raw_page(stat.relname, 0)))::numeric),
                    5)
            WHEN pc.relpages = 0 AND stat.n_live_tup > 0 THEN
                ROUND((1 /
                    (SELECT (current_setting('block_size')::int - 32) / (AVG(lp_len) + 8)
                    FROM heap_page_items(get_raw_page(stat.relname, 0)))::numeric),
                    5)
            END AS pages_on_tup
    FROM pg_stat_user_tables stat
    LEFT JOIN pg_class pc ON stat.relname = pc.relname
        AND pc.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    WHERE stat.schemaname = 'public' AND pc.relkind = 'r'
    ORDER BY stat.relname;

CREATE OR REPLACE VIEW v_page_usage_materialized AS
    SELECT
        pc.relname AS table_name,
        CASE
            WHEN s.page_capacity > 0 THEN FLOOR(s.exact_tuples::numeric / s.page_capacity)::int + 1
            ELSE 1
        END AS allocated_pages,
        s.exact_tuples AS tot_tups,
        s.page_capacity AS real_max_tups_in_page,
        s.estimated_page_capacity AS est_max_tups_in_page,
        CASE
            WHEN s.exact_tuples = 0 THEN NULL
            WHEN s.allocated_pages = 0 THEN s.exact_tuples
            WHEN s.page_capacity > 0 THEN s.exact_tuples % s.page_capacity
        END AS tups_in_allocated_page,
        CASE
            WHEN s.page_capacity > 0 THEN
                ROUND((1 / s.page_capacity::numeric), 5)
            WHEN s.page_capacity IS NULL AND s.exact_tuples > 0 THEN
                ROUND((1 / s.estimated_page_capacity::numeric), 5)
            END AS pages_on_tup
    FROM pg_class pc
    INNER JOIN pg_namespace ns ON pc.relnamespace = ns.oid
    CROSS JOIN LATERAL (
        SELECT
            get_exact_row_count(ns.nspname, pc.relname) AS exact_tuples,
            (pg_relation_size(format('%I.%I', ns.nspname, pc.relname), 'main') /
                current_setting('block_size')::int)::int AS allocated_pages,
            CASE
                WHEN pg_relation_size(format('%I.%I', ns.nspname, pc.relname), 'main') > 0 THEN
                    (SELECT count(*) FROM heap_page_items(get_raw_page(format('%I.%I', ns.nspname, pc.relname), 0)))
            END AS page_capacity,
            CASE
                WHEN pg_relation_size(format('%I.%I', ns.nspname, pc.relname), 'main') > 0 THEN
                    NULL
                ELSE
                    FLOOR((current_setting('block_size')::int - 32) /
                           (SELECT AVG(lp_len)::int FROM heap_page_items(get_raw_page(format('%I.%I', ns.nspname, pc.relname), 0))) + 8)::int
                END AS estimated_page_capacity
    ) AS s
    WHERE ns.nspname = 'public' AND pc.relkind = 'm'
    ORDER BY pc.relname;

CREATE OR REPLACE VIEW v_page_usage AS
    SELECT * FROM v_page_usage_table
    UNION ALL
    SELECT * FROM v_page_usage_materialized
    ORDER BY table_name;

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

-- SELECT ctid, * FROM mv_data_dict_columns;

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
        ANALYZE mv_data_dict_columns;
        REFRESH MATERIALIZED VIEW CONCURRENTLY mv_data_dict_tables;
        ANALYZE mv_data_dict_tables;

        RAISE NOTICE 'Refresh completed at %', NOW();

        PERFORM pg_sleep(3600);
    END LOOP;
END;
$$;

CALL refresh_materialized_views();


-- =========================================================
-- OPTIONAL SECTION: PASSWORD SETUP (EXAMPLE ONLY)
-- =========================================================
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
