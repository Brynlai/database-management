-- =============================================================================
-- BMCS3183 Advanced Database Management
-- Project: Bus Station Management System
-- Master DDL Script
--
-- This script creates all tables based on the provided ERD and DBDL.
-- It is designed to be run once to set up a clean database schema.
-- =============================================================================

-- Section 1: Schema Cleanup
-- -----------------------------------------------------------------------------
-- This section drops all tables in the reverse order of creation to avoid
-- foreign key constraint errors. This ensures a clean slate for every run.
PROMPT Dropping existing tables...

BEGIN EXECUTE IMMEDIATE 'DROP TABLE BookingDetails'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Refund'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Extension'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Ticket'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Booking'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Payment'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Member'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DriverList'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Driver'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Schedule'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ServiceDetails'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Bus'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Company'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Service'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE StaffAllocation'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE RentalCollection'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Staff'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Shop'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Promotion'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Campaign'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

-- Section 2: Create Tables (DDL)
-- -----------------------------------------------------------------------------
-- Tables are created in an order that respects foreign key dependencies.
-- Tables without foreign keys are created first.
PROMPT Creating tables...

-- Independent Entities (Group 1)
CREATE TABLE Member (
    member_id           NUMBER          CONSTRAINT pk_member PRIMARY KEY,
    name                VARCHAR2(100)   NOT NULL,
    email               VARCHAR2(100)   NOT NULL,
    contact_no          VARCHAR2(20),
    registration_date   DATE
);

CREATE TABLE Payment (
    payment_id          NUMBER          CONSTRAINT pk_payment PRIMARY KEY,
    payment_date        DATE            NOT NULL,
    amount              NUMBER(10, 2)   NOT NULL,
    payment_method      VARCHAR2(50)
);

CREATE TABLE Driver (
    driver_id           NUMBER          CONSTRAINT pk_driver PRIMARY KEY,
    name                VARCHAR2(100)   NOT NULL,
    license_no          VARCHAR2(50)    NOT NULL
);

CREATE TABLE Company (
    company_id          NUMBER          CONSTRAINT pk_company PRIMARY KEY,
    name                VARCHAR2(100)   NOT NULL
);

CREATE TABLE Service (
    service_id          NUMBER          CONSTRAINT pk_service PRIMARY KEY,
    service_name        VARCHAR2(100)   NOT NULL,
    standard_cost       NUMBER(10, 2)
);

CREATE TABLE Staff (
    staff_id            NUMBER          CONSTRAINT pk_staff PRIMARY KEY,
    name                VARCHAR2(100)   NOT NULL,
    role                VARCHAR2(50),
    email               VARCHAR2(100),
    contact_no          VARCHAR2(20),
    employment_date     DATE,
    status              VARCHAR2(20)
);

CREATE TABLE Shop (
    shop_id             NUMBER          CONSTRAINT pk_shop PRIMARY KEY,
    shop_name           VARCHAR2(100)   NOT NULL,
    location_code       VARCHAR2(20)
);

CREATE TABLE Campaign (
    campaign_id         NUMBER          CONSTRAINT pk_campaign PRIMARY KEY,
    campaign_name       VARCHAR2(100)   NOT NULL,
    start_date          DATE,
    end_date            DATE
);

-- Dependent Entities (Group 2)
CREATE TABLE Bus (
    bus_id              NUMBER          CONSTRAINT pk_bus PRIMARY KEY,
    plate_number        VARCHAR2(15)    NOT NULL,
    capacity            NUMBER(3),
    company_id          NUMBER,
    CONSTRAINT fk_bus_company FOREIGN KEY (company_id) REFERENCES Company(company_id)
);

CREATE TABLE Promotion (
    promotion_id        NUMBER          CONSTRAINT pk_promotion PRIMARY KEY,
    promotion_name      VARCHAR2(100)   NOT NULL,
    description         VARCHAR2(255),
    discount_type       VARCHAR2(50),
    discount_value      NUMBER(10, 2),
    applies_to          VARCHAR2(50),
    valid_from          DATE,
    valid_until         DATE,
    condition           VARCHAR2(255),
    campaign_id         NUMBER,
    CONSTRAINT fk_promo_campaign FOREIGN KEY (campaign_id) REFERENCES Campaign(campaign_id)
);

CREATE TABLE RentalCollection (
    rental_id           NUMBER          CONSTRAINT pk_rentalcollection PRIMARY KEY,
    rental_date         DATE,
    amount              NUMBER(10, 2),
    collection_date     DATE,
    rental_method       VARCHAR2(50),
    remark              VARCHAR2(255),
    shop_id             NUMBER,
    staff_id            NUMBER,
    CONSTRAINT fk_rental_shop FOREIGN KEY (shop_id) REFERENCES Shop(shop_id),
    CONSTRAINT fk_rental_staff FOREIGN KEY (staff_id) REFERENCES Staff(staff_id)
);


