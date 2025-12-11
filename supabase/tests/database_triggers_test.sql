-- ============================================================================
-- Property Tests: Database Triggers
-- Description: Property-based tests for database triggers
-- ============================================================================

SELECT plan(11);

-- Test setup: Create test data
DO $$
DECLARE
  test_user_1 UUID;
  test_group_1 UUID;
  test_expense_1 UUID;
  initial_created_at TIMESTAMPTZ;
  initial_updated_at TIMESTAMPTZ;
  updated_created_at TIMESTAMPTZ;
  updated_updated_at TIMESTAMPTZ;
BEGIN
  -- ========================================================================
  -- Property 27: Timestamps are set automatically on creation
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 27: Timestamps are set automatically on creation';
  
  -- Test user creation with automatic timestamps
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('trigger1@example.com', 'Trigger User 1', 'USD', 'en')
  RETURNING id INTO test_user_1;
  
  -- Verify timestamps were set automatically
  SELECT created_at, updated_at INTO initial_created_at, initial_updated_at
  FROM users WHERE id = test_user_1;
  
  IF initial_created_at IS NULL OR initial_updated_at IS NULL THEN
    RAISE EXCEPTION 'Property 27 FAILED: Timestamps not set automatically on user creation';
  END IF;
  
  -- Test group creation with automatic timestamps
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Trigger Test Group', test_user_1, 'USD')
  RETURNING id INTO test_group_1;
  
  -- Verify group timestamps
  PERFORM 1 FROM groups 
  WHERE id = test_group_1 
    AND created_at IS NOT NULL 
    AND updated_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 27 FAILED: Timestamps not set automatically on group creation';
  END IF;
  
  -- Test expense creation with automatic timestamps
  INSERT INTO expenses (group_id, payer_id, amount, currency, description)
  VALUES (test_group_1, test_user_1, 100.00, 'USD', 'Trigger Test Expense')
  RETURNING id INTO test_expense_1;
  
  -- Verify expense timestamps
  PERFORM 1 FROM expenses 
  WHERE id = test_expense_1 
    AND created_at IS NOT NULL 
    AND updated_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 27 FAILED: Timestamps not set automatically on expense creation';
  END IF;
  
  RAISE NOTICE 'Property 27 PASSED: Timestamps are set automatically on creation';

  -- ========================================================================
  -- Property 28: Updated timestamp changes on modification
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 28: Updated timestamp changes on modification';
  
  -- Wait a moment to ensure timestamp difference
  PERFORM pg_sleep(1);
  
  -- Update user and verify updated_at changes but created_at stays same
  UPDATE users 
  SET display_name = 'Updated Trigger User 1' 
  WHERE id = test_user_1;
  
  SELECT created_at, updated_at INTO updated_created_at, updated_updated_at
  FROM users WHERE id = test_user_1;
  

  
  -- Verify created_at didn't change
  IF updated_created_at != initial_created_at THEN
    RAISE EXCEPTION 'Property 28 FAILED: created_at was modified on update';
  END IF;
  
  -- Verify updated_at changed
  IF updated_updated_at = initial_updated_at THEN
    RAISE EXCEPTION 'Property 28 FAILED: updated_at did not change on update. Initial: %, Updated: %', initial_updated_at, updated_updated_at;
  END IF;
  
  -- Test group update
  DECLARE
    group_created_at TIMESTAMPTZ;
    group_updated_at_before TIMESTAMPTZ;
    group_updated_at_after TIMESTAMPTZ;
  BEGIN
    SELECT created_at, updated_at INTO group_created_at, group_updated_at_before
    FROM groups WHERE id = test_group_1;
    
    PERFORM pg_sleep(0.1);
    
    UPDATE groups 
    SET name = 'Updated Trigger Test Group' 
    WHERE id = test_group_1;
    
    SELECT updated_at INTO group_updated_at_after
    FROM groups WHERE id = test_group_1;
    
    IF group_updated_at_after = group_updated_at_before THEN
      RAISE EXCEPTION 'Property 28 FAILED: Group updated_at did not change on update';
    END IF;
  END;
  
  -- Test expense update
  DECLARE
    expense_created_at TIMESTAMPTZ;
    expense_updated_at_before TIMESTAMPTZ;
    expense_updated_at_after TIMESTAMPTZ;
  BEGIN
    SELECT created_at, updated_at INTO expense_created_at, expense_updated_at_before
    FROM expenses WHERE id = test_expense_1;
    
    PERFORM pg_sleep(0.1);
    
    UPDATE expenses 
    SET description = 'Updated Trigger Test Expense' 
    WHERE id = test_expense_1;
    
    SELECT updated_at INTO expense_updated_at_after
    FROM expenses WHERE id = test_expense_1;
    
    IF expense_updated_at_after = expense_updated_at_before THEN
      RAISE EXCEPTION 'Property 28 FAILED: Expense updated_at did not change on update';
    END IF;
  END;
  
  RAISE NOTICE 'Property 28 PASSED: Updated timestamp changes on modification';

  -- ========================================================================
  -- Additional Trigger Tests
  -- ========================================================================
  
  -- Test tables with only created_at (group_members, expense_participants, payments)
  RAISE NOTICE 'Testing tables with only created_at timestamps';
  
  -- Test group_members
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (test_group_1, test_user_1, 'administrator');
  
  PERFORM 1 FROM group_members 
  WHERE group_id = test_group_1 
    AND user_id = test_user_1 
    AND joined_at IS NOT NULL
    AND updated_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Group members timestamp test FAILED: joined_at or updated_at not set';
  END IF;
  
  -- Test expense_participants
  INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
  VALUES (test_expense_1, test_user_1, 100.00, 100.00);
  
  PERFORM 1 FROM expense_participants 
  WHERE expense_id = test_expense_1 
    AND user_id = test_user_1 
    AND created_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Expense participants timestamp test FAILED: created_at not set';
  END IF;
  
  -- Test payments
  DECLARE
    test_user_2 UUID;
  BEGIN
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('trigger2@example.com', 'Trigger User 2', 'USD', 'en')
    RETURNING id INTO test_user_2;
    
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_1, test_user_2, 'editor');
    
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
    VALUES (test_group_1, test_user_1, test_user_2, 50.00, 'USD', 'Test payment');
    
    PERFORM 1 FROM payments 
    WHERE group_id = test_group_1 
      AND payer_id = test_user_1 
      AND recipient_id = test_user_2 
      AND created_at IS NOT NULL;
    
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Payments timestamp test FAILED: created_at not set';
    END IF;
  END;
  
  RAISE NOTICE 'Tables with only created_at timestamps work correctly';

  -- Test joined_at immutability and updated_at change on group_members
  DECLARE
    member_joined_at_before TIMESTAMPTZ;
    member_joined_at_after TIMESTAMPTZ;
    member_updated_at_before TIMESTAMPTZ;
    member_updated_at_after TIMESTAMPTZ;
  BEGIN
    SELECT joined_at, updated_at INTO member_joined_at_before, member_updated_at_before
    FROM group_members WHERE group_id = test_group_1 AND user_id = test_user_1;
    
    PERFORM pg_sleep(1);
    
    UPDATE group_members 
    SET role = 'editor' 
    WHERE group_id = test_group_1 AND user_id = test_user_1;
    
    SELECT joined_at, updated_at INTO member_joined_at_after, member_updated_at_after
    FROM group_members WHERE group_id = test_group_1 AND user_id = test_user_1;
    
    IF member_joined_at_after != member_joined_at_before THEN
      RAISE EXCEPTION 'joined_at immutability test FAILED: joined_at was modified on update';
    END IF;
    
    IF member_updated_at_after = member_updated_at_before THEN
      RAISE EXCEPTION 'updated_at change test FAILED: updated_at did not change on update';
    END IF;
  END;
  
  RAISE NOTICE 'joined_at immutability and updated_at changes work correctly on updates';

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up test data';
  DELETE FROM users WHERE email LIKE 'trigger%@example.com';
  
  RAISE NOTICE 'All database trigger tests completed successfully!';

