### **1. Business Rules and Assumptions (For your Report)**

1.  **Company & Assets:** A `Company` is a distinct legal entity. It can own many `Buses` and employ many `Drivers`. Each `Bus` and `Driver` must be associated with exactly one `Company`. (One-to-Many Relationship)
2.  **Operations:** A `Schedule` is a specific trip that follows a predefined `Route` (origin/destination pair). Each schedule is operated by one `Bus` and one `Driver`.
3.  **Members & Transactions:** A `Member` is a registered customer. A member can purchase many `Tickets` over time. Each `Ticket` belongs to only one member. (One-to-Many Relationship)
4.  **Promotions:** A `Campaign` is a marketing event containing multiple `Promotions`. A `Promotion` can be valid for many different `Schedules`, and a `Schedule` may be eligible for multiple promotions. (Many-to-Many Relationship)
5.  **Assumption on Ticket Promotions:** A single `Ticket` can have, at most, one `Promotion` applied during purchase. The relationship is optional.
6.  **Maintenance:** A `Bus` can undergo many maintenance services over its lifetime. Each service event is recorded as a unique `Maintenance_Log` entry. (One-to-Many Relationship)

---

### **2. Entity & Attribute Breakdown (The Tables)**

Here are your tables with their columns and primary keys defined.

*   **Table: `Member`**
    *   `member_id` (PK, NUMBER) - Unique ID for the member.
    *   `name` (VARCHAR2(100))
    *   `email` (VARCHAR2(100))
    *   `contact_no` (VARCHAR2(20))
    *   `registration_date` (DATE)

*   **Table: `Company`**
    *   `company_id` (PK, NUMBER) - Unique ID for the bus company.
    *   `name` (VARCHAR2(100))

*   **Table: `Driver`**
    *   `driver_id` (PK, NUMBER) - Unique ID for the driver.
    *   `name` (VARCHAR2(100))
    *   `license_no` (VARCHAR2(50))
    *   `company_id` (FK, NUMBER)

*   **Table: `Bus`**
    *   `bus_id` (PK, NUMBER) - Unique ID for the bus.
    *   `plate_number` (VARCHAR2(15))
    *   `capacity` (NUMBER(3))
    *   `status` (VARCHAR2(20))
    *   `company_id` (FK, NUMBER)

*   **Table: `Route`**
    *   `route_id` (PK, NUMBER) - Unique ID for the route.
    *   `origin` (VARCHAR2(100))
    *   `destination` (VARCHAR2(100))

*   **Table: `Schedule`**
    *   `schedule_id` (PK, NUMBER) - Unique ID for a specific trip.
    *   `departure_time` (DATE)
    *   `arrival_time` (DATE)
    *   `price` (NUMBER(10, 2))
    *   `bus_id` (FK, NUMBER)
    *   `driver_id` (FK, NUMBER)
    *   `route_id` (FK, NUMBER)

*   **Table: `Campaign`**
    *   `campaign_id` (PK, NUMBER) - Unique ID for the campaign.
    *   `campaign_name` (VARCHAR2(100))
    *   `start_date` (DATE)
    *   `end_date` (DATE)

*   **Table: `Promotion`**
    *   `promotion_id` (PK, NUMBER) - Unique ID for the promotion.
    *   `promo_code` (VARCHAR2(20))
    *   `discount_type` (VARCHAR2(20))
    *   `discount_value` (NUMBER(10, 2))
    *   `campaign_id` (FK, NUMBER)

*   **Table: `Ticket`**
    *   `ticket_id` (PK, NUMBER) - Unique ID for the ticket transaction.
    *   `purchase_date` (DATE)
    *   `final_price` (NUMBER(10, 2))
    *   `status` (VARCHAR2(20))
    *   `member_id` (FK, NUMBER)
    *   `schedule_id` (FK, NUMBER)
    *   `promotion_id` (FK, NUMBER)

*   **Table: `Promotion_Schedule` (Bridge Table)**
    *   `promotion_id` (PK, FK, NUMBER) - Composite primary key component.
    *   `schedule_id` (PK, FK, NUMBER) - Composite primary key component.

*   **Table: `Maintenance_Log`**
    *   `log_id` (PK, NUMBER) - Unique ID for the maintenance event.
    *   `log_date` (DATE)
    *   `service_type` (VARCHAR2(50))
    *   `cost` (NUMBER(10, 2))
    *   `bus_id` (FK, NUMBER)

---

### **3. Relationships (The Foreign Keys)**

This section explicitly lists the connections you need to draw.

| Child Table        | Foreign Key Column | Parent Table      | Relationship Type |
| ------------------ | ------------------ | ----------------- | ----------------- |
| **Driver**         | `company_id`       | `Company`         | One-to-Many       |
| **Bus**            | `company_id`       | `Company`         | One-to-Many       |
| **Schedule**       | `bus_id`           | `Bus`             | One-to-Many       |
| **Schedule**       | `driver_id`        | `Driver`          | One-to-Many       |
| **Schedule**       | `route_id`         | `Route`           | One-to-Many       |
| **Promotion**      | `campaign_id`      | `Campaign`        | One-to-Many       |
| **Ticket**         | `member_id`        | `Member`          | One-to-Many       |
| **Ticket**         | `schedule_id`      | `Schedule`        | One-to-Many       |
| **Ticket**         | `promotion_id`     | `Promotion`       | One-to-Many (Opt) |
| **Maintenance_Log**| `bus_id`           | `Bus`             | One-to-Many       |
| **Promotion_Schedule** | `promotion_id`   | `Promotion`       | Many-to-Many      |
| **Promotion_Schedule** | `schedule_id`    | `Schedule`        | Many-to-Many      |

You now have all the necessary, structured information to create a complete and accurate ERD that meets the assignment's requirements.
