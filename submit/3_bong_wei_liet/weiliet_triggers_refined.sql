-- ==========================================================
-- Function: check_bus_overlap
-- Purpose : Return 1 if overlap exists for given bus/time range, else 0
-- ==========================================================
CREATE OR REPLACE FUNCTION check_bus_overlap (
    p_bus_id         IN Schedule.bus_id%TYPE,
    p_departure_time IN Schedule.departure_time%TYPE,
    p_arrival_time   IN Schedule.arrival_time%TYPE,
    p_schedule_id    IN Schedule.schedule_id%TYPE DEFAULT NULL
) RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
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
-- Trigger : trg_schedule_no_overlap
-- Timing  : BEFORE INSERT OR UPDATE OF departure_time, arrival_time, bus_id
-- Table   : Schedule
-- Purpose : Prevent overlapping schedules for the same bus
-- Notes   : Boundary touching allowed; uses check_bus_overlap()
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_schedule_no_overlap
BEFORE INSERT OR UPDATE OF departure_time, arrival_time, bus_id
ON Schedule
FOR EACH ROW
BEGIN
    IF :NEW.status <> 'Cancelled' THEN
        IF check_bus_overlap(:NEW.bus_id, :NEW.departure_time, :NEW.arrival_time, :NEW.schedule_id) = 1 THEN
            RAISE_APPLICATION_ERROR(-20021,
                'Conflict: Overlapping schedule exists for bus ' || :NEW.bus_id);
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20022,
            'Unexpected error in trg_schedule_no_overlap: ' || SQLERRM);
END;
/

-- ==========================================================
-- Trigger : trg_schedule_cancel_ticket_cascade
-- Timing  : AFTER UPDATE OF status
-- Table   : Schedule
-- Purpose : Cascade ticket cancellations when schedule is cancelled
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_sche_cancel_ticket_cascade
AFTER UPDATE OF status
ON Schedule
FOR EACH ROW
BEGIN
    IF :NEW.status = 'Cancelled' AND :OLD.status <> 'Cancelled' THEN
        UPDATE Ticket
        SET    status = 'Cancelled'
        WHERE  schedule_id = :NEW.schedule_id;

        DBMS_OUTPUT.PUT_LINE('Tickets cascaded to Cancelled for schedule '||:NEW.schedule_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20023,
            'Unexpected error in trg_schedule_cancel_ticket_cascade: ' || SQLERRM);
END;
/
-- ===== Display settings (clean output) =====
SET SERVEROUTPUT ON
SET LINESIZE 140
SET PAGESIZE 100
COLUMN dep_time FORMAT A20
COLUMN arr_time FORMAT A20

PROMPT =========================================================
PROMPT = Sanity: show a few schedules
PROMPT =========================================================
SELECT bus_id, schedule_id,
       TO_CHAR(departure_time,'DD-MON-YYYY HH24:MI') dep_time,
       TO_CHAR(arrival_time,'DD-MON-YYYY HH24:MI')   arr_time,
       status
FROM   Schedule
WHERE  ROWNUM <= 3;

PROMPT =========================================================
PROMPT = Overlap test
PROMPT =========================================================
DECLARE
  v_bus_id NUMBER := 94;
  v_dep    DATE;
  v_arr    DATE;
  v_new_id NUMBER;
BEGIN
  SELECT departure_time, arrival_time
  INTO   v_dep, v_arr
  FROM (
    SELECT departure_time, arrival_time
    FROM   Schedule
    WHERE  bus_id = v_bus_id
    AND    status <> 'Cancelled'
    ORDER  BY arrival_time DESC
  )
  WHERE ROWNUM = 1;

  DBMS_OUTPUT.PUT_LINE('Trying overlap within anchor window:');
  DBMS_OUTPUT.PUT_LINE('NEW_DEP='||TO_CHAR(v_dep + (10/1440),'DD-MON-YYYY HH24:MI')||
                       ' NEW_ARR='||TO_CHAR(v_dep + (20/1440),'DD-MON-YYYY HH24:MI'));

  INSERT INTO Schedule (
    schedule_id, departure_time, arrival_time,
    base_price, origin_station, destination_station, platform_no, bus_id, status
  ) VALUES (
    schedule_seq.NEXTVAL,
    v_dep + (10/1440),               -- +10 minutes
    v_dep + (20/1440),               -- +20 minutes
    25, 'KL', 'Melaka', 'P1', v_bus_id, 'Active'
  );
END;
/

