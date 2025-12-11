-- ============================================================================
-- Unit Tests: Audit Logs Table
-- Description: Unit tests for audit_logs table functionality and constraints
-- ============================================================================

SELECT plan(9);

-- Create test users
INSERT INTO users (email, display_name) VALUES ('unit_test1@example.com', 'Unit Test User 1');
INSERT INTO users (email, display_name) VALUES ('unit_test2@example.com', 'Unit Test User 2');

-- Create test group
INSERT INTO groups (name, creator_id) 
VALUES ('Unit Test Group', (SELECT id FROM users WHERE email = 'unit_test1@example.com'));

-- Test 1: Basic audit log creation
INSERT INTO audit_logs (
  entity_type, entity_id, action,
  user_id, user_email, user_display_name,
  group_id, group_name,
  after_state
) VALUES (
  'group',
  (SELECT id FROM groups WHERE name = 'Unit Test Group'),
  'create',
  (SELECT id FROM users WHERE email = 'unit_test1@example.com'),
  'unit_test1@example.com',
  'Unit Test User 1',
  (SELECT id FROM groups WHERE name = 'Unit Test Group'),
  'Unit Test Group',
  '{"name": "Unit Test Group"}'::jsonb
);

SELECT ok(
  (SELECT COUNT(*) FROM audit_logs WHERE user_email = 'unit_test1@example.com') = 1,
  'Test 1: Basic audit log creation'
);

-- Test 2: Entity type validation (invalid type should fail)
SELECT throws_ok(
  $$INSERT INTO audit_logs (entity_type, entity_id, action, user_id, user_email, user_display_name, after_state) 
    VALUES ('invalid_type', gen_random_uuid(), 'create', 
            (SELECT id FROM users WHERE email = 'unit_test1@example.com'),
            'unit_test1@example.com', 'Unit Test User 1', '{}')$$,
  '23514',
  NULL,
  'Test 2: Invalid entity type correctly rejected'
);

-- Test 3: Required field constraints (empty email should fail)
SELECT throws_ok(
  $$INSERT INTO audit_logs (entity_type, entity_id, action, user_id, user_email, user_display_name, after_state) 
    VALUES ('user', gen_random_uuid(), 'create',
            (SELECT id FROM users WHERE email = 'unit_test1@example.com'),
            '', 'Unit Test User 1', '{}')$$,
  '23514',
  NULL,
  'Test 3: Empty user_email correctly rejected'
);

-- Test 4: State consistency (create without after_state should fail)
SELECT throws_ok(
  $$INSERT INTO audit_logs (entity_type, entity_id, action, user_id, user_email, user_display_name, before_state) 
    VALUES ('user', gen_random_uuid(), 'create',
            (SELECT id FROM users WHERE email = 'unit_test1@example.com'),
            'unit_test1@example.com', 'Unit Test User 1', '{}')$$,
  '23514',
  NULL,
  'Test 4: Create action without after_state correctly rejected'
);

-- Test 5: JSONB storage works correctly
INSERT INTO audit_logs (
  entity_type, entity_id, action,
  user_id, user_email, user_display_name,
  after_state
) VALUES (
  'expense',
  gen_random_uuid(),
  'create',
  (SELECT id FROM users WHERE email = 'unit_test1@example.com'),
  'unit_test1@example.com',
  'Unit Test User 1',
  '{"amount": 150.75, "currency": "USD", "description": "Test expense"}'::jsonb
);

SELECT ok(
  (SELECT after_state->>'amount' FROM audit_logs WHERE entity_type = 'expense' AND user_email = 'unit_test1@example.com' LIMIT 1) = '150.75',
  'Test 5: JSONB data stored and retrieved correctly'
);

-- Test 6: Foreign key constraints (invalid user_id should fail)
SELECT throws_ok(
  $$INSERT INTO audit_logs (entity_type, entity_id, action, user_id, user_email, user_display_name, after_state) 
    VALUES ('user', gen_random_uuid(), 'create', gen_random_uuid(),
            'invalid@example.com', 'Invalid User', '{}')$$,
  '23503',
  NULL,
  'Test 6: Invalid user_id correctly rejected'
);

-- Test 7: SET NULL behavior on user deletion
-- First create audit log for user 2
INSERT INTO audit_logs (
  entity_type, entity_id, action,
  user_id, user_email, user_display_name,
  after_state
) VALUES (
  'user',
  (SELECT id FROM users WHERE email = 'unit_test2@example.com'),
  'create',
  (SELECT id FROM users WHERE email = 'unit_test2@example.com'),
  'unit_test2@example.com',
  'Unit Test User 2',
  '{}'::jsonb
);

-- Delete the user
DELETE FROM users WHERE email = 'unit_test2@example.com';

-- Verify SET NULL behavior
SELECT ok(
  (SELECT user_id FROM audit_logs WHERE user_email = 'unit_test2@example.com') IS NULL,
  'Test 7: user_id is NULL after user deletion'
);

SELECT ok(
  (SELECT user_email FROM audit_logs WHERE user_email = 'unit_test2@example.com') = 'unit_test2@example.com',
  'Test 8: user_email preserved after user deletion'
);

-- Test 9: Timestamp is set automatically
SELECT ok(
  (SELECT created_at FROM audit_logs WHERE user_email = 'unit_test1@example.com' LIMIT 1) IS NOT NULL,
  'Test 9: Timestamp set correctly on creation'
);

SELECT * FROM finish();
