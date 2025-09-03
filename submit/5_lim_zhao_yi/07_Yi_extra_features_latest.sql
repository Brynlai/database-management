-- =============================================================================
-- COMPLETE ORACLE XE 11.2 INDEX MANAGEMENT SOLUTION - FINAL VERSION
-- Purpose: Resolve all ORA-00955, ORA-01408, ORA-00904 errors
-- Features: Professional formatting, comprehensive index coverage, safe operations
-- Compatible with: Oracle Express Edition 11.2
-- Version: Final Production Release
-- =============================================================================

-- Optimal settings for Oracle XE 11.2
SET SERVEROUTPUT ON SIZE 1000000;
SET PAGESIZE 100;
SET LINESIZE 150;
SET VERIFY OFF;
SET FEEDBACK OFF;
SET HEADING ON;
SET ECHO OFF;
SET TIMING OFF;

-- Professional column formatting for readable output
COLUMN TABLE_NAME FORMAT A25 HEADING 'Table Name'
COLUMN INDEX_NAME FORMAT A35 HEADING 'Index Name'
COLUMN COLUMN_NAME FORMAT A25 HEADING 'Column Name'
COLUMN CONSTRAINT_NAME FORMAT A30 HEADING 'Constraint Name'
COLUMN NUM_ROWS FORMAT 999,999,999 HEADING 'Row Count'
COLUMN INDEX_COUNT FORMAT 999 HEADING 'Indexes'
COLUMN UNIQUENESS FORMAT A10 HEADING 'Unique'
COLUMN STATUS FORMAT A12 HEADING 'Status'
COLUMN INDEX_STATUS FORMAT A15 HEADING 'Index Status'
COLUMN INDEX_ASSESSMENT FORMAT A15 HEADING 'Assessment'
COLUMN COLUMN_LIST FORMAT A40 HEADING 'Column List'
COLUMN METRIC FORMAT A30 HEADING 'Metric'
COLUMN VALUE FORMAT 999,999 HEADING 'Count'
COLUMN DUP_COUNT FORMAT 999 HEADING 'Duplicates'
COLUMN HEALTH_STATUS FORMAT A12 HEADING 'Health'
COLUMN SIZE_CATEGORY FORMAT A12 HEADING 'Size'
COLUMN DESCRIPTION FORMAT A25 HEADING 'Description'

-- =============================================================================
-- UTILITY PROCEDURES FOR ENHANCED FORMATTING
-- =============================================================================

-- Create formatted section headers
CREATE OR REPLACE PROCEDURE PRINT_SECTION_HEADER(p_title VARCHAR2, p_width NUMBER DEFAULT 80) AS
    v_padding NUMBER;
    v_left_pad NUMBER;
    v_right_pad NUMBER;
BEGIN
    v_padding := p_width - LENGTH(p_title) - 2;
    v_left_pad := FLOOR(v_padding / 2);
    v_right_pad := CEIL(v_padding / 2);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', p_width, '='));
    DBMS_OUTPUT.PUT_LINE('|' || RPAD(' ', v_left_pad) || p_title || RPAD(' ', v_right_pad) || '|');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', p_width, '='));
    DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Create professional box headers
CREATE OR REPLACE PROCEDURE PRINT_BOX_HEADER(p_title VARCHAR2) AS
    v_title_length NUMBER;
    v_total_width NUMBER := 77;
    v_padding NUMBER;
    v_left_pad NUMBER;
    v_right_pad NUMBER;
BEGIN
    v_title_length := LENGTH(p_title);
    v_padding := v_total_width - v_title_length - 2;
    v_left_pad := FLOOR(v_padding / 2);
    v_right_pad := CEIL(v_padding / 2);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-' || RPAD('-', v_total_width, '-') || '|');
    DBMS_OUTPUT.PUT_LINE('|' || RPAD(' ', v_left_pad) || p_title || RPAD(' ', v_right_pad) || '|');
    DBMS_OUTPUT.PUT_LINE('-' || RPAD('-', v_total_width, '-') || '-');
    DBMS_OUTPUT.PUT_LINE('');
END;
/

-- =============================================================================
-- ADVANCED SAFE INDEX MANAGEMENT PROCEDURES
-- =============================================================================

