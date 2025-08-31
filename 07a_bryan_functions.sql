--=============================================================================
-- File: 07a_bryan_functions.sql
--=============================================================================
-- Purpose: Creates reusable User-Defined Functions for the system.
--=============================================================================

SET SERVEROUTPUT ON;

PROMPT Creating Function: calculate_final_ticket_price
CREATE OR REPLACE FUNCTION calculate_final_ticket_price (
    p_ticket_id IN Ticket.ticket_id%TYPE
)
RETURN NUMBER
IS
    v_base_price    Schedule.base_price%TYPE;
    v_promo_type    Promotion.discount_type%TYPE;
    v_promo_value   Promotion.discount_value%TYPE;
    v_final_price   NUMBER;
BEGIN
    -- This query joins the necessary tables to get the price and any promotion details.
    -- A LEFT JOIN is crucial because not every ticket has a promotion.
    SELECT
        s.base_price,
        p.discount_type,
        p.discount_value
    INTO
        v_base_price,
        v_promo_type,
        v_promo_value
    FROM Ticket t
    JOIN Schedule s ON t.schedule_id = s.schedule_id
    LEFT JOIN Promotion p ON t.promotion_id = p.promotion_id
    WHERE t.ticket_id = p_ticket_id;

    -- Apply the discount logic based on the promotion type
    IF v_promo_type = 'Percentage' THEN
        v_final_price := v_base_price * (1 - (v_promo_value / 100));
    ELSIF v_promo_type = 'Fixed Amount' THEN
        v_final_price := v_base_price - v_promo_value;
    ELSE
        -- If there is no promotion (v_promo_type is NULL), the price is the base price.
        v_final_price := v_base_price;
    END IF;

    -- Ensure the final price never drops below zero
    RETURN GREATEST(v_final_price, 0);

EXCEPTION
    -- If an invalid ticket_id is passed, return 0 instead of crashing.
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
END calculate_final_ticket_price;
/

COMMIT;