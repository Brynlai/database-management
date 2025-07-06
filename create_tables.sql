CREATE TABLE Member (
    member_id           NUMBER          CONSTRAINT pk_member PRIMARY KEY,
    name                VARCHAR2(100)   NOT NULL,
    email               VARCHAR2(100)   NOT NULL,
    contact_no          VARCHAR2(20),
    registration_date   DATE            DEFAULT SYSDATE,
    -- Named UNIQUE constraint for clarity in error messages
    CONSTRAINT uk_member_email UNIQUE (email)
);

CREATE TABLE Company (
    company_id          NUMBER          CONSTRAINT pk_company PRIMARY KEY,
    name                VARCHAR2(100)   NOT NULL,
    CONSTRAINT uk_company_name UNIQUE (name)
);

CREATE TABLE Driver (
    driver_id           NUMBER          CONSTRAINT pk_driver PRIMARY KEY,
    name                VARCHAR2(100)   NOT NULL,
    license_no          VARCHAR2(50)    NOT NULL,
    company_id          NUMBER,
    CONSTRAINT uk_driver_license UNIQUE (license_no),
    CONSTRAINT fk_driver_company FOREIGN KEY (company_id) REFERENCES Company(company_id)
);

CREATE TABLE Bus (
    bus_id              NUMBER          CONSTRAINT pk_bus PRIMARY KEY,
    plate_number        VARCHAR2(15)    NOT NULL,
    capacity            NUMBER(3)       NOT NULL,
    status              VARCHAR2(20)    DEFAULT 'Active' NOT NULL,
    company_id          NUMBER,
    CONSTRAINT uk_bus_plate UNIQUE (plate_number),
    CONSTRAINT chk_bus_capacity CHECK (capacity > 0),
    CONSTRAINT chk_bus_status CHECK (status IN ('Active', 'Maintenance')),
    CONSTRAINT fk_bus_company FOREIGN KEY (company_id) REFERENCES Company(company_id)
);

CREATE TABLE Route (
    route_id            NUMBER          CONSTRAINT pk_route PRIMARY KEY,
    origin              VARCHAR2(100)   NOT NULL,
    destination         VARCHAR2(100)   NOT NULL
);

CREATE TABLE Schedule (
    schedule_id         NUMBER          CONSTRAINT pk_schedule PRIMARY KEY,
    departure_time      DATE            NOT NULL,
    arrival_time        DATE            NOT NULL,
    price               NUMBER(10, 2)   NOT NULL,
    bus_id              NUMBER,
    driver_id           NUMBER,
    route_id            NUMBER,
    CONSTRAINT chk_schedule_price CHECK (price > 0),
    CONSTRAINT chk_schedule_times CHECK (arrival_time > departure_time),
    CONSTRAINT fk_schedule_bus FOREIGN KEY (bus_id) REFERENCES Bus(bus_id),
    CONSTRAINT fk_schedule_driver FOREIGN KEY (driver_id) REFERENCES Driver(driver_id),
    CONSTRAINT fk_schedule_route FOREIGN KEY (route_id) REFERENCES Route(route_id)
);

CREATE TABLE Campaign (
    campaign_id         NUMBER          CONSTRAINT pk_campaign PRIMARY KEY,
    campaign_name       VARCHAR2(100)   NOT NULL,
    start_date          DATE            NOT NULL,
    end_date            DATE            NOT NULL,
    CONSTRAINT chk_campaign_dates CHECK (end_date >= start_date)
);

CREATE TABLE Promotion (
    promotion_id        NUMBER          CONSTRAINT pk_promotion PRIMARY KEY,
    promo_code          VARCHAR2(20)    NOT NULL,
    discount_type       VARCHAR2(20)    NOT NULL,
    discount_value      NUMBER(10, 2)   NOT NULL,
    campaign_id         NUMBER,
    CONSTRAINT uk_promotion_code UNIQUE (promo_code),
    CONSTRAINT chk_promotion_type CHECK (discount_type IN ('Percentage', 'Fixed')),
    CONSTRAINT fk_promotion_campaign FOREIGN KEY (campaign_id) REFERENCES Campaign(campaign_id)
);

CREATE TABLE Ticket (
    ticket_id           NUMBER          CONSTRAINT pk_ticket PRIMARY KEY,
    purchase_date       DATE            DEFAULT SYSDATE,
    final_price         NUMBER(10, 2)   NOT NULL,
    status              VARCHAR2(20)    DEFAULT 'Confirmed' NOT NULL,
    member_id           NUMBER          NOT NULL,
    schedule_id         NUMBER          NOT NULL,
    promotion_id        NUMBER, -- Can be null if no promo was used
    CONSTRAINT chk_ticket_status CHECK (status IN ('Confirmed', 'Cancelled', 'Extended')),
    CONSTRAINT fk_ticket_member FOREIGN KEY (member_id) REFERENCES Member(member_id),
    CONSTRAINT fk_ticket_schedule FOREIGN KEY (schedule_id) REFERENCES Schedule(schedule_id),
    -- ON DELETE SET NULL: If a promotion is deleted, the ticket history is preserved
    -- without the promo link, rather than deleting the ticket or causing an error.
    CONSTRAINT fk_ticket_promotion FOREIGN KEY (promotion_id) REFERENCES Promotion(promotion_id) ON DELETE SET NULL
);

CREATE TABLE Promotion_Schedule (
    promotion_id        NUMBER,
    schedule_id         NUMBER,
    -- ON DELETE CASCADE: If a schedule or promotion is deleted, these links are meaningless and should be removed automatically.
    CONSTRAINT fk_ps_promotion FOREIGN KEY (promotion_id) REFERENCES Promotion(promotion_id) ON DELETE CASCADE,
    CONSTRAINT fk_ps_schedule FOREIGN KEY (schedule_id) REFERENCES Schedule(schedule_id) ON DELETE CASCADE,
    -- Composite primary key to ensure a promo can only be linked to a schedule once.
    CONSTRAINT pk_promotion_schedule PRIMARY KEY (promotion_id, schedule_id)
);

CREATE TABLE Maintenance_Log (
    log_id              NUMBER          CONSTRAINT pk_maintenance_log PRIMARY KEY,
    log_date            DATE            DEFAULT SYSDATE,
    service_type        VARCHAR2(50)    NOT NULL,
    cost                NUMBER(10, 2),
    bus_id              NUMBER          NOT NULL,
    CONSTRAINT chk_maintenance_type CHECK (service_type IN ('Repair', 'Tyre', 'Wash', 'Maintenance')),
    CONSTRAINT fk_maintenance_bus FOREIGN KEY (bus_id) REFERENCES Bus(bus_id)
);
​
COMMIT;
