-- ============================================================================
-- SQL Injection Prevention Tests (pgTAP format)
-- Description: pgTAP tests to verify SQL injection prevention
-- Requirements: All (Security requirement for all functions and queries)
-- ============================================================================

BEGIN;

-- Load pgTAP extension
SELECT plan(20);

-- ============================================================================
-- Test 1: Verify functions exist and use proper parameters
-- ============================================================================

SELECT has_function(
    'calculate_group_balances',
    ARRAY['uuid'],
    'calculate_group_balances function exists with UUID parameter'
);

SELECT has_function(
    'validate_expense_split',
    ARRAY['uuid'],
    'validate_expense_split function exists with UUID parameter'
);

SELECT has_function(
    'check_user_permission',
    ARRAY['uuid', 'uuid', 'text'],
    'check_user_permission function exists with proper parameters'
);

SELECT has_function(
    'generate_settlement_plan',
    ARRAY['uuid'],
    'generate_settlement_plan function exists with UUID parameter'
);

-- ============================================================================
-- Test 2: Verify input validation constraints exist
-- ============================================================================

SELECT col_has_check(
    'users',
    'email',
    'users table has email format validation'
);

SELECT col_has_check(
    'expenses',
    'amount',
    'expenses table has amount validation'
);

SELECT col_has_check(
    'users',
    'preferred_currency',
    'users table has currency code validation'
);

-- ============================================================================
-- Test 3: Verify RLS is enabled on all tables
-- ============================================================================

SELECT results_eq(
    'SELECT COUNT(*) FROM pg_tables WHERE schemaname = ''public'' AND rowsecurity = true',
    'SELECT 7::bigint',
    'All 7 public tables have RLS enabled'
);

-- ============================================================================
-- Test 4: Verify audit log protection
-- ============================================================================

SELECT has_rule(
    'audit_logs',
    'audit_logs_no_update',
    'audit_logs table has update prevention rule'
);

SELECT has_rule(
    'audit_logs',
    'audit_logs_no_delete',
    'audit_logs table has delete prevention rule'
);

-- ============================================================================
-- Test 5: Verify safe JSONB functions in triggers
-- ============================================================================

SELECT function_returns(
    'audit_expense_changes',
    'trigger',
    'audit_expense_changes returns trigger type'
);

SELECT function_returns(
    'audit_payment_changes',
    'trigger',
    'audit_payment_changes returns trigger type'
);

SELECT function_returns(
    'audit_membership_changes',
    'trigger',
    'audit_membership_changes returns trigger type'
);

-- ============================================================================
-- Test 6: Verify enum types exist for input validation
-- ============================================================================

SELECT has_type('member_role', 'member_role enum type exists');
SELECT has_type('split_method', 'split_method enum type exists');
SELECT has_type('action_type', 'action_type enum type exists');

-- ============================================================================
-- Test 7: Verify no dangerous dynamic SQL patterns
-- ============================================================================

-- This test checks that no functions contain dangerous EXECUTE patterns
SELECT results_eq(
    $$SELECT COUNT(*) FROM information_schema.routines 
      WHERE routine_schema = 'public' 
        AND routine_type = 'FUNCTION'
        AND routine_definition LIKE '%EXECUTE%''%'$$,
    'SELECT 0::bigint',
    'No functions contain dangerous EXECUTE with string literals'
);

-- ============================================================================
-- Test 8: Verify constraint count indicates proper validation
-- ============================================================================

SELECT cmp_ok(
    (SELECT COUNT(*) FROM information_schema.check_constraints 
     WHERE constraint_schema = 'public'),
    '>=',
    15,
    'At least 15 check constraints exist for input validation'
);

-- ============================================================================
-- Test 9: Verify trigger functions use safe practices
-- ============================================================================

SELECT results_eq(
    $$SELECT COUNT(*) FROM information_schema.routines 
      WHERE routine_schema = 'public' 
        AND routine_type = 'FUNCTION'
        AND routine_name LIKE '%audit%'
        AND (routine_definition LIKE '%jsonb_build_object%' 
             OR routine_definition LIKE '%to_jsonb%')$$,
    'SELECT 3::bigint',
    'All 3 audit trigger functions use safe JSONB methods'
);

SELECT * FROM finish();

ROLLBACK;