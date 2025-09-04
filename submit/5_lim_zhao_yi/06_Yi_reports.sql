--=============================================================================
-- File: 06_reports.sql
--=============================================================================
-- Purpose: Contains stored procedures designed to generate formatted,
--          human-readable reports for management using PL/SQL cursors.
--=============================================================================

SET SERVEROUTPUT ON;

--=============================================================================
-- Section 1: Operational Reports
--=============================================================================

PROMPT Creating Report Procedure: rpt_bus_maintenance_history
CREATE OR REPLACE PROCEDURE rpt_bus_maintenance_history (
    p_bus_id IN Bus.bus_id%TYPE
)
AS
    -- Outer cursor: Fetches the primary record (the bus).
    CURSOR bus_cursor IS
        SELECT
            b.bus_id,
            b.plate_number,
            c.name as company_name
        FROM Bus b
        JOIN Company c ON b.company_id = c.company_id
        WHERE b.bus_id = p_bus_id;

    -- Inner cursor: Fetches the detail records (service history for that bus).
    CURSOR service_history_cursor (cp_bus_id IN Bus.bus_id%TYPE) IS
        SELECT
            sd.service_date,
            s.service_name,
            sd.actual_cost,
            sd.remarks
        FROM ServiceDetails sd
        JOIN Service s ON sd.service_id = s.service_id
        WHERE sd.bus_id = cp_bus_id
        ORDER BY sd.service_date DESC;

    v_bus_found BOOLEAN := FALSE;

BEGIN
    -- Loop through the outer cursor (will only run once, or zero times if bus not found)
    FOR bus_rec IN bus_cursor LOOP
        v_bus_found := TRUE;

        -- Print the master report header
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
        DBMS_OUTPUT.PUT_LINE('Maintenance History Report');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));
        DBMS_OUTPUT.PUT_LINE('Bus Plate Number: ' || bus_rec.plate_number);
        DBMS_OUTPUT.PUT_LINE('Operating Company: ' || bus_rec.company_name);
        DBMS_OUTPUT.PUT_LINE('');

        -- Print the detail section header
        DBMS_OUTPUT.PUT_LINE('Service History:');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));
        DBMS_OUTPUT.PUT_LINE(
            RPAD('Service Date', 15) ||
            RPAD('Service Name', 25) ||
            RPAD('Cost (RM)', 15) ||
            'Remarks'
        );
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));

        -- Now, the inner cursor call is valid because bus_rec.bus_id exists
        FOR service_rec IN service_history_cursor(bus_rec.bus_id) LOOP
            DBMS_OUTPUT.PUT_LINE(
                RPAD(TO_CHAR(service_rec.service_date, 'DD-MON-YYYY'), 15) ||
                RPAD(SUBSTR(service_rec.service_name, 1, 23), 25) ||
                RPAD(TO_CHAR(service_rec.actual_cost, '99,990.00'), 15) ||
                NVL(service_rec.remarks, 'N/A')
            );
        END LOOP;

        DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    END LOOP;

    -- Handle the case where the bus_id was not found
    IF NOT v_bus_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: No bus found with ID ' || p_bus_id || '.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_bus_maintenance_history;
/

PROMPT Creating Report Procedure: rpt_shop_rental_statement
CREATE OR REPLACE PROCEDURE rpt_shop_rental_statement (
    p_shop_id IN Shop.shop_id%TYPE
)
AS
    -- Outer cursor: Get shop details
    CURSOR shop_cursor IS
        SELECT
            s.shop_id,
            s.shop_name,
            s.location_code
        FROM Shop s
        WHERE s.shop_id = p_shop_id;

    -- Inner cursor: Get rental payment history for the shop
    CURSOR rental_history_cursor (cp_shop_id IN Shop.shop_id%TYPE) IS
        SELECT
            rc.rental_date,
            rc.amount,
            rc.collection_date,
            rc.rental_method,
            rc.remark,
            st.name as staff_name
        FROM RentalCollection rc
        JOIN Staff st ON rc.staff_id = st.staff_id
        WHERE rc.shop_id = cp_shop_id
        ORDER BY rc.rental_date DESC;

    v_shop_found BOOLEAN := FALSE;
    v_total_collected NUMBER := 0;

