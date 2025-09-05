-- =============================================================================
-- Bus Station Management System - Reports with Enhanced Formatting
-- Focus: Ticket Management & Refunds Reporting
-- =============================================================================

SET SERVEROUTPUT ON;
SET PAGESIZE 1000;
SET LINESIZE 200;

-- Helper function to center text
CREATE OR REPLACE FUNCTION CENTER_TEXT(p_text IN VARCHAR2, p_width IN NUMBER) 
RETURN VARCHAR2 IS
    v_padding NUMBER;
    v_left_pad VARCHAR2(1000);
    v_right_pad VARCHAR2(1000);
BEGIN
    v_padding := (p_width - LENGTH(p_text)) / 2;
    v_left_pad := RPAD(' ', FLOOR(v_padding), ' ');
    v_right_pad := RPAD(' ', CEIL(v_padding), ' ');
    RETURN v_left_pad || p_text || v_right_pad;
END CENTER_TEXT;
/

-- Helper function to format currency
CREATE OR REPLACE FUNCTION FORMAT_CURRENCY(p_amount IN NUMBER) 
RETURN VARCHAR2 IS
BEGIN
    RETURN 'RM ' || TO_CHAR(p_amount, 'FM999,999,999.00');
END FORMAT_CURRENCY;
/

PROMPT Creating cursor-based reporting procedures

-- =============================================================================
-- REPORT 1: rpt_monthly_refund_summary
-- Purpose: Summary report showing total number of refunds and amount for a given month
-- Uses: Nested cursors to show overall summary and detailed breakdown by company
-- =============================================================================

CREATE OR REPLACE PROCEDURE rpt_monthly_refund_summary (
    p_month IN NUMBER DEFAULT EXTRACT(MONTH FROM SYSDATE),
    p_year IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
) AS
    -- Main cursor for monthly refund summary by company
    CURSOR c_company_refunds IS
        SELECT 
            c.company_id,
            c.name AS company_name,
            COUNT(r.refund_id) AS total_refunds,
            SUM(r.amount) AS total_refund_amount,
            AVG(r.amount) AS avg_refund_amount,
            MIN(r.amount) AS min_refund_amount,
            MAX(r.amount) AS max_refund_amount
        FROM Company c
        LEFT JOIN Bus b ON c.company_id = b.company_id
        LEFT JOIN Schedule s ON b.bus_id = s.bus_id
        LEFT JOIN Ticket t ON s.schedule_id = t.schedule_id
        LEFT JOIN Refund r ON t.ticket_id = r.ticket_id 
            AND EXTRACT(MONTH FROM r.refund_date) = p_month
            AND EXTRACT(YEAR FROM r.refund_date) = p_year
        GROUP BY c.company_id, c.name
        HAVING COUNT(r.refund_id) > 0
        ORDER BY total_refund_amount DESC;
    
    -- Nested cursor for detailed refund information by company
    CURSOR c_refund_details (p_company_id NUMBER) IS
        SELECT 
            r.refund_id,
            r.refund_date,
            r.amount,
            r.refund_method,
            t.ticket_id,
            t.seat_number,
            s.departure_time,
            s.origin_station,
            s.destination_station,
            s.base_price,
            m.name AS member_name,
            ROUND((r.refund_date - b.booking_date), 0) AS days_after_booking,
            ROUND((s.departure_time - r.refund_date) * 24, 2) AS hours_before_departure,
            ROUND((r.amount / s.base_price) * 100, 2) AS refund_percentage
        FROM Refund r
        INNER JOIN Ticket t ON r.ticket_id = t.ticket_id
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        INNER JOIN Bus bus ON s.bus_id = bus.bus_id
        INNER JOIN BookingDetails bd ON t.ticket_id = bd.ticket_id
        INNER JOIN Booking b ON bd.booking_id = b.booking_id
        INNER JOIN Member m ON b.member_id = m.member_id
        WHERE bus.company_id = p_company_id
          AND EXTRACT(MONTH FROM r.refund_date) = p_month
          AND EXTRACT(YEAR FROM r.refund_date) = p_year
        ORDER BY r.refund_date DESC, r.amount DESC;
    
    -- Variables for calculations
    v_total_refunds NUMBER := 0;
    v_total_amount NUMBER(12,2) := 0;
    v_company_count NUMBER := 0;
    v_month_name VARCHAR2(20);
    v_detail_count NUMBER := 0;
    
    -- Enhanced formatting variables
    v_separator VARCHAR2(200) := RPAD('=', 120, '=');
    v_sub_separator VARCHAR2(200) := RPAD('-', 120, '-');
    v_thin_separator VARCHAR2(200) := RPAD('.', 120, '.');
    
