--=============================================================================
-- File: oracle_xe112_complete_solution.sql
-- Target: Oracle XE 11g Release 2
-- Purpose: Complete solution with properly formatted output and column headers
--=============================================================================
-- REQUIREMENTS IMPLEMENTED:
-- 1. RentalCollection Table: Validate staff_id has Manager role before rental payment
-- 2. ServiceDetails Table: Validate bus_id exists before logging service
--
-- ANALYSIS FROM YOUR DATABASE:
-- Active Manager staff IDs: 4, 33, 53, 90, 93, 107, 118
-- We'll use staff_id = 4 (LeBron James 3, Manager, Active) for success test
-- We'll use staff_id = 1 (Tiffany Williams, Counter Staff, Active) for failure test
--=============================================================================

SET SERVEROUTPUT ON 
SET LINESIZE 120
SET PAGESIZE 50
SET FEEDBACK OFF
SET HEADING ON

PROMPT Testing the two required triggers with correct Active staff members
PROMPT

--=============================================================================
-- TRIGGER 1: RENTAL COLLECTION MANAGER VALIDATION
--=============================================================================
-- Purpose: Ensure only staff with Manager role can perform rental collections
CREATE OR REPLACE TRIGGER trg_validate_manager_rental
    BEFORE INSERT OR UPDATE ON RentalCollection
    FOR EACH ROW
DECLARE
    v_staff_role VARCHAR2(50);
BEGIN
    -- Get the role of the staff member
    SELECT role INTO v_staff_role
    FROM Staff
    WHERE staff_id = :NEW.staff_id;
    
    -- Check if the staff member has Manager role
    IF v_staff_role != 'Manager' THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Only staff members with Manager role can perform rental collections. ' ||
            'Staff ID ' || :NEW.staff_id || ' has role: ' || v_staff_role);
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 
            'Invalid staff_id: ' || :NEW.staff_id || ' does not exist in Staff table');
END;
/

PROMPT Trigger 1 Created: trg_validate_manager_rental
PROMPT

--=============================================================================
-- TRIGGER 2: SERVICE DETAILS BUS VALIDATION  
--=============================================================================
-- Purpose: Ensure bus_id exists before logging service work
CREATE OR REPLACE TRIGGER trg_validate_bus_service
    BEFORE INSERT OR UPDATE ON ServiceDetails
    FOR EACH ROW
DECLARE
    v_bus_count NUMBER;
BEGIN
    -- Check if the bus_id exists in Bus table
    SELECT COUNT(*)
    INTO v_bus_count
    FROM Bus
    WHERE bus_id = :NEW.bus_id;
    
    -- If bus doesn't exist, raise error
    IF v_bus_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 
            'Cannot log service for non-existent vehicle. ' ||
            'Bus ID ' || :NEW.bus_id || ' does not exist in Bus table');
    END IF;
END;
/

PROMPT Trigger 2 Created: trg_validate_bus_service
PROMPT

PROMPT =============================================================================
PROMPT TRIGGER TESTING SECTION
PROMPT =============================================================================

--=============================================================================
-- TEST 1: RENTAL COLLECTION - SUCCESS CASE (Active Manager)
--=============================================================================
PROMPT TEST 1: RentalCollection with Active Manager (should succeed):
BEGIN
    INSERT INTO RentalCollection (rental_id, rental_date, amount, collection_date, rental_method, remark, shop_id, staff_id)
    VALUES (rental_collection_seq.NEXTVAL, SYSDATE, 100.00, SYSDATE, 'Cash', 'Test - Active Manager Success', 1, 33);
    DBMS_OUTPUT.PUT_LINE(' SUCCESS: Rental collection by Active Manager allowed (Staff ID: 4 - LeBron James 3)');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/

--=============================================================================
-- TEST 2: RENTAL COLLECTION - FAILURE CASE (Counter Staff)
--=============================================================================
PROMPT TEST 2: RentalCollection with Counter Staff (should fail):
BEGIN
    INSERT INTO RentalCollection (rental_id, rental_date, amount, collection_date, rental_method, remark, shop_id, staff_id)
    VALUES (rental_collection_seq.NEXTVAL, SYSDATE, 100.00, SYSDATE, 'Cash', 'Test - Counter Staff Fail', 1, 1);
    DBMS_OUTPUT.PUT_LINE(' ERROR: This should not appear - trigger should have prevented this');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' EXPECTED ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/

--=============================================================================
-- TEST 3: RENTAL COLLECTION - FAILURE CASE (Invalid staff_id)
--=============================================================================
PROMPT TEST 3: RentalCollection with invalid staff_id (should fail):
BEGIN
    INSERT INTO RentalCollection (rental_id, rental_date, amount, collection_date, rental_method, remark, shop_id, staff_id)
    VALUES (rental_collection_seq.NEXTVAL, SYSDATE, 100.00, SYSDATE, 'Cash', 'Test - Invalid Staff', 1, 999);
    DBMS_OUTPUT.PUT_LINE(' ERROR: This should not appear - trigger should have prevented this');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' EXPECTED ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/

--=============================================================================
-- TEST 4: SERVICE DETAILS - SUCCESS CASE (Valid bus_id)
--=============================================================================
PROMPT TEST 4: ServiceDetails with valid bus_id (should succeed):
BEGIN
    INSERT INTO ServiceDetails (service_transaction_id, service_date, actual_cost, remarks, service_id, bus_id)
    VALUES (service_details_seq.NEXTVAL, SYSDATE, 55.00, 'Test - Valid Bus Success', 1, 1);
    DBMS_OUTPUT.PUT_LINE(' SUCCESS: Service logged for existing bus (Bus ID: 1)');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/

