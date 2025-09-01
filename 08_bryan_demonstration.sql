--=============================================================================
-- File: 08_demonstration.sql
--=============================================================================
-- Purpose: A clear, step-by-step demonstration of the project's features.
--          Each test shows a success case and a failure case to prove
--          the system's logic and error handling.
--=============================================================================

SET SERVEROUTPUT ON SIZE 1000000;

-- --=============================================================================
-- -- TASK 4: STORED PROCEDURES DEMONSTRATION
-- --=============================================================================


---
--- --- Testing Procedure 1: Add_New_Staff ---

--- [TEST 1.1] SUCCESS CASE: Adding a new, unique staff member.
BEGIN
    Add_New_Staff(
        p_name       => 'David Chen',
        p_role       => 'Manager',
        p_email      => 'david.chen@busstation.com',
        p_contact_no => '555-8888'
    );
END;
/

-- Verification Step
SELECT staff_id, name, email FROM Staff WHERE email = 'david.chen@busstation.com';


--- [TEST 1.2] FAILURE CASE: Attempting to add a staff member with a duplicate email.
BEGIN
    Add_New_Staff(
        p_name       => 'David Fake',
        p_role       => 'Cleaner',
        p_email      => 'david.chen@busstation.com', -- This email now exists
        p_contact_no => '555-9999'
    );
END;
/


---
--- --- Testing Procedure 2: Assign_Driver_To_Schedule ---

--- [TEST 2.1] SUCCESS CASE: Assigning Driver 15 to Schedule 25.
BEGIN
    Assign_Driver_To_Schedule(p_schedule_id => 25, p_driver_id => 15);
END;
/

-- Verification Step
SELECT * FROM DriverList WHERE schedule_id = 25 AND driver_id = 15;


--- [TEST 2.2] FAILURE CASE: Attempting the same assignment again.
BEGIN
    Assign_Driver_To_Schedule(p_schedule_id => 25, p_driver_id => 15);
END;
/


--=============================================================================
-- TASK 5: TRIGGERS DEMONSTRATION
--=============================================================================

---
--- --- Testing Trigger 1: trg_check_active_staff_assignment ---
--- --- Testing Trigger to Prevent Inactive Staff Assignment ---

-- Let's use Staff ID 1 and Service Transaction ID 15 for this test.
-- First, confirm the staff member's initial status.
SELECT name, status FROM Staff WHERE staff_id = 1;

--- [TEST 3.1] SUCCESS CASE: Assign an 'Active' staff member to a task.
BEGIN
    INSERT INTO StaffAllocation(service_transaction_id, staff_id, role)
    VALUES (15, 1, 'Technician');
    DBMS_OUTPUT.PUT_LINE('Success: Active staff member assigned correctly.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failure: ' || SQLERRM);
END;
/
-- Verification Step
SELECT * FROM StaffAllocation WHERE service_transaction_id = 15 AND staff_id = 1;


--- [TEST 3.2] FAILURE CASE: Attempt to assign the same staff member after making them inactive.
-- First, change the status to 'Resigned'.
UPDATE Staff SET status = 'Resigned' WHERE staff_id = 1;
COMMIT;
SELECT name, status FROM Staff WHERE staff_id = 1;

-- Now, attempt to assign them to another task (Service Transaction ID 16).
BEGIN
    INSERT INTO StaffAllocation(service_transaction_id, staff_id, role)
    VALUES (16, 1, 'Technician');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failure as expected: ' || SQLERRM);
END;
/

-- Cleanup: Revert staff status back to 'Active' for consistency.
UPDATE Staff SET status = 'Active' WHERE staff_id = 1;
DELETE FROM StaffAllocation WHERE service_transaction_id = 15 AND staff_id = 1;
COMMIT;


--- End of Staff Assignment Trigger Test ---


---
--- --- Testing Trigger 2: trg_prevent_company_deletion ---

--- [TEST 4.1] FAILURE CASE: Attempting to delete a company that still owns buses.
--- First, let's confirm Company ID 3 owns buses:
SELECT bus_id FROM Bus WHERE company_id = 3 AND ROWNUM <= 5;

--- Now, we attempt to delete the company...
BEGIN
    DELETE FROM Company WHERE company_id = 3;
END;
/


--=============================================================================
-- TASK 6: REPORTS DEMONSTRATION
--=============================================================================

---
--- --- Testing Report 1: rpt_campaign_performance ---

--- [TEST 5.1] Generating campaign performance report for 2025 (a year with data).
BEGIN
    rpt_campaign_performance(p_year => 2025);
END;
/

--- [TEST 5.2] Generating campaign performance report for 2020 (a year with no data).
BEGIN
    rpt_campaign_performance(p_year => 2020);
END;
/


---
--- --- Testing Report 2: rpt_bus_maintenance_history ---

--- [TEST 6.1] Generating maintenance history for Bus ID 15 (a bus with service records).
BEGIN
    rpt_bus_maintenance_history(p_bus_id => 15);
END;
/

--- [TEST 6.2] Generating maintenance history for a non-existent Bus ID 99999.
BEGIN
    rpt_bus_maintenance_history(p_bus_id => 99999);
END;
/


--=============================================================================
-- TASK 7: USER-DEFINED FUNCTION DEMONSTRATION
--=============================================================================

---
--- --- Testing Function: calculate_final_ticket_price ---

--- [TEST 7.1] Using the function in a query to verify a booking's total amount.
--- Check Booking ID 4, which may have promotions.

COLUMN stored_booking_total FORMAT 99,990.00 HEADING 'Stored Total'
COLUMN calculated_booking_total FORMAT 99,990.00 HEADING 'Calculated Total'
COLUMN difference FORMAT 99,990.00 HEADING 'Difference'

SELECT
    b.booking_id,
    b.total_amount AS stored_booking_total,
    SUM(calculate_final_ticket_price(t.ticket_id)) AS calculated_booking_total,
    b.total_amount - SUM(calculate_final_ticket_price(t.ticket_id)) AS difference
FROM Booking b
JOIN BookingDetails bd ON b.booking_id = bd.booking_id
JOIN Ticket t ON bd.ticket_id = t.ticket_id
WHERE b.booking_id = 4
GROUP BY
    b.booking_id,
    b.total_amount;

CLEAR COLUMNS;