-- Dependent Entities (Group 3)
CREATE TABLE Schedule (
    schedule_id         NUMBER          CONSTRAINT pk_schedule PRIMARY KEY,
    departure_time      DATE            NOT NULL,
    arrival_time        DATE,
    base_price          NUMBER(10, 2),
    origin_station      VARCHAR2(100),
    destination_station VARCHAR2(100),
    platform_no         VARCHAR2(10),
    bus_id              NUMBER,
    CONSTRAINT fk_schedule_bus FOREIGN KEY (bus_id) REFERENCES Bus(bus_id)
);

CREATE TABLE ServiceDetails (
    service_transaction_id NUMBER       CONSTRAINT pk_servicedetails PRIMARY KEY,
    service_date        DATE,
    actual_cost         NUMBER(10, 2),
    remarks             VARCHAR2(255),
    service_id          NUMBER,
    bus_id              NUMBER,
    CONSTRAINT fk_servicedetails_service FOREIGN KEY (service_id) REFERENCES Service(service_id),
    CONSTRAINT fk_servicedetails_bus FOREIGN KEY (bus_id) REFERENCES Bus(bus_id)
);

CREATE TABLE StaffAllocation (
    service_transaction_id NUMBER,
    staff_id            NUMBER,
    role                VARCHAR2(50),
    start_time          DATE,
    end_time            DATE,
    CONSTRAINT pk_staffallocation PRIMARY KEY (service_transaction_id, staff_id),
    CONSTRAINT fk_staffalloc_staff FOREIGN KEY (staff_id) REFERENCES Staff(staff_id)
);


-- Dependent Entities (Group 4)
CREATE TABLE DriverList (
    schedule_id         NUMBER,
    driver_id           NUMBER,
    assignment_notes    VARCHAR2(255),
    CONSTRAINT pk_driverlist PRIMARY KEY (schedule_id, driver_id),
    CONSTRAINT fk_driverlist_schedule FOREIGN KEY (schedule_id) REFERENCES Schedule(schedule_id),
    CONSTRAINT fk_driverlist_driver FOREIGN KEY (driver_id) REFERENCES Driver(driver_id)
);

CREATE TABLE Ticket (
    ticket_id           NUMBER          CONSTRAINT pk_ticket PRIMARY KEY,
    seat_number         VARCHAR2(10),
    status              VARCHAR2(20),
    schedule_id         NUMBER,
    CONSTRAINT fk_ticket_schedule FOREIGN KEY (schedule_id) REFERENCES Schedule(schedule_id)
);

CREATE TABLE Booking (
    booking_id          NUMBER          CONSTRAINT pk_booking PRIMARY KEY,
    booking_date        DATE,
    total_amount        NUMBER(10, 2),
    member_id           NUMBER,
    payment_id          NUMBER,
    CONSTRAINT fk_booking_member FOREIGN KEY (member_id) REFERENCES Member(member_id),
    CONSTRAINT fk_booking_payment FOREIGN KEY (payment_id) REFERENCES Payment(payment_id)
);


-- Dependent Entities (Group 5 - Final Layer)
CREATE TABLE BookingDetails (
    booking_id          NUMBER,
    ticket_id           NUMBER,
    CONSTRAINT pk_bookingdetails PRIMARY KEY (booking_id, ticket_id),
    CONSTRAINT fk_bookingdetails_booking FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    CONSTRAINT fk_bookingdetails_ticket FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id)
);

CREATE TABLE Refund (
    refund_id           NUMBER          CONSTRAINT pk_refund PRIMARY KEY,
    refund_date         DATE,
    amount              NUMBER(10, 2),
    refund_method       VARCHAR2(50),
    ticket_id           NUMBER,
    CONSTRAINT fk_refund_ticket FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id)
);

CREATE TABLE Extension (
    extension_id        NUMBER          CONSTRAINT pk_extension PRIMARY KEY,
    extension_date      DATE,
    amount              NUMBER(10, 2),
    extension_method    VARCHAR2(50),
    ticket_id           NUMBER,
    CONSTRAINT fk_extension_ticket FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id)
);


-- Section 3: Commit Transaction
-- -----------------------------------------------------------------------------
-- This saves all the table creation statements to the database.
COMMIT;

PROMPT All tables created successfully based on the provided schema.
