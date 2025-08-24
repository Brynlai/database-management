--=============================================================================
-- File: 05_triggers.sql
--=============================================================================
-- Purpose: Implements database triggers to enforce system-wide business rules
--          and maintain data integrity automatically.
--=============================================================================

SET SERVEROUTPUT ON;

--=============================================================================
-- Section 1: Audit Triggers
--=============================================================================

PROMPT Creating sequence and table for audit logs...

CREATE SEQUENCE staff_audit_log_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE Staff_Audit_Log (
    log_id          NUMBER(10) NOT NULL,
    staff_id        NUMBER(10) NOT NULL,
    changed_by      VARCHAR2(50) NOT NULL,
    change_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    old_role        VARCHAR2(50),
    new_role        VARCHAR2(50),
    old_status      VARCHAR2(20),
    new_status      VARCHAR2(20),
    action_type     VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_staff_audit_log PRIMARY KEY (log_id)
);

COMMENT ON TABLE Staff_Audit_Log IS 'Logs changes to the role or status of records in the Staff table.';


PROMPT Creating Trigger: trg_audit_staff_changes
CREATE OR REPLACE TRIGGER trg_audit_staff_changes
AFTER UPDATE OF role, status ON Staff
FOR EACH ROW
BEGIN
    -- This trigger fires only when the 'role' or 'status' columns are updated.
    -- We check if the value has actually changed before logging.
    IF :OLD.role <> :NEW.role OR :OLD.status <> :NEW.status THEN
        INSERT INTO Staff_Audit_Log (
            log_id,
            staff_id,
            changed_by,
            old_role,
            new_role,
            old_status,
            new_status,
            action_type
        )
        VALUES (
            staff_audit_log_seq.NEXTVAL,
            :OLD.staff_id, -- Use :OLD.staff_id as the primary key cannot be changed
            USER,         -- The Oracle system function to get the current database user
            :OLD.role,
            :NEW.role,
            :OLD.status,
            :NEW.status,
            'UPDATE'
        );
    END IF;
END;
/




-- Appending to 05_triggers.sql

--=============================================================================
-- Section 2: Data Integrity Triggers (Your Tasks)
--=============================================================================

PROMPT Creating Trigger: trg_prevent_company_deletion
CREATE OR REPLACE TRIGGER trg_prevent_company_deletion
BEFORE DELETE ON Company
FOR EACH ROW
DECLARE
    v_bus_count NUMBER;
BEGIN
    -- This trigger fires once for each company row being deleted.
    -- We need to check if this specific company (:OLD.company_id) has any buses.
    
    SELECT COUNT(*)
    INTO v_bus_count
    FROM Bus
    WHERE company_id = :OLD.company_id; -- :OLD refers to the company being deleted.

    -- If the count of buses is greater than zero, we must block the deletion.
    IF v_bus_count > 0 THEN
        -- Raising an application error stops the DELETE statement immediately
        -- and rolls back the transaction.
        RAISE_APPLICATION_ERROR(
            -20020, 
            'Cannot delete company ''' || :OLD.name || ''' (ID: ' || :OLD.company_id || '). ' ||
            'It currently owns ' || v_bus_count || ' bus(es). Please reassign buses first.'
        );
    END IF;
END;
/


