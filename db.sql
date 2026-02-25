DROP TABLE IF EXISTS BicycleStatus;
DROP TABLE IF EXISTS StationStatus;
DROP TABLE IF EXISTS Trip;
DROP TABLE IF EXISTS Membership;
DROP TABLE IF EXISTS Dock;
DROP TABLE IF EXISTS Bicycle;
DROP TABLE IF EXISTS Rider;
DROP TABLE IF EXISTS Station;
DROP TABLE IF EXISTS Program;

CREATE TABLE Program (
                         ProgramID   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         ProgramCode VARCHAR(50) NOT NULL UNIQUE,
                         CountryCode CHAR(2) NOT NULL,
                         Name        VARCHAR(100) NOT NULL,
                         Location    VARCHAR(100),
                         Phone       VARCHAR(30),
                         Email       VARCHAR(255),
                         Timezone    VARCHAR(64),
                         URL         VARCHAR(255),
                         ShortName   VARCHAR(50)
);

CREATE TABLE Station (
                         StationID     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         StationCode   VARCHAR(80) NOT NULL UNIQUE,
                         ProgramID     INT NOT NULL REFERENCES Program(ProgramID),
                         Address       VARCHAR(120) NOT NULL,
                         Name          VARCHAR(120) NOT NULL,
                         Latitude      NUMERIC(9,6) NOT NULL,
                         Longitude     NUMERIC(9,6) NOT NULL,
                         Capacity      INT NOT NULL CHECK (Capacity >= 1),
                         PostalCode    VARCHAR(20),
                         ContactPhone  VARCHAR(30),
                         ShortName     VARCHAR(50)
);

CREATE TABLE Dock (
                      DockID        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                      StationID     INT NOT NULL REFERENCES Station(StationID) ON DELETE CASCADE,
                      DockNumber    INT NOT NULL CHECK (DockNumber >= 1),
                      IsOperational BOOLEAN NOT NULL DEFAULT TRUE,
                      UNIQUE (StationID, DockNumber)
);

CREATE TABLE Rider (
                       RiderID    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                       FirstName  VARCHAR(50) NOT NULL,
                       LastName   VARCHAR(50) NOT NULL,
                       Email      VARCHAR(255) NOT NULL UNIQUE,
                       Phone      VARCHAR(30),
                       Street     VARCHAR(120),
                       Apt        VARCHAR(20),
                       City       VARCHAR(60),
                       State      VARCHAR(60),
                       Zip        VARCHAR(20)
);

CREATE TABLE Membership (
                            MembershipID   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                            RiderID        INT NOT NULL REFERENCES Rider(RiderID) ON DELETE CASCADE,
                            MembershipType VARCHAR(10) NOT NULL CHECK (MembershipType IN ('DAY','MONTH','ANNUAL')),
                            PurchasedAt    TIMESTAMP NOT NULL,
                            ExpiresAt      TIMESTAMP NOT NULL,
                            CHECK (ExpiresAt > PurchasedAt)
);

CREATE TABLE Bicycle (
                         BicycleID    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         BicycleType  VARCHAR(10) NOT NULL CHECK (BicycleType IN ('ELECTRIC','SMART','CLASSIC','CARGO')),
                         Make         VARCHAR(50),
                         Model        VARCHAR(50),
                         Color        VARCHAR(30),
                         YearAcquired INT CHECK (YearAcquired IS NULL OR (YearAcquired >= 1900 AND YearAcquired <= 2100))
);

CREATE TABLE Trip (
                      TripID              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                      RiderID             INT NOT NULL REFERENCES Rider(RiderID),
                      BicycleID           INT NOT NULL REFERENCES Bicycle(BicycleID),
                      StartStationID      INT NOT NULL REFERENCES Station(StationID),
                      EndStationID        INT NOT NULL REFERENCES Station(StationID),
                      StartTime           TIMESTAMP NOT NULL,
                      EndTime             TIMESTAMPTZ,
                      TotalDistance       NUMERIC(8,2) CHECK (TotalDistance IS NULL OR TotalDistance >= 0),
                      TotalElapsedSeconds INT CHECK (TotalElapsedSeconds IS NULL OR TotalElapsedSeconds >= 0),
                      TotalCost           NUMERIC(10,2) CHECK (TotalCost IS NULL OR TotalCost >= 0)
);

CREATE TABLE StationStatus (
                               StationStatusID     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                               StationID           INT NOT NULL REFERENCES Station(StationID) ON DELETE CASCADE,
                               ReportedAt          TIMESTAMP NOT NULL,
                               BikesAvailElectric  INT NOT NULL DEFAULT 0 CHECK (BikesAvailElectric >= 0),
                               BikesAvailClassic   INT NOT NULL DEFAULT 0 CHECK (BikesAvailClassic >= 0),
                               BikesAvailSmart     INT NOT NULL DEFAULT 0 CHECK (BikesAvailSmart >= 0),
                               BikesAvailCargo     INT NOT NULL DEFAULT 0 CHECK (BikesAvailCargo >= 0),
                               BikesAvailTotal     INT NOT NULL DEFAULT 0 CHECK (BikesAvailTotal >= 0),
                               DocksAvailTotal     INT NOT NULL DEFAULT 0 CHECK (DocksAvailTotal >= 0),
                               AcceptingReturns    BOOLEAN NOT NULL DEFAULT TRUE,
                               IsRenting           BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE BicycleStatus (
                               BicycleStatusID  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                               BicycleID        INT NOT NULL REFERENCES Bicycle(BicycleID) ON DELETE CASCADE,
                               RecordedAt       TIMESTAMP NOT NULL,
                               Status           VARCHAR(15) NOT NULL CHECK (Status IN ('AVAILABLE','IN_USE','NOT_AVAILABLE')),
                               Latitude         NUMERIC(9,6),
                               Longitude        NUMERIC(9,6),
                               BatteryPercent   INT CHECK (BatteryPercent IS NULL OR (BatteryPercent >= 0 AND BatteryPercent <= 100)),
                               RemainingRange   NUMERIC(6,2) CHECK (RemainingRange IS NULL OR RemainingRange >= 0)
);