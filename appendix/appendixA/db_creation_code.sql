DROP SCHEMA IF EXISTS camille_bike CASCADE;
CREATE SCHEMA camille_bike;
SET SEARCH_PATH = camille_bike;


CREATE TYPE bicycle_type as ENUM ('electric', 'smart', 'classic', 'cargo');

CREATE TYPE bicycle_availability as ENUM ('available', 'in use', 'not available', 'cargo');

CREATE TABLE Program (
    identifier VARCHAR(50) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    provided_city VARCHAR(50) NOT NULL,
    short_name VARCHAR(20),
    phone_number VARCHAR(50),
    timezone VARCHAR(50),
    email VARCHAR(50)
);

CREATE TABLE Station (
    identifier VARCHAR(50) PRIMARY KEY,
    program_identifier VARCHAR(50) NOT NULL,
    address VARCHAR(50) NOT NULL,
    name VARCHAR(50) NOT NULL,
    lattitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    phone_number VARCHAR(50),
    email VARCHAR(50),
    latest_status_update_timestamp TIMESTAMP NOT NULL,
    currently_accept_returns BOOLEAN NOT NULL,
    currently_accept_rentings BOOLEAN NOT NULL,
    FOREIGN KEY (program_identifier) REFERENCES Program(identifier)
);


CREATE TABLE Bicycle (
    identifier VARCHAR(50) PRIMARY KEY,
    bicycle_type bicycle_type NOT NULL,
    make VARCHAR(50),
    model VARCHAR(50),
    color VARCHAR(50),
    year_acquired INTEGER
);


CREATE TABLE Bicycle_status (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    bicycle_identifier VARCHAR(50) NOT NULL, 
    bicycle_availability bicycle_availability NOT NULL,
    lattitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    FOREIGN KEY (bicycle_identifier) REFERENCES Bicycle(identifier),
    UNIQUE (timestamp, bicycle_identifier)
);

CREATE TABLE E_bicycle_status (
    bicycle_status_id INT PRIMARY KEY,
    remaining_power_percent INT NOT NULL,
    remaining_range FLOAT NOT NULL,
    FOREIGN KEY (bicycle_status_id) REFERENCES Bicycle_status(id)
);


CREATE TABLE Dock (
    id SERIAL primary KEY,
    station_identifier VARCHAR(50) NOT NULL,
    docked_bike_identifier VARCHAR(50),
    FOREIGN KEY (station_identifier) REFERENCES Station(identifier),
    FOREIGN KEY (docked_bike_identifier) REFERENCES Bicycle(identifier)

);


CREATE TABLE Account (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL,
    password VARCHAR(50) NOT NULL,      --- storing hash would be better, but I keep it this way for clarity
    phone_number VARCHAR(50) NOT NULL,
    street VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state_name VARCHAR(50) NOT NULL,
    zip_code INT NOT NULL
);


CREATE TABLE Membership_type (
    name VARCHAR(50) PRIMARY KEY,
    duration_in_hours INT NOT NULL,
    price MONEY NOT NULL
);


CREATE TABLE Membership (
    id SERIAL PRIMARY KEY,
    account_id INT NOT NULL,
    membership_type_name VARCHAR(50) NOT NULL,
    date_of_purchase DATE NOT NULL,
    expiration_timestamp TIMESTAMP NOT NULL,
    FOREIGN KEY (account_id) REFERENCES Account(id),
    FOREIGN KEY (membership_type_name) REFERENCES Membership_type(name)
);

CREATE TABLE Ride (
    start_station_identifier VARCHAR(50) NOT NULL,
    end_station_identifier VARCHAR(50) NOT NULL,
    bicycle_identifier VARCHAR(50) NOT NULL, 
	account_id INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,

    end_time TIMESTAMP NOT NULL,
    total_distance FLOAT NOT NULL,
    elapsed_time VARCHAR(50) NOT NULL,
    total_cost MONEY NOT NULL,
    
    PRIMARY KEY (start_station_identifier, end_station_identifier, bicycle_identifier, account_id, start_time),
    FOREIGN KEY (bicycle_identifier) REFERENCES Bicycle(identifier),
    FOREIGN KEY (account_id) REFERENCES Account(id)
);


