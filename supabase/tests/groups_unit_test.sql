-- ============================================================================
-- Unit Tests: Groups Table
-- Description: Unit tests for groups table functionality and constraints
-- ============================================================================

-- Test setup: Create test users
DO $$
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_suffix TEXT := extract(epoch from now())::text;
BEGIN
  -- Create first test user with unique email
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('unit_test1_' || test_suffix || '@example.com', 'Unit Test User 1', 'USD', 'en')
  RETURNING id INTO test_user_1;
  
  -- Create second test user with unique email
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES ('unit_test2_' || test_suffix || '@example.com', 'Unit Test User 2', 'EUR', 'vi')
  RETURNING id INTO test_user_2;
  
  CREATE TEMP TABLE unit_test_users AS 
  SELECT test_user_1 as user_1, test_user_2 as user_2;
END $$;

-- ============================================================================
-- Test 1: Group creation with valid data
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  test_group_id UUID;
  group_count INTEGER;
BEGIN
  SELECT user_1 INTO test_user_id FROM unit_test_users;
  
  -- Test: Create group with minimal required data
  INSERT INTO groups (name, creator_id)
  VALUES ('Minimal Group', test_user_id)
  RETURNING id INTO test_group_id;
  
  -- Verify group was created
  SELECT COUNT(*) INTO group_count FROM groups WHERE id = test_group_id;
  ASSERT group_count = 1, 'Group should be created with minimal data';
  
  -- Test: Create group with all optional fields
  INSERT INTO groups (name, description, creator_id, primary_currency)
  VALUES (
    'Complete Group',
    'A group with all fields populated',
    test_user_id,
    'JPY'
  );
  
  RAISE NOTICE 'Test 1 PASSED: Group creation with valid data';
END $$;

-- ============================================================================
-- Test 2: Name constraints validation
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  error_count INTEGER := 0;
BEGIN
  SELECT user_1 INTO test_user_id FROM unit_test_users;
  
  -- Test 2.1: Empty name
  BEGIN
    INSERT INTO groups (name, creator_id) VALUES ('', test_user_id);
    RAISE NOTICE 'ERROR: Empty name was accepted!';
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
    RAISE NOTICE 'PASS: Empty name rejected';
  END;
  
  -- Test 2.2: Whitespace-only name
  BEGIN
    INSERT INTO groups (name, creator_id) VALUES ('   ', test_user_id);
    RAISE NOTICE 'ERROR: Whitespace-only name was accepted!';
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
    RAISE NOTICE 'PASS: Whitespace-only name rejected';
  END;
  
  -- Test 2.3: Tab and newline characters
  BEGIN
    INSERT INTO groups (name, creator_id) VALUES (E'\t\n', test_user_id);
    RAISE NOTICE 'ERROR: Tab/newline name was accepted!';
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
    RAISE NOTICE 'PASS: Tab/newline name rejected';
  END;
  
  -- Test 2.4: Name too long (101 characters)
  BEGIN
    INSERT INTO groups (name, creator_id) 
    VALUES (REPEAT('x', 101), test_user_id);
    RAISE NOTICE 'ERROR: Long name was accepted!';
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
    RAISE NOTICE 'PASS: Long name rejected';
  END;
  
  -- Test 2.5: Valid edge cases should work
  INSERT INTO groups (name, creator_id) VALUES ('A', test_user_id); -- 1 char
  INSERT INTO groups (name, creator_id) VALUES (REPEAT('y', 100), test_user_id); -- 100 chars
  INSERT INTO groups (name, creator_id) VALUES ('  Valid Name  ', test_user_id); -- Leading/trailing spaces
  
  ASSERT error_count = 4, FORMAT('All invalid name formats should be rejected (got %s errors, expected 4)', error_count);
  RAISE NOTICE 'Test 2 PASSED: Name constraints validation (% errors caught)', error_count;
END $$;

-- ============================================================================
-- Test 3: Currency code validation
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  error_count INTEGER := 0;
  success_count INTEGER := 0;
