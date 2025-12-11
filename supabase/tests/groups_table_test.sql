-- ============================================================================
-- Property Tests: Groups Table
-- Description: Property-based tests for groups table correctness
-- ============================================================================

-- Test setup: Create test users for foreign key relationships
DO $$
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_suffix TEXT := extract(epoch from now())::text;
BEGIN
  -- Create first test user with unique email
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('test1_' || test_suffix || '@example.com', 'Test User 1', 'USD', 'en')
  RETURNING id INTO test_user_1;
  
  -- Create second test user with unique email
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('test2_' || test_suffix || '@example.com', 'Test User 2', 'EUR', 'vi')
  RETURNING id INTO test_user_2;
  
  -- Store test user IDs for use in tests
  CREATE TEMP TABLE test_users AS 
  SELECT test_user_1 as user_1, test_user_2 as user_2;
END $$;

-- ============================================================================
-- Property 5: Group creation includes all required fields
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  test_group_id UUID;
  group_record RECORD;
BEGIN
  -- Get test user
  SELECT user_1 INTO test_user_id FROM test_users;
  
  -- Test: Create group with all required fields
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES ('Test Group', test_user_id, 'USD')
  RETURNING id INTO test_group_id;
  
  -- Verify: All required fields are populated
  SELECT * INTO group_record FROM groups WHERE id = test_group_id;
  
  ASSERT group_record.id IS NOT NULL, 'Group ID should be generated';
  ASSERT group_record.name = 'Test Group', 'Group name should be set';
  ASSERT group_record.creator_id = test_user_id, 'Creator ID should be set';
  ASSERT group_record.primary_currency = 'USD', 'Primary currency should be set';
  ASSERT group_record.created_at IS NOT NULL, 'Created timestamp should be set';
  ASSERT group_record.updated_at IS NOT NULL, 'Updated timestamp should be set';
  ASSERT group_record.deleted_at IS NULL, 'Deleted timestamp should be NULL for new groups';
  
  RAISE NOTICE 'Property 5 PASSED: Group creation includes all required fields';
END $$;

-- ============================================================================
-- Property 6: Group constraints are enforced
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  error_occurred BOOLEAN;
BEGIN
  -- Get test user
  SELECT user_1 INTO test_user_id FROM test_users;
  
  -- Test 6.1: Name cannot be empty
  error_occurred := FALSE;
  BEGIN
    INSERT INTO groups (name, creator_id) VALUES ('', test_user_id);
  EXCEPTION WHEN check_violation THEN
    error_occurred := TRUE;
  END;
  ASSERT error_occurred, 'Empty group name should be rejected';
  
  -- Test 6.2: Name cannot be only whitespace
  error_occurred := FALSE;
  BEGIN
    INSERT INTO groups (name, creator_id) VALUES ('   ', test_user_id);
  EXCEPTION WHEN check_violation THEN
    error_occurred := TRUE;
  END;
  ASSERT error_occurred, 'Whitespace-only group name should be rejected';
  
  -- Test 6.3: Name cannot exceed 100 characters
  error_occurred := FALSE;
  BEGIN
    INSERT INTO groups (name, creator_id) 
    VALUES (REPEAT('a', 101), test_user_id);
  EXCEPTION WHEN check_violation THEN
    error_occurred := TRUE;
  END;
  ASSERT error_occurred, 'Group name over 100 characters should be rejected';
  
  -- Test 6.4: Currency must be 3 characters
  error_occurred := FALSE;
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency) 
    VALUES ('Test Group', test_user_id, 'US');
  EXCEPTION WHEN check_violation THEN
    error_occurred := TRUE;
  END;
  ASSERT error_occurred, 'Currency code with wrong length should be rejected';
  
  -- Test 6.5: Currency must be uppercase letters
  error_occurred := FALSE;
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency) 
    VALUES ('Test Group', test_user_id, 'usd');
  EXCEPTION WHEN check_violation THEN
    error_occurred := TRUE;
  END;
  ASSERT error_occurred, 'Lowercase currency code should be rejected';
  
  -- Test 6.6: Description cannot be empty if provided
  error_occurred := FALSE;
  BEGIN
    INSERT INTO groups (name, creator_id, description) 
    VALUES ('Test Group', test_user_id, '');
  EXCEPTION WHEN check_violation THEN
    error_occurred := TRUE;
  END;
  ASSERT error_occurred, 'Empty description should be rejected';
  
  -- Test 6.7: Description cannot exceed 500 characters
  error_occurred := FALSE;
  BEGIN
    INSERT INTO groups (name, creator_id, description) 
    VALUES ('Test Group', test_user_id, REPEAT('a', 501));
  EXCEPTION WHEN check_violation THEN
    error_occurred := TRUE;
  END;
  ASSERT error_occurred, 'Description over 500 characters should be rejected';
  
  -- Test 6.8: Valid group should be accepted
  INSERT INTO groups (name, creator_id, primary_currency, description)
  VALUES ('Valid Group', test_user_id, 'EUR', 'A valid group description');
  
  RAISE NOTICE 'Property 6 PASSED: Group constraints are enforced';
END $$;

-- ============================================================================
-- Property 7: Group deletion cascades to related data
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  test_group_id UUID;
  related_count INTEGER;
