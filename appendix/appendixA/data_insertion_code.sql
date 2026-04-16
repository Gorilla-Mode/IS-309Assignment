-- These test data where generated using partly AI Claude

SET SEARCH_PATH = camille_bike;

-- Programs
INSERT INTO Program VALUES
    ('bcycle_heartland', 'Heartland B-cycle', 'US', 'Omaha, NE', 'Heartland', '402-957-2453', 'America/Chicago', 'info@heartlandbcycle.com'),
    ('bcycle_denver', 'Denver B-cycle', 'US', 'Denver, CO', 'Denver', '720-668-2453', 'America/Denver', 'info@denverbcycle.com');

-- Stations
INSERT INTO Station VALUES
    ('bcycle_heartland_1917', 'bcycle_heartland', '1625 S 67th St', '67th & Pine', 41.24497, -96.01573, '402-957-0001', NULL, '2024-11-01 10:30:00', TRUE, TRUE),
    ('bcycle_heartland_1918', 'bcycle_heartland', '200 S 20th St', '20th & Farnam', 41.25601, -95.93847, NULL, NULL, '2024-11-01 10:28:00', TRUE, TRUE),
    ('bcycle_denver_0042', 'bcycle_denver', '1600 Glenarm Pl', '16th & Glenarm', 39.74785, -104.99248, '720-668-0042', NULL, '2024-11-01 11:00:00', FALSE, TRUE);

-- Bicycles
INSERT INTO Bicycle VALUES
    ('bike_001', 'electric', 'GCM', 'Bcycle 2.0', 'white', 2022),
    ('bike_002', 'electric', 'GCM', 'Bcycle 2.0', 'blue', 2023),
    ('bike_003', 'classic', 'GCM', 'Bcycle Classic', 'red', 2021),
    ('bike_004', 'classic', 'GCM', 'Bcycle Classic', 'black', 2021),
    ('bike_005', 'cargo', 'GCM', 'Bcycle Cargo', 'green', 2023);

-- Docks
INSERT INTO Dock (station_identifier, docked_bike_identifier) VALUES
    ('bcycle_heartland_1917', 'bike_001'),
    ('bcycle_heartland_1917', 'bike_003'),
    ('bcycle_heartland_1917', NULL),
    ('bcycle_heartland_1918', 'bike_002'),
    ('bcycle_heartland_1918', NULL),
    ('bcycle_denver_0042', 'bike_004'),
    ('bcycle_denver_0042', 'bike_005'),
    ('bcycle_denver_0042', NULL);

-- Bicycle statuses
INSERT INTO Bicycle_status (timestamp, bicycle_identifier, bicycle_availability, lattitude, longitude) VALUES
    ('2024-11-01 10:30:00', 'bike_001', 'available', 41.24497, -96.01573),
    ('2024-11-01 10:30:00', 'bike_002', 'available', 41.25601, -95.93847),
    ('2024-11-01 10:30:00', 'bike_003', 'in use',    41.25100, -95.95000),
    ('2024-11-01 10:30:00', 'bike_004', 'available', 39.74785, -104.99248),
    ('2024-11-01 10:30:00', 'bike_005', 'not available', 39.74785, -104.99248);

-- E_bicycle_status (seulement pour bike_001 et bike_002, qui sont électriques)
INSERT INTO E_bicycle_status VALUES
    (1, 85, 32.5),
    (2, 62, 24.0);

-- Accounts
INSERT INTO Account (first_name, last_name, email, password, phone_number, street, city, state_name, zip_code) VALUES
    ('Alice', 'Martin', 'alice.martin@email.com', 'hashed_pw_1', '402-111-2222', '100 Main St', 'Omaha', 'Nebraska', 68102),
    ('Bob', 'Johnson', 'bob.johnson@email.com', 'hashed_pw_2', '402-333-4444', '200 Elm Ave', 'Omaha', 'Nebraska', 68105),
    ('Clara', 'Smith', 'clara.smith@email.com', 'hashed_pw_3', '720-555-6666', '300 Park Blvd', 'Denver', 'Colorado', 80202);

-- Membership types
INSERT INTO Membership_type VALUES
    ('daily',   24,   '$5.00'),
    ('monthly', 744,  '$25.00'),
    ('annual',  8760, '$100.00');

-- Memberships
INSERT INTO Membership (account_id, membership_type_name, date_of_purchase, expiration_timestamp) VALUES
    (1, 'annual',  '2024-01-15', '2025-01-15 00:00:00'),
    (2, 'monthly', '2024-10-10', '2024-11-10 00:00:00'),
    (3, 'daily',   '2024-11-01', '2024-11-02 00:00:00');

-- Rides
INSERT INTO Ride VALUES
    ('bcycle_heartland_1917', 'bcycle_heartland_1918', 'bike_003', 1, '2024-11-01 08:00:00', '2024-11-01 08:22:00', 3.4, '22 min', '$1.50'),
    ('bcycle_heartland_1918', 'bcycle_heartland_1917', 'bike_002', 2, '2024-11-01 09:15:00', '2024-11-01 09:45:00', 5.1, '30 min', '$2.00'),
    ('bcycle_denver_0042',    'bcycle_denver_0042',    'bike_004', 3, '2024-11-01 10:00:00', '2024-11-01 10:18:00', 2.7, '18 min', '$1.25');