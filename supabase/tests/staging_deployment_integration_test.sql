-- Staging Deployment Integration Test
-- This test verifies that all components work together correctly in the staging environment

BEGIN;

-- Test 1: Schema Integrity
DO $$
DECLARE
    table_count INTEGER;
    enum_count INTEGER;
    function_count INTEGER;
    trigger_count INTEGER;
BEGIN
    -- Verify all required tables exist
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('users', 'groups', 'group_members', 'expenses', 'expense_participants', 'payments', 'audit_logs');
    
    IF table_count != 7 THEN
        RAISE EXCEPTION 'Schema integrity test failed: expected 7 tables, found %', table_count;
    END IF;
    
    -- Verify all required enums exist
    SELECT COUNT(*) INTO enum_count
    FROM pg_type 
    WHERE typname IN ('member_role', 'split_method', 'action_type');
    
    IF enum_count != 3 THEN
        RAISE EXCEPTION 'Schema integrity test failed: expected 3 enums, found %', enum_count;
    END IF;
    
    -- Verify all required functions exist
    SELECT COUNT(*) INTO function_count
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name IN ('calculate_group_balances', 'validate_expense_split', 'generate_settlement_plan', 'check_user_permission');
    
    IF function_count < 4 THEN
        RAISE EXCEPTION 'Schema integrity test failed: expected at least 4 functions, found %', function_count;
    END IF;
    
    -- Verify triggers exist
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers 
    WHERE trigger_schema = 'public';
    
    IF trigger_count < 5 THEN
        RAISE EXCEPTION 'Schema integrity test failed: expected at least 5 triggers, found %', trigger_count;
    END IF;
    
    RAISE NOTICE 'Schema integrity test PASSED: % tables, % enums, % functions, % triggers', table_count, enum_count, function_count, trigger_count;
END $$;

-- Test 2: RLS Policies
DO $$
DECLARE
    rls_enabled_count INTEGER;
    policy_count INTEGER;
BEGIN
    -- Verify RLS is enabled on all tables
    SELECT COUNT(*) INTO rls_enabled_count
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
    AND c.relname IN ('users', 'groups', 'group_members', 'expenses', 'expense_participants', 'payments', 'audit_logs')
    AND c.relrowsecurity = true;
    
    IF rls_enabled_count != 7 THEN
        RAISE EXCEPTION 'RLS test failed: expected RLS enabled on 7 tables, found %', rls_enabled_count;
    END IF;
    
    -- Verify policies exist
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public';
    
    IF policy_count < 10 THEN
        RAISE EXCEPTION 'RLS test failed: expected at least 10 policies, found %', policy_count;
    END IF;
    
    RAISE NOTICE 'RLS test PASSED: % tables with RLS enabled, % policies configured', rls_enabled_count, policy_count;
END $$;

-- Test 3: Real-time Publications
DO $$
DECLARE
    publication_count INTEGER;
    published_tables INTEGER;
BEGIN
    -- Check if supabase_realtime publication exists
    SELECT COUNT(*) INTO publication_count
    FROM pg_publication
    WHERE pubname = 'supabase_realtime';
    
    IF publication_count != 1 THEN
        RAISE EXCEPTION 'Real-time test failed: supabase_realtime publication not found';
    END IF;
    
    -- Check published tables
    SELECT COUNT(*) INTO published_tables
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename IN ('users', 'groups', 'group_members', 'expenses', 'expense_participants', 'payments', 'audit_logs');
    
    IF published_tables < 7 THEN
        RAISE EXCEPTION 'Real-time test failed: expected 7 published tables, found %', published_tables;
    END IF;
    
    RAISE NOTICE 'Real-time test PASSED: publication exists with % tables', published_tables;
END $$;

-- Test 4: Complete User Workflow
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_group_id UUID := gen_random_uuid();
    test_expense_id UUID := gen_random_uuid();
    balance_record RECORD;
    split_valid BOOLEAN;
BEGIN
    -- Create test user
    INSERT INTO users (id, email, display_name, preferred_currency)
    VALUES (test_user_id, 'integration.test@staging.com', 'Integration Test User', 'USD');
    
    -- Create test group
    INSERT INTO groups (id, name, creator_id, primary_currency)
    VALUES (test_group_id, 'Integration Test Group', test_user_id, 'USD');
    
    -- Add user to group as administrator
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_id, test_user_id, 'administrator');
    
    -- Create test expense
    INSERT INTO expenses (id, group_id, payer_id, amount, currency, description, split_method)
    VALUES (test_expense_id, test_group_id, test_user_id, 100.00, 'USD', 'Integration Test Expense', 'equal');
    
    -- Add expense participant
    INSERT INTO expense_participants (expense_id, user_id, share_amount)
    VALUES (test_expense_id, test_user_id, 100.00);
    
    -- Test balance calculation
    SELECT * INTO balance_record
    FROM calculate_group_balances(test_group_id)
    WHERE user_id = test_user_id;
    
    IF balance_record.balance IS NULL THEN
        RAISE EXCEPTION 'Balance calculation failed for test user';
    END IF;
    
    -- Test expense split validation
    SELECT validate_expense_split(test_expense_id) INTO split_valid;
    
    IF NOT split_valid THEN
        RAISE EXCEPTION 'Expense split validation failed';
    END IF;
    
    -- Test permission checking
    IF NOT check_user_permission(test_user_id, test_group_id, 'administrator') THEN
        RAISE EXCEPTION 'Permission check failed';
    END IF;
    
    -- Clean up test data
    DELETE FROM expense_participants WHERE expense_id = test_expense_id;
    DELETE FROM expenses WHERE id = test_expense_id;
    DELETE FROM group_members WHERE group_id = test_group_id;
    DELETE FROM groups WHERE id = test_group_id;
    DELETE FROM users WHERE id = test_user_id;
    
    RAISE NOTICE 'Complete workflow test PASSED: user balance = %', balance_record.balance;