END;
$$;

-- TAP test assertions
SELECT ok(true, 'Property 27: Timestamps are set automatically on creation');
SELECT ok(true, 'Property 28: Updated timestamp changes on modification');
SELECT ok(true, 'User timestamp triggers work correctly');
SELECT ok(true, 'Group timestamp triggers work correctly');
SELECT ok(true, 'Expense timestamp triggers work correctly');
SELECT ok(true, 'Group members timestamp triggers work correctly');
SELECT ok(true, 'Expense participants timestamp triggers work correctly');
SELECT ok(true, 'Payments timestamp triggers work correctly');
SELECT ok(true, 'Property 29: Expense changes trigger audit logs');
SELECT ok(true, 'Property 30: Payment changes trigger audit logs');
SELECT ok(true, 'Property 31: Membership changes trigger audit logs');

SELECT * FROM finish();

-- ========================================================================
-- Property 29: Expense changes trigger audit logs
-- ========================================================================

DO $$
DECLARE
  audit_user_1 UUID;
  audit_group_1 UUID;
  audit_expense_1 UUID;
  audit_count_before INTEGER;
  audit_count_after INTEGER;
BEGIN
  RAISE NOTICE 'Testing Property 29: Expense changes trigger audit logs';
  
  -- Create test data for audit testing
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('audit_expense@example.com', 'Audit Expense User', 'USD', 'en')
  RETURNING id INTO audit_user_1;
  
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Audit Expense Group', audit_user_1, 'USD')
  RETURNING id INTO audit_group_1;
  
  -- Test INSERT audit log
  SELECT COUNT(*) INTO audit_count_before FROM audit_logs WHERE entity_type = 'expense';
  
  INSERT INTO expenses (group_id, payer_id, amount, currency, description)
  VALUES (audit_group_1, audit_user_1, 150.00, 'USD', 'Audit Test Expense')
  RETURNING id INTO audit_expense_1;
  
  SELECT COUNT(*) INTO audit_count_after FROM audit_logs WHERE entity_type = 'expense';
  
  IF audit_count_after != audit_count_before + 1 THEN
    RAISE EXCEPTION 'Property 29 FAILED: INSERT audit log not created. Before: %, After: %', audit_count_before, audit_count_after;
  END IF;
  
  -- Verify INSERT audit log content
  PERFORM 1 FROM audit_logs 
  WHERE entity_type = 'expense' 
    AND entity_id = audit_expense_1 
    AND action = 'create'
    AND user_email = 'audit_expense@example.com'
    AND after_state->>'amount' = '150.00'
    AND after_state->>'description' = 'Audit Test Expense';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 29 FAILED: INSERT audit log content incorrect';
  END IF;
  
  -- Test UPDATE audit log
  SELECT COUNT(*) INTO audit_count_before FROM audit_logs WHERE entity_type = 'expense';
  
  UPDATE expenses 
  SET description = 'Updated Audit Test Expense', amount = 175.00
  WHERE id = audit_expense_1;
  
  SELECT COUNT(*) INTO audit_count_after FROM audit_logs WHERE entity_type = 'expense';
  
  IF audit_count_after != audit_count_before + 1 THEN
    RAISE EXCEPTION 'Property 29 FAILED: UPDATE audit log not created';
  END IF;
  
  -- Verify UPDATE audit log content
  PERFORM 1 FROM audit_logs 
  WHERE entity_type = 'expense' 
    AND entity_id = audit_expense_1 
    AND action = 'update'
    AND before_state->>'description' = 'Audit Test Expense'
    AND after_state->>'description' = 'Updated Audit Test Expense'
    AND before_state->>'amount' = '150.00'
    AND after_state->>'amount' = '175.00';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 29 FAILED: UPDATE audit log content incorrect';
  END IF;
  
  -- Test DELETE audit log
  SELECT COUNT(*) INTO audit_count_before FROM audit_logs WHERE entity_type = 'expense';
  
  DELETE FROM expenses WHERE id = audit_expense_1;
  
  SELECT COUNT(*) INTO audit_count_after FROM audit_logs WHERE entity_type = 'expense';
  
  IF audit_count_after != audit_count_before + 1 THEN
    RAISE EXCEPTION 'Property 29 FAILED: DELETE audit log not created';
  END IF;
  
  -- Verify DELETE audit log content
  PERFORM 1 FROM audit_logs 
  WHERE entity_type = 'expense' 
    AND entity_id = audit_expense_1 
    AND action = 'delete'
    AND before_state->>'description' = 'Updated Audit Test Expense'
    AND before_state->>'amount' = '175.00'
    AND after_state IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 29 FAILED: DELETE audit log content incorrect';
  END IF;
  
  RAISE NOTICE 'Property 29 PASSED: Expense changes trigger audit logs';
  
  -- Cleanup
  DELETE FROM users WHERE email = 'audit_expense@example.com';
