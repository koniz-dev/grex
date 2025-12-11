-- Unit Tests: Migration Management System
-- Description: Comprehensive unit tests for migration management functions
-- Requirements: 16.3, 16.4, 16.5

BEGIN;

-- Test setup
SELECT plan(15);

-- Clear existing migration history for clean testing
DELETE FROM migration_history;

-- Test 1: Migration recording
SELECT ok(
    record_migration('test_migration.sql', '99999', 'Test migration', 100, 'abc123', TRUE, NULL),
    'Migration recording succeeds with valid data'
);

-- Test 2: Migration applied check
SELECT ok(
    is_migration_applied('test_migration.sql'),
    'Migration is marked as applied after recording'
);

-- Test 3: Migration status retrieval
SELECT ok(
    EXISTS (
        SELECT 1 FROM get_migration_status() 
        WHERE migration_name = 'test_migration.sql'
    ),
    'Migration appears in status list'
);

-- Test 4: Failed migration recording
SELECT ok(
    record_migration('failed_migration.sql', '99998', 'Failed test', 50, 'def456', FALSE, 'Test error'),
    'Failed migration recording succeeds'
);

SELECT ok(
    NOT is_migration_applied('failed_migration.sql'),
    'Failed migration is not marked as applied'
);

-- Test 5: Migration order validation - valid sequence
-- Ensure clean state
DELETE FROM migration_history;

SELECT ok(
    validate_migration_order('00001'),
    'First migration (00001) validates correctly'
);

-- Add first migration
SELECT record_migration('00001_first.sql', '00001', 'First migration', 100, 'hash1', TRUE, NULL);

SELECT ok(
    validate_migration_order('00002'),
    'Second migration (00002) validates correctly after first'
);

-- Test 6: Migration order validation - invalid sequence
SELECT ok(
    NOT validate_migration_order('00005'),
    'Non-sequential migration (00005) is rejected'
);

-- Test 7: Schema integrity verification
SELECT ok(
    EXISTS (
        SELECT 1 FROM verify_schema_integrity() 
        WHERE check_name = 'required_tables' AND status IN ('PASS', 'FAIL')
    ),
    'Schema verification returns table check results'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM verify_schema_integrity() 
        WHERE check_name = 'required_functions' AND status IN ('PASS', 'FAIL')
    ),
    'Schema verification returns function check results'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM verify_schema_integrity() 
        WHERE check_name = 'rls_enabled' AND status IN ('PASS', 'FAIL')
    ),
    'Schema verification returns RLS check results'
);

-- Test 8: Migration history constraints
-- Test empty migration name constraint
DO $$
BEGIN
    BEGIN
        INSERT INTO migration_history (migration_name, version, success)
        VALUES ('', '00001', TRUE);
        -- If we get here, the constraint didn't work
        PERFORM FALSE;
    EXCEPTION
        WHEN check_violation THEN
            -- This is expected
            NULL;
    END;
END;
$$;

SELECT ok(
    NOT EXISTS (
        SELECT 1 FROM migration_history 
        WHERE migration_name = ''
    ),
    'Empty migration name is rejected'
);

-- Test empty version constraint
DO $$
BEGIN
    BEGIN
        INSERT INTO migration_history (migration_name, version, success)
        VALUES ('00001_valid_name.sql', '', TRUE);
        -- If we get here, the constraint didn't work
        PERFORM FALSE;
    EXCEPTION
        WHEN check_violation THEN
            -- This is expected
            NULL;
    END;
END;
$$;

SELECT ok(
    NOT EXISTS (
        SELECT 1 FROM migration_history 
        WHERE version = ''
    ),
    'Empty version is rejected'
);

-- Test 9: Rollback functionality
-- Add a migration to rollback
SELECT record_migration('00002_to_rollback.sql', '00002', 'Migration to rollback', 150, 'hash2', TRUE, NULL);

SELECT ok(
    rollback_last_migration() LIKE '%00002_to_rollback.sql%',
    'Rollback returns correct migration name'
);

SELECT ok(
    NOT is_migration_applied('00002_to_rollback.sql'),
    'Rolled back migration is no longer marked as applied'
);

-- Cleanup test data
DELETE FROM migration_history WHERE migration_name LIKE '%test%' OR migration_name LIKE '%rollback%' OR version LIKE '999%' OR version IN ('00001', '00002');

SELECT * FROM finish();

ROLLBACK;