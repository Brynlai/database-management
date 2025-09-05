-- =============================================================================
-- Bus Station Management System - Stored Procedures
-- Focus: Ticket Management & Refunds
-- =============================================================================

SET SERVEROUTPUT ON;

PROMPT Creating stored procedures for ticket management...

-- Create sequence for refund and extension IDs
BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE refund_seq START WITH 1 INCREMENT BY 1';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            -- Sequence already exists, adjust it to current max refund_id + 1
            DECLARE
                v_max_refund_id NUMBER;
            BEGIN
                SELECT NVL(MAX(refund_id), 0) + 1 INTO v_max_refund_id FROM Refund;
                EXECUTE IMMEDIATE 'DROP SEQUENCE refund_seq';
                EXECUTE IMMEDIATE 'CREATE SEQUENCE refund_seq START WITH ' || v_max_refund_id || ' INCREMENT BY 1';
            END;
        ELSE
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE extension_seq START WITH 1 INCREMENT BY 1';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            -- Sequence already exists, adjust it to current max extension_id + 1
            DECLARE
                v_max_extension_id NUMBER;
            BEGIN
                SELECT NVL(MAX(extension_id), 0) + 1 INTO v_max_extension_id FROM Extension;
                EXECUTE IMMEDIATE 'DROP SEQUENCE extension_seq';
                EXECUTE IMMEDIATE 'CREATE SEQUENCE extension_seq START WITH ' || v_max_extension_id || ' INCREMENT BY 1';
            END;
        ELSE
            RAISE;
        END IF;
END;
/

-- =============================================================================
-- STORED PROCEDURE 1: ticket_cancel_and_refund
-- Purpose: Process a 70% refund if ticket cancellation is more than 48 hours before departure
-- Business Rule: Cancellation must be made more than 48 hours prior to departure
-- =============================================================================

CREATE OR REPLACE PROCEDURE ticket_cancel_and_refund (
    p_ticket_id IN NUMBER,
    p_refund_method IN VARCHAR2 DEFAULT 'Online Banking',
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) AS
    v_departure_time DATE;
    v_ticket_status VARCHAR2(20);
    v_base_price NUMBER(10,2);
    v_refund_amount NUMBER(10,2);
    v_hours_until_departure NUMBER;
    v_existing_refund_count NUMBER;
    v_existing_extension_count NUMBER;
    v_refund_id NUMBER;
    
    -- Custom exceptions
    ticket_not_found EXCEPTION;
    ticket_not_booked EXCEPTION;
    too_close_to_departure EXCEPTION;
    ticket_already_processed EXCEPTION;
    invalid_refund_method EXCEPTION;
    
BEGIN
    -- Initialize output parameters
    p_success := 0;
    p_message := '';
    
    -- Validate refund method
    IF p_refund_method NOT IN ('Credit Card', 'Debit Card', 'Online Banking', 'E-Wallet') THEN
        RAISE invalid_refund_method;
    END IF;
    
    -- Get ticket information
    BEGIN
        SELECT s.departure_time, t.status, s.base_price
        INTO v_departure_time, v_ticket_status, v_base_price
        FROM Ticket t
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE t.ticket_id = p_ticket_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ticket_not_found;
    END;
    
    -- Check if ticket is in 'Booked' status
    IF v_ticket_status != 'Booked' THEN
        RAISE ticket_not_booked;
    END IF;
    
    -- Calculate hours until departure
    v_hours_until_departure := (v_departure_time - SYSDATE) * 24;
    
    -- Check if cancellation is more than 48 hours before departure
    IF v_hours_until_departure <= 48 THEN
        RAISE too_close_to_departure;
    END IF;
    
    -- Check if ticket has already been refunded or extended
    SELECT COUNT(*) INTO v_existing_refund_count 
    FROM Refund WHERE ticket_id = p_ticket_id;
    
    SELECT COUNT(*) INTO v_existing_extension_count 
    FROM Extension WHERE ticket_id = p_ticket_id;
    
    IF v_existing_refund_count > 0 OR v_existing_extension_count > 0 THEN
        RAISE ticket_already_processed;
    END IF;
    
    -- Calculate 70% refund amount
    v_refund_amount := ROUND(v_base_price * 0.70, 2);
    
    -- Get next refund ID
    SELECT refund_seq.NEXTVAL INTO v_refund_id FROM DUAL;
    
    -- Insert refund record
    INSERT INTO Refund (
        refund_id,
        refund_date,
        amount,
        refund_method,
        ticket_id
    ) VALUES (
        v_refund_id,
        SYSDATE,
        v_refund_amount,
        p_refund_method,
        p_ticket_id
    );
    
    -- Update ticket status to 'Cancelled'
    UPDATE Ticket 
    SET status = 'Cancelled' 
    WHERE ticket_id = p_ticket_id;
    
    -- Commit the transaction
    COMMIT;
    
    -- Set success parameters with clean formatting
    p_success := 1;
    p_message := 'CANCELLATION SUCCESSFUL' || CHR(10) ||
                 '  Ticket ID .........: ' || TO_CHAR(p_ticket_id) || CHR(10) ||
                 '  Refund Amount .....: RM ' || TO_CHAR(ROUND(v_refund_amount, 2)) || CHR(10) ||
                 '  Refund Percentage .: ' || TO_CHAR(ROUND((v_refund_amount/v_base_price)*100, 1)) || '%' || CHR(10) ||
                 '  Hours Until Departure: ' || TO_CHAR(ROUND(v_hours_until_departure, 1));
    
