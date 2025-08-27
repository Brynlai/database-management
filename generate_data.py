import os
import random
from datetime import datetime, timedelta
from faker import Faker

START_DATE_GLOBAL = datetime(2024, 1, 1)
END_DATE_GLOBAL = datetime(2025, 12, 31)

NUM_COMPANIES = 12
NUM_DRIVERS = 200
NUM_STAFF = 150
NUM_SHOPS = 30
NUM_SERVICES = 12
NUM_MEMBERS = 7500
NUM_CAMPAIGNS = 10
NUM_PROMOTIONS = 50

NUM_BUSES = 120
NUM_SCHEDULES = 5000
NUM_PAYMENTS = 25000
NUM_BOOKINGS = 25000
NUM_RENTAL_COLLECTIONS = 500
NUM_SERVICE_DETAILS = 800
# MODIFICATION: Added counts for Refund and Extension tables
NUM_REFUNDS = 500      # Well over the 100 record requirement
NUM_EXTENSIONS = 300   # Well over the 100 record requirement

NUM_DRIVER_LIST_ENTRIES = 5000
NUM_STAFF_ALLOCATIONS = 1500

OUTPUT_FILE = "02_populate_data.sql"

STAFF_ROLES = ['Counter Staff', 'Cleaner', 'Manager', 'Technician']
STAFF_STATUSES = ['Active', 'Resigned', 'On Leave']
PAYMENT_METHODS = ['Credit Card', 'Debit Card', 'Online Banking', 'E-Wallet']
TICKET_STATUSES = ['Available', 'Booked', 'Cancelled', 'Extended']
PROMOTION_TYPES = ['Percentage', 'Fixed Amount']

fake = Faker('en_US')

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
refund_ids = list(range(1, NUM_REFUNDS + 1))
extension_ids = list(range(1, NUM_EXTENSIONS + 1))

ticket_id_counter = 1
# MODIFICATION: Added list to track booked tickets for refunds/extensions
booked_ticket_ids = []