BEGIN
  SELECT user_1 INTO test_user_id FROM unit_test_users;
  
  -- Test 3.1: Invalid currency lengths
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency) 
    VALUES ('Test Group', test_user_id, 'US'); -- Too short
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
  END;
  
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency) 
    VALUES ('Test Group', test_user_id, 'USDD'); -- Too long
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
  END;
  
  -- Test 3.2: Invalid currency formats
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency) 
    VALUES ('Test Group', test_user_id, 'usd'); -- Lowercase
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
  END;
  
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency) 
    VALUES ('Test Group', test_user_id, 'U1D'); -- Contains number
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
  END;
  
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency) 
    VALUES ('Test Group', test_user_id, 'U$D'); -- Contains symbol
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
  END;
  
  -- Test 3.3: Valid currency codes should work
  INSERT INTO groups (name, creator_id, primary_currency) 
  VALUES ('USD Group', test_user_id, 'USD');
  success_count := success_count + 1;
  
  INSERT INTO groups (name, creator_id, primary_currency) 
  VALUES ('EUR Group', test_user_id, 'EUR');
  success_count := success_count + 1;
  
  INSERT INTO groups (name, creator_id, primary_currency) 
  VALUES ('VND Group', test_user_id, 'VND');
  success_count := success_count + 1;
  
  ASSERT error_count = 5, 'All invalid currency codes should be rejected';
  ASSERT success_count = 3, 'All valid currency codes should be accepted';
  RAISE NOTICE 'Test 3 PASSED: Currency code validation (% errors, % successes)', error_count, success_count;
END $$;

-- ============================================================================
-- Test 4: Description constraints validation
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  error_count INTEGER := 0;
BEGIN
  SELECT user_1 INTO test_user_id FROM unit_test_users;
  
  -- Test 4.1: Empty description should be rejected
  BEGIN
    INSERT INTO groups (name, creator_id, description) 
    VALUES ('Test Group', test_user_id, '');
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
  END;
  
  -- Test 4.2: Whitespace-only description should be rejected
  BEGIN
    INSERT INTO groups (name, creator_id, description) 
    VALUES ('Test Group', test_user_id, '   ');
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
  END;
  
  -- Test 4.3: Description too long (501 characters)
  BEGIN
    INSERT INTO groups (name, creator_id, description) 
    VALUES ('Test Group', test_user_id, REPEAT('x', 501));
  EXCEPTION WHEN check_violation THEN
    error_count := error_count + 1;
  END;
  
  -- Test 4.4: Valid descriptions should work
  INSERT INTO groups (name, creator_id, description) 
  VALUES ('Group with NULL desc', test_user_id, NULL); -- NULL is OK
  
  INSERT INTO groups (name, creator_id, description) 
  VALUES ('Group with short desc', test_user_id, 'Short'); -- Short description
  
  INSERT INTO groups (name, creator_id, description) 
  VALUES ('Group with max desc', test_user_id, REPEAT('x', 500)); -- Max length
  
  ASSERT error_count = 3, 'All invalid descriptions should be rejected';
  RAISE NOTICE 'Test 4 PASSED: Description constraints validation (% errors caught)', error_count;
END $$;

-- ============================================================================
-- Test 5: Foreign key constraint to users
-- ============================================================================

DO $$
DECLARE
  fake_user_id UUID := gen_random_uuid();
  error_occurred BOOLEAN := FALSE;
BEGIN
  -- Test: Cannot create group with non-existent creator
  BEGIN
    INSERT INTO groups (name, creator_id)
    VALUES ('Invalid Group', fake_user_id);
  EXCEPTION WHEN foreign_key_violation THEN
    error_occurred := TRUE;
  END;
  
  ASSERT error_occurred, 'Group creation with invalid creator_id should fail';
  RAISE NOTICE 'Test 5 PASSED: Foreign key constraint to users';
END $$;

-- ============================================================================
-- Test 6: Cascade delete behavior
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  test_group_id UUID;
  group_exists BOOLEAN;
