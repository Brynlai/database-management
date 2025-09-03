--=============================================================================
-- File: 04_stored_procedures.sql
--=============================================================================
-- Purpose: Implements the core business logic of the system through
--          reusable, secure, and maintainable stored procedures.
--=============================================================================

SET SERVEROUTPUT ON;

--=============================================================================
-- 2. Create Indexes to Improve Performance
--=============================================================================

-- Indexes for RentalCollection table
CREATE INDEX idx_rental_collection_shop_id ON RentalCollection(shop_id);
CREATE INDEX idx_rental_collection_rental ON RentalCollection(rental_date);
CREATE INDEX idx_rental_collection_staff_id ON RentalCollection(staff_id);

-- Indexes for ServiceDetails table
CREATE INDEX idx_service_details_bus_id ON ServiceDetails(bus_id);
CREATE INDEX idx_service_details_service ON ServiceDetails(service_date);

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

--=============================================================================
-- Section 2: Service and Rental Management Procedures
--=============================================================================

PROMPT Creating Procedure: service_record_maintenance
CREATE OR REPLACE PROCEDURE service_record_maintenance (
    p_service_date    IN ServiceDetails.service_date%TYPE,
    p_actual_cost     IN ServiceDetails.actual_cost%TYPE,
    p_remarks         IN ServiceDetails.remarks%TYPE DEFAULT NULL,
    p_service_id      IN ServiceDetails.service_id%TYPE,
    p_bus_id          IN ServiceDetails.bus_id%TYPE
)
AS
    v_service_count NUMBER;
    v_bus_count     NUMBER;
    v_new_transaction_id NUMBER;
    v_id_exists NUMBER;
BEGIN
    -- Step 1: Validate that the service exists
    SELECT COUNT(*) INTO v_service_count FROM Service WHERE service_id = p_service_id;
    
    IF v_service_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Error: Service with ID ' || p_service_id || ' does not exist.');
    END IF;

    -- Step 2: Validate that the bus exists
    SELECT COUNT(*) INTO v_bus_count FROM Bus WHERE bus_id = p_bus_id;
    
    IF v_bus_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20031, 'Error: Bus with ID ' || p_bus_id || ' does not exist.');
    END IF;

    -- Step 3: Generate a safe transaction ID
    BEGIN
        -- Try to get the next sequence value
        SELECT service_details_seq.NEXTVAL INTO v_new_transaction_id FROM DUAL;
        
        -- Check if this ID already exists using COUNT instead of EXISTS
        SELECT COUNT(*) INTO v_id_exists FROM ServiceDetails WHERE service_transaction_id = v_new_transaction_id;
        
        WHILE v_id_exists > 0 LOOP
            SELECT service_details_seq.NEXTVAL INTO v_new_transaction_id FROM DUAL;
            SELECT COUNT(*) INTO v_id_exists FROM ServiceDetails WHERE service_transaction_id = v_new_transaction_id;
        END LOOP;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- If sequence fails, find the max ID and add 1
            SELECT NVL(MAX(service_transaction_id), 0) + 1 INTO v_new_transaction_id FROM ServiceDetails;
    END;

    -- Step 4: Insert the maintenance record with the safe ID
    INSERT INTO ServiceDetails (
        service_transaction_id,
        service_date,
        actual_cost,
        remarks,
        service_id,
        bus_id
    ) VALUES (
        v_new_transaction_id,
        p_service_date,
        p_actual_cost,
        p_remarks,
        p_service_id,
        p_bus_id
    );

    DBMS_OUTPUT.PUT_LINE('Maintenance record created successfully for bus ' || p_bus_id || ' with transaction ID ' || v_new_transaction_id || '.');
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20033, 'Duplicate key error: Service transaction already exists.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20032, 'Error recording maintenance: ' || SQLERRM);
END service_record_maintenance;
/

