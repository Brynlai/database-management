
### **1. Business Rules and Assumptions (For your Report)**

This section formalizes the logic from your lecturer's diagram and the assignment requirements.

1.  **Booking & Ticketing Process:** A `Member` initiates a `Booking`. A `Booking` acts as a "shopping cart" or "order" that can contain multiple `Tickets`. The `BookingDetails` table serves as a bridge, linking each individual `Ticket` to its parent `Booking`.
2.  **Payment & Transactions:** Every `Booking` must be associated with a single `Payment` transaction to be confirmed. We assume a `Payment` table to track this. The assignment also requires tracking `Refund` and `Extension` events, which will be modeled as their own tables linked to the original `Ticket` to maintain a clear audit trail.
3.  **Scheduling & Driver Allocation:** A `Schedule` represents a single trip following a specific `Route`. Critically, a `Schedule` can be operated by **one or more** `Drivers` (to allow for driver swaps on long routes). This many-to-many relationship is resolved by the `DriverList` bridge table.
4.  **Promotions:** A `Campaign` contains one or more `Promotions`. These promotions are made available on specific schedules, creating a many-to-many relationship that is not explicitly shown in the diagram but is required for the system to function. We will use a `Promotion_Schedule` bridge table for this.
5.  **Maintenance & Services:** A `Service` table will define the *types* of maintenance available (e.g., 'Tyre Replace', 'Wash'). The `ServiceDetails` table will act as a log, recording *when* a specific `Service` was performed on a specific `Bus`.
6.  **Staff & Facilities Management:** `Staff` are managed separately from `Drivers`. `StaffAllocation` will be a bridge table to assign staff to specific tasks or locations (e.g., shifts on a `Platform`). `Shop` entities are managed for rental, with `RentalCollection` logging the rental payments.

---

### **2. Entity & Attribute Breakdown (The Tables)**

Here are the tables based on your diagram, designed in 3NF with their purpose, columns, and keys defined.

*   **Table: `Member`**
    *   **Purpose:** Stores registered customer information.
    *   **Columns:** `member_id` (PK), `name`, `email`, `contact_no`, `registration_date`.
    *   **3NF Justification:** Centralizes member data, preventing redundancy in transaction tables.

*   **Table: `Company`**
    *   **Purpose:** Stores bus company information.
    *   **Columns:** `company_id` (PK), `name`.

*   **Table: `Driver`**
    *   **Purpose:** Stores bus driver details.
    *   **Columns:** `driver_id` (PK), `name`, `license_no`, `company_id` (FK).

*   **Table: `Bus`**
    *   **Purpose:** Manages the physical fleet of buses.
    *   **Columns:** `bus_id` (PK), `plate_number`, `capacity`, `status`, `company_id` (FK).

*   **Table: `Route`**
    *   **Purpose:** Defines origin and destination pairs.
    *   **Columns:** `route_id` (PK), `origin`, `destination`.
    *   **3NF Justification:** Prevents a transitive dependency in the `Schedule` table. `Destination` depends on the `Route`, not directly on the `Schedule`.

*   **Table: `Platform`**
    *   **Purpose:** Manages the physical bus platforms at the station.
    *   **Columns:** `platform_no` (PK), `location_desc`, `status`.

*   **Table: `Schedule`**
    *   **Purpose:** Defines a specific trip at a specific time, using specific assets.
    *   **Columns:** `schedule_id` (PK), `departure_time`, `arrival_time`, `base_price`, `bus_id` (FK), `route_id` (FK), `platform_no` (FK).

*   **Table: `Ticket`**
    *   **Purpose:** Represents a single, unique ticket for a seat on a schedule.
    *   **Columns:** `ticket_id` (PK), `seat_number`, `status`, `schedule_id` (FK).

*   **Table: `Booking`**
    *   **Purpose:** Acts as an "order header" for a transaction initiated by a member.
    *   **Columns:** `booking_id` (PK), `booking_date`, `total_amount`, `member_id` (FK).

*   **Table: `BookingDetails` (Bridge Table)**
    *   **Purpose:** Links a `Booking` to the multiple `Tickets` purchased within that single transaction.
    *   **Columns:** `booking_id` (PK, FK), `ticket_id` (PK, FK), `price_at_booking`.

