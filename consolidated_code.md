<Date> August 31, 2025 20:31</Date>

```01_create_tables.sql
--=============================================================================
-- File: 01_create_tables.sql
-- Purpose: Drops all existing database objects in the correct order to ensure
--          a clean slate, then creates all tables and sequences.
--=============================================================================

PROMPT Dropping all existing objects...

-- Drop objects in reverse order of dependency
PROMPT Dropping views...
DROP VIEW V_BOOKING_DETAILS;
DROP VIEW V_BUS_SCHEDULE_DETAILS;
DROP VIEW V_STAFF_SERVICE_WORK;

PROMPT Dropping triggers...
DROP TRIGGER trg_audit_staff_changes;
DROP TRIGGER trg_prevent_company_deletion;

PROMPT Dropping procedures and functions...
DROP PROCEDURE Add_New_Staff;
DROP PROCEDURE Assign_Driver_To_Schedule;
DROP PROCEDURE rpt_campaign_performance;
DROP PROCEDURE rpt_bus_maintenance_history;
DROP FUNCTION calculate_final_ticket_price; -- ADDED

PROMPT Dropping child tables...
DROP TABLE StaffAllocation;
DROP TABLE ServiceDetails;
DROP TABLE RentalCollection;
DROP TABLE BookingDetails;
DROP TABLE Extension;
DROP TABLE Refund;
DROP TABLE Ticket;
DROP TABLE Promotion;
DROP TABLE DriverList;
DROP TABLE Schedule;

PROMPT Dropping base tables...
DROP TABLE Campaign;
DROP TABLE Payment;
DROP TABLE Member;
DROP TABLE Service;
DROP TABLE Shop;
DROP TABLE Staff_Audit_Log; -- ADDED
DROP TABLE Staff;
DROP TABLE Driver;
DROP TABLE Bus;
DROP TABLE Company;

PROMPT Dropping all sequences...
DROP SEQUENCE company_seq;
DROP SEQUENCE bus_seq;
DROP SEQUENCE schedule_seq;
DROP SEQUENCE driver_seq;
DROP SEQUENCE staff_seq;
DROP SEQUENCE shop_seq;
DROP SEQUENCE rental_collection_seq;
DROP SEQUENCE service_seq;
DROP SEQUENCE service_details_seq;
DROP SEQUENCE campaign_seq;
DROP SEQUENCE promotion_seq;
DROP SEQUENCE member_seq;
DROP SEQUENCE payment_seq;
DROP SEQUENCE booking_seq;
DROP SEQUENCE ticket_seq;
DROP SEQUENCE refund_seq;
DROP SEQUENCE extension_seq;
DROP SEQUENCE staff_audit_log_seq; -- ADDED

--=============================================================================
-- Sequences for Primary Key Generation
--=============================================================================
CREATE SEQUENCE company_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE bus_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE schedule_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE driver_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE staff_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE shop_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE rental_collection_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE service_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE service_details_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE campaign_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE promotion_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE member_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE payment_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE booking_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ticket_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE refund_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE extension_seq START WITH 1 INCREMENT BY 1;

--=============================================================================
-- Table Creation Script
--=============================================================================
-- (The rest of the file is unchanged, starting with CREATE TABLE Company...)
CREATE TABLE Company (
    company_id      NUMBER(10) NOT NULL,
    name            VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_company PRIMARY KEY (company_id)
);

CREATE TABLE Bus (
    bus_id          NUMBER(10) NOT NULL,
    plate_number    VARCHAR2(20) NOT NULL UNIQUE,
    capacity        NUMBER(3) NOT NULL,
    company_id      NUMBER(10) NOT NULL,
    CONSTRAINT pk_bus PRIMARY KEY (bus_id),
    CONSTRAINT fk_bus_company FOREIGN KEY (company_id) REFERENCES Company(company_id),
    CONSTRAINT chk_bus_capacity CHECK (capacity > 0)
);

CREATE TABLE Driver (
    driver_id       NUMBER(10) NOT NULL,
    name            VARCHAR2(100) NOT NULL,
    license_no      VARCHAR2(50) NOT NULL UNIQUE,
    CONSTRAINT pk_driver PRIMARY KEY (driver_id)
);

CREATE TABLE Staff (
    staff_id            NUMBER(10) NOT NULL,
    name                VARCHAR2(100) NOT NULL,
    role                VARCHAR2(50) NOT NULL,
    email               VARCHAR2(100) NOT NULL UNIQUE,
    contact_no          VARCHAR2(25) NOT NULL,
    employment_date     DATE NOT NULL,
    status              VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_staff PRIMARY KEY (staff_id),
    CONSTRAINT chk_staff_role CHECK (role IN ('Counter Staff', 'Cleaner', 'Manager', 'Technician')),
    CONSTRAINT chk_staff_status CHECK (status IN ('Active', 'Resigned', 'On Leave'))
);

CREATE TABLE Shop (
    shop_id         NUMBER(10) NOT NULL,
    shop_name       VARCHAR2(100) NOT NULL,
    location_code   VARCHAR2(20) NOT NULL UNIQUE,
    CONSTRAINT pk_shop PRIMARY KEY (shop_id)
);

CREATE TABLE Service (
    service_id      NUMBER(10) NOT NULL,
    service_name    VARCHAR2(100) NOT NULL,
    standard_cost   NUMBER(10, 2) NOT NULL,
    CONSTRAINT pk_service PRIMARY KEY (service_id),
    CONSTRAINT chk_service_cost CHECK (standard_cost >= 0)
);

CREATE TABLE Member (
    member_id           NUMBER(10) NOT NULL,
    name                VARCHAR2(100) NOT NULL,
    email               VARCHAR2(100) NOT NULL UNIQUE,
    contact_no          VARCHAR2(25) NOT NULL,
    registration_date   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_member PRIMARY KEY (member_id)
);

CREATE TABLE Payment (
    payment_id      NUMBER(10) NOT NULL,
    payment_date    DATE DEFAULT SYSDATE NOT NULL,
    amount          NUMBER(10, 2) NOT NULL,
    payment_method  VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_payment PRIMARY KEY (payment_id),
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    CONSTRAINT chk_payment_method CHECK (payment_method IN ('Credit Card', 'Debit Card', 'Online Banking', 'E-Wallet'))
);

CREATE TABLE Campaign (
    campaign_id     NUMBER(10) NOT NULL,
    campaign_name   VARCHAR2(100) NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    CONSTRAINT pk_campaign PRIMARY KEY (campaign_id),
    CONSTRAINT chk_campaign_dates CHECK (end_date >= start_date)
);

CREATE TABLE Schedule (
    schedule_id         NUMBER(10) NOT NULL,
    departure_time      DATE NOT NULL,
    arrival_time        DATE NOT NULL,
    base_price          NUMBER(10, 2) NOT NULL,
    origin_station      VARCHAR2(100) NOT NULL,
    destination_station VARCHAR2(100) NOT NULL,
    platform_no         VARCHAR2(10),
    bus_id              NUMBER(10) NOT NULL,
    CONSTRAINT pk_schedule PRIMARY KEY (schedule_id),
    CONSTRAINT fk_schedule_bus FOREIGN KEY (bus_id) REFERENCES Bus(bus_id),
    CONSTRAINT chk_schedule_times CHECK (arrival_time > departure_time),
    CONSTRAINT chk_schedule_price CHECK (base_price > 0)
);

CREATE TABLE DriverList (
    schedule_id         NUMBER(10) NOT NULL,
    driver_id           NUMBER(10) NOT NULL,
    assignment_notes    VARCHAR2(255),
    CONSTRAINT pk_driverlist PRIMARY KEY (schedule_id, driver_id),
    CONSTRAINT fk_driverlist_schedule FOREIGN KEY (schedule_id) REFERENCES Schedule(schedule_id),
    CONSTRAINT fk_driverlist_driver FOREIGN KEY (driver_id) REFERENCES Driver(driver_id)
);

CREATE TABLE Promotion (
    promotion_id    NUMBER(10) NOT NULL,
    promotion_name  VARCHAR2(100) NOT NULL,
    description     VARCHAR2(255),
    discount_type   VARCHAR2(20) NOT NULL,
    discount_value  NUMBER(10, 2) NOT NULL,
    applies_to      VARCHAR2(50),
    valid_from      DATE NOT NULL,
    valid_until     DATE NOT NULL,
    condition       VARCHAR2(255),
    campaign_id     NUMBER(10) NOT NULL,
    CONSTRAINT pk_promotion PRIMARY KEY (promotion_id),
    CONSTRAINT fk_promotion_campaign FOREIGN KEY (campaign_id) REFERENCES Campaign(campaign_id),
    CONSTRAINT chk_promo_dates CHECK (valid_until >= valid_from),
    CONSTRAINT chk_promo_discount_type CHECK (discount_type IN ('Percentage', 'Fixed Amount')),
    CONSTRAINT chk_promo_discount_value CHECK (discount_value > 0)
);

CREATE TABLE Ticket (
    ticket_id       NUMBER(10) NOT NULL,
    seat_number     VARCHAR2(10) NOT NULL,
    status          VARCHAR2(20) NOT NULL,
    schedule_id     NUMBER(10) NOT NULL,
    promotion_id    NUMBER(10),
    CONSTRAINT pk_ticket PRIMARY KEY (ticket_id),
    CONSTRAINT fk_ticket_schedule FOREIGN KEY (schedule_id) REFERENCES Schedule(schedule_id),
    CONSTRAINT fk_ticket_promotion FOREIGN KEY (promotion_id) REFERENCES Promotion(promotion_id),
    CONSTRAINT chk_ticket_status CHECK (status IN ('Available', 'Booked', 'Cancelled', 'Extended'))
);

CREATE TABLE Refund (
    refund_id       NUMBER(10) NOT NULL,
    refund_date     DATE NOT NULL,
    amount          NUMBER(10, 2) NOT NULL,
    refund_method   VARCHAR2(50) NOT NULL,
    ticket_id       NUMBER(10) NOT NULL UNIQUE,
    CONSTRAINT pk_refund PRIMARY KEY (refund_id),
    CONSTRAINT fk_refund_ticket FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id),
    CONSTRAINT chk_refund_amount CHECK (amount > 0)
);

CREATE TABLE Extension (
    extension_id      NUMBER(10) NOT NULL,
    extension_date    DATE NOT NULL,
    amount            NUMBER(10, 2) NOT NULL,
    extension_method  VARCHAR2(50) NOT NULL,
    ticket_id         NUMBER(10) NOT NULL UNIQUE,
    CONSTRAINT pk_extension PRIMARY KEY (extension_id),
    CONSTRAINT fk_extension_ticket FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id),
    CONSTRAINT chk_extension_amount CHECK (amount > 0)
);

CREATE TABLE Booking (
    booking_id      NUMBER(10) NOT NULL,
    booking_date    DATE DEFAULT SYSDATE NOT NULL,
    total_amount    NUMBER(10, 2) NOT NULL,
    member_id       NUMBER(10) NOT NULL,
    payment_id      NUMBER(10) NOT NULL UNIQUE,
    CONSTRAINT pk_booking PRIMARY KEY (booking_id),
    CONSTRAINT fk_booking_member FOREIGN KEY (member_id) REFERENCES Member(member_id),
    CONSTRAINT fk_booking_payment FOREIGN KEY (payment_id) REFERENCES Payment(payment_id),
    CONSTRAINT chk_booking_amount CHECK (total_amount >= 0)
);

CREATE TABLE BookingDetails (
    booking_id  NUMBER(10) NOT NULL,
    ticket_id   NUMBER(10) NOT NULL,
    CONSTRAINT pk_bookingdetails PRIMARY KEY (booking_id, ticket_id),
    CONSTRAINT fk_bd_booking FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    CONSTRAINT fk_bd_ticket FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id)
);

CREATE TABLE RentalCollection (
    rental_id           NUMBER(10) NOT NULL,
    rental_date         DATE NOT NULL,
    amount              NUMBER(10, 2) NOT NULL,
    collection_date     DATE,
    rental_method       VARCHAR2(50),
    remark              VARCHAR2(255),
    shop_id             NUMBER(10) NOT NULL,
    staff_id            NUMBER(10) NOT NULL,
    CONSTRAINT pk_rentalcollection PRIMARY KEY (rental_id),
    CONSTRAINT fk_rc_shop FOREIGN KEY (shop_id) REFERENCES Shop(shop_id),
    CONSTRAINT fk_rc_staff FOREIGN KEY (staff_id) REFERENCES Staff(staff_id),
    CONSTRAINT chk_rc_amount CHECK (amount > 0)
);

CREATE TABLE ServiceDetails (
    service_transaction_id  NUMBER(10) NOT NULL,
    service_date            DATE NOT NULL,
    actual_cost             NUMBER(10, 2) NOT NULL,
    remarks                 VARCHAR2(255),
    service_id              NUMBER(10) NOT NULL,
    bus_id                  NUMBER(10) NOT NULL,
    CONSTRAINT pk_servicedetails PRIMARY KEY (service_transaction_id),
    CONSTRAINT fk_sd_service FOREIGN KEY (service_id) REFERENCES Service(service_id),
    CONSTRAINT fk_sd_bus FOREIGN KEY (bus_id) REFERENCES Bus(bus_id)
);

CREATE TABLE StaffAllocation (
    service_transaction_id  NUMBER(10) NOT NULL,
    staff_id                NUMBER(10) NOT NULL,
    role                    VARCHAR2(100) NOT NULL,
    start_time              DATE,
    end_time                DATE,
    CONSTRAINT pk_staffallocation PRIMARY KEY (service_transaction_id, staff_id),
    CONSTRAINT fk_sa_servicedetails FOREIGN KEY (service_transaction_id) REFERENCES ServiceDetails(service_transaction_id),
    CONSTRAINT fk_sa_staff FOREIGN KEY (staff_id) REFERENCES Staff(staff_id)
);

COMMIT;
```

