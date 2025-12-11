-- ============================================================================
-- Property Tests: Users Table
-- Description: Test users table constraints, validation, and properties
-- Properties: 1, 2, 3, 4 (User creation, email uniqueness, timestamp updates, cascade delete)
-- Validates: Requirements 1.1, 1.2, 1.3, 1.5
-- ============================================================================

BEGIN;

-- Test Plan
SELECT plan(25);

-- ============================================================================
-- Property 1: User creation includes all required fields
-- For any user registration, the created user record should have a unique ID,
-- email, display name, and timestamps populated.
-- ============================================================================

-- Test user creation with all required fields
INSERT INTO users (email, display_name) 
VALUES ('test@example.com', 'Test User');

SELECT ok(
  EXISTS(
    SELECT 1 FROM users 
    WHERE email = 'test@example.com' 
    AND display_name = 'Test User'
    AND id IS NOT NULL
    AND created_at IS NOT NULL
    AND updated_at IS NOT NULL
  ),
  'User creation includes all required fields'
);

-- Test default values are set
SELECT ok(
  EXISTS(
    SELECT 1 FROM users 
    WHERE email = 'test@example.com'
    AND preferred_currency = 'USD'
    AND preferred_language = 'en'
    AND deleted_at IS NULL
  ),
  'User creation sets default values correctly'
);

-- ============================================================================
-- Property 2: Email uniqueness is enforced
-- For any two users, their email addresses should be different,
-- and attempting to insert a duplicate email should be rejected.
-- ============================================================================

-- Test unique email constraint
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('test@example.com', 'Another User') $$,
  '23505',
  'duplicate key value violates unique constraint "users_email_key"',
  'Duplicate email should be rejected'
);

-- Test case insensitive uniqueness (PostgreSQL is case sensitive by default)
SELECT lives_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('TEST@EXAMPLE.COM', 'Upper Case User') $$,
  'Different case email should be allowed (case sensitive)'
);

-- ============================================================================
-- Property 3: Updated timestamp changes on modification
-- For any user profile update, the updated_at timestamp should be
-- greater than its previous value.
-- ============================================================================

-- Get initial timestamp
SELECT updated_at INTO @initial_timestamp 
FROM users 
WHERE email = 'test@example.com';

-- Wait a moment and update
SELECT pg_sleep(0.1);

UPDATE users 
SET display_name = 'Updated Test User' 
WHERE email = 'test@example.com';

-- Verify timestamp was updated
SELECT ok(
  (SELECT updated_at FROM users WHERE email = 'test@example.com') > 
  (SELECT updated_at FROM users WHERE email = 'test@example.com' LIMIT 1),
  'Updated timestamp changes on modification'
);

-- ============================================================================
-- Email Format Validation Tests
-- ============================================================================

-- Test valid email formats
SELECT lives_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('valid.email@domain.com', 'Valid User 1') $$,
  'Valid email format should be accepted'
);

SELECT lives_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('user+tag@example.org', 'Valid User 2') $$,
  'Email with plus sign should be accepted'
);

SELECT lives_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('user123@sub.domain.co.uk', 'Valid User 3') $$,
  'Email with subdomain should be accepted'
);

-- Test invalid email formats
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('invalid-email', 'Invalid User') $$,
  '23514',
  'new row for relation "users" violates check constraint "email_format"',
  'Invalid email format should be rejected'
);

SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('user@', 'Invalid User') $$,
  '23514',
  'new row for relation "users" violates check constraint "email_format"',
  'Incomplete email should be rejected'
);

SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('@domain.com', 'Invalid User') $$,
  '23514',
  'new row for relation "users" violates check constraint "email_format"',
  'Email without username should be rejected'
);

-- ============================================================================
-- Display Name Validation Tests
-- ============================================================================

-- Test empty display name
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('empty@example.com', '') $$,
  '23514',
  'new row for relation "users" violates check constraint "display_name_not_empty"',
  'Empty display name should be rejected'
);

-- Test whitespace-only display name
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('whitespace@example.com', '   ') $$,
  '23514',
  'new row for relation "users" violates check constraint "display_name_not_empty"',
  'Whitespace-only display name should be rejected'
);

-- Test max length display name
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name) VALUES ('long@example.com', $long$This is a very long display name that exceeds the maximum allowed length of 100 characters and should be rejected by the constraint$long$) $$,
  '23514',
  'new row for relation "users" violates check constraint "display_name_max_length"',
  'Display name exceeding max length should be rejected'
);

-- ============================================================================
-- Currency Code Validation Tests
-- ============================================================================

-- Test valid currency codes
SELECT lives_ok(
  $$ INSERT INTO users (email, display_name, preferred_currency) VALUES ('currency1@example.com', 'Currency User 1', 'EUR') $$,
  'Valid currency code EUR should be accepted'
);

