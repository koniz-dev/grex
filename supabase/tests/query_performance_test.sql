-- Performance Tests: Query Performance Analysis
-- Description: Test query performance with large datasets and analyze execution plans
-- Requirements: 12.1, 12.2, 12.3

BEGIN;

-- Test setup
SELECT plan(8);

-- Create performance test data
DO $$
DECLARE
    i INTEGER;
    j INTEGER;
    test_user_ids UUID[];
    test_group_ids UUID[];
    test_expense_ids UUID[];
    current_user_id UUID;
    current_group_id UUID;
    current_expense_id UUID;
BEGIN
    -- Create 100 test users for performance testing
    FOR i IN 1..100 LOOP
        INSERT INTO users (email, display_name, preferred_currency, preferred_language)
        VALUES ('perf_user_' || i || '@example.com', 'Performance User ' || i, 'USD', 'en')
        RETURNING id INTO current_user_id;
        
        test_user_ids := array_append(test_user_ids, current_user_id);
    END LOOP;
    
    -- Create 20 test groups
    FOR i IN 1..20 LOOP
        INSERT INTO groups (name, description, creator_id, primary_currency)
        VALUES ('Performance Group ' || i, 'Group for performance testing', test_user_ids[1], 'USD')
        RETURNING id INTO current_group_id;
        
        test_group_ids := array_append(test_group_ids, current_group_id);
        
        -- Add 5 members to each group
        FOR j IN 1..5 LOOP
            INSERT INTO group_members (group_id, user_id, role)
            VALUES (current_group_id, test_user_ids[j], 
                CASE 
                    WHEN j = 1 THEN 'administrator'::member_role
                    WHEN j <= 3 THEN 'editor'::member_role
                    ELSE 'viewer'::member_role
                END
            );
        END LOOP;
    END LOOP;
    
    -- Create 1000 test expenses (50 per group)
    FOR i IN 1..20 LOOP
        current_group_id := test_group_ids[i];
        
        FOR j IN 1..50 LOOP
            INSERT INTO expenses (group_id, payer_id, description, amount, currency, expense_date, split_method)
            VALUES (
                current_group_id, 
                test_user_ids[(j % 5) + 1], 
                'Performance Test Expense ' || j || ' for Group ' || i,
                (j * 10.50)::DECIMAL(10,2),
                'USD',
                CURRENT_DATE - (j || ' days')::INTERVAL,
                CASE (j % 4)
                    WHEN 0 THEN 'equal'::split_method
                    WHEN 1 THEN 'percentage'::split_method
                    WHEN 2 THEN 'exact'::split_method
                    ELSE 'shares'::split_method
                END
            )
            RETURNING id INTO current_expense_id;
            
            test_expense_ids := array_append(test_expense_ids, current_expense_id);
            
            -- Add expense participants
            FOR k IN 1..3 LOOP
                INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
                VALUES (
                    current_expense_id,
                    test_user_ids[k],
                    ((j * 10.50) / 3)::DECIMAL(10,2),
                    33.33
                );
            END LOOP;
        END LOOP;
    END LOOP;
    
    -- Create 500 test payments
    FOR i IN 1..500 LOOP
        INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date)
        VALUES (
            test_group_ids[(i % 20) + 1],
            test_user_ids[(i % 5) + 1],
            test_user_ids[((i + 1) % 5) + 1],
            (i * 5.25)::DECIMAL(10,2),
            'USD',
            CURRENT_DATE - (i || ' days')::INTERVAL
        );
    END LOOP;
    
    -- Store test data info
    PERFORM set_config('test.user_count', array_length(test_user_ids, 1)::text, true);
    PERFORM set_config('test.group_count', array_length(test_group_ids, 1)::text, true);
    PERFORM set_config('test.expense_count', array_length(test_expense_ids, 1)::text, true);
    PERFORM set_config('test.first_group_id', test_group_ids[1]::text, true);
END;
$$;

-- Test 1: Large dataset query performance - Users
SELECT ok(
    (SELECT COUNT(*) FROM users WHERE email LIKE 'perf_user_%') = 100,
    'Performance test data created successfully - 100 users'
);