EXCEPTION
    WHEN ticket_not_found THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error: Ticket ID ' || p_ticket_id || ' not found.';
        
    WHEN ticket_not_booked THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error: Ticket ID ' || p_ticket_id || ' is not in booked status. Current status: ' || v_ticket_status;
        
    WHEN too_close_to_departure THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'CANCELLATION DENIED' || CHR(10) ||
                     '  Reason ...........: Too close to departure' || CHR(10) ||
                     '  Hours Remaining ..: ' || TO_CHAR(ROUND(v_hours_until_departure, 1)) || CHR(10) ||
                     '  Minimum Required .: 48.0 hours';
        
    WHEN ticket_already_processed THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error: Ticket ID ' || p_ticket_id || ' has already been refunded or extended.';
        
    WHEN invalid_refund_method THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error: Invalid refund method. Allowed methods: Credit Card, Debit Card, Online Banking, E-Wallet.';
        
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Unexpected error: ' || SQLERRM;
END ticket_cancel_and_refund;
/

-- =============================================================================
-- STORED PROCEDURE 2: ticket_extend_validity
-- Purpose: Extend ticket validity with current price plus RM 5 administrative fee
-- Business Rule: Extension must be made more than 48 hours prior to departure
-- =============================================================================

CREATE OR REPLACE PROCEDURE ticket_extend_validity (
    p_ticket_id IN NUMBER,
    p_extension_method IN VARCHAR2 DEFAULT 'Online Banking',
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) AS
    v_departure_time DATE;
    v_ticket_status VARCHAR2(20);
    v_base_price NUMBER(10,2);
    v_extension_amount NUMBER(10,2);
    v_hours_until_departure NUMBER;
    v_existing_refund_count NUMBER;
    v_existing_extension_count NUMBER;
    v_extension_id NUMBER;
    
    -- Custom exceptions
    ticket_not_found EXCEPTION;
    ticket_not_booked EXCEPTION;
    too_close_to_departure EXCEPTION;
    ticket_already_processed EXCEPTION;
    invalid_extension_method EXCEPTION;
    
