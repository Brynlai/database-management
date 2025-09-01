--=============================================================================
-- File: 05_triggers.sql
--=============================================================================
-- Purpose: Implements database triggers to enforce system-wide business rules
--          and maintain data integrity automatically.
--=============================================================================

SET SERVEROUTPUT ON;
-- The Staff_Audit_Log table and its sequence are created in 01_create_tables.sql

--=============================================================================
-- Trigger 1: Staff Change Auditing (Operational Level)  (Module 6)
--=============================================================================
-- Purpose: Creates a permanent audit record of any changes to a staff member's
--          role or status for security and accountability.

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
















--=============================================================================
-- Trigger 2: Prevent Orphaned Bus Records (Data Integrity) (Module 6)
--=============================================================================
-- Purpose: Protects data integrity by blocking the deletion of any bus company
--          that still owns active buses in the system.

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


