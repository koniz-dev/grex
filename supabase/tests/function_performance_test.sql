-- Performance Tests: Database Function Performance
-- Description: Test performance of database functions with large datasets
-- Requirements: 10.1, 10.3

BEGIN;

-- Test setup
SELECT plan(6);

-- Create performance test data for function testing
DO $$
DECLARE
    i INTEGER;
    j INTEGER;
    test_user_ids UUID[];
    test_group_id UUID;
    test_expense_ids UUID[];
    current_user_id UUID;
    current_expense_id UUID;
BEGIN
    -- Create 50 test users
    FOR i IN 1..50 LOOP
        INSERT INTO users (email, display_name, preferred_currency, preferred_language)
        VALUES ('func_perf_user_' || i || '@example.com', 'Function Perf User ' || i, 'USD', 'en')
        RETURNING id INTO current_user_id;
        
        test_user_ids := array_append(test_user_ids, current_user_id);
    END LOOP;
    
    -- Create one large group with all users
    INSERT INTO groups (name, description, creator_id, primary_currency)
    VALUES ('Large Function Test Group', 'Group for function performance testing', test_user_ids[1], 'USD')
    RETURNING id INTO test_group_id;
    
    -- Add all users to the group
    FOR i IN 1..50 LOOP
        INSERT INTO group_members (group_id, user_id, role)
        VALUES (test_group_id, test_user_ids[i], 
            CASE 
                WHEN i <= 5 THEN 'administrator'::member_role
                WHEN i <= 25 THEN 'editor'::member_role
                ELSE 'viewer'::member_role
            END
        );
    END LOOP;
    
    -- Create 500 expenses with complex splits
    FOR i IN 1..500 LOOP
        INSERT INTO expenses (group_id, payer_id, description, amount, currency, expense_date, split_method)
        VALUES (
            test_group_id, 
            test_user_ids[(i % 50) + 1], 
            'Function Performance Test Expense ' || i,
            (i * 12.75 + 50)::DECIMAL(12,2),
            'USD',
            CURRENT_DATE - (i || ' days')::INTERVAL,
            CASE (i % 4)
                WHEN 0 THEN 'equal'::split_method
                WHEN 1 THEN 'percentage'::split_method
                WHEN 2 THEN 'exact'::split_method
                ELSE 'shares'::split_method
            END
        )
        RETURNING id INTO current_expense_id;
        
        test_expense_ids := array_append(test_expense_ids, current_expense_id);
        
        -- Add 10 participants per expense for complex calculations
        FOR j IN 1..10 LOOP
            INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
            VALUES (
                current_expense_id,
                test_user_ids[j],
                ((i * 12.75 + 50) / 10)::DECIMAL(12,2),
                10.0
            );
        END LOOP;
    END LOOP;
    
    -- Create 1000 payments for complex balance calculations
    FOR i IN 1..1000 LOOP
        INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date)
        VALUES (
            test_group_id,
            test_user_ids[(i % 50) + 1],
            test_user_ids[((i + 25) % 50) + 1],
            (i * 3.25)::DECIMAL(12,2),
            'USD',
            CURRENT_DATE - (i || ' hours')::INTERVAL
        );
    END LOOP;
    
    -- Store test data info
    PERFORM set_config('test.func_group_id', test_group_id::text, true);
    PERFORM set_config('test.func_expense_count', array_length(test_expense_ids, 1)::text, true);
    PERFORM set_config('test.func_first_expense_id', test_expense_ids[1]::text, true);
END;
$$;

-- Test 1: Balance calculation function performance with large group
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    balance_count INTEGER;
    total_balance DECIMAL(12,2);
BEGIN
    start_time := clock_timestamp();
    
    SELECT COUNT(*), SUM(ABS(balance)) INTO balance_count, total_balance
    FROM calculate_group_balances(current_setting('test.func_group_id')::UUID);
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.balance_func_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.balance_func_count', balance_count::text, true);
    PERFORM set_config('test.total_balance', total_balance::text, true);
END;
$$;