def generate_sql(f):
    """Main function to orchestrate the generation of all SQL statements."""
    f.write("-- =============================================================================\n")
    f.write(f"-- Data Population Script Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"-- Date Range: {START_DATE_GLOBAL.strftime('%Y-%m-%d')} to {END_DATE_GLOBAL.strftime('%Y-%m-%d')}\n")
    f.write("-- =============================================================================\n\n")

    # Level 0: No dependencies
    print("Generating Companies, Drivers, Staff, Shops, Services, Members, Campaigns...")
    generate_companies(f)
    generate_drivers(f)
    generate_staff(f)
    generate_shops(f)
    generate_services(f)
    generate_members(f)
    generate_campaigns(f)

    # Level 1
    print("Generating Promotions, Buses, Payments...")
    generate_promotions(f)
    generate_buses(f)
    generate_payments(f)

    # Level 2
    print("Generating Schedules, Rental Collections, Service Details...")
    generate_schedules(f)
    generate_rental_collections(f)
    generate_service_details(f)

    # Level 3
    print("Generating Driver Lists, Staff Allocations...")
    generate_driver_lists(f)
    generate_staff_allocations(f)
    
    # Level 4: Core booking flow
    print("Generating Bookings, Tickets, and BookingDetails...")
    generate_booking_flow(f)
    
    # MODIFICATION: Added calls to generate refunds and extensions
    # These must run AFTER the booking flow to have tickets to work with.
    print("Generating Refunds...")
    generate_refunds(f)
    print("Generating Extensions...")
    generate_extensions(f)
    
    # Final step: Add some extra available tickets
    print("Generating additional 'Available' tickets...")
    generate_available_tickets(f, 2000)

def sql_string(value):
    return str(value).replace("'", "''")

def sql_date(dt_obj):
    return f"TO_DATE('{dt_obj.strftime('%Y-%m-%d %H:%M:%S')}', 'YYYY-MM-DD HH24-MI-SS')"

def get_random_date():
    time_between_dates = END_DATE_GLOBAL - START_DATE_GLOBAL
    random_number_of_days = random.randrange(time_between_dates.days)
    random_date = START_DATE_GLOBAL + timedelta(days=random_number_of_days)
    return random_date

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
        license_no = fake.bothify(text='?#######??').upper()
        f.write(f"INSERT INTO Driver (driver_id, name, license_no) VALUES ({i}, '{name}', '{license_no}');\n")
    f.write("\n")

def generate_staff(f):
    f.write("-- Data for Staff Table\n")
    for i in staff_ids:
        name = sql_string(fake.name())
        role = random.choice(STAFF_ROLES)
        email = fake.unique.email()
        contact_no = fake.phone_number()
        emp_date = sql_date(get_random_date())
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
        reg_date = sql_date(get_random_date())
        f.write(f"INSERT INTO Member (member_id, name, email, contact_no, registration_date) VALUES ({i}, '{name}', '{email}', '{contact_no}', {reg_date});\n")
    f.write("\n")
    
def generate_campaigns(f):
    f.write("-- Data for Campaign Table\n")
    for i in campaign_ids:
        name = sql_string(fake.catch_phrase() + " Campaign")
        start_date_obj = get_random_date()
        end_date_obj = start_date_obj + timedelta(days=random.randint(30, 90))
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
        start_date_obj = get_random_date()
        end_date_obj = start_date_obj + timedelta(days=random.randint(15, 60))
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
        pay_date_obj = get_random_date()
        amount = round(random.uniform(15.0, 250.0), 2)
        method = random.choice(PAYMENT_METHODS)
        f.write(f"INSERT INTO Payment (payment_id, payment_date, amount, payment_method) VALUES ({i}, {sql_date(pay_date_obj)}, {amount}, '{method}');\n")
    f.write("\n")

def generate_schedules(f):
    f.write("-- Data for Schedule Table\n")
    for i in schedule_ids:
        dep_time_obj = get_random_date()
        arr_time_obj = dep_time_obj + timedelta(hours=random.randint(1, 8), minutes=random.randint(0, 59))
        if arr_time_obj > END_DATE_GLOBAL:
            arr_time_obj = END_DATE_GLOBAL
            if arr_time_obj <= dep_time_obj:
                dep_time_obj = arr_time_obj - timedelta(hours=1)
                if dep_time_obj < START_DATE_GLOBAL:
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
        rental_date_obj = get_random_date()
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
        service_date_obj = get_random_date()
        cost = round(random.uniform(100.0, 5000.0), 2)
        service_id = random.choice(service_ids)
        bus_id = random.choice(bus_ids)
        f.write(f"INSERT INTO ServiceDetails (service_transaction_id, service_date, actual_cost, service_id, bus_id) VALUES ({i}, {sql_date(service_date_obj)}, {cost}, {service_id}, {bus_id});\n")
    f.write("\n")

def generate_driver_lists(f):
    f.write("-- Data for DriverList (Bridge) Table\n")
    generated_pairs = set()
    attempts = 0
    max_attempts = NUM_DRIVER_LIST_ENTRIES * 5
    while len(generated_pairs) < NUM_DRIVER_LIST_ENTRIES and attempts < max_attempts:
        schedule_id = random.choice(schedule_ids)
        driver_id = random.choice(driver_ids)
        if (schedule_id, driver_id) not in generated_pairs:
            f.write(f"INSERT INTO DriverList (schedule_id, driver_id) VALUES ({schedule_id}, {driver_id});\n")
            generated_pairs.add((schedule_id, driver_id))
        attempts += 1
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
    f.write("\n")


def generate_booking_flow(f):
    global ticket_id_counter, booked_ticket_ids
    f.write("-- Data for Booking, Ticket, and BookingDetails Tables (Linked)\n")
    
    available_payment_ids = random.sample(payment_ids, NUM_BOOKINGS)

    for i in range(NUM_BOOKINGS):
        booking_id = booking_ids[i]
        booking_date_obj = get_random_date()
        member_id = random.choice(member_ids)
        payment_id = available_payment_ids.pop()
        total_amount = 0
        
        booking_sql = f"INSERT INTO Booking (booking_id, booking_date, total_amount, member_id, payment_id) VALUES ({booking_id}, {sql_date(booking_date_obj)}, {{total_amount}}, {member_id}, {payment_id});\n"
        
        num_tickets_in_booking = random.randint(1, 4)
        ticket_sqls = []
        booking_details_sqls = []
        
        for _ in range(num_tickets_in_booking):
            seat = f"{random.randint(1, 15)}{random.choice('ABCD')}"
            status = 'Booked'
            schedule_id = random.choice(schedule_ids)
            has_promo = random.random() < 0.3
            promo_id = random.choice(promotion_ids) if has_promo else 'NULL'
            
            ticket_sqls.append(f"INSERT INTO Ticket (ticket_id, seat_number, status, schedule_id, promotion_id) VALUES ({ticket_id_counter}, '{seat}', '{status}', {schedule_id}, {promo_id});\n")
            booking_details_sqls.append(f"INSERT INTO BookingDetails (booking_id, ticket_id) VALUES ({booking_id}, {ticket_id_counter});\n")
            
            # MODIFICATION: Track the ID of this booked ticket
            booked_ticket_ids.append(ticket_id_counter)
            
            price = random.uniform(20.0, 150.0)
            if has_promo:
                price *= 0.9
            total_amount += price
            
            ticket_id_counter += 1

        f.write(booking_sql.format(total_amount=round(total_amount, 2)))
        f.writelines(ticket_sqls)
        f.writelines(booking_details_sqls)
        f.write("\n")

# MODIFICATION: New function to generate refunds
def generate_refunds(f):
    global booked_ticket_ids
    f.write("-- Data for Refund Table\n")

    # Ensure we don't try to refund more tickets than exist
    num_to_refund = min(NUM_REFUNDS, len(booked_ticket_ids))
    
    # Randomly select tickets to be refunded
    tickets_to_refund = random.sample(booked_ticket_ids, num_to_refund)
    
    for i in range(num_to_refund):
        refund_id = refund_ids[i]
        ticket_id = tickets_to_refund[i]
        
        refund_date = sql_date(get_random_date())
        amount = round(random.uniform(20.0, 100.0) * 0.7, 2) # 70% refund
        method = random.choice(PAYMENT_METHODS)
        
        f.write(f"INSERT INTO Refund (refund_id, refund_date, amount, refund_method, ticket_id) VALUES ({refund_id}, {refund_date}, {amount}, '{method}', {ticket_id});\n")
        # Optional: Update ticket status. This is better handled by a trigger, which Alia will build.
        # f.write(f"UPDATE Ticket SET status = 'Cancelled' WHERE ticket_id = {ticket_id};\n")

    # Remove the refunded tickets from the available pool
    booked_ticket_ids = [tid for tid in booked_ticket_ids if tid not in tickets_to_refund]
    f.write("\n")

# MODIFICATION: New function to generate extensions
def generate_extensions(f):
    global booked_ticket_ids
    f.write("-- Data for Extension Table\n")

    # Ensure we don't try to extend more tickets than are left
    num_to_extend = min(NUM_EXTENSIONS, len(booked_ticket_ids))
    
    # Randomly select from the REMAINING tickets to be extended
    tickets_to_extend = random.sample(booked_ticket_ids, num_to_extend)
    
    for i in range(num_to_extend):
        extension_id = extension_ids[i]
        ticket_id = tickets_to_extend[i]
        
        extension_date = sql_date(get_random_date())
        amount = round(random.uniform(20.0, 100.0) + 5.0, 2) # Current price + RM5
        method = random.choice(PAYMENT_METHODS)
        
        f.write(f"INSERT INTO Extension (extension_id, extension_date, amount, extension_method, ticket_id) VALUES ({extension_id}, {extension_date}, {amount}, '{method}', {ticket_id});\n")
        # Optional: Update ticket status.
        # f.write(f"UPDATE Ticket SET status = 'Extended' WHERE ticket_id = {ticket_id};\n")

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