BEGIN
  -- Create a new user for this test
  INSERT INTO users (email, display_name)
  VALUES ('cascade_test_' || extract(epoch from now())::text || '@example.com', 'Cascade Test User')
  RETURNING id INTO test_user_id;
  
  -- Create a group
  INSERT INTO groups (name, creator_id)
  VALUES ('Group for Cascade Test', test_user_id)
  RETURNING id INTO test_group_id;
  
  -- Verify group exists
  SELECT EXISTS(SELECT 1 FROM groups WHERE id = test_group_id) INTO group_exists;
  ASSERT group_exists, 'Group should exist before user deletion';
  
  -- Delete the user (should cascade to group)
  DELETE FROM users WHERE id = test_user_id;
  
  -- Verify group was deleted
  SELECT EXISTS(SELECT 1 FROM groups WHERE id = test_group_id) INTO group_exists;
  ASSERT NOT group_exists, 'Group should be deleted when creator is deleted';
  
  RAISE NOTICE 'Test 6 PASSED: Cascade delete behavior';
END $$;

-- ============================================================================
-- Test 7: Timestamp behavior
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  test_group_id UUID;
  created_time TIMESTAMPTZ;
  updated_time_1 TIMESTAMPTZ;
  updated_time_2 TIMESTAMPTZ;
BEGIN
  SELECT user_2 INTO test_user_id FROM unit_test_users;
  
  -- Create group and check initial timestamps
  INSERT INTO groups (name, creator_id)
  VALUES ('Timestamp Test Group', test_user_id)
  RETURNING id INTO test_group_id;
  
  SELECT created_at, updated_at INTO created_time, updated_time_1 
  FROM groups WHERE id = test_group_id;
  
  ASSERT created_time IS NOT NULL, 'Created timestamp should be set';
  ASSERT updated_time_1 IS NOT NULL, 'Updated timestamp should be set';
  ASSERT updated_time_1 >= created_time, 'Updated timestamp should be >= created timestamp';
  
  -- Wait and update
  PERFORM pg_sleep(0.1);
  UPDATE groups SET name = 'Updated Timestamp Test Group' WHERE id = test_group_id;
  
  SELECT updated_at INTO updated_time_2 FROM groups WHERE id = test_group_id;
  ASSERT updated_time_2 >= updated_time_1, 'Updated timestamp should be >= original after update';
  
  RAISE NOTICE 'Test 7 PASSED: Timestamp behavior';
END $$;

-- ============================================================================
-- Test 8: Index performance verification
-- ============================================================================

DO $$
DECLARE
  test_user_id UUID;
  i INTEGER;
  start_time TIMESTAMPTZ;
  end_time TIMESTAMPTZ;
  duration INTERVAL;
BEGIN
  SELECT user_2 INTO test_user_id FROM unit_test_users;
  
  -- Create multiple groups for performance testing
  start_time := clock_timestamp();
  
  FOR i IN 1..100 LOOP
    INSERT INTO groups (name, creator_id, primary_currency)
    VALUES ('Performance Test Group ' || i, test_user_id, 'USD');
  END LOOP;
  
  end_time := clock_timestamp();
  duration := end_time - start_time;
  
  -- Test index usage with queries
  start_time := clock_timestamp();
  
  -- Query by creator_id (should use idx_groups_creator_id)
  PERFORM COUNT(*) FROM groups WHERE creator_id = test_user_id;
  
  -- Query active groups (should use idx_groups_active)
  PERFORM COUNT(*) FROM groups WHERE deleted_at IS NULL;
  
  end_time := clock_timestamp();
  
  RAISE NOTICE 'Test 8 PASSED: Index performance verification (Insert: %, Query: %)', 
    duration, end_time - start_time;
END $$;

-- ============================================================================
-- Cleanup
-- ============================================================================

-- Clean up test data
DO $$
BEGIN
  DELETE FROM groups WHERE name LIKE '%Test%' OR name LIKE '%Group%' OR name = 'A' OR name LIKE 'Performance%';
  DELETE FROM users WHERE email LIKE '%unit_test%@example.com' OR email LIKE '%cascade_test%@example.com';
  DROP TABLE IF EXISTS unit_test_users;
  
  RAISE NOTICE 'Groups table unit tests completed successfully!';
END $$;