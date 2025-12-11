-- ============================================================================
-- Unit Tests: Payments Table
-- Description: Unit tests for payments table functionality and constraints
-- ============================================================================

-- Test setup and execution
DO $$
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_user_3 UUID;
  test_group_1 UUID;
  test_payment_id UUID;
BEGIN
  RAISE NOTICE 'Starting payments table unit tests';

  -- ========================================================================
  -- Setup: Create test data
  -- ========================================================================
  
  -- Create test users
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES 
    ('unit_payment1@example.com', 'Unit Test Payment User 1', 'USD', 'en'),
    ('unit_payment2@example.com', 'Unit Test Payment User 2', 'USD', 'en'),
    ('unit_payment3@example.com', 'Unit Test Payment User 3', 'USD', 'en')
  RETURNING id INTO test_user_1, test_user_2, test_user_3;

  -- Create test group
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Unit Test Payment Group', test_user_1, 'USD')
  RETURNING id INTO test_group_1;

  -- Create group memberships
  INSERT INTO group_members (group_id, user_id, role)
  VALUES 
    (test_group_1, test_user_1, 'administrator'),
    (test_group_1, test_user_2, 'editor'),
    (test_group_1, test_user_3, 'editor');

  -- ========================================================================
  -- Test 1: Basic payment creation
  -- ========================================================================
  
  RAISE NOTICE 'Test 1: Basic payment creation';
  
  -- Test creating payment with required fields
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
  VALUES (test_group_1, test_user_1, test_user_2, 50.00, 'USD', 'Test payment')
  RETURNING id INTO test_payment_id;
  
  -- Verify payment was created
  PERFORM 1 FROM payments 
  WHERE id = test_payment_id
    AND group_id = test_group_1
    AND payer_id = test_user_1
    AND recipient_id = test_user_2
    AND amount = 50.00
    AND currency = 'USD'
    AND notes = 'Test payment'
    AND payment_date = CURRENT_DATE
    AND created_at IS NOT NULL
    AND deleted_at IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 1 FAILED: Basic payment creation failed';
  END IF;
  
  RAISE NOTICE 'Test 1 PASSED: Basic payment creation successful';

  -- ========================================================================
  -- Test 2: Amount positive constraint
  -- ========================================================================
  
  RAISE NOTICE 'Test 2: Amount positive constraint';
  
  -- Test valid positive amount
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
  VALUES (test_group_1, test_user_2, test_user_3, 25.00, 'USD');
  
  -- Test invalid zero amount
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_3, test_user_1, 0.00, 'USD');
    
    RAISE EXCEPTION 'Test 2 FAILED: Zero payment amount was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 2 PASSED: Zero payment amount correctly rejected';
  END;
  
  -- Test invalid negative amount
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_3, test_user_1, -15.00, 'USD');
    
    RAISE EXCEPTION 'Test 2 FAILED: Negative payment amount was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 2 PASSED: Negative payment amount correctly rejected';
  END;

  -- ========================================================================
  -- Test 3: Payer not recipient constraint
  -- ========================================================================
  
  RAISE NOTICE 'Test 3: Payer not recipient constraint';
  
  -- Test valid different payer and recipient (already tested above)
  -- Test invalid same payer and recipient
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_1, test_user_1, 30.00, 'USD');
    
    RAISE EXCEPTION 'Test 3 FAILED: Self-payment was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 3 PASSED: Self-payment correctly rejected';
  END;

  -- ========================================================================
  -- Test 4: Currency code validation
  -- ========================================================================
  
  RAISE NOTICE 'Test 4: Currency code validation';
  
  -- Test valid currency codes
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
  VALUES (test_group_1, test_user_1, test_user_3, 100.00, 'EUR');
  
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
  VALUES (test_group_1, test_user_2, test_user_1, 75.00, 'GBP');
  
  -- Test invalid currency code (wrong length)
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_3, test_user_2, 40.00, 'DOLLAR');
    
    RAISE EXCEPTION 'Test 4 FAILED: Invalid currency code length was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 4 PASSED: Invalid currency code length correctly rejected';
  END;
  
  -- Test invalid currency code (wrong format)
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_3, test_user_2, 40.00, 'us1');
    
    RAISE EXCEPTION 'Test 4 FAILED: Invalid currency code format was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 4 PASSED: Invalid currency code format correctly rejected';
  END;

  -- ========================================================================
  -- Test 5: Notes validation
  -- ========================================================================
  
  RAISE NOTICE 'Test 5: Notes validation';
  
  -- Test valid notes (NULL)
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
  VALUES (test_group_1, test_user_1, test_user_2, 20.00, 'USD', NULL);
  
  -- Test valid notes (non-empty)
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
  VALUES (test_group_1, test_user_2, test_user_3, 35.00, 'USD', 'Valid payment note');
  
  -- Test invalid notes (empty string)
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
    VALUES (test_group_1, test_user_3, test_user_1, 45.00, 'USD', '   ');
    
    RAISE EXCEPTION 'Test 5 FAILED: Empty notes string was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 5 PASSED: Empty notes string correctly rejected';
  END;

  -- ========================================================================
  -- Test 6: Foreign key constraint to groups table
  -- ========================================================================
  
  RAISE NOTICE 'Test 6: Foreign key constraint to groups table';
  
  -- Test invalid group_id (should fail)
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (gen_random_uuid(), test_user_1, test_user_2, 25.00, 'USD');
    
    RAISE EXCEPTION 'Test 6 FAILED: Invalid group_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Test 6 PASSED: Invalid group_id correctly rejected';
  END;

  -- ========================================================================
  -- Test 7: Foreign key constraint to users table
  -- ========================================================================
  
  RAISE NOTICE 'Test 7: Foreign key constraint to users table';
  
  -- Test invalid payer_id (should fail)
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, gen_random_uuid(), test_user_2, 25.00, 'USD');
    
    RAISE EXCEPTION 'Test 7 FAILED: Invalid payer_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Test 7 PASSED: Invalid payer_id correctly rejected';
  END;
  
  -- Test invalid recipient_id (should fail)
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_1, gen_random_uuid(), 25.00, 'USD');
    
    RAISE EXCEPTION 'Test 7 FAILED: Invalid recipient_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Test 7 PASSED: Invalid recipient_id correctly rejected';
  END;

  -- ========================================================================
  -- Test 8: Cascade delete when group is deleted
  -- ========================================================================
  
  RAISE NOTICE 'Test 8: Cascade delete when group is deleted';
  
  -- Create separate group with payments for cascade test
  DECLARE
    test_group_2 UUID;
    payment_count INTEGER;
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency)
    VALUES ('Cascade Test Group', test_user_1, 'USD')
    RETURNING id INTO test_group_2;
    
    INSERT INTO group_members (group_id, user_id, role)
    VALUES 
      (test_group_2, test_user_1, 'administrator'),
      (test_group_2, test_user_2, 'editor');
    
    -- Add payments to the group
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES 
      (test_group_2, test_user_1, test_user_2, 60.00, 'USD'),
      (test_group_2, test_user_2, test_user_1, 40.00, 'USD');
    
    -- Verify payments exist
    SELECT COUNT(*) INTO payment_count 
    FROM payments WHERE group_id = test_group_2;
    
    IF payment_count != 2 THEN
      RAISE EXCEPTION 'Test 8 SETUP FAILED: Expected 2 payments, found %', payment_count;
    END IF;
    
    -- Delete the group
    DELETE FROM groups WHERE id = test_group_2;
    
    -- Verify all payments were deleted
    SELECT COUNT(*) INTO payment_count 
    FROM payments WHERE group_id = test_group_2;
    
    IF payment_count != 0 THEN
      RAISE EXCEPTION 'Test 8 FAILED: Payments not deleted when group deleted';
    END IF;
    
    RAISE NOTICE 'Test 8 PASSED: Payments cascade deleted with group';
  END;

  -- ========================================================================
  -- Test 9: Cascade delete when user is deleted
  -- ========================================================================
  
  RAISE NOTICE 'Test 9: Cascade delete when user is deleted';
  
  -- Count payments involving test_user_3 before deletion
  DECLARE
    user_payment_count INTEGER;
  BEGIN
    SELECT COUNT(*) INTO user_payment_count 
    FROM payments WHERE payer_id = test_user_3 OR recipient_id = test_user_3;
    
    -- Delete the user
    DELETE FROM users WHERE id = test_user_3;
    
    -- Verify all payments involving the user were deleted
    SELECT COUNT(*) INTO user_payment_count 
    FROM payments WHERE payer_id = test_user_3 OR recipient_id = test_user_3;
    
    IF user_payment_count != 0 THEN
      RAISE EXCEPTION 'Test 9 FAILED: Payments not deleted when user deleted';
    END IF;
    
    RAISE NOTICE 'Test 9 PASSED: Payments cascade deleted with user';
  END;

  -- ========================================================================
  -- Test 10: Timestamp behavior
  -- ========================================================================
  
  RAISE NOTICE 'Test 10: Timestamp behavior';
  
  -- Get a payment to test timestamps
  SELECT id INTO test_payment_id 
  FROM payments 
  WHERE group_id = test_group_1 AND payer_id = test_user_1
  LIMIT 1;
  
  DECLARE
    created_timestamp TIMESTAMPTZ;
    payment_date_value DATE;
  BEGIN
    -- Get timestamps
    SELECT created_at, payment_date INTO created_timestamp, payment_date_value
    FROM payments WHERE id = test_payment_id;
    
    -- Verify created_at timestamp is recent (within last minute)
    IF created_timestamp < NOW() - INTERVAL '1 minute' THEN
      RAISE EXCEPTION 'Test 10 FAILED: created_at timestamp not set correctly';
    END IF;
    
    -- Verify payment_date is set to current date by default
    IF payment_date_value != CURRENT_DATE THEN
      RAISE EXCEPTION 'Test 10 FAILED: payment_date not set to current date';
    END IF;
    
    RAISE NOTICE 'Test 10 PASSED: Timestamps set correctly on creation';
  END;

  -- ========================================================================
  -- Test 11: Payment date validation
  -- ========================================================================
  
  RAISE NOTICE 'Test 11: Payment date validation';
  
  -- Test valid payment date (today)
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date)
  VALUES (test_group_1, test_user_1, test_user_2, 15.00, 'USD', CURRENT_DATE);
  
  -- Test valid payment date (yesterday)
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date)
  VALUES (test_group_1, test_user_2, test_user_1, 25.00, 'USD', CURRENT_DATE - INTERVAL '1 day');
  
  -- Test invalid payment date (too far in future)
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date)
    VALUES (test_group_1, test_user_1, test_user_2, 35.00, 'USD', CURRENT_DATE + INTERVAL '2 days');
    
    RAISE EXCEPTION 'Test 11 FAILED: Future payment date was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 11 PASSED: Future payment date correctly rejected';
  END;

  -- ========================================================================
  -- Test 12: Soft delete functionality
  -- ========================================================================
  
  RAISE NOTICE 'Test 12: Soft delete functionality';
  
  -- Test soft delete by setting deleted_at
  DECLARE
    test_payment_soft_delete UUID;
  BEGIN
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency)
    VALUES (test_group_1, test_user_1, test_user_2, 80.00, 'USD')
    RETURNING id INTO test_payment_soft_delete;
    
    -- Soft delete the payment
    UPDATE payments SET deleted_at = NOW() WHERE id = test_payment_soft_delete;
    
    -- Verify payment is soft deleted
    PERFORM 1 FROM payments 
    WHERE id = test_payment_soft_delete AND deleted_at IS NOT NULL;
    
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Test 12 FAILED: Soft delete not working';
    END IF;
    
    RAISE NOTICE 'Test 12 PASSED: Soft delete functionality works correctly';
  END;

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up unit test data';
  
  -- Clean up test data (cascade will handle related records)
  DELETE FROM users WHERE email LIKE 'unit_payment%@example.com';
  DELETE FROM groups WHERE name LIKE 'Unit Test Payment Group%' OR name = 'Cascade Test Group';
  
  RAISE NOTICE 'All payments table unit tests completed successfully!';

END;
$$;