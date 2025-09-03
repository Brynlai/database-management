-- ===========================================================================
-- Report 1: On demand and Detail report of Member Lifetime Value by Company
-- ===========================================================================

SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE rpt_member_value_by_company (
    p_top_n_members IN NUMBER DEFAULT 10
)
AS
    CURSOR member_cursor IS
        SELECT m.member_id, m.name, m.email, SUM(b.total_amount) as lifetime_value
        FROM Member m JOIN Booking b ON m.member_id = b.member_id
        GROUP BY m.member_id, m.name, m.email ORDER BY lifetime_value DESC;
    CURSOR spending_by_company_cursor (p_member_id IN NUMBER) IS
        SELECT c.name as company_name, SUM(s.base_price) as spent_with_company
        FROM Ticket t JOIN Schedule s ON t.schedule_id = s.schedule_id JOIN Bus bu ON s.bus_id = bu.bus_id
        JOIN Company c ON bu.company_id = c.company_id JOIN BookingDetails bd ON t.ticket_id = bd.ticket_id
        JOIN Booking b ON bd.booking_id = b.booking_id WHERE b.member_id = p_member_id
        GROUP BY c.name ORDER BY spent_with_company DESC;
    v_member_rank NUMBER := 1;
    v_title VARCHAR2(100);
BEGIN
    v_title := 'Top ' || p_top_n_members || ' Member Lifetime Value Report by Company';
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD(v_title, 40 + (LENGTH(v_title)/2) ));
    DBMS_OUTPUT.PUT_LINE('Report Generated On: ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH:MI:SS AM'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

    FOR member_rec IN member_cursor LOOP
        EXIT WHEN v_member_rank > p_top_n_members;
        DBMS_OUTPUT.NEW_LINE;
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        DBMS_OUTPUT.PUT_LINE(v_member_rank || '. Member: ' || member_rec.name || ' (' || member_rec.email || ')');
        DBMS_OUTPUT.PUT_LINE('   Total Lifetime Spending: RM ' || TO_CHAR(member_rec.lifetime_value, 'FM999,999,990.00'));
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        FOR company_rec IN spending_by_company_cursor(member_rec.member_id) LOOP
            DBMS_OUTPUT.PUT_LINE('   - Spent with ' || RPAD(company_rec.company_name, 30) || ': RM ' || TO_CHAR(company_rec.spent_with_company, 'FM99,990.00'));
        END LOOP;
        v_member_rank := v_member_rank + 1;
    END LOOP;
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
END rpt_member_value_by_company;
/

COMMIT;


-- =========================================================================
-- Report 2: On Demand and Detail report of Company Cancellation Analysis
-- =========================================================================

CREATE OR REPLACE PROCEDURE rpt_cancellation_by_company (
    p_year IN NUMBER
)
AS
    CURSOR company_cursor IS SELECT company_id, name FROM Company ORDER BY name;
    CURSOR member_cancellation_cursor (p_company_id IN NUMBER, p_filter_year IN NUMBER) IS
        SELECT m.name, COUNT(t.ticket_id) as cancellation_count
        FROM Member m JOIN Booking b ON m.member_id = b.member_id JOIN BookingDetails bd ON b.booking_id = bd.booking_id
        JOIN Ticket t ON bd.ticket_id = t.ticket_id JOIN Schedule s ON t.schedule_id = s.schedule_id
        JOIN Bus bu ON s.bus_id = bu.bus_id
        WHERE t.status = 'Cancelled' AND bu.company_id = p_company_id AND EXTRACT(YEAR FROM b.booking_date) = p_filter_year
        GROUP BY m.name ORDER BY cancellation_count DESC;
    v_rank NUMBER;
    v_title VARCHAR2(100);
BEGIN
    v_title := 'Company Cancellation Analysis Report for Year: ' || p_year;
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD(v_title, 40 + (LENGTH(v_title)/2) ));
    DBMS_OUTPUT.PUT_LINE('Report Generated On: ' || TO_CHAR(SYSDATE, 'DD-Mon-YYYY HH:MI:SS AM'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));

    FOR company_rec IN company_cursor LOOP
        DBMS_OUTPUT.NEW_LINE;
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        DBMS_OUTPUT.PUT_LINE('Company: ' || company_rec.name);
        DBMS_OUTPUT.PUT_LINE('Top 3 Members by Cancellations:');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        v_rank := 1;
        FOR member_rec IN member_cancellation_cursor(company_rec.company_id, p_year) LOOP
            EXIT WHEN v_rank > 3;
            DBMS_OUTPUT.PUT_LINE('  ' || v_rank || '. ' || RPAD(member_rec.name, 40) || ' (' || member_rec.cancellation_count || ' cancellations)');
            v_rank := v_rank + 1;
        END LOOP;
        IF v_rank = 1 THEN
            DBMS_OUTPUT.PUT_LINE('  No member cancellations found for this company in ' || p_year || '.');
        END IF;
    END LOOP;
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(LPAD('--- End of Report ---', 49));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
END rpt_cancellation_by_company;
/

COMMIT;