BEGIN
    -- Get month name for display
    SELECT TO_CHAR(TO_DATE(p_month, 'MM'), 'Month') INTO v_month_name FROM DUAL;
    v_month_name := TRIM(v_month_name);
    
    -- Report header
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('MONTHLY REFUND SUMMARY REPORT', 120));
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT(UPPER(v_month_name) || ' ' || p_year, 120));
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('Generated on: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'), 120));
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    
    -- Check if there are any refunds for the specified month/year
    FOR company_rec IN c_company_refunds LOOP
        v_company_count := v_company_count + 1;
        v_total_refunds := v_total_refunds + company_rec.total_refunds;
        v_total_amount := v_total_amount + NVL(company_rec.total_refund_amount, 0);
        
        -- Company summary section
        DBMS_OUTPUT.PUT_LINE('COMPANY: ' || company_rec.company_name || ' (ID: ' || company_rec.company_id || ')');
        DBMS_OUTPUT.PUT_LINE(v_sub_separator);
        DBMS_OUTPUT.PUT_LINE('Total Refunds: ' || LPAD(company_rec.total_refunds, 10));
        DBMS_OUTPUT.PUT_LINE('Total Amount:  ' || LPAD(FORMAT_CURRENCY(company_rec.total_refund_amount), 20));
        DBMS_OUTPUT.PUT_LINE('Average:       ' || LPAD(FORMAT_CURRENCY(company_rec.avg_refund_amount), 20));
        DBMS_OUTPUT.PUT_LINE('Range:         ' || LPAD(FORMAT_CURRENCY(company_rec.min_refund_amount), 20) || 
                            ' - ' || FORMAT_CURRENCY(company_rec.max_refund_amount));
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        
        -- Detailed refund information using nested cursor
        DBMS_OUTPUT.PUT_LINE('DETAILED REFUND BREAKDOWN:');
        DBMS_OUTPUT.PUT_LINE(v_thin_separator);
        DBMS_OUTPUT.PUT_LINE(
            RPAD('Refund ID', 10) || ' | ' ||
            RPAD('Date', 12) || ' | ' ||
            RPAD('Amount', 12) || ' | ' ||
            RPAD('Method', 15) || ' | ' ||
            RPAD('Route', 25) || ' | ' ||
            RPAD('Member', 20) || ' | ' ||
            RPAD('%', 6)
        );
        DBMS_OUTPUT.PUT_LINE(v_thin_separator);
        
        v_detail_count := 0;
        FOR detail_rec IN c_refund_details(company_rec.company_id) LOOP
            v_detail_count := v_detail_count + 1;
            
            DBMS_OUTPUT.PUT_LINE(
                RPAD(detail_rec.refund_id, 10) || ' | ' ||
                RPAD(TO_CHAR(detail_rec.refund_date, 'DD-MON'), 12) || ' | ' ||
                RPAD(FORMAT_CURRENCY(detail_rec.amount), 12) || ' | ' ||
                RPAD(SUBSTR(detail_rec.refund_method, 1, 15), 15) || ' | ' ||
                RPAD(SUBSTR(detail_rec.origin_station || '-' || detail_rec.destination_station, 1, 24), 25) || ' | ' ||
                RPAD(SUBSTR(detail_rec.member_name, 1, 19), 20) || ' | ' ||
                RPAD(TO_CHAR(detail_rec.refund_percentage, '990') || '%', 6)
            );
            
            -- Show additional details for first few records
            IF v_detail_count <= 3 THEN
                DBMS_OUTPUT.PUT_LINE('  -> Ticket: ' || detail_rec.ticket_id || 
                                   ' | Seat: ' || detail_rec.seat_number ||
                                   ' | Departure: ' || TO_CHAR(detail_rec.departure_time, 'DD-MON HH24:MI') ||
                                   ' | Hours before: ' || detail_rec.hours_before_departure);
            END IF;
        END LOOP;
        
        IF v_detail_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('    No detailed records found.');
        ELSIF v_detail_count > 3 THEN
            DBMS_OUTPUT.PUT_LINE('    ... and ' || (v_detail_count - 3) || ' more refunds.');
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE(CHR(10));
    END LOOP;
    
    -- Overall summary
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('OVERALL SUMMARY', 120));
    DBMS_OUTPUT.PUT_LINE(v_separator);
    
    IF v_company_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('No refunds were processed in ' || v_month_name || ' ' || p_year, 120));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Report Period:          ' || RPAD(v_month_name || ' ' || p_year, 20));
        DBMS_OUTPUT.PUT_LINE('Companies with Refunds: ' || LPAD(v_company_count, 20));
        DBMS_OUTPUT.PUT_LINE('Total Refunds:          ' || LPAD(v_total_refunds, 20));
        DBMS_OUTPUT.PUT_LINE('Total Amount:           ' || LPAD(FORMAT_CURRENCY(v_total_amount), 20));
        DBMS_OUTPUT.PUT_LINE('Average per Refund:     ' || LPAD(FORMAT_CURRENCY(v_total_amount / NULLIF(v_total_refunds, 0)), 20));
        
        -- Calculate additional statistics
        DECLARE
            v_total_tickets NUMBER;
            v_refund_rate NUMBER(5,2);
        BEGIN
            SELECT COUNT(*)
            INTO v_total_tickets
            FROM Ticket t
            INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
            WHERE EXTRACT(MONTH FROM s.departure_time) = p_month
              AND EXTRACT(YEAR FROM s.departure_time) = p_year
              AND t.status IN ('Booked', 'Cancelled', 'Extended');
            
            v_refund_rate := ROUND((v_total_refunds / NULLIF(v_total_tickets, 0)) * 100, 2);
            
            DBMS_OUTPUT.PUT_LINE('Tickets in Period:      ' || LPAD(v_total_tickets, 20));
            DBMS_OUTPUT.PUT_LINE('Refund Rate:            ' || LPAD(NVL(v_refund_rate, 0) || '%', 20));
        END;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('Report completed at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'), 120));
    DBMS_OUTPUT.PUT_LINE(v_separator);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in Monthly Refund Summary Report: ' || SQLERRM);
        RAISE;
