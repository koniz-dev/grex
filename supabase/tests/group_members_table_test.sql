-- ============================================================================
-- Property Tests: Group Members Table
-- Description: Property-based tests for group_members table correctness
-- ============================================================================

-- Test setup: Create test data
DO $
DECLARE
  test_user_1 UUID;
  test_user_2 UUID;
  test_user_3 UUID;
  test_group_1 UUID;
  test_group_2 UUID;
  test_member_1 UUID;
  test_member_2 UUID;
BEGIN
  -- Create test users
  INSERT INTO users (email, display_name, preferred_currency, preferred_language)
  VALUES 
    ('test1@example.com', 'Test User 1', 'USD', 'en'),
    ('test2@example.com', 'Test User 2', 'EUR', 'vi'),
    ('test3@example.com', 'Test User 3', 'GBP', 'en')
  RETURNING id INTO test_user_1, test_user_2, test_user_3;

  -- Create test groups
  INSERT INTO groups (name, creator_id, primary_currency)
  VALUES 
    ('Test Group 1', test_user_1, 'USD'),
    ('Test Group 2', test_user_2, 'EUR')
  RETURNING id INTO test_group_1, test_group_2;

  -- ========================================================================
  -- Property 9: Membership creation includes all required fields
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 9: Membership creation includes all required fields';
  
  -- Test: Create membership with all required fields
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (test_group_1, test_user_1, 'administrator')
  RETURNING id INTO test_member_1;
  
  -- Verify all fields are populated
  PERFORM 1 FROM group_members 
  WHERE id = test_member_1
    AND group_id IS NOT NULL
    AND user_id IS NOT NULL
    AND role IS NOT NULL
    AND joined_at IS NOT NULL
    AND updated_at IS NOT NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 9 FAILED: Membership creation missing required fields';
  END IF;
  
  RAISE NOTICE 'Property 9 PASSED: All required fields populated on membership creation';

  -- ========================================================================
  -- Property 10: User-group uniqueness is enforced
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 10: User-group uniqueness is enforced';
  
  -- Test: Attempt to create duplicate membership (should fail)
  BEGIN
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_1, test_user_1, 'editor');
    
    RAISE EXCEPTION 'Property 10 FAILED: Duplicate membership was allowed';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE 'Property 10 PASSED: Duplicate membership correctly rejected';
  END;
  
  -- Test: Same user can join different groups (should succeed)
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (test_group_2, test_user_1, 'editor')
  RETURNING id INTO test_member_2;
  
  IF test_member_2 IS NULL THEN
    RAISE EXCEPTION 'Property 10 FAILED: User cannot join multiple groups';
  END IF;
  
  RAISE NOTICE 'Property 10 PASSED: User can join multiple different groups';

  -- ========================================================================
  -- Property 11: Role validation is enforced
  -- ========================================================================
  
  RAISE NOTICE 'Testing Property 11: Role validation is enforced';
  
  -- Test: Valid roles are accepted
  INSERT INTO group_members (group_id, user_id, role)
  VALUES 
    (test_group_1, test_user_2, 'administrator'),
    (test_group_1, test_user_3, 'editor'),
    (test_group_2, test_user_3, 'viewer');
  
  -- Verify roles are stored correctly
  PERFORM 1 FROM group_members 
  WHERE group_id = test_group_1 AND user_id = test_user_2 AND role = 'administrator';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 11 FAILED: Valid administrator role not stored';
  END IF;
  
  PERFORM 1 FROM group_members 
  WHERE group_id = test_group_1 AND user_id = test_user_3 AND role = 'editor';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 11 FAILED: Valid editor role not stored';
  END IF;
  
  PERFORM 1 FROM group_members 
  WHERE group_id = test_group_2 AND user_id = test_user_3 AND role = 'viewer';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Property 11 FAILED: Valid viewer role not stored';
  END IF;
  
  -- Test: Invalid role is rejected
  BEGIN
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_2, test_user_2, 'invalid_role'::member_role);
    
    RAISE EXCEPTION 'Property 11 FAILED: Invalid role was accepted';
  EXCEPTION
    WHEN invalid_text_representation THEN
      RAISE NOTICE 'Property 11 PASSED: Invalid role correctly rejected';
  END;
  
  RAISE NOTICE 'Property 11 PASSED: Role validation enforced correctly';

  -- ========================================================================
  -- Additional Property Tests
  -- ========================================================================
  
  -- Test: Foreign key constraints are enforced
  RAISE NOTICE 'Testing foreign key constraints';
  
  -- Test: Invalid group_id is rejected
  BEGIN
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (gen_random_uuid(), test_user_1, 'editor');
    
    RAISE EXCEPTION 'Foreign key constraint FAILED: Invalid group_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Foreign key constraint PASSED: Invalid group_id correctly rejected';
  END;
  
  -- Test: Invalid user_id is rejected
  BEGIN
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_1, gen_random_uuid(), 'editor');
    
    RAISE EXCEPTION 'Foreign key constraint FAILED: Invalid user_id was accepted';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'Foreign key constraint PASSED: Invalid user_id correctly rejected';
  END;

  -- Test: Cascade delete when group is deleted
  RAISE NOTICE 'Testing cascade delete behavior';
  
  -- Count memberships before group deletion
  DECLARE
    membership_count_before INTEGER;
    membership_count_after INTEGER;
  BEGIN
    SELECT COUNT(*) INTO membership_count_before 
    FROM group_members WHERE group_id = test_group_2;
    
    -- Delete the group
    DELETE FROM groups WHERE id = test_group_2;
    
    -- Count memberships after group deletion
    SELECT COUNT(*) INTO membership_count_after 
    FROM group_members WHERE group_id = test_group_2;
    
    IF membership_count_after != 0 THEN
      RAISE EXCEPTION 'Cascade delete FAILED: Memberships not deleted with group';
    END IF;
    
    RAISE NOTICE 'Cascade delete PASSED: Memberships deleted when group deleted (% -> %)', 
      membership_count_before, membership_count_after;
  END;

  -- Test: Cascade delete when user is deleted
  RAISE NOTICE 'Testing cascade delete when user is deleted';
  
  DECLARE
    user_membership_count_before INTEGER;
    user_membership_count_after INTEGER;
  BEGIN
    SELECT COUNT(*) INTO user_membership_count_before 
    FROM group_members WHERE user_id = test_user_3;
    
    -- Delete the user
    DELETE FROM users WHERE id = test_user_3;
    
    -- Count memberships after user deletion
    SELECT COUNT(*) INTO user_membership_count_after 
    FROM group_members WHERE user_id = test_user_3;
    
    IF user_membership_count_after != 0 THEN
      RAISE EXCEPTION 'Cascade delete FAILED: Memberships not deleted with user';
    END IF;
    
    RAISE NOTICE 'Cascade delete PASSED: Memberships deleted when user deleted (% -> %)', 
      user_membership_count_before, user_membership_count_after;
  END;

  -- Test: Timestamp triggers work correctly
  RAISE NOTICE 'Testing timestamp triggers';
  
  DECLARE
    original_updated_at TIMESTAMPTZ;
    new_updated_at TIMESTAMPTZ;
  BEGIN
    -- Get original timestamp
    SELECT updated_at INTO original_updated_at 
    FROM group_members WHERE id = test_member_1;
    
    -- Wait a moment to ensure timestamp difference
    PERFORM pg_sleep(0.1);
    
    -- Update the membership
    UPDATE group_members 
    SET role = 'editor' 
    WHERE id = test_member_1;
    
    -- Get new timestamp
    SELECT updated_at INTO new_updated_at 
    FROM group_members WHERE id = test_member_1;
    
    IF new_updated_at <= original_updated_at THEN
      RAISE EXCEPTION 'Timestamp trigger FAILED: updated_at not changed on update';
    END IF;
    
    RAISE NOTICE 'Timestamp trigger PASSED: updated_at changed from % to %', 
      original_updated_at, new_updated_at;
  END;

  -- ========================================================================
  -- Cleanup
  -- ========================================================================
  
  RAISE NOTICE 'Cleaning up test data';
  
  -- Clean up test data (cascade will handle related records)
  DELETE FROM users WHERE email LIKE 'test%@example.com';
  DELETE FROM groups WHERE name LIKE 'Test Group %';
  
  RAISE NOTICE 'All group_members table property tests completed successfully!';

END;
$;