-- Ultimate safe index creation procedure for Oracle XE 11.2
CREATE OR REPLACE PROCEDURE SAFE_CREATE_INDEX_XE112 (
    p_index_name IN VARCHAR2,
    p_table_name IN VARCHAR2,
    p_column_list IN VARCHAR2,
    p_show_details IN VARCHAR2 DEFAULT 'Y'
) AS
    v_index_exists NUMBER := 0;
    v_table_exists NUMBER := 0;
    v_columns_exist NUMBER := 0;
    v_already_indexed NUMBER := 0;
    v_sql VARCHAR2(4000);
    v_first_column VARCHAR2(128);
    v_total_columns NUMBER := 0;
    v_column_name VARCHAR2(128);
    v_pos NUMBER := 1;
    v_comma_pos NUMBER;
    v_status VARCHAR2(20);
    v_index_name_formatted VARCHAR2(40);
    v_table_name_formatted VARCHAR2(25);
BEGIN
    v_index_name_formatted := RPAD(p_index_name, 35);
    v_table_name_formatted := RPAD(p_table_name, 20);
    
    -- Check if table exists
    SELECT COUNT(*) INTO v_table_exists
    FROM USER_TABLES 
    WHERE TABLE_NAME = UPPER(p_table_name);
    
    IF v_table_exists = 0 THEN
        v_status := 'TABLE NOT FOUND';
        IF p_show_details = 'Y' THEN
            DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 15) || ' | ' || v_index_name_formatted || ' | ' || v_table_name_formatted);
        END IF;
        RETURN;
    END IF;
    
    -- Check if index already exists
    SELECT COUNT(*) INTO v_index_exists
    FROM USER_INDEXES
    WHERE INDEX_NAME = UPPER(p_index_name);
    
    IF v_index_exists > 0 THEN
        v_status := 'ALREADY EXISTS';
        IF p_show_details = 'Y' THEN
            DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 15) || ' | ' || v_index_name_formatted || ' | ' || v_table_name_formatted);
        END IF;
        RETURN;
    END IF;
    
    -- Count total columns in the column list
    v_total_columns := LENGTH(p_column_list) - LENGTH(REPLACE(p_column_list, ',', '')) + 1;
    
    -- Validate all columns exist in the table
    v_pos := 1;
    FOR i IN 1..v_total_columns LOOP
        IF i = v_total_columns THEN
            v_column_name := TRIM(SUBSTR(p_column_list, v_pos));
        ELSE
            v_comma_pos := INSTR(p_column_list, ',', v_pos);
            v_column_name := TRIM(SUBSTR(p_column_list, v_pos, v_comma_pos - v_pos));
            v_pos := v_comma_pos + 1;
        END IF;
        
        SELECT COUNT(*) INTO v_columns_exist
        FROM USER_TAB_COLUMNS
        WHERE TABLE_NAME = UPPER(p_table_name)
        AND COLUMN_NAME = UPPER(v_column_name);
        
        IF v_columns_exist = 0 THEN
            v_status := 'COLUMN NOT FOUND';
            IF p_show_details = 'Y' THEN
                DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 15) || ' | ' || v_index_name_formatted || ' | Column: ' || v_column_name);
            END IF;
            RETURN;
        END IF;
    END LOOP;
    
    -- Get first column for duplicate check
    IF INSTR(p_column_list, ',') > 0 THEN
        v_first_column := TRIM(SUBSTR(p_column_list, 1, INSTR(p_column_list, ',') - 1));
    ELSE
        v_first_column := TRIM(p_column_list);
    END IF;
    
    -- Check for existing index on the same column(s)
    SELECT COUNT(*) INTO v_already_indexed
    FROM USER_IND_COLUMNS uic
    WHERE uic.TABLE_NAME = UPPER(p_table_name)
    AND uic.COLUMN_NAME = UPPER(v_first_column)
    AND uic.COLUMN_POSITION = 1;
    
    IF v_already_indexed > 0 THEN
        v_status := 'COLUMN INDEXED';
        IF p_show_details = 'Y' THEN
            DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 15) || ' | ' || v_index_name_formatted || ' | ' || v_table_name_formatted || ' | ' || v_first_column);
        END IF;
        RETURN;
    END IF;
    
    -- Create the index
    BEGIN
        v_sql := 'CREATE INDEX ' || UPPER(p_index_name) || ' ON ' || UPPER(p_table_name) || '(' || p_column_list || ')';
        EXECUTE IMMEDIATE v_sql;
        v_status := 'CREATED';
        IF p_show_details = 'Y' THEN
            DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 15) || ' | ' || v_index_name_formatted || ' | ' || v_table_name_formatted || ' | ' || p_column_list);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -955 THEN
                v_status := 'NAME EXISTS';
            ELSIF SQLCODE = -1408 THEN
                v_status := 'ALREADY INDEXED';
            ELSE
                v_status := 'ERROR';
            END IF;
            IF p_show_details = 'Y' THEN
                DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 15) || ' | ' || v_index_name_formatted || ' | ' || SQLERRM);
            END IF;
    END;
