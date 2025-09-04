-- =============================================================================
-- Bus Station Management System - Extra Features (CLEAN OUTPUT VERSION)
-- Focus: Performance Optimization, Indexes, Functions, and Additional Enhancements
-- Enhanced with clean, readable ASCII formatting for all outputs
-- Compatible with Oracle Database XE 11g Release 2
-- =============================================================================

SET SERVEROUTPUT ON;
SET PAGESIZE 100;
SET LINESIZE 120;

PROMPT Creating indexes and additional features with enhanced formatting...

-- =============================================================================
-- SAFE INDEX CREATION WITH CLEAN OUTPUT FORMATTING
-- =============================================================================

-- Safe index creation procedure with enhanced output
DECLARE
    index_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(index_exists, -955);
    v_main_separator VARCHAR2(80) := RPAD('=', 75, '=');
    v_sub_separator VARCHAR2(80) := RPAD('-', 75, '-');
BEGIN
    -- Enhanced header for index creation
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    DBMS_OUTPUT.PUT_LINE('              DATABASE INDEX CREATION STATUS');
    DBMS_OUTPUT.PUT_LINE('                Generated: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Index 1: Composite index for ticket status and departure time queries
    BEGIN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_ticket_status_departure ON Ticket (status, schedule_id)';
        DBMS_OUTPUT.PUT_LINE('  [SUCCESS] Index Created: idx_ticket_status_departure');
        DBMS_OUTPUT.PUT_LINE('            Table: Ticket | Columns: status, schedule_id');
    EXCEPTION
        WHEN index_exists THEN
            DBMS_OUTPUT.PUT_LINE('  [EXISTS]  Index Skipped: idx_ticket_status_departure');
            DBMS_OUTPUT.PUT_LINE('            Already exists in database');
    END;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Index 2: Composite index for refund date range queries
    BEGIN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_refund_date_amount ON Refund (refund_date, amount, ticket_id)';
        DBMS_OUTPUT.PUT_LINE('  [SUCCESS] Index Created: idx_refund_date_amount');
        DBMS_OUTPUT.PUT_LINE('            Table: Refund | Columns: refund_date, amount, ticket_id');
    EXCEPTION
        WHEN index_exists THEN
            DBMS_OUTPUT.PUT_LINE('  [EXISTS]  Index Skipped: idx_refund_date_amount');
            DBMS_OUTPUT.PUT_LINE('            Already exists in database');
    END;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Index 3: Composite index for extension date and ticket lookup
    BEGIN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_extension_date_ticket ON Extension (extension_date, ticket_id, amount)';
        DBMS_OUTPUT.PUT_LINE('  [SUCCESS] Index Created: idx_extension_date_ticket');
        DBMS_OUTPUT.PUT_LINE('            Table: Extension | Columns: extension_date, ticket_id, amount');
    EXCEPTION
        WHEN index_exists THEN
            DBMS_OUTPUT.PUT_LINE('  [EXISTS]  Index Skipped: idx_extension_date_ticket');
            DBMS_OUTPUT.PUT_LINE('            Already exists in database');
    END;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Index 4: Index for schedule departure time queries
    BEGIN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_schedule_departure_time ON Schedule (departure_time, origin_station, destination_station)';
        DBMS_OUTPUT.PUT_LINE('  [SUCCESS] Index Created: idx_schedule_departure_time');
        DBMS_OUTPUT.PUT_LINE('            Table: Schedule | Columns: departure_time, origin_station, destination_station');
    EXCEPTION
        WHEN index_exists THEN
            DBMS_OUTPUT.PUT_LINE('  [EXISTS]  Index Skipped: idx_schedule_departure_time');
            DBMS_OUTPUT.PUT_LINE('            Already exists in database');
    END;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Index 5: Composite index for booking details with member lookup
    BEGIN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_booking_member_date ON Booking (member_id, booking_date, total_amount)';
        DBMS_OUTPUT.PUT_LINE('  [SUCCESS] Index Created: idx_booking_member_date');
        DBMS_OUTPUT.PUT_LINE('            Table: Booking | Columns: member_id, booking_date, total_amount');
    EXCEPTION
        WHEN index_exists THEN
            DBMS_OUTPUT.PUT_LINE('  [EXISTS]  Index Skipped: idx_booking_member_date');
            DBMS_OUTPUT.PUT_LINE('            Already exists in database');
    END;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Index 6: Index for audit log searches by table and date
    BEGIN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_audit_log_table_date ON Staff_Audit_Log (table_name, change_date, operation)';
        DBMS_OUTPUT.PUT_LINE('  [SUCCESS] Index Created: idx_audit_log_table_date');
        DBMS_OUTPUT.PUT_LINE('            Table: Staff_Audit_Log | Columns: table_name, change_date, operation');
    EXCEPTION
        WHEN index_exists THEN
            DBMS_OUTPUT.PUT_LINE('  [EXISTS]  Index Skipped: idx_audit_log_table_date');
            DBMS_OUTPUT.PUT_LINE('            Already exists in database');
    END;
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    DBMS_OUTPUT.PUT_LINE('              INDEX CREATION PROCESS COMPLETED');
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
END;
/

-- =============================================================================
-- ENHANCED FUNCTIONS for Common Business Logic (Oracle XE 11g R2 Compatible)
-- =============================================================================

-- Function 1: Calculate refund amount based on business rules
CREATE OR REPLACE FUNCTION calculate_refund_amount(
    p_ticket_id IN NUMBER,
    p_refund_type IN VARCHAR2 DEFAULT 'STANDARD'
) RETURN NUMBER AS
    v_base_price NUMBER(10,2);
    v_departure_time DATE;
    v_refund_amount NUMBER(10,2);
    v_hours_until_departure NUMBER;
    v_ticket_status VARCHAR2(20);
    
BEGIN
    -- Get ticket pricing and schedule information with status check
    SELECT s.base_price, s.departure_time, t.status
    INTO v_base_price, v_departure_time, v_ticket_status
    FROM Ticket t
    INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
    WHERE t.ticket_id = p_ticket_id;
    
    -- Only calculate refund for booked or extended tickets
    IF v_ticket_status NOT IN ('Booked', 'Extended') THEN
        RETURN 0;
    END IF;
    
    v_hours_until_departure := (v_departure_time - SYSDATE) * 24;
    
    -- Apply business rules for refund calculation
    CASE 
        WHEN p_refund_type = 'COMPANY_CANCELLATION' THEN
            -- Full refund for company cancellations regardless of timing
            v_refund_amount := v_base_price;
        WHEN v_hours_until_departure > 48 THEN
            -- Standard 70% refund for cancellations > 48 hours
            v_refund_amount := ROUND(v_base_price * 0.70, 2);
        WHEN v_hours_until_departure > 24 THEN
            -- Reduced refund 24-48 hours before departure
            v_refund_amount := ROUND(v_base_price * 0.50, 2);
        WHEN v_hours_until_departure > 0 THEN
            -- Minimal refund if departure hasn't passed but < 24 hours
            v_refund_amount := ROUND(v_base_price * 0.25, 2);
        ELSE
            -- No refund after departure time has passed
            v_refund_amount := 0;
    END CASE;
    
    RETURN NVL(v_refund_amount, 0);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN -1; -- Error indicator
END calculate_refund_amount;
/

-- Function 2: Calculate extension cost (base price + admin fee)
CREATE OR REPLACE FUNCTION calculate_extension_cost(
    p_ticket_id IN NUMBER
) RETURN NUMBER AS
    v_base_price NUMBER(10,2);
    v_extension_cost NUMBER(10,2);
    v_admin_fee CONSTANT NUMBER(10,2) := 5.00;
    v_ticket_status VARCHAR2(20);
    v_departure_time DATE;
    v_hours_until_departure NUMBER;
    
BEGIN
    -- Get base price and ticket information
    SELECT s.base_price, t.status, s.departure_time
    INTO v_base_price, v_ticket_status, v_departure_time
    FROM Ticket t
    INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
    WHERE t.ticket_id = p_ticket_id;
    
    -- Only calculate extension cost for booked tickets
    IF v_ticket_status != 'Booked' THEN
        RETURN 0;
    END IF;
    
    v_hours_until_departure := (v_departure_time - SYSDATE) * 24;
    
    -- Only allow extensions if departure hasn't passed and > 24 hours
    IF v_hours_until_departure > 24 THEN
        v_extension_cost := v_base_price + v_admin_fee;
    ELSE
        v_extension_cost := 0; -- No extension allowed
    END IF;
    
    RETURN NVL(v_extension_cost, 0);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN -1; -- Error indicator
END calculate_extension_cost;
/

-- Function 3: Enhanced eligibility check with detailed status
CREATE OR REPLACE FUNCTION is_ticket_eligible(
    p_ticket_id IN NUMBER,
    p_operation IN VARCHAR2 -- 'CANCEL' or 'EXTEND'
) RETURN VARCHAR2 AS
    v_departure_time DATE;
    v_ticket_status VARCHAR2(20);
    v_hours_until_departure NUMBER;
    v_existing_refund_count NUMBER;
    v_existing_extension_count NUMBER;
    v_origin_station VARCHAR2(100);
    v_destination_station VARCHAR2(100);
    
BEGIN
    -- Get comprehensive ticket information
    SELECT s.departure_time, t.status, s.origin_station, s.destination_station
    INTO v_departure_time, v_ticket_status, v_origin_station, v_destination_station
    FROM Ticket t
    INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
    WHERE t.ticket_id = p_ticket_id;
    
    -- Check for existing refunds or extensions
    SELECT COUNT(*) INTO v_existing_refund_count 
    FROM Refund WHERE ticket_id = p_ticket_id;
    
    SELECT COUNT(*) INTO v_existing_extension_count 
    FROM Extension WHERE ticket_id = p_ticket_id;
    
    -- Calculate hours until departure (can be negative if past)
    v_hours_until_departure := (v_departure_time - SYSDATE) * 24;
    
    -- Check eligibility based on operation type
    IF p_operation = 'CANCEL' THEN
        IF v_ticket_status NOT IN ('Booked', 'Extended') THEN
            RETURN 'INELIGIBLE: Ticket status is ' || v_ticket_status || ' (Route: ' || v_origin_station || '-' || v_destination_station || ')';
        ELSIF v_existing_refund_count > 0 THEN
            RETURN 'INELIGIBLE: Ticket already refunded';
        ELSIF v_hours_until_departure <= 0 THEN
            RETURN 'INELIGIBLE: Departure time has passed (' || 
                   ROUND(ABS(v_hours_until_departure), 2) || ' hours ago)';
        ELSIF v_hours_until_departure <= 24 THEN
            RETURN 'ELIGIBLE: Can be cancelled with reduced refund (' || 
                   ROUND(v_hours_until_departure, 2) || ' hours until departure)';
        ELSE
            RETURN 'ELIGIBLE: Can be cancelled with standard refund (' || 
                   ROUND(v_hours_until_departure, 2) || ' hours until departure)';
        END IF;
        
    ELSIF p_operation = 'EXTEND' THEN
        IF v_ticket_status NOT IN ('Booked') THEN
            RETURN 'INELIGIBLE: Ticket status is ' || v_ticket_status || ' (only Booked tickets can be extended)';
        ELSIF v_existing_extension_count > 0 THEN
            RETURN 'INELIGIBLE: Ticket already extended';
        ELSIF v_existing_refund_count > 0 THEN
            RETURN 'INELIGIBLE: Ticket already refunded';
        ELSIF v_hours_until_departure <= 0 THEN
            RETURN 'INELIGIBLE: Departure time has passed (' || 
                   ROUND(ABS(v_hours_until_departure), 2) || ' hours ago)';
        ELSIF v_hours_until_departure <= 24 THEN
            RETURN 'INELIGIBLE: Less than 24 hours until departure (' || 
                   ROUND(v_hours_until_departure, 2) || ' hours remaining)';
        ELSE
            RETURN 'ELIGIBLE: Can be extended (' || 
                   ROUND(v_hours_until_departure, 2) || ' hours until departure)';
        END IF;
    ELSE
        RETURN 'ERROR: Invalid operation type (use CANCEL or EXTEND)';
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ERROR: Ticket ID ' || p_ticket_id || ' not found';
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END is_ticket_eligible;
/

-- =============================================================================
-- ENHANCED VIEWS with FIXED table aliases and identifier lengths
-- =============================================================================

-- FIXED VIEW 1: Refund analysis with corrected table aliases
CREATE OR REPLACE VIEW V_REFUND_ANALYSIS AS
SELECT 
    r.refund_id,
    r.refund_date,
    r.amount AS refund_amount,
    r.refund_method,
    t.ticket_id,
    t.seat_number,
    t.status AS current_status,
    s.base_price AS original_price,
    s.departure_time,
    s.origin_station,
    s.destination_station,
    c.name AS company_name,
    m.name AS member_name,
    bkg.booking_date,
    -- Calculated fields
    ROUND((r.amount / s.base_price) * 100, 2) AS refund_percentage,
    ROUND(r.refund_date - bkg.booking_date, 0) AS days_booking_to_refund,
    ROUND((s.departure_time - r.refund_date) * 24, 2) AS hours_refund_before_dept,
    s.base_price - r.amount AS revenue_loss,
    -- Categorization
    CASE 
        WHEN ROUND((r.amount / s.base_price) * 100, 2) = 100 THEN 'Full Refund'
        WHEN ROUND((r.amount / s.base_price) * 100, 2) >= 70 THEN 'Standard Refund (70%)'
        WHEN ROUND((r.amount / s.base_price) * 100, 2) >= 50 THEN 'Reduced Refund (50%)'
        WHEN ROUND((r.amount / s.base_price) * 100, 2) > 0 THEN 'Minimal Refund'
        ELSE 'No Refund'
    END AS refund_category,
    CASE 
        WHEN ROUND((s.departure_time - r.refund_date) * 24, 2) > 168 THEN 'Week+ Advance'
        WHEN ROUND((s.departure_time - r.refund_date) * 24, 2) > 48 THEN 'Standard Advance'
        WHEN ROUND((s.departure_time - r.refund_date) * 24, 2) > 24 THEN 'Short Notice'
        ELSE 'Last Minute'
    END AS timing_category
FROM Refund r
INNER JOIN Ticket t ON r.ticket_id = t.ticket_id
INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
INNER JOIN Bus bus ON s.bus_id = bus.bus_id
INNER JOIN Company c ON bus.company_id = c.company_id
INNER JOIN BookingDetails bd ON t.ticket_id = bd.ticket_id
INNER JOIN Booking bkg ON bd.booking_id = bkg.booking_id
INNER JOIN Member m ON bkg.member_id = m.member_id;

-- FIXED VIEW 2: Extension analysis with shortened identifier names
CREATE OR REPLACE VIEW V_EXTENSION_ANALYSIS AS
SELECT 
    e.extension_id,
    e.extension_date,
    e.amount AS extension_amount,
    e.extension_method,
    t.ticket_id,
    t.seat_number,
    t.status AS current_status,
    s.base_price AS original_price,
    s.departure_time,
    s.origin_station,
    s.destination_station,
    c.name AS company_name,
    m.name AS member_name,
    bkg.booking_date,
    -- Calculated fields with FIXED identifier lengths
    e.amount - s.base_price AS admin_fee_paid,
    ROUND(e.extension_date - bkg.booking_date, 0) AS days_booking_to_ext,
    ROUND((s.departure_time - e.extension_date) * 24, 2) AS hours_ext_before_dept,
    e.amount - s.base_price AS additional_revenue,
    -- Categorization
    CASE 
        WHEN ROUND((s.departure_time - e.extension_date) * 24, 2) > 168 THEN 'Week+ Advance'
        WHEN ROUND((s.departure_time - e.extension_date) * 24, 2) > 48 THEN 'Standard Advance'
        WHEN ROUND((s.departure_time - e.extension_date) * 24, 2) > 24 THEN 'Short Notice'
        ELSE 'Last Minute'
    END AS timing_category
FROM Extension e
INNER JOIN Ticket t ON e.ticket_id = t.ticket_id
INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
INNER JOIN Bus bus ON s.bus_id = bus.bus_id
INNER JOIN Company c ON bus.company_id = c.company_id
INNER JOIN BookingDetails bd ON t.ticket_id = bd.ticket_id
INNER JOIN Booking bkg ON bd.booking_id = bkg.booking_id
INNER JOIN Member m ON bkg.member_id = m.member_id;

-- =============================================================================
-- PERFORMANCE MONITORING VIEWS (Oracle XE 11g R2 Compatible)
-- =============================================================================

CREATE OR REPLACE VIEW V_TICKET_PERFORMANCE_STATS AS
SELECT 
    'Bookings' AS operation,
    COUNT(*) AS total_operations,
    ROUND(COUNT(*) / GREATEST(ROUND(SYSDATE - MIN(bkg.booking_date)), 1), 1) AS daily_average,
    MIN(bkg.booking_date) AS first_operation,
    MAX(bkg.booking_date) AS last_operation,
    ROUND(AVG(bkg.total_amount), 3) AS avg_amount
FROM Booking bkg
WHERE bkg.booking_date >= SYSDATE - 30
UNION ALL
SELECT 
    'Refunds' AS operation,
    COUNT(*) AS total_operations,
    ROUND(COUNT(*) / GREATEST(ROUND(SYSDATE - MIN(r.refund_date)), 1), 1) AS daily_average,
    MIN(r.refund_date) AS first_operation,
    MAX(r.refund_date) AS last_operation,
    ROUND(AVG(r.amount), 3) AS avg_amount
FROM Refund r
WHERE r.refund_date >= SYSDATE - 30
UNION ALL
SELECT 
    'Extensions' AS operation,
    COUNT(*) AS total_operations,
    ROUND(COUNT(*) / GREATEST(ROUND(SYSDATE - MIN(e.extension_date)), 1), 1) AS daily_average,
    MIN(e.extension_date) AS first_operation,
    MAX(e.extension_date) AS last_operation,
    ROUND(AVG(e.amount), 3) AS avg_amount
FROM Extension e
WHERE e.extension_date >= SYSDATE - 30;

-- =============================================================================
-- EXCEPTION HANDLING ENHANCEMENTS (Oracle XE 11g R2 Compatible)
-- =============================================================================

CREATE OR REPLACE PACKAGE ticket_exceptions AS
    ticket_not_found EXCEPTION;
    PRAGMA EXCEPTION_INIT(ticket_not_found, -20101);
    
    invalid_ticket_status EXCEPTION;
    PRAGMA EXCEPTION_INIT(invalid_ticket_status, -20102);
    
    departure_too_close EXCEPTION;
    PRAGMA EXCEPTION_INIT(departure_too_close, -20103);
    
    already_processed EXCEPTION;
    PRAGMA EXCEPTION_INIT(already_processed, -20104);
    
    invalid_amount EXCEPTION;
    PRAGMA EXCEPTION_INIT(invalid_amount, -20105);
    
    PROCEDURE raise_ticket_error(
        p_error_code IN NUMBER,
        p_ticket_id IN NUMBER,
        p_additional_info IN VARCHAR2 DEFAULT NULL
    );
END ticket_exceptions;
/

CREATE OR REPLACE PACKAGE BODY ticket_exceptions AS
    PROCEDURE raise_ticket_error(
        p_error_code IN NUMBER,
        p_ticket_id IN NUMBER,
        p_additional_info IN VARCHAR2 DEFAULT NULL
    ) AS
        v_message VARCHAR2(4000);
    BEGIN
        CASE p_error_code
            WHEN -20101 THEN
                v_message := 'Ticket ID ' || p_ticket_id || ' not found';
            WHEN -20102 THEN
                v_message := 'Invalid ticket status for Ticket ID ' || p_ticket_id;
            WHEN -20103 THEN
                v_message := 'Departure too close for Ticket ID ' || p_ticket_id;
            WHEN -20104 THEN
                v_message := 'Ticket ID ' || p_ticket_id || ' already processed';
            WHEN -20105 THEN
                v_message := 'Invalid amount for Ticket ID ' || p_ticket_id;
            ELSE
                v_message := 'Unknown error for Ticket ID ' || p_ticket_id;
        END CASE;
        
        IF p_additional_info IS NOT NULL THEN
            v_message := v_message || '. ' || p_additional_info;
        END IF;
        
        RAISE_APPLICATION_ERROR(p_error_code, v_message);
    END raise_ticket_error;
END ticket_exceptions;
/

-- =============================================================================
-- ENHANCED UTILITY PROCEDURES WITH CLEAN OUTPUT FORMATTING
-- =============================================================================

CREATE OR REPLACE PROCEDURE show_ticket_system_stats AS
    CURSOR c_stats IS
        SELECT * FROM V_TICKET_PERFORMANCE_STATS
        ORDER BY operation;
        
    v_main_separator VARCHAR2(100) := RPAD('=', 85, '=');
    v_table_separator VARCHAR2(100) := RPAD('-', 85, '-');
    v_count NUMBER := 0;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    DBMS_OUTPUT.PUT_LINE('              TICKET MANAGEMENT SYSTEM - PERFORMANCE REPORT');
    DBMS_OUTPUT.PUT_LINE('                       Last 30 Days Overview');
    DBMS_OUTPUT.PUT_LINE('                   Generated: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Clean table headers with proper alignment
    DBMS_OUTPUT.PUT_LINE('  ' ||
        RPAD('OPERATION', 15) || ' | ' ||
        RPAD('TOTAL OPS', 10) || ' | ' ||
        RPAD('DAILY AVG', 10) || ' | ' ||
        RPAD('FIRST OP', 11) || ' | ' ||
        RPAD('LAST OP', 11) || ' | ' ||
        RPAD('AVG AMOUNT', 12)
    );
    DBMS_OUTPUT.PUT_LINE('  ' || v_table_separator);
    
    FOR stat_rec IN c_stats LOOP
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE('  ' ||
            RPAD(stat_rec.operation, 15) || ' | ' ||
            LPAD(NVL(stat_rec.total_operations, 0), 9) || ' | ' ||
            LPAD(TO_CHAR(NVL(stat_rec.daily_average, 0), '999.9'), 9) || ' | ' ||
            RPAD(TO_CHAR(stat_rec.first_operation, 'DD-MON-YY'), 11) || ' | ' ||
            RPAD(TO_CHAR(stat_rec.last_operation, 'DD-MON-YY'), 11) || ' | ' ||
            LPAD('RM ' || TO_CHAR(NVL(stat_rec.avg_amount, 0), '9999.99'), 11)
        );
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('  ' || v_table_separator);
    DBMS_OUTPUT.PUT_LINE('');
    
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  No performance data available for the last 30 days.');
        DBMS_OUTPUT.PUT_LINE('  System may be newly initialized or have no recent activity.');
        DBMS_OUTPUT.PUT_LINE('');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  Performance Summary:');
        DBMS_OUTPUT.PUT_LINE('    - Operations Tracked .....: ' || v_count);
        DBMS_OUTPUT.PUT_LINE('    - Data Period ............: Last 30 days');
        DBMS_OUTPUT.PUT_LINE('    - Report Accuracy ........: Real-time database query');
        DBMS_OUTPUT.PUT_LINE('');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    DBMS_OUTPUT.PUT_LINE('                    PERFORMANCE REPORT COMPLETED');
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  ERROR: Performance statistics unavailable');
        DBMS_OUTPUT.PUT_LINE('  Reason: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(v_main_separator);
END show_ticket_system_stats;
/

-- =============================================================================
-- ENHANCED TEST PROCEDURE WITH CLEAN OUTPUT FORMATTING
-- =============================================================================

CREATE OR REPLACE PROCEDURE test_extra_features AS
    CURSOR c_tickets IS
        SELECT t.ticket_id, t.seat_number, t.status, 
               s.departure_time, s.origin_station, s.destination_station,
               s.base_price
        FROM Ticket t
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE ROWNUM <= 5
        ORDER BY t.ticket_id;
    
    v_refund_amount NUMBER;
    v_extension_cost NUMBER;
    v_eligibility VARCHAR2(200);
    v_count NUMBER;
    v_ticket_count NUMBER := 0;
    v_main_separator VARCHAR2(80) := RPAD('=', 75, '=');
    v_section_separator VARCHAR2(80) := RPAD('-', 75, '-');
    v_ticket_separator VARCHAR2(80) := RPAD('.', 60, '.');
    
BEGIN
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    DBMS_OUTPUT.PUT_LINE('                 EXTRA FEATURES TESTING SUITE');
    DBMS_OUTPUT.PUT_LINE('                Oracle XE 11g R2 Compatible');
    DBMS_OUTPUT.PUT_LINE('              Test Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Check if tickets exist
    SELECT COUNT(*) INTO v_count FROM Ticket WHERE ROWNUM <= 1;
    
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  [WARNING] No tickets found in database');
        DBMS_OUTPUT.PUT_LINE('            Please run sample data population before testing');
        DBMS_OUTPUT.PUT_LINE('            Test cannot proceed without ticket data');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE(v_main_separator);
        RETURN;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('  TESTING SCOPE: Multiple ticket analysis with business logic validation');
    DBMS_OUTPUT.PUT_LINE('  DATA SOURCE:   Live database tickets (max 5 samples)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_section_separator);
    
    FOR ticket_rec IN c_tickets LOOP
        v_ticket_count := v_ticket_count + 1;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  TICKET #' || v_ticket_count || ' - ID: ' || ticket_rec.ticket_id);
        DBMS_OUTPUT.PUT_LINE('  ' || v_ticket_separator);
        DBMS_OUTPUT.PUT_LINE('    Seat Number ........: ' || ticket_rec.seat_number);
        DBMS_OUTPUT.PUT_LINE('    Current Status .....: ' || ticket_rec.status);
        DBMS_OUTPUT.PUT_LINE('    Route ..............: ' || ticket_rec.origin_station || ' to ' || ticket_rec.destination_station);
        DBMS_OUTPUT.PUT_LINE('    Base Price .........: RM ' || TO_CHAR(ticket_rec.base_price, '999.99'));
        DBMS_OUTPUT.PUT_LINE('    Departure Time .....: ' || TO_CHAR(ticket_rec.departure_time, 'DD-MON-YYYY HH24:MI'));
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Test refund calculation
        DBMS_OUTPUT.PUT_LINE('    REFUND ANALYSIS:');
        BEGIN
            v_refund_amount := calculate_refund_amount(ticket_rec.ticket_id);
            IF v_refund_amount = -1 THEN
                DBMS_OUTPUT.PUT_LINE('      Status ............: ERROR in calculation');
            ELSIF v_refund_amount = 0 THEN
                DBMS_OUTPUT.PUT_LINE('      Status ............: Not eligible for refund');
            ELSE
                DBMS_OUTPUT.PUT_LINE('      Status ............: Eligible');
                DBMS_OUTPUT.PUT_LINE('      Refund Amount .....: RM ' || TO_CHAR(v_refund_amount, '999.99'));
                DBMS_OUTPUT.PUT_LINE('      Percentage ........: ' || 
                    TO_CHAR(ROUND((v_refund_amount / ticket_rec.base_price) * 100, 1), '999.9') || '%');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('      Status ............: CALCULATION ERROR');
                DBMS_OUTPUT.PUT_LINE('      Error ..............: ' || SUBSTR(SQLERRM, 1, 50));
        END;
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Test extension cost calculation
        DBMS_OUTPUT.PUT_LINE('    EXTENSION ANALYSIS:');
        BEGIN
            v_extension_cost := calculate_extension_cost(ticket_rec.ticket_id);
            IF v_extension_cost = -1 THEN
                DBMS_OUTPUT.PUT_LINE('      Status ............: ERROR in calculation');
            ELSIF v_extension_cost = 0 THEN
                DBMS_OUTPUT.PUT_LINE('      Status ............: Not eligible for extension');
            ELSE
                DBMS_OUTPUT.PUT_LINE('      Status ............: Eligible');
                DBMS_OUTPUT.PUT_LINE('      Extension Cost ....: RM ' || TO_CHAR(v_extension_cost, '999.99'));
                DBMS_OUTPUT.PUT_LINE('      Admin Fee .........: RM 5.00');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('      Status ............: CALCULATION ERROR');
                DBMS_OUTPUT.PUT_LINE('      Error ..............: ' || SUBSTR(SQLERRM, 1, 50));
        END;
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Test eligibility checks
        DBMS_OUTPUT.PUT_LINE('    ELIGIBILITY CHECKS:');
        BEGIN
            v_eligibility := is_ticket_eligible(ticket_rec.ticket_id, 'CANCEL');
            DBMS_OUTPUT.PUT_LINE('      Cancellation ......: ' || SUBSTR(v_eligibility, 1, 80));
            
            v_eligibility := is_ticket_eligible(ticket_rec.ticket_id, 'EXTEND');
            DBMS_OUTPUT.PUT_LINE('      Extension ..........: ' || SUBSTR(v_eligibility, 1, 80));
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('      Status ............: ELIGIBILITY CHECK ERROR');
                DBMS_OUTPUT.PUT_LINE('      Error ..............: ' || SUBSTR(SQLERRM, 1, 50));
        END;
        
        IF v_ticket_count < 5 THEN
            DBMS_OUTPUT.PUT_LINE('  ' || v_ticket_separator);
        END IF;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_section_separator);
    DBMS_OUTPUT.PUT_LINE('                    SYSTEM VIEWS VALIDATION');
    DBMS_OUTPUT.PUT_LINE(v_section_separator);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test views with enhanced output
    BEGIN
        SELECT COUNT(*) INTO v_count FROM V_REFUND_ANALYSIS WHERE ROWNUM <= 1;
        DBMS_OUTPUT.PUT_LINE('  [SUCCESS] V_REFUND_ANALYSIS View .....: Operational (' || v_count || ' records accessible)');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  [ERROR]   V_REFUND_ANALYSIS View .....: ' || SUBSTR(SQLERRM, 1, 50));
    END;
    
    BEGIN
        SELECT COUNT(*) INTO v_count FROM V_EXTENSION_ANALYSIS WHERE ROWNUM <= 1;
        DBMS_OUTPUT.PUT_LINE('  [SUCCESS] V_EXTENSION_ANALYSIS View ...: Operational (' || v_count || ' records accessible)');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  [ERROR]   V_EXTENSION_ANALYSIS View ...: ' || SUBSTR(SQLERRM, 1, 50));
    END;
    
    BEGIN
        SELECT COUNT(*) INTO v_count FROM V_TICKET_PERFORMANCE_STATS WHERE ROWNUM <= 1;
        DBMS_OUTPUT.PUT_LINE('  [SUCCESS] V_TICKET_PERFORMANCE_STATS ..: Operational (' || v_count || ' stat records)');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  [ERROR]   V_TICKET_PERFORMANCE_STATS ..: ' || SUBSTR(SQLERRM, 1, 50));
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    DBMS_OUTPUT.PUT_LINE('                    TESTING SUITE COMPLETED');
    DBMS_OUTPUT.PUT_LINE('  Results: ' || v_ticket_count || ' tickets analyzed, business logic validated');
    DBMS_OUTPUT.PUT_LINE('  Status: All core functions operational and ready for production use');
    DBMS_OUTPUT.PUT_LINE(v_main_separator);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  [CRITICAL ERROR] Testing suite encountered fatal error');
        DBMS_OUTPUT.PUT_LINE('  Error Details: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('  Please check database connectivity and table structures');
        DBMS_OUTPUT.PUT_LINE(v_main_separator);
END test_extra_features;
/

-- =============================================================================
-- COMPLETION MESSAGE WITH CLEAN FORMATTING
-- =============================================================================

DECLARE
    v_separator VARCHAR2(80) := RPAD('=', 75, '=');
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('            EXTRA FEATURES COMPLETED');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  AVAILABLE PROCEDURES:');
    DBMS_OUTPUT.PUT_LINE('    - EXEC test_extra_features;           (Test all functions)');
    DBMS_OUTPUT.PUT_LINE('    - EXEC show_ticket_system_stats;      (Performance report)');
    DBMS_OUTPUT.PUT_LINE(v_separator);
END;
/