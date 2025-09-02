-- =============================================================================
-- Bus Station Management System - Specific Ticket Queries
-- Query 1: Find all tickets that were successfully refunded in a specific month
-- Query 2: List all tickets for journeys scheduled to depart tomorrow
-- =============================================================================

SET SERVEROUTPUT ON;
SET PAGESIZE 120;
SET LINESIZE 200;
SET WRAP OFF;
SET FEEDBACK ON;
SET HEADING ON;
CLEAR COLUMNS;

PROMPT;
PROMPT ====================================================================================;
PROMPT Ticket queries completed successfully!
PROMPT;
PROMPT Query 1 shows: Find all tickets that were successfully refunded in a specific month.
PROMPT Query 2 shows: All tickets departing tomorrow with passenger details
PROMPT;
PROMPT ====================================================================================;
-- =============================================================================
-- QUERY 1: Find all tickets that were successfully refunded in a specific month
-- Change the month (1-12) and year values below as needed
-- =============================================================================

-- Set the month and year you want to query (change these values)
DEFINE query_month = 1      -- Change to desired month (1=Jan, 2=Feb, 3=Mar, etc.)
DEFINE query_year = 2024    -- Change to desired year

PROMPT Query 1: Tickets successfully refunded in month &query_month of &query_year...

COLUMN refund_id        FORMAT 99999 HEADING "Refund|ID"
COLUMN refund_date      FORMAT A11 HEADING "Refund|Date"
COLUMN refund_amount    FORMAT 999.99 HEADING "Amount|RM"
COLUMN refund_method    FORMAT A20 HEADING "Method"
COLUMN member_name      FORMAT A18 HEADING "Member"
COLUMN route            FORMAT A28 HEADING "Route"
COLUMN hours_before     FORMAT 9999.9 HEADING "Hours Before"

SELECT 
    r.refund_id,
    TO_CHAR(r.refund_date, 'DD-MON-YYYY') AS refund_date,
    r.amount AS refund_amount,
    r.refund_method,
    SUBSTR(m.name, 1, 18) AS member_name,
    SUBSTR(s.origin_station || ' To ' || s.destination_station, 1, 28) AS route,
    ROUND((s.departure_time - r.refund_date) * 24, 1) AS hours_before
FROM Refund r
INNER JOIN Ticket t ON r.ticket_id = t.ticket_id
INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
INNER JOIN BookingDetails bd ON t.ticket_id = bd.ticket_id
INNER JOIN Booking b ON bd.booking_id = b.booking_id
INNER JOIN Member m ON b.member_id = m.member_id
WHERE EXTRACT(MONTH FROM r.refund_date) = &query_month
  AND EXTRACT(YEAR FROM r.refund_date) = &query_year
ORDER BY r.refund_date DESC, r.amount DESC;

PROMPT;
PROMPT =============================================================================;
PROMPT;

-- =============================================================================
-- QUERY 2: List all tickets for journeys scheduled to depart tomorrow
-- =============================================================================
PROMPT Query 2: Tickets for journeys departing tomorrow...

COLUMN ticket_id        FORMAT 99999 HEADING "Ticket|ID"
COLUMN seat_number      FORMAT A4 HEADING "Seat"
COLUMN ticket_status    FORMAT A8 HEADING "Status"
COLUMN departure_time   FORMAT A13 HEADING "Departure"
COLUMN route            FORMAT A28 HEADING "Route"
COLUMN company_name     FORMAT A16 HEADING "Company"
COLUMN passenger_name   FORMAT A18 HEADING "Passenger"
COLUMN final_price      FORMAT 999.99 HEADING "Price|RM"
COLUMN hours_until      FORMAT 999.9 HEADING "Hours|Until"

SELECT 
    t.ticket_id,
    t.seat_number,
    t.status AS ticket_status,
    TO_CHAR(s.departure_time, 'DD-MON HH24:MI') AS departure_time,
    SUBSTR(s.origin_station || ' To ' || s.destination_station, 1, 28) AS route,
    SUBSTR(c.name, 1, 16) AS company_name,
    CASE 
        WHEN t.status = 'Booked' THEN SUBSTR(m.name, 1, 18)
        ELSE NULL 
    END AS passenger_name,
    CASE 
        WHEN pr.discount_type = 'Percentage' THEN 
            ROUND(s.base_price * (1 - pr.discount_value/100), 2)
        WHEN pr.discount_type = 'Fixed Amount' THEN 
            ROUND(s.base_price - pr.discount_value, 2)
        ELSE s.base_price
    END AS final_price,
    ROUND((s.departure_time - SYSDATE) * 24, 1) AS hours_until
FROM Ticket t
INNER JOIN Schedule s ON t.schedule_id = s.schedule_id
INNER JOIN Bus bus ON s.bus_id = bus.bus_id
INNER JOIN Company c ON bus.company_id = c.company_id
LEFT JOIN Promotion pr ON t.promotion_id = pr.promotion_id
LEFT JOIN BookingDetails bd ON t.ticket_id = bd.ticket_id
LEFT JOIN Booking b ON bd.booking_id = b.booking_id
LEFT JOIN Member m ON b.member_id = m.member_id
WHERE TRUNC(s.departure_time) = TRUNC(SYSDATE + 1)
GROUP BY t.ticket_id, t.seat_number, t.status, s.departure_time,
         s.origin_station, s.destination_station, s.base_price, 
         c.name, m.name, pr.discount_type, pr.discount_value
ORDER BY s.departure_time ASC, t.seat_number ASC;

