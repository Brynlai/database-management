--=============================================================================
-- File: 05_bryan_triggers.sql
-- Author: Bryan Lai ZhonPoa
-- Purpose: Implements advanced database triggers to automatically enforce
--          complex system-wide business rules and data integrity policies.
--=============================================================================

SET SERVEROUTPUT ON;




























--=============================================================================
-- Trigger 1: Check Staff Assignment
--=============================================================================
-- Purpose: Enforces two critical business rules before a staff member is
--          assigned to a service task:
--          1. The staff member's status must be 'Active'.
--          2. The role for the task must match the staff's official role.
CREATE OR REPLACE TRIGGER trg_check_staff_assignment
BEFORE INSERT OR UPDATE ON StaffAllocation
FOR EACH ROW
DECLARE
    v_staff_details Staff%ROWTYPE;
BEGIN
    -- Step 1: Fetch the staff member's full details for validation.
    BEGIN
        SELECT *
        INTO v_staff_details
        FROM Staff
        WHERE staff_id = :NEW.staff_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20026, 'Assignment Failed: Staff member with ID ' || :NEW.staff_id || ' does not exist.');
    END;

    -- Step 2: Validate the staff member's status.
    IF v_staff_details.status != 'Active' THEN
        RAISE_APPLICATION_ERROR(
            -20025,
            'Assignment Failed: Staff member ''' || v_staff_details.name || ''' has a status of ''' || v_staff_details.status || '''. Only active staff can be assigned.'
        );
    END IF;

    -- Step 3: Validate that the assigned role matches the staff's official role.
    IF v_staff_details.role != :NEW.role THEN
        RAISE_APPLICATION_ERROR(
            -20027,
            'Assignment Failed: Role mismatch. Staff member ''' || v_staff_details.name || ''' is a ''' || v_staff_details.role || ''' and cannot be assigned as a ''' || :NEW.role || '''.'
        );
    END IF;
END;
/

















--=============================================================================
-- Trigger 2: Prevent Orphaned Bus Records
--=============================================================================
-- Purpose: Protects data integrity by blocking the deletion of a company that
--          still owns buses. This enhanced version provides a list of example
--          bus plate numbers to make the error message actionable.
CREATE OR REPLACE TRIGGER trg_prevent_company_deletion
BEFORE DELETE ON Company
FOR EACH ROW
DECLARE
    v_bus_count     NUMBER;
    v_bus_examples  VARCHAR2(200);
BEGIN
    -- Step 1: Check if this company owns any buses.
    SELECT COUNT(*)
    INTO v_bus_count
    FROM Bus
    WHERE company_id = :OLD.company_id;

    -- Step 2: If buses exist, gather examples and raise a detailed error.
    IF v_bus_count > 0 THEN
        -- Step 2a: Use LISTAGG to get a comma-separated list of plate numbers.
        SELECT LISTAGG(plate_number, ', ') WITHIN GROUP (ORDER BY plate_number)
        INTO v_bus_examples
        FROM (
            SELECT plate_number FROM Bus
            WHERE company_id = :OLD.company_id AND ROWNUM <= 3
        );

        -- Step 2b: Raise a detailed, actionable error.
        RAISE_APPLICATION_ERROR(
            -20020,
            'Cannot delete company ''' || :OLD.name || '''. It owns ' || v_bus_count ||
            ' bus(es). Please reassign them first. (Examples: ' || v_bus_examples || '...)'
        );
    END IF;
END;
/



















--=============================================================================
-- Demonstration Script
--=============================================================================
PROMPT =================================================================
PROMPT DEMONSTRATING TRIGGERS
PROMPT =================================================================

--
-- DEMO 1: trg_check_staff_assignment
--
PROMPT --- Testing Trigger 1: Invalid Staff Assignment ---

PROMPT [SETUP] Creating temporary staff and service for a clean test...
DECLARE
    v_service_id Service.service_id%TYPE;
    v_bus_id Bus.bus_id%TYPE;
BEGIN
    -- Clean up from previous runs
    DELETE FROM StaffAllocation WHERE staff_id = 99903;
    DELETE FROM Staff WHERE staff_id = 99903;
    DELETE FROM ServiceDetails WHERE service_transaction_id = 99998;
    COMMIT;

    -- Create a temporary 'Cleaner' staff member
    INSERT INTO Staff(staff_id, name, role, email, contact_no, employment_date, status)
    VALUES (99903, 'Test Cleaner Dave', 'Cleaner', 'cleaner.dave@test.com', '111', SYSDATE, 'Active');

    -- Create a temporary service transaction to assign to
    SELECT service_id, bus_id INTO v_service_id, v_bus_id FROM ServiceDetails WHERE ROWNUM = 1;
    INSERT INTO ServiceDetails(service_transaction_id, service_date, actual_cost, service_id, bus_id)
    VALUES (99998, SYSDATE, 100, v_service_id, v_bus_id);
    COMMIT;
END;
/

PROMPT [SUCCESS CASE 1.1] Assigning an active staff member to a matching role.
BEGIN
    INSERT INTO StaffAllocation(service_transaction_id, staff_id, role)
    VALUES (99998, 99903, 'Cleaner'); -- Role matches Staff table
    DBMS_OUTPUT.PUT_LINE('Success: Active staff member assigned to a matching role.');
    ROLLBACK; -- Rollback to keep test environment clean for next step
END;
/

PROMPT [FAILURE CASE 1.2] Assigning a staff member to a mismatched role.
BEGIN
    INSERT INTO StaffAllocation(service_transaction_id, staff_id, role)
    VALUES (99998, 99903, 'Technician'); -- Role MISMATCH
END;
/

PROMPT [FAILURE CASE 1.3] Assigning an inactive staff member.
-- First, make the staff member inactive
UPDATE Staff SET status = 'On Leave' WHERE staff_id = 99903;
COMMIT;
BEGIN
    INSERT INTO StaffAllocation(service_transaction_id, staff_id, role)
    VALUES (99998, 99903, 'Cleaner'); -- Status is now 'On Leave'
END;
/

PROMPT [CLEANUP] Removing temporary staff and service data...
BEGIN
    DELETE FROM StaffAllocation WHERE staff_id = 99903;
    DELETE FROM Staff WHERE staff_id = 99903;
    DELETE FROM ServiceDetails WHERE service_transaction_id = 99998;
    COMMIT;
END;
/

--
-- DEMO 2: trg_prevent_company_deletion
--
PROMPT --- Testing Trigger 2: Prevent Company Deletion with Diagnostics ---

PROMPT [SETUP] Creating a temporary company and assigning buses to it...
BEGIN
    -- Clean up from previous runs
    DELETE FROM Bus WHERE company_id = 999;
    DELETE FROM Company WHERE company_id = 999;
    COMMIT;

    -- Create company and buses
    INSERT INTO Company(company_id, name) VALUES (999, 'Temp Test Transport');
    INSERT INTO Bus(bus_id, plate_number, capacity, company_id) VALUES (bus_seq.NEXTVAL, 'TEST-001', 50, 999);
    INSERT INTO Bus(bus_id, plate_number, capacity, company_id) VALUES (bus_seq.NEXTVAL, 'TEST-002', 50, 999);
    INSERT INTO Bus(bus_id, plate_number, capacity, company_id) VALUES (bus_seq.NEXTVAL, 'TEST-003', 50, 999);
    COMMIT;
END;
/
PROMPT Current buses for 'Temp Test Transport':
SELECT plate_number FROM Bus WHERE company_id = 999;

PROMPT [FAILURE CASE 2.1] Attempting to delete the company while it still owns buses.
BEGIN
    DELETE FROM Company WHERE company_id = 999;
END;
/

PROMPT [SUCCESS CASE 2.2] Deleting the buses first, then deleting the company.
BEGIN
    -- First, reassign or delete the buses
    DELETE FROM Bus WHERE company_id = 999;
    -- Now, delete the company
    DELETE FROM Company WHERE company_id = 999;
    DBMS_OUTPUT.PUT_LINE('Success: Company with ID 999 deleted after its buses were removed.');
    COMMIT;
END;
/
-- Verification: Check if company is gone
SELECT COUNT(*) FROM Company WHERE company_id = 999;