```02a_sync_sequences.sql
--=============================================================================
-- File: 02a_sync_sequences.sql
--=============================================================================
-- Sequence still starts at 1, but after inserting example 10 rows, 1 already used, so need to reset to use max_value + 1 for primary key value.
--=============================================================================

SET SERVEROUTPUT ON;

DECLARE
  -- Helper procedure to find the max ID, drop the sequence, and recreate it
  -- starting at the correct value. This is a standard practice for bulk loads.
  PROCEDURE reset_sequence(p_seq_name IN VARCHAR2, p_table_name IN VARCHAR2, p_pk_column IN VARCHAR2) IS
    l_max_id NUMBER;
  BEGIN
    -- Find the highest current primary key value in the table
    EXECUTE IMMEDIATE 'SELECT COALESCE(MAX(' || p_pk_column || '), 0) FROM ' || p_table_name INTO l_max_id;
    
    -- Add 1 to start the sequence at the next available value
    l_max_id := l_max_id + 1;

    -- Drop the existing sequence
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || p_seq_name;
    
    -- Recreate the sequence starting with the correct new value
    EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || p_seq_name || ' START WITH ' || l_max_id || ' INCREMENT BY 1 NOCACHE';
    
    DBMS_OUTPUT.PUT_LINE('Sequence ' || RPAD(p_seq_name, 25) || ' reset to start at ' || l_max_id);
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error resetting sequence ' || p_seq_name || '. Manual check required. Error: ' || SQLERRM);
  END reset_sequence;

BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Starting Sequence Synchronization ---');

  reset_sequence('company_seq', 'Company', 'company_id');
  reset_sequence('bus_seq', 'Bus', 'bus_id');
  reset_sequence('schedule_seq', 'Schedule', 'schedule_id');
  reset_sequence('driver_seq', 'Driver', 'driver_id');
  reset_sequence('staff_seq', 'Staff', 'staff_id');
  reset_sequence('shop_seq', 'Shop', 'shop_id');
  reset_sequence('rental_collection_seq', 'RentalCollection', 'rental_id');
  reset_sequence('service_seq', 'Service', 'service_id');
  reset_sequence('service_details_seq', 'ServiceDetails', 'service_transaction_id');
  reset_sequence('campaign_seq', 'Campaign', 'campaign_id');
  reset_sequence('promotion_seq', 'Promotion', 'promotion_id');
  reset_sequence('member_seq', 'Member', 'member_id');
  reset_sequence('payment_seq', 'Payment', 'payment_id');
  reset_sequence('booking_seq', 'Booking', 'booking_id');
  reset_sequence('ticket_seq', 'Ticket', 'ticket_id');
  reset_sequence('refund_seq', 'Refund', 'refund_id');
  reset_sequence('extension_seq', 'Extension', 'extension_id');

  DBMS_OUTPUT.PUT_LINE('--- Sequence Synchronization Complete ---');
END;
/

COMMIT;
```

