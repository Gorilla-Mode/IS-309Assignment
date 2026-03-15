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
    IF NOT EXISTS (
        SELECT 1
        FROM Station
        WHERE StationID = p_station_id
    ) THEN
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
    IF NOT EXISTS (
        SELECT 1
        FROM rider
        WHERE riderid = p_rider_id
    ) THEN
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
        SET expiresat = v_existing_expires_at + (v_expires_at - v_purchased_at)
        WHERE membershipid = v_existing_membership_id
        RETURNING membershipid INTO p_membership_id;

        RAISE NOTICE 'Membership extended for riderid: %. membershipid: %. New expiry: %', p_rider_id, p_membership_id,
        v_existing_expires_at + (v_expires_at - v_purchased_at);
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
'Purchases or extends a membership for a rider.
Params:
    p_rider_id: The ID of the rider to purchase membership for.
    p_membership_type: The type of membership to purchase. Must be DAY, MONTH, or ANNUAL.
Returns:
    p_membership_id: The ID of the membership that was purchased or extended.
    ';