SELECT ok(
    current_setting('test.balance_func_count')::INTEGER = 50,
    'Balance calculation function returns all 50 group members'
);

-- Test 2: Balance calculation performance benchmark
SELECT ok(
    current_setting('test.balance_func_time')::NUMERIC < 2000, -- 2 seconds max
    'Balance calculation completes within 2 seconds for large group'
);

-- Test 3: Expense split validation function performance
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    valid_count INTEGER := 0;
    total_tested INTEGER := 0;
    expense_record RECORD;
BEGIN
    start_time := clock_timestamp();
    
    -- Test validation on first 100 expenses
    FOR expense_record IN 
        SELECT id FROM expenses 
        WHERE description LIKE 'Function Performance Test Expense%'
        ORDER BY id
        LIMIT 100
    LOOP
        total_tested := total_tested + 1;
        IF validate_expense_split(expense_record.id) THEN
            valid_count := valid_count + 1;
        END IF;
    END LOOP;
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.validation_func_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.validation_valid_count', valid_count::text, true);
    PERFORM set_config('test.validation_total_tested', total_tested::text, true);
END;
$$;

SELECT ok(
    current_setting('test.validation_total_tested')::INTEGER = 100,
    'Split validation function processes all test expenses'
);

-- Test 4: Split validation performance benchmark
SELECT ok(
    current_setting('test.validation_func_time')::NUMERIC < 5000, -- 5 seconds max for 100 validations
    'Split validation completes within 5 seconds for 100 expenses'
);

-- Test 5: Settlement plan generation performance
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    settlement_count INTEGER;
    total_settlement_amount DECIMAL(12,2);
BEGIN
    start_time := clock_timestamp();
    
    SELECT COUNT(*), SUM(amount) INTO settlement_count, total_settlement_amount
    FROM generate_settlement_plan(current_setting('test.func_group_id')::UUID);
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.settlement_func_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.settlement_count', settlement_count::text, true);
    PERFORM set_config('test.settlement_amount', COALESCE(total_settlement_amount, 0)::text, true);
END;
$$;

SELECT ok(
    current_setting('test.settlement_func_time')::NUMERIC < 3000, -- 3 seconds max
    'Settlement plan generation completes within 3 seconds'
);

-- Test 6: Function performance summary
SELECT ok(
    current_setting('test.balance_func_time')::NUMERIC < 2000 AND
    current_setting('test.validation_func_time')::NUMERIC < 5000 AND
    current_setting('test.settlement_func_time')::NUMERIC < 3000,
    'All database functions meet performance benchmarks'
);

-- Performance Summary (for manual review)
DO $$
BEGIN
    RAISE NOTICE 'Function Performance Test Results:';
    RAISE NOTICE '- Balance calculation (50 users, 500 expenses, 1000 payments): % ms', 
        current_setting('test.balance_func_time');
    RAISE NOTICE '- Split validation (100 expenses): % ms', 
        current_setting('test.validation_func_time');
    RAISE NOTICE '- Settlement plan generation: % ms', 
        current_setting('test.settlement_func_time');
    RAISE NOTICE 'Data processed:';
    RAISE NOTICE '  - % expenses validated', current_setting('test.validation_total_tested');
    RAISE NOTICE '  - % settlement transactions generated', current_setting('test.settlement_count');
    RAISE NOTICE '  - Total settlement amount: $%', current_setting('test.settlement_amount');
END;
$$;

-- Cleanup function performance test data
DELETE FROM expense_participants WHERE expense_id IN (
    SELECT id FROM expenses WHERE description LIKE 'Function Performance Test Expense%'
);
DELETE FROM payments WHERE group_id = current_setting('test.func_group_id')::UUID;
DELETE FROM expenses WHERE description LIKE 'Function Performance Test Expense%';
DELETE FROM group_members WHERE group_id = current_setting('test.func_group_id')::UUID;
DELETE FROM groups WHERE name = 'Large Function Test Group';
DELETE FROM users WHERE email LIKE 'func_perf_user_%@example.com';

SELECT * FROM finish();

ROLLBACK;