```02b_check_count.sql
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
```

```03_bryan_queries_and_views.sql
--=============================================================================
-- File: 03_queries_and_views.sql
--=============================================================================
-- Purpose: Creates reusable views to simplify data access and provides
--          examples of complex analytical queries for management.
--=============================================================================











--=============================================================================
-- Section 1: Foundational Views
--=============================================================================
-- These views abstract complex joins and provide a simplified, logical layer
-- for other developers and analysts to query against.

PROMPT Creating View: V_BOOKING_DETAILS
CREATE OR REPLACE VIEW V_BOOKING_DETAILS AS
SELECT
    b.booking_id,
    b.booking_date,
    m.member_id,
    m.name AS member_name,
    m.email AS member_email,
    t.ticket_id,
    t.seat_number,
    t.status AS ticket_status,
    s.schedule_id,
    s.departure_time,
    s.arrival_time,
    s.origin_station,
    s.destination_station,
    s.base_price,
    c.name AS company_name,
    p.promotion_id,
    p.promotion_name
FROM Booking b
JOIN Member m ON b.member_id = m.member_id
JOIN BookingDetails bd ON b.booking_id = bd.booking_id
JOIN Ticket t ON bd.ticket_id = t.ticket_id
JOIN Schedule s ON t.schedule_id = s.schedule_id
JOIN Bus bu ON s.bus_id = bu.bus_id
JOIN Company c ON bu.company_id = c.company_id
LEFT JOIN Promotion p ON t.promotion_id = p.promotion_id;

COMMENT ON TABLE V_BOOKING_DETAILS IS 'A comprehensive view combining booking, member, ticket, and schedule information for easy querying of all booking-related data.';


PROMPT Creating View: V_BUS_SCHEDULE_DETAILS
CREATE OR REPLACE VIEW V_BUS_SCHEDULE_DETAILS AS
SELECT
    s.schedule_id,
    s.departure_time,
    s.arrival_time,
    s.base_price,
    s.origin_station,
    s.destination_station,
    s.platform_no,
    b.bus_id,
    b.plate_number,
    b.capacity,
    c.company_id,
    c.name AS company_name
FROM Schedule s
JOIN Bus b ON s.bus_id = b.bus_id
JOIN Company c ON b.company_id = c.company_id;

COMMENT ON TABLE V_BUS_SCHEDULE_DETAILS IS 'A simplified view joining schedule, bus, and company details, ideal for searching and displaying trip information.';


--=============================================================================
-- Section 2: Analytical Queries for Management
--=============================================================================

PROMPT Creating View: V_STAFF_SERVICE_WORK
CREATE OR REPLACE VIEW V_STAFF_SERVICE_WORK AS
SELECT
    st.staff_id,
    st.role,
    st.name,
    sa.service_transaction_id,
    sd.actual_cost
FROM Staff st
JOIN StaffAllocation sa ON st.staff_id = sa.staff_id
JOIN ServiceDetails sd ON sa.service_transaction_id = sd.service_transaction_id;

COMMENT ON TABLE V_STAFF_SERVICE_WORK IS 'View mapping staff to their service tasks and costs, used for operational performance reporting.';












--=============================================================================
-- Query 1: Monthly Revenue Summary by Bus Company (Strategic Level)
--=============================================================================
-- Purpose: Provides a high-level overview of revenue generated by each bus
--          company, aggregated by month. This helps strategic management
--          assess partner performance and financial trends.

PROMPT Running Query: Monthly Revenue by Company (Formatted Report)

-- Setup for the report format
SET LINESIZE 100
SET PAGESIZE 200
TTITLE CENTER 'Monthly Revenue Report by Bus Company' SKIP 2

-- Define column formats for clean output
COLUMN booking_month FORMAT A10 HEADING 'Month'
COLUMN company_name  FORMAT A35 HEADING 'Bus Company'
COLUMN total_revenue FORMAT 999,999,990.00 HEADING 'Total Revenue (RM)'
COLUMN ticket_count  FORMAT 999,999 HEADING 'Tickets Sold'

-- Group the report by month and compute monthly subtotals
BREAK ON booking_month SKIP 1
COMPUTE SUM LABEL 'Total:' OF total_revenue ON booking_month

-- The actual query
SELECT
    TO_CHAR(vb.booking_date, 'YYYY-MM') AS booking_month,
    vb.company_name,
    SUM(vb.base_price) AS total_revenue,
    COUNT(vb.ticket_id) AS ticket_count
FROM V_BOOKING_DETAILS vb
WHERE vb.ticket_status = 'Booked'
GROUP BY
    TO_CHAR(vb.booking_date, 'YYYY-MM'),
    vb.company_name
ORDER BY
    booking_month DESC,
    total_revenue DESC;

-- Clean up formatting settings to not affect subsequent queries
CLEAR COLUMNS;
CLEAR BREAKS;
CLEAR COMPUTES;
TTITLE OFF;
















--=============================================================================
-- Query 2: Staff Performance on Service Tasks (Operational Level)
--=============================================================================
-- Purpose: Measures the productivity of maintenance staff by counting the
--          number of service tasks completed and the total cost of those
--          services. This is useful for operational managers to evaluate
--          workload and performance.

PROMPT Running Query: Staff Service Performance (Formatted Report)

-- Setup for the report format
SET LINESIZE 120
SET PAGESIZE 200
TTITLE CENTER 'Staff Service Performance Report' SKIP 2

-- Define column formats for clean output
COLUMN staff_role         FORMAT A15 HEADING 'Staff Role'
COLUMN staff_name         FORMAT A30 HEADING 'Staff Name'
COLUMN tasks_completed    FORMAT 999,990 HEADING 'Tasks|Completed'
COLUMN total_service_cost FORMAT 999,999,990.00 HEADING 'Total Cost of Services (RM)'

-- Group the report by role for readability
BREAK ON staff_role SKIP 1

-- The actual query
SELECT
    v.role AS staff_role,
    v.name AS staff_name,
    COUNT(v.service_transaction_id) AS tasks_completed,
    SUM(v.actual_cost) AS total_service_cost
FROM V_STAFF_SERVICE_WORK v
WHERE v.role IN ('Technician', 'Cleaner')
GROUP BY
    v.role,
    v.staff_id,
    v.name
ORDER BY
    v.role,
    tasks_completed DESC;

-- Clean up formatting settings to not affect subsequent queries
CLEAR COLUMNS;
CLEAR BREAKS;
TTITLE OFF;

COMMIT;
```

