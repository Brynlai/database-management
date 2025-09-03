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
-- 4.1.7 Report 1: On-demand Summary Report of Annual Campaign Performance. (Additional Module 2: Campaign promotions.)
--
-- Purpose: To provide a strategic overview of campaign effectiveness by summarizing ticket sales, revenue,
--          and calculating key performance indicators (KPIs) for a user-specified year.
--

CREATE OR REPLACE PROCEDURE rpt_campaign_performance (
    p_year IN NUMBER
)
AS
    -- Outer cursor: campaigns in the requested year
    CURSOR campaign_cursor IS
        SELECT
            c.campaign_id,
            c.campaign_name
        FROM Campaign c
        WHERE EXTRACT(YEAR FROM c.start_date) = p_year
           OR EXTRACT(YEAR FROM c.end_date) = p_year
        ORDER BY c.start_date;

    -- Inner cursor: aggregated stats per campaign
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

    v_report_generated      BOOLEAN := FALSE;
    v_grand_total_promos    NUMBER := 0;
    v_grand_total_tickets   NUMBER := 0;
    v_grand_total_revenue   NUMBER := 0;
    v_avg_revenue_per_tkt   NUMBER;

BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE('Campaign Performance Report for Year: ' || p_year);
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Campaign Name', 40) ||
        RPAD('Promotions', 12) ||
        RPAD('Tickets Sold', 12) ||
        RPAD('Avg Rev/Tkt', 15) ||
        'Total Revenue (RM)'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

    -- Loop through each campaign
    FOR campaign_rec IN campaign_cursor LOOP
        v_report_generated := TRUE;

        FOR stats_rec IN campaign_stats_cursor(campaign_rec.campaign_id) LOOP
            IF stats_rec.tickets_sold > 0 THEN
                v_avg_revenue_per_tkt := stats_rec.total_revenue / stats_rec.tickets_sold;
            ELSE
                v_avg_revenue_per_tkt := 0;
            END IF;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(SUBSTR(campaign_rec.campaign_name, 1, 38), 40) ||
                LPAD(TO_CHAR(stats_rec.promo_count, 'FM999,990'), 12) ||
                LPAD(TO_CHAR(stats_rec.tickets_sold, 'FM999,990'), 12) ||
                LPAD(TO_CHAR(v_avg_revenue_per_tkt, 'FM99,990.00'), 15) ||
                LPAD(TO_CHAR(stats_rec.total_revenue, 'FM9,999,990.00'), 21)
            );

            v_grand_total_promos  := v_grand_total_promos + stats_rec.promo_count;
            v_grand_total_tickets := v_grand_total_tickets + stats_rec.tickets_sold;
            v_grand_total_revenue := v_grand_total_revenue + stats_rec.total_revenue;
        END LOOP;
    END LOOP;

    -- Handle the case where no campaigns were found
    IF NOT v_report_generated THEN
        DBMS_OUTPUT.PUT_LINE('No campaign data found for the year ' || p_year || '.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
        
        IF v_grand_total_tickets > 0 THEN
            v_avg_revenue_per_tkt := v_grand_total_revenue / v_grand_total_tickets;
        ELSE
            v_avg_revenue_per_tkt := 0;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(
            RPAD('GRAND TOTALS:', 40) ||
            LPAD(TO_CHAR(v_grand_total_promos, 'FM999,990'), 12) ||
            LPAD(TO_CHAR(v_grand_total_tickets, 'FM999,990'), 12) ||
            LPAD(TO_CHAR(v_avg_revenue_per_tkt, 'FM99,990.00'), 15) ||
            LPAD(TO_CHAR(v_grand_total_revenue, 'FM9,999,990.00'), 21)
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_campaign_performance;
/






















--
-- 4.1.8 Report 2: On-demand Detail Report of Bus Maintenance History. (Module 7)
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
            sd.actual_cost
        FROM ServiceDetails sd
        JOIN Service s ON sd.service_id = s.service_id
        WHERE sd.bus_id = cp_bus_id
        ORDER BY sd.service_date DESC;
        
    v_bus_found BOOLEAN := FALSE;
    v_event_count NUMBER := 0;
    v_total_cost  NUMBER := 0;

BEGIN
    -- Loop through the outer cursor
    FOR bus_rec IN bus_cursor LOOP
        v_bus_found := TRUE;
        
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
        DBMS_OUTPUT.PUT_LINE('Maintenance History Report');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        DBMS_OUTPUT.PUT_LINE('Bus Plate Number: ' || bus_rec.plate_number);
        DBMS_OUTPUT.PUT_LINE('Operating Company: ' || bus_rec.company_name);
        DBMS_OUTPUT.PUT_LINE('');
        
        DBMS_OUTPUT.PUT_LINE('Service History:');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        DBMS_OUTPUT.PUT_LINE(
            RPAD('Service Date', 20) ||
            RPAD('Service Name', 30) ||
            'Cost (RM)'
        );
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        
        -- Loop through the inner cursor to print details and calculate totals
        FOR service_rec IN service_history_cursor(bus_rec.bus_id) LOOP
            DBMS_OUTPUT.PUT_LINE(
                RPAD(TO_CHAR(service_rec.service_date, 'DD-MON-YYYY'), 20) ||
                RPAD(SUBSTR(service_rec.service_name, 1, 28), 30) ||
                LPAD(TO_CHAR(service_rec.actual_cost, 'FM9,999,990.00'), 15)
            );
            
            v_event_count := v_event_count + 1;
            v_total_cost := v_total_cost + service_rec.actual_cost;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Overall Summary for Bus ' || bus_rec.plate_number || ':');
        DBMS_OUTPUT.PUT_LINE(RPAD('Total Maintenance Events:', 35) || LPAD(v_event_count, 22));
        DBMS_OUTPUT.PUT_LINE(RPAD('Total Lifetime Maintenance Cost:', 35) || 'RM ' || LPAD(TO_CHAR(v_total_cost, 'FM99,999,990.00'), 19));
        
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
    END LOOP;
    
    IF NOT v_bus_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: No bus found with ID ' || p_bus_id || '.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_bus_maintenance_history;
/