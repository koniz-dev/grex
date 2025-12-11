-- ============================================================================
-- Unit Tests: Group Members Table
-- Description: Unit tests for group_members table functionality and constraints
-- ============================================================================

-- Test setup and execution
DO $
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_user_3 UUID;
  test_group_1 UUID;
  test_group_2 UUID;
  test_member_id UUID;
BEGIN
  RAISE NOTICE 'Starting group_members table unit tests';

  -- ========================================================================
  -- Setup: Create test data
  -- ========================================================================
  
  -- Create test users
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES 
    ('unit_test1@example.com', 'Unit Test User 1', 'USD', 'en'),
    ('unit_test2@example.com', 'Unit Test User 2', 'EUR', 'vi'),
    ('unit_test3@example.com', 'Unit Test User 3', 'GBP', 'en')
  RETURNING id INTO test_user_1, test_user_2, test_user_3;

  -- Create test groups
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES 
    ('Unit Test Group 1', test_user_1, 'USD'),
    ('Unit Test Group 2', test_user_2, 'EUR')
  RETURNING id INTO test_group_1, test_group_2;

  -- ========================================================================
  -- Test 1: Basic membership creation
  -- ========================================================================
  
  RAISE NOTICE 'Test 1: Basic membership creation';
  
  -- Test creating membership with all fields
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (test_group_1, test_user_1, 'administrator')
  RETURNING id INTO test_member_id;
  
  -- Verify membership was created
  PERFORM 1 FROM group_members 
  WHERE id = test_member_id
    AND group_id = test_group_1
    AND user_id = test_user_1
    AND role = 'administrator'
    AND joined_at IS NOT NULL
    AND updated_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 1 FAILED: Basic membership creation failed';
  END IF;
  
  RAISE NOTICE 'Test 1 PASSED: Basic membership creation successful';

  -- ========================================================================
  -- Test 2: Default role assignment
  -- ========================================================================
  
  RAISE NOTICE 'Test 2: Default role assignment';
  
  -- Test creating membership without specifying role (should default to 'editor')
  INSERT INTO group_members (group_id, user_id)
  VALUES (test_group_1, test_user_2)
  RETURNING id INTO test_member_id;
  
  -- Verify default role is 'editor'
  PERFORM 1 FROM group_members 
  WHERE id = test_member_id AND role = 'editor';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 2 FAILED: Default role not set to editor';
  END IF;
  
  RAISE NOTICE 'Test 2 PASSED: Default role correctly set to editor';

  -- ========================================================================
  -- Test 3: Unique constraint on (group_id, user_id)
  -- ========================================================================
  
  RAISE NOTICE 'Test 3: Unique constraint on (group_id, user_id)';
  
  -- Test duplicate membership (should fail)
  BEGIN
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_1, test_user_2, 'viewer');
    
    RAISE EXCEPTION 'Test 3 FAILED: Duplicate membership was allowed';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE 'Test 3 PASSED: Duplicate membership correctly rejected';
  END;

  -- ========================================================================
  -- Test 4: Role enum validation
  -- ========================================================================
  
  RAISE NOTICE 'Test 4: Role enum validation';
  
  -- Test all valid roles
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (test_group_2, test_user_1, 'administrator');
  
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (test_group_2, test_user_2, 'editor');
  
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (test_group_2, test_user_3, 'viewer');
  
  -- Verify all roles were stored correctly
  PERFORM 1 FROM group_members 
  WHERE group_id = test_group_2 AND user_id = test_user_1 AND role = 'administrator';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 4 FAILED: Administrator role not stored correctly';
  END IF;
  
  PERFORM 1 FROM group_members 
  WHERE group_id = test_group_2 AND user_id = test_user_2 AND role = 'editor';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 4 FAILED: Editor role not stored correctly';
  END IF;
  
  PERFORM 1 FROM group_members 
  WHERE group_id = test_group_2 AND user_id = test_user_3 AND role = 'viewer';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Test 4 FAILED: Viewer role not stored correctly';
  END IF;
  
  RAISE NOTICE 'Test 4 PASSED: All valid roles stored correctly';

  -- ========================================================================
  -- Test 5: Foreign key constraint to groups table
  -- ========================================================================
  
  RAISE NOTICE 'Test 5: Foreign key constraint to groups table';
  
  -- Test invalid group_id (should fail)
  BEGIN
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (gen_random_uuid(), test_user_1, 'editor');
    
    RAISE EXCEPTION 'Test 5 FAILED: Invalid group_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Test 5 PASSED: Invalid group_id correctly rejected';
  END;

  -- ========================================================================
  -- Test 6: Foreign key constraint to users table
  -- ========================================================================
  
  RAISE NOTICE 'Test 6: Foreign key constraint to users table';
  
  -- Test invalid user_id (should fail)
  BEGIN
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_1, gen_random_uuid(), 'editor');
    
    RAISE EXCEPTION 'Test 6 FAILED: Invalid user_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Test 6 PASSED: Invalid user_id correctly rejected';
  END;

  -- ========================================================================
  -- Test 7: Cascade delete when group is deleted
  -- ========================================================================
  
  RAISE NOTICE 'Test 7: Cascade delete when group is deleted';
  
  -- Count memberships in test_group_2 before deletion
  DECLARE
    membership_count INTEGER;
  BEGIN
    SELECT COUNT(*) INTO membership_count 
    FROM group_members WHERE group_id = test_group_2;
    
    IF membership_count = 0 THEN
      RAISE EXCEPTION 'Test 7 SETUP FAILED: No memberships found in test group';
    END IF;
    
    -- Delete the group
    DELETE FROM groups WHERE id = test_group_2;
    
    -- Verify all memberships were deleted
    SELECT COUNT(*) INTO membership_count 
    FROM group_members WHERE group_id = test_group_2;
    
    IF membership_count != 0 THEN
      RAISE EXCEPTION 'Test 7 FAILED: Memberships not deleted when group deleted';
    END IF;
    
    RAISE NOTICE 'Test 7 PASSED: Memberships cascade deleted with group';
  END;

  -- ========================================================================
  -- Test 8: Cascade delete when user is deleted
  -- ========================================================================
  
  RAISE NOTICE 'Test 8: Cascade delete when user is deleted';
  
  -- Count memberships for test_user_3 before deletion
  DECLARE
    user_membership_count INTEGER;
  BEGIN
    SELECT COUNT(*) INTO user_membership_count 
    FROM group_members WHERE user_id = test_user_3;
    
    -- Delete the user
    DELETE FROM users WHERE id = test_user_3;
    
    -- Verify all memberships were deleted
    SELECT COUNT(*) INTO user_membership_count 
    FROM group_members WHERE user_id = test_user_3;
    
    IF user_membership_count != 0 THEN
      RAISE EXCEPTION 'Test 8 FAILED: Memberships not deleted when user deleted';
    END IF;
    
    RAISE NOTICE 'Test 8 PASSED: Memberships cascade deleted with user';
  END;

  -- ========================================================================
  -- Test 9: Timestamp behavior
  -- ========================================================================
  
  RAISE NOTICE 'Test 9: Timestamp behavior';
  
  -- Get a membership to test timestamps
  SELECT id INTO test_member_id 
  FROM group_members 
  WHERE group_id = test_group_1 AND user_id = test_user_1;
  
  DECLARE
    original_joined_at TIMESTAMPTZ;
    original_updated_at TIMESTAMPTZ;
    new_joined_at TIMESTAMPTZ;
    new_updated_at TIMESTAMPTZ;
  BEGIN
    -- Get original timestamps
    SELECT joined_at, updated_at INTO original_joined_at, original_updated_at
    FROM group_members WHERE id = test_member_id;
    
    -- Wait a moment to ensure timestamp difference
    PERFORM pg_sleep(0.1);
    
    -- Update the membership
    UPDATE group_members 
    SET role = 'editor' 
    WHERE id = test_member_id;
    
    -- Get new timestamps
    SELECT joined_at, updated_at INTO new_joined_at, new_updated_at
    FROM group_members WHERE id = test_member_id;
    
    -- Verify joined_at didn't change
    IF new_joined_at != original_joined_at THEN
      RAISE EXCEPTION 'Test 9 FAILED: joined_at changed on update';
    END IF;
    
    -- Verify updated_at changed
    IF new_updated_at <= original_updated_at THEN
      RAISE EXCEPTION 'Test 9 FAILED: updated_at not updated on modification';
    END IF;
    
    RAISE NOTICE 'Test 9 PASSED: Timestamps behave correctly (joined_at preserved, updated_at changed)';
  END;

  -- ========================================================================
  -- Test 10: Multiple memberships per user (different groups)
  -- ========================================================================
  
  RAISE NOTICE 'Test 10: Multiple memberships per user (different groups)';
  
  -- Create another group for testing
  DECLARE
    test_group_3 UUID;
  BEGIN
    INSERT INTO groups (name, creator_id, primary_currency)
    VALUES ('Unit Test Group 3', test_user_1, 'JPY')
    RETURNING id INTO test_group_3;
    
    -- Add test_user_1 to the new group (they're already in test_group_1)
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_3, test_user_1, 'viewer');
    
    -- Verify user has memberships in multiple groups
    DECLARE
      membership_count INTEGER;
    BEGIN
      SELECT COUNT(*) INTO membership_count 
      FROM group_members WHERE user_id = test_user_1;
      
      IF membership_count < 2 THEN
        RAISE EXCEPTION 'Test 10 FAILED: User cannot have multiple group memberships';
      END IF;
      
      RAISE NOTICE 'Test 10 PASSED: User can have multiple group memberships (count: %)', membership_count;
    END;
  END;

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up unit test data';
  
  -- Clean up test data (cascade will handle related records)
  DELETE FROM users WHERE email LIKE 'unit_test%@example.com';
  DELETE FROM groups WHERE name LIKE 'Unit Test Group %';
  
  RAISE NOTICE 'All group_members table unit tests completed successfully!';

END;
$;