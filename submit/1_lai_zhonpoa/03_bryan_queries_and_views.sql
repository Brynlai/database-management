--=============================================================================
-- File: 03_queries_and_views.sql
--=============================================================================
-- Purpose: Creates reusable views to simplify data access and provides
--          examples of complex analytical queries for management.
--=============================================================================

--=============================================================================
-- Section 1: Foundational Views
--=============================================================================
-- These views abstract complex joins and provide a simplified, logical layer
-- for other developers and analysts to query against.

PROMPT Creating View: V_BOOKING_DETAILS
CREATE OR REPLACE VIEW V_BOOKING_DETAILS AS
SELECT
    b.booking_id,
    b.booking_date,
    m.member_id,
    m.name AS member_name,
    m.email AS member_email,
    m.paid_registration_fee,
    t.ticket_id,
    t.seat_number,
    t.status AS ticket_status,
    s.schedule_id,
    s.departure_time,
    s.arrival_time,
    s.origin_station,
    s.destination_station,
    s.base_price,
    c.company_id,
    c.name AS company_name,
    p.promotion_id,
    p.promotion_name
FROM Booking b
JOIN Member m ON b.member_id = m.member_id
JOIN BookingDetails bd ON b.booking_id = bd.booking_id
JOIN Ticket t ON bd.ticket_id = t.ticket_id
JOIN Schedule s ON t.schedule_id = s.schedule_id
JOIN Bus bu ON s.bus_id = bu.bus_id
JOIN Company c ON bu.company_id = c.company_id
LEFT JOIN Promotion p ON t.promotion_id = p.promotion_id;

COMMENT ON TABLE V_BOOKING_DETAILS IS 'A comprehensive view combining booking, member, ticket, and schedule information for easy querying of all booking-related data.';


PROMPT Creating View: V_BUS_SCHEDULE_DETAILS
CREATE OR REPLACE VIEW V_BUS_SCHEDULE_DETAILS AS
SELECT
    s.schedule_id,
    s.departure_time,
    s.arrival_time,
    s.base_price,
    s.origin_station,
    s.destination_station,
    s.platform_no,
    b.bus_id,
    b.plate_number,
    b.capacity,
    c.company_id,
    c.name AS company_name
FROM Schedule s
JOIN Bus b ON s.bus_id = b.bus_id
JOIN Company c ON b.company_id = c.company_id;

COMMENT ON TABLE V_BUS_SCHEDULE_DETAILS IS 'A simplified view joining schedule, bus, and company details, ideal for searching and displaying trip information.';


PROMPT Creating View: V_STAFF_SERVICE_WORK
CREATE OR REPLACE VIEW V_STAFF_SERVICE_WORK AS
SELECT
    st.staff_id,
    st.role,
    st.name,
    sa.service_transaction_id,
    sd.actual_cost,
    sd.service_date
FROM Staff st
JOIN StaffAllocation sa ON st.staff_id = sa.staff_id
JOIN ServiceDetails sd ON sa.service_transaction_id = sd.service_transaction_id;

COMMENT ON TABLE V_STAFF_SERVICE_WORK IS 'View mapping staff to their service tasks and costs, used for operational performance reporting.';




















--=============================================================================
-- Query 1: Annual Revenue Analysis with Market Share (Strategic Level)
--=============================================================================
-- Purpose: This query provides a strategic analysis of market share for a specific year.
--          It allows management to enter a year and receive a report showing not just
--          raw revenue per company, but also each company's percentage contribution
--          to the total revenue for that year. This is essential for annual reviews
--          and strategic planning.

PROMPT Running Query: Annual Revenue Analysis with Market Share

-- Define a substitution variable for the year. Can be changed when running the script.
DEFINE query_year = 2024

-- Setup for the report format
SET LINESIZE 120
SET PAGESIZE 200
TTITLE CENTER 'Annual Revenue and Market Share Analysis for Year &query_year' SKIP 2

-- Define column formats for clean output and readability
COLUMN booking_month FORMAT A10 HEADING 'Month'
COLUMN company_name  FORMAT A30 HEADING 'Bus Company'
COLUMN total_revenue FORMAT 999,999,990.00 HEADING 'Total Revenue (RM)'
COLUMN ticket_count  FORMAT 999,999 HEADING 'Tickets Sold'
COLUMN revenue_pct   FORMAT A15 HEADING 'Revenue Share'

