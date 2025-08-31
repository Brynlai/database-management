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
-- DBMS_OUTPUT.PUT_LINE('');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
-- DBMS_OUTPUT.PUT_LINE('-- Task 4: Stored Procedures Demonstration');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));


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
-- DBMS_OUTPUT.PUT_LINE('');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
-- DBMS_OUTPUT.PUT_LINE('-- Task 5: Triggers Demonstration');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));


---
--- --- Testing Trigger 1: trg_audit_staff_changes ---

--- [TEST 3.1] Updating a staff member's role to activate the audit trigger.
--- First, let's see the current role of Staff ID 20:
SELECT name, role FROM Staff WHERE staff_id = 20;

--- Now, we perform the update...
UPDATE Staff SET role = 'Manager' WHERE staff_id = 20;
COMMIT;

--- The update is done. Let's verify the new role:
SELECT name, role FROM Staff WHERE staff_id = 20;

--- And finally, let's check the Staff_Audit_Log to prove the trigger worked automatically:
SELECT log_id, staff_id, old_role, new_role, changed_by FROM Staff_Audit_Log WHERE staff_id = 20;


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
-- DBMS_OUTPUT.PUT_LINE('');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
-- DBMS_OUTPUT.PUT_LINE('-- Task 6: Reports Demonstration');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));


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
--- We will check Booking ID 4, which may have promotions.

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

DBMS_OUTPUT.PUT_LINE('');
DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
DBMS_OUTPUT.PUT_LINE('-- Demonstration Complete');
DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));