END;
/

-- Safe drop procedure with enhanced error handling
CREATE OR REPLACE PROCEDURE SAFE_DROP_INDEX_XE112 (
    p_index_name IN VARCHAR2,
    p_show_details IN VARCHAR2 DEFAULT 'Y'
) AS
    v_index_exists NUMBER := 0;
    v_constraint_name VARCHAR2(128);
    v_sql VARCHAR2(1000);
    v_status VARCHAR2(25);
    v_index_name_formatted VARCHAR2(40);
BEGIN
    v_index_name_formatted := RPAD(p_index_name, 35);
    
    -- Check if index exists
    SELECT COUNT(*) INTO v_index_exists
    FROM USER_INDEXES
    WHERE INDEX_NAME = UPPER(p_index_name);
    
    IF v_index_exists = 0 THEN
        v_status := 'NOT EXISTS';
        IF p_show_details = 'Y' THEN
            DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 20) || ' | ' || v_index_name_formatted);
        END IF;
        RETURN;
    END IF;
    
    -- Check if index supports a constraint
    BEGIN
        SELECT CONSTRAINT_NAME INTO v_constraint_name
        FROM USER_CONSTRAINTS 
        WHERE INDEX_NAME = UPPER(p_index_name)
        AND ROWNUM = 1;
        
        v_status := 'CONSTRAINT PROTECTED';
        IF p_show_details = 'Y' THEN
            DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 20) || ' | ' || v_index_name_formatted || ' | ' || v_constraint_name);
        END IF;
        RETURN;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Safe to drop
            BEGIN
                v_sql := 'DROP INDEX ' || UPPER(p_index_name);
                EXECUTE IMMEDIATE v_sql;
                v_status := 'DROPPED';
                IF p_show_details = 'Y' THEN
                    DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 20) || ' | ' || v_index_name_formatted);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    v_status := 'ERROR';
                    IF p_show_details = 'Y' THEN
                        DBMS_OUTPUT.PUT_LINE(' ' || RPAD(v_status, 20) || ' | ' || v_index_name_formatted || ' | ' || SQLERRM);
                    END IF;
            END;
    END;
END;
/

-- Recreate index procedure
CREATE OR REPLACE PROCEDURE RECREATE_INDEX_XE112 (
    p_index_name IN VARCHAR2,
    p_table_name IN VARCHAR2,
    p_column_list IN VARCHAR2
) AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' RECREATING INDEX: ' || p_index_name);
    DBMS_OUTPUT.PUT_LINE('   ' || RPAD('-', 70, '-'));
    SAFE_DROP_INDEX_XE112(p_index_name);
    SAFE_CREATE_INDEX_XE112(p_index_name, p_table_name, p_column_list);
    DBMS_OUTPUT.PUT_LINE('   ' || RPAD('-', 70, '-'));
    DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Analysis procedure for comprehensive database assessment
CREATE OR REPLACE PROCEDURE ANALYZE_DATABASE_XE112 AS
    v_total_tables NUMBER;
    v_total_indexes NUMBER;
    v_performance_indexes NUMBER;
    v_tables_with_indexes NUMBER;
BEGIN
    -- Get summary statistics
    SELECT COUNT(*) INTO v_total_tables FROM USER_TABLES;
    SELECT COUNT(*) INTO v_total_indexes FROM USER_INDEXES;
    SELECT COUNT(*) INTO v_performance_indexes FROM USER_INDEXES WHERE INDEX_NAME LIKE 'IDX_%';
    SELECT COUNT(DISTINCT TABLE_NAME) INTO v_tables_with_indexes FROM USER_INDEXES;
    
    PRINT_BOX_HEADER('DATABASE ANALYSIS SUMMARY');
    
    DBMS_OUTPUT.PUT_LINE(' Total Tables in Schema: ' || LPAD(v_total_tables, 8));
    DBMS_OUTPUT.PUT_LINE(' Total Indexes Created: ' || LPAD(v_total_indexes, 8));
    DBMS_OUTPUT.PUT_LINE(' Performance Indexes: ' || LPAD(v_performance_indexes, 8));
    DBMS_OUTPUT.PUT_LINE('  Tables with Indexes: ' || LPAD(v_tables_with_indexes, 8));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' Index Coverage: ' || ROUND((v_tables_with_indexes / v_total_tables) * 100, 1) || '%');
    DBMS_OUTPUT.PUT_LINE(' Performance Ratio: ' || ROUND((v_performance_indexes / v_total_indexes) * 100, 1) || '%');