*   **Table: `DriverList` (Bridge Table)**
    *   **Purpose:** Resolves the many-to-many relationship between `Schedule` and `Driver`.
    *   **Columns:** `schedule_id` (PK, FK), `driver_id` (PK, FK), `segment_of_journey`.

*   **Table: `Campaign` & `Promotion`**
    *   **Purpose:** Manage marketing initiatives.
    *   **Columns (`Campaign`):** `campaign_id` (PK), `campaign_name`, `start_date`, `end_date`.
    *   **Columns (`Promotion`):** `promotion_id` (PK), `promo_code`, `discount_type`, `discount_value`, `campaign_id` (FK).

*   **Table: `Payment`, `Refund`, `Extension`**
    *   **Purpose:** To explicitly log all financial events related to a booking or ticket.
    *   **Columns (`Payment`):** `payment_id` (PK), `payment_date`, `amount`, `payment_method`, `booking_id` (FK).
    *   **Columns (`Refund`):** `refund_id` (PK), `refund_date`, `refund_amount`, `ticket_id` (FK).
    *   **Columns (`Extension`):** `extension_id` (PK), `extension_date`, `extension_fee`, `original_ticket_id` (FK), `new_ticket_id` (FK).

*   **Table: `Service` & `ServiceDetails`**
    *   **Purpose:** Manage bus maintenance.
    *   **Columns (`Service`):** `service_id` (PK), `service_name` (e.g., 'Tyre Replace'), `standard_cost`.
    *   **Columns (`ServiceDetails`):** `service_transaction_id` (PK), `service_date`, `actual_cost`, `bus_id` (FK), `service_id` (FK).

*   **Table: `Staff`, `Shop`, `StaffAllocation`, `RentalCollection`**
    *   **Purpose:** Manage internal staff and commercial tenants.
    *   **Columns (`Staff`):** `staff_id` (PK), `name`, `role`.
    *   **Columns (`Shop`):** `shop_id` (PK), `location_code`, `shop_type`.
    *   **Columns (`StaffAllocation` - Bridge):** `allocation_id` (PK), `staff_id` (FK), `platform_no` (FK), `shift_date`.
    *   **Columns (`RentalCollection`):** `rental_collection_id` (PK), `payment_date`, `amount`, `shop_id` (FK).

---

### **3. Relationships (The Foreign Keys)**

This table is your direct guide for drawing the connections in your ERD.

| Child Table | Foreign Key Column | Parent Table | Relationship Type | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Driver** | `company_id` | `Company` | One-to-Many | A Driver belongs to one Company. |
| **Bus** | `company_id` | `Company` | One-to-Many | A Bus is owned by one Company. |
| **Schedule** | `bus_id` | `Bus` | One-to-Many | A Schedule uses one Bus. |
| **Schedule** | `route_id` | `Route` | One-to-Many | A Schedule follows one Route. |
| **Schedule** | `platform_no` | `Platform` | One-to-Many | A Schedule departs from one Platform. |
| **Ticket** | `schedule_id` | `Schedule` | One-to-Many | A Ticket is for one Schedule. |
| **Booking** | `member_id` | `Member` | One-to-Many | A Booking is made by one Member. |
| **Payment** | `booking_id` | `Booking` | One-to-One | A Booking has one Payment. |
| **BookingDetails** | `booking_id` | `Booking` | Many-to-Many | Links Bookings to Tickets. |
| **BookingDetails** | `ticket_id` | `Ticket` | Many-to-Many | Links Tickets to Bookings. |
| **DriverList** | `schedule_id` | `Schedule` | Many-to-Many | Links Schedules to Drivers. |
| **DriverList** | `driver_id` | `Driver` | Many-to-Many | Links Drivers to Schedules. |
| **Promotion** | `campaign_id`| `Campaign`| One-to-Many | A Promotion is part of one Campaign. |
| **Refund** | `ticket_id` | `Ticket` | One-to-Many | A Ticket can have refunds logged. |
| **Extension** | `original_ticket_id`| `Ticket` | One-to-Many | An Extension event relates to a Ticket. |
| **ServiceDetails** | `bus_id` | `Bus` | One-to-Many | A Service is performed on a Bus. |
| **ServiceDetails** | `service_id` | `Service` | One-to-Many | Identifies the type of service. |
| **StaffAllocation**| `staff_id` | `Staff` | Many-to-Many | Links Staff to tasks/locations. |
| **RentalCollection**| `shop_id` | `Shop` | One-to-Many | Rent is collected for a Shop. |
