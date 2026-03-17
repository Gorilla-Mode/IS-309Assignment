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



CREATE OR REPLACE PROCEDURE CREATE_ACCOUNT_SP(
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_email VARCHAR(50),
    IN p_phone VARCHAR(30),
    IN p_street     VARCHAR(120),
    IN p_apt        VARCHAR(20),
    IN p_city       VARCHAR(60),
    IN p_state      VARCHAR(60),
    IN p_zip        VARCHAR(20),
    OUT p_account_id INT
) LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_email INT;
BEGIN
    SELECT count(*) INTO v_existing_email FROM rider where email = p_email;

    IF v_existing_email != 0 THEN
        RAISE EXCEPTION 'Account already exist with email address %', v_existing_email;
    end if;

    INSERT INTO rider (firstname, lastname, email, phone, street, apt, city, state, zip) VALUES
        (p_first_name, p_last_name, p_email, p_phone, p_street, p_apt,
         p_city, p_state, p_zip)
    RETURNING riderid INTO p_account_id;

    RAISE NOTICE 'Created the account, riderId is : %', p_account_id;
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
