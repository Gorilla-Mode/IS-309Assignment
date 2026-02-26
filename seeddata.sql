INSERT INTO Program (ProgramCode, CountryCode, Name, Location, Phone, Email, Timezone, URL, ShortName)
VALUES
    ('CITIBIKE_NYC', 'US', 'Citi Bike', 'New York, NY', '+1-855-245-3311', 'support@citibikenyc.com', 'America/New_York', 'https://citibikenyc.com', 'CitiBike'),
    ('DIVVY_CHI', 'US', 'Divvy', 'Chicago, IL', '+1-855-553-4889', 'support@divvybikes.com', 'America/Chicago', 'https://divvybikes.com', 'Divvy'),
    ('BIXI_MTL', 'CA', 'BIXI Montréal', 'Montréal, QC', '+1-514-789-2494', 'info@bixi.com', 'America/Montreal', 'https://bixi.com', 'BIXI'),
    ('BYSYKKEL_OSL', 'NO', 'Oslo Bysykkel', 'Oslo', '+47-915-89-700', 'post@oslobysykkel.no', 'Europe/Oslo', 'https://oslobysykkel.no', 'Bysykkel');

INSERT INTO Station (StationCode, ProgramID, Address, Name, Latitude, Longitude, Capacity, PostalCode, ContactPhone, ShortName)
VALUES
    -- Citi Bike NYC stations
    ('NYC-6839', 1, '346 Broadway', 'Broadway & Leonard St', 40.717548, -74.005305, 30, '10013', NULL, 'Broadway/Leonard'),
    ('NYC-6140', 1, '1 Central Park S', 'Central Park South & 6th Ave', 40.765909, -73.976342, 40, '10019', NULL, 'CPS/6th'),
    ('NYC-5972', 1, '11 Wall St', 'Wall St & William St', 40.706858, -74.009625, 24, '10005', NULL, 'Wall/William'),
    ('NYC-7612', 1, '350 W 42nd St', '42nd St & Dyer Ave', 40.758985, -73.993800, 36, '10036', NULL, '42nd/Dyer'),
    -- Divvy Chicago stations
    ('CHI-15541', 2, '333 N Michigan Ave', 'Michigan Ave & Lake St', 41.886024, -87.624117, 28, '60601', NULL, 'Michigan/Lake'),
    ('CHI-15544', 2, '1000 W Diversey Pkwy', 'Diversey Pkwy & Sheffield Ave', 41.932733, -87.653818, 20, '60614', NULL, 'Diversey/Sheffield'),
    ('CHI-15549', 2, '200 E Randolph St', 'Millennium Park', 41.881032, -87.624084, 50, '60601', NULL, 'Millennium'),
    -- BIXI Montréal stations
    ('MTL-7060', 3, '350 Rue Sainte-Catherine O', 'Ste-Catherine / McGill College', 45.503204, -73.571640, 35, 'H3B 1A3', NULL, 'SteCath/McGill'),
    ('MTL-7039', 3, '1250 Rue Peel', 'Peel / Ste-Catherine', 45.501689, -73.573022, 25, 'H3B 4W8', NULL, 'Peel/SteCath'),
    -- Oslo Bysykkel stations
    ('OSL-2315', 4, 'Aker Brygge 1', 'Aker Brygge', 59.910764, 10.727177, 30, '0250', NULL, 'AkerBrygge'),
    ('OSL-2350', 4, 'Karl Johans gate 1', 'Jernbanetorget', 59.911096, 10.750923, 24, '0154', NULL, 'Jernbanetorget');

INSERT INTO Dock (StationID, DockNumber, IsOperational)
VALUES
    -- Station 1: Broadway & Leonard (30 capacity, showing 5 docks)
    (1, 1, TRUE), (1, 2, TRUE), (1, 3, TRUE), (1, 4, FALSE), (1, 5, TRUE),
    -- Station 2: Central Park South (40 capacity, showing 5 docks)
    (2, 1, TRUE), (2, 2, TRUE), (2, 3, TRUE), (2, 4, TRUE), (2, 5, TRUE),
    -- Station 3: Wall St (24 capacity, showing 4 docks)
    (3, 1, TRUE), (3, 2, FALSE), (3, 3, TRUE), (3, 4, TRUE),
    -- Station 5: Michigan Ave (28 capacity, showing 4 docks)
    (5, 1, TRUE), (5, 2, TRUE), (5, 3, TRUE), (5, 4, TRUE),
    -- Station 7: Millennium Park (50 capacity, showing 5 docks)
    (7, 1, TRUE), (7, 2, TRUE), (7, 3, FALSE), (7, 4, TRUE), (7, 5, TRUE),
    -- Station 8: Ste-Catherine (35 capacity, showing 3 docks)
    (8, 1, TRUE), (8, 2, TRUE), (8, 3, TRUE),
    -- Station 10: Aker Brygge (30 capacity, showing 3 docks)
    (10, 1, TRUE), (10, 2, TRUE), (10, 3, TRUE),
    -- Station 11: Jernbanetorget (24 capacity, showing 3 docks)
    (11, 1, TRUE), (11, 2, FALSE), (11, 3, TRUE);

