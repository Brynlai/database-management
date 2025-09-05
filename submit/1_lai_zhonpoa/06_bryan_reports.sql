--=============================================================================
-- File: 06_bryan_reports.sql
-- Author: Bryan Lai ZhonPoa
-- Purpose: Contains advanced stored procedures to generate formatted,
--          analytical reports with actionable insights for management.
--=============================================================================

SET SERVEROUTPUT ON SIZE 1000000;



















--=============================================================================
-- Report 1: Campaign Analytics Dashboard
--=============================================================================
-- Purpose: Provides a strategic, tabular analytics dashboard for marketing.
--          Each campaign is displayed as a single row, showing key
--          performance indicators like Adjusted Profit for easy comparison.
--          A grand total summary is provided. This procedure uses a nested
--          cursor structure to meet assignment requirements.

CREATE OR REPLACE PROCEDURE rpt_campaign_analytics (
    p_year IN NUMBER
)
AS
    CURSOR campaign_cursor IS
        SELECT c.campaign_id, c.campaign_name
        FROM Campaign c
        JOIN Promotion p ON c.campaign_id = p.campaign_id
        JOIN Ticket t ON p.promotion_id = t.promotion_id
        JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE t.status = 'Booked'
          AND (EXTRACT(YEAR FROM c.start_date) = p_year OR EXTRACT(YEAR FROM c.end_date) = p_year)
        GROUP BY c.campaign_id, c.campaign_name
        ORDER BY SUM(s.base_price) DESC;

    CURSOR campaign_stats_cursor (cp_campaign_id IN NUMBER) IS
        SELECT
            COUNT(DISTINCT p.promotion_id) AS promo_count,
            COUNT(t.ticket_id) AS tickets_sold,
            NVL(SUM(s.base_price), 0) AS gross_revenue,
            NVL(SUM(CASE p.discount_type
                    WHEN 'Percentage' THEN s.base_price * (p.discount_value / 100)
                    WHEN 'Fixed Amount' THEN p.discount_value ELSE 0 END
            ), 0) AS total_discounts
        FROM Promotion p
        JOIN Ticket t ON p.promotion_id = t.promotion_id
        JOIN Schedule s ON t.schedule_id = s.schedule_id
        WHERE t.status = 'Booked' AND p.campaign_id = cp_campaign_id;

    v_stats_rec             campaign_stats_cursor%ROWTYPE;
    v_net_revenue           NUMBER;
    v_adj_profit            NUMBER;
    v_grand_gross_rev       NUMBER;
    v_grand_net_rev         NUMBER;
    v_grand_discounts       NUMBER;
    v_grand_tickets         NUMBER;
    v_grand_promos          NUMBER := 0;
    v_grand_adj_profit      NUMBER;
    v_report_generated      BOOLEAN := FALSE;

