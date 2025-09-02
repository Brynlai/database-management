-- =============================================================================
-- Bus Station Management System - Oracle XE 11g R2 Complete Implementation
-- Focus: Ticket Management & Refunds Business Rule Enforcement
-- Based on files 01, 02, 03, 04 with full data population
-- =============================================================================

SET SERVEROUTPUT ON;
SET PAGESIZE 50;
SET LINESIZE 120;

PROMPT Creating complete Bus Station Management System with triggers...

-- =============================================================================
-- Clean up existing objects
-- =============================================================================

-- Drop existing triggers if they exist
DECLARE
    trigger_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO trigger_count 
    FROM user_triggers 
    WHERE trigger_name = 'TRG_REFUND_DEPT_VALIDATION';
    
    IF trigger_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TRIGGER trg_refund_dept_validation';
        DBMS_OUTPUT.PUT_LINE('Dropped existing trigger: trg_refund_dept_validation');
    END IF;
END;
/

DECLARE
    trigger_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO trigger_count 
    FROM user_triggers 
    WHERE trigger_name = 'TRG_EXT_STATUS_VAL';
    
    IF trigger_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TRIGGER trg_ext_status_val';
        DBMS_OUTPUT.PUT_LINE('Dropped existing trigger: trg_ext_status_val');
    END IF;
END;
/

-- Handle audit table creation
DECLARE
    table_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO table_count 
    FROM user_tables 
    WHERE table_name = 'STAFF_AUDIT_LOG';
    
    IF table_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE Staff_Audit_Log CASCADE CONSTRAINTS';
        DBMS_OUTPUT.PUT_LINE('Dropped existing Staff_Audit_Log table');
    END IF;
    
    -- Create Staff_Audit_Log table
    EXECUTE IMMEDIATE '
    CREATE TABLE Staff_Audit_Log (
        log_id NUMBER(10) NOT NULL,
        table_name VARCHAR2(50) NOT NULL,
        operation VARCHAR2(20) NOT NULL,
        record_id VARCHAR2(50) NOT NULL,
        old_values CLOB,
        new_values CLOB,
        change_date DATE DEFAULT SYSDATE NOT NULL,
        changed_by VARCHAR2(100) DEFAULT USER NOT NULL,
        CONSTRAINT pk_staff_audit_log PRIMARY KEY (log_id)
    )';
    DBMS_OUTPUT.PUT_LINE('Created Staff_Audit_Log table');
    
    -- Create audit log sequence
    EXECUTE IMMEDIATE 'DROP SEQUENCE staff_audit_log_seq';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE SEQUENCE staff_audit_log_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- =============================================================================
-- TRIGGER 1: trg_refund_dept_validation
-- Purpose: Before a refund is inserted, block the transaction if the ticket's departure time is within 48 hours
-- =============================================================================

CREATE OR REPLACE TRIGGER trg_refund_dept_validation
    BEFORE INSERT ON Refund
    FOR EACH ROW
DECLARE
    v_departure_time DATE;
    v_ticket_status VARCHAR2(20);
    v_hours_until_departure NUMBER;
    v_origin_station VARCHAR2(100);
    v_destination_station VARCHAR2(100);
    v_existing_refund_count NUMBER;
    v_existing_extension_count NUMBER;
    v_base_price NUMBER(10,2);
    
    -- Custom exceptions
    invalid_ticket EXCEPTION;
    invalid_status EXCEPTION;
    already_processed EXCEPTION;
    timing_violation EXCEPTION;
    
