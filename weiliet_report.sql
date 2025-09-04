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

/* ===========================================================
   Wei Liet — Database Management Project
   Complete Report + Queries Script (Oracle 11g Safe)
   =========================================================== */

-- ===========================================================
-- 1) Index (safe creation, skip if exists)
-- ===========================================================
BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_schedule_bus_time ON Schedule (bus_id, departure_time)';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -955 THEN NULL; ELSE RAISE; END IF;
END;
/

-- Confirm index
SELECT index_name, table_name, column_name
FROM   user_ind_columns
WHERE  table_name = 'SCHEDULE'
ORDER  BY index_name, column_position;

-- ===========================================================
-- 2) View: V_SCHEDULE_ASSIGNMENTS
-- Purpose: Unified view of schedules, buses, companies, drivers
-- ===========================================================
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

-- ===========================================================
-- 3) Report: Weekly Driver Assignments
-- Input: p_week_start (DATE) → Monday (or any start day)
-- ===========================================================
CREATE OR REPLACE PROCEDURE rpt_weekly_driver_assignments (
    p_week_start IN DATE
)
AS
    CURSOR c_all IS
        SELECT d.driver_id,
               d.name       AS driver_name,
               s.schedule_id,
               TO_CHAR(s.departure_time,'DD-MON-YYYY HH24:MI') AS dep_time,
               TO_CHAR(s.arrival_time,  'DD-MON-YYYY HH24:MI') AS arr_time,
               s.origin_station,
               s.destination_station,
               s.platform_no,
               s.status
        FROM   Driver d
        LEFT JOIN V_BUS_SCHEDULE_DETAILS s
               ON s.driver_id = d.driver_id
              AND s.departure_time BETWEEN p_week_start AND (p_week_start + 6)
        ORDER  BY d.name, s.departure_time;

    v_total_all   PLS_INTEGER := 0;
    v_total_sched PLS_INTEGER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));
    DBMS_OUTPUT.PUT_LINE('Weekly Driver Assignment Report: '||
                         TO_CHAR(p_week_start,'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));

    -- Header row
    DBMS_OUTPUT.PUT_LINE(
        RPAD('DRIVER_ID',10)||
        RPAD('DRIVER_NAME',22)||
        RPAD('SCHED_ID',10)||
        RPAD('DEPARTURE',20)||
        RPAD('ARRIVAL',20)||
        RPAD('ORIGIN',20)||
        RPAD('DESTINATION',18)||
        RPAD('PLATFORM',10)||
        'STATUS'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));

    -- Main loop
    FOR rec IN c_all LOOP
        v_total_all := v_total_all + 1;

        IF rec.schedule_id IS NOT NULL THEN
            v_total_sched := v_total_sched + 1;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(rec.driver_id,10)||
                RPAD(rec.driver_name,22)||
                RPAD(rec.schedule_id,10)||
                RPAD(rec.dep_time,20)||
                RPAD(rec.arr_time,20)||
                RPAD(SUBSTR(rec.origin_station,1,20),20)||
                RPAD(SUBSTR(rec.destination_station,1,20),20)||
                RPAD(NVL(rec.platform_no,'-'),10)||
                NVL(rec.status,'-')
            );
        END IF;
    END LOOP;

    -- Blank line
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE('Drivers with no assignments this week:');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));

    -- List drivers with no schedules separately
    FOR d IN (SELECT driver_id, name
              FROM   Driver
              WHERE  driver_id NOT IN (
                         SELECT DISTINCT driver_id
                         FROM   V_BUS_SCHEDULE_DETAILS
                         WHERE departure_time BETWEEN p_week_start AND (p_week_start + 6)
                         AND   driver_id IS NOT NULL
                     )
              ORDER  BY name) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(d.driver_id,10)||d.name);
    END LOOP;

    -- Totals
    DBMS_OUTPUT.PUT_LINE(CHR(10)||
        'Total rows (drivers checked): '||v_total_all);
    DBMS_OUTPUT.PUT_LINE('Total schedules listed: '||v_total_sched);

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in rpt_weekly_driver_assignments: '||SQLERRM);
END;
/


