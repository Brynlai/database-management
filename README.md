### **1. Business Rules and Assumptions (For your Report)**

1.  **Booking Process:** A `Member` creates a single `Booking` transaction to purchase one or more `Tickets`. The `BookingDetails` table links the booking to the tickets.
2.  **Financials:** A `Booking` is associated with one `Payment`. If a ticket is cancelled or extended, a `Refund` or `Extension` record is created, linking back to the original `Ticket`.
3.  **Driver Assignments:** A `Schedule` can have multiple `Drivers` assigned to it throughout its journey (e.g., for long routes with driver switches). This is a **many-to-many relationship** managed by the `DriverList` table.
4.  **Campaigns:** A `Campaign` contains `Promotions`. These are applied at the `Booking` or `Ticket` level.
5.  **Operations:** A `Company` owns `Buses`. A `Schedule` uses one `Bus`.
6.  **Staffing:** A `Staff` member can be assigned to work on multiple `Schedules` (e.g., counter staff for a specific departure). This is managed by `StaffAllocation`.
7.  **Maintenance:** A `Service` (e.g., "Tyre Replacement") can be performed on many buses. A record of each specific service event is logged in `ServiceDetails`.
8.  **Denormalization for Practicality (Assumption):** As per requirements, the origin/destination stations and platform information will be stored directly in the `Schedule` table to simplify schedule-based queries.

---

### **2. Entity & Attribute Breakdown (The Tables)**

Here are the tables based on the sketch, with their purpose and attributes defined.

*   **Table: `Member`**
    *   **Purpose:** Stores customer information.
    *   **Attributes:** `member_id` (PK), `name`, `email`, `contact_no`, `registration_date`.

*   **Table: `Booking`**
    *   **Purpose:** Represents a single transaction or "shopping cart" event by a member.
    *   **Attributes:** `booking_id` (PK), `booking_date`, `total_amount`, `member_id` (FK).

*   **Table: `Ticket`**
    *   **Purpose:** Represents a single, specific ticket for a seat on a schedule.
    *   **Attributes:** `ticket_id` (PK), `seat_number`, `status` ('Confirmed', 'Cancelled'), `schedule_id` (FK).

*   **Table: `Schedule`**
    *   **Purpose:** Defines a specific bus trip.
    *   **Attributes:** `schedule_id` (PK), `departure_time`, `arrival_time`, `base_price`, `origin_station`, `destination_station`, `platform_no`, `bus_id` (FK).

*   **Table: `Company`**
    *   **Purpose:** Stores information about bus companies.
    *   **Attributes:** `company_id` (PK), `name`.

*   **Table: `Bus`**
    *   **Purpose:** Manages the physical bus fleet.
    *   **Attributes:** `bus_id` (PK), `plate_number`, `capacity`, `company_id` (FK).

*   **Table: `Driver`**
    *   **Purpose:** Stores details of all drivers.
    *   **Attributes:** `driver_id` (PK), `name`, `license_no`.

*   **Table: `Campaign`**
    *   **Purpose:** Manages high-level marketing campaigns.
    *   **Attributes:** `campaign_id` (PK), `campaign_name`, `start_date`, `end_date`.

*   **Table: `Service`**
    *   **Purpose:** A lookup table for maintenance types.
    *   **Attributes:** `service_id` (PK), `service_name` ('Repair', 'Tyre Replace'), `standard_cost`.

*   **Table: `Staff`**
    *   **Purpose:** Stores information on all station employees.
    *   **Attributes:** `staff_id` (PK), `name`, `role` ('Counter', 'Cleaner').

*   **Table: `Shop`**
    *   **Purpose:** Manages the retail shops in the station.
    *   **Attributes:** `shop_id` (PK), `shop_name`, `location_code`.

*   **Table: `Payment`, `Extension`, `Refund`**
    *   **Purpose:** These are all financial event tables.
    *   **Attributes:** `payment_id` (PK), `payment_date`, `amount`, `payment_method`, `booking_id` (FK). (Similar structure for `Extension` and `Refund`, but they would link to `ticket_id`).

*   **Bridge Table: `BookingDetails`**
    *   **Purpose:** To resolve the many-to-many link between a `Booking` and the `Tickets` it contains.
    *   **Attributes:** `booking_id` (PK, FK), `ticket_id` (PK, FK).

*   **Bridge Table: `DriverList`**
    *   **Purpose:** To resolve the many-to-many link between a `Schedule` and its assigned `Drivers`.
    *   **Attributes:** `schedule_id` (PK, FK), `driver_id` (PK, FK), `assignment_notes` (e.g., 'First leg').

*   **Transaction/Bridge Table: `ServiceDetails`**
    *   **Purpose:** This is the maintenance log. It links a `Service` type to a `Bus` for a specific event.
    *   **Attributes:** `service_transaction_id` (PK), `service_date`, `actual_cost`, `remarks`, `service_id` (FK), `bus_id` (FK).

---

### **3. Relationships (The Foreign Keys)**

This is the most critical part for drawing your ERD. It shows exactly how the tables connect.

| "Child" Table (Has the Foreign Key) | Foreign Key Column | "Parent" Table (Has the Primary Key) | Relationship Explained |
| :--- | :--- | :--- | :--- |
| **Booking** | `member_id` | `Member` | One **Member** can make many **Bookings**. |
| **Payment** | `booking_id` | `Booking` | One **Booking** has one **Payment**. |
| **BookingDetails** | `booking_id` | `Booking` | Links **Booking** to **Ticket** (M:N). |
| **BookingDetails** | `ticket_id` | `Ticket` | Links **Ticket** to **Booking** (M:N). |
| **Ticket** | `schedule_id` | `Schedule` | Many **Tickets** can be for one **Schedule**. |
| **Schedule** | `bus_id` | `Bus` | One **Bus** can operate many **Schedules**. |
| **Bus** | `company_id` | `Company` | One **Company** owns many **Buses**. |
| **DriverList** | `schedule_id` | `Schedule` | Links **Schedule** to **Driver** (M:N). |
| **DriverList** | `driver_id` | `Driver` | Links **Driver** to **Schedule** (M:N). |
| **ServiceDetails** | `service_id` | `Service` | One **Service** type can be logged many times. |
| **ServiceDetails** | `bus_id` | `Bus` | One **Bus** has many **ServiceDetails** logs. |
| **StaffAllocation** | `staff_id` | `Staff` | Links **Staff** to **Schedule** (M:N, *if you build this*).|
| **RentalCollection**| `shop_id` | `Shop` | One **Shop** has many **RentalCollections**. |