BEGIN
    -- Loop through shop details
    FOR shop_rec IN shop_cursor LOOP
        v_shop_found := TRUE;

        -- Print the report header
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
        DBMS_OUTPUT.PUT_LINE('Shop Rental Statement');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
        DBMS_OUTPUT.PUT_LINE('Shop Name: ' || shop_rec.shop_name);
        DBMS_OUTPUT.PUT_LINE('Location Code: ' || shop_rec.location_code);
        DBMS_OUTPUT.PUT_LINE('');

        -- Print the detail section header
        DBMS_OUTPUT.PUT_LINE('Payment History:');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
        DBMS_OUTPUT.PUT_LINE(
            RPAD('Rental Date', 12) ||
            RPAD('Amount (RM)', 12) ||
            RPAD('Collected', 12) ||
            RPAD('Method', 15) ||
            RPAD('Staff', 15) ||
            'Remarks'
        );
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

        -- Loop through rental history
        FOR rental_rec IN rental_history_cursor(shop_rec.shop_id) LOOP
            v_total_collected := v_total_collected + rental_rec.amount;
            DBMS_OUTPUT.PUT_LINE(
                RPAD(TO_CHAR(rental_rec.rental_date, 'DD-MON-YY'), 12) ||
                RPAD(TO_CHAR(rental_rec.amount, '99,990.00'), 12) ||
                RPAD(TO_CHAR(rental_rec.collection_date, 'DD-MON-YY'), 12) ||
                RPAD(NVL(rental_rec.rental_method, 'N/A'), 15) ||
                RPAD(SUBSTR(rental_rec.staff_name, 1, 13), 15) ||
                NVL(rental_rec.remark, 'N/A')
            );
        END LOOP;

        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
        DBMS_OUTPUT.PUT_LINE('Total Collected: RM ' || TO_CHAR(v_total_collected, '999,999,990.00'));
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
    END LOOP;

    -- Handle the case where the shop_id was not found
    IF NOT v_shop_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: No shop found with ID ' || p_shop_id || '.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_shop_rental_statement;
/

PROMPT Creating Report Procedure: rpt_all_shops_rental
CREATE OR REPLACE PROCEDURE rpt_all_shops_rental
AS
    -- Cursor to get all shops
    CURSOR shop_cursor IS
        SELECT shop_id
        FROM Shop
        ORDER BY shop_id;
BEGIN
    FOR shop_rec IN shop_cursor LOOP
        -- Call the existing procedure for each shop
        rpt_shop_rental_statement(shop_rec.shop_id);
        DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Add some space between shop reports
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_all_shops_rental;
/

PROMPT Creating Report Procedure: rpt_service_cost_by_type
CREATE OR REPLACE PROCEDURE rpt_service_cost_by_type
AS
    -- Cursor to get service cost summary by type
    CURSOR service_summary_cursor IS
        SELECT
            s.service_name,
            s.standard_cost,
            COUNT(sd.service_transaction_id) as service_count,
            SUM(sd.actual_cost) as total_actual_cost,
            AVG(sd.actual_cost) as avg_actual_cost,
            MIN(sd.actual_cost) as min_cost,
            MAX(sd.actual_cost) as max_cost
        FROM Service s
        LEFT JOIN ServiceDetails sd ON s.service_id = sd.service_id
        GROUP BY s.service_id, s.service_name, s.standard_cost
        ORDER BY total_actual_cost DESC NULLS LAST;

    v_grand_total NUMBER := 0;

BEGIN
    -- Print the report header
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));
    DBMS_OUTPUT.PUT_LINE('Service Cost Summary by Type');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Service Name', 25) ||
        RPAD('Standard', 12) ||  -- Increased width
        RPAD('Count', 8) ||
        RPAD('Total Spent', 15) ||
        RPAD('Average', 15) ||   -- Increased width
        RPAD('Min Cost', 12) ||  -- Increased width
        'Max Cost'               -- Will use remaining space
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));

    -- Loop through service summary
    FOR service_rec IN service_summary_cursor LOOP
        v_grand_total := v_grand_total + NVL(service_rec.total_actual_cost, 0);
        DBMS_OUTPUT.PUT_LINE(
            RPAD(SUBSTR(service_rec.service_name, 1, 23), 25) ||
            RPAD(TO_CHAR(service_rec.standard_cost, '999,999.99'), 12) ||  -- Added comma formatting
            RPAD(TO_CHAR(NVL(service_rec.service_count, 0), '9999'), 8) ||  -- Increased digit count
            RPAD(TO_CHAR(NVL(service_rec.total_actual_cost, 0), '999,999,990.00'), 15) ||  -- Added comma formatting
            RPAD(TO_CHAR(NVL(service_rec.avg_actual_cost, 0), '999,999.99'), 15) ||  -- Added comma formatting
            RPAD(TO_CHAR(NVL(service_rec.min_cost, 0), '999,999.99'), 12) ||  -- Added comma formatting
            TO_CHAR(NVL(service_rec.max_cost, 0), '999,999.99')  -- Added comma formatting
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));
    DBMS_OUTPUT.PUT_LINE('Grand Total: RM ' || TO_CHAR(v_grand_total, '999,999,999,990.00'));  -- Increased digit count
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_service_cost_by_type;
/

-- Call the procedures with example parameters
BEGIN
    rpt_bus_maintenance_history(1); -- Replace 1 with a valid bus_id
    DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Add some space between reports
    rpt_all_shops_rental(); -- This will show rental statements for ALL shops
    DBMS_OUTPUT.PUT_LINE(CHR(10)); -- Add some space between reports
    rpt_service_cost_by_type();
END;
/