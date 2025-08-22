import os
import random
from datetime import datetime, timedelta
from faker import Faker

# # --- Configuration ---
# # --- Configuration ---
# # Global Date Range for all generated data - Focused 6-year span
# START_DATE_GLOBAL = datetime(2020, 1, 1)
# END_DATE_GLOBAL = datetime(2025, 12, 31)

# # Base table counts - Scaled to reflect a 6-year operational history
# NUM_COMPANIES = 15 # Reduced from 25; reflects a mature but not decades-old operation.
# NUM_DRIVERS = 350 # Reduced from 1000; a solid roster for a 6-year period.
# NUM_STAFF = 250 # Reduced from 750; appropriate for the scale of operations.
# NUM_SHOPS = 40 # Reduced from 100; a busy but smaller commercial area.
# NUM_SERVICES = 15 # Reduced from 30; core services are established, but fewer niche ones.
# NUM_MEMBERS = 15000 # Reduced from 50k; member growth is time-dependent.
# NUM_CAMPAIGNS = 20 # Reduced from 50; fewer campaigns over a shorter period.
# NUM_PROMOTIONS = 100 # Reduced from 250; scales with campaigns.

# # Transactional table counts - Scaled aggressively to match the ~70% time reduction
# NUM_BUSES = 300 # Reduced from 1000; fleet size grows over time.
# NUM_SCHEDULES = 15000 # Reduced from 50k; directly reflects fewer years of operation.
# NUM_PAYMENTS = 75000 # Reduced from 250k; scales 1:1 with bookings.
# NUM_BOOKINGS = 75000 # Reduced from 250k; the core transactional driver.
# NUM_RENTAL_COLLECTIONS = 1500 # Reduced from 5k; fewer rental cycles have passed.
# NUM_SERVICE_DETAILS = 2500 # Reduced from 7.5k; fewer services needed for a smaller fleet over less time.

# # Bridge table counts
# # BookingDetails will be generated based on NUM_BOOKINGS, resulting in 75,000 to 300,000 tickets.
# NUM_DRIVER_LIST_ENTRIES = 15000 # Reduced from 50k; scales with the number of schedules.
# NUM_STAFF_ALLOCATIONS = 5000 # Reduced from 15k; scales with the number of service details.



# Global Date Range for all generated data - Focused 2-year span
START_DATE_GLOBAL = datetime(2024, 1, 1)
END_DATE_GLOBAL = datetime(2025, 12, 31)

# Base table counts - Scaled for a mature operation within a 2-year window
NUM_COMPANIES = 12          # A stable number of operators.
NUM_DRIVERS = 200           # A solid roster of active drivers.
NUM_STAFF = 150             # Lean but sufficient operational staff.
NUM_SHOPS = 30              # A busy but focused commercial area.
NUM_SERVICES = 12           # Core, essential services.
NUM_MEMBERS = 7500          # Reflects an established member base.
NUM_CAMPAIGNS = 10          # Fewer major campaigns over a shorter period.
NUM_PROMOTIONS = 50         # Scales with campaigns.

# Transactional table counts - Scaled to a 2-year period (approx. 1/3 of the 6-year values)
NUM_BUSES = 120             # A realistic fleet size.
NUM_SCHEDULES = 5000        # Reflects 2 years of operational schedules.
NUM_PAYMENTS = 25000        # Scales 1:1 with bookings.
NUM_BOOKINGS = 25000        # The core transactional driver for the period.
NUM_RENTAL_COLLECTIONS = 500 # Fewer rental cycles have passed.
NUM_SERVICE_DETAILS = 800   # Fewer services needed for the fleet over 2 years.

# Bridge table counts
# BookingDetails will be generated based on NUM_BOOKINGS, resulting in 25,000 to 100,000 tickets.
NUM_DRIVER_LIST_ENTRIES = 5000 # Scales with the number of schedules.
NUM_STAFF_ALLOCATIONS = 1500   # Scales with the number of service details.

OUTPUT_FILE = "02_populate_data.sql"