END;
/

-- =============================================================================
-- MAIN EXECUTION: COMPREHENSIVE INDEX MANAGEMENT
-- =============================================================================



-- =============================================================================
-- STEP 1: DATABASE ANALYSIS
-- =============================================================================

BEGIN
    PRINT_SECTION_HEADER('CURRENT DATABASE STATE ANALYSIS');
END;
/

BEGIN
    PRINT_BOX_HEADER('CURRENT TABLES IN SCHEMA');
END;
/

SELECT 
    RPAD(TABLE_NAME, 25) AS TABLE_NAME,
    LPAD(TO_CHAR(NVL(NUM_ROWS, 0), '999,999,999'), 12) AS NUM_ROWS,
    CASE 
        WHEN NVL(NUM_ROWS, 0) = 0 THEN ' Empty'
        WHEN NVL(NUM_ROWS, 0) < 1000 THEN ' Small'
        WHEN NVL(NUM_ROWS, 0) < 10000 THEN ' Medium'
        ELSE '  Large'
    END AS SIZE_CATEGORY
FROM USER_TABLES 
ORDER BY NVL(NUM_ROWS, 0) DESC, TABLE_NAME;

BEGIN
    PRINT_BOX_HEADER('CURRENT INDEXES IN SCHEMA');
END;
/

SELECT 
    RPAD(INDEX_NAME, 35) AS INDEX_NAME,
    RPAD(TABLE_NAME, 20) AS TABLE_NAME,
    RPAD(UNIQUENESS, 10) AS UNIQUENESS,
    RPAD(STATUS, 12) AS STATUS
FROM USER_INDEXES
ORDER BY TABLE_NAME, INDEX_NAME;

-- =============================================================================
-- STEP 2: COMPREHENSIVE INDEX CREATION
-- =============================================================================