```04_bryan_stored_procedures.sql
--=============================================================================
-- File: 04_stored_procedures.sql
--=============================================================================
-- Purpose: Implements the core business logic of the system through
--          reusable, secure, and maintainable stored procedures.
--=============================================================================

SET SERVEROUTPUT ON;

--=============================================================================
-- Section 1: Administrative Procedures
--=============================================================================
-- Purpose: Error handling to prevent duplication of staff records based on their email address, ensureing data integrity.

CREATE OR REPLACE PROCEDURE Add_New_Staff (
    p_name          IN Staff.name%TYPE,
    p_role          IN Staff.role%TYPE,
    p_email         IN Staff.email%TYPE,
    p_contact_no    IN Staff.contact_no%TYPE,
    p_status        IN Staff.status%TYPE DEFAULT 'Active'
)
AS
    -- No local variables
BEGIN
    INSERT INTO Staff (
        staff_id,
        name,
        role,
        email,
        contact_no,
        employment_date,
        status
    )
    VALUES (
        staff_seq.NEXTVAL,
        p_name,
        p_role,
        p_email,
        p_contact_no,
        SYSDATE, -- Employment date set to current system date
        p_status
    );

    DBMS_OUTPUT.PUT_LINE('Successfully added new staff member: ' || p_name);
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Error: A staff member with the email ''' || p_email || ''' already exists.');

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'An unexpected error occurred. Oracle error code: ' || SQLCODE || ' - ' || SQLERRM);
END Add_New_Staff;
/


--=============================================================================
-- Procedure 2: Assign Driver to Schedule (Operational Level)
--=============================================================================
-- Purpose: Before assignment, verify both driver and schedule exist.

CREATE OR REPLACE PROCEDURE Assign_Driver_To_Schedule (
    p_schedule_id   IN Schedule.schedule_id%TYPE,
    p_driver_id     IN Driver.driver_id%TYPE,
    p_notes         IN DriverList.assignment_notes%TYPE DEFAULT NULL
)
AS
    v_schedule_count NUMBER;
    v_driver_count   NUMBER;
BEGIN
    -- Step 1: Validate that the schedule exists to prevent foreign key errors.
    SELECT COUNT(*) INTO v_schedule_count FROM Schedule WHERE schedule_id = p_schedule_id;
    
    IF v_schedule_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Error: Schedule with ID ' || p_schedule_id || ' does not exist.');
    END IF;

    -- Step 2: Validate that the driver exists.
    SELECT COUNT(*) INTO v_driver_count FROM Driver WHERE driver_id = p_driver_id;
    
    IF v_driver_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Error: Driver with ID ' || p_driver_id || ' does not exist.');
    END IF;

    -- Step 3: If validation passes, insert the new assignment.
    INSERT INTO DriverList (
        schedule_id,
        driver_id,
        assignment_notes
    ) VALUES (
        p_schedule_id,
        p_driver_id,
        p_notes
    );

    DBMS_OUTPUT.PUT_LINE('Successfully assigned driver ' || p_driver_id || ' to schedule ' || p_schedule_id || '.');
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20012, 'Error: Driver ' || p_driver_id || ' is already assigned to schedule ' || p_schedule_id || '.');

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END Assign_Driver_To_Schedule;
/
```

```05_bryan_triggers.sql
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














--=============================================================================
-- Trigger 1: Staff Change Auditing (Operational Level)
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
-- Trigger 2: Prevent Orphaned Bus Records (Data Integrity)
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


```

```06_bryan_reports.sql
--=============================================================================
-- File: 06_reports.sql
--=============================================================================
-- Purpose: Contains stored procedures designed to generate formatted,
--          human-readable reports for management using PL/SQL cursors.
--=============================================================================

SET SERVEROUTPUT ON;

--=============================================================================
-- Section 1: Financial and Marketing Reports
--=============================================================================














--
-- 4.1.7 Report 1: On-demand Summary Report of Annual Campaign Performance.
--
-- Purpose: To provide a strategic overview of campaign effectiveness by summarizing ticket sales, revenue,
--          and calculating key performance indicators (KPIs) for a user-specified year.
--

CREATE OR REPLACE PROCEDURE rpt_campaign_performance (
    p_year IN NUMBER
)
AS
    -- Outer cursor: campaigns in the requested year
    CURSOR campaign_cursor IS
        SELECT
            c.campaign_id,
            c.campaign_name
        FROM Campaign c
        WHERE EXTRACT(YEAR FROM c.start_date) = p_year
           OR EXTRACT(YEAR FROM c.end_date) = p_year
        ORDER BY c.start_date;

    -- Inner cursor: aggregated stats per campaign
    CURSOR campaign_stats_cursor (cp_campaign_id IN Campaign.campaign_id%TYPE) IS
        SELECT
            COUNT(DISTINCT p.promotion_id) AS promo_count,
            COUNT(vb.ticket_id) AS tickets_sold,
            NVL(SUM(vb.base_price), 0) AS total_revenue
        FROM Promotion p
        LEFT JOIN V_BOOKING_DETAILS vb
               ON vb.promotion_id = p.promotion_id
              AND vb.ticket_status = 'Booked'
        WHERE p.campaign_id = cp_campaign_id;

    v_report_generated      BOOLEAN := FALSE;
    v_grand_total_promos    NUMBER := 0;
    v_grand_total_tickets   NUMBER := 0;
    v_grand_total_revenue   NUMBER := 0;
    v_avg_revenue_per_tkt   NUMBER;

BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE('Campaign Performance Report for Year: ' || p_year);
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Campaign Name', 40) ||
        RPAD('Promotions', 12) ||
        RPAD('Tickets Sold', 12) ||
        RPAD('Avg Rev/Tkt', 15) ||
        'Total Revenue (RM)'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

    -- Loop through each campaign
    FOR campaign_rec IN campaign_cursor LOOP
        v_report_generated := TRUE;

        FOR stats_rec IN campaign_stats_cursor(campaign_rec.campaign_id) LOOP
            IF stats_rec.tickets_sold > 0 THEN
                v_avg_revenue_per_tkt := stats_rec.total_revenue / stats_rec.tickets_sold;
            ELSE
                v_avg_revenue_per_tkt := 0;
            END IF;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(SUBSTR(campaign_rec.campaign_name, 1, 38), 40) ||
                LPAD(TO_CHAR(stats_rec.promo_count, 'FM999,990'), 12) ||
                LPAD(TO_CHAR(stats_rec.tickets_sold, 'FM999,990'), 12) ||
                LPAD(TO_CHAR(v_avg_revenue_per_tkt, 'FM99,990.00'), 15) ||
                LPAD(TO_CHAR(stats_rec.total_revenue, 'FM9,999,990.00'), 21)
            );

            v_grand_total_promos  := v_grand_total_promos + stats_rec.promo_count;
            v_grand_total_tickets := v_grand_total_tickets + stats_rec.tickets_sold;
            v_grand_total_revenue := v_grand_total_revenue + stats_rec.total_revenue;
        END LOOP;
    END LOOP;

    -- Handle the case where no campaigns were found
    IF NOT v_report_generated THEN
        DBMS_OUTPUT.PUT_LINE('No campaign data found for the year ' || p_year || '.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
        
        IF v_grand_total_tickets > 0 THEN
            v_avg_revenue_per_tkt := v_grand_total_revenue / v_grand_total_tickets;
        ELSE
            v_avg_revenue_per_tkt := 0;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(
            RPAD('GRAND TOTALS:', 40) ||
            LPAD(TO_CHAR(v_grand_total_promos, 'FM999,990'), 12) ||
            LPAD(TO_CHAR(v_grand_total_tickets, 'FM999,990'), 12) ||
            LPAD(TO_CHAR(v_avg_revenue_per_tkt, 'FM99,990.00'), 15) ||
            LPAD(TO_CHAR(v_grand_total_revenue, 'FM9,999,990.00'), 21)
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_campaign_performance;
/






















--
-- 4.1.8 Report 2: On-demand Detail Report of Bus Maintenance History.
--
-- Purpose: To provide operational managers with a complete, chronological log of all service activities and
--          associated costs for a specific bus to aid in maintenance tracking and cost analysis.
--

CREATE OR REPLACE PROCEDURE rpt_bus_maintenance_history (
    p_bus_id IN Bus.bus_id%TYPE
)
AS
    -- Outer cursor: Fetches the primary record (the bus).
    CURSOR bus_cursor IS
        SELECT
            b.bus_id,
            b.plate_number,
            c.name as company_name
        FROM Bus b
        JOIN Company c ON b.company_id = c.company_id
        WHERE b.bus_id = p_bus_id;

    -- Inner cursor: Fetches the detail records (service history for that bus).
    CURSOR service_history_cursor (cp_bus_id IN Bus.bus_id%TYPE) IS
        SELECT
            sd.service_date,
            s.service_name,
            sd.actual_cost
        FROM ServiceDetails sd
        JOIN Service s ON sd.service_id = s.service_id
        WHERE sd.bus_id = cp_bus_id
        ORDER BY sd.service_date DESC;
        
    v_bus_found BOOLEAN := FALSE;
    v_event_count NUMBER := 0;
    v_total_cost  NUMBER := 0;

BEGIN
    -- Loop through the outer cursor
    FOR bus_rec IN bus_cursor LOOP
        v_bus_found := TRUE;
        
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
        DBMS_OUTPUT.PUT_LINE('Maintenance History Report');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        DBMS_OUTPUT.PUT_LINE('Bus Plate Number: ' || bus_rec.plate_number);
        DBMS_OUTPUT.PUT_LINE('Operating Company: ' || bus_rec.company_name);
        DBMS_OUTPUT.PUT_LINE('');
        
        DBMS_OUTPUT.PUT_LINE('Service History:');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        DBMS_OUTPUT.PUT_LINE(
            RPAD('Service Date', 20) ||
            RPAD('Service Name', 30) ||
            'Cost (RM)'
        );
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
        
        -- Loop through the inner cursor to print details and calculate totals
        FOR service_rec IN service_history_cursor(bus_rec.bus_id) LOOP
            DBMS_OUTPUT.PUT_LINE(
                RPAD(TO_CHAR(service_rec.service_date, 'DD-MON-YYYY'), 20) ||
                RPAD(SUBSTR(service_rec.service_name, 1, 28), 30) ||
                LPAD(TO_CHAR(service_rec.actual_cost, 'FM9,999,990.00'), 15)
            );
            
            v_event_count := v_event_count + 1;
            v_total_cost := v_total_cost + service_rec.actual_cost;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Overall Summary for Bus ' || bus_rec.plate_number || ':');
        DBMS_OUTPUT.PUT_LINE(RPAD('Total Maintenance Events:', 35) || LPAD(v_event_count, 22));
        DBMS_OUTPUT.PUT_LINE(RPAD('Total Lifetime Maintenance Cost:', 35) || 'RM ' || LPAD(TO_CHAR(v_total_cost, 'FM99,999,990.00'), 19));
        
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
    END LOOP;
    
    IF NOT v_bus_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: No bus found with ID ' || p_bus_id || '.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while generating the report: ' || SQLERRM);
END rpt_bus_maintenance_history;
/
```