# --- Valid values for CHECK constraints ---
STAFF_ROLES = ['Counter Staff', 'Cleaner', 'Manager', 'Technician']
STAFF_STATUSES = ['Active', 'Resigned', 'On Leave']
PAYMENT_METHODS = ['Credit Card', 'Debit Card', 'Online Banking', 'E-Wallet']
TICKET_STATUSES = ['Available', 'Booked', 'Cancelled', 'Extended']
PROMOTION_TYPES = ['Percentage', 'Fixed Amount']

# --- Main Script ---
fake = Faker('en_US')

# Lists to store generated Primary Keys for Foreign Key usage
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
# Ticket IDs will be handled by a global counter
ticket_id_counter = 1


def generate_sql(f):
    """Main function to orchestrate the generation of all SQL statements."""
    f.write("-- =============================================================================\n")
    f.write(f"-- Data Population Script Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("-- Date Range: {START_DATE_GLOBAL.strftime('%Y-%m-%d')} to {END_DATE_GLOBAL.strftime('%Y-%m-%d')}\n")
    f.write("-- =============================================================================\n\n")

    # Level 0: Tables with no foreign key dependencies
    print("Generating Companies...")
    generate_companies(f)
    print("Generating Drivers...")
    generate_drivers(f)
    print("Generating Staff...")
    generate_staff(f)
    print("Generating Shops...")
    generate_shops(f)
    print("Generating Services...")
    generate_services(f)
    print("Generating Members...")
    generate_members(f)
    print("Generating Campaigns...")
    generate_campaigns(f)

    # Level 1: Depend on Level 0
    print("Generating Promotions...")
    generate_promotions(f)
    print("Generating Buses...")
    generate_buses(f)
    print("Generating Payments...")
    generate_payments(f)

    # Level 2: Depend on Level 1
    print("Generating Schedules...")
    generate_schedules(f)
    print("Generating Rental Collections...")
    generate_rental_collections(f)
    print("Generating Service Details...")
    generate_service_details(f)

    # Level 3: Bridge tables and transactions
    print("Generating Driver Lists (Bridge)...")
    generate_driver_lists(f)
    print("Generating Staff Allocations (Bridge)...")
    generate_staff_allocations(f)
    
    # Level 4: The core booking flow (Booking, Ticket, BookingDetails)
    print("Generating Bookings, Tickets, and BookingDetails (Core Flow)...")
    generate_booking_flow(f)
    
    # Generate some additional available tickets
    print("Generating additional 'Available' tickets...")
    generate_available_tickets(f, 2000) # Increased extra available tickets


def sql_string(value):
    """Escapes single quotes for SQL strings."""
    return str(value).replace("'", "''")

def sql_date(dt_obj):
    """Formats a datetime object for Oracle's TO_DATE function."""
    return f"TO_DATE('{dt_obj.strftime('%Y-%m-%d %H:%M:%S')}', 'YYYY-MM-DD HH24:MI:SS')"

def get_random_date():
    """Returns a random datetime within the global defined range."""
    time_between_dates = END_DATE_GLOBAL - START_DATE_GLOBAL
    random_days = random.randint(0, time_between_dates.days)
    random_seconds = random.randint(0, 24*60*60 -1)
    return START_DATE_GLOBAL + timedelta(days=random_days, seconds=random_seconds)

# --- Generator Functions ---

def generate_companies(f):
    f.write("-- Data for Company Table\n")
    for i in company_ids:
        name = sql_string(fake.company())
        f.write(f"INSERT INTO Company (company_id, name) VALUES ({i}, '{name}');\n")
    f.write("\n")

def generate_drivers(f):
    f.write("-- Data for Driver Table\n")
    for i in driver_ids:
        name = sql_string(fake.name())
        license_no = fake.bothify(text='?#######??').upper() # Random license format
        f.write(f"INSERT INTO Driver (driver_id, name, license_no) VALUES ({i}, '{name}', '{license_no}');\n")
    f.write("\n")

def generate_staff(f):
    f.write("-- Data for Staff Table\n")
    for i in staff_ids:
        name = sql_string(fake.name())
        role = random.choice(STAFF_ROLES)
        email = fake.unique.email()
        contact_no = fake.phone_number()
        emp_date = sql_date(get_random_date()) # Use global date range
        status = random.choice(STAFF_STATUSES)
        f.write(f"INSERT INTO Staff (staff_id, name, role, email, contact_no, employment_date, status) VALUES ({i}, '{name}', '{role}', '{email}', '{contact_no}', {emp_date}, '{status}');\n")
    f.write("\n")

def generate_shops(f):
    f.write("-- Data for Shop Table\n")
    for i in shop_ids:
        shop_name = sql_string(fake.company() + " " + fake.random_element(elements=('Stall', 'Mart', 'Cafe')))
        location_code = fake.unique.bothify(text='L?-###').upper()
        f.write(f"INSERT INTO Shop (shop_id, shop_name, location_code) VALUES ({i}, '{shop_name}', '{location_code}');\n")
    f.write("\n")

def generate_services(f):
    f.write("-- Data for Service Table\n")
    service_names = ['Bus Wash', 'Tyre Replacement', 'Engine Overhaul', 'Brake System Repair', 'Oil Change', 'AC Service', 'Full Inspection']
    for i in service_ids:
        service_name = random.choice(service_names)
        cost = round(random.uniform(50.0, 2000.0), 2)
        # Ensure we don't run out of names for the small list
        if i > len(service_names):
             service_name = f"Generic Service {i}"
        f.write(f"INSERT INTO Service (service_id, service_name, standard_cost) VALUES ({i}, '{service_name}', {cost});\n")
    f.write("\n")

def generate_members(f):
    f.write("-- Data for Member Table\n")
    for i in member_ids:
        name = sql_string(fake.name())
        email = fake.unique.email()
        contact_no = fake.phone_number()
        reg_date = sql_date(get_random_date()) # Use global date range
        f.write(f"INSERT INTO Member (member_id, name, email, contact_no, registration_date) VALUES ({i}, '{name}', '{email}', '{contact_no}', {reg_date});\n")
    f.write("\n")
    
def generate_campaigns(f):
    f.write("-- Data for Campaign Table\n")
    for i in campaign_ids:
        name = sql_string(fake.catch_phrase() + " Campaign")
        start_date_obj = get_random_date() # Use global date range
        end_date_obj = start_date_obj + timedelta(days=random.randint(30, 90))
        # Ensure end_date does not exceed global end_date
        if end_date_obj > END_DATE_GLOBAL:
            end_date_obj = END_DATE_GLOBAL
        f.write(f"INSERT INTO Campaign (campaign_id, campaign_name, start_date, end_date) VALUES ({i}, '{name}', {sql_date(start_date_obj)}, {sql_date(end_date_obj)});\n")
    f.write("\n")

def generate_promotions(f):
    f.write("-- Data for Promotion Table\n")
    for i in promotion_ids:
        name = sql_string(fake.bs().title())
        desc = sql_string(fake.sentence(nb_words=8))
        disc_type = random.choice(PROMOTION_TYPES)
        disc_value = round(random.uniform(5, 20), 2) if disc_type == 'Percentage' else round(random.uniform(1, 10), 2)
        start_date_obj = get_random_date() # Use global date range
        end_date_obj = start_date_obj + timedelta(days=random.randint(15, 60))
        # Ensure end_date does not exceed global end_date
        if end_date_obj > END_DATE_GLOBAL:
            end_date_obj = END_DATE_GLOBAL
        campaign_id = random.choice(campaign_ids)
        f.write(f"INSERT INTO Promotion (promotion_id, promotion_name, description, discount_type, discount_value, valid_from, valid_until, campaign_id) VALUES ({i}, '{name}', '{desc}', '{disc_type}', {disc_value}, {sql_date(start_date_obj)}, {sql_date(end_date_obj)}, {campaign_id});\n")
    f.write("\n")
    
def generate_buses(f):
    f.write("-- Data for Bus Table\n")
    for i in bus_ids:
        plate = fake.unique.license_plate()
        capacity = random.randint(40, 55)
        company_id = random.choice(company_ids)
        f.write(f"INSERT INTO Bus (bus_id, plate_number, capacity, company_id) VALUES ({i}, '{plate}', {capacity}, {company_id});\n")
    f.write("\n")

def generate_payments(f):
    f.write("-- Data for Payment Table\n")
    for i in payment_ids:
        pay_date_obj = get_random_date() # Use global date range
        amount = round(random.uniform(15.0, 250.0), 2)
        method = random.choice(PAYMENT_METHODS)
        f.write(f"INSERT INTO Payment (payment_id, payment_date, amount, payment_method) VALUES ({i}, {sql_date(pay_date_obj)}, {amount}, '{method}');\n")
    f.write("\n")

def generate_schedules(f):
    f.write("-- Data for Schedule Table\n")
    for i in schedule_ids:
        dep_time_obj = get_random_date() # Use global date range
        arr_time_obj = dep_time_obj + timedelta(hours=random.randint(1, 8), minutes=random.randint(0, 59))
        # Ensure arrival_time is within the global date range if departure is near the end
        if arr_time_obj > END_DATE_GLOBAL:
            arr_time_obj = END_DATE_GLOBAL # Clamp to end date if it overshoots
            if arr_time_obj <= dep_time_obj: # Make sure arrival is still after departure
                dep_time_obj = arr_time_obj - timedelta(hours=1) # Adjust departure if needed
                if dep_time_obj < START_DATE_GLOBAL: # If that makes dep too early, just pick a new random
                    dep_time_obj = get_random_date()
                    arr_time_obj = dep_time_obj + timedelta(hours=random.randint(1,8), minutes=random.randint(0,59))


        price = round(random.uniform(20.0, 150.0), 2)
        origin = fake.city()
        destination = fake.city()
        while origin == destination:
            destination = fake.city()
        platform = f"P{random.randint(1, 20)}"
        bus_id = random.choice(bus_ids)
        f.write(f"INSERT INTO Schedule (schedule_id, departure_time, arrival_time, base_price, origin_station, destination_station, platform_no, bus_id) VALUES ({i}, {sql_date(dep_time_obj)}, {sql_date(arr_time_obj)}, {price}, '{origin}', '{destination}', '{platform}', {bus_id});\n")
    f.write("\n")

def generate_rental_collections(f):
    f.write("-- Data for RentalCollection Table\n")
    for i in range(1, NUM_RENTAL_COLLECTIONS + 1):
        rental_date_obj = get_random_date() # Use global date range
        amount = round(random.uniform(500.0, 3000.0), 2)
        collection_date_obj = rental_date_obj + timedelta(days=random.randint(0, 5))
        if collection_date_obj > END_DATE_GLOBAL:
            collection_date_obj = END_DATE_GLOBAL
        shop_id = random.choice(shop_ids)
        staff_id = random.choice(staff_ids)
        f.write(f"INSERT INTO RentalCollection (rental_id, rental_date, amount, collection_date, shop_id, staff_id) VALUES ({i}, {sql_date(rental_date_obj)}, {amount}, {sql_date(collection_date_obj)}, {shop_id}, {staff_id});\n")
    f.write("\n")
    
def generate_service_details(f):
    f.write("-- Data for ServiceDetails Table\n")
    for i in service_detail_ids:
        service_date_obj = get_random_date() # Use global date range
        cost = round(random.uniform(100.0, 5000.0), 2)
        service_id = random.choice(service_ids)
        bus_id = random.choice(bus_ids)
        f.write(f"INSERT INTO ServiceDetails (service_transaction_id, service_date, actual_cost, service_id, bus_id) VALUES ({i}, {sql_date(service_date_obj)}, {cost}, {service_id}, {bus_id});\n")
    f.write("\n")

def generate_driver_lists(f):
    f.write("-- Data for DriverList (Bridge) Table\n")
    generated_pairs = set()
    # To ensure 10,000 unique entries, we might need more attempts
    attempts = 0
    max_attempts = NUM_DRIVER_LIST_ENTRIES * 5 # Allow more attempts to find unique pairs
    while len(generated_pairs) < NUM_DRIVER_LIST_ENTRIES and attempts < max_attempts:
        schedule_id = random.choice(schedule_ids)
        driver_id = random.choice(driver_ids)
        if (schedule_id, driver_id) not in generated_pairs:
            f.write(f"INSERT INTO DriverList (schedule_id, driver_id) VALUES ({schedule_id}, {driver_id});\n")
            generated_pairs.add((schedule_id, driver_id))
        attempts += 1
    if len(generated_pairs) < NUM_DRIVER_LIST_ENTRIES:
        print(f"Warning: Could only generate {len(generated_pairs)} unique DriverList entries out of {NUM_DRIVER_LIST_ENTRIES} requested.")
    f.write("\n")

def generate_staff_allocations(f):
    f.write("-- Data for StaffAllocation (Bridge) Table\n")
    generated_pairs = set()
    attempts = 0
    max_attempts = NUM_STAFF_ALLOCATIONS * 5
    while len(generated_pairs) < NUM_STAFF_ALLOCATIONS and attempts < max_attempts:
        service_id = random.choice(service_detail_ids)
        staff_id = random.choice(staff_ids)
        role = random.choice(['Technician', 'Cleaner'])
        if (service_id, staff_id) not in generated_pairs:
            f.write(f"INSERT INTO StaffAllocation (service_transaction_id, staff_id, role) VALUES ({service_id}, {staff_id}, '{role}');\n")
            generated_pairs.add((service_id, staff_id))
        attempts += 1
    if len(generated_pairs) < NUM_STAFF_ALLOCATIONS:
        print(f"Warning: Could only generate {len(generated_pairs)} unique StaffAllocation entries out of {NUM_STAFF_ALLOCATIONS} requested.")
    f.write("\n")

def generate_booking_flow(f):
    global ticket_id_counter
    f.write("-- Data for Booking, Ticket, and BookingDetails Tables (Linked)\n")
    
    # Use a copy of payment_ids to ensure each payment is used at most once
    # Ensure there are enough payment IDs for all bookings
    if len(payment_ids) < NUM_BOOKINGS:
        print(f"Warning: Not enough unique payment IDs ({len(payment_ids)}) for {NUM_BOOKINGS} bookings. Some bookings might not be generated.")
        bookings_to_generate = len(payment_ids)
    else:
        bookings_to_generate = NUM_BOOKINGS

    available_payment_ids = random.sample(payment_ids, bookings_to_generate) # Get unique payment IDs for bookings

    for i in range(bookings_to_generate):
        booking_id = booking_ids[i]
        
        # 1. Create Booking
        booking_date_obj = get_random_date() # Use global date range
        member_id = random.choice(member_ids)
        payment_id = available_payment_ids.pop() # Take a unique payment
        total_amount = 0 # Will be calculated after tickets are made
        
        # Hold the booking insert statement
        booking_sql = f"INSERT INTO Booking (booking_id, booking_date, total_amount, member_id, payment_id) VALUES ({booking_id}, {sql_date(booking_date_obj)}, {{total_amount}}, {member_id}, {payment_id});\n"
        
        num_tickets_in_booking = random.randint(1, 4)
        ticket_sqls = []
        booking_details_sqls = []
        
        for _ in range(num_tickets_in_booking):
            # 2. Create Tickets for this Booking
            seat = f"{random.randint(1, 15)}{random.choice('ABCD')}"
            status = 'Booked' # Tickets in a booking are always booked
            schedule_id = random.choice(schedule_ids)
            
            # Decide if a promotion is applied
            has_promo = random.random() < 0.3 # 30% chance of promo
            promo_id = random.choice(promotion_ids) if has_promo else 'NULL'
            
            ticket_sqls.append(f"INSERT INTO Ticket (ticket_id, seat_number, status, schedule_id, promotion_id) VALUES ({ticket_id_counter}, '{seat}', '{status}', {schedule_id}, {promo_id});\n")
            
            # 3. Create BookingDetails entry
            booking_details_sqls.append(f"INSERT INTO BookingDetails (booking_id, ticket_id) VALUES ({booking_id}, {ticket_id_counter});\n")
            
            # Dummy price logic for total_amount
            price = random.uniform(20.0, 150.0)
            if has_promo:
                price *= 0.9 # Assume 10% discount for simplicity
            total_amount += price
            
            ticket_id_counter += 1

        # Now write the completed statements
        f.write(booking_sql.format(total_amount=round(total_amount, 2)))
        f.writelines(ticket_sqls)
        f.writelines(booking_details_sqls)
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


if __name__ == "__main__":
    if os.path.exists(OUTPUT_FILE):
        os.remove(OUTPUT_FILE)

    with open(OUTPUT_FILE, 'w') as f:
        generate_sql(f)
        
    print(f"Successfully generated {OUTPUT_FILE} with a large volume of sample data.")