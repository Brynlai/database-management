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
PROMPT = Query 1: Drivers assigned to a schedule
PROMPT =========================================================

-- Bind variable for schedule_id (change as needed)
VARIABLE p_schedule_id NUMBER
EXEC :p_schedule_id := 166;

SELECT d.driver_id,
       d.name                      AS driver_name,
       d.license_no,
       dl.assignment_notes         AS assignment
FROM   DriverList dl
JOIN   Driver     d ON d.driver_id = dl.driver_id
WHERE  dl.schedule_id = :p_schedule_id
ORDER  BY d.name;

-- (via view, if you created V_SCHEDULE_ASSIGNMENTS)
-- SELECT driver_id,
--        driver_name,
--        license_no,
--        schedule_id,
--        platform_no,
--        TO_CHAR(departure_time,'DD-MON-YYYY HH24:MI') AS dep_time,
--        TO_CHAR(arrival_time,  'DD-MON-YYYY HH24:MI') AS arr_time,
--        status
-- FROM   V_SCHEDULE_ASSIGNMENTS
-- WHERE  schedule_id = :p_schedule_id
-- ORDER  BY driver_name;

PROMPT
PROMPT =========================================================
PROMPT = Query 2: Next 7 days schedules for a bus (by plate no.)
PROMPT =========================================================

-- Bind variable for plate number 
VARIABLE p_plate VARCHAR2(20)
EXEC :p_plate := 'QBT-345';

SELECT s.schedule_id,
       b.plate_number,
       TO_CHAR(s.departure_time,'DD-MON-YYYY HH24:MI') AS dep_time,
       TO_CHAR(s.arrival_time,  'DD-MON-YYYY HH24:MI') AS arr_time,
       s.origin_station         AS origin_station,
       s.destination_station    AS dest_station,
       s.platform_no,
       s.status
FROM   Schedule s
JOIN   Bus      b ON b.bus_id = s.bus_id
WHERE  b.plate_number = :p_plate
  AND  s.departure_time BETWEEN SYSDATE AND SYSDATE + 7
ORDER  BY s.departure_time;

-- (via view, if you created V_SCHEDULE_ASSIGNMENTS):
-- SELECT schedule_id,
--        plate_number,
--        TO_CHAR(departure_time,'DD-MON-YYYY HH24:MI') AS dep_time,
--        TO_CHAR(arrival_time,  'DD-MON-YYYY HH24:MI') AS arr_time,
--        origin_station,
--        destination_station,
--        platform_no,
--        status
-- FROM   V_SCHEDULE_ASSIGNMENTS
-- WHERE  plate_number = :p_plate
--   AND  departure_time BETWEEN SYSDATE AND SYSDATE + 7
-- ORDER  BY departure_time;

PROMPT
PROMPT =========================== End of Queries ===========================