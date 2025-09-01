import os
import random
from datetime import datetime, timedelta
from faker import Faker

# --- Configuration ---
START_DATE_GLOBAL = datetime(2024, 1, 1)
END_DATE_GLOBAL = datetime(2025, 12, 31)

# Base and Transaction Counts
NUM_COMPANIES = 12
NUM_DRIVERS = 200
NUM_STAFF = 150
NUM_SHOPS = 30
NUM_SERVICES = 12
NUM_MEMBERS = 7500
NUM_CAMPAIGNS = 10
NUM_PROMOTIONS = 100
NUM_BUSES = 120
NUM_SCHEDULES = 5000
# MODIFICATION: Reduced the primary transaction drivers for a more balanced dataset.
NUM_PAYMENTS = 3000      # Lowered from 25000
NUM_BOOKINGS = 3000      # Lowered from 25000. This is the main change.
NUM_RENTAL_COLLECTIONS = 500
NUM_SERVICE_DETAILS = 800
NUM_REFUNDS = 300        # Slightly reduced to stay proportional
NUM_EXTENSIONS = 200       # Slightly reduced to stay proportional
NUM_DRIVER_LIST_ENTRIES = 5000
# MODIFICATION: Adjusted to be more realistic in proportion to service details.
NUM_STAFF_ALLOCATIONS = 1000   # Lowered from 1500

OUTPUT_FILE = "02_populate_data.sql"

# --- Valid Values ---
STAFF_ROLES = ['Counter Staff', 'Cleaner', 'Manager', 'Technician']
STAFF_STATUSES = ['Active', 'Resigned', 'On Leave']
PAYMENT_METHODS = ['Credit Card', 'Debit Card', 'Online Banking', 'E-Wallet']
TICKET_STATUSES = ['Available', 'Booked', 'Cancelled', 'Extended']
PROMOTION_TYPES = ['Percentage', 'Fixed Amount']

# --- Main Script ---
fake = Faker('en_US')

# --- Primary Key Lists ---
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

# --- Global Trackers for Logical Consistency ---
ticket_id_counter = 1
schedules_data = []
booked_tickets_data = []

