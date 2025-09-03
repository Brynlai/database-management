-- =========================================================================
-- Trigger 1:  Update Ticket Status on Refund (trg_update_ticket_on_refund)
-- =========================================================================

SET SERVEROUTPUT ON;

CREATE OR REPLACE TRIGGER trg_update_ticket_on_refund
AFTER INSERT ON Refund
FOR EACH ROW
BEGIN
    UPDATE Ticket
    SET status = 'Cancelled'
    WHERE ticket_id = :NEW.ticket_id;

    —- To see the trigger is working
    DBMS_OUTPUT.PUT_LINE('--- Trigger Fired: trg_update_ticket_on_refund ---');
    DBMS_OUTPUT.PUT_LINE('Trigger Fired: Ticket ID ' || :NEW.ticket_id || ' status automatically updated to Cancelled.');
END;
/

COMMIT;


-- ======================================================================================
-- Trigger 2:  Validating member’s existence before booking (trg_validate_booking_member)
-- ======================================================================================

SET SERVEROUTPUT ON;

CREATE OR REPLACE TRIGGER trg_validate_booking_member
    BEFORE INSERT ON Booking
    FOR EACH ROW
DECLARE
    v_member_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_member_count
    FROM Member
    WHERE member_id = :NEW.member_id;

    IF v_member_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Booking Rejected: Member with ID ' || :NEW.member_id || ' does not exist.');
    END IF;
END trg_validate_booking_member;
/

COMMIT;



