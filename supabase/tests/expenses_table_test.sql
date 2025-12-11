-- ============================================================================
-- Property Tests: Expenses Table
-- Description: Property-based tests for expenses table correctness
-- ============================================================================

-- Test setup: Create test data
DO $$
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_group_1 UUID;
  test_group_2 UUID;
  test_expense_1 UUID;
  test_expense_2 UUID;
BEGIN
  -- Create test users
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES 
    ('expense_test1@example.com', 'Expense Test User 1', 'USD', 'en'),
    ('expense_test2@example.com', 'Expense Test User 2', 'EUR', 'vi')
  RETURNING id INTO test_user_1, test_user_2;

  -- Create test groups
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES 
    ('Expense Test Group 1', test_user_1, 'USD'),
    ('Expense Test Group 2', test_user_2, 'EUR')
  RETURNING id INTO test_group_1, test_group_2;

  -- Add users to groups
  INSERT INTO group_members (group_id, user_id, role)
  VALUES 
    (test_group_1, test_user_1, 'administrator'),
    (test_group_1, test_user_2, 'editor'),
    (test_group_2, test_user_2, 'administrator');

  -- ========================================================================
  -- Property 12: Expense creation includes all required fields
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 12: Expense creation includes all required fields';
  
  -- Test: Create expense with all required fields
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
  VALUES (test_group_1, test_user_1, 100.50, 'USD', 'Test dinner expense', 'equal')
  RETURNING id INTO test_expense_1;
  
  -- Verify all required fields are populated
  PERFORM 1 FROM expenses 
  WHERE id = test_expense_1
    AND group_id IS NOT NULL
    AND payer_id IS NOT NULL
    AND amount IS NOT NULL
    AND currency IS NOT NULL
    AND description IS NOT NULL
    AND expense_date IS NOT NULL
    AND split_method IS NOT NULL
    AND created_at IS NOT NULL
    AND updated_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 12 FAILED: Expense creation missing required fields';
  END IF;
  
  RAISE NOTICE 'Property 12 PASSED: All required fields populated on expense creation';

  -- ========================================================================
  -- Property 13: Expense constraints are enforced
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 13: Expense constraints are enforced';
  
  -- Test: Positive amount constraint
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, -50.00, 'USD', 'Negative amount test');
    
    RAISE EXCEPTION 'Property 13 FAILED: Negative amount was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 13 PASSED: Negative amount correctly rejected';
  END;
  
  -- Test: Currency code length constraint
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, 50.00, 'USDD', 'Invalid currency test');
    
    RAISE EXCEPTION 'Property 13 FAILED: Invalid currency code was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 13 PASSED: Invalid currency code correctly rejected';
  END;
  
  -- Test: Empty description constraint
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, 50.00, 'USD', '   ');
    
    RAISE EXCEPTION 'Property 13 FAILED: Empty description was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 13 PASSED: Empty description correctly rejected';
  END;
  
  -- Test: Valid expense creation
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, notes)
  VALUES (test_group_1, test_user_2, 75.25, 'USD', 'Valid expense test', 'Test notes')
  RETURNING id INTO test_expense_2;
  
  -- Verify valid expense was created
  PERFORM 1 FROM expenses 
  WHERE id = test_expense_2
    AND amount = 75.25
    AND currency = 'USD'
    AND description = 'Valid expense test'
    AND notes = 'Test notes';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 13 FAILED: Valid expense not created correctly';
  END IF;
  
  RAISE NOTICE 'Property 13 PASSED: Valid expense constraints enforced correctly';

  -- ========================================================================
  -- Property 14: Expense deletion cascades to participants
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 14: Expense deletion cascades to participants';
  
  -- Note: This will be fully tested when expense_participants table is created
  -- For now, we test that expense can be deleted without issues
  
  DELETE FROM expenses WHERE id = test_expense_2;
  
  -- Verify expense was deleted
  PERFORM 1 FROM expenses WHERE id = test_expense_2;
  
  IF FOUND THEN
    RAISE EXCEPTION 'Property 14 FAILED: Expense not deleted';
  END IF;
  
  RAISE NOTICE 'Property 14 PASSED: Expense deletion works (participants cascade will be tested later)';

  -- ========================================================================
  -- Property 15: Expense update modifies timestamp
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 15: Expense update modifies timestamp';
  
  DECLARE
    original_updated_at TIMESTAMPTZ;
    new_updated_at TIMESTAMPTZ;
  BEGIN
    -- Get original timestamp
    SELECT updated_at INTO original_updated_at 
    FROM expenses WHERE id = test_expense_1;
    
    -- Wait a moment to ensure timestamp difference
    PERFORM pg_sleep(0.1);
    
    -- Update the expense
    UPDATE expenses 
    SET description = 'Updated test dinner expense'
    WHERE id = test_expense_1;
    
    -- Get new timestamp
    SELECT updated_at INTO new_updated_at 
    FROM expenses WHERE id = test_expense_1;
    
    IF new_updated_at <= original_updated_at THEN
      RAISE EXCEPTION 'Property 15 FAILED: updated_at not changed on update';
    END IF;
    
    RAISE NOTICE 'Property 15 PASSED: updated_at changed from % to %', 
      original_updated_at, new_updated_at;
  END;

  -- ========================================================================
  -- Additional Property Tests
  -- ========================================================================
  
  -- Test: Foreign key constraints are enforced
  RAISE NOTICE 'Testing foreign key constraints';
  
  -- Test: Invalid group_id is rejected
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (gen_random_uuid(), test_user_1, 50.00, 'USD', 'Invalid group test');
    
    RAISE EXCEPTION 'Foreign key constraint FAILED: Invalid group_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Foreign key constraint PASSED: Invalid group_id correctly rejected';
  END;
  
  -- Test: Invalid payer_id is rejected
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, gen_random_uuid(), 50.00, 'USD', 'Invalid payer test');
    
    RAISE EXCEPTION 'Foreign key constraint FAILED: Invalid payer_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Foreign key constraint PASSED: Invalid payer_id correctly rejected';
  END;

  -- Test: Split method enum validation
  RAISE NOTICE 'Testing split method enum validation';
  
  -- Test all valid split methods
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
  VALUES 
    (test_group_1, test_user_1, 25.00, 'USD', 'Equal split test', 'equal'),
    (test_group_1, test_user_1, 30.00, 'USD', 'Percentage split test', 'percentage'),
    (test_group_1, test_user_1, 35.00, 'USD', 'Exact split test', 'exact'),
    (test_group_1, test_user_1, 40.00, 'USD', 'Shares split test', 'shares');
  
  -- Verify all split methods were stored correctly
  PERFORM 1 FROM expenses WHERE description = 'Equal split test' AND split_method = 'equal';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Split method test FAILED: Equal split method not stored';
  END IF;
  
  PERFORM 1 FROM expenses WHERE description = 'Percentage split test' AND split_method = 'percentage';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Split method test FAILED: Percentage split method not stored';
  END IF;
  
  PERFORM 1 FROM expenses WHERE description = 'Exact split test' AND split_method = 'exact';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Split method test FAILED: Exact split method not stored';
  END IF;
  
  PERFORM 1 FROM expenses WHERE description = 'Shares split test' AND split_method = 'shares';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Split method test FAILED: Shares split method not stored';
  END IF;
  
  RAISE NOTICE 'Split method enum validation PASSED: All valid split methods stored correctly';

  -- Test: Cascade delete when group is deleted
  RAISE NOTICE 'Testing cascade delete when group is deleted';
  
  DECLARE
    expense_count_before INTEGER;
    expense_count_after INTEGER;
  BEGIN
    SELECT COUNT(*) INTO expense_count_before 
    FROM expenses WHERE group_id = test_group_2;
    
    -- Create an expense in test_group_2
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_2, test_user_2, 60.00, 'EUR', 'Test expense for cascade delete');
    
    SELECT COUNT(*) INTO expense_count_before 
    FROM expenses WHERE group_id = test_group_2;
    
    -- Delete the group
    DELETE FROM groups WHERE id = test_group_2;
    
    -- Count expenses after group deletion
    SELECT COUNT(*) INTO expense_count_after 
    FROM expenses WHERE group_id = test_group_2;
    
    IF expense_count_after != 0 THEN
      RAISE EXCEPTION 'Cascade delete FAILED: Expenses not deleted with group';
    END IF;
    
    RAISE NOTICE 'Cascade delete PASSED: Expenses deleted when group deleted (% -> %)', 
      expense_count_before, expense_count_after;
  END;

  -- Test: Cascade delete when user is deleted
  RAISE NOTICE 'Testing cascade delete when user is deleted';
  
  DECLARE
    user_expense_count_before INTEGER;
    user_expense_count_after INTEGER;
  BEGIN
    SELECT COUNT(*) INTO user_expense_count_before 
    FROM expenses WHERE payer_id = test_user_2;
    
    -- Delete the user
    DELETE FROM users WHERE id = test_user_2;
    
    -- Count expenses after user deletion
    SELECT COUNT(*) INTO user_expense_count_after 
    FROM expenses WHERE payer_id = test_user_2;
    
    IF user_expense_count_after != 0 THEN
      RAISE EXCEPTION 'Cascade delete FAILED: Expenses not deleted with user';
    END IF;
    
    RAISE NOTICE 'Cascade delete PASSED: Expenses deleted when user deleted (% -> %)', 
      user_expense_count_before, user_expense_count_after;
  END;

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up test data';
  
  -- Clean up test data (cascade will handle related records)
  DELETE FROM users WHERE email LIKE 'expense_test%@example.com';
  DELETE FROM groups WHERE name LIKE 'Expense Test Group %';
  
  RAISE NOTICE 'All expenses table property tests completed successfully!';

END;
$$;