END rpt_monthly_refund_summary;
/

-- =============================================================================
-- REPORT 2: rpt_ticket_extensions_detail
-- Purpose: Detailed report listing all ticket extensions processed within a specific week
-- Uses: Nested cursors to show extensions by day and detailed passenger information
-- =============================================================================

CREATE OR REPLACE PROCEDURE rpt_ticket_extensions_detail (
    p_start_date IN DATE DEFAULT TRUNC(SYSDATE, 'IW'), -- Start of current week (Monday)
    p_end_date IN DATE DEFAULT TRUNC(SYSDATE, 'IW') + 6 -- End of current week (Sunday)
) AS
    -- Main cursor for daily extension summary
    CURSOR c_daily_extensions IS
        SELECT 
            TRUNC(e.extension_date) AS extension_day,
            COUNT(e.extension_id) AS daily_extensions,
            SUM(e.amount) AS daily_total_amount,
            AVG(e.amount) AS daily_avg_amount,
            COUNT(DISTINCT e.extension_method) AS payment_methods_used
        FROM Extension e
        WHERE TRUNC(e.extension_date) BETWEEN TRUNC(p_start_date) AND TRUNC(p_end_date)
        GROUP BY TRUNC(e.extension_date)
        ORDER BY extension_day;
    
    -- Nested cursor for detailed extension information by day
    CURSOR c_extension_details (p_day DATE) IS
        SELECT 
            e.extension_id,
            e.extension_date,
            e.amount,
            e.extension_method,
            t.ticket_id,
            t.seat_number,
            t.status AS ticket_status,
            s.schedule_id,
            s.departure_time,
            s.arrival_time,
            s.base_price,
            s.origin_station,
            s.destination_station,
            s.platform_no,
            bus.plate_number,
            c.name AS company_name,
            m.name AS member_name,
            m.email AS member_email,
            m.contact_no AS member_contact,
            b.booking_date,
            -- Calculations
            e.amount - s.base_price AS admin_fee,
            ROUND((s.departure_time - e.extension_date) * 24, 2) AS hours_before_departure,
            ROUND((e.extension_date - b.booking_date), 0) AS days_after_booking
        FROM Extension e
        INNER JOIN Ticket t ON e.ticket_id = t.ticket_id
        INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
        INNER JOIN Bus bus ON s.bus_id = bus.bus_id
        INNER JOIN Company c ON bus.company_id = c.company_id
        INNER JOIN BookingDetails bd ON t.ticket_id = bd.ticket_id
        INNER JOIN Booking b ON bd.booking_id = b.booking_id
        INNER JOIN Member m ON b.member_id = m.member_id
        WHERE TRUNC(e.extension_date) = TRUNC(p_day)
        ORDER BY e.extension_date DESC, s.departure_time ASC;
    
    -- Nested cursor for payment method breakdown by day
    CURSOR c_payment_methods (p_day DATE) IS
        SELECT 
            e.extension_method,
            COUNT(*) AS method_count,
            SUM(e.amount) AS method_total,
            AVG(e.amount) AS method_avg
        FROM Extension e
        WHERE TRUNC(e.extension_date) = TRUNC(p_day)
        GROUP BY e.extension_method
        ORDER BY method_count DESC;
    
    -- Variables for calculations and formatting
    v_week_total_extensions NUMBER := 0;
    v_week_total_amount NUMBER(12,2) := 0;
    v_week_admin_fees NUMBER(12,2) := 0;
    v_days_with_extensions NUMBER := 0;
    v_separator VARCHAR2(200) := RPAD('=', 120, '=');
    v_sub_separator VARCHAR2(200) := RPAD('-', 120, '-');
    v_thin_separator VARCHAR2(200) := RPAD('.', 120, '.');
    v_detail_count NUMBER;
    
