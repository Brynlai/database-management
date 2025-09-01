--=============================================================================
-- File: 05_triggers.sql
--=============================================================================
-- Purpose: Implements database triggers to enforce system-wide business rules
--          and maintain data integrity automatically.
--=============================================================================

SET SERVEROUTPUT ON;
-- The Staff_Audit_Log table and its sequence are created in 01_create_tables.sql

--=============================================================================
-- Trigger 1: Prevent Inactive Staff Assignment (Data Integrity)
--=============================================================================
-- Purpose: Ensures that only staff with an 'Active' status can be assigned to
--          new tasks in either StaffAllocation or RentalCollection. This
--          prevents operational failures and maintains data integrity.

CREATE OR REPLACE TRIGGER trg_prevent_inactive_assign
BEFORE INSERT OR UPDATE ON StaffAllocation
FOR EACH ROW
DECLARE
    v_staff_status Staff.status%TYPE;
BEGIN
    -- Look up the status of the staff member being assigned.
    SELECT status
    INTO v_staff_status
    FROM Staff
    WHERE staff_id = :NEW.staff_id;

    -- If the staff member is not active, block the transaction.
    IF v_staff_status != 'Active' THEN
        RAISE_APPLICATION_ERROR(
            -20025,
            'Assignment Failed: Staff member ' || :NEW.staff_id ||
            ' cannot be assigned to a task because their status is ''' || v_staff_status || '''.'
        );
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- This handles the case where a non-existent staff_id is used.
        RAISE_APPLICATION_ERROR(-20026, 'Assignment Failed: Staff member with ID ' || :NEW.staff_id || ' does not exist.');
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