BEGIN
    PRINT_SECTION_HEADER('COMPREHENSIVE INDEX CREATION');
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting comprehensive index creation');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Status          | Index Name                          | Table Name           | Columns');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 95, '-'));
    
    -- BOOKING SYSTEM INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' BOOKING SYSTEM INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_BOOKING_MEMBER_ID', 'BOOKING', 'MEMBER_ID');
    SAFE_CREATE_INDEX_XE112('IDX_BOOKING_PAYMENT_ID', 'BOOKING', 'PAYMENT_ID');
    SAFE_CREATE_INDEX_XE112('IDX_BOOKING_DATE', 'BOOKING', 'BOOKING_DATE');
    SAFE_CREATE_INDEX_XE112('IDX_BOOKING_TOTAL_AMOUNT', 'BOOKING', 'TOTAL_AMOUNT');
    SAFE_CREATE_INDEX_XE112('IDX_BOOKING_MEMBER_DATE', 'BOOKING', 'MEMBER_ID, BOOKING_DATE');
    
    -- TICKET SYSTEM INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' TICKET SYSTEM INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_TICKET_SCHEDULE_ID', 'TICKET', 'SCHEDULE_ID');
    SAFE_CREATE_INDEX_XE112('IDX_TICKET_PROMOTION_ID', 'TICKET', 'PROMOTION_ID');
    SAFE_CREATE_INDEX_XE112('IDX_TICKET_STATUS', 'TICKET', 'STATUS');
    SAFE_CREATE_INDEX_XE112('IDX_TICKET_SEAT_NUMBER', 'TICKET', 'SEAT_NUMBER');
    SAFE_CREATE_INDEX_XE112('IDX_TICKET_STATUS_SCHEDULE', 'TICKET', 'STATUS, SCHEDULE_ID');
    
    -- SCHEDULE MANAGEMENT INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' SCHEDULE MANAGEMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_SCHEDULE_BUS_ID', 'SCHEDULE', 'BUS_ID');
    SAFE_CREATE_INDEX_XE112('IDX_SCHEDULE_DEPARTURE', 'SCHEDULE', 'DEPARTURE_TIME');
    SAFE_CREATE_INDEX_XE112('IDX_SCHEDULE_ARRIVAL', 'SCHEDULE', 'ARRIVAL_TIME');
    SAFE_CREATE_INDEX_XE112('IDX_SCHEDULE_ORIGIN', 'SCHEDULE', 'ORIGIN_STATION');
    SAFE_CREATE_INDEX_XE112('IDX_SCHEDULE_DESTINATION', 'SCHEDULE', 'DESTINATION_STATION');
    SAFE_CREATE_INDEX_XE112('IDX_SCHEDULE_PRICE', 'SCHEDULE', 'BASE_PRICE');
    SAFE_CREATE_INDEX_XE112('IDX_SCHEDULE_TIME_RANGE', 'SCHEDULE', 'DEPARTURE_TIME, ARRIVAL_TIME');
    SAFE_CREATE_INDEX_XE112('IDX_SCHEDULE_ROUTE', 'SCHEDULE', 'ORIGIN_STATION, DESTINATION_STATION');
    
    -- BOOKING DETAILS INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' BOOKING DETAILS INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_BOOKINGDETAILS_BOOKING_ID', 'BOOKINGDETAILS', 'BOOKING_ID');
    SAFE_CREATE_INDEX_XE112('IDX_BOOKINGDETAILS_TICKET_ID', 'BOOKINGDETAILS', 'TICKET_ID');
    
    -- STAFF MANAGEMENT INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' STAFF MANAGEMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_STAFF_ROLE', 'STAFF', 'ROLE');
    SAFE_CREATE_INDEX_XE112('IDX_STAFF_STATUS', 'STAFF', 'STATUS');
    SAFE_CREATE_INDEX_XE112('IDX_STAFF_EMPLOYMENT_DATE', 'STAFF', 'EMPLOYMENT_DATE');
    SAFE_CREATE_INDEX_XE112('IDX_STAFF_EMAIL', 'STAFF', 'EMAIL');
    SAFE_CREATE_INDEX_XE112('IDX_STAFF_CONTACT', 'STAFF', 'CONTACT_NO');
    SAFE_CREATE_INDEX_XE112('IDX_STAFF_ROLE_STATUS', 'STAFF', 'ROLE, STATUS');
    
    -- STAFF ALLOCATION INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' STAFF ALLOCATION INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_STAFFALLOCATION_STAFF_ID', 'STAFFALLOCATION', 'STAFF_ID');
    SAFE_CREATE_INDEX_XE112('IDX_STAFFALLOCATION_SERVICE_ID', 'STAFFALLOCATION', 'SERVICE_TRANSACTION_ID');
    SAFE_CREATE_INDEX_XE112('IDX_STAFFALLOCATION_ROLE', 'STAFFALLOCATION', 'ROLE');
    SAFE_CREATE_INDEX_XE112('IDX_STAFFALLOCATION_TIME', 'STAFFALLOCATION', 'START_TIME, END_TIME');
    
    -- SERVICE MANAGEMENT INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' SERVICE MANAGEMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_SERVICE_NAME', 'SERVICE', 'SERVICE_NAME');
    SAFE_CREATE_INDEX_XE112('IDX_SERVICE_COST', 'SERVICE', 'STANDARD_COST');
    
    -- SERVICE DETAILS INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' SERVICE DETAILS INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_SERVICEDETAILS_BUS_ID', 'SERVICEDETAILS', 'BUS_ID');
    SAFE_CREATE_INDEX_XE112('IDX_SERVICEDETAILS_SERVICE_ID', 'SERVICEDETAILS', 'SERVICE_ID');
    SAFE_CREATE_INDEX_XE112('IDX_SERVICEDETAILS_DATE', 'SERVICEDETAILS', 'SERVICE_DATE');
    SAFE_CREATE_INDEX_XE112('IDX_SERVICEDETAILS_COST', 'SERVICEDETAILS', 'ACTUAL_COST');
    SAFE_CREATE_INDEX_XE112('IDX_SERVICEDETAILS_BUS_DATE', 'SERVICEDETAILS', 'BUS_ID, SERVICE_DATE');
    
    -- DRIVER MANAGEMENT INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' DRIVER MANAGEMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_DRIVER_NAME', 'DRIVER', 'NAME');
    SAFE_CREATE_INDEX_XE112('IDX_DRIVER_LICENSE', 'DRIVER', 'LICENSE_NO');
    
    -- DRIVER LIST INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' DRIVER ASSIGNMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_DRIVERLIST_SCHEDULE_ID', 'DRIVERLIST', 'SCHEDULE_ID');
    SAFE_CREATE_INDEX_XE112('IDX_DRIVERLIST_DRIVER_ID', 'DRIVERLIST', 'DRIVER_ID');
    
    -- RENTAL MANAGEMENT INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' RENTAL MANAGEMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_RENTALCOLLECTION_SHOP_ID', 'RENTALCOLLECTION', 'SHOP_ID');
    SAFE_CREATE_INDEX_XE112('IDX_RENTALCOLLECTION_STAFF_ID', 'RENTALCOLLECTION', 'STAFF_ID');
    SAFE_CREATE_INDEX_XE112('IDX_RENTALCOLLECTION_DATE', 'RENTALCOLLECTION', 'RENTAL_DATE');
    SAFE_CREATE_INDEX_XE112('IDX_RENTALCOLLECTION_AMOUNT', 'RENTALCOLLECTION', 'AMOUNT');
    SAFE_CREATE_INDEX_XE112('IDX_RENTALCOLLECTION', 'RENTALCOLLECTION', 'COLLECTION_DATE');
    
    -- PROMOTION SYSTEM INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' PROMOTION SYSTEM INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_PROMOTION_CAMPAIGN_ID', 'PROMOTION', 'CAMPAIGN_ID');
    SAFE_CREATE_INDEX_XE112('IDX_PROMOTION_DATES', 'PROMOTION', 'VALID_FROM, VALID_UNTIL');
    SAFE_CREATE_INDEX_XE112('IDX_PROMOTION_DISCOUNT_TYPE', 'PROMOTION', 'DISCOUNT_TYPE');
    SAFE_CREATE_INDEX_XE112('IDX_PROMOTION_DISCOUNT_VALUE', 'PROMOTION', 'DISCOUNT_VALUE');
    
    -- MEMBER MANAGEMENT INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' MEMBER MANAGEMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_MEMBER_REGISTRATION_DATE', 'MEMBER', 'REGISTRATION_DATE');
    SAFE_CREATE_INDEX_XE112('IDX_MEMBER_EMAIL', 'MEMBER', 'EMAIL');
    SAFE_CREATE_INDEX_XE112('IDX_MEMBER_NAME', 'MEMBER', 'NAME');
    SAFE_CREATE_INDEX_XE112('IDX_MEMBER_CONTACT', 'MEMBER', 'CONTACT_NO');
    
    -- PAYMENT SYSTEM INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' PAYMENT SYSTEM INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_PAYMENT_DATE', 'PAYMENT', 'PAYMENT_DATE');
    SAFE_CREATE_INDEX_XE112('IDX_PAYMENT_METHOD', 'PAYMENT', 'PAYMENT_METHOD');
    SAFE_CREATE_INDEX_XE112('IDX_PAYMENT_AMOUNT', 'PAYMENT', 'AMOUNT');
    
    -- CAMPAIGN MANAGEMENT INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' CAMPAIGN MANAGEMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_CAMPAIGN_DATES', 'CAMPAIGN', 'START_DATE, END_DATE');
    SAFE_CREATE_INDEX_XE112('IDX_CAMPAIGN_NAME', 'CAMPAIGN', 'CAMPAIGN_NAME');
    
    -- BUS FLEET INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' BUS FLEET INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_BUS_COMPANY_ID', 'BUS', 'COMPANY_ID');
    SAFE_CREATE_INDEX_XE112('IDX_BUS_PLATE_NUMBER', 'BUS', 'PLATE_NUMBER');
    SAFE_CREATE_INDEX_XE112('IDX_BUS_CAPACITY', 'BUS', 'CAPACITY');
    
    -- REFUND SYSTEM INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' REFUND SYSTEM INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_REFUND_DATE', 'REFUND', 'REFUND_DATE');
    SAFE_CREATE_INDEX_XE112('IDX_REFUND_TICKET_ID', 'REFUND', 'TICKET_ID');
    SAFE_CREATE_INDEX_XE112('IDX_REFUND_AMOUNT', 'REFUND', 'AMOUNT');
    SAFE_CREATE_INDEX_XE112('IDX_REFUND_METHOD', 'REFUND', 'REFUND_METHOD');
    
    -- EXTENSION SYSTEM INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' EXTENSION SYSTEM INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_EXTENSION_DATE', 'EXTENSION', 'EXTENSION_DATE');
    SAFE_CREATE_INDEX_XE112('IDX_EXTENSION_TICKET_ID', 'EXTENSION', 'TICKET_ID');
    SAFE_CREATE_INDEX_XE112('IDX_EXTENSION_AMOUNT', 'EXTENSION', 'AMOUNT');
    SAFE_CREATE_INDEX_XE112('IDX_EXTENSION_METHOD', 'EXTENSION', 'EXTENSION_METHOD');
    
    -- COMPANY MANAGEMENT INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' COMPANY MANAGEMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_COMPANY_NAME', 'COMPANY', 'NAME');
    
    -- SHOP MANAGEMENT INDEXES
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' SHOP MANAGEMENT INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_SHOP_LOCATION', 'SHOP', 'LOCATION_CODE');
    SAFE_CREATE_INDEX_XE112('IDX_SHOP_NAME', 'SHOP', 'SHOP_NAME');
    
    -- DATA WAREHOUSE INDEXES (if tables exist)
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(' DATA WAREHOUSE INDEXES:');
    SAFE_CREATE_INDEX_XE112('IDX_ENROLLMENT_COURSE_KEY', 'ENROLLMENT_FACT', 'COURSE_KEY');
    SAFE_CREATE_INDEX_XE112('IDX_ENROLLMENT_DATE_KEY', 'ENROLLMENT_FACT', 'DATE_KEY');
    SAFE_CREATE_INDEX_XE112('IDX_ENROLLMENT_STUDENT_KEY', 'ENROLLMENT_FACT', 'STUDENT_KEY');
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 95, '='));
    DBMS_OUTPUT.PUT_LINE(' COMPREHENSIVE INDEX CREATION COMPLETE!');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 95, '='));
    
