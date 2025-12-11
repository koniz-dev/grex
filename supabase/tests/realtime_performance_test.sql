-- Performance Tests: Real-time Performance Analysis
-- Description: Test real-time publication performance and latency
-- Requirements: 11.1, 11.2, 11.3

BEGIN;

-- Test setup
SELECT plan(8);

-- Test 1: Real-time publication configuration
SELECT ok(
    (SELECT COUNT(*) FROM pg_publication_tables WHERE pubname = 'supabase_realtime') = 7,
    'All 7 tables are configured for real-time publication'
);

-- Test 2: Publication includes high-traffic tables
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename IN ('expenses', 'payments', 'expense_participants')
    ),
    'High-traffic tables are included in real-time publication'
);

-- Create test data for real-time performance testing
DO $$
DECLARE
    i INTEGER;
    test_user_ids UUID[];
    test_group_id UUID;
    current_user_id UUID;
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
    batch_duration INTERVAL;
BEGIN
    -- Create 20 test users
    FOR i IN 1..20 LOOP
        INSERT INTO users (email, display_name, preferred_currency, preferred_language)
        VALUES ('rt_perf_user_' || i || '@example.com', 'RT Perf User ' || i, 'USD', 'en')
        RETURNING id INTO current_user_id;
        
        test_user_ids := array_append(test_user_ids, current_user_id);
    END LOOP;
    
    -- Create test group
    INSERT INTO groups (name, description, creator_id, primary_currency)
    VALUES ('Real-time Performance Test Group', 'Group for RT performance testing', test_user_ids[1], 'USD')
    RETURNING id INTO test_group_id;
    
    -- Add members to group
    FOR i IN 1..20 LOOP
        INSERT INTO group_members (group_id, user_id, role)
        VALUES (test_group_id, test_user_ids[i], 'editor'::member_role);
    END LOOP;
    
    PERFORM set_config('test.rt_group_id', test_group_id::text, true);
    PERFORM set_config('test.rt_user_count', array_length(test_user_ids, 1)::text, true);
END;
$$;

-- Test 3: Batch insert performance (simulates high-frequency updates)
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    insert_count INTEGER := 0;
    i INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Insert 100 expenses rapidly (simulates busy period)
    FOR i IN 1..100 LOOP
        INSERT INTO expenses (group_id, payer_id, description, amount, currency, expense_date, split_method)
        VALUES (
            current_setting('test.rt_group_id')::UUID,
            (SELECT id FROM users WHERE email = 'rt_perf_user_' || ((i % 20) + 1) || '@example.com'),
            'RT Performance Expense ' || i,
            (i * 5.50)::DECIMAL(10,2),
            'USD',
            CURRENT_DATE,
            'equal'::split_method
        );
        insert_count := insert_count + 1;
    END LOOP;
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.batch_insert_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.batch_insert_count', insert_count::text, true);
END;
$$;

SELECT ok(
    current_setting('test.batch_insert_count')::INTEGER = 100,
    'Batch insert of 100 expenses completed successfully'
);

-- Test 4: Batch insert performance benchmark
SELECT ok(
    current_setting('test.batch_insert_time')::NUMERIC < 5000, -- 5 seconds max
    'Batch insert completes within 5 seconds (good for real-time responsiveness)'
);

-- Test 5: Rapid update performance (simulates concurrent user activity)
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    update_count INTEGER := 0;
    expense_record RECORD;
BEGIN
    start_time := clock_timestamp();
    
    -- Update all test expenses rapidly
    FOR expense_record IN 
        SELECT id FROM expenses 
        WHERE description LIKE 'RT Performance Expense%'
        ORDER BY id
    LOOP
        UPDATE expenses 
        SET description = description || ' (Updated)',
            amount = amount + 1.00
        WHERE id = expense_record.id;
        
        update_count := update_count + 1;
    END LOOP;
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.batch_update_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.batch_update_count', update_count::text, true);
END;
$$;

SELECT ok(
    current_setting('test.batch_update_count')::INTEGER = 100,
    'Batch update of 100 expenses completed successfully'
);

-- Test 6: Batch update performance benchmark
SELECT ok(
    current_setting('test.batch_update_time')::NUMERIC < 3000, -- 3 seconds max
    'Batch update completes within 3 seconds (good for real-time responsiveness)'
);

-- Test 7: Payment insertion performance (high-frequency operation)
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    payment_count INTEGER := 0;
    i INTEGER;
    payer_id UUID;
    recipient_id UUID;
