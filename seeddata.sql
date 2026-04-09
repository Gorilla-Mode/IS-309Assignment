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