END;
/

-- =============================================================================
-- STEP 3: INDEX VERIFICATION AND ANALYSIS
-- =============================================================================

BEGIN
    PRINT_SECTION_HEADER('INDEX VERIFICATION AND ANALYSIS');
END;
/

BEGIN
    PRINT_BOX_HEADER('PERFORMANCE INDEXES CREATED');
END;
/

SELECT 
    RPAD(INDEX_NAME, 35) AS INDEX_NAME,
    RPAD(TABLE_NAME, 20) AS TABLE_NAME,
    RPAD(UNIQUENESS, 10) AS UNIQUENESS,
    RPAD(STATUS, 12) AS STATUS,
    CASE 
        WHEN STATUS = 'VALID' THEN ' Active'
        WHEN STATUS = 'UNUSABLE' THEN ' Broken'
        ELSE ' ' || STATUS
    END AS HEALTH_STATUS
FROM USER_INDEXES 
WHERE INDEX_NAME LIKE 'IDX_%'
ORDER BY TABLE_NAME, INDEX_NAME;

BEGIN
    PRINT_BOX_HEADER('FOREIGN KEY COLUMNS INDEX STATUS');
END;
/

SELECT 
    RPAD(uc.TABLE_NAME, 20) AS TABLE_NAME,
    RPAD(ucc.COLUMN_NAME, 25) AS COLUMN_NAME,
    RPAD(uc.CONSTRAINT_NAME, 30) AS CONSTRAINT_NAME,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM USER_IND_COLUMNS uic 
            WHERE uic.TABLE_NAME = uc.TABLE_NAME 
            AND uic.COLUMN_NAME = ucc.COLUMN_NAME
        ) THEN ' Indexed'
        ELSE ' Missing Index'
    END AS INDEX_STATUS
