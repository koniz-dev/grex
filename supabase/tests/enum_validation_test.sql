-- ============================================================================
-- Property Tests: Enum Validation
-- Description: Test enum types validation and constraints
-- Property: Enum values are validated (Property 44)
-- Validates: Requirements 13.4
-- ============================================================================

-- Test Framework Setup
-- Note: This uses pgTAP testing framework for PostgreSQL
-- Install: CREATE EXTENSION pgtap;

BEGIN;

-- Load the pgTAP extension
-- CREATE EXTENSION IF NOT EXISTS pgtap;

-- ============================================================================
-- Property 44: Enum values are validated
-- For any enum column insertion, only valid enum values should be accepted,
-- and invalid values should be rejected.
-- ============================================================================

-- Test Plan
SELECT plan(15);

-- ============================================================================
-- Test 1: member_role enum validation
-- ============================================================================

-- Test valid member_role values
SELECT lives_ok(
  $$ SELECT 'administrator'::member_role $$,
  'administrator is valid member_role'
);

SELECT lives_ok(
  $$ SELECT 'editor'::member_role $$,
  'editor is valid member_role'
);

SELECT lives_ok(
  $$ SELECT 'viewer'::member_role $$,
  'viewer is valid member_role'
);

-- Test invalid member_role values
SELECT throws_ok(
  $$ SELECT 'invalid_role'::member_role $$,
  '22P02',
  'invalid input value for enum member_role: "invalid_role"',
  'invalid_role should be rejected for member_role'
);

SELECT throws_ok(
  $$ SELECT 'admin'::member_role $$,
  '22P02',
  'invalid input value for enum member_role: "admin"',
  'admin should be rejected for member_role (must be administrator)'
);

-- ============================================================================
-- Test 2: split_method enum validation
-- ============================================================================

-- Test valid split_method values
SELECT lives_ok(
  $$ SELECT 'equal'::split_method $$,
  'equal is valid split_method'
);

SELECT lives_ok(
  $$ SELECT 'percentage'::split_method $$,
  'percentage is valid split_method'
);

SELECT lives_ok(
  $$ SELECT 'exact'::split_method $$,
  'exact is valid split_method'
);

SELECT lives_ok(
  $$ SELECT 'shares'::split_method $$,
  'shares is valid split_method'
);

-- Test invalid split_method values
SELECT throws_ok(
  $$ SELECT 'proportional'::split_method $$,
  '22P02',
  'invalid input value for enum split_method: "proportional"',
  'proportional should be rejected for split_method (must be shares)'
);

SELECT throws_ok(
  $$ SELECT 'custom'::split_method $$,
  '22P02',
  'invalid input value for enum split_method: "custom"',
  'custom should be rejected for split_method'
);

-- ============================================================================
-- Test 3: action_type enum validation
-- ============================================================================

-- Test valid action_type values
SELECT lives_ok(
  $$ SELECT 'create'::action_type $$,
  'create is valid action_type'
);

SELECT lives_ok(
  $$ SELECT 'update'::action_type $$,
  'update is valid action_type'
);

SELECT lives_ok(
  $$ SELECT 'delete'::action_type $$,
  'delete is valid action_type'
);

-- Test invalid action_type values
SELECT throws_ok(
  $$ SELECT 'insert'::action_type $$,
  '22P02',
  'invalid input value for enum action_type: "insert"',
  'insert should be rejected for action_type (must be create)'
);

SELECT throws_ok(
  $$ SELECT 'remove'::action_type $$,
  '22P02',
  'invalid input value for enum action_type: "remove"',
  'remove should be rejected for action_type (must be delete)'
);

-- ============================================================================
-- Property-Based Test: Random invalid values
-- ============================================================================

-- Test that random strings are rejected
-- This simulates property-based testing with random inputs
DO $$
DECLARE
  invalid_values TEXT[] := ARRAY['', 'null', '123', 'ADMIN', 'Equal', 'CREATE', 'random_string', 'special!@#'];
  val TEXT;
BEGIN
  FOREACH val IN ARRAY invalid_values
  LOOP
    -- Test member_role
    BEGIN
      EXECUTE format('SELECT %L::member_role', val);
      RAISE EXCEPTION 'Expected enum validation to fail for member_role: %', val;
    EXCEPTION
      WHEN invalid_text_representation THEN
        -- Expected behavior - enum validation rejected the value
        NULL;
    END;
    
    -- Test split_method
    BEGIN
      EXECUTE format('SELECT %L::split_method', val);
      RAISE EXCEPTION 'Expected enum validation to fail for split_method: %', val;
    EXCEPTION
      WHEN invalid_text_representation THEN
        -- Expected behavior - enum validation rejected the value
        NULL;
    END;
    
    -- Test action_type
    BEGIN
      EXECUTE format('SELECT %L::action_type', val);
      RAISE EXCEPTION 'Expected enum validation to fail for action_type: %', val;
    EXCEPTION
      WHEN invalid_text_representation THEN
        -- Expected behavior - enum validation rejected the value
        NULL;
    END;
  END LOOP;
END
$$;

-- Finish tests
SELECT finish();

ROLLBACK;

-- ============================================================================
-- Manual Test Queries (for development)
-- ============================================================================

-- Uncomment to run manual tests:

-- View all enum types
-- SELECT typname, typtype FROM pg_type WHERE typname IN ('member_role', 'split_method', 'action_type');

-- View enum values
-- SELECT enumlabel FROM pg_enum WHERE enumtypid = 'member_role'::regtype ORDER BY enumsortorder;

-- Test valid values
-- SELECT 'administrator'::member_role, 'equal'::split_method, 'create'::action_type;

-- Test invalid values (should fail)
-- SELECT 'invalid'::member_role;  -- Should throw error