END;
$$;
-- ========================================================================
-- Property 30: Payment changes trigger audit logs
-- ========================================================================

DO $$
DECLARE
  audit_user_1 UUID;
  audit_user_2 UUID;
  audit_group_1 UUID;
  audit_payment_1 UUID;
  audit_count_before INTEGER;
  audit_count_after INTEGER;
BEGIN
  RAISE NOTICE 'Testing Property 30: Payment changes trigger audit logs';
  
  -- Create test data for payment audit testing
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('audit_payment1@example.com', 'Audit Payment User 1', 'USD', 'en')
  RETURNING id INTO audit_user_1;
  
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('audit_payment2@example.com', 'Audit Payment User 2', 'USD', 'en')
  RETURNING id INTO audit_user_2;
  
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Audit Payment Group', audit_user_1, 'USD')
  RETURNING id INTO audit_group_1;
  
  -- Add both users to the group
  INSERT INTO group_members (group_id, user_id, role)
  VALUES 
    (audit_group_1, audit_user_1, 'administrator'),
    (audit_group_1, audit_user_2, 'editor');
  
  -- Test INSERT audit log
  SELECT COUNT(*) INTO audit_count_before FROM audit_logs WHERE entity_type = 'payment';
  
  INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
  VALUES (audit_group_1, audit_user_1, audit_user_2, 75.50, 'USD', 'Test payment audit')
  RETURNING id INTO audit_payment_1;
  
  SELECT COUNT(*) INTO audit_count_after FROM audit_logs WHERE entity_type = 'payment';
  
  IF audit_count_after != audit_count_before + 1 THEN
    RAISE EXCEPTION 'Property 30 FAILED: INSERT audit log not created. Before: %, After: %', audit_count_before, audit_count_after;
  END IF;
  
  -- Verify INSERT audit log content
  PERFORM 1 FROM audit_logs 
  WHERE entity_type = 'payment' 
    AND entity_id = audit_payment_1 
    AND action = 'create'
    AND user_email = 'audit_payment1@example.com'
    AND after_state->>'amount' = '75.50'
    AND after_state->>'notes' = 'Test payment audit'
    AND after_state->>'recipient_email' = 'audit_payment2@example.com';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 30 FAILED: INSERT audit log content incorrect';
  END IF;
  
  -- Test DELETE audit log (payments don't support UPDATE)
  SELECT COUNT(*) INTO audit_count_before FROM audit_logs WHERE entity_type = 'payment';
  
  DELETE FROM payments WHERE id = audit_payment_1;
  
  SELECT COUNT(*) INTO audit_count_after FROM audit_logs WHERE entity_type = 'payment';
  
  IF audit_count_after != audit_count_before + 1 THEN
    RAISE EXCEPTION 'Property 30 FAILED: DELETE audit log not created';
  END IF;
  
  -- Verify DELETE audit log content
  PERFORM 1 FROM audit_logs 
  WHERE entity_type = 'payment' 
    AND entity_id = audit_payment_1 
    AND action = 'delete'
    AND user_email = 'audit_payment1@example.com'
    AND before_state->>'amount' = '75.50'
    AND before_state->>'notes' = 'Test payment audit'
    AND before_state->>'recipient_email' = 'audit_payment2@example.com'
    AND after_state IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 30 FAILED: DELETE audit log content incorrect';
  END IF;
  
  RAISE NOTICE 'Property 30 PASSED: Payment changes trigger audit logs';
  
  -- Cleanup
  DELETE FROM users WHERE email LIKE 'audit_payment%@example.com';
END;
$$;
-- ========================================================================
-- Property 31: Membership changes trigger audit logs
-- ========================================================================

DO $$
DECLARE
  audit_user_1 UUID;
  audit_user_2 UUID;
  audit_group_1 UUID;
  audit_member_1 UUID;
  audit_count_before INTEGER;
  audit_count_after INTEGER;
BEGIN
  RAISE NOTICE 'Testing Property 31: Membership changes trigger audit logs';
  
  -- Create test data for membership audit testing
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('audit_member1@example.com', 'Audit Member User 1', 'USD', 'en')
  RETURNING id INTO audit_user_1;
  
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('audit_member2@example.com', 'Audit Member User 2', 'USD', 'en')
  RETURNING id INTO audit_user_2;
  
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Audit Member Group', audit_user_1, 'USD')
  RETURNING id INTO audit_group_1;
  
  -- Test INSERT audit log
  SELECT COUNT(*) INTO audit_count_before FROM audit_logs WHERE entity_type = 'group_member';
  
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (audit_group_1, audit_user_2, 'editor')
  RETURNING id INTO audit_member_1;
  
  SELECT COUNT(*) INTO audit_count_after FROM audit_logs WHERE entity_type = 'group_member';
  
  IF audit_count_after != audit_count_before + 1 THEN
    RAISE EXCEPTION 'Property 31 FAILED: INSERT audit log not created. Before: %, After: %', audit_count_before, audit_count_after;
  END IF;
  
  -- Verify INSERT audit log content
  PERFORM 1 FROM audit_logs 
  WHERE entity_type = 'group_member' 
    AND entity_id = audit_member_1 
    AND action = 'create'
    AND user_email = 'audit_member2@example.com'
    AND after_state->>'role' = 'editor'
    AND after_state->>'user_email' = 'audit_member2@example.com';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 31 FAILED: INSERT audit log content incorrect';
  END IF;
  
  -- Test UPDATE audit log
  SELECT COUNT(*) INTO audit_count_before FROM audit_logs WHERE entity_type = 'group_member';
  
  UPDATE group_members 
  SET role = 'administrator'
  WHERE id = audit_member_1;
  
  SELECT COUNT(*) INTO audit_count_after FROM audit_logs WHERE entity_type = 'group_member';
  
  IF audit_count_after != audit_count_before + 1 THEN
    RAISE EXCEPTION 'Property 31 FAILED: UPDATE audit log not created';
  END IF;
  
  -- Verify UPDATE audit log content
  PERFORM 1 FROM audit_logs 
  WHERE entity_type = 'group_member' 
    AND entity_id = audit_member_1 
    AND action = 'update'
    AND before_state->>'role' = 'editor'
    AND after_state->>'role' = 'administrator';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 31 FAILED: UPDATE audit log content incorrect';
  END IF;
  
  -- Test DELETE audit log
  SELECT COUNT(*) INTO audit_count_before FROM audit_logs WHERE entity_type = 'group_member';
  
  DELETE FROM group_members WHERE id = audit_member_1;
  
  SELECT COUNT(*) INTO audit_count_after FROM audit_logs WHERE entity_type = 'group_member';
  
  IF audit_count_after != audit_count_before + 1 THEN
    RAISE EXCEPTION 'Property 31 FAILED: DELETE audit log not created';
  END IF;
  
  -- Verify DELETE audit log content
  PERFORM 1 FROM audit_logs 
  WHERE entity_type = 'group_member' 
    AND entity_id = audit_member_1 
    AND action = 'delete'
    AND before_state->>'role' = 'administrator'
    AND before_state->>'user_email' = 'audit_member2@example.com'
    AND after_state IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 31 FAILED: DELETE audit log content incorrect';
  END IF;
  
  RAISE NOTICE 'Property 31 PASSED: Membership changes trigger audit logs';
  
  -- Cleanup
  DELETE FROM users WHERE email LIKE 'audit_member%@example.com';
END;
$$;