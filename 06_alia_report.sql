-- ===========================================================================
-- Report 1: On demand and Detail report of Company’s Most Valuable Members
-- ===========================================================================

SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE rpt_company_member_value (
    p_company_name IN VARCHAR2,
    p_top_n        IN NUMBER DEFAULT 5
)
AS
    CURSOR company_cursor IS
        SELECT company_id, name FROM Company WHERE LOWER(name) = LOWER(p_company_name);
    CURSOR top_spenders_cursor (p_company_id IN NUMBER) IS
        SELECT
            m.name, m.email, SUM(s.base_price) as total_spent_with_company
        FROM Member m JOIN Booking b ON m.member_id = b.member_id JOIN BookingDetails bd ON b.booking_id = bd.booking_id
        JOIN Ticket t ON bd.ticket_id = t.ticket_id JOIN Schedule s ON t.schedule_id = s.schedule_id
        JOIN Bus bu ON s.bus_id = bu.bus_id WHERE bu.company_id = p_company_id
        GROUP BY m.name, m.email ORDER BY total_spent_with_company DESC;
    v_rank NUMBER;
    v_company_found BOOLEAN := FALSE;
    v_title VARCHAR2(100);
BEGIN
    v_title := 'Top ' || p_top_n || ' Most Valuable Members Report';
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD(v_title, 40 + (LENGTH(v_title)/2) ));
    DBMS_OUTPUT.PUT_LINE('Report Generated On: ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH:MI:SS AM'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

    FOR company_rec IN company_cursor LOOP
        v_company_found := TRUE;
        DBMS_OUTPUT.NEW_LINE;
        DBMS_OUTPUT.PUT_LINE('Analysis for Company: ' || company_rec.name);
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));
        
        DBMS_OUTPUT.PUT_LINE(
            RPAD('Rank', 6) ||
            RPAD('Member Name', 28) ||
            RPAD('Email Address', 30) ||
            'Total Spent (RM)'
        );
        DBMS_OUTPUT.PUT_LINE(
            RPAD('----', 6) ||
            RPAD('-----------------------', 28) ||
            RPAD('-------------------------', 30) ||
            '----------------'
        );
        
        v_rank := 1;
        FOR member_rec IN top_spenders_cursor(company_rec.company_id) LOOP
            EXIT WHEN v_rank > p_top_n;
            
            DBMS_OUTPUT.PUT_LINE(
                RPAD(v_rank, 6) ||
                RPAD(member_rec.name, 28) ||
                RPAD(member_rec.email, 30) ||
                LPAD(TO_CHAR(member_rec.total_spent_with_company, 'FM9,999,990.00'), 16) -- Use LPAD for right-alignment of numbers
            );
            v_rank := v_rank + 1;
        END LOOP;

        IF v_rank = 1 THEN
            DBMS_OUTPUT.PUT_LINE('  No member spending data found for this company.');
        END IF;
    END LOOP;

    IF NOT v_company_found THEN
        DBMS_OUTPUT.NEW_LINE;
        DBMS_OUTPUT.PUT_LINE('No company found with the name ''' || p_company_name || '''.');
    END IF;

    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(LPAD('--- End of Report ---', 49));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
END rpt_company_member_value;
/

COMMIT;


-- ===========================================================================
-- Report 2: On-Demand and Detail Report of a Company's Member Cancellations
-- ===========================================================================

CREATE OR REPLACE PROCEDURE rpt_company_cancellation (
    p_company_name IN VARCHAR2,
    p_year         IN NUMBER,
    p_top_n        IN NUMBER DEFAULT 3
)
AS
    -- MASTER CURSOR
    CURSOR company_cursor IS
        SELECT company_id, name FROM Company WHERE LOWER(name) = LOWER(p_company_name);

    -- DETAIL CURSOR
    CURSOR member_cancellation_cursor (p_company_id IN NUMBER, p_filter_year IN NUMBER) IS
        SELECT m.name, m.email, COUNT(t.ticket_id) as cancellation_count
        FROM Member m JOIN Booking b ON m.member_id = b.member_id JOIN BookingDetails bd ON b.booking_id = bd.booking_id
        JOIN Ticket t ON bd.ticket_id = t.ticket_id JOIN Schedule s ON t.schedule_id = s.schedule_id
        JOIN Bus bu ON s.bus_id = bu.bus_id
        WHERE t.status = 'Cancelled' AND bu.company_id = p_company_id AND EXTRACT(YEAR FROM b.booking_date) = p_filter_year
        GROUP BY m.name, m.email ORDER BY cancellation_count DESC;
    v_rank NUMBER;
    v_company_found BOOLEAN := FALSE;
    v_title VARCHAR2(100);
BEGIN
    v_title := 'Top ' || p_top_n || ' Member Cancellations Report';
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD(v_title, 40 + (LENGTH(v_title)/2) ));
    DBMS_OUTPUT.PUT_LINE('Report Generated On: ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH:MI:SS AM'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

    FOR company_rec IN company_cursor LOOP
        v_company_found := TRUE;
        DBMS_OUTPUT.NEW_LINE;
        DBMS_OUTPUT.PUT_LINE('Analysis for Company: ' || company_rec.name || ' in Year ' || p_year);
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));

        -- Column Headers
        DBMS_OUTPUT.PUT_LINE(
            RPAD('Rank', 6) ||
            RPAD('Member Name', 28) ||
            RPAD('Email Address', 30) ||
            'Cancellations'
        );
        DBMS_OUTPUT.PUT_LINE(
            RPAD('----', 6) ||
            RPAD('-----------------------', 28) ||
            RPAD('-------------------------', 30) ||
            '-------------'
        );
        
        v_rank := 1;
        FOR member_rec IN member_cancellation_cursor(company_rec.company_id, p_year) LOOP
            EXIT WHEN v_rank > p_top_n;
            
            -- Column-Formatted Output
            DBMS_OUTPUT.PUT_LINE(
                RPAD(v_rank, 6) ||
                RPAD(member_rec.name, 28) ||
                RPAD(member_rec.email, 30) ||
                LPAD(member_rec.cancellation_count, 16)
            );
            v_rank := v_rank + 1;
        END LOOP;

        IF v_rank = 1 THEN
            DBMS_OUTPUT.PUT_LINE('  No member cancellations found for this company in ' || p_year || '.');
        END IF;
    END LOOP;

    IF NOT v_company_found THEN
        DBMS_OUTPUT.NEW_LINE;
        DBMS_OUTPUT.PUT_LINE('No company found with the name ''' || p_company_name || '''.');
    END IF;

    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(LPAD('--- End of Report ---', 49));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
END rpt_company_cancellation;
/

COMMIT;
