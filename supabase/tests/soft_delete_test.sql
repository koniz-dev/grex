-- Property Tests: Soft Delete Functionality
-- Description: Test soft delete properties across all entities
-- Requirements: 15.1, 15.2, 15.3, 15.5

BEGIN;

-- Test setup
SELECT plan(8);

-- Create test data
DO $$
DECLARE
    test_user_id UUID;
    test_user2_id UUID;
    test_group_id UUID;
    test_expense_id UUID;
    test_payment_id UUID;
BEGIN
    -- Create test user
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('softdelete@example.com', 'Soft Delete Test User', 'USD', 'en')
    RETURNING id INTO test_user_id;
    
    -- Create second test user for payment
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('softdelete2@example.com', 'Soft Delete Test User 2', 'USD', 'en')
    RETURNING id INTO test_user2_id;
    
    -- Create test group
    INSERT INTO groups (name, description, creator_id, primary_currency)
    VALUES ('Soft Delete Test Group', 'Test group for soft delete', test_user_id, 'USD')
    RETURNING id INTO test_group_id;
    
    -- Create test expense
    INSERT INTO expenses (group_id, payer_id, description, amount, currency, expense_date, split_method)
    VALUES (test_group_id, test_user_id, 'Test expense', 100.00, 'USD', CURRENT_DATE, 'equal')
    RETURNING id INTO test_expense_id;
    
    -- Create test payment (different payer and recipient)
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date)
    VALUES (test_group_id, test_user_id, test_user2_id, 50.00, 'USD', CURRENT_DATE)
    RETURNING id INTO test_payment_id;
    
    -- Store IDs for tests
    PERFORM set_config('test.user_id', test_user_id::text, true);
    PERFORM set_config('test.group_id', test_group_id::text, true);
    PERFORM set_config('test.expense_id', test_expense_id::text, true);
    PERFORM set_config('test.payment_id', test_payment_id::text, true);
END;
$$;

-- Property 47: Soft delete sets timestamp
-- **Validates: Requirements 15.1**
SELECT ok(
    soft_delete_user(current_setting('test.user_id')::UUID) = TRUE,
    'Property 47: Soft delete user sets timestamp'
);

SELECT ok(
    (SELECT deleted_at FROM users WHERE id = current_setting('test.user_id')::UUID) IS NOT NULL,
    'Property 47: User deleted_at timestamp is set after soft delete'
);

-- Property 48: Active records exclude soft-deleted
-- **Validates: Requirements 15.2**
SELECT ok(
    NOT EXISTS (
        SELECT 1 FROM get_active_users() 
        WHERE id = current_setting('test.user_id')::UUID
    ),
    'Property 48: Active users exclude soft-deleted users'
);

-- Test soft delete for group
SELECT ok(
    soft_delete_group(current_setting('test.group_id')::UUID) = TRUE,
    'Property 47: Soft delete group sets timestamp'
);

SELECT ok(
    NOT EXISTS (
        SELECT 1 FROM get_active_groups() 
        WHERE id = current_setting('test.group_id')::UUID
    ),
    'Property 48: Active groups exclude soft-deleted groups'
);

-- Property 49: Restore clears deleted timestamp
-- **Validates: Requirements 15.3**
SELECT ok(
    restore_user(current_setting('test.user_id')::UUID) = TRUE,
    'Property 49: Restore user clears deleted timestamp'
);

SELECT ok(
    (SELECT deleted_at FROM users WHERE id = current_setting('test.user_id')::UUID) IS NULL,
    'Property 49: User deleted_at timestamp is cleared after restore'
);

-- Property 50: Soft delete maintains referential integrity
-- **Validates: Requirements 15.5**
-- Test that soft deleting a user doesn't break foreign key relationships
SELECT ok(
    EXISTS (
        SELECT 1 FROM expenses 
        WHERE payer_id = current_setting('test.user_id')::UUID
    ),
    'Property 50: Soft delete maintains referential integrity - expenses still reference user'
);

-- Cleanup test data
DO $$
BEGIN
    -- Hard delete test records
    DELETE FROM payments WHERE id = current_setting('test.payment_id')::UUID;
    DELETE FROM expenses WHERE id = current_setting('test.expense_id')::UUID;
    DELETE FROM groups WHERE id = current_setting('test.group_id')::UUID;
    DELETE FROM users WHERE email LIKE 'softdelete%@example.com';
END;
$$;

SELECT * FROM finish();

ROLLBACK;