FROM USER_CONSTRAINTS uc
JOIN USER_CONS_COLUMNS ucc ON uc.CONSTRAINT_NAME = ucc.CONSTRAINT_NAME
WHERE uc.CONSTRAINT_TYPE = 'R'  -- Foreign Key constraints
ORDER BY uc.TABLE_NAME, ucc.COLUMN_NAME;

BEGIN
    PRINT_BOX_HEADER('INDEX COVERAGE BY TABLE');
END;
/

SELECT 
    RPAD(ut.TABLE_NAME, 25) AS TABLE_NAME,
    LPAD(TO_CHAR(NVL(ut.NUM_ROWS, 0), '999,999,999'), 12) AS NUM_ROWS,
    LPAD(COUNT(ui.INDEX_NAME), 8) AS INDEX_COUNT,
    CASE 
        WHEN COUNT(ui.INDEX_NAME) = 0 THEN ' No Indexes'
        WHEN COUNT(ui.INDEX_NAME) < 3 THEN ' Few Indexes'
        WHEN COUNT(ui.INDEX_NAME) > 10 THEN ' Many Indexes'
        ELSE ' Good Coverage'
    END AS INDEX_ASSESSMENT
FROM USER_TABLES ut
LEFT JOIN USER_INDEXES ui ON ut.TABLE_NAME = ui.TABLE_NAME
GROUP BY ut.TABLE_NAME, ut.NUM_ROWS
ORDER BY COUNT(ui.INDEX_NAME) DESC, ut.NUM_ROWS DESC;

-- =============================================================================
-- STEP 4: DUPLICATE INDEX DETECTION
-- =============================================================================