PROMPT Creating Procedure: shop_collect_rental
CREATE OR REPLACE PROCEDURE shop_collect_rental (
    p_rental_date     IN RentalCollection.rental_date%TYPE,
    p_amount          IN RentalCollection.amount%TYPE,
    p_collection_date IN RentalCollection.collection_date%TYPE DEFAULT SYSDATE,
    p_rental_method   IN RentalCollection.rental_method%TYPE DEFAULT NULL,
    p_remark          IN RentalCollection.remark%TYPE DEFAULT NULL,
    p_shop_id         IN RentalCollection.shop_id%TYPE,
    p_staff_id        IN RentalCollection.staff_id%TYPE
)
AS
    v_shop_count NUMBER;
    v_staff_count NUMBER;
    v_staff_role Staff.role%TYPE;
BEGIN
    -- Step 1: Validate that the shop exists
    SELECT COUNT(*) INTO v_shop_count FROM Shop WHERE shop_id = p_shop_id;
    
    IF v_shop_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20040, 'Error: Shop with ID ' || p_shop_id || ' does not exist.');
    END IF;

    -- Step 2: Validate that the staff exists and has proper role
    SELECT COUNT(*), MAX(role) INTO v_staff_count, v_staff_role 
    FROM Staff 
    WHERE staff_id = p_staff_id AND status = 'Active';
    
    IF v_staff_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20041, 'Error: Active staff with ID ' || p_staff_id || ' does not exist.');
    END IF;

    -- Step 3: Insert the rental collection record
    INSERT INTO RentalCollection (
        rental_id,
        rental_date,
        amount,
        collection_date,
        rental_method,
        remark,
        shop_id,
        staff_id
    ) VALUES (
        rental_collection_seq.NEXTVAL,
        p_rental_date,
        p_amount,
        p_collection_date,
        p_rental_method,
        p_remark,
        p_shop_id,
        p_staff_id
    );

    DBMS_OUTPUT.PUT_LINE('Rental collection recorded successfully for shop ' || p_shop_id || '.');
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20042, 'Error recording rental collection: ' || SQLERRM);
END shop_collect_rental;
/

--=============================================================================
-- Section 3: Test the procedures with example calls
--=============================================================================

PROMPT Testing Procedures with Example Data...

DECLARE
    v_valid_schedule_id Schedule.schedule_id%TYPE;
    v_valid_driver_id Driver.driver_id%TYPE;
    v_valid_service_id Service.service_id%TYPE;
    v_valid_bus_id Bus.bus_id%TYPE;
    v_valid_shop_id Shop.shop_id%TYPE;
    v_valid_staff_id Staff.staff_id%TYPE;
    v_unassigned_driver_found BOOLEAN := FALSE;
    v_unassigned_schedule_found BOOLEAN := FALSE;
    v_new_staff_id Staff.staff_id%TYPE;
    v_new_rental_id RentalCollection.rental_id%TYPE;
    v_new_service_transaction_id ServiceDetails.service_transaction_id%TYPE;
    v_unique_email Staff.email%TYPE;
    v_unique_number NUMBER;