-- ===========================================================
-- 4) Report: Platform Usage by Hour
-- Input: p_target_date (DATE)
-- ===========================================================
CREATE OR REPLACE PROCEDURE rpt_platform_usage_by_hour (
    p_target_date IN DATE
)
AS
    CURSOR platform_usage_cursor IS
        SELECT s.platform_no,
               TO_CHAR(s.departure_time,'HH24') AS hour_slot,
               COUNT(*) AS departures
        FROM   V_SCHEDULE_ASSIGNMENTS s
        WHERE  TRUNC(s.departure_time) = TRUNC(p_target_date)
        GROUP  BY s.platform_no, TO_CHAR(s.departure_time,'HH24')
        ORDER  BY s.platform_no, hour_slot;

    v_any_data BOOLEAN := FALSE;
    v_total    PLS_INTEGER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 60, '='));
    DBMS_OUTPUT.PUT_LINE('Platform Usage Report ('||TO_CHAR(p_target_date,'DD-MON-YYYY')||')');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
    DBMS_OUTPUT.PUT_LINE(RPAD('PLATFORM',12)||RPAD('HOUR',8)||'DEPARTURES');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

    FOR rec IN platform_usage_cursor LOOP
        v_any_data := TRUE;
        v_total := v_total + rec.departures;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(NVL(rec.platform_no,'-'),12)||
            RPAD(rec.hour_slot,8)||
            TO_CHAR(rec.departures,'9999')
        );
    END LOOP;

    IF NOT v_any_data THEN
        DBMS_OUTPUT.PUT_LINE('(no departures on this date)');
    ELSE
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
        DBMS_OUTPUT.PUT_LINE('Total departures: '||v_total);
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 60, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in rpt_platform_usage_by_hour: '||SQLERRM);
END;
/

-- ===========================================================
-- 5) Test Blocks (ad-hoc queries, Oracle 11g safe)
-- ===========================================================

-- Driver assignments for a schedule
VARIABLE p_schedule_id NUMBER
EXEC :p_schedule_id := 122;

SELECT schedule_id, driver_id, driver_name, license_no, platform_no,
       TO_CHAR(departure_time,'DD-MON-YYYY HH24:MI') AS dep_time,
       TO_CHAR(arrival_time,  'DD-MON-YYYY HH24:MI') AS arr_time,
       status
FROM   V_SCHEDULE_ASSIGNMENTS
WHERE  schedule_id = :p_schedule_id
ORDER  BY driver_name;

-- Upcoming 7-day schedules for a bus plate number
-- ===== Pretty output for “next 7 days by plate number” =====
SET LINESIZE 200
SET PAGESIZE 200
SET WRAP OFF
SET COLSEP '  |  '

COLUMN schedule_id           HEADING 'SCHEDULE'  FORMAT 999999
COLUMN plate_number          HEADING 'PLATE'     FORMAT A10
COLUMN company_name          HEADING 'COMPANY'   FORMAT A22
COLUMN departure_time_char   HEADING 'DEPARTURE' FORMAT A17
COLUMN arrival_time_char     HEADING 'ARRIVAL'   FORMAT A17
COLUMN origin_station        HEADING 'FROM'      FORMAT A18
COLUMN destination_station   HEADING 'TO'        FORMAT A18
COLUMN platform_no           HEADING 'PLATFORM'  FORMAT A8
COLUMN status                HEADING 'STATUS'    FORMAT A9

-- (keep existing :p_plate)
VARIABLE p_plate VARCHAR2(20)
EXEC :p_plate := 'QBT-345';

SELECT
       s.schedule_id,
       b.plate_number,
       c.name AS company_name,
       TO_CHAR(s.departure_time,'DD-MON-YYYY HH24:MI') AS departure_time_char,
       TO_CHAR(s.arrival_time,  'DD-MON-YYYY HH24:MI') AS arrival_time_char,
       s.origin_station,
       s.destination_station,
       s.platform_no,
       s.status
FROM   Schedule s
JOIN   Bus      b ON b.bus_id = s.bus_id
LEFT JOIN Company c ON c.company_id = b.company_id
WHERE  b.plate_number = :p_plate
  AND  s.departure_time BETWEEN SYSDATE AND SYSDATE + 7
ORDER  BY s.departure_time;


-- Weekly driver assignments (run procedure)
BEGIN
  rpt_weekly_driver_assignments(TO_DATE('2025-09-01','YYYY-MM-DD'));
END;
/

-- Platform usage report (run procedure)
BEGIN
  rpt_platform_usage_by_hour(TO_DATE('2024-6-01','YYYY-MM-DD'));
END;
/