-- Group the report by month and compute monthly subtotals for BOTH revenue and tickets
BREAK ON booking_month SKIP 1
COMPUTE SUM LABEL 'Monthly Total:' OF total_revenue ticket_count ON booking_month

-- The actual query using an analytic function
SELECT
    booking_month,
    company_name,
    total_revenue,
    ticket_count,
    TO_CHAR(RATIO_TO_REPORT(total_revenue) OVER (PARTITION BY booking_month) * 100, '990.0') || '%' AS revenue_pct
FROM (
    -- Subquery to perform the initial aggregation
    SELECT
        TO_CHAR(vb.booking_date, 'YYYY-MM') AS booking_month,
        vb.company_name,
        SUM(vb.base_price) AS total_revenue,
        COUNT(vb.ticket_id) AS ticket_count
    FROM V_BOOKING_DETAILS vb
    WHERE vb.ticket_status = 'Booked'
      AND EXTRACT(YEAR FROM vb.booking_date) = &query_year -- MODIFICATION: Filter by the defined year
    GROUP BY
        TO_CHAR(vb.booking_date, 'YYYY-MM'),
        vb.company_name
)
ORDER BY
    booking_month DESC,
    total_revenue DESC;

-- Clean up formatting settings to not affect subsequent queries
CLEAR COLUMNS;
CLEAR BREAKS;
CLEAR COMPUTES;
TTITLE OFF;

























--=============================================================================
-- Query 2: Staff Cost and Workload Analysis (Operational Level)
--=============================================================================
-- Purpose: This operational query is for workshop managers to analyze workload and
--          cost distribution. It not only shows tasks and costs per employee but
--          also calculates each staff member's cost contribution as a percentage
--          of their role's total. This helps pinpoint high-cost staff, identify
--          efficiency opportunities, and manage budgets more effectively.

PROMPT Running Query: Staff Cost and Workload Analysis

-- Setup for the report format
SET LINESIZE 120
SET PAGESIZE 200
TTITLE CENTER 'Staff Cost and Workload Analysis by Role' SKIP 2

-- Define column formats for a clean, professional report
COLUMN staff_role         FORMAT A15 HEADING 'Staff Role'
COLUMN staff_name         FORMAT A25 HEADING 'Staff Name'
COLUMN tasks_completed    FORMAT 999,990 HEADING 'Tasks|Completed'
COLUMN total_service_cost FORMAT 9,999,990.00 HEADING 'Total Cost|(RM)'
COLUMN avg_cost_per_task  FORMAT 999,990.00 HEADING 'Avg Cost|Per Task (RM)'
COLUMN cost_share         FORMAT A15 HEADING 'Share of|Role Cost'

-- Group the report by role and compute role-based totals
BREAK ON staff_role SKIP 1
COMPUTE SUM LABEL 'Role Total:' OF tasks_completed total_service_cost ON staff_role

-- The actual query using a Common Table Expression (CTE) for clarity
WITH StaffAggregates AS (
    -- Step 1: Aggregate the raw numbers per staff member
    SELECT
        v.role AS staff_role,
        v.name AS staff_name,
        COUNT(v.service_transaction_id) AS tasks_completed,
        SUM(v.actual_cost) AS total_service_cost,
        AVG(v.actual_cost) AS avg_cost_per_task
    FROM V_STAFF_SERVICE_WORK v
    WHERE v.role IN ('Technician', 'Cleaner')
    GROUP BY
        v.role,
        v.staff_id,
        v.name
)
-- Step 2: Select from the aggregated data and apply the analytic function
SELECT
    staff_role,
    staff_name,
    tasks_completed,
    total_service_cost,
    avg_cost_per_task,
    -- Calculate each staff's cost as a percentage of their role's total cost
    TO_CHAR(RATIO_TO_REPORT(total_service_cost) OVER (PARTITION BY staff_role) * 100, '990.0') || '%' AS cost_share
FROM StaffAggregates
ORDER BY
    staff_role,
    tasks_completed DESC;

-- Clean up formatting settings
CLEAR COLUMNS;
CLEAR BREAKS;
CLEAR COMPUTES;
TTITLE OFF;

COMMIT;