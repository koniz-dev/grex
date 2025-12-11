-- ============================================================================
-- Property Tests: Payments Table
-- Description: Property-based tests for payments table correctness
-- ============================================================================

-- Test setup: Create test data
DO $$
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_user_3 UUID;
  test_group_1 UUID;
  test_payment_1 UUID;
  test_payment_2 UUID;
BEGIN
  -- Create test users
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES 
    ('payment1@example.com', 'Payment User 1', 'USD', 'en'),
    ('payment2@example.com', 'Payment User 2', 'USD', 'en'),
    ('payment3@example.com', 'Payment User 3', 'USD', 'en')
  RETURNING id INTO test_user_1, test_user_2, test_user_3;

  -- Create test group
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Test Payment Group', test_user_1, 'USD')
  RETURNING id INTO test_group_1;

  -- Create group memberships
  INSERT INTO group_members (group_id, user_id, role)
  VALUES 
    (test_group_1, test_user_1, 'administrator'),
    (test_group_1, test_user_2, 'editor'),
    (test_group_1, test_user_3, 'editor');

  -- ========================================================================
  -- Property 20: Payment creation includes all required fields
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 20: Payment creation includes all required fields';
  
  -- Test: Create payment with all required fields
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
  VALUES (test_group_1, test_user_1, test_user_2, 50.00, 'USD', 'Test payment')
  RETURNING id INTO test_payment_1;
  
  -- Verify all required fields are populated
  PERFORM 1 FROM payments 
  WHERE id = test_payment_1
    AND group_id IS NOT NULL
    AND payer_id IS NOT NULL
    AND recipient_id IS NOT NULL
    AND amount IS NOT NULL
    AND currency IS NOT NULL
    AND payment_date IS NOT NULL
    AND created_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 20 FAILED: Payment creation missing required fields';
  END IF;
  
  RAISE NOTICE 'Property 20 PASSED: All required fields populated on payment creation';

  -- ========================================================================
  -- Property 21: Payment constraints are enforced
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 21: Payment constraints are enforced';
  
  -- Test: Positive amount constraint
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_2, test_user_3, -25.00, 'USD');
    
    RAISE EXCEPTION 'Property 21 FAILED: Negative payment amount was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 21 PASSED: Negative payment amount correctly rejected';
  END;
  
  -- Test: Payer != recipient constraint
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_1, test_user_1, 30.00, 'USD');
    
    RAISE EXCEPTION 'Property 21 FAILED: Self-payment was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 21 PASSED: Self-payment correctly rejected';
  END;
  
  -- Test: Currency code length constraint
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_2, test_user_3, 40.00, 'INVALID');
    
    RAISE EXCEPTION 'Property 21 FAILED: Invalid currency code was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 21 PASSED: Invalid currency code correctly rejected';
  END;
  
  -- Test: Valid payment creation
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
  VALUES (test_group_1, test_user_2, test_user_3, 75.00, 'EUR')
  RETURNING id INTO test_payment_2;
  
  IF test_payment_2 IS NULL THEN
    RAISE EXCEPTION 'Property 21 FAILED: Valid payment creation failed';
  END IF;
  
  RAISE NOTICE 'Property 21 PASSED: All payment constraints enforced correctly';

  -- ========================================================================
  -- Property 22: Payment deletion does not cascade
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 22: Payment deletion does not cascade';
  
  -- Test: Delete payment directly (should succeed without affecting users/groups)
  DECLARE
    user_count_before INTEGER;
    user_count_after INTEGER;
    group_count_before INTEGER;
    group_count_after INTEGER;
  BEGIN
    -- Count users and groups before payment deletion
    SELECT COUNT(*) INTO user_count_before FROM users 
    WHERE id IN (test_user_1, test_user_2, test_user_3);
    
    SELECT COUNT(*) INTO group_count_before FROM groups 
    WHERE id = test_group_1;
    
    -- Delete the payment
    DELETE FROM payments WHERE id = test_payment_1;
    
    -- Count users and groups after payment deletion
    SELECT COUNT(*) INTO user_count_after FROM users 
    WHERE id IN (test_user_1, test_user_2, test_user_3);
    
    SELECT COUNT(*) INTO group_count_after FROM groups 
    WHERE id = test_group_1;
    
    -- Verify users and groups are unchanged
    IF user_count_before != user_count_after THEN
      RAISE EXCEPTION 'Property 22 FAILED: Payment deletion affected users';
    END IF;
    
    IF group_count_before != group_count_after THEN
      RAISE EXCEPTION 'Property 22 FAILED: Payment deletion affected groups';
    END IF;
    
    RAISE NOTICE 'Property 22 PASSED: Payment deletion does not cascade to users/groups';
  END;

  -- ========================================================================
  -- Property 23: Payment timestamp is set automatically
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 23: Payment timestamp is set automatically';
  
  -- Test: Verify created_at is set automatically
  DECLARE
    payment_created_at TIMESTAMPTZ;
  BEGIN
    SELECT created_at INTO payment_created_at 
    FROM payments WHERE id = test_payment_2;
    
    -- Verify timestamp is recent (within last minute)
    IF payment_created_at < NOW() - INTERVAL '1 minute' THEN
      RAISE EXCEPTION 'Property 23 FAILED: created_at timestamp not set correctly';
    END IF;
    
    -- Verify payment_date is set to current date by default
    PERFORM 1 FROM payments 
    WHERE id = test_payment_2 AND payment_date = CURRENT_DATE;
    
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Property 23 FAILED: payment_date not set to current date';
    END IF;
    
    RAISE NOTICE 'Property 23 PASSED: Payment timestamps set automatically';
  END;

  -- ========================================================================
  -- Additional Property Tests
  -- ========================================================================
  
  -- Test: Foreign key constraints are enforced
  RAISE NOTICE 'Testing foreign key constraints';
  
  -- Test: Invalid group_id is rejected
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (gen_random_uuid(), test_user_1, test_user_2, 25.00, 'USD');
    
    RAISE EXCEPTION 'Foreign key constraint FAILED: Invalid group_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Foreign key constraint PASSED: Invalid group_id correctly rejected';
  END;
  
  -- Test: Invalid payer_id is rejected
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, gen_random_uuid(), test_user_2, 25.00, 'USD');
    
    RAISE EXCEPTION 'Foreign key constraint FAILED: Invalid payer_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Foreign key constraint PASSED: Invalid payer_id correctly rejected';
  END;
  
  -- Test: Invalid recipient_id is rejected
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_1, gen_random_uuid(), 25.00, 'USD');
    
    RAISE EXCEPTION 'Foreign key constraint FAILED: Invalid recipient_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Foreign key constraint PASSED: Invalid recipient_id correctly rejected';
  END;

  -- Test: Cascade delete when group is deleted
  RAISE NOTICE 'Testing cascade delete when group is deleted';
  
  DECLARE
    payment_count_before INTEGER;
    payment_count_after INTEGER;
  BEGIN
    SELECT COUNT(*) INTO payment_count_before 
    FROM payments WHERE group_id = test_group_1;
    
    -- Delete the group
    DELETE FROM groups WHERE id = test_group_1;
    
    -- Count payments after group deletion
    SELECT COUNT(*) INTO payment_count_after 
    FROM payments WHERE group_id = test_group_1;
    
    IF payment_count_after != 0 THEN
      RAISE EXCEPTION 'Cascade delete FAILED: Payments not deleted with group';
    END IF;
    
    RAISE NOTICE 'Cascade delete PASSED: Payments deleted when group deleted (% -> %)', 
      payment_count_before, payment_count_after;
  END;

  -- Test: Cascade delete when user is deleted
  RAISE NOTICE 'Testing cascade delete when user is deleted';
  
  -- Create new test data for user deletion test
  DECLARE
    test_user_4 UUID;
    test_user_5 UUID;
    test_group_2 UUID;
    user_payment_count_before INTEGER;
    user_payment_count_after INTEGER;
  BEGIN
    INSERT INTO users (email, display_name)
    VALUES 
      ('payment4@example.com', 'Payment User 4'),
      ('payment5@example.com', 'Payment User 5')
    RETURNING id INTO test_user_4, test_user_5;
    
    INSERT INTO groups (name, creator_id)
    VALUES ('Test Payment Group 2', test_user_4)
    RETURNING id INTO test_group_2;
    
    INSERT INTO group_members (group_id, user_id, role)
    VALUES 
      (test_group_2, test_user_4, 'administrator'),
      (test_group_2, test_user_5, 'editor');
    
    -- Create payment involving test_user_5
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_2, test_user_4, test_user_5, 100.00, 'USD');
    
    SELECT COUNT(*) INTO user_payment_count_before 
    FROM payments WHERE payer_id = test_user_5 OR recipient_id = test_user_5;
    
    -- Delete the user
    DELETE FROM users WHERE id = test_user_5;
    
    -- Count payments after user deletion
    SELECT COUNT(*) INTO user_payment_count_after 
    FROM payments WHERE payer_id = test_user_5 OR recipient_id = test_user_5;
    
    IF user_payment_count_after != 0 THEN
      RAISE EXCEPTION 'Cascade delete FAILED: Payments not deleted with user';
    END IF;
    
    RAISE NOTICE 'Cascade delete PASSED: Payments deleted when user deleted (% -> %)', 
      user_payment_count_before, user_payment_count_after;
  END;

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up test data';
  
  -- Clean up test data (cascade will handle related records)
  DELETE FROM users WHERE email LIKE 'payment%@example.com';
  DELETE FROM groups WHERE name LIKE 'Test Payment Group%';
  
  RAISE NOTICE 'All payments table property tests completed successfully!';

END;
$$;