--=============================================================================
-- TEST 5: SERVICE DETAILS - FAILURE CASE (Invalid bus_id)
--=============================================================================
PROMPT TEST 5: ServiceDetails with invalid bus_id (should fail):
BEGIN
    INSERT INTO ServiceDetails (service_transaction_id, service_date, actual_cost, remarks, service_id, bus_id)
    VALUES (service_details_seq.NEXTVAL, SYSDATE, 55.00, 'Test - Invalid Bus', 1, 999);
    DBMS_OUTPUT.PUT_LINE(' ERROR: This should not appear - trigger should have prevented this');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' EXPECTED ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT
PROMPT =============================================================================
PROMPT DATABASE VERIFICATION QUERIES WITH PROPER HEADERS
PROMPT =============================================================================

-- Show all Active Manager staff members used in tests
PROMPT
PROMPT *** ACTIVE MANAGER STAFF MEMBERS USED IN SUCCESSFUL TESTS ***
COLUMN staff_id FORMAT 999999 HEADING 'Staff|ID'
COLUMN name FORMAT A20 HEADING 'Employee Name'
COLUMN role FORMAT A15 HEADING 'Role'
COLUMN status FORMAT A10 HEADING 'Status'
COLUMN employment_date FORMAT A12 HEADING 'Employment|Date'

SELECT 
    staff_id,
    name,
    role,
    status,
    TO_CHAR(employment_date, 'DD-MON-YY') as employment_date
FROM Staff 
WHERE staff_id IN (4, 33, 53) AND role = 'Manager'
ORDER BY staff_id;

-- Show Counter Staff used in failure test
PROMPT
PROMPT *** COUNTER STAFF MEMBER USED IN FAILURE TEST ***
SELECT 
    staff_id,
    name,
    role,
    status,
    TO_CHAR(employment_date, 'DD-MON-YY') as employment_date
FROM Staff 
WHERE staff_id = 1;

-- Display test records created today
PROMPT
PROMPT *** TEST RECORDS CREATED DURING THIS EXECUTION ***
COLUMN table_name FORMAT A15 HEADING 'Table Name'
COLUMN record_id FORMAT 999999 HEADING 'Record|ID'
COLUMN staff_bus_id FORMAT 999999 HEADING 'Staff/Bus|ID'
COLUMN amount FORMAT 999.99 HEADING 'Amount'
COLUMN remark FORMAT A30 HEADING 'Remark'
COLUMN record_date FORMAT A12 HEADING 'Record|Date'

SELECT 
    'RentalCollection' as table_name, 
    rental_id as record_id, 
    staff_id as staff_bus_id, 
    amount, 
    remark,
    TO_CHAR(rental_date, 'DD-MON-YY') as record_date
FROM RentalCollection
WHERE remark LIKE 'Test%' AND rental_date >= TRUNC(SYSDATE)
UNION ALL
SELECT 
    'ServiceDetails' as table_name, 
    service_transaction_id as record_id, 
    bus_id as staff_bus_id, 
    actual_cost as amount, 
    remarks as remark,
    TO_CHAR(service_date, 'DD-MON-YY') as record_date
FROM ServiceDetails
WHERE remarks LIKE 'Test%' AND service_date >= TRUNC(SYSDATE)
ORDER BY table_name, record_id DESC;

-- Show all Active Managers available for future testing
PROMPT
PROMPT *** ALL ACTIVE MANAGER STAFF MEMBERS AVAILABLE FOR TESTING ***
COLUMN staff_id FORMAT 999999 HEADING 'Staff|ID'
COLUMN name FORMAT A20 HEADING 'Employee Name'
COLUMN role FORMAT A15 HEADING 'Role'
COLUMN status FORMAT A10 HEADING 'Status'

SELECT 
    staff_id,
    name,
    role,
    status
FROM Staff 
WHERE role = 'Manager' AND status = 'Active'
ORDER BY staff_id;

-- Show available buses for ServiceDetails testing
PROMPT
PROMPT *** AVAILABLE BUSES FOR SERVICEDETAILS TESTING ***
COLUMN bus_id FORMAT 999999 HEADING 'Bus|ID'
COLUMN plate_number FORMAT A15 HEADING 'Plate Number'
COLUMN capacity FORMAT 999999 HEADING 'Capacity'
COLUMN company_id FORMAT 999999 HEADING 'Company|ID'

SELECT 
    bus_id,
    plate_number,
    capacity,
    company_id
FROM Bus
WHERE ROWNUM <= 5
ORDER BY bus_id;

-- Show trigger status with proper formatting
PROMPT
PROMPT *** CURRENT TRIGGER STATUS ***
COLUMN trigger_name FORMAT A30 HEADING 'Trigger Name'
COLUMN status FORMAT A10 HEADING 'Status'
COLUMN triggering_event FORMAT A20 HEADING 'Triggering Event'
COLUMN table_name FORMAT A20 HEADING 'Table Name'

SELECT 
    trigger_name,
    status,
    triggering_event,
    table_name
FROM user_triggers
WHERE trigger_name IN ('TRG_VALIDATE_MANAGER_RENTAL', 'TRG_VALIDATE_BUS_SERVICE')
ORDER BY trigger_name;