```07_extra_features.sql
--=============================================================================
-- File: 07_extra_features.sql
--=============================================================================
-- Purpose: Implements performance enhancements and other database objects
--          that support the overall system.
--=============================================================================

PROMPT Creating indexes for performance...

-- Index for Booking table
-- Purpose: Speeds up finding all bookings made by a specific member. Crucial for person_a's tasks.
CREATE INDEX idx_booking_member_id ON Booking(member_id);

-- Index for Ticket table
-- Purpose: Speeds up finding all tickets for a given schedule. Benefits both booking and scheduling tasks.
CREATE INDEX idx_ticket_schedule_id ON Ticket(schedule_id);

-- Index for Schedule table
-- Purpose: Speeds up finding all schedules assigned to a specific bus. Crucial for person_b's tasks.
CREATE INDEX idx_schedule_bus_id ON Schedule(bus_id);

-- Index for BookingDetails table
-- Purpose: Optimizes the frequent joins between Bookings and Tickets.
CREATE INDEX idx_bookingdetails_ticket_id ON BookingDetails(ticket_id);

-- Index for StaffAllocation table
-- Purpose: Supports queries related to staff assignments and performance, like the one in 03_queries_and_views.sql.
CREATE INDEX idx_staffallocation_staff_id ON StaffAllocation(staff_id);

-- Index for ServiceDetails table
-- Purpose: Optimizes lookups for a bus's complete maintenance history. Supports your reporting tasks.
CREATE INDEX idx_servicedetails_bus_id ON ServiceDetails(bus_id);

-- Index for DriverList table
-- Purpose: Improves performance when searching for drivers assigned to a schedule.
CREATE INDEX idx_driverlist_driver_id ON DriverList(driver_id);

PROMPT Index creation complete.

COMMIT;
```

```07a_bryan_functions.sql
--=============================================================================
-- File: 07a_bryan_functions.sql
--=============================================================================
-- Purpose: Creates reusable User-Defined Functions for the system.
--=============================================================================

SET SERVEROUTPUT ON;

PROMPT Creating Function: calculate_final_ticket_price
CREATE OR REPLACE FUNCTION calculate_final_ticket_price (
    p_ticket_id IN Ticket.ticket_id%TYPE
)
RETURN NUMBER
IS
    v_base_price    Schedule.base_price%TYPE;
    v_promo_type    Promotion.discount_type%TYPE;
    v_promo_value   Promotion.discount_value%TYPE;
    v_final_price   NUMBER;
BEGIN
    -- This query joins the necessary tables to get the price and any promotion details.
    -- A LEFT JOIN is crucial because not every ticket has a promotion.
    SELECT
        s.base_price,
        p.discount_type,
        p.discount_value
    INTO
        v_base_price,
        v_promo_type,
        v_promo_value
    FROM Ticket t
    JOIN Schedule s ON t.schedule_id = s.schedule_id
    LEFT JOIN Promotion p ON t.promotion_id = p.promotion_id
    WHERE t.ticket_id = p_ticket_id;

    -- Apply the discount logic based on the promotion type
    IF v_promo_type = 'Percentage' THEN
        v_final_price := v_base_price * (1 - (v_promo_value / 100));
    ELSIF v_promo_type = 'Fixed Amount' THEN
        v_final_price := v_base_price - v_promo_value;
    ELSE
        -- If there is no promotion (v_promo_type is NULL), the price is the base price.
        v_final_price := v_base_price;
    END IF;

    -- Ensure the final price never drops below zero
    RETURN GREATEST(v_final_price, 0);

EXCEPTION
    -- If an invalid ticket_id is passed, return 0 instead of crashing.
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
END calculate_final_ticket_price;
/

COMMIT;
```