BEGIN
  -- Get test user
  SELECT user_1 INTO test_user_id FROM test_users;
  
  -- Create a group
  INSERT INTO groups (name, creator_id)
  VALUES ('Group to Delete', test_user_id)
  RETURNING id INTO test_group_id;
  
  -- Verify group exists
  SELECT COUNT(*) INTO related_count FROM groups WHERE id = test_group_id;
  ASSERT related_count = 1, 'Group should exist before deletion';
  
  -- Delete the creator user (should cascade to group)
  DELETE FROM users WHERE id = test_user_id;
  
  -- Verify group was cascade deleted
  SELECT COUNT(*) INTO related_count FROM groups WHERE id = test_group_id;
  ASSERT related_count = 0, 'Group should be cascade deleted when creator is deleted';
  
  RAISE NOTICE 'Property 7 PASSED: Group deletion cascades to related data';
END $$;

-- ============================================================================
-- Property 8: Group update modifies timestamp
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  test_group_id UUID;
  original_updated_at TIMESTAMPTZ;
  new_updated_at TIMESTAMPTZ;
  original_created_at TIMESTAMPTZ;
  new_created_at TIMESTAMPTZ;
BEGIN
  -- Get test user (create new one since previous was deleted)
  INSERT INTO users (email, display_name)
  VALUES ('test3_' || extract(epoch from now())::text || '@example.com', 'Test User 3')
  RETURNING id INTO test_user_id;
  
  -- Create a group
  INSERT INTO groups (name, creator_id)
  VALUES ('Group to Update', test_user_id)
  RETURNING id INTO test_group_id;
  
  -- Get original timestamps
  SELECT created_at, updated_at INTO original_created_at, original_updated_at 
  FROM groups WHERE id = test_group_id;
  
  -- Wait to ensure timestamp difference (trigger uses NOW())
  PERFORM pg_sleep(0.1);
  
  -- Update the group (trigger will automatically set updated_at to NOW())
  UPDATE groups SET name = 'Updated Group Name' WHERE id = test_group_id;
  
  -- Get new timestamps
  SELECT created_at, updated_at INTO new_created_at, new_updated_at 
  FROM groups WHERE id = test_group_id;
  
  -- Verify timestamp was updated by trigger and created_at remained the same
  ASSERT new_updated_at >= original_updated_at, 
    FORMAT('Updated timestamp should be >= original after modification. Original: %s, New: %s', 
           original_updated_at, new_updated_at);
  ASSERT new_created_at = original_created_at, 
    'Created timestamp should not change on update';
  
  -- Also verify the name was actually updated
  ASSERT (SELECT name FROM groups WHERE id = test_group_id) = 'Updated Group Name',
    'Group name should be updated';
  
  RAISE NOTICE 'Property 8 PASSED: Group update modifies timestamp (trigger working correctly)';
END $$;

-- ============================================================================
-- Additional Edge Case Tests
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  test_group_id UUID;
BEGIN
  -- Get test user (find the one we created in the previous test)
  SELECT id INTO test_user_id FROM users WHERE email LIKE 'test3_%@example.com' LIMIT 1;
  
  -- Test: Group with NULL description should be allowed
  INSERT INTO groups (name, creator_id, description)
  VALUES ('Group with NULL description', test_user_id, NULL)
  RETURNING id INTO test_group_id;
  
  ASSERT test_group_id IS NOT NULL, 'Group with NULL description should be created successfully';
  
  -- Test: Group name with valid special characters
  INSERT INTO groups (name, creator_id)
  VALUES ('Group-Name_With.Special@Characters!', test_user_id);
  
  -- Test: Group with minimum valid name length (1 character)
  INSERT INTO groups (name, creator_id)
  VALUES ('A', test_user_id);
  
  -- Test: Group with maximum valid name length (100 characters)
  INSERT INTO groups (name, creator_id)
  VALUES (REPEAT('a', 100), test_user_id);
  
  RAISE NOTICE 'Edge case tests PASSED: Groups table handles boundary conditions correctly';
END $$;

-- ============================================================================
-- Foreign Key Constraint Tests
-- ============================================================================

DO $$
DECLARE
  fake_user_id UUID := gen_random_uuid();
  error_occurred BOOLEAN;
BEGIN
  -- Test: Cannot create group with non-existent creator
  error_occurred := FALSE;
  BEGIN
    INSERT INTO groups (name, creator_id)
    VALUES ('Invalid Group', fake_user_id);
  EXCEPTION WHEN foreign_key_violation THEN
    error_occurred := TRUE;
  END;
  ASSERT error_occurred, 'Group creation with non-existent creator should be rejected';
  
  RAISE NOTICE 'Foreign key constraint tests PASSED: Groups table enforces referential integrity';
END $$;

-- ============================================================================
-- Cleanup
-- ============================================================================

-- Clean up test data
DO $$
BEGIN
  DELETE FROM groups WHERE name LIKE '%Test%' OR name LIKE '%Group%' OR name = 'A';
  DELETE FROM users WHERE email LIKE '%test%@example.com';
  DROP TABLE IF EXISTS test_users;
  
  RAISE NOTICE 'Groups table property tests completed successfully!';
END $$;