BEGIN
    -- Report header
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('TICKET EXTENSIONS DETAILED REPORT', 120));
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('Period: ' || TO_CHAR(p_start_date, 'DD-MON-YYYY') || 
                        ' to ' || TO_CHAR(p_end_date, 'DD-MON-YYYY'), 120));
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('Generated on: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'), 120));
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    
    -- Process each day in the week
    FOR daily_rec IN c_daily_extensions LOOP
        v_days_with_extensions := v_days_with_extensions + 1;
        v_week_total_extensions := v_week_total_extensions + daily_rec.daily_extensions;
        v_week_total_amount := v_week_total_amount + daily_rec.daily_total_amount;
        
        -- Daily summary header
        DBMS_OUTPUT.PUT_LINE('DATE: ' || TO_CHAR(daily_rec.extension_day, 'Day, DD-Month-YYYY'));
        DBMS_OUTPUT.PUT_LINE(v_sub_separator);
        DBMS_OUTPUT.PUT_LINE('Extensions Today: ' || daily_rec.daily_extensions || 
                            ' | Total Amount: ' || FORMAT_CURRENCY(daily_rec.daily_total_amount) ||
                            ' | Average: ' || FORMAT_CURRENCY(daily_rec.daily_avg_amount));
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        
        -- Payment methods breakdown for the day
        DBMS_OUTPUT.PUT_LINE('PAYMENT METHODS BREAKDOWN:');
        DBMS_OUTPUT.PUT_LINE(v_thin_separator);
        FOR payment_rec IN c_payment_methods(daily_rec.extension_day) LOOP
            DBMS_OUTPUT.PUT_LINE('  ' || RPAD(payment_rec.extension_method, 15) || ': ' ||
                                RPAD(payment_rec.method_count || ' extensions', 15) ||
                                FORMAT_CURRENCY(payment_rec.method_total));
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        
        -- Detailed extension records
        DBMS_OUTPUT.PUT_LINE('DETAILED EXTENSION RECORDS:');
        DBMS_OUTPUT.PUT_LINE(v_thin_separator);
        DBMS_OUTPUT.PUT_LINE(
            RPAD('Time', 6) || ' | ' ||
            RPAD('Ext.ID', 8) || ' | ' ||
            RPAD('Member', 20) || ' | ' ||
            RPAD('Route', 25) || ' | ' ||
            RPAD('Departure', 12) || ' | ' ||
            RPAD('Amount', 12) || ' | ' ||
            RPAD('Hours', 8)
        );
        DBMS_OUTPUT.PUT_LINE(v_thin_separator);
        
        v_detail_count := 0;
        FOR detail_rec IN c_extension_details(daily_rec.extension_day) LOOP
            v_detail_count := v_detail_count + 1;
            v_week_admin_fees := v_week_admin_fees + detail_rec.admin_fee;
            
            DBMS_OUTPUT.PUT_LINE(
                RPAD(TO_CHAR(detail_rec.extension_date, 'HH24:MI'), 6) || ' | ' ||
                RPAD(detail_rec.extension_id, 8) || ' | ' ||
                RPAD(SUBSTR(detail_rec.member_name, 1, 19), 20) || ' | ' ||
                RPAD(SUBSTR(detail_rec.origin_station || '-' || detail_rec.destination_station, 1, 24), 25) || ' | ' ||
                RPAD(TO_CHAR(detail_rec.departure_time, 'DD-MON HH24MI'), 12) || ' | ' ||
                RPAD(FORMAT_CURRENCY(detail_rec.amount), 12) || ' | ' ||
                RPAD(TO_CHAR(ROUND(detail_rec.hours_before_departure, 1)), 8)
            );
            
            -- Additional details for comprehensive view
            DBMS_OUTPUT.PUT_LINE('  Ticket: ' || detail_rec.ticket_id || 
                                ' | Seat: ' || detail_rec.seat_number ||
                                ' | Bus: ' || detail_rec.plate_number ||
                                ' | Company: ' || detail_rec.company_name);
            DBMS_OUTPUT.PUT_LINE('  Contact: ' || detail_rec.member_contact || 
                                ' | Email: ' || detail_rec.member_email);
            DBMS_OUTPUT.PUT_LINE('  Base Price: ' || FORMAT_CURRENCY(detail_rec.base_price) ||
                                ' + Admin Fee: ' || FORMAT_CURRENCY(detail_rec.admin_fee) ||
                                ' | Payment: ' || detail_rec.extension_method);
            DBMS_OUTPUT.PUT_LINE('  Booking to Extension: ' || detail_rec.days_after_booking || ' days' ||
                                ' | Platform: ' || NVL(detail_rec.platform_no, 'TBD'));
            DBMS_OUTPUT.PUT_LINE(CHR(10));
        END LOOP;
        
        IF v_detail_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('    No extension records found for this day.');
            DBMS_OUTPUT.PUT_LINE(CHR(10));
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(CHR(10));
    END LOOP;
    
    -- Weekly summary
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('WEEKLY SUMMARY', 120));
    DBMS_OUTPUT.PUT_LINE(v_separator);
    
    IF v_days_with_extensions = 0 THEN
        DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('No ticket extensions were processed during the specified week.', 120));
        DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('Period: ' || TO_CHAR(p_start_date, 'DD-MON-YYYY') || 
                            ' to ' || TO_CHAR(p_end_date, 'DD-MON-YYYY'), 120));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Report Period:          ' || TO_CHAR(p_start_date, 'DD-MON-YYYY') || 
                            ' to ' || TO_CHAR(p_end_date, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Days with Extensions:   ' || LPAD(v_days_with_extensions, 20) || ' out of ' || 
                            (TRUNC(p_end_date) - TRUNC(p_start_date) + 1) || ' days');
        DBMS_OUTPUT.PUT_LINE('Total Extensions:       ' || LPAD(v_week_total_extensions, 20));
        DBMS_OUTPUT.PUT_LINE('Total Amount:           ' || LPAD(FORMAT_CURRENCY(v_week_total_amount), 20));
        DBMS_OUTPUT.PUT_LINE('Total Admin Fees:       ' || LPAD(FORMAT_CURRENCY(v_week_admin_fees), 20));
        DBMS_OUTPUT.PUT_LINE('Average per Extension:  ' || 
                            LPAD(FORMAT_CURRENCY(v_week_total_amount / NULLIF(v_week_total_extensions, 0)), 20));
        DBMS_OUTPUT.PUT_LINE('Daily Average:          ' || 
                            LPAD(TO_CHAR(v_week_total_extensions / NULLIF(v_days_with_extensions, 0), '990.99') || 
                            ' extensions per active day', 40));
        
        -- Calculate extension trends
        DECLARE
            v_total_booked_tickets NUMBER;
            v_extension_rate NUMBER(5,2);
        BEGIN
            SELECT COUNT(*)
            INTO v_total_booked_tickets
            FROM Ticket t
            INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
            WHERE s.departure_time BETWEEN p_start_date AND p_end_date + 7 -- Extensions for next week's departures
              AND t.status IN ('Booked', 'Extended');
            
            v_extension_rate := ROUND((v_week_total_extensions / NULLIF(v_total_booked_tickets, 0)) * 100, 2);
            
            DBMS_OUTPUT.PUT_LINE('Booked Tickets (period): ' || LPAD(v_total_booked_tickets, 20));
            DBMS_OUTPUT.PUT_LINE('Extension Rate:          ' || LPAD(NVL(v_extension_rate, 0) || '%', 20));
        END;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE(CENTER_TEXT('Report completed at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'), 120));
    DBMS_OUTPUT.PUT_LINE(v_separator);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in Ticket Extensions Detail Report: ' || SQLERRM);
        RAISE;
