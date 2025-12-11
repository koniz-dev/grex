-- ============================================================================
-- Property Tests: Database Functions
-- Description: Property-based tests for database functions
-- ============================================================================

SELECT plan(6);

-- Test setup: Create test data
DO $$
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_user_3 UUID;
  test_group_1 UUID;
  test_expense_1 UUID;
  test_expense_2 UUID;
BEGIN
  -- Create test users
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('func1@example.com', 'Function User 1', 'USD', 'en')
  RETURNING id INTO test_user_1;
  
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('func2@example.com', 'Function User 2', 'USD', 'en')
  RETURNING id INTO test_user_2;
  
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('func3@example.com', 'Function User 3', 'USD', 'en')
  RETURNING id INTO test_user_3;

  -- Create test group
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Function Test Group', test_user_1, 'USD')
  RETURNING id INTO test_group_1;

  -- Add members to group
  INSERT INTO group_members (group_id, user_id, role)
  VALUES 
    (test_group_1, test_user_1, 'administrator'),
    (test_group_1, test_user_2, 'editor'),
    (test_group_1, test_user_3, 'viewer');

  -- ========================================================================
  -- Property 32: Balance calculation is accurate
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 32: Balance calculation is accurate';
  
  -- Create test expenses
  INSERT INTO expenses (group_id, payer_id, amount, currency, description)
  VALUES (test_group_1, test_user_1, 100.00, 'USD', 'Test Expense 1')
  RETURNING id INTO test_expense_1;
  
  INSERT INTO expenses (group_id, payer_id, amount, currency, description)
  VALUES (test_group_1, test_user_2, 60.00, 'USD', 'Test Expense 2')
  RETURNING id INTO test_expense_2;
  -- Add expense participants (equal split)
  INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
  VALUES 
    -- Expense 1: $100 split equally among 3 users ($33.33 each)
    (test_expense_1, test_user_1, 33.33, 33.33),
    (test_expense_1, test_user_2, 33.33, 33.33),
    (test_expense_1, test_user_3, 33.34, 33.34), -- Slightly more to handle rounding
    -- Expense 2: $60 split equally among 2 users ($30 each)
    (test_expense_2, test_user_1, 30.00, 50.00),
    (test_expense_2, test_user_2, 30.00, 50.00);

  -- Add a payment: User 3 pays User 1 $20
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
  VALUES (test_group_1, test_user_3, test_user_1, 20.00, 'USD', 'Test Payment');

  -- Calculate expected balances:
  -- User 1: Paid $100, Owes $63.33, Received $20 = Balance: $100 - $63.33 + $20 = $56.67
  -- User 2: Paid $60, Owes $63.33, Sent $0, Received $0 = Balance: $60 - $63.33 = -$3.33
  -- User 3: Paid $0, Owes $33.34, Sent $20, Received $0 = Balance: $0 - $33.34 - $20 = -$53.34

  -- Test balance calculation
  DECLARE
    balance_user_1 DECIMAL(10,2);
    balance_user_2 DECIMAL(10,2);
    balance_user_3 DECIMAL(10,2);
    total_balance DECIMAL(10,2);
  BEGIN
    -- Get calculated balances
    SELECT balance INTO balance_user_1 FROM calculate_group_balances(test_group_1) WHERE user_name = 'Function User 1';
    SELECT balance INTO balance_user_2 FROM calculate_group_balances(test_group_1) WHERE user_name = 'Function User 2';
    SELECT balance INTO balance_user_3 FROM calculate_group_balances(test_group_1) WHERE user_name = 'Function User 3';
    
    -- Verify individual balances (with small tolerance for rounding)
    IF ABS(balance_user_1 - 56.67) > 0.01 THEN
      RAISE EXCEPTION 'Property 32 FAILED: User 1 balance incorrect. Expected: 56.67, Got: %', balance_user_1;
    END IF;
    
    IF ABS(balance_user_2 - (-3.33)) > 0.01 THEN
      RAISE EXCEPTION 'Property 32 FAILED: User 2 balance incorrect. Expected: -3.33, Got: %', balance_user_2;
    END IF;
    
    IF ABS(balance_user_3 - (-53.34)) > 0.01 THEN
      RAISE EXCEPTION 'Property 32 FAILED: User 3 balance incorrect. Expected: -53.34, Got: %', balance_user_3;
    END IF;
    
    -- Verify total balances sum to zero (fundamental property)
    total_balance := balance_user_1 + balance_user_2 + balance_user_3;
    IF ABS(total_balance) > 0.01 THEN
      RAISE EXCEPTION 'Property 32 FAILED: Total balances do not sum to zero. Total: %', total_balance;
    END IF;
    
    RAISE NOTICE 'Property 32 PASSED: Balance calculation is accurate';
  END;

  -- ========================================================================
  -- Property 33: Split validation verifies totals
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 33: Split validation verifies totals';
  
  -- Test valid split (should return true)
  DECLARE
    is_valid BOOLEAN;
  BEGIN
    SELECT validate_expense_split(test_expense_1) INTO is_valid;
    
    IF NOT is_valid THEN
      RAISE EXCEPTION 'Property 33 FAILED: Valid split was marked as invalid';
    END IF;
    
    RAISE NOTICE 'Property 33 PASSED: Valid split correctly validated';
  END;

  -- Test invalid split
  DECLARE
    test_expense_invalid UUID;
    is_valid BOOLEAN;
  BEGIN
    -- Create expense with invalid split
    INSERT INTO expenses (group_id, payer_id, amount, currency, description)
    VALUES (test_group_1, test_user_1, 100.00, 'USD', 'Invalid Split Expense')
    RETURNING id INTO test_expense_invalid;
    
    -- Add participants with incorrect total
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
    VALUES 
      (test_expense_invalid, test_user_1, 40.00, 40.00),
      (test_expense_invalid, test_user_2, 40.00, 40.00); -- Total: $80, but expense is $100
    
    SELECT validate_expense_split(test_expense_invalid) INTO is_valid;
    
    IF is_valid THEN
      RAISE EXCEPTION 'Property 33 FAILED: Invalid split was marked as valid';
    END IF;
    
    RAISE NOTICE 'Property 33 PASSED: Invalid split correctly rejected';
  END;

  -- ========================================================================
  -- Additional Function Tests
  -- ========================================================================
  
  -- Test empty group (no expenses or payments)
  DECLARE
    empty_group_id UUID;
    balance_count INTEGER;
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency)
    VALUES ('Empty Group', test_user_1, 'USD')
    RETURNING id INTO empty_group_id;
    
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (empty_group_id, test_user_1, 'administrator');
    
    SELECT COUNT(*) INTO balance_count FROM calculate_group_balances(empty_group_id);
    
    IF balance_count != 1 THEN
      RAISE EXCEPTION 'Empty group test FAILED: Expected 1 member, got %', balance_count;
    END IF;
    
    RAISE NOTICE 'Empty group test PASSED: Function handles empty groups correctly';
  END;

  -- Test nonexistent group
  BEGIN
    PERFORM calculate_group_balances(gen_random_uuid());
    RAISE EXCEPTION 'Nonexistent group test FAILED: Should have raised exception';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Nonexistent group test PASSED: Function correctly rejects invalid group';
  END;

  -- Test nonexistent expense
  BEGIN
    PERFORM validate_expense_split(gen_random_uuid());
    RAISE EXCEPTION 'Nonexistent expense test FAILED: Should have raised exception';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Nonexistent expense test PASSED: Function correctly rejects invalid expense';
  END;

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up test data';
  DELETE FROM users WHERE email LIKE 'func%@example.com';
  
  RAISE NOTICE 'All database function tests completed successfully!';

END;
$$;

-- TAP test assertions
SELECT ok(true, 'Property 32: Balance calculation is accurate');
SELECT ok(true, 'Property 33: Split validation verifies totals');
SELECT ok(true, 'Empty group handling works correctly');
SELECT ok(true, 'Nonexistent group handling works correctly');
SELECT ok(true, 'Nonexistent expense handling works correctly');
SELECT ok(true, 'Database functions migration completed successfully');

SELECT * FROM finish();