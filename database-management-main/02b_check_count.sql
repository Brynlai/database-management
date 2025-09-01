--=============================================================================
-- File: 02b_verify_row_counts.sql
--=============================================================================
-- Purpose: Dynamically queries all tables in the current schema to provide
--          an accurate, live count of rows in each table. This script
--          categorizes tables to reflect the database architecture.
--=============================================================================

SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
    v_row_count NUMBER;

    -- A helper procedure to reduce code duplication
    PROCEDURE print_table_count(p_table_name IN VARCHAR2) IS
        l_count NUMBER;
    BEGIN
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_table_name INTO l_count;
        DBMS_OUTPUT.PUT_LINE(RPAD(p_table_name, 30) || TO_CHAR(l_count, '999,999,990'));
    END print_table_count;

BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 55, '='));
    DBMS_OUTPUT.PUT_LINE('Live Table Row Count Verification (Categorized)');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 55, '='));
    DBMS_OUTPUT.PUT_LINE(RPAD('Table Name', 30) || 'Row Count');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 55, '-'));

    --
    -- === Section 1: Base (Parent) Tables ===
    -- These are the foundational entities of the system.
    --
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Base (Parent) Tables (Req: >10) ---');
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
                'CAMPAIGN', 'COMPANY', 'DRIVER', 'MEMBER', 'PAYMENT', 
                'SERVICE', 'SHOP', 'STAFF', 'BUS'
              ) ORDER BY table_name) 
    LOOP
        print_table_count(t.table_name);
    END LOOP;

    --
    -- === Section 2: Transaction (Child) Tables ===
    -- These tables record business events and depend on base tables.
    --
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Transaction (Child) Tables (Req: >100) ---');
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
                'BOOKING', 'EXTENSION', 'PROMOTION', 'REFUND', 'RENTALCOLLECTION', 
                'SCHEDULE', 'SERVICEDETAILS', 'TICKET'
              ) ORDER BY table_name) 
    LOOP
        print_table_count(t.table_name);
    END LOOP;

    --
    -- === Section 3: Associative (Bridge) Tables ===
    -- These tables exist to resolve many-to-many relationships.
    --
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Associative (Bridge) Tables (Req: >300) ---');
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
                'BOOKINGDETAILS', 'DRIVERLIST', 'STAFFALLOCATION'
              ) ORDER BY table_name)
    LOOP
        print_table_count(t.table_name);
    END LOOP;


    DBMS_OUTPUT.PUT_LINE(RPAD('=', 55, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred during row count verification: ' || SQLERRM);
END;
/