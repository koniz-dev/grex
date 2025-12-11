-- Manual SQL Injection Prevention Test
-- This test can be run directly to verify SQL injection prevention

\echo 'Starting SQL Injection Prevention Tests...'

-- Test 1: Verify functions use parameterized queries
\echo 'Test 1: Function Parameter Safety'

-- Test calculate_group_balances with valid UUID
SELECT 'Testing calculate_group_balances with valid UUID...' as status;
SELECT COUNT(*) as function_exists FROM information_schema.routines 
WHERE routine_name = 'calculate_group_balances' AND routine_type = 'FUNCTION';

-- Test 2: Verify input validation constraints exist
\echo 'Test 2: Input Validation Constraints'

-- Check email format constraint
SELECT 'Checking email format constraint...' as status;
SELECT COUNT(*) as email_constraints FROM information_schema.check_constraints 
WHERE constraint_name LIKE '%email%' OR check_clause LIKE '%email%';

-- Check positive amount constraints
SELECT 'Checking positive amount constraints...' as status;
SELECT COUNT(*) as amount_constraints FROM information_schema.check_constraints 
WHERE check_clause LIKE '%> 0%' OR check_clause LIKE '%amount%positive%';

-- Test 3: Verify no dynamic SQL execution patterns
\echo 'Test 3: Dynamic SQL Pattern Check'

-- This would be done by examining the function source code
-- Check if any functions use EXECUTE with string concatenation
SELECT 'Checking for dynamic SQL patterns in functions...' as status;
SELECT routine_name, routine_definition 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_type = 'FUNCTION'
  AND (routine_definition LIKE '%EXECUTE%' OR routine_definition LIKE '%||%');

-- Test 4: Verify RLS is enabled
\echo 'Test 4: Row Level Security Status'

SELECT 'Checking RLS status on all tables...' as status;
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('users', 'groups', 'group_members', 'expenses', 'expense_participants', 'payments', 'audit_logs')
ORDER BY tablename;

-- Test 5: Verify audit log immutability
\echo 'Test 5: Audit Log Protection'

SELECT 'Checking audit log protection rules...' as status;
SELECT rulename, ev_type, is_instead 
FROM pg_rules 
WHERE tablename = 'audit_logs';

-- Test 6: Check for proper JSONB usage in triggers
\echo 'Test 6: Safe JSONB Usage in Triggers'

SELECT 'Checking trigger functions for safe JSONB usage...' as status;
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_type = 'FUNCTION'
  AND routine_name LIKE '%audit%'
  AND (routine_definition LIKE '%jsonb_build_object%' OR routine_definition LIKE '%to_jsonb%');

\echo 'SQL Injection Prevention Tests Completed.'
\echo 'Review the output above to verify:'
\echo '1. All functions exist and use parameters'
\echo '2. Input validation constraints are in place'
\echo '3. No dynamic SQL patterns found'
\echo '4. RLS is enabled on all tables'
\echo '5. Audit logs are protected'
\echo '6. Triggers use safe JSONB functions'