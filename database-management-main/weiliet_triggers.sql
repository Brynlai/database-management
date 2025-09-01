-- ==========================================================
-- Trigger: trg_schedule_no_overlap
-- Purpose: Prevent overlapping schedules for the same bus
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_schedule_no_overlap
BEFORE INSERT OR UPDATE OF departure_time, arrival_time, bus_id
ON Schedule
FOR EACH ROW
DECLARE
    v_conflict NUMBER;
BEGIN
    -- Only check if status is not Cancelled
    IF :NEW.status <> 'Cancelled' THEN
        SELECT COUNT(*) INTO v_conflict
        FROM Schedule s
        WHERE s.bus_id = :NEW.bus_id
          AND s.status <> 'Cancelled'
          AND s.schedule_id <> NVL(:NEW.schedule_id, -1)
          AND :NEW.departure_time < s.arrival_time
          AND :NEW.arrival_time   > s.departure_time;

        IF v_conflict > 0 THEN
            RAISE_APPLICATION_ERROR(-20021, 'Conflict: Overlapping schedule exists for bus ' || :NEW.bus_id);
        END IF;
    END IF;
END;
/

-- ==========================================================
-- Trigger: trg_schedule_cancel_ticket_cascade
-- Purpose: Cascade ticket cancellations when schedule is cancelled
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_schedule_cancel_ticket_cascade
AFTER UPDATE OF status
ON Schedule
FOR EACH ROW
BEGIN
    IF :NEW.status = 'Cancelled' AND :OLD.status <> 'Cancelled' THEN
        UPDATE Ticket
        SET status = 'Cancelled'
        WHERE schedule_id = :NEW.schedule_id;

        DBMS_OUTPUT.PUT_LINE('All tickets for schedule '||:NEW.schedule_id||' set to Cancelled.');
    END IF;
END;
/

-- Step 1: Pick an existing bus and schedule times
SELECT bus_id, schedule_id, departure_time, arrival_time
FROM Schedule
WHERE ROWNUM <= 3;

-- Step 2: Try to insert an overlapping schedule (should FAIL)
INSERT INTO Schedule (
    schedule_id, departure_time, arrival_time,
    base_price, origin_station, destination_station,
    platform_no, bus_id, status
) VALUES (
    schedule_seq.NEXTVAL,
    TO_DATE('2024-12-31 19:46','YYYY-MM-DD HH24:MI'),
    TO_DATE('2025-01-01 02:23','YYYY-MM-DD HH24:MI'),
    25, 'KL', 'Melaka', '1', '94', 'Active'
);
-- Expect: ORA-20021 Conflict error

-- Departure = existing arrival (boundary touching, allowed)
INSERT INTO Schedule (
    schedule_id, departure_time, arrival_time,
    base_price, origin_station, destination_station,
    platform_no, bus_id, status
) VALUES (
    schedule_seq.NEXTVAL,
    (SELECT MAX(arrival_time) FROM Schedule WHERE bus_id='94'),
    (SELECT MAX(arrival_time) FROM Schedule WHERE bus_id='94') + INTERVAL '2' HOUR,
    30, 'KL', 'Seremban', '2', '94', 'Active'
);
-- Should succeed

-- Test Cascade Ticket Cancellation
-- Step 1: Find a schedule with tickets
SELECT s.schedule_id, COUNT(t.ticket_id) AS num_tickets, s.status
FROM Schedule s
JOIN Ticket t ON s.schedule_id = t.schedule_id
GROUP BY s.schedule_id, s.status
HAVING COUNT(t.ticket_id) > 0
FETCH FIRST 1 ROWS ONLY;

-- assume schedule_id = 101

-- Step 2: Cancel that schedule
UPDATE Schedule
SET status = 'Cancelled'
WHERE schedule_id = 101;

COMMIT;

-- Step 3: Check tickets are updated
SELECT ticket_id, status
FROM Ticket
WHERE schedule_id = 101;
-- Expect: all rows show 'Cancelled'
