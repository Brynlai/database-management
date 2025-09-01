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
    v_bus_cnt     NUMBER;
    v_overlap_cnt NUMBER;
BEGIN
    -- 1) Bus must exist
    SELECT COUNT(*) INTO v_bus_cnt
    FROM Bus
    WHERE bus_id = p_bus_id;

    IF v_bus_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Bus not found: ' || p_bus_id);
    END IF;

    -- 2) Time order
    IF p_arrival_time <= p_departure_time THEN
        RAISE_APPLICATION_ERROR(-20002, 'Arrival time must be greater than departure time.');
    END IF;

    -- 3) Overlap check for SAME bus (boundary touching allowed)
    -- Overlap if: new_dep < existing_arr AND new_arr > existing_dep
    SELECT COUNT(*) INTO v_overlap_cnt
    FROM Schedule s
    WHERE s.bus_id = p_bus_id
      AND p_departure_time < s.arrival_time
      AND p_arrival_time   > s.departure_time;

    IF v_overlap_cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Overlapping schedule detected for bus ' || p_bus_id);
    END IF;

    -- 4) Insert (status defaults to 'Active' from your ALTER)
    o_schedule_id := schedule_seq.NEXTVAL;

    INSERT INTO Schedule (
        schedule_id, bus_id, departure_time, arrival_time,
        base_price, origin_station, destination_station, platform_no, status
    ) VALUES (
        o_schedule_id, p_bus_id, p_departure_time, p_arrival_time,
        p_base_price, p_origin_station, p_destination_station, p_platform_no, 'Active'
    );

    DBMS_OUTPUT.PUT_LINE('New schedule created: ' || o_schedule_id);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END schedule_add_new;
/


CREATE OR REPLACE PROCEDURE schedule_cancel_trip (
    p_schedule_id IN Schedule.schedule_id%TYPE
)
AS
    v_status Schedule.status%TYPE;
BEGIN
    SELECT status INTO v_status
    FROM Schedule
    WHERE schedule_id = p_schedule_id;

    IF v_status = 'Cancelled' THEN
        RAISE_APPLICATION_ERROR(-20011, 'Schedule '||p_schedule_id||' is already Cancelled.');
    END IF;

    UPDATE Schedule
    SET status = 'Cancelled'
    WHERE schedule_id = p_schedule_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Schedule not found: '||p_schedule_id);
    END IF;

    DBMS_OUTPUT.PUT_LINE('Schedule '||p_schedule_id||' set to Cancelled.');
    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20013, 'Schedule not found: '||p_schedule_id);
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END schedule_cancel_trip;
/

SELECT column_id, column_name, data_type
FROM user_tab_columns
WHERE table_name = 'SCHEDULE'
ORDER BY column_id;

SET SERVEROUTPUT ON;

-- A) Insert a valid schedule (far future so no overlap)
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

-- Verify
SELECT schedule_id, bus_id, departure_time, arrival_time, platform_no, status
FROM Schedule
WHERE schedule_id = (SELECT MAX(schedule_id) FROM Schedule);

-- B) Overlap attempt for same bus (should raise ORA-20003)
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

-- C) Boundary touching (should succeed)
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
    p_departure_time      => v_arr,           -- exact touch
    p_arrival_time        => v_arr + 2/24,
    p_base_price          => 22.00,
    p_origin_station      => 'ChainA',
    p_destination_station => 'ChainB',
    p_platform_no         => 'P02',
    o_schedule_id         => v_new_id
  );
END;
/

-- D) Cancel (watch STATUS flip)
DECLARE
  v_sched_id Schedule.schedule_id%TYPE;
BEGIN
  SELECT MAX(schedule_id)
  INTO   v_sched_id
  FROM   Schedule;

  schedule_cancel_trip(p_schedule_id => v_sched_id);
END;
/
-- OR
BEGIN
  schedule_cancel_trip(p_schedule_id => 123);
END;
/

SELECT schedule_id, status
FROM Schedule
WHERE schedule_id = 123;