END rpt_ticket_extensions_detail;
/

-- =============================================================================
-- Test procedure for running both reports
-- =============================================================================

CREATE OR REPLACE PROCEDURE test_ticket_reports AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Running sample ticket management reports...');
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    
    -- Run monthly refund summary for current month
    DBMS_OUTPUT.PUT_LINE('=== MONTHLY REFUND SUMMARY REPORT ===');
    rpt_monthly_refund_summary(EXTRACT(MONTH FROM SYSDATE), EXTRACT(YEAR FROM SYSDATE));
    
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    
    -- Run ticket extensions detail for current week
    DBMS_OUTPUT.PUT_LINE('=== TICKET EXTENSIONS DETAIL REPORT ===');
    rpt_ticket_extensions_detail(TRUNC(SYSDATE, 'IW'), TRUNC(SYSDATE, 'IW') + 6);
    
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE('Report testing completed.');
    
END test_ticket_reports;
/

PROMPT reporting procedures created successfully!
PROMPT To run monthly refund summary: EXEC rpt_monthly_refund_summary(1, 2024);
PROMPT To run extensions detail report: EXEC rpt_ticket_extensions_detail(DATE '2024-01-01', DATE '2024-01-07');
PROMPT To test both reports: EXEC test_ticket_reports;

COMMIT;