BEGIN
    start_time := clock_timestamp();
    
    -- Insert 200 payments rapidly
    FOR i IN 1..200 LOOP
        SELECT id INTO payer_id FROM users WHERE email = 'rt_perf_user_' || ((i % 20) + 1) || '@example.com';
        SELECT id INTO recipient_id FROM users WHERE email = 'rt_perf_user_' || (((i + 10) % 20) + 1) || '@example.com';
        
        INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date)
        VALUES (
            current_setting('test.rt_group_id')::UUID,
            payer_id,
            recipient_id,
            (i * 2.25)::DECIMAL(10,2),
            'USD',
            CURRENT_DATE
        );
        payment_count := payment_count + 1;
    END LOOP;
    
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    
    PERFORM set_config('test.payment_insert_time', extract(milliseconds from execution_time)::text, true);
    PERFORM set_config('test.payment_insert_count', payment_count::text, true);
END;
$$;

SELECT ok(
    current_setting('test.payment_insert_time')::NUMERIC < 4000, -- 4 seconds max
    'Payment batch insert completes within 4 seconds'
);

-- Test 8: Overall real-time performance summary
SELECT ok(
    current_setting('test.batch_insert_time')::NUMERIC < 5000 AND
    current_setting('test.batch_update_time')::NUMERIC < 3000 AND
    current_setting('test.payment_insert_time')::NUMERIC < 4000,
    'All real-time operations meet performance benchmarks'
);

-- Performance Summary and Recommendations
DO $$
BEGIN
    RAISE NOTICE 'Real-time Performance Test Results:';
    RAISE NOTICE '- Batch expense insert (100 records): % ms', current_setting('test.batch_insert_time');
    RAISE NOTICE '- Batch expense update (100 records): % ms', current_setting('test.batch_update_time');
    RAISE NOTICE '- Batch payment insert (200 records): % ms', current_setting('test.payment_insert_time');
    RAISE NOTICE '';
    RAISE NOTICE 'Real-time Performance Analysis:';
    RAISE NOTICE '- Average insert time per expense: % ms', 
        (current_setting('test.batch_insert_time')::NUMERIC / 100)::DECIMAL(10,2);
    RAISE NOTICE '- Average update time per expense: % ms', 
        (current_setting('test.batch_update_time')::NUMERIC / 100)::DECIMAL(10,2);
    RAISE NOTICE '- Average insert time per payment: % ms', 
        (current_setting('test.payment_insert_time')::NUMERIC / 200)::DECIMAL(10,2);
    RAISE NOTICE '';
    RAISE NOTICE 'Recommendations for Real-time Optimization:';
    
    IF current_setting('test.batch_insert_time')::NUMERIC > 3000 THEN
        RAISE NOTICE '- Consider optimizing expense insert triggers for better real-time performance';
    ELSE
        RAISE NOTICE '- Expense insert performance is optimal for real-time updates';
    END IF;
    
    IF current_setting('test.batch_update_time')::NUMERIC > 2000 THEN
        RAISE NOTICE '- Consider optimizing expense update triggers for better real-time performance';
    ELSE
        RAISE NOTICE '- Expense update performance is optimal for real-time updates';
    END IF;
    
    IF current_setting('test.payment_insert_time')::NUMERIC > 3000 THEN
        RAISE NOTICE '- Consider optimizing payment insert triggers for better real-time performance';
    ELSE
        RAISE NOTICE '- Payment insert performance is optimal for real-time updates';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Real-time Client Recommendations:';
    RAISE NOTICE '- Use connection pooling for multiple concurrent subscribers';
    RAISE NOTICE '- Implement client-side debouncing for rapid updates';
    RAISE NOTICE '- Consider batching real-time events on the client side';
    RAISE NOTICE '- Use RLS filters to reduce unnecessary event traffic';
END;
$$;

-- Cleanup real-time performance test data
DELETE FROM payments WHERE group_id = current_setting('test.rt_group_id')::UUID;
DELETE FROM expenses WHERE description LIKE 'RT Performance Expense%';
DELETE FROM group_members WHERE group_id = current_setting('test.rt_group_id')::UUID;
DELETE FROM groups WHERE name = 'Real-time Performance Test Group';
DELETE FROM users WHERE email LIKE 'rt_perf_user_%@example.com';

SELECT * FROM finish();

ROLLBACK;