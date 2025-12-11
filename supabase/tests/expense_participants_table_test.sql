-- ============================================================================
-- Property Tests: Expense Participants Table
-- Description: Property-based tests for expense_participants table correctness
-- ============================================================================

-- Test setup: Create test data
DO $$
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_user_3 UUID;
  test_group_1 UUID;
  test_expense_1 UUID;
  test_expense_2 UUID;
  test_participant_1 UUID;
  test_participant_2 UUID;
BEGIN
  -- Create test users
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES 
    ('participant1@example.com', 'Participant 1', 'USD', 'en'),
    ('participant2@example.com', 'Participant 2', 'USD', 'en'),
    ('participant3@example.com', 'Participant 3', 'USD', 'en')
  RETURNING id INTO test_user_1, test_user_2, test_user_3;

  -- Create test group
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Test Expense Group', test_user_1, 'USD')
  RETURNING id INTO test_group_1;

  -- Create group memberships
  INSERT INTO group_members (group_id, user_id, role)
  VALUES 
    (test_group_1, test_user_1, 'administrator'),
    (test_group_1, test_user_2, 'editor'),
    (test_group_1, test_user_3, 'editor');

  -- Create test expenses
  INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
  VALUES 
    (test_group_1, test_user_1, 100.00, 'USD', 'Test Expense 1', 'equal'),
    (test_group_1, test_user_2, 150.00, 'USD', 'Test Expense 2', 'percentage')
  RETURNING id INTO test_expense_1, test_expense_2;

  -- ========================================================================
  -- Property 16: Participant creation includes all required fields
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 16: Participant creation includes all required fields';
  
  -- Test: Create participant with all required fields
  INSERT INTO expense_participants (expense_id, user_id, share_amount)
  VALUES (test_expense_1, test_user_1, 33.33)
  RETURNING id INTO test_participant_1;
  
  -- Verify all required fields are populated
  PERFORM 1 FROM expense_participants 
  WHERE id = test_participant_1
    AND expense_id IS NOT NULL
    AND user_id IS NOT NULL
    AND share_amount IS NOT NULL
    AND created_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 16 FAILED: Participant creation missing required fields';
  END IF;
  
  RAISE NOTICE 'Property 16 PASSED: All required fields populated on participant creation';

  -- ========================================================================
  -- Property 17: Participant constraints are enforced
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 17: Participant constraints are enforced';
  
  -- Test: Positive share amount constraint
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (test_expense_1, test_user_2, -10.00);
    
    RAISE EXCEPTION 'Property 17 FAILED: Negative share amount was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 17 PASSED: Negative share amount correctly rejected';
  END;
  
  -- Test: Share percentage range constraint (valid percentage)
  INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
  VALUES (test_expense_2, test_user_1, 90.00, 60.00);
  
  -- Test: Share percentage range constraint (invalid percentage > 100)
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
    VALUES (test_expense_2, test_user_2, 75.00, 150.00);
    
    RAISE EXCEPTION 'Property 17 FAILED: Share percentage > 100 was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 17 PASSED: Share percentage > 100 correctly rejected';
  END;
  
  -- Test: Share percentage range constraint (invalid percentage < 0)
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
    VALUES (test_expense_2, test_user_3, 60.00, -5.00);
    
    RAISE EXCEPTION 'Property 17 FAILED: Negative share percentage was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 17 PASSED: Negative share percentage correctly rejected';
  END;
  
  -- Test: Share count positive constraint (valid count)
  INSERT INTO expense_participants (expense_id, user_id, share_amount, share_count)
  VALUES (test_expense_1, test_user_2, 33.33, 2);
  
  -- Test: Share count positive constraint (invalid count)
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_count)
    VALUES (test_expense_1, test_user_3, 33.34, 0);
    
    RAISE EXCEPTION 'Property 17 FAILED: Zero share count was allowed';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'Property 17 PASSED: Zero share count correctly rejected';
  END;
  
  RAISE NOTICE 'Property 17 PASSED: All participant constraints enforced correctly';

  -- ========================================================================
  -- Property 18: Participant deletion cascades with expense
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 18: Participant deletion cascades with expense';
  
  -- Create additional expense with participants for cascade test
  DECLARE
    test_expense_3 UUID;
    participant_count_before INTEGER;
    participant_count_after INTEGER;
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
    VALUES (test_group_1, test_user_3, 75.00, 'USD', 'Cascade Test Expense', 'equal')
    RETURNING id INTO test_expense_3;
    
    -- Add participants to the expense
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES 
      (test_expense_3, test_user_1, 25.00),
      (test_expense_3, test_user_2, 25.00),
      (test_expense_3, test_user_3, 25.00);
    
    -- Count participants before expense deletion
    SELECT COUNT(*) INTO participant_count_before 
    FROM expense_participants WHERE expense_id = test_expense_3;
    
    -- Delete the expense
    DELETE FROM expenses WHERE id = test_expense_3;
    
    -- Count participants after expense deletion
    SELECT COUNT(*) INTO participant_count_after 
    FROM expense_participants WHERE expense_id = test_expense_3;
    
    IF participant_count_after != 0 THEN
      RAISE EXCEPTION 'Property 18 FAILED: Participants not deleted when expense deleted';
    END IF;
    
    RAISE NOTICE 'Property 18 PASSED: Participants cascade deleted with expense (% -> %)', 
      participant_count_before, participant_count_after;
  END;

  -- ========================================================================
  -- Property 19: Expense split totals match expense amount
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 19: Expense split totals match expense amount';
  
  -- Create expense with exact split that should sum to total
  DECLARE
    test_expense_4 UUID;
    expense_amount NUMERIC(15, 2);
    total_shares NUMERIC(15, 2);
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
    VALUES (test_group_1, test_user_1, 120.00, 'USD', 'Exact Split Test', 'exact')
    RETURNING id INTO test_expense_4;
    
    -- Add participants with exact amounts that sum to expense total
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES 
      (test_expense_4, test_user_1, 50.00),
      (test_expense_4, test_user_2, 30.00),
      (test_expense_4, test_user_3, 40.00);
    
    -- Get expense amount
    SELECT amount INTO expense_amount FROM expenses WHERE id = test_expense_4;
    
    -- Calculate total of participant shares
    SELECT SUM(share_amount) INTO total_shares 
    FROM expense_participants WHERE expense_id = test_expense_4;
    
    -- Verify totals match (within small tolerance for rounding)
    IF ABS(expense_amount - total_shares) >= 0.01 THEN
      RAISE EXCEPTION 'Property 19 FAILED: Split totals (%) do not match expense amount (%)', 
        total_shares, expense_amount;
    END IF;
    
    RAISE NOTICE 'Property 19 PASSED: Split totals (%) match expense amount (%)', 
      total_shares, expense_amount;
  END;

  -- ========================================================================
  -- Additional Property Tests
  -- ========================================================================
  
  -- Test: Unique constraint on (expense_id, user_id)
  RAISE NOTICE 'Testing unique constraint on (expense_id, user_id)';
  
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (test_expense_1, test_user_1, 50.00);
    
    RAISE EXCEPTION 'Unique constraint FAILED: Duplicate participant was allowed';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE 'Unique constraint PASSED: Duplicate participant correctly rejected';
  END;

  -- Test: Foreign key constraints
  RAISE NOTICE 'Testing foreign key constraints';
  
  -- Test: Invalid expense_id is rejected
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (gen_random_uuid(), test_user_1, 25.00);
    
    RAISE EXCEPTION 'Foreign key constraint FAILED: Invalid expense_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Foreign key constraint PASSED: Invalid expense_id correctly rejected';
  END;
  
  -- Test: Invalid user_id is rejected
  BEGIN
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (test_expense_1, gen_random_uuid(), 25.00);
    
    RAISE EXCEPTION 'Foreign key constraint FAILED: Invalid user_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Foreign key constraint PASSED: Invalid user_id correctly rejected';
  END;

  -- Test: Cascade delete when user is deleted
  RAISE NOTICE 'Testing cascade delete when user is deleted';
  
  DECLARE
    user_participant_count_before INTEGER;
    user_participant_count_after INTEGER;
  BEGIN
    SELECT COUNT(*) INTO user_participant_count_before 
    FROM expense_participants WHERE user_id = test_user_3;
    
    -- Delete the user
    DELETE FROM users WHERE id = test_user_3;
    
    -- Count participations after user deletion
    SELECT COUNT(*) INTO user_participant_count_after 
    FROM expense_participants WHERE user_id = test_user_3;
    
    IF user_participant_count_after != 0 THEN
      RAISE EXCEPTION 'Cascade delete FAILED: Participations not deleted with user';
    END IF;
    
    RAISE NOTICE 'Cascade delete PASSED: Participations deleted when user deleted (% -> %)', 
      user_participant_count_before, user_participant_count_after;
  END;

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up test data';
  
  -- Clean up test data (cascade will handle related records)
  DELETE FROM users WHERE email LIKE 'participant%@example.com';
  DELETE FROM groups WHERE name = 'Test Expense Group';
  
  RAISE NOTICE 'All expense_participants table property tests completed successfully!';

END;
$$;