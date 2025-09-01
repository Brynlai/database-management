--=============================================================================
-- File: 02a_sync_sequences.sql
--=============================================================================
-- Sequence still starts at 1, but after inserting example 10 rows, 1 already used, so need to reset to use max_value + 1 for primary key value.
--=============================================================================

SET SERVEROUTPUT ON;

DECLARE
  -- Helper procedure to find the max ID, drop the sequence, and recreate it
  -- starting at the correct value. This is a standard practice for bulk loads.
  PROCEDURE reset_sequence(p_seq_name IN VARCHAR2, p_table_name IN VARCHAR2, p_pk_column IN VARCHAR2) IS
    l_max_id NUMBER;
  BEGIN
    -- Find the highest current primary key value in the table
    EXECUTE IMMEDIATE 'SELECT COALESCE(MAX(' || p_pk_column || '), 0) FROM ' || p_table_name INTO l_max_id;
    
    -- Add 1 to start the sequence at the next available value
    l_max_id := l_max_id + 1;

    -- Drop the existing sequence
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || p_seq_name;
    
    -- Recreate the sequence starting with the correct new value
    EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || p_seq_name || ' START WITH ' || l_max_id || ' INCREMENT BY 1 NOCACHE';
    
    DBMS_OUTPUT.PUT_LINE('Sequence ' || RPAD(p_seq_name, 25) || ' reset to start at ' || l_max_id);
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error resetting sequence ' || p_seq_name || '. Manual check required. Error: ' || SQLERRM);
  END reset_sequence;

BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Starting Sequence Synchronization ---');

  reset_sequence('company_seq', 'Company', 'company_id');
  reset_sequence('bus_seq', 'Bus', 'bus_id');
  reset_sequence('schedule_seq', 'Schedule', 'schedule_id');
  reset_sequence('driver_seq', 'Driver', 'driver_id');
  reset_sequence('staff_seq', 'Staff', 'staff_id');
  reset_sequence('shop_seq', 'Shop', 'shop_id');
  reset_sequence('rental_collection_seq', 'RentalCollection', 'rental_id');
  reset_sequence('service_seq', 'Service', 'service_id');
  reset_sequence('service_details_seq', 'ServiceDetails', 'service_transaction_id');
  reset_sequence('campaign_seq', 'Campaign', 'campaign_id');
  reset_sequence('promotion_seq', 'Promotion', 'promotion_id');
  reset_sequence('member_seq', 'Member', 'member_id');
  reset_sequence('payment_seq', 'Payment', 'payment_id');
  reset_sequence('booking_seq', 'Booking', 'booking_id');
  reset_sequence('ticket_seq', 'Ticket', 'ticket_id');
  reset_sequence('refund_seq', 'Refund', 'refund_id');
  reset_sequence('extension_seq', 'Extension', 'extension_id');

  DBMS_OUTPUT.PUT_LINE('--- Sequence Synchronization Complete ---');
END;
/

COMMIT;