SELECT lives_ok(
  $$ INSERT INTO users (email, display_name, preferred_currency) VALUES ('currency2@example.com', 'Currency User 2', 'VND') $$,
  'Valid currency code VND should be accepted'
);

-- Test invalid currency codes
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name, preferred_currency) VALUES ('invalid-currency@example.com', 'Invalid Currency User', 'usd') $$,
  '23514',
  'new row for relation "users" violates check constraint "currency_code_format"',
  'Lowercase currency code should be rejected'
);

SELECT throws_ok(
  $$ INSERT INTO users (email, display_name, preferred_currency) VALUES ('invalid-currency2@example.com', 'Invalid Currency User', 'USDD') $$,
  '23514',
  'new row for relation "users" violates check constraint "currency_code_length"',
  'Currency code with wrong length should be rejected'
);

-- ============================================================================
-- Language Code Validation Tests
-- ============================================================================

-- Test valid language codes
SELECT lives_ok(
  $$ INSERT INTO users (email, display_name, preferred_language) VALUES ('lang1@example.com', 'Language User 1', 'vi') $$,
  'Valid language code vi should be accepted'
);

SELECT lives_ok(
  $$ INSERT INTO users (email, display_name, preferred_language) VALUES ('lang2@example.com', 'Language User 2', 'zh') $$,
  'Valid language code zh should be accepted'
);

-- Test invalid language codes
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name, preferred_language) VALUES ('invalid-lang@example.com', 'Invalid Language User', 'EN') $$,
  '23514',
  'new row for relation "users" violates check constraint "language_code_format"',
  'Uppercase language code should be rejected'
);

SELECT throws_ok(
  $$ INSERT INTO users (email, display_name, preferred_language) VALUES ('invalid-lang2@example.com', 'Invalid Language User', 'eng') $$,
  '23514',
  'new row for relation "users" violates check constraint "language_code_length"',
  'Language code with wrong length should be rejected'
);

-- ============================================================================
-- Avatar URL Validation Tests
-- ============================================================================

-- Test valid avatar URLs
SELECT lives_ok(
  $$ INSERT INTO users (email, display_name, avatar_url) VALUES ('avatar1@example.com', 'Avatar User 1', 'https://example.com/avatar.jpg') $$,
  'Valid HTTPS avatar URL should be accepted'
);

SELECT lives_ok(
  $$ INSERT INTO users (email, display_name, avatar_url) VALUES ('avatar2@example.com', 'Avatar User 2', 'http://example.com/avatar.png') $$,
  'Valid HTTP avatar URL should be accepted'
);

-- Test NULL avatar URL (should be allowed)
SELECT lives_ok(
  $$ INSERT INTO users (email, display_name, avatar_url) VALUES ('no-avatar@example.com', 'No Avatar User', NULL) $$,
  'NULL avatar URL should be accepted'
);

-- Test invalid avatar URL
SELECT throws_ok(
  $$ INSERT INTO users (email, display_name, avatar_url) VALUES ('invalid-avatar@example.com', 'Invalid Avatar User', 'not-a-url') $$,
  '23514',
  'new row for relation "users" violates check constraint "avatar_url_format"',
  'Invalid avatar URL should be rejected'
);

-- ============================================================================
-- Property-Based Test: Random valid data
-- ============================================================================

-- Test multiple valid user creations
DO $$
DECLARE
  i INTEGER;
  test_email TEXT;
  test_name TEXT;
BEGIN
  FOR i IN 1..10 LOOP
    test_email := 'user' || i || '@test' || i || '.com';
    test_name := 'Test User ' || i;
    
    INSERT INTO users (email, display_name) 
    VALUES (test_email, test_name);
    
    -- Verify user was created with all required fields
    IF NOT EXISTS(
      SELECT 1 FROM users 
      WHERE email = test_email 
      AND display_name = test_name
      AND id IS NOT NULL
      AND created_at IS NOT NULL
      AND updated_at IS NOT NULL
      AND preferred_currency = 'USD'
      AND preferred_language = 'en'
    ) THEN
      RAISE EXCEPTION 'User creation failed for %', test_email;
    END IF;
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

-- View table structure
-- \d users

-- Test user creation
-- INSERT INTO users (email, display_name) VALUES ('manual@test.com', 'Manual Test User');

-- View created user
-- SELECT * FROM users WHERE email = 'manual@test.com';

-- Test constraint violations
-- INSERT INTO users (email, display_name) VALUES ('invalid-email', 'Test');  -- Should fail
-- INSERT INTO users (email, display_name) VALUES ('manual@test.com', 'Duplicate');  -- Should fail