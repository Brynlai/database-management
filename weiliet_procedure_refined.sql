CREATE OR REPLACE FUNCTION check_bus_overlap (
    p_bus_id         IN Schedule.bus_id%TYPE,
    p_departure_time IN Schedule.departure_time%TYPE,
    p_arrival_time   IN Schedule.arrival_time%TYPE,
    p_schedule_id    IN Schedule.schedule_id%TYPE DEFAULT NULL
) RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO   v_count
    FROM   Schedule s
    WHERE  s.bus_id = p_bus_id
      AND  s.status <> 'Cancelled'
      AND  s.schedule_id <> NVL(p_schedule_id, -1)
      AND  p_departure_time < s.arrival_time
      AND  p_arrival_time   > s.departure_time;

    RETURN CASE WHEN v_count > 0 THEN 1 ELSE 0 END;
END;
/


-- ==========================================================
-- Procedure : schedule_add_new
-- Purpose   : Insert a new schedule (status='Active') with validations
-- Notes     : Boundary touching allowed; used check_bus_overlap()
-- ==========================================================
CREATE OR REPLACE PROCEDURE schedule_add_new (
    p_bus_id              IN  Schedule.bus_id%TYPE,
    p_departure_time      IN  Schedule.departure_time%TYPE,
    p_arrival_time        IN  Schedule.arrival_time%TYPE,
    p_base_price          IN  Schedule.base_price%TYPE,
    p_origin_station      IN  Schedule.origin_station%TYPE,
    p_destination_station IN  Schedule.destination_station%TYPE,
    p_platform_no         IN  Schedule.platform_no%TYPE,
    o_schedule_id         OUT Schedule.schedule_id%TYPE
)
AS
    -- error code constants
    c_err_bus_missing    CONSTANT PLS_INTEGER := -20001;
    c_err_time_order     CONSTANT PLS_INTEGER := -20002;
    c_err_overlap        CONSTANT PLS_INTEGER := -20003;
    c_err_unexpected     CONSTANT PLS_INTEGER := -20004;

    v_bus_cnt NUMBER;
BEGIN
    -- basic null checks
    IF p_bus_id IS NULL OR p_departure_time IS NULL OR p_arrival_time IS NULL THEN
        RAISE_APPLICATION_ERROR(c_err_unexpected, 'Missing required inputs (bus_id / times).');
    END IF;

    -- Bus must exist
    SELECT COUNT(*) INTO v_bus_cnt
    FROM   Bus
    WHERE  bus_id = p_bus_id;

    IF v_bus_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(c_err_bus_missing, 'Bus not found: ' || p_bus_id);
    END IF;

    -- Time order
    IF p_arrival_time <= p_departure_time THEN
        RAISE_APPLICATION_ERROR(c_err_time_order, 'Arrival time must be greater than departure time.');
    END IF;

    -- Overlap (reusable function)
    IF check_bus_overlap(p_bus_id, p_departure_time, p_arrival_time) = 1 THEN
        RAISE_APPLICATION_ERROR(c_err_overlap, 'Overlapping schedule detected for bus ' || p_bus_id);
    END IF;

    -- Insert
    o_schedule_id := schedule_seq.NEXTVAL;

    INSERT INTO Schedule (
        schedule_id, bus_id, departure_time, arrival_time,
        base_price, origin_station, destination_station, platform_no, status
    ) VALUES (
        o_schedule_id, p_bus_id, p_departure_time, p_arrival_time,
        p_base_price, p_origin_station, p_destination_station, p_platform_no, 'Active'
    );

    DBMS_OUTPUT.PUT_LINE('OK: New schedule created => ' || o_schedule_id);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(c_err_unexpected, 'schedule_add_new failed: ' || SQLERRM);
END;
/


-- ==========================================================
-- Procedure : schedule_cancel_trip
-- Purpose   : Set an existing schedule to 'Cancelled'
-- Notes     : Ticket cascade handled by AFTER UPDATE trigger
-- ==========================================================
CREATE OR REPLACE PROCEDURE schedule_cancel_trip (
    p_schedule_id IN Schedule.schedule_id%TYPE
)
AS
    c_err_not_found   CONSTANT PLS_INTEGER := -20012;
    c_err_already_can CONSTANT PLS_INTEGER := -20011;
    c_err_unexpected  CONSTANT PLS_INTEGER := -20014;

    v_status Schedule.status%TYPE;
BEGIN
    IF p_schedule_id IS NULL THEN
        RAISE_APPLICATION_ERROR(c_err_not_found, 'Schedule id is required.');
    END IF;

    SELECT status INTO v_status
    FROM   Schedule
    WHERE  schedule_id = p_schedule_id;

    IF v_status = 'Cancelled' THEN
        RAISE_APPLICATION_ERROR(c_err_already_can, 'Schedule '||p_schedule_id||' is already Cancelled.');
    END IF;

    UPDATE Schedule
    SET    status = 'Cancelled'
    WHERE  schedule_id = p_schedule_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(c_err_not_found, 'Schedule not found: '||p_schedule_id);
    END IF;

    DBMS_OUTPUT.PUT_LINE('OK: Schedule '||p_schedule_id||' set to Cancelled.');
    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(c_err_not_found, 'Schedule not found: '||p_schedule_id);
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(c_err_unexpected, 'schedule_cancel_trip failed: ' || SQLERRM);
END;
/