BEGIN
    -- Initialize output parameters
    p_success := 0;
    p_message := '';
    
    -- Validate extension method
    IF p_extension_method NOT IN ('Credit Card', 'Debit Card', 'Online Banking', 'E-Wallet') THEN
        RAISE invalid_extension_method;
    END IF;
    
    -- Get ticket information
    BEGIN
        SELECT s.departure_time, t.status, s.base_price
        INTO v_departure_time, v_ticket_status, v_base_price
        FROM Ticket t
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE t.ticket_id = p_ticket_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ticket_not_found;
    END;
    
    -- Check if ticket is in 'Booked' status
    IF v_ticket_status != 'Booked' THEN
        RAISE ticket_not_booked;
    END IF;
    
    -- Calculate hours until departure
    v_hours_until_departure := (v_departure_time - SYSDATE) * 24;
    
    -- Check if extension is more than 48 hours before departure
    IF v_hours_until_departure <= 48 THEN
        RAISE too_close_to_departure;
    END IF;
    
    -- Check if ticket has already been refunded or extended
    SELECT COUNT(*) INTO v_existing_refund_count 
    FROM Refund WHERE ticket_id = p_ticket_id;
    
    SELECT COUNT(*) INTO v_existing_extension_count 
    FROM Extension WHERE ticket_id = p_ticket_id;
    
    IF v_existing_refund_count > 0 OR v_existing_extension_count > 0 THEN
        RAISE ticket_already_processed;
    END IF;
    
    -- Calculate extension amount (current price + RM 5.00 administrative fee)
    v_extension_amount := v_base_price + 5.00;
    
    -- Get next extension ID
    SELECT extension_seq.NEXTVAL INTO v_extension_id FROM DUAL;
    
    -- Insert extension record
    INSERT INTO Extension (
        extension_id,
        extension_date,
        amount,
        extension_method,
        ticket_id
    ) VALUES (
        v_extension_id,
        SYSDATE,
        v_extension_amount,
        p_extension_method,
        p_ticket_id
    );
    
    -- Update ticket status to 'Extended'
    UPDATE Ticket 
    SET status = 'Extended' 
    WHERE ticket_id = p_ticket_id;
    
    -- Commit the transaction
    COMMIT;
    
    -- Set success parameters with clean formatting
    p_success := 1;
    p_message := 'EXTENSION SUCCESSFUL' || CHR(10) ||
                 '  Ticket ID .........: ' || TO_CHAR(p_ticket_id) || CHR(10) ||
                 '  Original Price ....: RM ' || TO_CHAR(ROUND(v_base_price, 2)) || CHR(10) ||
                 '  Admin Fee .........: RM 5.00' || CHR(10) ||
                 '  Total Extension ...: RM ' || TO_CHAR(ROUND(v_extension_amount, 2)) || CHR(10) ||
                 '  Hours Until Departure: ' || TO_CHAR(ROUND(v_hours_until_departure, 1));
    
EXCEPTION
    WHEN ticket_not_found THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error: Ticket ID ' || p_ticket_id || ' not found.';
        
    WHEN ticket_not_booked THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error: Ticket ID ' || p_ticket_id || ' is not in booked status. Current status: ' || v_ticket_status;
        
    WHEN too_close_to_departure THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'EXTENSION DENIED' || CHR(10) ||
                     '  Reason ...........: Too close to departure' || CHR(10) ||
                     '  Hours Remaining ..: ' || TO_CHAR(ROUND(v_hours_until_departure, 1)) || CHR(10) ||
                     '  Minimum Required .: 48.0 hours';
        
    WHEN ticket_already_processed THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error: Ticket ID ' || p_ticket_id || ' has already been refunded or extended.';
        
    WHEN invalid_extension_method THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error: Invalid extension method. Allowed methods: Credit Card, Debit Card, Online Banking, E-Wallet.';
        
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Unexpected error: ' || SQLERRM;
END ticket_extend_validity;
/

-- =============================================================================
-- Test procedures to demonstrate functionality
-- =============================================================================

PROMPT Creating test procedure for ticket management...

