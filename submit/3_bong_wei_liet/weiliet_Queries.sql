-- ===== Display settings =====
SET SERVEROUTPUT ON
SET LINESIZE 140
SET PAGESIZE 100
COLUMN index_name     FORMAT A28
COLUMN table_name     FORMAT A12
COLUMN column_name    FORMAT A18
COLUMN driver_name    FORMAT A22
COLUMN license_no     FORMAT A16
COLUMN assignment     FORMAT A30
COLUMN plate_number   FORMAT A12
COLUMN dep_time       FORMAT A20
COLUMN arr_time       FORMAT A20
COLUMN origin_station FORMAT A18
COLUMN dest_station   FORMAT A18
COLUMN platform_no    FORMAT A8
COLUMN status         FORMAT A10

CREATE OR REPLACE VIEW V_SCHEDULE_ASSIGNMENTS AS
SELECT
    s.schedule_id,
    s.bus_id,
    b.plate_number,
    b.company_id,
    c.name               AS company_name,
    s.departure_time,
    s.arrival_time,
    s.base_price,
    s.origin_station,
    s.destination_station,
    s.platform_no,
    s.status,
    dl.driver_id,
    d.name               AS driver_name,
    d.license_no
FROM       Schedule   s
JOIN       Bus        b  ON b.bus_id       = s.bus_id
LEFT JOIN  Company    c  ON c.company_id   = b.company_id
LEFT JOIN  DriverList dl ON dl.schedule_id = s.schedule_id
LEFT JOIN  Driver     d  ON d.driver_id    = dl.driver_id;

PROMPT =========================================================
PROMPT = Index (optimization for overlap checks and lookups)
PROMPT =========================================================

-- ======================================================
-- Index: idx_schedule_bus_time
-- Purpose: Optimize overlap checks and lookups by bus & time
-- ======================================================
CREATE INDEX idx_schedule_bus_time ON Schedule (bus_id, departure_time);
-- ORA-01408 (safe to ignore).

SELECT index_name, table_name, column_name
FROM   user_ind_columns
WHERE  table_name = 'SCHEDULE'
ORDER  BY index_name, column_position;

PROMPT
PROMPT =========================================================
PROMPT = Query 1: Tickets on a specify schedule 
PROMPT =========================================================

SELECT v.schedule_id,
       v.plate_number,
       v.driver_id,
       v.driver_name,
       COUNT(t.ticket_id) AS total_booked_tickets
FROM   V_SCHEDULE_ASSIGNMENTS v
JOIN   Ticket t ON v.schedule_id = t.schedule_id
WHERE  t.schedule_id = 288
GROUP  BY v.schedule_id, v.plate_number, v.driver_id, v.driver_name;


PROMPT
PROMPT =========================================================
PROMPT = Query 2: Driver’s Schedules within a Time Period
PROMPT =========================================================

SELECT driver_id,
       driver_name,
       COUNT(schedule_id) AS total_schedules
FROM   V_SCHEDULE_ASSIGNMENTS
WHERE  departure_time BETWEEN TO_DATE('01-JAN-2025','DD-MON-YYYY') AND TO_DATE('01-SEP-2025','DD-MON-YYYY') AND driver_id = '121'
GROUP  BY driver_id, driver_name
ORDER  BY total_schedules DESC;


PROMPT
PROMPT =========================== End of Queries ===========================