-- Property Tests: Migration Management System
-- Description: Test migration management properties and validation
-- Requirements: 16.3, 16.4, 16.5

BEGIN;

-- Test setup
SELECT plan(6);

-- Property 51: Migrations execute in order
-- **Validates: Requirements 16.3**
-- Clear existing migration history for clean test
DELETE FROM migration_history;

-- Test that migration order validation works correctly
SELECT ok(
    validate_migration_order('00001') = TRUE,
    'Property 51: First migration (00001) is valid when no migrations exist'
);

-- Test that out-of-order migrations are rejected
DO $$
BEGIN
    -- Record a migration to test order validation
    PERFORM record_migration('00001_test.sql', '00001', 'Test migration', 100, 'checksum1', TRUE, NULL);
END;
$$;

SELECT ok(
    validate_migration_order('00002') = TRUE,
    'Property 51: Sequential migration (00002) is valid after 00001'
);

SELECT ok(
    validate_migration_order('00004') = FALSE,
    'Property 51: Non-sequential migration (00004) is invalid after 00001'
);

-- Property 52: Failed migrations rollback
-- **Validates: Requirements 16.4**
-- Test that failed migrations are properly recorded
DO $$
BEGIN
    -- Record a failed migration
    PERFORM record_migration('00002_failed.sql', '00002', 'Failed migration', 50, 'checksum2', FALSE, 'Test error');
END;
$$;

SELECT ok(
    NOT is_migration_applied('00002_failed.sql'),
    'Property 52: Failed migrations are not considered applied'
);

-- Property 53: Schema integrity is verified
-- **Validates: Requirements 16.5**
-- Test that schema verification detects issues
SELECT ok(
    EXISTS (
        SELECT 1 FROM verify_schema_integrity() 
        WHERE check_name = 'required_tables'
    ),
    'Property 53: Schema verification checks required tables'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM verify_schema_integrity() 
        WHERE check_name = 'rls_enabled'
    ),
    'Property 53: Schema verification checks RLS status'
);

-- Cleanup test data
DELETE FROM migration_history WHERE migration_name LIKE '%test%' OR migration_name LIKE '%failed%';

SELECT * FROM finish();

ROLLBACK;