-- ============================================================================
-- Unit Tests: Expenses Table
-- Description: Unit tests for expenses table functionality and constraints
-- ============================================================================

-- Test setup and execution
DO $$
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_group_1 UUID;
  test_expense_id UUID;
BEGIN
  RAISE NOTICE 'Starting expenses table unit tests';

  -- ========================================================================
  -- Setup: Create test data
  -- ========================================================================
  
  -- Create test users
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES 
    ('expense_unit1@example.com', 'Expense Unit User 1', 'USD', 'en'),
    ('expense_unit2@example.com', 'Expense Unit User 2', 'EUR', 'vi')
  RETURNING id INTO test_user_1, test_user_2;

  -- Create test group
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Expense Unit Test Group', test_user_1, 'USD')
  RETURNING id INTO test_group_1;

  -- Add users to group
  INSERT INTO group_members (group_id, user_id, role)
  VALUES 
    (test_group_1, test_user_1, 'administrator'),
    (test_group_1, test_user_2, 'editor');

  -- ========================================================================
  -- Test 1: Basic expense creation
  -- ========================================================================
  
  RAISE NOTICE 'Test 1: Basic expense creation';
  
  -- Test creating expense with all required fields
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
  VALUES (test_group_1, test_user_1, 125.75, 'USD', 'Restaurant dinner', 'equal')
  RETURNING id INTO test_expense_id;
  
  -- Verify expense was created correctly
  PERFORM 1 FROM expenses 
  WHERE id = test_expense_id
    AND group_id = test_group_1
    AND payer_id = test_user_1
    AND amount = 125.75
    AND currency = 'USD'
    AND description = 'Restaurant dinner'
    AND split_method = 'equal'
    AND expense_date = CURRENT_DATE
    AND created_at IS NOT NULL
    AND updated_at IS NOT NULL
    AND deleted_at IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 1 FAILED: Basic expense creation failed';
  END IF;
  
  RAISE NOTICE 'Test 1 PASSED: Basic expense creation successful';

  -- ========================================================================
  -- Test 2: Default values
  -- ========================================================================
  
  RAISE NOTICE 'Test 2: Default values';
  
  -- Test creating expense with minimal fields (should use defaults)
  INSERT INTO expenses (group_id, payer_id, amount, currency, description)
  VALUES (test_group_1, test_user_2, 50.00, 'USD', 'Coffee')
  RETURNING id INTO test_expense_id;
  
  -- Verify defaults are applied
  PERFORM 1 FROM expenses 
  WHERE id = test_expense_id 
    AND split_method = 'equal'  -- Default split method
    AND expense_date = CURRENT_DATE;  -- Default expense date
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 2 FAILED: Default values not applied correctly';
  END IF;
  
  RAISE NOTICE 'Test 2 PASSED: Default values applied correctly';

  -- ========================================================================
  -- Test 3: Amount positive constraint
  -- ========================================================================
  
  RAISE NOTICE 'Test 3: Amount positive constraint';
  
  -- Test negative amount (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, -25.00, 'USD', 'Negative amount test');
    
    RAISE EXCEPTION 'Test 3 FAILED: Negative amount was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 3 PASSED: Negative amount correctly rejected';
  END;
  
  -- Test zero amount (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, 0.00, 'USD', 'Zero amount test');
    
    RAISE EXCEPTION 'Test 3 FAILED: Zero amount was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 3 PASSED: Zero amount correctly rejected';
  END;

  -- ========================================================================
  -- Test 4: Currency code validation
  -- ========================================================================
  
  RAISE NOTICE 'Test 4: Currency code validation';
  
  -- Test invalid currency length (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, 50.00, 'US', 'Short currency test');
    
    RAISE EXCEPTION 'Test 4 FAILED: Short currency code was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 4 PASSED: Short currency code correctly rejected';
  END;
  
  -- Test invalid currency format (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, 50.00, 'us1', 'Invalid currency format test');
    
    RAISE EXCEPTION 'Test 4 FAILED: Invalid currency format was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 4 PASSED: Invalid currency format correctly rejected';
  END;
  
  -- Test valid currencies
  INSERT INTO expenses (group_id, payer_id, amount, currency, description)
  VALUES 
    (test_group_1, test_user_1, 25.00, 'USD', 'USD test'),
    (test_group_1, test_user_1, 30.00, 'EUR', 'EUR test'),
    (test_group_1, test_user_1, 35.00, 'GBP', 'GBP test'),
    (test_group_1, test_user_1, 40.00, 'VND', 'VND test');
  
  -- Verify valid currencies were stored
  PERFORM 1 FROM expenses WHERE description = 'USD test' AND currency = 'USD';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 4 FAILED: Valid USD currency not stored';
  END IF;
  
  RAISE NOTICE 'Test 4 PASSED: Currency code validation working correctly';

  -- ========================================================================
  -- Test 5: Description validation
  -- ========================================================================
  
  RAISE NOTICE 'Test 5: Description validation';
  
  -- Test empty description (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, 50.00, 'USD', '');
    
    RAISE EXCEPTION 'Test 5 FAILED: Empty description was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 5 PASSED: Empty description correctly rejected';
  END;
  
  -- Test whitespace-only description (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, 50.00, 'USD', '   ');
    
    RAISE EXCEPTION 'Test 5 FAILED: Whitespace-only description was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 5 PASSED: Whitespace-only description correctly rejected';
  END;
  
  -- Test very long description (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, 50.00, 'USD', REPEAT('a', 501));
    
    RAISE EXCEPTION 'Test 5 FAILED: Too long description was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 5 PASSED: Too long description correctly rejected';
  END;

  -- ========================================================================
  -- Test 6: Split method enum validation
  -- ========================================================================
  
  RAISE NOTICE 'Test 6: Split method enum validation';
  
  -- Test all valid split methods
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
  VALUES 
    (test_group_1, test_user_1, 100.00, 'USD', 'Equal split', 'equal'),
    (test_group_1, test_user_1, 100.00, 'USD', 'Percentage split', 'percentage'),
    (test_group_1, test_user_1, 100.00, 'USD', 'Exact split', 'exact'),
    (test_group_1, test_user_1, 100.00, 'USD', 'Shares split', 'shares');
  
  -- Verify all split methods were stored correctly
  DECLARE
    split_count INTEGER;
  BEGIN
    SELECT COUNT(*) INTO split_count 
    FROM expenses 
    WHERE description IN ('Equal split', 'Percentage split', 'Exact split', 'Shares split');
    
    IF split_count != 4 THEN
      RAISE EXCEPTION 'Test 6 FAILED: Not all split methods stored correctly';
    END IF;
    
    RAISE NOTICE 'Test 6 PASSED: All split method enums stored correctly';
  END;

  -- ========================================================================
  -- Test 7: Foreign key constraints
  -- ========================================================================
  
  RAISE NOTICE 'Test 7: Foreign key constraints';
  
  -- Test invalid group_id (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (gen_random_uuid(), test_user_1, 50.00, 'USD', 'Invalid group test');
    
    RAISE EXCEPTION 'Test 7 FAILED: Invalid group_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Test 7 PASSED: Invalid group_id correctly rejected';
  END;
  
  -- Test invalid payer_id (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, gen_random_uuid(), 50.00, 'USD', 'Invalid payer test');
    
    RAISE EXCEPTION 'Test 7 FAILED: Invalid payer_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Test 7 PASSED: Invalid payer_id correctly rejected';
  END;

  -- ========================================================================
  -- Test 8: Notes validation
  -- ========================================================================
  
  RAISE NOTICE 'Test 8: Notes validation';
  
  -- Test valid notes
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, notes)
  VALUES (test_group_1, test_user_1, 45.00, 'USD', 'Expense with notes', 'These are valid notes');
  
  -- Test NULL notes (should be allowed)
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, notes)
  VALUES (test_group_1, test_user_1, 55.00, 'USD', 'Expense without notes', NULL);
  
  -- Test empty notes (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description, notes)
    VALUES (test_group_1, test_user_1, 65.00, 'USD', 'Empty notes test', '');
    
    RAISE EXCEPTION 'Test 8 FAILED: Empty notes were allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 8 PASSED: Empty notes correctly rejected';
  END;
  
  -- Test too long notes (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description, notes)
    VALUES (test_group_1, test_user_1, 75.00, 'USD', 'Long notes test', REPEAT('n', 1001));
    
    RAISE EXCEPTION 'Test 8 FAILED: Too long notes were allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 8 PASSED: Too long notes correctly rejected';
  END;

  -- ========================================================================
  -- Test 9: Expense date validation
  -- ========================================================================
  
  RAISE NOTICE 'Test 9: Expense date validation';
  
  -- Test past date (should be allowed)
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, expense_date)
  VALUES (test_group_1, test_user_1, 85.00, 'USD', 'Past expense', CURRENT_DATE - INTERVAL '30 days');
  
  -- Test current date (should be allowed)
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, expense_date)
  VALUES (test_group_1, test_user_1, 95.00, 'USD', 'Today expense', CURRENT_DATE);
  
  -- Test far future date (should fail)
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description, expense_date)
    VALUES (test_group_1, test_user_1, 105.00, 'USD', 'Far future expense', CURRENT_DATE + INTERVAL '10 days');
    
    RAISE EXCEPTION 'Test 9 FAILED: Far future date was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 9 PASSED: Far future date correctly rejected';
  END;

  -- ========================================================================
  -- Test 10: Timestamp behavior
  -- ========================================================================
  
  RAISE NOTICE 'Test 10: Timestamp behavior';
  
  -- Get an expense to test timestamps
  SELECT id INTO test_expense_id 
  FROM expenses 
  WHERE description = 'Restaurant dinner';
  
  DECLARE
    original_created_at TIMESTAMPTZ;
    original_updated_at TIMESTAMPTZ;
    new_created_at TIMESTAMPTZ;
    new_updated_at TIMESTAMPTZ;
  BEGIN
    -- Get original timestamps
    SELECT created_at, updated_at INTO original_created_at, original_updated_at
    FROM expenses WHERE id = test_expense_id;
    
    -- Wait a moment to ensure timestamp difference
    PERFORM pg_sleep(0.1);
    
    -- Update the expense
    UPDATE expenses 
    SET description = 'Updated restaurant dinner'
    WHERE id = test_expense_id;
    
    -- Get new timestamps
    SELECT created_at, updated_at INTO new_created_at, new_updated_at
    FROM expenses WHERE id = test_expense_id;
    
    -- Verify created_at didn't change
    IF new_created_at != original_created_at THEN
      RAISE EXCEPTION 'Test 10 FAILED: created_at changed on update';
    END IF;
    
    -- Verify updated_at changed
    IF new_updated_at <= original_updated_at THEN
      RAISE EXCEPTION 'Test 10 FAILED: updated_at not updated on modification';
    END IF;
    
    RAISE NOTICE 'Test 10 PASSED: Timestamps behave correctly (created_at preserved, updated_at changed)';
  END;

  -- ========================================================================
  -- Test 11: Cascade delete behavior
  -- ========================================================================
  
  RAISE NOTICE 'Test 11: Cascade delete behavior';
  
  -- Create another group and expense for testing
  DECLARE
    test_group_2 UUID;
    expense_count_before INTEGER;
    expense_count_after INTEGER;
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency)
    VALUES ('Temp Test Group', test_user_2, 'EUR')
    RETURNING id INTO test_group_2;
    
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_2, test_user_2, 'administrator');
    
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_2, test_user_2, 150.00, 'EUR', 'Temp expense for cascade test');
    
    SELECT COUNT(*) INTO expense_count_before 
    FROM expenses WHERE group_id = test_group_2;
    
    -- Delete the group
    DELETE FROM groups WHERE id = test_group_2;
    
    -- Verify expenses were cascade deleted
    SELECT COUNT(*) INTO expense_count_after 
    FROM expenses WHERE group_id = test_group_2;
    
    IF expense_count_after != 0 THEN
      RAISE EXCEPTION 'Test 11 FAILED: Expenses not cascade deleted with group';
    END IF;
    
    RAISE NOTICE 'Test 11 PASSED: Expenses cascade deleted with group (% -> %)', 
      expense_count_before, expense_count_after;
  END;

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up unit test data';
  
  -- Clean up test data (cascade will handle related records)
  DELETE FROM users WHERE email LIKE 'expense_unit%@example.com';
  DELETE FROM groups WHERE name LIKE '%Unit Test Group%';
  
  RAISE NOTICE 'All expenses table unit tests completed successfully!';

END;
$$;