CREATE OR REPLACE PROCEDURE test_ticket_procedures AS
    v_success NUMBER;
    v_message VARCHAR2(4000);
    v_test_ticket_id NUMBER;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TICKET MANAGEMENT PROCEDURES TEST ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Find a booked ticket for testing
    BEGIN
        SELECT ticket_id 
        INTO v_test_ticket_id
        FROM (
            SELECT t.ticket_id
            FROM Ticket t
            INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
            WHERE t.status = 'Booked'
              AND s.departure_time > SYSDATE + 3  -- More than 3 days from now
              AND NOT EXISTS (SELECT 1 FROM Refund r WHERE r.ticket_id = t.ticket_id)
              AND NOT EXISTS (SELECT 1 FROM Extension e WHERE e.ticket_id = t.ticket_id)
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('Ticket ID found: ' || v_test_ticket_id);
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Display ticket validation status
        DECLARE
            v_ticket_status VARCHAR2(20);
            v_refund_count NUMBER;
            v_extension_count NUMBER;
            v_hours_remaining NUMBER;
            v_departure_time DATE;
            v_is_valid VARCHAR2(10);
        BEGIN
            SELECT t.status, s.departure_time,
                   (s.departure_time - SYSDATE) * 24
            INTO v_ticket_status, v_departure_time, v_hours_remaining
            FROM Ticket t
            INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
            WHERE t.ticket_id = v_test_ticket_id;
            
            SELECT COUNT(*) INTO v_refund_count FROM Refund WHERE ticket_id = v_test_ticket_id;
            SELECT COUNT(*) INTO v_extension_count FROM Extension WHERE ticket_id = v_test_ticket_id;
            
            IF v_ticket_status = 'Booked' AND v_refund_count = 0 AND v_extension_count = 0 THEN
                v_is_valid := '[VALID]';
            ELSE
                v_is_valid := '[INVALID]';
            END IF;
            
            DBMS_OUTPUT.PUT_LINE('Ticket Validation Status: ' || v_is_valid);
            DBMS_OUTPUT.PUT_LINE('  - Status: ' || v_ticket_status || ' (Required: Booked)');
            DBMS_OUTPUT.PUT_LINE('  - Previous Refunds: ' || v_refund_count || ' (Required: 0)');
            DBMS_OUTPUT.PUT_LINE('  - Previous Extensions: ' || v_extension_count || ' (Required: 0)');
            DBMS_OUTPUT.PUT_LINE('  - Hours Until Departure: ' || ROUND(v_hours_remaining, 1) || ' (Required: >48)');
        END;
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Test cancellation procedure
        DBMS_OUTPUT.PUT_LINE('--- Testing Ticket Cancellation ---');
        ticket_cancel_and_refund(v_test_ticket_id, 'Online Banking', v_success, v_message);
        
        IF v_success = 1 THEN
            DBMS_OUTPUT.PUT_LINE('SUCCESS: ' || v_message);
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAILURE: ' || v_message);
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No suitable booked tickets found for testing cancellation.');
            DBMS_OUTPUT.PUT_LINE('Please ensure there are booked tickets with departure time > 3 days from now.');
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Find another booked ticket for extension testing
    BEGIN
        SELECT ticket_id 
        INTO v_test_ticket_id
        FROM (
            SELECT t.ticket_id
            FROM Ticket t
            INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
            WHERE t.status = 'Booked'
              AND s.departure_time > SYSDATE + 3  -- More than 3 days from now
              AND NOT EXISTS (SELECT 1 FROM Refund r WHERE r.ticket_id = t.ticket_id)
              AND NOT EXISTS (SELECT 1 FROM Extension e WHERE e.ticket_id = t.ticket_id)
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;
        
        
        DBMS_OUTPUT.PUT_LINE('Ticket ID found for extension: ' || v_test_ticket_id);
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Display ticket validation status for extension
        DECLARE
            v_ticket_status VARCHAR2(20);
            v_refund_count NUMBER;
            v_extension_count NUMBER;
            v_hours_remaining NUMBER;
            v_departure_time DATE;
            v_is_valid VARCHAR2(10);
        BEGIN
            SELECT t.status, s.departure_time,
                   (s.departure_time - SYSDATE) * 24
            INTO v_ticket_status, v_departure_time, v_hours_remaining
            FROM Ticket t
            INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
            WHERE t.ticket_id = v_test_ticket_id;
            
            SELECT COUNT(*) INTO v_refund_count FROM Refund WHERE ticket_id = v_test_ticket_id;
            SELECT COUNT(*) INTO v_extension_count FROM Extension WHERE ticket_id = v_test_ticket_id;
            
            IF v_ticket_status = 'Booked' AND v_refund_count = 0 AND v_extension_count = 0 THEN
                v_is_valid := '[VALID]';
            ELSE
                v_is_valid := '[INVALID]';
            END IF;
            
            DBMS_OUTPUT.PUT_LINE('Ticket Validation Status: ' || v_is_valid);
            DBMS_OUTPUT.PUT_LINE('  - Status: ' || v_ticket_status || ' (Required: Booked)');
            DBMS_OUTPUT.PUT_LINE('  - Previous Refunds: ' || v_refund_count || ' (Required: 0)');
            DBMS_OUTPUT.PUT_LINE('  - Previous Extensions: ' || v_extension_count || ' (Required: 0)');
            DBMS_OUTPUT.PUT_LINE('  - Hours Until Departure: ' || ROUND(v_hours_remaining, 1) || ' (Required: >48)');
        END;
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Test extension procedure
        DBMS_OUTPUT.PUT_LINE('--- Testing Ticket Extension ---');
        ticket_extend_validity(v_test_ticket_id, 'Credit Card', v_success, v_message);
        
        IF v_success = 1 THEN
            DBMS_OUTPUT.PUT_LINE('SUCCESS: ' || v_message);
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAILURE: ' || v_message);
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No suitable booked tickets found for testing extension.');
            DBMS_OUTPUT.PUT_LINE('Please ensure there are booked tickets with departure time > 3 days from now.');
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST COMPLETED ===');
    
END test_ticket_procedures;
/

PROMPT Stored procedures created successfully!


COMMIT;
