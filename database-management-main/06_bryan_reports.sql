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

















--
-- 4.1.7 Report 1: On-demand Summary Report of Annual Campaign Performance.
--
-- Purpose: To provide a strategic overview of campaign effectiveness by summarizing ticket sales and revenue
--          generated from associated promotions for a user-specified year.
--

CREATE OR REPLACE PROCEDURE rpt_campaign_performance (
    p_year IN NUMBER
)
AS
    -- Outer cursor: campaigns in the requested year
    CURSOR campaign_cursor IS
        SELECT
            c.campaign_id,
            c.campaign_name,
            c.start_date,
            c.end_date
        FROM Campaign c
        WHERE EXTRACT(YEAR FROM c.start_date) = p_year
           OR EXTRACT(YEAR FROM c.end_date) = p_year
        ORDER BY c.start_date;

    -- Inner cursor: aggregated stats per campaign derived from bookings view
    CURSOR campaign_stats_cursor (cp_campaign_id IN Campaign.campaign_id%TYPE) IS
        SELECT
            COUNT(DISTINCT p.promotion_id) AS promo_count,
            COUNT(vb.ticket_id) AS tickets_sold,
            NVL(SUM(vb.base_price), 0) AS total_revenue
        FROM Promotion p
        LEFT JOIN V_BOOKING_DETAILS vb
               ON vb.promotion_id = p.promotion_id
              AND vb.ticket_status = 'Booked'
        WHERE p.campaign_id = cp_campaign_id;

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

    -- Loop through each campaign and fetch nested aggregated stats
    FOR campaign_rec IN campaign_cursor LOOP
        v_report_generated := TRUE;

        FOR stats_rec IN campaign_stats_cursor(campaign_rec.campaign_id) LOOP
            DBMS_OUTPUT.PUT_LINE(
                RPAD(SUBSTR(campaign_rec.campaign_name, 1, 38), 40) ||
                RPAD(TO_CHAR(NVL(stats_rec.promo_count, 0), '999,990'), 15) ||
                RPAD(TO_CHAR(NVL(stats_rec.tickets_sold, 0), '999,990'), 15) ||
                TO_CHAR(NVL(stats_rec.total_revenue, 0), '999,999,990.00')
            );
        END LOOP;

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


























--
-- 4.1.8 Report 2: On-demand Detail Report of Bus Maintenance History.
--
-- Purpose: To provide operational managers with a complete, chronological log of all service activities and
--          associated costs for a specific bus to aid in maintenance tracking and cost analysis.
--

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