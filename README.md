### **1. Business Rules and Assumptions**

This section translates the assignment requirements and the lecturer's sketch into formal rules.

1.  **Core Entities:** The system will manage `Members`, `Companies`, `Buses`, `Drivers`, `Staff`, and `Shops` as distinct entities.
2.  **Booking and Ticketing:** A `Booking` is the process a `Member` undertakes to reserve a seat. A successful booking results in the creation of one or more `Tickets`. For simplicity and normalization, we will model this as a direct relationship between `Member` and `Ticket`, where the `Ticket` table represents the successful booking.
3.  **Ticket Management:** A `Ticket` can have its status changed to 'Cancelled' or 'Extended' based on business rules (e.g., the 2-day advance notice). Events like `Refund` and `Extension` charges will be managed by procedures acting on the `Ticket` table.
4.  **Schedules and Operations:** A `Schedule` represents a single trip. It follows a `Route`, uses one `Bus`, and departs from a `Platform`.
5.  **Driver Allocation (Many-to-Many):** A single `Schedule` (especially a long one) can have multiple `Drivers` assigned to it (e.g., for shift changes). A `Driver` can be assigned to many different `Schedules`. This requires a **bridge table**, which we will call **`DriverList`** as per the sketch.
6.  **Promotions (Many-to-Many):** A `Promotion` can be valid for many `Schedules`, and a `Schedule` can be eligible for many promotions. This requires a **bridge table**.
7.  **Maintenance (One-to-Many):** A `Bus` can undergo many maintenance services. Each event is logged. We will have a lookup table for `Service` types and a transaction table called **`ServiceDetails`** to log the work done.
8.  **Staff and Shops:** The station manages its own `Staff` and the `Shops` it rents out. We will track staff assignments and rental payment collections.

---

### **2. Entity & Attribute Breakdown (The Tables)**

Here is the professional interpretation of the lecturer's sketch, organized into a list of normalized tables.

*   **Table: `Member`**
    *   **Purpose:** Stores registered customer information.
    *   **Attributes:** `member_id` (PK), `name`, `email`, `contact_no`, `registration_date`.

*   **Table: `Company`**
    *   **Purpose:** Stores bus company details.
    *   **Attributes:** `company_id` (PK), `name`, `contact_person`.

*   **Table: `Driver`**
    *   **Purpose:** Stores individual driver details.
    *   **Attributes:** `driver_id` (PK), `name`, `license_no`, `company_id` (FK).

*   **Table: `Bus`**
    *   **Purpose:** Manages the physical bus fleet.
    *   **Attributes:** `bus_id` (PK), `plate_number`, `capacity`, `status`, `company_id` (FK).

*   **Table: `Route`**
    *   **Purpose:** Defines origin-destination pairs. Essential for 3NF.
    *   **Attributes:** `route_id` (PK), `origin`, `destination`.

*   **Table: `Platform`**
    *   **Purpose:** Manages the physical bus platforms.
    *   **Attributes:** `platform_no` (PK), `location_desc`, `status`.

*   **Table: `Schedule`**
    *   **Purpose:** Represents a single, specific bus trip.
    *   **Attributes:** `schedule_id` (PK), `departure_time`, `arrival_time`, `price`, `bus_id` (FK), `route_id` (FK), `platform_no` (FK).

*   **Table: `DriverList` (Bridge Table)**
    *   **Purpose:** Resolves the Many-to-Many relationship between `Schedule` and `Driver`.
    *   **Attributes:** `schedule_id` (PK, FK), `driver_id` (PK, FK), `shift_assignment` (e.g., 'First Leg').

*   **Table: `Ticket`**
    *   **Purpose:** The central transaction table, representing a confirmed booking.
    *   **Attributes:** `ticket_id` (PK), `purchase_date`, `final_price`, `status` ('Confirmed', 'Cancelled', 'Extended'), `member_id` (FK), `schedule_id` (FK), `promotion_id` (FK, optional).

*   **Table: `Campaign` & `Promotion`**
    *   **Purpose:** Manages marketing efforts.
    *   **`Campaign` Attributes:** `campaign_id` (PK), `campaign_name`, `start_date`, `end_date`.
    *   **`Promotion` Attributes:** `promotion_id` (PK), `promo_code`, `discount_type`, `discount_value`, `campaign_id` (FK).

*   **Table: `Promotion_Schedule` (Bridge Table)**
    *   **Purpose:** Resolves the Many-to-Many relationship between `Promotion` and `Schedule`.
    *   **Attributes:** `promotion_id` (PK, FK), `schedule_id` (PK, FK).

*   **Table: `Service`**
    *   **Purpose:** A lookup table for maintenance types as per the sketch.
    *   **Attributes:** `service_id` (PK), `service_name` ('Repair', 'Tyre', 'Wash'), `description`.

*   **Table: `ServiceDetails` (Transaction Table)**
    *   **Purpose:** Logs a specific maintenance service performed on a bus.
    *   **Attributes:** `service_transaction_id` (PK), `log_date`, `cost`, `remarks`, `bus_id` (FK), `service_id` (FK).

*   **Table: `Staff` & `Shop`**
    *   **Purpose:** Manages internal staff and rental shops.
    *   **`Staff` Attributes:** `staff_id` (PK), `name`, `role` ('Counter Staff', 'Cleaner').
    *   **`Shop` Attributes:** `shop_id` (PK), `location_code`, `shop_type` ('Stall', 'Shop Lot').

*   **Table: `RentalCollection` (Transaction Table)**
    *   **Purpose:** Logs rental payments collected from shops.
    *   **Attributes:** `rental_collection_id` (PK), `payment_date`, `amount`, `month_covered`, `shop_id` (FK).

---

### **3. Relationships (Foreign Keys)**

This is your guide for drawing the connections in your ERD.

| Child Table / Bridge Table | Foreign Key Column(s) | Parent Table(s) | Relationship |
| :--- | :--- | :--- | :--- |
| **Driver** | `company_id` | `Company` | One-to-Many |
| **Bus** | `company_id` | `Company` | One-to-Many |
| **Schedule** | `bus_id` | `Bus` | One-to-Many |
| **Schedule** | `route_id` | `Route` | One-to-Many |
| **Schedule** | `platform_no`| `Platform` | One-to-Many |
| **DriverList** | `schedule_id`, `driver_id` | `Schedule`, `Driver` | Many-to-Many |
| **Ticket** | `member_id` | `Member` | One-to-Many |
| **Ticket** | `schedule_id` | `Schedule` | One-to-Many |
| **Ticket** | `promotion_id`| `Promotion` | One-to-Many (Opt.)|
| **Promotion** | `campaign_id`| `Campaign` | One-to-Many |
| **Promotion_Schedule**| `promotion_id`, `schedule_id` | `Promotion`, `Schedule` | Many-to-Many |
| **ServiceDetails** | `bus_id` | `Bus` | One-to-Many |
| **ServiceDetails** | `service_id` | `Service` | One-to-Many |
| **RentalCollection** | `shop_id` | `Shop` | One-to-Many |

You now have a complete, structured blueprint based on your lecturer's guidance, refined with professional design principles. Use this to draw your ERD and then proceed to write the DDL.