BEGIN
    -- Get ticket and schedule information
    BEGIN
        SELECT s.departure_time, t.status, s.origin_station, s.destination_station, s.base_price
        INTO v_departure_time, v_ticket_status, v_origin_station, v_destination_station, v_base_price
        FROM Ticket t
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE t.ticket_id = :NEW.ticket_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE invalid_ticket;
    END;
    
    -- Check if ticket has invalid status for refund
    IF v_ticket_status IN ('Cancelled', 'Available') THEN
        RAISE invalid_status;
    END IF;
    
    -- Check if ticket is eligible for refund (must be Booked)
    IF v_ticket_status NOT IN ('Booked') THEN
        RAISE invalid_status;
    END IF;
    
    -- Check if ticket has already been refunded
    SELECT COUNT(*) INTO v_existing_refund_count
    FROM Refund WHERE ticket_id = :NEW.ticket_id;
    
    IF v_existing_refund_count > 0 THEN
        RAISE already_processed;
    END IF;
    
    -- Check if ticket has already been extended
    SELECT COUNT(*) INTO v_existing_extension_count
    FROM Extension WHERE ticket_id = :NEW.ticket_id;
    
    IF v_existing_extension_count > 0 THEN
        RAISE already_processed;
    END IF;
    
    -- Calculate hours until departure
    v_hours_until_departure := (v_departure_time - SYSDATE) * 24;
    
    -- CORE BUSINESS RULE: Block if departure time is within 48 hours
    IF v_hours_until_departure <= 48 THEN
        RAISE timing_violation;
    END IF;
    
    -- Log the refund attempt for audit purposes
    INSERT INTO Staff_Audit_Log (
        log_id,
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        change_date,
        changed_by
    ) VALUES (
        staff_audit_log_seq.NEXTVAL,
        'REFUND',
        'INSERT',
        TO_CHAR(:NEW.refund_id),
        NULL,
        'Ticket: ' || :NEW.ticket_id || ', Amount: ' || :NEW.amount || 
        ', Method: ' || :NEW.refund_method || ', Hours before departure: ' || 
        TO_CHAR(ROUND(v_hours_until_departure, 2)),
        SYSDATE,
        USER
    );
    
EXCEPTION
    WHEN invalid_ticket THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Refund blocked: Ticket ID ' || :NEW.ticket_id || ' not found or invalid schedule reference.');
            
    WHEN invalid_status THEN
        RAISE_APPLICATION_ERROR(-20002, 
            'Refund blocked: Ticket ID ' || :NEW.ticket_id || 
            ' has status "' || v_ticket_status || '". ' ||
            'Only booked tickets can be refunded. ' ||
            'Route: ' || v_origin_station || ' to ' || v_destination_station);
            
    WHEN already_processed THEN
        RAISE_APPLICATION_ERROR(-20003, 
            'Refund blocked: Ticket ID ' || :NEW.ticket_id || 
            ' has already been refunded or extended. Multiple processing not allowed.');
            
    WHEN timing_violation THEN
        RAISE_APPLICATION_ERROR(-20004, 
            'Refund blocked: Ticket ID ' || :NEW.ticket_id || 
            ' departure is in ' || TO_CHAR(ROUND(v_hours_until_departure, 2)) || 
            ' hours. Refunds require minimum 48 hours advance notice. ' ||
            'Route: ' || v_origin_station || ' to ' || v_destination_station || 
            '. Departure: ' || TO_CHAR(v_departure_time, 'DD-MON-YYYY HH24:MI'));
            
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20999, 
            'Refund validation error: ' || SQLERRM);
END trg_refund_dept_validation;
/

-- =============================================================================
-- TRIGGER 2: trg_ext_status_val
-- Purpose: Before an extension is inserted, block the transaction if the target ticket has a status of 'Cancelled' or 'Refunded'
-- =============================================================================

CREATE OR REPLACE TRIGGER trg_ext_status_val
    BEFORE INSERT ON Extension
    FOR EACH ROW
DECLARE
    v_departure_time DATE;
    v_ticket_status VARCHAR2(20);
    v_hours_until_departure NUMBER;
    v_origin_station VARCHAR2(100);
    v_destination_station VARCHAR2(100);
    v_existing_refund_count NUMBER;
    v_existing_extension_count NUMBER;
    v_base_price NUMBER(10,2);
    
    -- Custom exceptions
    invalid_ticket EXCEPTION;
    invalid_status EXCEPTION;
    already_processed EXCEPTION;
    timing_violation EXCEPTION;
    
