import os
import random
from datetime import datetime, timedelta
from faker import Faker

# --- Configuration ---
# Base table counts
NUM_COMPANIES = 10
NUM_DRIVERS = 200
NUM_STAFF = 150
NUM_SHOPS = 30
NUM_SERVICES = 15
NUM_MEMBERS = 2000
NUM_CAMPAIGNS = 10
NUM_PROMOTIONS = 50

# Transactional table counts
NUM_BUSES = 200
NUM_SCHEDULES = 1500
NUM_PAYMENTS = 3000
NUM_BOOKINGS = 2500 # Should be less than or equal to payments
NUM_RENTAL_COLLECTIONS = 500
NUM_SERVICE_DETAILS = 800

# Bridge table counts (minimum 1000 as requested)
NUM_DRIVER_LIST_ENTRIES = 1200
NUM_STAFF_ALLOCATIONS = 1000
# BookingDetails will be generated based on bookings (1-4 tickets per booking)
# This will result in thousands of entries.

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
    generate_available_tickets(f, 500) # Generate 500 extra available tickets


def sql_string(value):
    """Escapes single quotes for SQL strings."""
    return str(value).replace("'", "''")

def sql_date(dt_obj):
    """Formats a datetime object for Oracle's TO_DATE function."""
    return f"TO_DATE('{dt_obj.strftime('%Y-%m-%d %H:%M:%S')}', 'YYYY-MM-DD HH24:MI:SS')"

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
        emp_date = sql_date(fake.date_time_between(start_date='-10y', end_date='now'))
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
        reg_date = sql_date(fake.date_time_between(start_date='-5y', end_date='now'))
        f.write(f"INSERT INTO Member (member_id, name, email, contact_no, registration_date) VALUES ({i}, '{name}', '{email}', '{contact_no}', {reg_date});\n")
    f.write("\n")
    
def generate_campaigns(f):
    f.write("-- Data for Campaign Table\n")
    for i in campaign_ids:
        name = sql_string(fake.catch_phrase() + " Campaign")
        start_date = fake.date_time_between(start_date='-1y', end_date='+1y')
        end_date = start_date + timedelta(days=random.randint(30, 90))
        f.write(f"INSERT INTO Campaign (campaign_id, campaign_name, start_date, end_date) VALUES ({i}, '{name}', {sql_date(start_date)}, {sql_date(end_date)});\n")
    f.write("\n")

def generate_promotions(f):
    f.write("-- Data for Promotion Table\n")
    for i in promotion_ids:
        name = sql_string(fake.bs().title())
        desc = sql_string(fake.sentence(nb_words=8))
        disc_type = random.choice(PROMOTION_TYPES)
        disc_value = round(random.uniform(5, 20), 2) if disc_type == 'Percentage' else round(random.uniform(1, 10), 2)
        start_date = fake.date_time_between(start_date='-6m', end_date='+6m')
        end_date = start_date + timedelta(days=random.randint(15, 60))
        campaign_id = random.choice(campaign_ids)
        f.write(f"INSERT INTO Promotion (promotion_id, promotion_name, description, discount_type, discount_value, valid_from, valid_until, campaign_id) VALUES ({i}, '{name}', '{desc}', '{disc_type}', {disc_value}, {sql_date(start_date)}, {sql_date(end_date)}, {campaign_id});\n")
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
        pay_date = sql_date(fake.date_time_between(start_date='-2y', end_date='now'))
        amount = round(random.uniform(15.0, 250.0), 2)
        method = random.choice(PAYMENT_METHODS)
        f.write(f"INSERT INTO Payment (payment_id, payment_date, amount, payment_method) VALUES ({i}, {pay_date}, {amount}, '{method}');\n")
    f.write("\n")

