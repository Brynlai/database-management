--=============================================================================
-- File: 04_stored_procedures.sql
--=============================================================================
-- Purpose: Implements the core business logic of the system through
--          reusable, secure, and maintainable stored procedures.
--=============================================================================

SET SERVEROUTPUT ON;

--=============================================================================
-- Section 1: Administrative Procedures
--=============================================================================

PROMPT Creating Procedure: Add_New_Staff
CREATE OR REPLACE PROCEDURE Add_New_Staff (
    p_name          IN Staff.name%TYPE,
    p_role          IN Staff.role%TYPE,
    p_email         IN Staff.email%TYPE,
    p_contact_no    IN Staff.contact_no%TYPE,
    p_status        IN Staff.status%TYPE DEFAULT 'Active'
)
AS
    -- No local variables
BEGIN
    INSERT INTO Staff (
        staff_id,
        name,
        role,
        email,
        contact_no,
        employment_date,
        status
    )
    VALUES (
        staff_seq.NEXTVAL,
        p_name,
        p_role,
        p_email,
        p_contact_no,
        SYSDATE, -- Employment date set to current system date
        p_status
    );

    DBMS_OUTPUT.PUT_LINE('Successfully added new staff member: ' || p_name);
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Error: A staff member with the email ''' || p_email || ''' already exists.');

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'An unexpected error occurred. Oracle error code: ' || SQLCODE || ' - ' || SQLERRM);
END Add_New_Staff;
/

PROMPT Creating Procedure: Assign_Driver_To_Schedule
CREATE OR REPLACE PROCEDURE Assign_Driver_To_Schedule (
    p_schedule_id   IN Schedule.schedule_id%TYPE,
    p_driver_id     IN Driver.driver_id%TYPE,
    p_notes         IN DriverList.assignment_notes%TYPE DEFAULT NULL
)
AS
    v_schedule_count NUMBER;
    v_driver_count   NUMBER;
BEGIN
    -- Step 1: Validate that the schedule exists to prevent foreign key errors.
    SELECT COUNT(*) INTO v_schedule_count FROM Schedule WHERE schedule_id = p_schedule_id;
    
    IF v_schedule_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Error: Schedule with ID ' || p_schedule_id || ' does not exist.');
    END IF;

    -- Step 2: Validate that the driver exists.
    SELECT COUNT(*) INTO v_driver_count FROM Driver WHERE driver_id = p_driver_id;
    
    IF v_driver_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Error: Driver with ID ' || p_driver_id || ' does not exist.');
    END IF;

    -- Step 3: If validation passes, insert the new assignment.
    INSERT INTO DriverList (
        schedule_id,
        driver_id,
        assignment_notes
    ) VALUES (
        p_schedule_id,
        p_driver_id,
        p_notes
    );

    DBMS_OUTPUT.PUT_LINE('Successfully assigned driver ' || p_driver_id || ' to schedule ' || p_schedule_id || '.');
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20012, 'Error: Driver ' || p_driver_id || ' is already assigned to schedule ' || p_schedule_id || '.');

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END Assign_Driver_To_Schedule;
/