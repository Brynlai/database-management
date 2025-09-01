--=============================================================================
-- File: 07_extra_features.sql
--=============================================================================
-- Purpose: Implements performance enhancements and other database objects
--          that support the overall system.
--=============================================================================

PROMPT Creating indexes for performance...

-- Index for Booking table
-- Purpose: Speeds up finding all bookings made by a specific member.
CREATE INDEX idx_booking_member_id ON Booking(member_id);

-- Index for Ticket table
-- Purpose: Speeds up finding all tickets for a given schedule. Benefits both booking and scheduling tasks.
CREATE INDEX idx_ticket_schedule_id ON Ticket(schedule_id);

-- Index for Schedule table
-- Purpose: Speeds up finding all schedules assigned to a specific bus.
CREATE INDEX idx_schedule_bus_id ON Schedule(bus_id);

-- Index for BookingDetails table
-- Purpose: Optimizes the frequent joins between Bookings and Tickets.
CREATE INDEX idx_bookingdetails_ticket_id ON BookingDetails(ticket_id);

-- Index for StaffAllocation table
-- Purpose: Supports queries related to staff assignments and performance, like the one in 03_queries_and_views.sql.
CREATE INDEX idx_staffallocation_staff_id ON StaffAllocation(staff_id);

-- Index for ServiceDetails table
-- Purpose: Optimizes lookups for a bus's complete maintenance history.
CREATE INDEX idx_servicedetails_bus_id ON ServiceDetails(bus_id);

-- Index for DriverList table
-- Purpose: Improves performance when searching for drivers assigned to a schedule.
CREATE INDEX idx_driverlist_driver_id ON DriverList(driver_id);

PROMPT Index creation complete.

COMMIT;