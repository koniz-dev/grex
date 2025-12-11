-- ============================================================================
-- Unit Tests: Users Table
-- Description: Focused unit tests for specific users table functionality
-- Validates: Requirements 1.1, 1.2
-- ============================================================================

BEGIN;

-- Test Plan
SELECT plan(15);

-- ============================================================================
-- Unit Test 1: Basic User Creation
-- ============================================================================

-- Test minimal user creation
INSERT INTO users (email, display_name) 
VALUES ('unit@test.com', 'Unit Test User')
RETURNING id INTO @user_id;

SELECT ok(
  @user_id IS NOT NULL,
  'User creation returns valid UUID'
);

SELECT is(
  (SELECT email FROM users WHERE id = @user_id),
  'unit@test.com',
  'Email is stored correctly'
);

SELECT is(
  (SELECT display_name FROM users WHERE id = @user_id),
  'Unit Test User',
  'Display name is stored correctly'
);

-- ============================================================================
-- Unit Test 2: Default Values
-- ============================================================================

SELECT is(
  (SELECT preferred_currency FROM users WHERE id = @user_id),
  'USD',
  'Default currency is USD'
);

SELECT is(
  (SELECT preferred_language FROM users WHERE id = @user_id),
  'en',
  'Default language is en'
);

SELECT ok(
  (SELECT deleted_at FROM users WHERE id = @user_id) IS NULL,
  'Default deleted_at is NULL'
);

-- ============================================================================
-- Unit Test 3: Timestamp Behavior
-- ============================================================================

SELECT ok(
  (SELECT created_at FROM users WHERE id = @user_id) <= NOW(),
  'Created timestamp is not in future'
);

SELECT ok(
  (SELECT updated_at FROM users WHERE id = @user_id) <= NOW(),
  'Updated timestamp is not in future'
);

SELECT is(
  (SELECT created_at FROM users WHERE id = @user_id),
  (SELECT updated_at FROM users WHERE id = @user_id),
  'Initial created_at equals updated_at'
);

-- ============================================================================
-- Unit Test 4: Email Uniqueness Constraint
-- ============================================================================

-- Test duplicate email rejection
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('unit@test.com', 'Duplicate User') $$,
  '23505',
  NULL,
  'Duplicate email is rejected'
);

-- Test different email acceptance
SELECT lives_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('different@test.com', 'Different User') $$,
  'Different email is accepted'
);

-- ============================================================================
-- Unit Test 5: Email Format Validation
-- ============================================================================

-- Test various invalid email formats
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('no-at-sign', 'Invalid') $$,
  '23514',
  NULL,
  'Email without @ is rejected'
);

SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('no-domain@', 'Invalid') $$,
  '23514',
  NULL,
  'Email without domain is rejected'
);

-- ============================================================================
-- Unit Test 6: Currency Code Validation
-- ============================================================================

-- Test valid currency codes
SELECT lives_ok(
  $$ INSERT INTO users (email, display_name, preferred_currency) VALUES ('eur@test.com', 'EUR User', 'EUR') $$,
  'EUR currency code is valid'
);

SELECT lives_ok(
  $$ INSERT INTO users (email, display_name, preferred_currency) VALUES ('vnd@test.com', 'VND User', 'VND') $$,
  'VND currency code is valid'
);

-- Test invalid currency code
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name, preferred_currency) VALUES ('invalid@test.com', 'Invalid', 'US') $$,
  '23514',
  NULL,
  'Invalid currency code length is rejected'
);

-- Finish tests
SELECT finish();

ROLLBACK;

-- ============================================================================
-- Performance Test Queries (for development)
-- ============================================================================

-- Uncomment to test performance:

-- Test index usage for email lookup
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM users WHERE email = 'test@example.com';

-- Test index usage for active users
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM users WHERE deleted_at IS NULL ORDER BY created_at;

-- Test bulk insert performance
-- INSERT INTO users (email, display_name) 
-- SELECT 
--   'user' || i || '@bulk.test', 
--   'Bulk User ' || i 
-- FROM generate_series(1, 1000) i;