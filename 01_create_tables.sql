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
DROP FUNCTION calculate_final_ticket_price;

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
DROP TABLE Staff_Audit_Log;
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
DROP SEQUENCE staff_audit_log_seq;

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