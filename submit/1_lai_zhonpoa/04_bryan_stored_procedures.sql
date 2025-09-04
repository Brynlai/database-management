--=============================================================================
-- File: 04_bryan_stored_procedures.sql
-- Author: Bryan Lai ZhonPoa
-- Purpose: Implements the core business logic for system administration and
--          operations through reusable and validated stored procedures.
--=============================================================================

SET SERVEROUTPUT ON;






































--=============================================================================
-- Procedure 1: Add New Staff (Enhanced for Robustness)
--=============================================================================
-- Purpose: Safely adds a new staff member to the system. This enhanced
--          version includes proactive validation of input parameters to provide
--          clearer error messages and returns the new staff_id.
CREATE OR REPLACE PROCEDURE Add_New_Staff (
    p_name          IN Staff.name%TYPE,
    p_role          IN Staff.role%TYPE,
    p_email         IN Staff.email%TYPE,
    p_contact_no    IN Staff.contact_no%TYPE,
    p_status        IN Staff.status%TYPE,
    o_new_staff_id  OUT Staff.staff_id%TYPE
)
AS
BEGIN
    -- Step 1: Proactive validation for role
    IF p_role NOT IN ('Counter Staff', 'Cleaner', 'Manager', 'Technician') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Validation Error: Invalid role specified. Must be one of: Counter Staff, Cleaner, Manager, Technician.');
    END IF;

    -- Step 2: Proactive validation for status
    IF p_status NOT IN ('Active', 'Resigned', 'On Leave') THEN
        RAISE_APPLICATION_ERROR(-20004, 'Validation Error: Invalid status specified. Must be one of: Active, Resigned, On Leave.');
    END IF;

    -- Step 3: Insert the new record and capture the new ID
    INSERT INTO Staff (
        staff_id, name, role, email, contact_no, employment_date, status
    ) VALUES (
        staff_seq.NEXTVAL, p_name, p_role, p_email, p_contact_no, SYSDATE, p_status
    ) RETURNING staff_id INTO o_new_staff_id;

    DBMS_OUTPUT.PUT_LINE('Success: New staff member ''' || p_name || ''' added with ID ' || o_new_staff_id || '.');
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Error: A staff member with the email ''' || p_email || ''' already exists.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END Add_New_Staff;
/









































--=============================================================================
-- Procedure 2: Reassign Driver for a Schedule (Upgraded for Business Value)
--=============================================================================
-- Purpose: Atomically reassigns a driver for a specific schedule. This is a
--          critical operational tool for handling last-minute changes like
--          sick leave. It ensures the old assignment is removed and the new
--          one is added in a single, validated transaction.
CREATE OR REPLACE PROCEDURE Reassign_Driver_For_Schedule (
    p_schedule_id       IN Schedule.schedule_id%TYPE,
    p_old_driver_id     IN Driver.driver_id%TYPE,
    p_new_driver_id     IN Driver.driver_id%TYPE,
    p_notes             IN DriverList.assignment_notes%TYPE DEFAULT 'Reassignment'
)
AS
    v_schedule_count    NUMBER;
    v_new_driver_count  NUMBER;
    v_old_assignment_count NUMBER;
BEGIN
    -- Step 1: Validate that the schedule exists.
    SELECT COUNT(*) INTO v_schedule_count FROM Schedule WHERE schedule_id = p_schedule_id;
    IF v_schedule_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Reassignment Failed: Schedule with ID ' || p_schedule_id || ' does not exist.');
    END IF;

    -- Step 2: Validate that the new driver exists.
    SELECT COUNT(*) INTO v_new_driver_count FROM Driver WHERE driver_id = p_new_driver_id;
    IF v_new_driver_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Reassignment Failed: New driver with ID ' || p_new_driver_id || ' does not exist.');
    END IF;

    -- Step 3: Crucial Validation - Verify the old driver is currently assigned to this schedule.
    SELECT COUNT(*) INTO v_old_assignment_count FROM DriverList
    WHERE schedule_id = p_schedule_id AND driver_id = p_old_driver_id;

    IF v_old_assignment_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Reassignment Failed: Driver ' || p_old_driver_id || ' is not currently assigned to schedule ' || p_schedule_id || '.');
    END IF;

    -- Step 4: Perform the reassignment transactionally.
    DELETE FROM DriverList
    WHERE schedule_id = p_schedule_id AND driver_id = p_old_driver_id;

    INSERT INTO DriverList (
        schedule_id,
        driver_id,
        assignment_notes
    ) VALUES (
        p_schedule_id,
        p_new_driver_id,
        p_notes
    );

    DBMS_OUTPUT.PUT_LINE('Success: Reassigned schedule ' || p_schedule_id || ' from driver ' || p_old_driver_id || ' to driver ' || p_new_driver_id || '.');
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20012, 'Reassignment Failed: New driver ' || p_new_driver_id || ' is already assigned to schedule ' || p_schedule_id || '.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END Reassign_Driver_For_Schedule;
/





































--=============================================================================
-- Demonstration Script
--=============================================================================
PROMPT =================================================================
PROMPT DEMONSTRATING STORED PROCEDURES
PROMPT =================================================================














--
-- DEMO 1: Add_New_Staff Procedure
--
PROMPT --- Testing Procedure 1: Add_New_Staff ---

PROMPT [SETUP] Cleaning up any previous test data for 'Add_New_Staff'
BEGIN
    DELETE FROM Staff WHERE email = 'maria.garcia.demo@busstation.com';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

PROMPT [SUCCESS CASE 1.1] Adding a new staff member with valid data.
DECLARE
    v_new_id NUMBER;
BEGIN
    Add_New_Staff(
        p_name       => 'Maria Garcia',
        p_role       => 'Technician',
        p_email      => 'maria.garcia.demo@busstation.com',
        p_contact_no => '555-1234',
        p_status     => 'Active',
        o_new_staff_id => v_new_id
    );
END;
/
-- Verification Step
SELECT staff_id, name, email, role FROM Staff WHERE email = 'maria.garcia.demo@busstation.com';

PROMPT [FAILURE CASE 1.2] Attempting to add a staff member with a duplicate email.
DECLARE
    v_new_id NUMBER;
BEGIN
    Add_New_Staff('John Doe', 'Manager', 'maria.garcia.demo@busstation.com', '555-5678', 'Active', v_new_id);
END;
/

PROMPT [FAILURE CASE 1.3] Attempting to add a staff member with an invalid role.
DECLARE
    v_new_id NUMBER;
BEGIN
    Add_New_Staff('Invalid Role Person', 'CEO', 'ceo.demo@busstation.com', '555-1111', 'Active', v_new_id);
END;
/





















--
-- DEMO 2: Reassign_Driver_For_Schedule Procedure
--
PROMPT --- Testing Procedure 2: Reassign_Driver_For_Schedule ---

PROMPT [SETUP] Creating a fully isolated test environment...
DECLARE
    v_bus_id Bus.bus_id%TYPE;
BEGIN
    -- Clean up any leftovers from a previous failed run to ensure idempotency
    DELETE FROM DriverList WHERE schedule_id = 99999;
    DELETE FROM Schedule WHERE schedule_id = 99999;
    DELETE FROM Driver WHERE driver_id IN (99901, 99902);
    COMMIT;
    
    -- Select a valid bus_id to create a valid schedule
    SELECT bus_id INTO v_bus_id FROM Bus WHERE ROWNUM = 1;

    -- Create fresh test data
    INSERT INTO Driver (driver_id, name, license_no) VALUES (99901, 'Old Driver Bob', 'TEST-OLD-99901');
    INSERT INTO Driver (driver_id, name, license_no) VALUES (99902, 'New Driver Alice', 'TEST-NEW-99902');
    INSERT INTO Schedule (schedule_id, departure_time, arrival_time, base_price, origin_station, destination_station, bus_id)
    VALUES (99999, SYSDATE + 1, SYSDATE + 1.5, 50, 'Test Origin', 'Test Destination', v_bus_id);
    INSERT INTO DriverList (schedule_id, driver_id, assignment_notes) VALUES (99999, 99901, 'Initial assignment for test');
    COMMIT;
END;
/

PROMPT Initial state for temporary Schedule 99999:
SELECT dl.schedule_id, dl.driver_id, d.name FROM DriverList dl JOIN Driver d ON dl.driver_id = d.driver_id WHERE dl.schedule_id = 99999;

PROMPT [SUCCESS CASE 2.1] Reassigning a driver on the temporary schedule.
BEGIN
    Reassign_Driver_For_Schedule(
        p_schedule_id   => 99999,
        p_old_driver_id => 99901,
        p_new_driver_id => 99902,
        p_notes         => 'Emergency reassignment test'
    );
END;
/
PROMPT State after successful reassignment:
SELECT dl.schedule_id, dl.driver_id, d.name, dl.assignment_notes FROM DriverList dl JOIN Driver d ON dl.driver_id = d.driver_id WHERE dl.schedule_id = 99999;

PROMPT [FAILURE CASE 2.2] Attempting to reassign a driver who is no longer assigned.
BEGIN
    Reassign_Driver_For_Schedule(
        p_schedule_id   => 99999,
        p_old_driver_id => 99901, -- Bob is no longer assigned, this should fail.
        p_new_driver_id => 10,    -- A random valid driver
        p_notes         => 'This should fail'
    );
END;
/

PROMPT [CLEANUP] Removing all temporary test data...
BEGIN
    DELETE FROM DriverList WHERE schedule_id = 99999;
    DELETE FROM Schedule WHERE schedule_id = 99999;
    DELETE FROM Driver WHERE driver_id IN (99901, 99902);
    COMMIT;
END;
/