# (The rest of the script remains exactly the same as the logically corrected version I provided previously)
# --- Main Generation Orchestrator ---
def generate_sql(f):
    f.write("-- =============================================================================\n")
    f.write(f"-- Data Population Script Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"-- Date Range: {START_DATE_GLOBAL.strftime('%Y-%m-%d')} to {END_DATE_GLOBAL.strftime('%Y-%m-%d')}\n")
    f.write("-- =============================================================================\n\n")

    print("Generating Level 0 Tables...")
    generate_companies(f); generate_drivers(f); generate_staff(f); generate_shops(f); generate_services(f); generate_members(f); generate_campaigns(f)
    print("Generating Level 1 Tables...")
    generate_promotions(f); generate_buses(f); generate_payments(f)
    print("Generating Level 2 Tables (Schedules are critical)...")
    generate_schedules(f); generate_rental_collections(f); generate_service_details(f)
    print("Generating Level 3 Tables...")
    generate_driver_lists(f); generate_staff_allocations(f)
    print("Generating Core Booking Flow (Tickets, Bookings)...")
    generate_booking_flow(f)
    print("Generating Post-Booking Transactions (Refunds, Extensions)...")
    generate_refunds(f)
    generate_extensions(f)
    print("Generating Additional Available Tickets...")
    generate_available_tickets(f, 500) # Reduced this slightly as well

# --- Helper Functions ---
def sql_string(value):
    return str(value).replace("'", "''")

def sql_date(dt_obj):
    return f"TO_DATE('{dt_obj.strftime('%Y-%m-%d %H:%M:%S')}', 'YYYY-MM-DD HH24:MI:SS')"

def get_random_date():
    days_between = (END_DATE_GLOBAL - START_DATE_GLOBAL).days
    random_days = random.randrange(days_between)
    return START_DATE_GLOBAL + timedelta(days=random_days, seconds=random.randrange(86400))

# --- Generator Functions ---
def generate_schedules(f):
    global schedules_data
    f.write("-- Data for Schedule Table\n")
    for i in schedule_ids:
        dep_time_obj = get_random_date()
        arr_time_obj = dep_time_obj + timedelta(hours=random.randint(1, 8), minutes=random.randint(0, 59))
        if arr_time_obj > END_DATE_GLOBAL: continue
        schedules_data.append({'id': i, 'departure': dep_time_obj})
        price = round(random.uniform(20.0, 150.0), 2)
        origin = fake.city(); destination = fake.city()
        while origin == destination: destination = fake.city()
        platform = f"P{random.randint(1, 20)}"
        bus_id = random.choice(bus_ids)
        f.write(f"INSERT INTO Schedule (schedule_id, departure_time, arrival_time, base_price, origin_station, destination_station, platform_no, bus_id) VALUES ({i}, {sql_date(dep_time_obj)}, {sql_date(arr_time_obj)}, {price}, '{origin}', '{destination}', '{platform}', {bus_id});\n")
    f.write("\n")

def generate_booking_flow(f):
    global ticket_id_counter, booked_tickets_data
    f.write("-- Data for Booking, Ticket, and BookingDetails Tables (Linked)\n")
    available_payment_ids = random.sample(payment_ids, NUM_BOOKINGS)
    for i in range(NUM_BOOKINGS):
        booking_id = booking_ids[i]
        selected_schedule = random.choice(schedules_data)
        departure_time = selected_schedule['departure']
        schedule_id = selected_schedule['id']
        booking_offset = timedelta(days=random.randint(1, 90), seconds=random.randint(0, 86399))
        booking_date_obj = departure_time - booking_offset
        if booking_date_obj < START_DATE_GLOBAL:
            booking_date_obj = START_DATE_GLOBAL + timedelta(seconds=1)
        member_id = random.choice(member_ids)
        payment_id = available_payment_ids.pop()
        total_amount = 0
        booking_sql = f"INSERT INTO Booking (booking_id, booking_date, total_amount, member_id, payment_id) VALUES ({booking_id}, {sql_date(booking_date_obj)}, {{total_amount}}, {member_id}, {payment_id});\n"
        num_tickets_in_booking = random.randint(1, 4)
        ticket_sqls = []; booking_details_sqls = []
        for _ in range(num_tickets_in_booking):
            seat = f"{random.randint(1, 15)}{random.choice('ABCD')}"
            status = 'Booked'
            has_promo = random.random() < 0.3
            promo_id = random.choice(promotion_ids) if has_promo else 'NULL'
            ticket_sqls.append(f"INSERT INTO Ticket (ticket_id, seat_number, status, schedule_id, promotion_id) VALUES ({ticket_id_counter}, '{seat}', '{status}', {schedule_id}, {promo_id});\n")
            booking_details_sqls.append(f"INSERT INTO BookingDetails (booking_id, ticket_id) VALUES ({booking_id}, {ticket_id_counter});\n")
            booked_tickets_data.append({'id': ticket_id_counter, 'booking_date': booking_date_obj, 'departure': departure_time})
            price = random.uniform(20.0, 150.0)
            if has_promo: price *= 0.9
            total_amount += price
            ticket_id_counter += 1
        f.write(booking_sql.format(total_amount=round(total_amount, 2)))
        f.writelines(ticket_sqls); f.writelines(booking_details_sqls)
        f.write("\n")

def generate_refunds(f):
    global booked_tickets_data
    f.write("-- Data for Refund Table\n")
    num_to_refund = min(NUM_REFUNDS, len(booked_tickets_data))
    tickets_to_refund = random.sample(booked_tickets_data, num_to_refund)
    for i in range(num_to_refund):
        refund_id = refund_ids[i]
        ticket_info = tickets_to_refund[i]
        ticket_id = ticket_info['id']
        time_diff = ticket_info['departure'] - ticket_info['booking_date']
        refund_offset = timedelta(seconds=random.randint(1, max(1, int(time_diff.total_seconds()) - 1)))
        refund_date_obj = ticket_info['booking_date'] + refund_offset
        amount = round(random.uniform(20.0, 100.0) * 0.7, 2)
        method = random.choice(PAYMENT_METHODS)
        f.write(f"INSERT INTO Refund (refund_id, refund_date, amount, refund_method, ticket_id) VALUES ({refund_id}, {sql_date(refund_date_obj)}, {amount}, '{method}', {ticket_id});\n")
    refunded_ids = {t['id'] for t in tickets_to_refund}
    booked_tickets_data = [t for t in booked_tickets_data if t['id'] not in refunded_ids]
    f.write("\n")

def generate_extensions(f):
    global booked_tickets_data
    f.write("-- Data for Extension Table\n")
    num_to_extend = min(NUM_EXTENSIONS, len(booked_tickets_data))
    tickets_to_extend = random.sample(booked_tickets_data, num_to_extend)
    for i in range(num_to_extend):
        extension_id = extension_ids[i]
        ticket_info = tickets_to_extend[i]
        ticket_id = ticket_info['id']
        time_diff = ticket_info['departure'] - ticket_info['booking_date']
        extension_offset = timedelta(seconds=random.randint(1, max(1, int(time_diff.total_seconds()) - 1)))
        extension_date_obj = ticket_info['booking_date'] + extension_offset
        amount = round(random.uniform(20.0, 100.0) + 5.0, 2)
        method = random.choice(PAYMENT_METHODS)
        f.write(f"INSERT INTO Extension (extension_id, extension_date, amount, extension_method, ticket_id) VALUES ({extension_id}, {sql_date(extension_date_obj)}, {amount}, '{method}', {ticket_id});\n")
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

def generate_companies(f):
    f.write("-- Data for Company Table\n")
    for i in company_ids: f.write(f"INSERT INTO Company (company_id, name) VALUES ({i}, '{sql_string(fake.company())}');\n")
    f.write("\n")
def generate_drivers(f):
    f.write("-- Data for Driver Table\n")
    for i in driver_ids: f.write(f"INSERT INTO Driver (driver_id, name, license_no) VALUES ({i}, '{sql_string(fake.name())}', '{fake.bothify(text='?#######??').upper()}');\n")
    f.write("\n")
def generate_staff(f):
    f.write("-- Data for Staff Table\n")
    for i in staff_ids: f.write(f"INSERT INTO Staff (staff_id, name, role, email, contact_no, employment_date, status) VALUES ({i}, '{sql_string(fake.name())}', '{random.choice(STAFF_ROLES)}', '{fake.unique.email()}', '{fake.phone_number()}', {sql_date(get_random_date())}, '{random.choice(STAFF_STATUSES)}');\n")
    f.write("\n")
def generate_shops(f):
    f.write("-- Data for Shop Table\n")
    for i in shop_ids: f.write(f"INSERT INTO Shop (shop_id, shop_name, location_code) VALUES ({i}, '{sql_string(fake.company() + ' Mart')}', '{fake.unique.bothify(text='L?-###').upper()}');\n")
    f.write("\n")
def generate_services(f):
    f.write("-- Data for Service Table\n")
    service_names = ['Bus Wash', 'Tyre Replacement', 'Engine Overhaul', 'Brake System Repair', 'Oil Change', 'AC Service', 'Full Inspection']
    for i in service_ids: f.write(f"INSERT INTO Service (service_id, service_name, standard_cost) VALUES ({i}, '{random.choice(service_names)}', {round(random.uniform(50.0, 2000.0), 2)});\n")
    f.write("\n")
def generate_members(f):
    f.write("-- Data for Member Table\n")
    for i in member_ids: f.write(f"INSERT INTO Member (member_id, name, email, contact_no, registration_date) VALUES ({i}, '{sql_string(fake.name())}', '{fake.unique.email()}', '{fake.phone_number()}', {sql_date(get_random_date())});\n")
    f.write("\n")
def generate_campaigns(f):
    f.write("-- Data for Campaign Table\n")
    for i in campaign_ids:
        start_date = get_random_date()
        end_date = start_date + timedelta(days=random.randint(30, 90))
        if end_date > END_DATE_GLOBAL: end_date = END_DATE_GLOBAL
        f.write(f"INSERT INTO Campaign (campaign_id, campaign_name, start_date, end_date) VALUES ({i}, '{sql_string(fake.catch_phrase())} Campaign', {sql_date(start_date)}, {sql_date(end_date)});\n")
    f.write("\n")
def generate_promotions(f):
    f.write("-- Data for Promotion Table\n")
    for i in promotion_ids:
        start_date = get_random_date()
        end_date = start_date + timedelta(days=random.randint(15, 60))
        if end_date > END_DATE_GLOBAL: end_date = END_DATE_GLOBAL
        disc_type = random.choice(PROMOTION_TYPES)
        disc_val = round(random.uniform(5, 20), 2) if disc_type == 'Percentage' else round(random.uniform(1, 10), 2)
        f.write(f"INSERT INTO Promotion (promotion_id, promotion_name, description, discount_type, discount_value, valid_from, valid_until, campaign_id) VALUES ({i}, '{sql_string(fake.bs().title())}', '{sql_string(fake.sentence(nb_words=8))}', '{disc_type}', {disc_val}, {sql_date(start_date)}, {sql_date(end_date)}, {random.choice(campaign_ids)});\n")
    f.write("\n")
def generate_buses(f):
    f.write("-- Data for Bus Table\n")
    for i in bus_ids: f.write(f"INSERT INTO Bus (bus_id, plate_number, capacity, company_id) VALUES ({i}, '{fake.unique.license_plate()}', {random.randint(40, 55)}, {random.choice(company_ids)});\n")
    f.write("\n")
def generate_payments(f):
    f.write("-- Data for Payment Table\n")
    for i in payment_ids: f.write(f"INSERT INTO Payment (payment_id, payment_date, amount, payment_method) VALUES ({i}, {sql_date(get_random_date())}, {round(random.uniform(15.0, 250.0), 2)}, '{random.choice(PAYMENT_METHODS)}');\n")
    f.write("\n")
def generate_rental_collections(f):
    f.write("-- Data for RentalCollection Table\n")
    for i in range(1, NUM_RENTAL_COLLECTIONS + 1):
        rental_date = get_random_date()
        coll_date = rental_date + timedelta(days=random.randint(0, 5))
        if coll_date > END_DATE_GLOBAL: coll_date = END_DATE_GLOBAL
        f.write(f"INSERT INTO RentalCollection (rental_id, rental_date, amount, collection_date, shop_id, staff_id) VALUES ({i}, {sql_date(rental_date)}, {round(random.uniform(500.0, 3000.0), 2)}, {sql_date(coll_date)}, {random.choice(shop_ids)}, {random.choice(staff_ids)});\n")
    f.write("\n")
def generate_service_details(f):
    f.write("-- Data for ServiceDetails Table\n")
    for i in service_detail_ids: f.write(f"INSERT INTO ServiceDetails (service_transaction_id, service_date, actual_cost, service_id, bus_id) VALUES ({i}, {sql_date(get_random_date())}, {round(random.uniform(100.0, 5000.0), 2)}, {random.choice(service_ids)}, {random.choice(bus_ids)});\n")
    f.write("\n")
def generate_driver_lists(f):
    f.write("-- Data for DriverList (Bridge) Table\n")
    pairs = set()
    attempts = 0
    while len(pairs) < NUM_DRIVER_LIST_ENTRIES and attempts < NUM_DRIVER_LIST_ENTRIES * 5:
        pair = (random.choice(schedule_ids), random.choice(driver_ids))
        if pair not in pairs:
            f.write(f"INSERT INTO DriverList (schedule_id, driver_id) VALUES ({pair[0]}, {pair[1]});\n")
            pairs.add(pair)
        attempts += 1
    f.write("\n")
def generate_staff_allocations(f):
    f.write("-- Data for StaffAllocation (Bridge) Table\n")
    pairs = set()
    attempts = 0
    while len(pairs) < NUM_STAFF_ALLOCATIONS and attempts < NUM_STAFF_ALLOCATIONS * 5:
        pair = (random.choice(service_detail_ids), random.choice(staff_ids))
        if pair not in pairs:
            f.write(f"INSERT INTO StaffAllocation (service_transaction_id, staff_id, role) VALUES ({pair[0]}, {pair[1]}, '{random.choice(['Technician', 'Cleaner'])}');\n")
            pairs.add(pair)
        attempts += 1
    f.write("\n")

# --- Script Execution ---
if __name__ == "__main__":
    if os.path.exists(OUTPUT_FILE):
        os.remove(OUTPUT_FILE)
    with open(OUTPUT_FILE, 'w') as f:
        generate_sql(f)
    print(f"Successfully generated {OUTPUT_FILE} with logically consistent chronological data.")