```08_bryan_demonstration.sql
--=============================================================================
-- File: 08_demonstration.sql
--=============================================================================
-- Purpose: A clear, step-by-step demonstration of the project's features.
--          Each test shows a success case and a failure case to prove
--          the system's logic and error handling.
--=============================================================================

SET SERVEROUTPUT ON SIZE 1000000;

-- --=============================================================================
-- -- TASK 4: STORED PROCEDURES DEMONSTRATION
-- --=============================================================================
-- DBMS_OUTPUT.PUT_LINE('');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
-- DBMS_OUTPUT.PUT_LINE('-- Task 4: Stored Procedures Demonstration');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));


---
--- --- Testing Procedure 1: Add_New_Staff ---

--- [TEST 1.1] SUCCESS CASE: Adding a new, unique staff member.
BEGIN
    Add_New_Staff(
        p_name       => 'David Chen',
        p_role       => 'Manager',
        p_email      => 'david.chen@busstation.com',
        p_contact_no => '555-8888'
    );
END;
/

-- Verification Step
SELECT staff_id, name, email FROM Staff WHERE email = 'david.chen@busstation.com';


--- [TEST 1.2] FAILURE CASE: Attempting to add a staff member with a duplicate email.
BEGIN
    Add_New_Staff(
        p_name       => 'David Fake',
        p_role       => 'Cleaner',
        p_email      => 'david.chen@busstation.com', -- This email now exists
        p_contact_no => '555-9999'
    );
END;
/


---
--- --- Testing Procedure 2: Assign_Driver_To_Schedule ---

--- [TEST 2.1] SUCCESS CASE: Assigning Driver 15 to Schedule 25.
BEGIN
    Assign_Driver_To_Schedule(p_schedule_id => 25, p_driver_id => 15);
END;
/

-- Verification Step
SELECT * FROM DriverList WHERE schedule_id = 25 AND driver_id = 15;


--- [TEST 2.2] FAILURE CASE: Attempting the same assignment again.
BEGIN
    Assign_Driver_To_Schedule(p_schedule_id => 25, p_driver_id => 15);
END;
/


--=============================================================================
-- TASK 5: TRIGGERS DEMONSTRATION
--=============================================================================
-- DBMS_OUTPUT.PUT_LINE('');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
-- DBMS_OUTPUT.PUT_LINE('-- Task 5: Triggers Demonstration');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));


---
--- --- Testing Trigger 1: trg_audit_staff_changes ---

--- [TEST 3.1] Updating a staff member's role to activate the audit trigger.
--- First, let's see the current role of Staff ID 20:
SELECT name, role FROM Staff WHERE staff_id = 20;

--- Now, we perform the update...
UPDATE Staff SET role = 'Manager' WHERE staff_id = 20;
COMMIT;

--- The update is done. Let's verify the new role:
SELECT name, role FROM Staff WHERE staff_id = 20;

--- And finally, let's check the Staff_Audit_Log to prove the trigger worked automatically:
SELECT log_id, staff_id, old_role, new_role, changed_by FROM Staff_Audit_Log WHERE staff_id = 20;


---
--- --- Testing Trigger 2: trg_prevent_company_deletion ---

--- [TEST 4.1] FAILURE CASE: Attempting to delete a company that still owns buses.
--- First, let's confirm Company ID 3 owns buses:
SELECT bus_id FROM Bus WHERE company_id = 3 AND ROWNUM <= 5;

--- Now, we attempt to delete the company...
BEGIN
    DELETE FROM Company WHERE company_id = 3;
END;
/


--=============================================================================
-- TASK 6: REPORTS DEMONSTRATION
--=============================================================================
-- DBMS_OUTPUT.PUT_LINE('');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
-- DBMS_OUTPUT.PUT_LINE('-- Task 6: Reports Demonstration');
-- DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));


---
--- --- Testing Report 1: rpt_campaign_performance ---

--- [TEST 5.1] Generating campaign performance report for 2025 (a year with data).
BEGIN
    rpt_campaign_performance(p_year => 2025);
END;
/

--- [TEST 5.2] Generating campaign performance report for 2020 (a year with no data).
BEGIN
    rpt_campaign_performance(p_year => 2020);
END;
/


---
--- --- Testing Report 2: rpt_bus_maintenance_history ---

--- [TEST 6.1] Generating maintenance history for Bus ID 15 (a bus with service records).
BEGIN
    rpt_bus_maintenance_history(p_bus_id => 15);
END;
/

--- [TEST 6.2] Generating maintenance history for a non-existent Bus ID 99999.
BEGIN
    rpt_bus_maintenance_history(p_bus_id => 99999);
END;
/


--=============================================================================
-- TASK 7: USER-DEFINED FUNCTION DEMONSTRATION
--=============================================================================

---
--- --- Testing Function: calculate_final_ticket_price ---

--- [TEST 7.1] Using the function in a query to verify a booking's total amount.
--- We will check Booking ID 4, which may have promotions.

COLUMN stored_booking_total FORMAT 99,990.00 HEADING 'Stored Total'
COLUMN calculated_booking_total FORMAT 99,990.00 HEADING 'Calculated Total'
COLUMN difference FORMAT 99,990.00 HEADING 'Difference'

SELECT
    b.booking_id,
    b.total_amount AS stored_booking_total,
    SUM(calculate_final_ticket_price(t.ticket_id)) AS calculated_booking_total,
    b.total_amount - SUM(calculate_final_ticket_price(t.ticket_id)) AS difference
FROM Booking b
JOIN BookingDetails bd ON b.booking_id = bd.booking_id
JOIN Ticket t ON bd.ticket_id = t.ticket_id
WHERE b.booking_id = 4
GROUP BY
    b.booking_id,
    b.total_amount;

CLEAR COLUMNS;

DBMS_OUTPUT.PUT_LINE('');
DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
DBMS_OUTPUT.PUT_LINE('-- Demonstration Complete');
DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
```