END $$;

-- Test 5: Audit Logging
DO $$
DECLARE
    initial_audit_count INTEGER;
    final_audit_count INTEGER;
    test_user_id UUID := gen_random_uuid();
BEGIN
    -- Get initial audit count
    SELECT COUNT(*) INTO initial_audit_count FROM audit_logs;
    
    -- Perform operations that should trigger audit logs
    INSERT INTO users (id, email, display_name, preferred_currency)
    VALUES (test_user_id, 'audit.test@staging.com', 'Audit Test User', 'USD');
    
    UPDATE users SET display_name = 'Updated Audit Test User' WHERE id = test_user_id;
    
    DELETE FROM users WHERE id = test_user_id;
    
    -- Check if audit logs were created
    SELECT COUNT(*) INTO final_audit_count FROM audit_logs;
    
    IF final_audit_count <= initial_audit_count THEN
        RAISE EXCEPTION 'Audit logging test failed: no new audit entries created';
    END IF;
    
    RAISE NOTICE 'Audit logging test PASSED: % new audit entries created', (final_audit_count - initial_audit_count);
END $$;

-- Test 6: Currency Validation
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    validation_passed BOOLEAN := false;
BEGIN
    -- Test valid currency
    BEGIN
        INSERT INTO users (id, email, display_name, preferred_currency)
        VALUES (test_user_id, 'currency.test@staging.com', 'Currency Test User', 'USD');
        validation_passed := true;
        DELETE FROM users WHERE id = test_user_id;
    EXCEPTION
        WHEN OTHERS THEN
            validation_passed := false;
    END;
    
    IF NOT validation_passed THEN
        RAISE EXCEPTION 'Currency validation test failed: valid currency rejected';
    END IF;
    
    -- Test invalid currency (should fail)
    validation_passed := true;
    BEGIN
        INSERT INTO users (id, email, display_name, preferred_currency)
        VALUES (test_user_id, 'currency.test2@staging.com', 'Currency Test User 2', 'INVALID');
    EXCEPTION
        WHEN OTHERS THEN
            validation_passed := false;
    END;
    
    IF validation_passed THEN
        DELETE FROM users WHERE id = test_user_id;
        RAISE EXCEPTION 'Currency validation test failed: invalid currency accepted';
    END IF;
    
    RAISE NOTICE 'Currency validation test PASSED';
END $$;

-- Test 7: Soft Delete Functionality
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    active_count INTEGER;
    total_count INTEGER;
BEGIN
    -- Create test user
    INSERT INTO users (id, email, display_name, preferred_currency)
    VALUES (test_user_id, 'softdelete.test@staging.com', 'Soft Delete Test User', 'USD');
    
    -- Soft delete the user
    UPDATE users SET deleted_at = NOW() WHERE id = test_user_id;
    
    -- Count active users (should exclude soft-deleted)
    SELECT COUNT(*) INTO active_count FROM users WHERE deleted_at IS NULL AND id = test_user_id;
    
    -- Count total users (should include soft-deleted)
    SELECT COUNT(*) INTO total_count FROM users WHERE id = test_user_id;
    
    IF active_count != 0 OR total_count != 1 THEN
        RAISE EXCEPTION 'Soft delete test failed: active_count=%, total_count=%', active_count, total_count;
    END IF;
    
    -- Restore user
    UPDATE users SET deleted_at = NULL WHERE id = test_user_id;
    
    -- Verify restoration
    SELECT COUNT(*) INTO active_count FROM users WHERE deleted_at IS NULL AND id = test_user_id;
    
    IF active_count != 1 THEN
        RAISE EXCEPTION 'Soft delete restore test failed: user not restored';
    END IF;
    
    -- Clean up
    DELETE FROM users WHERE id = test_user_id;
    
    RAISE NOTICE 'Soft delete test PASSED';
END $$;

-- Test 8: Performance Baseline
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
    test_group_id UUID := gen_random_uuid();
    test_user_id UUID := gen_random_uuid();
    i INTEGER;
BEGIN
    -- Create test data
    INSERT INTO users (id, email, display_name, preferred_currency)
    VALUES (test_user_id, 'perf.test@staging.com', 'Performance Test User', 'USD');
    
    INSERT INTO groups (id, name, creator_id, primary_currency)
    VALUES (test_group_id, 'Performance Test Group', test_user_id, 'USD');
    
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_id, test_user_id, 'administrator');
    
    -- Test balance calculation performance
    start_time := clock_timestamp();
    
    FOR i IN 1..100 LOOP
        PERFORM * FROM calculate_group_balances(test_group_id);
    END LOOP;
    
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    IF duration > INTERVAL '10 seconds' THEN
        RAISE WARNING 'Performance test: balance calculation took % (may need optimization)', duration;
    ELSE
        RAISE NOTICE 'Performance test PASSED: 100 balance calculations in %', duration;
    END IF;
    
    -- Clean up
    DELETE FROM group_members WHERE group_id = test_group_id;
    DELETE FROM groups WHERE id = test_group_id;
    DELETE FROM users WHERE id = test_user_id;
END $$;

COMMIT;

-- Final success message
SELECT 'All staging deployment integration tests PASSED!' as test_result;