--=============================================================================
-- Purpose: Ancillary Services & Finance Module for Bus Station Management System
-- Database: Oracle XE 11g
--=============================================================================
-- This module focuses on non-ticket revenue and operational costs including
-- maintenance services and shop rental collections.
--=============================================================================

SET SERVEROUTPUT ON;

--=============================================================================
-- Section 1: Queries (2)
--=============================================================================

PROMPT Creating Query 1: Total Rental Income by Shop for Current Year

-- Setup formatting for the query output
SET LINESIZE 150
SET PAGESIZE 200
TTITLE CENTER 'Annual Rental Income by Shop for Year ' EXTRACT(YEAR FROM SYSDATE) SKIP 2

COLUMN shop_name FORMAT A40 HEADING 'Shop Name'
COLUMN location_code FORMAT A15 HEADING 'Location Code'
COLUMN total_rental_income FORMAT 999,999,990.00 HEADING 'Total Rental Income (RM)'
COLUMN payment_count FORMAT 999,990 HEADING 'Number of Payments'
COLUMN avg_payment FORMAT 999,990.00 HEADING 'Average Payment (RM)'

-- Query 1: Total rental income collected from each shop for the entire year
SELECT 
    s.shop_name,
    s.location_code,
    NVL(SUM(rc.amount), 0) AS total_rental_income,
    COUNT(rc.rental_id) AS payment_count,
    NVL(AVG(rc.amount), 0) AS avg_payment
FROM Shop s
LEFT JOIN RentalCollection rc ON s.shop_id = rc.shop_id 
    AND EXTRACT(YEAR FROM rc.rental_date) = EXTRACT(YEAR FROM SYSDATE)
GROUP BY s.shop_id, s.shop_name, s.location_code
ORDER BY total_rental_income DESC, s.shop_name;

-- Clean up formatting
CLEAR COLUMNS;
TTITLE OFF;

PROMPT Creating Query 2: Total Maintenance Costs by Bus

-- Setup formatting for the query output
SET LINESIZE 150
TTITLE CENTER 'Bus Maintenance Costs Summary (Most to Least Expensive)' SKIP 2

COLUMN plate_number FORMAT A18 HEADING 'Bus Plate Number'
COLUMN company_name FORMAT A26 HEADING 'Company Name'
COLUMN total_maintenance_cost FORMAT 999,999,990.00 HEADING 'Total Maintenance Cost (RM)'
COLUMN service_count FORMAT 999,990 HEADING 'Number of Services'
COLUMN avg_service_cost FORMAT 999,990.00 HEADING 'Average Service Cost (RM)'
COLUMN latest_service FORMAT A16 HEADING 'Latest Service'

-- Query 2: Total maintenance costs for each bus, ordered from most to least expensive
SELECT 
    b.plate_number,
    c.name AS company_name,
    NVL(SUM(sd.actual_cost), 0) AS total_maintenance_cost,
    COUNT(sd.service_transaction_id) AS service_count,
    NVL(AVG(sd.actual_cost), 0) AS avg_service_cost,
    NVL(TO_CHAR(MAX(sd.service_date), 'DD-MON-YYYY'), 'No Service') AS latest_service
FROM Bus b
JOIN Company c ON b.company_id = c.company_id
LEFT JOIN ServiceDetails sd ON b.bus_id = sd.bus_id
GROUP BY b.bus_id, b.plate_number, c.name
ORDER BY total_maintenance_cost DESC, b.plate_number;

-- Clean up formatting
CLEAR COLUMNS;
TTITLE OFF;


PROMPT Query completed successfully!