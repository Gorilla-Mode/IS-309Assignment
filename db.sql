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