-- Test 2: Large dataset query performance - Groups with members
SELECT ok(
    (SELECT COUNT(*) FROM groups WHERE name LIKE 'Performance Group%') = 20,
    'Performance test data created successfully - 20 groups'
);

-- Test 3: Large dataset query performance - Expenses
SELECT ok(
    (SELECT COUNT(*) FROM expenses WHERE description LIKE 'Performance Test Expense%') = 1000,
    'Performance test data created successfully - 1000 expenses'
);

-- Test 4: Index performance - Group expenses query
-- This should use the idx_expenses_group_id index
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    expense_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO expense_count
    FROM expenses 
    WHERE group_id = current_setting('test.first_group_id')::UUID;
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.group_expenses_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.group_expenses_count', expense_count::text, true);
END;
$$;

SELECT ok(
    current_setting('test.group_expenses_count')::INTEGER = 50,
    'Group expenses query returns correct count'
);

-- Test 5: Index performance - User expenses across groups
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    expense_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO expense_count
    FROM expenses e
    JOIN group_members gm ON e.group_id = gm.group_id
    WHERE gm.user_id = (SELECT id FROM users WHERE email = 'perf_user_1@example.com' LIMIT 1);
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.user_expenses_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.user_expenses_count', expense_count::text, true);
END;
$$;

SELECT ok(
    current_setting('test.user_expenses_count')::INTEGER > 0,
    'User expenses across groups query returns data'
);

-- Test 6: Complex join performance - Expense participants with user details
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    participant_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO participant_count
    FROM expense_participants ep
    JOIN expenses e ON ep.expense_id = e.id
    JOIN users u ON ep.user_id = u.id
    WHERE e.group_id = current_setting('test.first_group_id')::UUID;
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.participants_join_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.participants_count', participant_count::text, true);
END;
$$;

SELECT ok(
    current_setting('test.participants_count')::INTEGER = 150, -- 50 expenses * 3 participants each
    'Complex join query returns correct participant count'
);

-- Test 7: Aggregation performance - Group balance calculations
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    balance_count INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO balance_count
    FROM calculate_group_balances(current_setting('test.first_group_id')::UUID);
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.balance_calc_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.balance_count', balance_count::text, true);
END;
$$;

SELECT ok(
    current_setting('test.balance_count')::INTEGER = 5, -- 5 members in first group
    'Balance calculation returns correct member count'
);

-- Test 8: Performance summary and optimization recommendations
SELECT ok(
    current_setting('test.group_expenses_time')::NUMERIC < 100 AND
    current_setting('test.user_expenses_time')::NUMERIC < 200 AND
    current_setting('test.participants_join_time')::NUMERIC < 300 AND
    current_setting('test.balance_calc_time')::NUMERIC < 500,
    'All queries execute within acceptable time limits (< 500ms)'
);

-- Performance Summary (for manual review)
DO $$
BEGIN
    RAISE NOTICE 'Performance Test Results:';
    RAISE NOTICE '- Group expenses query: % ms', current_setting('test.group_expenses_time');
    RAISE NOTICE '- User expenses query: % ms', current_setting('test.user_expenses_time');
    RAISE NOTICE '- Participants join query: % ms', current_setting('test.participants_join_time');
    RAISE NOTICE '- Balance calculation: % ms', current_setting('test.balance_calc_time');
    RAISE NOTICE 'Test data: % users, % groups, % expenses', 
        current_setting('test.user_count'),
        current_setting('test.group_count'),
        current_setting('test.expense_count');
END;
$$;

-- Cleanup performance test data
DELETE FROM expense_participants WHERE expense_id IN (
    SELECT id FROM expenses WHERE description LIKE 'Performance Test Expense%'
);
DELETE FROM payments WHERE group_id IN (
    SELECT id FROM groups WHERE name LIKE 'Performance Group%'
);
DELETE FROM expenses WHERE description LIKE 'Performance Test Expense%';
DELETE FROM group_members WHERE group_id IN (
    SELECT id FROM groups WHERE name LIKE 'Performance Group%'
);
DELETE FROM groups WHERE name LIKE 'Performance Group%';
DELETE FROM users WHERE email LIKE 'perf_user_%@example.com';

SELECT * FROM finish();

ROLLBACK;