BEGIN
    SELECT NVL(SUM(tickets_sold),0), NVL(SUM(gross_revenue),0), NVL(SUM(total_discounts),0), NVL(SUM(net_revenue),0), NVL(SUM(adj_profit),0)
    INTO v_grand_tickets, v_grand_gross_rev, v_grand_discounts, v_grand_net_rev, v_grand_adj_profit
    FROM (SELECT COUNT(t.ticket_id) AS tickets_sold, SUM(s.base_price) AS gross_revenue,
            SUM(CASE p.discount_type WHEN 'Percentage' THEN s.base_price * (p.discount_value/100) WHEN 'Fixed Amount' THEN p.discount_value ELSE 0 END) AS total_discounts,
            SUM(s.base_price) - SUM(CASE p.discount_type WHEN 'Percentage' THEN s.base_price * (p.discount_value/100) WHEN 'Fixed Amount' THEN p.discount_value ELSE 0 END) as net_revenue,
            SUM(s.base_price) - (2 * SUM(CASE p.discount_type WHEN 'Percentage' THEN s.base_price * (p.discount_value/100) WHEN 'Fixed Amount' THEN p.discount_value ELSE 0 END)) as adj_profit
          FROM Campaign c JOIN Promotion p ON c.campaign_id=p.campaign_id JOIN Ticket t ON p.promotion_id=t.promotion_id
          JOIN Schedule s ON t.schedule_id=s.schedule_id
          WHERE t.status='Booked' AND (EXTRACT(YEAR FROM c.start_date)=p_year OR EXTRACT(YEAR FROM c.end_date)=p_year)
          GROUP BY c.campaign_id);

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 128, '='));
    DBMS_OUTPUT.PUT_LINE('Campaign Analytics Dashboard for Year: ' || p_year);
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 128, '='));

    DBMS_OUTPUT.PUT_LINE(
        RPAD('Campaign Name', 42) ||
        LPAD('Promos', 8) ||
        LPAD('Tickets', 10) ||
        LPAD('Discounts (RM)', 18) ||
        LPAD('Net Rev (RM)', 18) ||
        LPAD('Adj. Profit (RM)', 18) ||
        LPAD('Avg/Tkt (RM)', 14)
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 128, '-'));

    FOR camp_rec IN campaign_cursor LOOP
        v_report_generated := TRUE;
        OPEN campaign_stats_cursor(camp_rec.campaign_id);
        FETCH campaign_stats_cursor INTO v_stats_rec;
        CLOSE campaign_stats_cursor;

        v_net_revenue := v_stats_rec.gross_revenue - v_stats_rec.total_discounts;
        v_adj_profit := v_net_revenue - v_stats_rec.total_discounts;
        v_grand_promos := v_grand_promos + v_stats_rec.promo_count;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(SUBSTR(camp_rec.campaign_name, 1, 40), 42) ||
            LPAD(TO_CHAR(v_stats_rec.promo_count, 'FM990'), 8) ||
            LPAD(TO_CHAR(v_stats_rec.tickets_sold, 'FM9,990'), 10) ||
            LPAD(TO_CHAR(v_stats_rec.total_discounts, 'FM99,999.00'), 18) ||
            LPAD(TO_CHAR(v_net_revenue, 'FM99,999.00'), 18) ||
            LPAD(TO_CHAR(v_adj_profit, 'SFM99,999.00'), 18) ||
            LPAD(TO_CHAR(CASE WHEN v_stats_rec.tickets_sold > 0 THEN v_net_revenue / v_stats_rec.tickets_sold ELSE 0 END, 'FM990.00'), 14)
        );
    END LOOP;

    IF v_report_generated THEN
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 128, '-'));
        DBMS_OUTPUT.PUT_LINE(
            RPAD('GRAND TOTALS:', 42) ||
            LPAD(TO_CHAR(v_grand_promos, 'FM990'), 8) ||
            LPAD(TO_CHAR(v_grand_tickets, 'FM9,990'), 10) ||
            LPAD(TO_CHAR(v_grand_discounts, 'FM999,999,990.00'), 18) ||
            LPAD(TO_CHAR(v_grand_net_rev, 'FM999,999,990.00'), 18) ||
            LPAD(TO_CHAR(v_grand_adj_profit, 'SFM999,999,990.00'), 18) ||
            LPAD(TO_CHAR(CASE WHEN v_grand_tickets > 0 THEN v_grand_net_rev / v_grand_tickets ELSE 0 END, 'FM990.00'), 14)
        );
    ELSE
        DBMS_OUTPUT.PUT_LINE('No campaign data found for the year ' || p_year || '.');
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 128, '='));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_campaign_analytics;
/


















--=============================================================================
-- Report 2: Bus Maintenance History
--=============================================================================
-- Purpose: Provides a detailed operational and financial analysis of all
--          service activities for a specific bus, comparing actual costs
--          against standard costs to identify budget variances.

CREATE OR REPLACE PROCEDURE rpt_bus_maintenance_history (
    p_bus_id IN Bus.bus_id%TYPE
)
AS
    CURSOR bus_cursor IS
        SELECT b.plate_number, c.name as company_name
        FROM Bus b JOIN Company c ON b.company_id = c.company_id
        WHERE b.bus_id = p_bus_id;

    CURSOR service_history_cursor (cp_bus_id IN Bus.bus_id%TYPE) IS
        SELECT s.service_name, sd.service_date, sd.actual_cost, s.standard_cost
        FROM ServiceDetails sd
        JOIN Service s ON sd.service_id = s.service_id
        WHERE sd.bus_id = cp_bus_id
        ORDER BY sd.service_date DESC;

    v_bus_found BOOLEAN := FALSE;
    v_event_count NUMBER := 0;
    v_total_actual NUMBER := 0;
    v_total_standard NUMBER := 0;
    v_variance NUMBER;