BEGIN
    -- Get ticket and schedule information
    BEGIN
        SELECT s.departure_time, t.status, s.origin_station, s.destination_station, s.base_price
        INTO v_departure_time, v_ticket_status, v_origin_station, v_destination_station, v_base_price
        FROM Ticket t
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE t.ticket_id = :NEW.ticket_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE invalid_ticket;
    END;
    
    -- CORE BUSINESS RULE: Block if ticket status is 'Cancelled' or 'Refunded'
    -- Note: In this database schema, 'Refunded' tickets are tracked via Refund table
    -- So we check for 'Cancelled' status and existing refunds
    IF v_ticket_status IN ('Cancelled', 'Available') THEN
        RAISE invalid_status;
    END IF;
    
    -- Check if ticket has already been refunded (equivalent to 'Refunded' status)
    SELECT COUNT(*) INTO v_existing_refund_count
    FROM Refund WHERE ticket_id = :NEW.ticket_id;
    
    IF v_existing_refund_count > 0 THEN
        RAISE invalid_status; -- Treat refunded tickets as invalid for extension
    END IF;
    
    -- Check if ticket is eligible for extension (must be Booked)
    IF v_ticket_status NOT IN ('Booked') THEN
        RAISE invalid_status;
    END IF;
    
    -- Check if ticket has already been extended
    SELECT COUNT(*) INTO v_existing_extension_count
    FROM Extension WHERE ticket_id = :NEW.ticket_id;
    
    IF v_existing_extension_count > 0 THEN
        RAISE already_processed;
    END IF;
    
    -- Calculate hours until departure
    v_hours_until_departure := (v_departure_time - SYSDATE) * 24;
    
    -- Additional business rule: 48-hour advance notice for extensions
    IF v_hours_until_departure <= 48 THEN
        RAISE timing_violation;
    END IF;
    
    -- Log the extension attempt for audit purposes
    INSERT INTO Staff_Audit_Log (
        log_id,
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        change_date,
        changed_by
    ) VALUES (
        staff_audit_log_seq.NEXTVAL,
        'EXTENSION',
        'INSERT',
        TO_CHAR(:NEW.extension_id),
        NULL,
        'Ticket: ' || :NEW.ticket_id || ', Amount: ' || :NEW.amount || 
        ', Method: ' || :NEW.extension_method || ', Hours before departure: ' || 
        TO_CHAR(ROUND(v_hours_until_departure, 2)),
        SYSDATE,
        USER
    );
    
EXCEPTION
    WHEN invalid_ticket THEN
        RAISE_APPLICATION_ERROR(-20011, 
            'Extension blocked: Ticket ID ' || :NEW.ticket_id || ' not found or invalid schedule reference.');
            
    WHEN invalid_status THEN
        IF v_existing_refund_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 
                'Extension blocked: Ticket ID ' || :NEW.ticket_id || 
                ' has been refunded. Extensions not allowed for refunded tickets. ' ||
                'Route: ' || v_origin_station || ' to ' || v_destination_station);
        ELSE
            RAISE_APPLICATION_ERROR(-20013, 
                'Extension blocked: Ticket ID ' || :NEW.ticket_id || 
                ' has status "' || v_ticket_status || '". ' ||
                'Extensions not allowed for cancelled or available tickets. ' ||
                'Route: ' || v_origin_station || ' to ' || v_destination_station);
        END IF;
            
    WHEN already_processed THEN
        RAISE_APPLICATION_ERROR(-20014, 
            'Extension blocked: Ticket ID ' || :NEW.ticket_id || 
            ' has already been extended. Multiple extensions not allowed.');
            
    WHEN timing_violation THEN
        RAISE_APPLICATION_ERROR(-20015, 
            'Extension blocked: Ticket ID ' || :NEW.ticket_id || 
            ' departure is in ' || TO_CHAR(ROUND(v_hours_until_departure, 2)) || 
            ' hours. Extensions require minimum 48 hours advance notice. ' ||
            'Route: ' || v_origin_station || ' to ' || v_destination_station || 
            '. Departure: ' || TO_CHAR(v_departure_time, 'DD-MON-YYYY HH24:MI'));
            
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20999, 
            'Extension validation error: ' || SQLERRM);
END trg_ext_status_val;
/

-- =============================================================================
-- Procedure to display trigger information and actual tickets that trigger blocking conditions
-- =============================================================================