INSERT INTO Rider (FirstName, LastName, Email, Phone, Street, Apt, City, State, Zip)
VALUES
    ('Alice',   'Johnson',  'alice.johnson@example.com',    '+1-212-555-0101', '123 Main St',        '4A',  'New York',  'NY', '10001'),
    ('Bob',     'Smith',    'bob.smith@example.com',        '+1-312-555-0202', '456 Oak Ave',        NULL,  'Chicago',   'IL', '60614'),
    ('Clara',   'Dubois',   'clara.dubois@example.com',     '+1-514-555-0303', '789 Rue Sherbrooke', '12',  'Montréal',  'QC', 'H3A 1G1'),
    ('David',   'Lee',      'david.lee@example.com',        '+1-212-555-0404', '321 Park Ave',       '7B',  'New York',  'NY', '10022'),
    ('Emma',    'Larsen',   'emma.larsen@example.com',      '+47-912-34-567',  'Bygdøy allé 10',     NULL,  'Oslo',      NULL, '0262'),
    ('Frank',   'Garcia',   'frank.garcia@example.com',     '+1-312-555-0606', '100 State St',       NULL,  'Chicago',   'IL', '60601'),
    ('Grace',   'Wang',     'grace.wang@example.com',       '+1-212-555-0707', '55 W 46th St',       '3C',  'New York',  'NY', '10036'),
    ('Henrik',  'Olsen',    'henrik.olsen@example.com',     '+47-987-65-432',  'Grünerløkka 5',      NULL,  'Oslo',      NULL, '0555'),
    ('Isabelle','Tremblay', 'isabelle.tremblay@example.com','+1-514-555-0909', '220 Av du Parc',     NULL,  'Montréal',  'QC', 'H2W 1R4'),
    ('James',   'Brown',    'james.brown@example.com',      '+1-212-555-1010', '88 Greenwich St',    NULL,  'New York',  'NY', '10006');

INSERT INTO Membership (RiderID, MembershipType, PurchasedAt, ExpiresAt)
VALUES
    (1,  'ANNUAL', '2025-03-01 09:00:00', '2026-03-01 09:00:00'),
    (2,  'MONTH',  '2025-12-15 14:30:00', '2026-01-15 14:30:00'),
    (3,  'ANNUAL', '2025-06-01 08:00:00', '2026-06-01 08:00:00'),
    (4,  'DAY',    '2026-02-20 07:00:00', '2026-02-21 07:00:00'),
    (5,  'ANNUAL', '2025-09-01 10:00:00', '2026-09-01 10:00:00'),
    (6,  'MONTH',  '2026-02-01 12:00:00', '2026-03-01 12:00:00'),
    (7,  'DAY',    '2026-02-25 06:00:00', '2026-02-26 06:00:00'),
    (8,  'ANNUAL', '2025-05-15 11:00:00', '2026-05-15 11:00:00'),
    (9,  'MONTH',  '2026-01-20 09:30:00', '2026-02-20 09:30:00'),
    (10, 'ANNUAL', '2025-07-01 08:00:00', '2026-07-01 08:00:00');

INSERT INTO Bicycle (BicycleType, Make, Model, Color, YearAcquired)
VALUES
    ('ELECTRIC', 'Lyft',        'Gen 4E',    'Gray',   2024),
    ('CLASSIC',  'Lyft',        'Gen 4',     'Blue',   2023),
    ('SMART',    'PBSC',        'E-FIT 527', 'Black',  2024),
    ('CLASSIC',  'PBSC',        'FIT 527',   'Green',  2022),
    ('ELECTRIC', 'PBSC',        'E-FIT 527', 'White',  2025),
    ('CARGO',    'Urban Arrow', 'Family',    'Black',  2024),
    ('CLASSIC',  'Lyft',        'Gen 3',     'Blue',   2021),
    ('ELECTRIC', 'VanMoof',     'S5',        'Silver', 2024),
    ('SMART',    'VanMoof',     'A5',        'Red',    2025),
    ('CLASSIC',  'PBSC',        'FIT 527',   'Green',  2023),
    ('ELECTRIC', 'Lyft',        'Gen 4E',    'Gray',   2025),
    ('CARGO',    'Tern',        'GSD S10',   'Blue',   2024);