```generate_data.py
import os
import random
from datetime import datetime, timedelta
from faker import Faker

# --- Configuration ---
START_DATE_GLOBAL = datetime(2024, 1, 1)
END_DATE_GLOBAL = datetime(2025, 12, 31)

# Base and Transaction Counts
NUM_COMPANIES = 12
NUM_DRIVERS = 200
NUM_STAFF = 150
NUM_SHOPS = 30
NUM_SERVICES = 12
NUM_MEMBERS = 7500
NUM_CAMPAIGNS = 10
NUM_PROMOTIONS = 50
NUM_BUSES = 120
NUM_SCHEDULES = 5000
# MODIFICATION: Reduced the primary transaction drivers for a more balanced dataset.
NUM_PAYMENTS = 3000      # Lowered from 25000
NUM_BOOKINGS = 3000      # Lowered from 25000. This is the main change.
NUM_RENTAL_COLLECTIONS = 500
NUM_SERVICE_DETAILS = 800
NUM_REFUNDS = 300        # Slightly reduced to stay proportional
NUM_EXTENSIONS = 200       # Slightly reduced to stay proportional
NUM_DRIVER_LIST_ENTRIES = 5000
# MODIFICATION: Adjusted to be more realistic in proportion to service details.
NUM_STAFF_ALLOCATIONS = 1000   # Lowered from 1500

OUTPUT_FILE = "02_populate_data.sql"

# --- Valid Values ---
STAFF_ROLES = ['Counter Staff', 'Cleaner', 'Manager', 'Technician']
STAFF_STATUSES = ['Active', 'Resigned', 'On Leave']
PAYMENT_METHODS = ['Credit Card', 'Debit Card', 'Online Banking', 'E-Wallet']
TICKET_STATUSES = ['Available', 'Booked', 'Cancelled', 'Extended']
PROMOTION_TYPES = ['Percentage', 'Fixed Amount']

# --- Main Script ---
fake = Faker('en_US')

# --- Primary Key Lists ---
company_ids = list(range(1, NUM_COMPANIES + 1))
driver_ids = list(range(1, NUM_DRIVERS + 1))
staff_ids = list(range(1, NUM_STAFF + 1))
shop_ids = list(range(1, NUM_SHOPS + 1))
service_ids = list(range(1, NUM_SERVICES + 1))
member_ids = list(range(1, NUM_MEMBERS + 1))
campaign_ids = list(range(1, NUM_CAMPAIGNS + 1))
promotion_ids = list(range(1, NUM_PROMOTIONS + 1))
bus_ids = list(range(1, NUM_BUSES + 1))
schedule_ids = list(range(1, NUM_SCHEDULES + 1))
payment_ids = list(range(1, NUM_PAYMENTS + 1))
booking_ids = list(range(1, NUM_BOOKINGS + 1))
service_detail_ids = list(range(1, NUM_SERVICE_DETAILS + 1))
refund_ids = list(range(1, NUM_REFUNDS + 1))
extension_ids = list(range(1, NUM_EXTENSIONS + 1))

# --- Global Trackers for Logical Consistency ---
ticket_id_counter = 1
schedules_data = []
booked_tickets_data = []

# (The rest of the script remains exactly the same as the logically corrected version I provided previously)
# --- Main Generation Orchestrator ---
def generate_sql(f):
    f.write("-- =============================================================================\n")
    f.write(f"-- Data Population Script Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"-- Date Range: {START_DATE_GLOBAL.strftime('%Y-%m-%d')} to {END_DATE_GLOBAL.strftime('%Y-%m-%d')}\n")
    f.write("-- =============================================================================\n\n")

    print("Generating Level 0 Tables...")
    generate_companies(f); generate_drivers(f); generate_staff(f); generate_shops(f); generate_services(f); generate_members(f); generate_campaigns(f)
    print("Generating Level 1 Tables...")
    generate_promotions(f); generate_buses(f); generate_payments(f)
    print("Generating Level 2 Tables (Schedules are critical)...")
    generate_schedules(f); generate_rental_collections(f); generate_service_details(f)
    print("Generating Level 3 Tables...")
    generate_driver_lists(f); generate_staff_allocations(f)
    print("Generating Core Booking Flow (Tickets, Bookings)...")
    generate_booking_flow(f)
    print("Generating Post-Booking Transactions (Refunds, Extensions)...")
    generate_refunds(f)
    generate_extensions(f)
    print("Generating Additional Available Tickets...")
    generate_available_tickets(f, 500) # Reduced this slightly as well

# --- Helper Functions ---
def sql_string(value):
    return str(value).replace("'", "''")

def sql_date(dt_obj):
    return f"TO_DATE('{dt_obj.strftime('%Y-%m-%d %H:%M:%S')}', 'YYYY-MM-DD HH24:MI:SS')"

def get_random_date():
    days_between = (END_DATE_GLOBAL - START_DATE_GLOBAL).days
    random_days = random.randrange(days_between)
    return START_DATE_GLOBAL + timedelta(days=random_days, seconds=random.randrange(86400))

# --- Generator Functions ---
def generate_schedules(f):
    global schedules_data
    f.write("-- Data for Schedule Table\n")
    for i in schedule_ids:
        dep_time_obj = get_random_date()
        arr_time_obj = dep_time_obj + timedelta(hours=random.randint(1, 8), minutes=random.randint(0, 59))
        if arr_time_obj > END_DATE_GLOBAL: continue
        schedules_data.append({'id': i, 'departure': dep_time_obj})
        price = round(random.uniform(20.0, 150.0), 2)
        origin = fake.city(); destination = fake.city()
        while origin == destination: destination = fake.city()
        platform = f"P{random.randint(1, 20)}"
        bus_id = random.choice(bus_ids)
        f.write(f"INSERT INTO Schedule (schedule_id, departure_time, arrival_time, base_price, origin_station, destination_station, platform_no, bus_id) VALUES ({i}, {sql_date(dep_time_obj)}, {sql_date(arr_time_obj)}, {price}, '{origin}', '{destination}', '{platform}', {bus_id});\n")
    f.write("\n")

def generate_booking_flow(f):
    global ticket_id_counter, booked_tickets_data
    f.write("-- Data for Booking, Ticket, and BookingDetails Tables (Linked)\n")
    available_payment_ids = random.sample(payment_ids, NUM_BOOKINGS)
    for i in range(NUM_BOOKINGS):
        booking_id = booking_ids[i]
        selected_schedule = random.choice(schedules_data)
        departure_time = selected_schedule['departure']
        schedule_id = selected_schedule['id']
        booking_offset = timedelta(days=random.randint(1, 90), seconds=random.randint(0, 86399))
        booking_date_obj = departure_time - booking_offset
        if booking_date_obj < START_DATE_GLOBAL:
            booking_date_obj = START_DATE_GLOBAL + timedelta(seconds=1)
        member_id = random.choice(member_ids)
        payment_id = available_payment_ids.pop()
        total_amount = 0
        booking_sql = f"INSERT INTO Booking (booking_id, booking_date, total_amount, member_id, payment_id) VALUES ({booking_id}, {sql_date(booking_date_obj)}, {{total_amount}}, {member_id}, {payment_id});\n"
        num_tickets_in_booking = random.randint(1, 4)
        ticket_sqls = []; booking_details_sqls = []
        for _ in range(num_tickets_in_booking):
            seat = f"{random.randint(1, 15)}{random.choice('ABCD')}"
            status = 'Booked'
            has_promo = random.random() < 0.3
            promo_id = random.choice(promotion_ids) if has_promo else 'NULL'
            ticket_sqls.append(f"INSERT INTO Ticket (ticket_id, seat_number, status, schedule_id, promotion_id) VALUES ({ticket_id_counter}, '{seat}', '{status}', {schedule_id}, {promo_id});\n")
            booking_details_sqls.append(f"INSERT INTO BookingDetails (booking_id, ticket_id) VALUES ({booking_id}, {ticket_id_counter});\n")
            booked_tickets_data.append({'id': ticket_id_counter, 'booking_date': booking_date_obj, 'departure': departure_time})
            price = random.uniform(20.0, 150.0)
            if has_promo: price *= 0.9
            total_amount += price
            ticket_id_counter += 1
        f.write(booking_sql.format(total_amount=round(total_amount, 2)))
        f.writelines(ticket_sqls); f.writelines(booking_details_sqls)
        f.write("\n")

def generate_refunds(f):
    global booked_tickets_data
    f.write("-- Data for Refund Table\n")
    num_to_refund = min(NUM_REFUNDS, len(booked_tickets_data))
    tickets_to_refund = random.sample(booked_tickets_data, num_to_refund)
    for i in range(num_to_refund):
        refund_id = refund_ids[i]
        ticket_info = tickets_to_refund[i]
        ticket_id = ticket_info['id']
        time_diff = ticket_info['departure'] - ticket_info['booking_date']
        refund_offset = timedelta(seconds=random.randint(1, max(1, int(time_diff.total_seconds()) - 1)))
        refund_date_obj = ticket_info['booking_date'] + refund_offset
        amount = round(random.uniform(20.0, 100.0) * 0.7, 2)
        method = random.choice(PAYMENT_METHODS)
        f.write(f"INSERT INTO Refund (refund_id, refund_date, amount, refund_method, ticket_id) VALUES ({refund_id}, {sql_date(refund_date_obj)}, {amount}, '{method}', {ticket_id});\n")
    refunded_ids = {t['id'] for t in tickets_to_refund}
    booked_tickets_data = [t for t in booked_tickets_data if t['id'] not in refunded_ids]
    f.write("\n")

def generate_extensions(f):
    global booked_tickets_data
    f.write("-- Data for Extension Table\n")
    num_to_extend = min(NUM_EXTENSIONS, len(booked_tickets_data))
    tickets_to_extend = random.sample(booked_tickets_data, num_to_extend)
    for i in range(num_to_extend):
        extension_id = extension_ids[i]
        ticket_info = tickets_to_extend[i]
        ticket_id = ticket_info['id']
        time_diff = ticket_info['departure'] - ticket_info['booking_date']
        extension_offset = timedelta(seconds=random.randint(1, max(1, int(time_diff.total_seconds()) - 1)))
        extension_date_obj = ticket_info['booking_date'] + extension_offset
        amount = round(random.uniform(20.0, 100.0) + 5.0, 2)
        method = random.choice(PAYMENT_METHODS)
        f.write(f"INSERT INTO Extension (extension_id, extension_date, amount, extension_method, ticket_id) VALUES ({extension_id}, {sql_date(extension_date_obj)}, {amount}, '{method}', {ticket_id});\n")
    f.write("\n")

def generate_available_tickets(f, count):
    global ticket_id_counter
    f.write("-- Data for additional 'Available' Tickets\n")
    for _ in range(count):
        seat = f"{random.randint(1, 15)}{random.choice('ABCD')}"
        status = 'Available'
        schedule_id = random.choice(schedule_ids)
        promo_id = 'NULL'
        f.write(f"INSERT INTO Ticket (ticket_id, seat_number, status, schedule_id, promotion_id) VALUES ({ticket_id_counter}, '{seat}', '{status}', {schedule_id}, {promo_id});\n")
        ticket_id_counter += 1
    f.write("\n")

def generate_companies(f):
    f.write("-- Data for Company Table\n")
    for i in company_ids: f.write(f"INSERT INTO Company (company_id, name) VALUES ({i}, '{sql_string(fake.company())}');\n")
    f.write("\n")
def generate_drivers(f):
    f.write("-- Data for Driver Table\n")
    for i in driver_ids: f.write(f"INSERT INTO Driver (driver_id, name, license_no) VALUES ({i}, '{sql_string(fake.name())}', '{fake.bothify(text='?#######??').upper()}');\n")
    f.write("\n")
def generate_staff(f):
    f.write("-- Data for Staff Table\n")
    for i in staff_ids: f.write(f"INSERT INTO Staff (staff_id, name, role, email, contact_no, employment_date, status) VALUES ({i}, '{sql_string(fake.name())}', '{random.choice(STAFF_ROLES)}', '{fake.unique.email()}', '{fake.phone_number()}', {sql_date(get_random_date())}, '{random.choice(STAFF_STATUSES)}');\n")
    f.write("\n")
def generate_shops(f):
    f.write("-- Data for Shop Table\n")
    for i in shop_ids: f.write(f"INSERT INTO Shop (shop_id, shop_name, location_code) VALUES ({i}, '{sql_string(fake.company() + ' Mart')}', '{fake.unique.bothify(text='L?-###').upper()}');\n")
    f.write("\n")
def generate_services(f):
    f.write("-- Data for Service Table\n")
    service_names = ['Bus Wash', 'Tyre Replacement', 'Engine Overhaul', 'Brake System Repair', 'Oil Change', 'AC Service', 'Full Inspection']
    for i in service_ids: f.write(f"INSERT INTO Service (service_id, service_name, standard_cost) VALUES ({i}, '{random.choice(service_names)}', {round(random.uniform(50.0, 2000.0), 2)});\n")
    f.write("\n")
def generate_members(f):
    f.write("-- Data for Member Table\n")
    for i in member_ids: f.write(f"INSERT INTO Member (member_id, name, email, contact_no, registration_date) VALUES ({i}, '{sql_string(fake.name())}', '{fake.unique.email()}', '{fake.phone_number()}', {sql_date(get_random_date())});\n")
    f.write("\n")
def generate_campaigns(f):
    f.write("-- Data for Campaign Table\n")
    for i in campaign_ids:
        start_date = get_random_date()
        end_date = start_date + timedelta(days=random.randint(30, 90))
        if end_date > END_DATE_GLOBAL: end_date = END_DATE_GLOBAL
        f.write(f"INSERT INTO Campaign (campaign_id, campaign_name, start_date, end_date) VALUES ({i}, '{sql_string(fake.catch_phrase())} Campaign', {sql_date(start_date)}, {sql_date(end_date)});\n")
    f.write("\n")
def generate_promotions(f):
    f.write("-- Data for Promotion Table\n")
    for i in promotion_ids:
        start_date = get_random_date()
        end_date = start_date + timedelta(days=random.randint(15, 60))
        if end_date > END_DATE_GLOBAL: end_date = END_DATE_GLOBAL
        disc_type = random.choice(PROMOTION_TYPES)
        disc_val = round(random.uniform(5, 20), 2) if disc_type == 'Percentage' else round(random.uniform(1, 10), 2)
        f.write(f"INSERT INTO Promotion (promotion_id, promotion_name, description, discount_type, discount_value, valid_from, valid_until, campaign_id) VALUES ({i}, '{sql_string(fake.bs().title())}', '{sql_string(fake.sentence(nb_words=8))}', '{disc_type}', {disc_val}, {sql_date(start_date)}, {sql_date(end_date)}, {random.choice(campaign_ids)});\n")
    f.write("\n")
def generate_buses(f):
    f.write("-- Data for Bus Table\n")
    for i in bus_ids: f.write(f"INSERT INTO Bus (bus_id, plate_number, capacity, company_id) VALUES ({i}, '{fake.unique.license_plate()}', {random.randint(40, 55)}, {random.choice(company_ids)});\n")
    f.write("\n")
def generate_payments(f):
    f.write("-- Data for Payment Table\n")
    for i in payment_ids: f.write(f"INSERT INTO Payment (payment_id, payment_date, amount, payment_method) VALUES ({i}, {sql_date(get_random_date())}, {round(random.uniform(15.0, 250.0), 2)}, '{random.choice(PAYMENT_METHODS)}');\n")
    f.write("\n")
def generate_rental_collections(f):
    f.write("-- Data for RentalCollection Table\n")
    for i in range(1, NUM_RENTAL_COLLECTIONS + 1):
        rental_date = get_random_date()
        coll_date = rental_date + timedelta(days=random.randint(0, 5))
        if coll_date > END_DATE_GLOBAL: coll_date = END_DATE_GLOBAL
        f.write(f"INSERT INTO RentalCollection (rental_id, rental_date, amount, collection_date, shop_id, staff_id) VALUES ({i}, {sql_date(rental_date)}, {round(random.uniform(500.0, 3000.0), 2)}, {sql_date(coll_date)}, {random.choice(shop_ids)}, {random.choice(staff_ids)});\n")
    f.write("\n")
def generate_service_details(f):
    f.write("-- Data for ServiceDetails Table\n")
    for i in service_detail_ids: f.write(f"INSERT INTO ServiceDetails (service_transaction_id, service_date, actual_cost, service_id, bus_id) VALUES ({i}, {sql_date(get_random_date())}, {round(random.uniform(100.0, 5000.0), 2)}, {random.choice(service_ids)}, {random.choice(bus_ids)});\n")
    f.write("\n")
def generate_driver_lists(f):
    f.write("-- Data for DriverList (Bridge) Table\n")
    pairs = set()
    attempts = 0
    while len(pairs) < NUM_DRIVER_LIST_ENTRIES and attempts < NUM_DRIVER_LIST_ENTRIES * 5:
        pair = (random.choice(schedule_ids), random.choice(driver_ids))
        if pair not in pairs:
            f.write(f"INSERT INTO DriverList (schedule_id, driver_id) VALUES ({pair[0]}, {pair[1]});\n")
            pairs.add(pair)
        attempts += 1
    f.write("\n")
def generate_staff_allocations(f):
    f.write("-- Data for StaffAllocation (Bridge) Table\n")
    pairs = set()
    attempts = 0
    while len(pairs) < NUM_STAFF_ALLOCATIONS and attempts < NUM_STAFF_ALLOCATIONS * 5:
        pair = (random.choice(service_detail_ids), random.choice(staff_ids))
        if pair not in pairs:
            f.write(f"INSERT INTO StaffAllocation (service_transaction_id, staff_id, role) VALUES ({pair[0]}, {pair[1]}, '{random.choice(['Technician', 'Cleaner'])}');\n")
            pairs.add(pair)
        attempts += 1
    f.write("\n")

# --- Script Execution ---
if __name__ == "__main__":
    if os.path.exists(OUTPUT_FILE):
        os.remove(OUTPUT_FILE)
    with open(OUTPUT_FILE, 'w') as f:
        generate_sql(f)
    print(f"Successfully generated {OUTPUT_FILE} with logically consistent chronological data.")
```