def generate_schedules(f):
    f.write("-- Data for Schedule Table\n")
    for i in schedule_ids:
        dep_time = fake.date_time_between(start_date='-1y', end_date='+1y')
        arr_time = dep_time + timedelta(hours=random.randint(1, 8), minutes=random.randint(0, 59))
        price = round(random.uniform(20.0, 150.0), 2)
        origin = fake.city()
        destination = fake.city()
        while origin == destination:
            destination = fake.city()
        platform = f"P{random.randint(1, 20)}"
        bus_id = random.choice(bus_ids)
        f.write(f"INSERT INTO Schedule (schedule_id, departure_time, arrival_time, base_price, origin_station, destination_station, platform_no, bus_id) VALUES ({i}, {sql_date(dep_time)}, {sql_date(arr_time)}, {price}, '{origin}', '{destination}', '{platform}', {bus_id});\n")
    f.write("\n")

def generate_rental_collections(f):
    f.write("-- Data for RentalCollection Table\n")
    for i in range(1, NUM_RENTAL_COLLECTIONS + 1):
        rental_date = fake.date_time_between(start_date='-3y', end_date='now')
        amount = round(random.uniform(500.0, 3000.0), 2)
        collection_date = rental_date + timedelta(days=random.randint(0, 5))
        shop_id = random.choice(shop_ids)
        staff_id = random.choice(staff_ids)
        f.write(f"INSERT INTO RentalCollection (rental_id, rental_date, amount, collection_date, shop_id, staff_id) VALUES ({i}, {sql_date(rental_date)}, {amount}, {sql_date(collection_date)}, {shop_id}, {staff_id});\n")
    f.write("\n")
    
def generate_service_details(f):
    f.write("-- Data for ServiceDetails Table\n")
    for i in service_detail_ids:
        service_date = sql_date(fake.date_time_between(start_date='-4y', end_date='now'))
        cost = round(random.uniform(100.0, 5000.0), 2)
        service_id = random.choice(service_ids)
        bus_id = random.choice(bus_ids)
        f.write(f"INSERT INTO ServiceDetails (service_transaction_id, service_date, actual_cost, service_id, bus_id) VALUES ({i}, {service_date}, {cost}, {service_id}, {bus_id});\n")
    f.write("\n")

def generate_driver_lists(f):
    f.write("-- Data for DriverList (Bridge) Table\n")
    generated_pairs = set()
    while len(generated_pairs) < NUM_DRIVER_LIST_ENTRIES:
        schedule_id = random.choice(schedule_ids)
        driver_id = random.choice(driver_ids)
        if (schedule_id, driver_id) not in generated_pairs:
            f.write(f"INSERT INTO DriverList (schedule_id, driver_id) VALUES ({schedule_id}, {driver_id});\n")
            generated_pairs.add((schedule_id, driver_id))
    f.write("\n")

def generate_staff_allocations(f):
    f.write("-- Data for StaffAllocation (Bridge) Table\n")
    generated_pairs = set()
    while len(generated_pairs) < NUM_STAFF_ALLOCATIONS:
        service_id = random.choice(service_detail_ids)
        staff_id = random.choice(staff_ids)
        role = random.choice(['Technician', 'Cleaner'])
        if (service_id, staff_id) not in generated_pairs:
            f.write(f"INSERT INTO StaffAllocation (service_transaction_id, staff_id, role) VALUES ({service_id}, {staff_id}, '{role}');\n")
            generated_pairs.add((service_id, staff_id))
    f.write("\n")

def generate_booking_flow(f):
    global ticket_id_counter
    f.write("-- Data for Booking, Ticket, and BookingDetails Tables (Linked)\n")
    
    # Use a copy of payment_ids to ensure each payment is used at most once
    available_payment_ids = payment_ids[:]
    
    for booking_id in booking_ids:
        if not available_payment_ids:
            print("Warning: Ran out of available payment IDs for bookings.")
            break
        
        # 1. Create Booking
        booking_date = sql_date(fake.date_time_between(start_date='-2y', end_date='now'))
        member_id = random.choice(member_ids)
        payment_id = available_payment_ids.pop(random.randrange(len(available_payment_ids))) # Take a unique payment
        total_amount = 0 # Will be calculated after tickets are made
        
        # Hold the booking insert statement
        booking_sql = f"INSERT INTO Booking (booking_id, booking_date, total_amount, member_id, payment_id) VALUES ({booking_id}, {booking_date}, {{total_amount}}, {member_id}, {payment_id});\n"
        
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
            # In a real system, this would query the schedule and promotion tables.
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