INSERT INTO Trip (RiderID, BicycleID, StartStationID, EndStationID, StartTime, EndTime, TotalDistance, TotalElapsedSeconds, TotalCost)
VALUES
    -- NYC trips
    (1,  2,  1, 2, '2026-02-20 08:15:00', '2026-02-20 08:42:00+00',  4.30, 1620, 0.00),
    (4,  1,  2, 3, '2026-02-20 09:00:00', '2026-02-20 09:25:00+00',  6.10, 1500, 3.50),
    (7,  7,  3, 4, '2026-02-20 12:10:00', '2026-02-20 12:35:00+00',  3.80, 1500, 3.50),
    (10, 2,  4, 1, '2026-02-21 07:30:00', '2026-02-21 07:55:00+00',  5.00, 1500, 0.00),
    (1,  1,  1, 4, '2026-02-22 17:00:00', '2026-02-22 17:38:00+00',  7.20, 2280, 0.00),
    -- Chicago trips
    (2,  4,  5, 6, '2026-02-19 08:00:00', '2026-02-19 08:22:00+00',  3.50, 1320, 0.00),
    (6,  7,  6, 7, '2026-02-20 13:15:00', '2026-02-20 13:50:00+00',  5.20, 2100, 0.00),
    (2,  4,  7, 5, '2026-02-21 18:00:00', '2026-02-21 18:30:00+00',  4.10, 1800, 0.00),
    -- Montréal trips
    (3,  3,  8, 9, '2026-02-18 10:00:00', '2026-02-18 10:20:00+00',  2.10, 1200, 0.00),
    (9,  5,  9, 8, '2026-02-20 16:30:00', '2026-02-20 16:55:00+00',  2.50, 1500, 0.00),
    (3,  10, 8, 9, '2026-02-22 08:45:00', '2026-02-22 09:05:00+00',  2.00, 1200, 0.00),
    -- Oslo trips
    (5,  8,  10, 11, '2026-02-17 07:30:00', '2026-02-17 07:50:00+00', 2.80, 1200, 0.00),
    (8,  9,  11, 10, '2026-02-19 15:00:00', '2026-02-19 15:25:00+00', 3.00, 1500, 0.00),
    (5,  8,  10, 11, '2026-02-24 08:00:00', '2026-02-24 08:18:00+00', 2.90, 1080, 0.00),
    -- Ongoing trip (no end yet)
    (7,  11, 2,  2, '2026-02-25 07:45:00', NULL, NULL, NULL, NULL);

INSERT INTO StationStatus (StationID, ReportedAt, BikesAvailElectric, BikesAvailClassic, BikesAvailSmart, BikesAvailCargo, BikesAvailTotal, DocksAvailTotal, AcceptingReturns, IsRenting)
VALUES
    (1,  '2026-02-25 08:00:00', 3, 5, 0, 0,  8, 22, TRUE,  TRUE),
    (2,  '2026-02-25 08:00:00', 5, 8, 2, 0, 15, 25, TRUE,  TRUE),
    (3,  '2026-02-25 08:00:00', 1, 3, 0, 0,  4, 20, TRUE,  TRUE),
    (4,  '2026-02-25 08:00:00', 2, 6, 1, 0,  9, 27, TRUE,  TRUE),
    (5,  '2026-02-25 08:00:00', 2, 4, 0, 1,  7, 21, TRUE,  TRUE),
    (6,  '2026-02-25 08:00:00', 0, 3, 0, 0,  3, 17, TRUE,  TRUE),
    (7,  '2026-02-25 08:00:00', 4, 10, 2, 1, 17, 33, TRUE,  TRUE),
    (8,  '2026-02-25 08:00:00', 3, 6, 1, 0, 10, 25, TRUE,  TRUE),
    (9,  '2026-02-25 08:00:00', 1, 4, 0, 0,  5, 20, TRUE,  TRUE),
    (10, '2026-02-25 08:00:00', 2, 3, 1, 0,  6, 24, TRUE,  TRUE),
    (11, '2026-02-25 08:00:00', 1, 2, 0, 0,  3, 21, FALSE, TRUE);

INSERT INTO BicycleStatus (BicycleID, RecordedAt, Status, Latitude, Longitude, BatteryPercent, RemainingRange)
VALUES
    (1,  '2026-02-25 08:00:00', 'AVAILABLE',     40.765909, -73.976342,  72,    28.50),
    (2,  '2026-02-25 08:00:00', 'AVAILABLE',     40.717548, -74.005305,  NULL,  NULL),
    (3,  '2026-02-25 08:00:00', 'AVAILABLE',     45.503204, -73.571640,  85,    35.00),
    (4,  '2026-02-25 08:00:00', 'AVAILABLE',     41.886024, -87.624117,  NULL,  NULL),
    (5,  '2026-02-25 08:00:00', 'AVAILABLE',     45.501689, -73.573022,  60,    24.00),
    (6,  '2026-02-25 08:00:00', 'NOT_AVAILABLE', 41.881032, -87.624084,  NULL,  NULL),
    (7,  '2026-02-25 08:00:00', 'AVAILABLE',     41.932733, -87.653818,  NULL,  NULL),
    (8,  '2026-02-25 08:00:00', 'AVAILABLE',     59.910764,  10.727177,  90,    40.00),
    (9,  '2026-02-25 08:00:00', 'AVAILABLE',     59.911096,  10.750923,  55,    22.00),
    (10, '2026-02-25 08:00:00', 'AVAILABLE',     45.503204, -73.571640,  NULL,  NULL),
    (11, '2026-02-25 08:00:00', 'IN_USE',        40.750000, -73.990000,  45,    18.00),
    (12, '2026-02-25 08:00:00', 'NOT_AVAILABLE', 41.886024, -87.624117,  NULL,  NULL);