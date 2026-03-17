CREATE OR REPLACE FUNCTION VALIDATE_RECORD_EXISTS_FN(
    p_table_name TEXT,
    p_column_name TEXT,
    p_value INT
)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
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

CREATE OR REPLACE PROCEDURE PURCHASE_MEMBERSHIP_SP(
    IN p_rider_id INT,
    IN p_membership_type VARCHAR(10),
    OUT p_membership_id INT
)
LANGUAGE plpgsql
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

/* =====================================================
   STATEMENT-LEVEL TRIGGER
   Logs INSERT, UPDATE and DELETE operations performed
   on the Dock table.
   ===================================================== */
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