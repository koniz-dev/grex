-- ============================================================================
-- Unit Tests: Expense Participants Table
-- Description: Unit tests for expense_participants table functionality and constraints
-- ============================================================================

-- Test setup and execution
DO $$
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_user_3 UUID;
  test_group_1 UUID;
  test_expense_1 UUID;
  test_participant_id UUID;
BEGIN
  RAISE NOTICE 'Starting expense_participants table unit tests';

  -- ========================================================================
  -- Setup: Create test data
  -- ========================================================================
  
  -- Create test users
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES 
    ('unit_participant1@example.com', 'Unit Test Participant 1', 'USD', 'en'),
    ('unit_participant2@example.com', 'Unit Test Participant 2', 'USD', 'en'),
    ('unit_participant3@example.com', 'Unit Test Participant 3', 'USD', 'en')
  RETURNING id INTO test_user_1, test_user_2, test_user_3;

  -- Create test group
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Unit Test Expense Group', test_user_1, 'USD')
  RETURNING id INTO test_group_1;

  -- Create group memberships
  INSERT INTO group_members (group_id, user_id, role)
  VALUES 
    (test_group_1, test_user_1, 'administrator'),
    (test_group_1, test_user_2, 'editor'),
    (test_group_1, test_user_3, 'editor');

  -- Create test expense
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
  VALUES (test_group_1, test_user_1, 90.00, 'USD', 'Unit Test Expense', 'equal')
  RETURNING id INTO test_expense_1;

  -- ========================================================================
  -- Test 1: Basic participant creation
  -- ========================================================================
  
  RAISE NOTICE 'Test 1: Basic participant creation';
  
  -- Test creating participant with required fields
  INSERT INTO expense_participants (expense_id, user_id, share_amount)
  VALUES (test_expense_1, test_user_1, 30.00)
  RETURNING id INTO test_participant_id;
  
  -- Verify participant was created
  PERFORM 1 FROM expense_participants 
  WHERE id = test_participant_id
    AND expense_id = test_expense_1
    AND user_id = test_user_1
    AND share_amount = 30.00
    AND created_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 1 FAILED: Basic participant creation failed';
  END IF;
  
  RAISE NOTICE 'Test 1 PASSED: Basic participant creation successful';

  -- ========================================================================
  -- Test 2: Share amount positive constraint
  -- ========================================================================
  
  RAISE NOTICE 'Test 2: Share amount positive constraint';
  
  -- Test valid positive amount
  INSERT INTO expense_participants (expense_id, user_id, share_amount)
  VALUES (test_expense_1, test_user_2, 30.00);
  
  -- Test invalid zero amount
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (test_expense_1, test_user_3, 0.00);
    
    RAISE EXCEPTION 'Test 2 FAILED: Zero share amount was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 2 PASSED: Zero share amount correctly rejected';
  END;
  
  -- Test invalid negative amount
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (test_expense_1, test_user_3, -15.00);
    
    RAISE EXCEPTION 'Test 2 FAILED: Negative share amount was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Test 2 PASSED: Negative share amount correctly rejected';
  END;

  -- ========================================================================
  -- Test 3: Share percentage range constraint
  -- ========================================================================
  
  RAISE NOTICE 'Test 3: Share percentage range constraint';
  
  -- Create new expense for percentage tests
  DECLARE
    test_expense_2 UUID;
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
    VALUES (test_group_1, test_user_2, 100.00, 'USD', 'Percentage Test Expense', 'percentage')
    RETURNING id INTO test_expense_2;
    
    -- Test valid percentage (0%)
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
    VALUES (test_expense_2, test_user_1, 0.00, 0.00);
    
    -- Test valid percentage (100%)
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
    VALUES (test_expense_2, test_user_2, 100.00, 100.00);
    
    -- Test valid percentage (50%)
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
    VALUES (test_expense_2, test_user_3, 50.00, 50.00);
    
    -- Test invalid percentage (> 100%)
    BEGIN
      INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
      VALUES (test_expense_2, test_user_1, 150.00, 150.00);
      
      RAISE EXCEPTION 'Test 3 FAILED: Share percentage > 100 was allowed';
    EXCEPTION
      WHEN check_violation THEN
        RAISE NOTICE 'Test 3 PASSED: Share percentage > 100 correctly rejected';
    END;
    
    -- Test invalid percentage (< 0%)
    BEGIN
      INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
      VALUES (test_expense_2, test_user_2, -10.00, -10.00);
      
      RAISE EXCEPTION 'Test 3 FAILED: Negative share percentage was allowed';
    EXCEPTION
      WHEN check_violation THEN
        RAISE NOTICE 'Test 3 PASSED: Negative share percentage correctly rejected';
    END;
  END;

  -- ========================================================================
  -- Test 4: Share count positive constraint
  -- ========================================================================
  
  RAISE NOTICE 'Test 4: Share count positive constraint';
  
  -- Create new expense for share count tests
  DECLARE
    test_expense_3 UUID;
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
    VALUES (test_group_1, test_user_3, 120.00, 'USD', 'Shares Test Expense', 'shares')
    RETURNING id INTO test_expense_3;
    
    -- Test valid share count (1)
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_count)
    VALUES (test_expense_3, test_user_1, 40.00, 1);
    
    -- Test valid share count (3)
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_count)
    VALUES (test_expense_3, test_user_2, 80.00, 2);
    
    -- Test invalid share count (0)
    BEGIN
      INSERT INTO expense_participants (expense_id, user_id, share_amount, share_count)
      VALUES (test_expense_3, test_user_3, 0.00, 0);
      
      RAISE EXCEPTION 'Test 4 FAILED: Zero share count was allowed';
    EXCEPTION
      WHEN check_violation THEN
        RAISE NOTICE 'Test 4 PASSED: Zero share count correctly rejected';
    END;
    
    -- Test invalid share count (negative)
    BEGIN
      INSERT INTO expense_participants (expense_id, user_id, share_amount, share_count)
      VALUES (test_expense_3, test_user_3, 40.00, -1);
      
      RAISE EXCEPTION 'Test 4 FAILED: Negative share count was allowed';
    EXCEPTION
      WHEN check_violation THEN
        RAISE NOTICE 'Test 4 PASSED: Negative share count correctly rejected';
    END;
  END;

  -- ========================================================================
  -- Test 5: Unique constraint on (expense_id, user_id)
  -- ========================================================================
  
  RAISE NOTICE 'Test 5: Unique constraint on (expense_id, user_id)';
  
  -- First participation should succeed (already created in Test 1)
  -- Second participation for same user and expense should fail
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (test_expense_1, test_user_1, 15.00);
    
    RAISE EXCEPTION 'Test 5 FAILED: Duplicate participation was allowed';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE 'Test 5 PASSED: Duplicate participation correctly rejected';
  END;

  -- ========================================================================
  -- Test 6: Foreign key constraint to expenses table
  -- ========================================================================
  
  RAISE NOTICE 'Test 6: Foreign key constraint to expenses table';
  
  -- Test invalid expense_id (should fail)
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (gen_random_uuid(), test_user_1, 25.00);
    
    RAISE EXCEPTION 'Test 6 FAILED: Invalid expense_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Test 6 PASSED: Invalid expense_id correctly rejected';
  END;

  -- ========================================================================
  -- Test 7: Foreign key constraint to users table
  -- ========================================================================
  
  RAISE NOTICE 'Test 7: Foreign key constraint to users table';
  
  -- Test invalid user_id (should fail)
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (test_expense_1, gen_random_uuid(), 25.00);
    
    RAISE EXCEPTION 'Test 7 FAILED: Invalid user_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Test 7 PASSED: Invalid user_id correctly rejected';
  END;

  -- ========================================================================
  -- Test 8: Cascade delete when expense is deleted
  -- ========================================================================
  
  RAISE NOTICE 'Test 8: Cascade delete when expense is deleted';
  
  -- Create expense with participants for cascade test
  DECLARE
    test_expense_4 UUID;
    participant_count INTEGER;
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
    VALUES (test_group_1, test_user_1, 60.00, 'USD', 'Cascade Delete Test', 'equal')
    RETURNING id INTO test_expense_4;
    
    -- Add participants
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES 
      (test_expense_4, test_user_1, 20.00),
      (test_expense_4, test_user_2, 20.00),
      (test_expense_4, test_user_3, 20.00);
    
    -- Verify participants exist
    SELECT COUNT(*) INTO participant_count 
    FROM expense_participants WHERE expense_id = test_expense_4;
    
    IF participant_count != 3 THEN
      RAISE EXCEPTION 'Test 8 SETUP FAILED: Expected 3 participants, found %', participant_count;
    END IF;
    
    -- Delete the expense
    DELETE FROM expenses WHERE id = test_expense_4;
    
    -- Verify all participants were deleted
    SELECT COUNT(*) INTO participant_count 
    FROM expense_participants WHERE expense_id = test_expense_4;
    
    IF participant_count != 0 THEN
      RAISE EXCEPTION 'Test 8 FAILED: Participants not deleted when expense deleted';
    END IF;
    
    RAISE NOTICE 'Test 8 PASSED: Participants cascade deleted with expense';
  END;

  -- ========================================================================
  -- Test 9: Cascade delete when user is deleted
  -- ========================================================================
  
  RAISE NOTICE 'Test 9: Cascade delete when user is deleted';
  
  -- Count participations for test_user_3 before deletion
  DECLARE
    user_participation_count INTEGER;
  BEGIN
    SELECT COUNT(*) INTO user_participation_count 
    FROM expense_participants WHERE user_id = test_user_3;
    
    -- Delete the user
    DELETE FROM users WHERE id = test_user_3;
    
    -- Verify all participations were deleted
    SELECT COUNT(*) INTO user_participation_count 
    FROM expense_participants WHERE user_id = test_user_3;
    
    IF user_participation_count != 0 THEN
      RAISE EXCEPTION 'Test 9 FAILED: Participations not deleted when user deleted';
    END IF;
    
    RAISE NOTICE 'Test 9 PASSED: Participations cascade deleted with user';
  END;

  -- ========================================================================
  -- Test 10: Timestamp behavior
  -- ========================================================================
  
  RAISE NOTICE 'Test 10: Timestamp behavior';
  
  -- Get a participant to test timestamps
  SELECT id INTO test_participant_id 
  FROM expense_participants 
  WHERE expense_id = test_expense_1 AND user_id = test_user_1;
  
  DECLARE
    created_timestamp TIMESTAMPTZ;
  BEGIN
    -- Get created timestamp
    SELECT created_at INTO created_timestamp
    FROM expense_participants WHERE id = test_participant_id;
    
    -- Verify timestamp is recent (within last minute)
    IF created_timestamp < NOW() - INTERVAL '1 minute' THEN
      RAISE EXCEPTION 'Test 10 FAILED: created_at timestamp not set correctly';
    END IF;
    
    RAISE NOTICE 'Test 10 PASSED: Timestamp set correctly on creation';
  END;

  -- ========================================================================
  -- Test 11: Different split method scenarios
  -- ========================================================================
  
  RAISE NOTICE 'Test 11: Different split method scenarios';
  
  -- Test equal split scenario
  DECLARE
    equal_expense UUID;
    total_amount NUMERIC(15, 2) := 99.00;
    per_person NUMERIC(15, 2) := 33.00;
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
    VALUES (test_group_1, test_user_1, total_amount, 'USD', 'Equal Split Test', 'equal')
    RETURNING id INTO equal_expense;
    
    -- Add equal participants
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES 
      (equal_expense, test_user_1, per_person),
      (equal_expense, test_user_2, per_person);
    
    -- Verify equal split was created
    PERFORM 1 FROM expense_participants 
    WHERE expense_id = equal_expense AND share_amount = per_person;
    
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Test 11 FAILED: Equal split not created correctly';
    END IF;
    
    RAISE NOTICE 'Test 11 PASSED: Equal split scenario works correctly';
  END;

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up unit test data';
  
  -- Clean up test data (cascade will handle related records)
  DELETE FROM users WHERE email LIKE 'unit_participant%@example.com';
  DELETE FROM groups WHERE name = 'Unit Test Expense Group';
  
  RAISE NOTICE 'All expense_participants table unit tests completed successfully!';

END;
$$;