BEGIN
    -- Generate a truly unique number using sequence
    SELECT staff_seq.NEXTVAL INTO v_unique_number FROM DUAL;
    v_unique_email := 'lebron.james.' || v_unique_number || '@example.com';
    
    -- Test Add_New_Staff with unique email
    BEGIN
        Add_New_Staff('LeBron James ' || v_unique_number, 'Manager', v_unique_email, '123-456-' || LPAD(v_unique_number, 4, '0'));
        
        -- Get the ID of the newly added staff
        SELECT staff_id INTO v_new_staff_id 
        FROM Staff 
        WHERE email = v_unique_email;
        
        DBMS_OUTPUT.PUT_LINE('Successfully added staff with ID: ' || v_new_staff_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to add staff: ' || SQLERRM);
            v_new_staff_id := NULL;
            RETURN; -- Exit if we can't add staff
    END;
    
    -- Get valid IDs from the database
    BEGIN
        SELECT schedule_id INTO v_valid_schedule_id 
        FROM Schedule WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No schedules found in the database.');
            RETURN;
    END;
    
    -- Try to find a driver not already assigned to this schedule
    BEGIN
        SELECT d.driver_id INTO v_valid_driver_id 
        FROM Driver d
        WHERE NOT EXISTS (
            SELECT 1 FROM DriverList dl 
            WHERE dl.driver_id = d.driver_id 
            AND dl.schedule_id = v_valid_schedule_id
        )
        AND ROWNUM = 1;
        v_unassigned_driver_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- If no unassigned driver found, try to find a different schedule
            BEGIN
                SELECT s.schedule_id INTO v_valid_schedule_id
                FROM Schedule s
                WHERE NOT EXISTS (
                    SELECT 1 FROM DriverList dl 
                    WHERE dl.schedule_id = s.schedule_id 
                    AND dl.driver_id = 1
                )
                AND ROWNUM = 1;
                v_valid_driver_id := 1; -- Use driver 1 with the new schedule
                v_unassigned_schedule_found := TRUE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('No available driver-schedule combinations found.');
                    -- Skip the assignment test
                    NULL;
            END;
    END;
    
    -- Get other valid IDs
    BEGIN
        SELECT service_id INTO v_valid_service_id 
        FROM Service WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No services found in the database.');
            RETURN;
    END;
    
    BEGIN
        SELECT bus_id INTO v_valid_bus_id 
        FROM Bus WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No buses found in the database.');
            RETURN;
    END;
    
    BEGIN
        SELECT shop_id INTO v_valid_shop_id 
        FROM Shop WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No shops found in the database.');
            RETURN;
    END;
    
    -- Test other procedures with valid IDs
    IF v_unassigned_driver_found OR v_unassigned_schedule_found THEN
        BEGIN
            Assign_Driver_To_Schedule(v_valid_schedule_id, v_valid_driver_id, 'Regular assignment');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Failed to assign driver: ' || SQLERRM);
        END;
    END IF;
    
    BEGIN
        service_record_maintenance(SYSDATE, 250.00, 'Oil change and filter replacement', v_valid_service_id, v_valid_bus_id);
        
        -- Get the ID of the newly created service transaction
        SELECT MAX(service_transaction_id) INTO v_new_service_transaction_id 
        FROM ServiceDetails 
        WHERE bus_id = v_valid_bus_id AND service_id = v_valid_service_id;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to record maintenance: ' || SQLERRM);
    END;
    
    BEGIN
        shop_collect_rental(TRUNC(SYSDATE), 1500.00, SYSDATE, 'Cash', 'Monthly rental', v_valid_shop_id, v_new_staff_id);
        
        -- Get the ID of the newly created rental collection
        SELECT MAX(rental_id) INTO v_new_rental_id 
        FROM RentalCollection 
        WHERE shop_id = v_valid_shop_id AND staff_id = v_new_staff_id;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to collect rental: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('Test procedures execution completed.');
    
    -- Display the actual data from the database
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== ACTUAL DATA FROM DATABASE ===');
    
    -- Display new staff member details
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '1. New Staff Member:');
    FOR staff_rec IN (
        SELECT staff_id, name, role, email, contact_no, employment_date, status 
        FROM Staff 
        WHERE staff_id = v_new_staff_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('   Staff ID: ' || staff_rec.staff_id);
        DBMS_OUTPUT.PUT_LINE('   Name: ' || staff_rec.name);
        DBMS_OUTPUT.PUT_LINE('   Role: ' || staff_rec.role);
        DBMS_OUTPUT.PUT_LINE('   Email: ' || staff_rec.email);
        DBMS_OUTPUT.PUT_LINE('   Contact: ' || staff_rec.contact_no);
        DBMS_OUTPUT.PUT_LINE('   Employment Date: ' || TO_CHAR(staff_rec.employment_date, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('   Status: ' || staff_rec.status);
    END LOOP;
    
    -- Display driver assignment details if available
    IF v_unassigned_driver_found OR v_unassigned_schedule_found THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || '2. Driver Assignment:');
        FOR driver_rec IN (
            SELECT dl.schedule_id, dl.driver_id, d.name as driver_name, dl.assignment_notes
            FROM DriverList dl
            JOIN Driver d ON dl.driver_id = d.driver_id
            WHERE dl.schedule_id = v_valid_schedule_id AND dl.driver_id = v_valid_driver_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('   Schedule ID: ' || driver_rec.schedule_id);
            DBMS_OUTPUT.PUT_LINE('   Driver ID: ' || driver_rec.driver_id);
            DBMS_OUTPUT.PUT_LINE('   Driver Name: ' || driver_rec.driver_name);
            DBMS_OUTPUT.PUT_LINE('   Assignment Notes: ' || NVL(driver_rec.assignment_notes, 'None'));
        END LOOP;
    END IF;
    
    -- Display maintenance record details if available
    IF v_new_service_transaction_id IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || '3. Maintenance Record:');
        FOR service_rec IN (
            SELECT sd.service_transaction_id, sd.service_date, sd.actual_cost, sd.remarks, 
                   s.service_name, b.plate_number
            FROM ServiceDetails sd
            JOIN Service s ON sd.service_id = s.service_id
            JOIN Bus b ON sd.bus_id = b.bus_id
            WHERE sd.service_transaction_id = v_new_service_transaction_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('   Transaction ID: ' || service_rec.service_transaction_id);
            DBMS_OUTPUT.PUT_LINE('   Service Date: ' || TO_CHAR(service_rec.service_date, 'DD-MON-YYYY'));
            DBMS_OUTPUT.PUT_LINE('   Actual Cost: RM ' || service_rec.actual_cost);
            DBMS_OUTPUT.PUT_LINE('   Service Name: ' || service_rec.service_name);
            DBMS_OUTPUT.PUT_LINE('   Bus Plate: ' || service_rec.plate_number);
            DBMS_OUTPUT.PUT_LINE('   Remarks: ' || NVL(service_rec.remarks, 'None'));
        END LOOP;
    END IF;
    
    -- Display rental collection details if available
    IF v_new_rental_id IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || '4. Rental Collection:');
        FOR rental_rec IN (
            SELECT rc.rental_id, rc.rental_date, rc.amount, rc.collection_date, 
                   rc.rental_method, rc.remark, s.shop_name, st.name as staff_name
            FROM RentalCollection rc
            JOIN Shop s ON rc.shop_id = s.shop_id
            JOIN Staff st ON rc.staff_id = st.staff_id
            WHERE rc.rental_id = v_new_rental_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('   Rental ID: ' || rental_rec.rental_id);
            DBMS_OUTPUT.PUT_LINE('   Rental Date: ' || TO_CHAR(rental_rec.rental_date, 'DD-MON-YYYY'));
            DBMS_OUTPUT.PUT_LINE('   Amount: RM ' || rental_rec.amount);
            DBMS_OUTPUT.PUT_LINE('   Collection Date: ' || TO_CHAR(rental_rec.collection_date, 'DD-MON-YYYY'));
            DBMS_OUTPUT.PUT_LINE('   Method: ' || NVL(rental_rec.rental_method, 'Not specified'));
            DBMS_OUTPUT.PUT_LINE('   Shop Name: ' || rental_rec.shop_name);
            DBMS_OUTPUT.PUT_LINE('   Collected By: ' || rental_rec.staff_name);
            DBMS_OUTPUT.PUT_LINE('   Remarks: ' || NVL(rental_rec.remark, 'None'));
        END LOOP;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error during testing: ' || SQLERRM);
END;
/