BEGIN
    PRINT_SECTION_HEADER('DUPLICATE INDEX DETECTION');
END;
/

BEGIN
    PRINT_BOX_HEADER('DUPLICATE INDEX ANALYSIS');
END;
/

WITH index_signatures AS (
    SELECT 
        ui.INDEX_NAME,
        ui.TABLE_NAME,
        ui.UNIQUENESS,
        LISTAGG(uic.COLUMN_NAME, ',') WITHIN GROUP (ORDER BY uic.COLUMN_POSITION) AS COLUMN_LIST,
        COUNT(*) OVER (PARTITION BY ui.TABLE_NAME, 
                      LISTAGG(uic.COLUMN_NAME, ',') WITHIN GROUP (ORDER BY uic.COLUMN_POSITION)) AS DUP_COUNT
    FROM USER_INDEXES ui
    JOIN USER_IND_COLUMNS uic ON ui.INDEX_NAME = uic.INDEX_NAME
    GROUP BY ui.INDEX_NAME, ui.TABLE_NAME, ui.UNIQUENESS
)
SELECT 
    RPAD(TABLE_NAME, 20) AS TABLE_NAME,
    RPAD(SUBSTR(COLUMN_LIST, 1, 40), 40) AS COLUMN_LIST,
    RPAD(INDEX_NAME, 35) AS INDEX_NAME,
    RPAD(UNIQUENESS, 10) AS UNIQUENESS,
    LPAD(DUP_COUNT, 3) AS DUP_COUNT,
    CASE WHEN DUP_COUNT > 1 THEN ' DUPLICATE' ELSE ' UNIQUE' END AS STATUS
FROM index_signatures
WHERE DUP_COUNT > 1
ORDER BY TABLE_NAME, COLUMN_LIST, INDEX_NAME;

-- =============================================================================
-- STEP 5: FINAL SUMMARY AND RECOMMENDATIONS
-- =============================================================================

BEGIN
    PRINT_SECTION_HEADER('FINAL SUMMARY AND RECOMMENDATIONS');
END;
/

-- Run comprehensive analysis
BEGIN
    ANALYZE_DATABASE_XE112;
END;
/

BEGIN
    PRINT_BOX_HEADER('DATABASE INDEX STATISTICS');
END;
/

SELECT 
    RPAD(metric_info.METRIC, 30) AS METRIC,
    LPAD(TO_CHAR(metric_info.VALUE, '999,999'), 8) AS VALUE,
    CASE 
        WHEN metric_info.METRIC = 'Total Indexes' THEN ' All indexes in schema'
        WHEN metric_info.METRIC = 'Performance Indexes' THEN ' Custom performance indexes'
        WHEN metric_info.METRIC = 'System Indexes' THEN ' Constraint-related indexes'
        WHEN metric_info.METRIC = 'Tables with Indexes' THEN '  Indexed tables'
        ELSE ' Database coverage'
    END AS DESCRIPTION
FROM (
    SELECT 'Total Indexes' AS METRIC, COUNT(*) AS VALUE FROM USER_INDEXES
    UNION ALL
    SELECT 'Performance Indexes', COUNT(*) FROM USER_INDEXES WHERE INDEX_NAME LIKE 'IDX_%'
    UNION ALL
    SELECT 'System Indexes', COUNT(*) FROM USER_INDEXES WHERE INDEX_NAME NOT LIKE 'IDX_%'
    UNION ALL
    SELECT 'Tables with Indexes', COUNT(DISTINCT TABLE_NAME) FROM USER_INDEXES
) metric_info;


-- Clean up column formatting
COLUMN TABLE_NAME CLEAR
COLUMN INDEX_NAME CLEAR
COLUMN COLUMN_NAME CLEAR
COLUMN CONSTRAINT_NAME CLEAR
COLUMN NUM_ROWS CLEAR
COLUMN INDEX_COUNT CLEAR
COLUMN UNIQUENESS CLEAR
COLUMN STATUS CLEAR
COLUMN INDEX_STATUS CLEAR
COLUMN INDEX_ASSESSMENT CLEAR
COLUMN COLUMN_LIST CLEAR
COLUMN METRIC CLEAR
COLUMN VALUE CLEAR
COLUMN DUP_COUNT CLEAR
COLUMN HEALTH_STATUS CLEAR
COLUMN SIZE_CATEGORY CLEAR
COLUMN DESCRIPTION CLEAR

-- Reset session settings to Oracle XE 11.2 defaults
SET PAGESIZE 14;
SET LINESIZE 80;
SET VERIFY ON;
SET ECHO ON;

