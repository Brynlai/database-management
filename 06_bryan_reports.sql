--=============================================================================
-- File: 06_reports.sql
--=============================================================================
-- Purpose: Contains stored procedures designed to generate formatted,
--          human-readable reports for management using PL/SQL cursors.
--=============================================================================

SET SERVEROUTPUT ON;

--=============================================================================
-- Section 1: Financial and Marketing Reports
--=============================================================================

PROMPT Creating Report Procedure: rpt_campaign_performance
CREATE OR REPLACE PROCEDURE rpt_campaign_performance (
    p_year IN NUMBER
)
AS
    -- This cursor will fetch all campaigns that were active in the given year.
    CURSOR campaign_cursor IS
        SELECT
            campaign_id,
            campaign_name,
            start_date,
            end_date
        FROM Campaign
        WHERE EXTRACT(YEAR FROM start_date) = p_year
           OR EXTRACT(YEAR FROM end_date) = p_year
        ORDER BY start_date;

    v_promo_count       NUMBER;
    v_tickets_sold      NUMBER;
    v_total_revenue     NUMBER(12, 2);
    v_report_generated  BOOLEAN := FALSE;

BEGIN
    -- Print the report header
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));
    DBMS_OUTPUT.PUT_LINE('Campaign Performance Report for Year: ' || p_year);
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Campaign Name', 40) ||
        RPAD('Promotions', 15) ||
        RPAD('Tickets Sold', 15) ||
        'Total Revenue (RM)'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));

    -- Loop through each campaign found by the cursor
    FOR campaign_rec IN campaign_cursor LOOP
        v_report_generated := TRUE;

        -- 1. Count the number of promotions for this campaign
        SELECT COUNT(*)
        INTO v_promo_count
        FROM Promotion
        WHERE campaign_id = campaign_rec.campaign_id;

        -- 2. Calculate tickets sold and revenue for this campaign's promotions
        SELECT
            COALESCE(COUNT(t.ticket_id), 0),
            COALESCE(SUM(s.base_price), 0)
        INTO v_tickets_sold, v_total_revenue
        FROM Ticket t
        JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE t.promotion_id IN (SELECT promotion_id FROM Promotion WHERE campaign_id = campaign_rec.campaign_id)
          AND t.status = 'Booked';

        -- Print the formatted row for this campaign
        DBMS_OUTPUT.PUT_LINE(
            RPAD(SUBSTR(campaign_rec.campaign_name, 1, 38), 40) ||
            RPAD(TO_CHAR(v_promo_count, '999,990'), 15) ||
            RPAD(TO_CHAR(v_tickets_sold, '999,990'), 15) ||
            TO_CHAR(v_total_revenue, '999,999,990.00')
        );

    END LOOP;

    -- Handle the case where no campaigns were found for the given year
    IF NOT v_report_generated THEN
        DBMS_OUTPUT.PUT_LINE('No campaign data found for the year ' || p_year || '.');
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_campaign_performance;
/


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