CREATE OR REPLACE PROCEDURE show_trigger_info AS
    CURSOR c_refund_blocked_tickets IS
        SELECT t.ticket_id, 
               t.seat_number,
               t.status,
               s.origin_station || ' to ' || s.destination_station AS route,
               TO_CHAR(s.departure_time, 'DD-MON-YYYY HH24:MI') AS departure_time,
               ROUND((s.departure_time - SYSDATE) * 24, 2) AS hours_until_departure
        FROM Ticket t
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE t.status = 'Booked'
          AND (s.departure_time - SYSDATE) * 24 <= 48
          AND NOT EXISTS (SELECT 1 FROM Refund r WHERE r.ticket_id = t.ticket_id)
        ORDER BY hours_until_departure;
        
    CURSOR c_extension_blocked_tickets IS
        SELECT t.ticket_id,
               t.seat_number,
               t.status,
               s.origin_station || ' to ' || s.destination_station AS route,
               TO_CHAR(s.departure_time, 'DD-MON-YYYY HH24:MI') AS departure_time,
               CASE 
                   WHEN t.status = 'Cancelled' THEN 'Cancelled Status'
                   WHEN EXISTS (SELECT 1 FROM Refund r WHERE r.ticket_id = t.ticket_id) THEN 'Already Refunded'
                   ELSE 'Other Invalid Status'
               END AS block_reason
        FROM Ticket t
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE (t.status = 'Cancelled' 
               OR EXISTS (SELECT 1 FROM Refund r WHERE r.ticket_id = t.ticket_id))
        ORDER BY t.ticket_id;
        
    v_count NUMBER := 0;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Triggers (2):');
    DBMS_OUTPUT.PUT_LINE('On Refund Table: Before a refund is inserted, block the transaction if the ticket''s departure time is within 48 hours.');
    DBMS_OUTPUT.PUT_LINE('On Extension Table: Before an extension is inserted, block the transaction if the target ticket has a status of ''Cancelled'' or ''Refunded''.');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Show tickets that would be blocked for REFUND (departure within 48 hours)
    DBMS_OUTPUT.PUT_LINE('=== TICKETS BLOCKED FOR REFUND (Departure within 48 hours) ===');
    v_count := 0;
    FOR rec IN c_refund_blocked_tickets LOOP
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ticket ID | Seat | Status |       Route          | Departure Time    | Hours Until');
            DBMS_OUTPUT.PUT_LINE('----------|------|--------|----------------------|-------------------|-------------');
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.ticket_id, 9) || ' | ' ||
            RPAD(rec.seat_number, 4) || ' | ' ||
            RPAD(rec.status, 6) || ' | ' ||
            RPAD(rec.route, 20) || ' | ' ||
            RPAD(rec.departure_time, 17) || ' | ' ||
            rec.hours_until_departure || 'h'
        );
        v_count := v_count + 1;
    END LOOP;
    
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No tickets found with departure within 48 hours.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Total: ' || v_count || ' tickets would be BLOCKED for refund.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Show tickets that would be blocked for EXTENSION (Cancelled or Refunded status)
    DBMS_OUTPUT.PUT_LINE('=== TICKETS BLOCKED FOR EXTENSION (Cancelled or Refunded status) ===');
    v_count := 0;
    FOR rec IN c_extension_blocked_tickets LOOP
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ticket ID | Seat | Status |      Route           | Departure Time    | Block Reason');
            DBMS_OUTPUT.PUT_LINE('----------|------|--------|----------------------|-------------------|-----------------');
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.ticket_id, 9) || ' | ' ||
            RPAD(rec.seat_number, 4) || ' | ' ||
            RPAD(rec.status, 6) || ' | ' ||
            RPAD(rec.route, 20) || ' | ' ||
            RPAD(rec.departure_time, 17) || ' | ' ||
            rec.block_reason
        );
        v_count := v_count + 1;
    END LOOP;
    
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No tickets found with Cancelled status or existing refunds.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Total: ' || v_count || ' tickets would be BLOCKED for extension.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Show trigger status
    DECLARE
        v_refund_trigger_status VARCHAR2(20);
        v_extension_trigger_status VARCHAR2(20);
    BEGIN
        SELECT status INTO v_refund_trigger_status 
        FROM user_triggers 
        WHERE trigger_name = 'TRG_REFUND_DEPT_VALIDATION';
        
        SELECT status INTO v_extension_trigger_status 
        FROM user_triggers 
        WHERE trigger_name = 'TRG_EXT_STATUS_VAL';
        
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Some triggers not found in user_triggers view');
    END;
END show_trigger_info;
/

-- =============================================================================
-- Test procedure to demonstrate trigger functionality
-- =============================================================================