--  SELECT bus_id, departure_time, arrival_time, status
--  FROM   (SELECT bus_id, departure_time, arrival_time, status
--        FROM   Schedule
--        WHERE  bus_id = 94);
--  
--  INSERT INTO Schedule (
--      schedule_id, departure_time, arrival_time,
--      base_price, origin_station, destination_station,
--      platform_no, bus_id, status
--  ) VALUES (
--      schedule_seq.NEXTVAL,
--      TO_DATE('2024-12-31 19:46','YYYY-MM-DD HH24:MI'),
--      TO_DATE('2025-01-01 02:23','YYYY-MM-DD HH24:MI'),
--      25, 'KL', 'Melaka', '1', 94, 'Active'
--  );
--/


-- Expect: ORA-20021 Conflict error from BEFORE trigger

PROMPT =========================================================
PROMPT = Boundary-touching test
PROMPT =========================================================
DECLARE
  v_bus_id NUMBER := 94;
  v_dep    DATE;
  v_arr    DATE;
BEGIN
  SELECT departure_time, arrival_time
  INTO   v_dep, v_arr
  FROM (
    SELECT departure_time, arrival_time
    FROM   Schedule
    WHERE  bus_id = v_bus_id
    AND    status <> 'Cancelled'
    ORDER  BY arrival_time DESC
  )
  WHERE ROWNUM = 1;

  DBMS_OUTPUT.PUT_LINE('Boundary insert at anchor ARR:');
  DBMS_OUTPUT.PUT_LINE('NEW_DEP='||TO_CHAR(v_arr,'DD-MON-YYYY HH24:MI')||
                       ' NEW_ARR='||TO_CHAR(v_arr + (120/1440),'DD-MON-YYYY HH24:MI'));

  INSERT INTO Schedule (
    schedule_id, departure_time, arrival_time,
    base_price, origin_station, destination_station, platform_no, bus_id, status
  ) VALUES (
    schedule_seq.NEXTVAL,
    v_arr,                            -- exact boundary touch
    v_arr + (120/1440),               -- +120 minutes
    30, 'KL', 'Seremban', 'P2', v_bus_id, 'Active'
  );

  DBMS_OUTPUT.PUT_LINE('Boundary-touching insert Successed.');
  COMMIT;
END;
/
--SELECT bus_id, departure_time, arrival_time, status
--FROM   (SELECT bus_id, departure_time, arrival_time, status
--        FROM   Schedule
--        WHERE  bus_id = 94);
--
--INSERT INTO Schedule (
--  schedule_id, departure_time, arrival_time,
--  base_price, origin_station, destination_station,
--  platform_no, bus_id, status
--) VALUES (
--  schedule_seq.NEXTVAL,
--  (SELECT MAX(arrival_time) FROM Schedule WHERE bus_id=94),
--  (SELECT MAX(arrival_time) FROM Schedule WHERE bus_id=94) + INTERVAL '2' HOUR,
--  30, 'KL', 'Seremban', '2', 94, 'Active'
--);
--/

PROMPT =========================================================
PROMPT = Cascade test (update one schedule to Cancelled)
PROMPT =========================================================
SET SERVEROUTPUT ON

DECLARE
  v_sched Schedule.schedule_id%TYPE;
BEGIN
  SELECT schedule_id
  INTO   v_sched
  FROM   Schedule
  WHERE  schedule_id = 240;  

  UPDATE Schedule
  SET    status = 'Cancelled'
  WHERE  schedule_id = v_sched;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Cancelled schedule '||v_sched||' tickets should be cascaded.');

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Schedule '||v_sched||' not found.');
END;
/

-- verify cascade
SELECT ticket_id, status
FROM   Ticket
WHERE  schedule_id = 240
;

PROMPT =========================================================
PROMPT = Cancel ticket follows by schedule 
PROMPT =========================================================
-- Find a schedule with tickets (Oracle 11g style)
SELECT *
FROM (
  SELECT s.schedule_id, COUNT(t.ticket_id) AS num_tickets, s.status
  FROM Schedule s
  JOIN Ticket t ON s.schedule_id = t.schedule_id
  GROUP BY s.schedule_id, s.status
  HAVING COUNT(t.ticket_id) > 0
) WHERE ROWNUM = 1;

-- assume schedule_id = 240
UPDATE Schedule
SET status = 'Cancelled'
WHERE schedule_id = 240;
COMMIT;

-- Verify tickets updated
SELECT ticket_id, status
FROM Ticket
WHERE schedule_id = 240;