-- ===== SQL*Plus display settings (lecturer style) =====
SET SERVEROUTPUT ON
SET LINESIZE 140
SET PAGESIZE 100
COLUMN dep_time        FORMAT A20
COLUMN arr_time        FORMAT A20
COLUMN origin_station  FORMAT A16
COLUMN dest_station    FORMAT A16
COLUMN platform_no     FORMAT A8
COLUMN status          FORMAT A10

PROMPT =========================================================
PROMPT = A) Insert a valid schedule
PROMPT =========================================================
DECLARE
  v_new_id  Schedule.schedule_id%TYPE;
  v_bus_id  Bus.bus_id%TYPE;
BEGIN
  SELECT bus_id INTO v_bus_id FROM Bus WHERE ROWNUM = 1;

  schedule_add_new(
    p_bus_id              => v_bus_id,
    p_departure_time      => TRUNC(SYSDATE) + 400,
    p_arrival_time        => TRUNC(SYSDATE) + 400 + 2/24,
    p_base_price          => 25.00,
    p_origin_station      => 'Port William',
    p_destination_station => 'New Harbor',
    p_platform_no         => 'P99',
    o_schedule_id         => v_new_id
  );

  DBMS_OUTPUT.PUT_LINE('Created schedule: '||v_new_id);
END;
/

PROMPT -- Verify last schedule
SELECT schedule_id,
       bus_id,
       TO_CHAR(departure_time,'DD-MON-YYYY HH24:MI') dep_time,
       TO_CHAR(arrival_time,'DD-MON-YYYY HH24:MI')   arr_time,
       platform_no,
       status
FROM   Schedule
WHERE  schedule_id = (SELECT MAX(schedule_id) FROM Schedule);

PROMPT =========================================================
PROMPT = B) Overlap attempt for same bus
PROMPT =========================================================
DECLARE
  v_new_id  Schedule.schedule_id%TYPE;
  v_bus_id  Bus.bus_id%TYPE;
  v_dep     DATE;
  v_arr     DATE;
BEGIN
  SELECT bus_id, departure_time, arrival_time
  INTO   v_bus_id, v_dep, v_arr
  FROM   Schedule
  WHERE  schedule_id = (SELECT MAX(schedule_id) FROM Schedule);

  schedule_add_new(
    p_bus_id              => v_bus_id,
    p_departure_time      => v_dep + 1/24,
    p_arrival_time        => v_arr + 1/24,
    p_base_price          => 20.00,
    p_origin_station      => 'OverlapStart',
    p_destination_station => 'OverlapEnd',
    p_platform_no         => 'P01',
    o_schedule_id         => v_new_id
  );
END;
/

PROMPT =========================================================
PROMPT = C) Boundary touching 
PROMPT =========================================================
DECLARE
  v_new_id  Schedule.schedule_id%TYPE;
  v_bus_id  Bus.bus_id%TYPE;
  v_dep     DATE;
  v_arr     DATE;
BEGIN
  SELECT bus_id, departure_time, arrival_time
  INTO   v_bus_id, v_dep, v_arr
  FROM   Schedule
  WHERE  schedule_id = (SELECT MAX(schedule_id) FROM Schedule);

  schedule_add_new(
    p_bus_id              => v_bus_id,
    p_departure_time      => v_arr,           
    p_arrival_time        => v_arr + 2/24,
    p_base_price          => 22.00,
    p_origin_station      => 'ChainA',
    p_destination_station => 'ChainB',
    p_platform_no         => 'P02',
    o_schedule_id         => v_new_id
  );
END;
/

PROMPT =========================================================
PROMPT = D) Cancel latest schedule (watch STATUS flip)
PROMPT =========================================================
DECLARE
  v_sched_id Schedule.schedule_id%TYPE;
BEGIN
  SELECT MAX(schedule_id) INTO v_sched_id FROM Schedule;
  schedule_cancel_trip(p_schedule_id => v_sched_id);
END;
/

SELECT schedule_id, status
FROM   Schedule
WHERE  schedule_id = (SELECT MAX(schedule_id) FROM Schedule);

-- to manually assign a bus scheduele

-- DECLARE
--   v_new_id  Schedule.schedule_id%TYPE;
--   v_bus_id  Bus.bus_id%TYPE := 94;  -- manually set
--   v_dep     DATE := TO_DATE('2025-09-12 08:00','YYYY-MM-DD HH24:MI');
--   v_arr     DATE := TO_DATE('2025-09-12 10:00','YYYY-MM-DD HH24:MI');
-- BEGIN
--   schedule_add_new(
--     p_bus_id              => v_bus_id,
--     p_departure_time      => v_dep,
--     p_arrival_time        => v_arr,
--     p_base_price          => 28.00,             -- your price here
--     p_origin_station      => 'KL',
--     p_destination_station => 'Seremban',
--     p_platform_no         => 'P05',
--     o_schedule_id         => v_new_id
--   );
--   DBMS_OUTPUT.PUT_LINE('Created schedule: '||v_new_id);
-- END;
-- /