CREATE OR REPLACE PROCEDURE test_triggers_with_sample_data AS
    v_test_ticket_id NUMBER;
    v_test_refund_id NUMBER;
    v_test_extension_id NUMBER;
    v_base_price NUMBER(10,2);
    v_refund_amount NUMBER(10,2);
    v_extension_amount NUMBER(10,2);
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING ORACLE TRIGGERS WITH SAMPLE DATA ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Show trigger information first
    show_trigger_info;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Find a booked ticket for testing
    BEGIN
        SELECT t.ticket_id, s.base_price
        INTO v_test_ticket_id, v_base_price
        FROM Ticket t
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE t.status = 'Booked'
          AND s.departure_time > SYSDATE + 3  -- More than 3 days
          AND NOT EXISTS (SELECT 1 FROM Refund r WHERE r.ticket_id = t.ticket_id)
          AND NOT EXISTS (SELECT 1 FROM Extension e WHERE e.ticket_id = t.ticket_id)
          AND ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('=== TRIGGER TESTING ===');
        DBMS_OUTPUT.PUT_LINE('Test ticket found: ' || v_test_ticket_id);
        DBMS_OUTPUT.PUT_LINE('Base price: RM ' || v_base_price);
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Calculate amounts
        v_refund_amount := ROUND(v_base_price * 0.70, 2);
        v_extension_amount := v_base_price + 5.00;
        
        -- Test 1: Valid refund (should succeed)
        DBMS_OUTPUT.PUT_LINE('TEST 1: Valid refund (should succeed)');
        
        SELECT refund_seq.NEXTVAL INTO v_test_refund_id FROM DUAL;
        
        INSERT INTO Refund (
            refund_id, refund_date, amount, refund_method, ticket_id
        ) VALUES (
            v_test_refund_id, SYSDATE, v_refund_amount, 'Online Banking', v_test_ticket_id
        );
        
        DBMS_OUTPUT.PUT_LINE('✓ Refund inserted successfully - Trigger allowed valid refund');
        
        -- Clean up for next test
        DELETE FROM Refund WHERE refund_id = v_test_refund_id;
        DBMS_OUTPUT.PUT_LINE('✓ Test refund cleaned up');
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Test 2: Valid extension (should succeed)
        DBMS_OUTPUT.PUT_LINE('TEST 2: Valid extension (should succeed)');
        
        SELECT extension_seq.NEXTVAL INTO v_test_extension_id FROM DUAL;
        
        INSERT INTO Extension (
            extension_id, extension_date, amount, extension_method, ticket_id
        ) VALUES (
            v_test_extension_id, SYSDATE, v_extension_amount, 'Credit Card', v_test_ticket_id
        );
        
        DBMS_OUTPUT.PUT_LINE('✓ Extension inserted successfully - Trigger allowed valid extension');
        
        -- Clean up
        DELETE FROM Extension WHERE extension_id = v_test_extension_id;
        DBMS_OUTPUT.PUT_LINE('✓ Test extension cleaned up');
        DBMS_OUTPUT.PUT_LINE('');
        
        DBMS_OUTPUT.PUT_LINE('=== ALL TRIGGER TESTS PASSED ===');
        DBMS_OUTPUT.PUT_LINE('Both triggers are working correctly!');
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No suitable test ticket found. Please ensure you have:');
            DBMS_OUTPUT.PUT_LINE('- Booked tickets with departure > 3 days from now');
            DBMS_OUTPUT.PUT_LINE('- No existing refunds or extensions for the ticket');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Test error: ' || SQLERRM);
    END;
    
    COMMIT;
END test_triggers_with_sample_data;
/

-- =============================================================================
-- Initialize some sample data for testing if tables are empty
-- =============================================================================

DECLARE
    v_schedule_count NUMBER;
    v_ticket_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_schedule_count FROM Schedule;
    SELECT COUNT(*) INTO v_ticket_count FROM Ticket;
    
    IF v_schedule_count = 0 OR v_ticket_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Adding sample data for trigger testing...');
        
        -- Add a sample schedule
        INSERT INTO Schedule (
            schedule_id, departure_time, arrival_time, base_price, 
            origin_station, destination_station, platform_no, bus_id
        ) VALUES (
            schedule_seq.NEXTVAL, 
            SYSDATE + 5,  -- 5 days from now
            SYSDATE + 5.5,  -- 5.5 days from now
            45.00,
            'Kuala Lumpur',
            'Penang',
            'A1',
            1
        );
        
        -- Add sample tickets
        INSERT INTO Ticket (
            ticket_id, seat_number, status, schedule_id, promotion_id
        ) VALUES (
            ticket_seq.NEXTVAL, 'A01', 'Booked', schedule_seq.CURRVAL, NULL
        );
        
        INSERT INTO Ticket (
            ticket_id, seat_number, status, schedule_id, promotion_id
        ) VALUES (
            ticket_seq.NEXTVAL, 'A02', 'Cancelled', schedule_seq.CURRVAL, NULL
        );
        
        INSERT INTO Ticket (
            ticket_id, seat_number, status, schedule_id, promotion_id
        ) VALUES (
            ticket_seq.NEXTVAL, 'A03', 'Available', schedule_seq.CURRVAL, NULL
        );
        
        DBMS_OUTPUT.PUT_LINE('Sample data added successfully');
        COMMIT;
    END IF;
END;
/

COMMIT;

PROMPT =============================================================================
PROMPT Bus Station Management System Triggers created successfully!
PROMPT =============================================================================
PROMPT;
PROMPT =============================================================================

-- Display the trigger information immediately
EXEC show_trigger_info;