BEGIN
    FOR bus_rec IN bus_cursor LOOP
        v_bus_found := TRUE;
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 110, '='));
        DBMS_OUTPUT.PUT_LINE('Maintenance History and Cost Variance Report');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 110, '-'));
        DBMS_OUTPUT.PUT_LINE('Bus Plate Number: ' || bus_rec.plate_number);
        DBMS_OUTPUT.PUT_LINE('Operating Company: ' || bus_rec.company_name);
        DBMS_OUTPUT.PUT_LINE('');

        DBMS_OUTPUT.PUT_LINE('Service History Details:');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 110, '-'));
        DBMS_OUTPUT.PUT_LINE(
            RPAD('Service Date', 14) ||
            RPAD('Service Name', 28) ||
            LPAD('Std Cost', 15) ||
            LPAD('Actual Cost', 15) ||
            LPAD('Variance', 15) ||
            LPAD('Variance %', 12)
        );
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 110, '-'));

        FOR service_rec IN service_history_cursor(p_bus_id) LOOP
            v_variance := service_rec.actual_cost - service_rec.standard_cost;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(TO_CHAR(service_rec.service_date, 'DD-MON-YYYY'), 14) ||
                RPAD(SUBSTR(service_rec.service_name, 1, 26), 28) ||
                LPAD(TO_CHAR(service_rec.standard_cost, 'FM99,990.00'), 15) ||
                LPAD(TO_CHAR(service_rec.actual_cost, 'FM99,990.00'), 15) ||
                LPAD(TO_CHAR(v_variance, 'SFM99,990.00'), 15) ||
                LPAD(CASE WHEN service_rec.standard_cost > 0
                          THEN TO_CHAR((v_variance / service_rec.standard_cost) * 100, 'SFM990.0') || '%'
                          ELSE 'N/A' END, 12)
            );
            v_event_count    := v_event_count + 1;
            v_total_actual   := v_total_actual + service_rec.actual_cost;
            v_total_standard := v_total_standard + service_rec.standard_cost;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE(RPAD('-', 110, '-'));
        DBMS_OUTPUT.PUT_LINE('Overall Financial Summary for Bus ' || bus_rec.plate_number || ':');
        DBMS_OUTPUT.PUT_LINE(RPAD('Total Maintenance Events:', 35) || LPAD(v_event_count, 20));
        DBMS_OUTPUT.PUT_LINE(RPAD('Total Standard Cost:', 35) || 'RM ' || LPAD(TO_CHAR(v_total_standard, 'FM999,990.00'), 17));
        DBMS_OUTPUT.PUT_LINE(RPAD('Total Actual Cost:', 35) || 'RM ' || LPAD(TO_CHAR(v_total_actual, 'FM999,990.00'), 17));
        DBMS_OUTPUT.PUT_LINE(RPAD('Total Lifetime Variance:', 35) || 'RM ' || LPAD(TO_CHAR(v_total_actual - v_total_standard, 'SFM999,990.00'), 17));
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 110, '='));
    END LOOP;
    
    IF NOT v_bus_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: No bus found with ID ' || p_bus_id || '.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_bus_maintenance_history;
/

--=============================================================================
-- Demonstration Script
--=============================================================================
PROMPT =================================================================
PROMPT DEMONSTRATING REPORTS
PROMPT =================================================================

SET LINESIZE 180;

--
-- DEMO 1: rpt_campaign_analytics
--
PROMPT --- Testing Report 1: Campaign Analytics ---

PROMPT [SUCCESS CASE 1.1] Generating detailed analytics report for 2025.
BEGIN
    rpt_campaign_analytics(p_year => 2025);
END;
/

--
-- DEMO 2: rpt_bus_maintenance_history
--
PROMPT --- Testing Report 2: Bus Maintenance History ---

PROMPT [SUCCESS CASE 2.1] Generating maintenance history for Bus ID 31 (a bus with service records).
BEGIN
    rpt_bus_maintenance_history(p_bus_id => 31);
END;
/
