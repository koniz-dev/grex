-- Unit Tests: Soft Delete Functions
-- Description: Comprehensive unit tests for soft delete functionality
-- Requirements: 15.1, 15.2, 15.3, 15.4, 15.5

BEGIN;

-- Test setup
SELECT plan(21);

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
    VALUES ('unittest@example.com', 'Unit Test User', 'USD', 'en')
    RETURNING id INTO test_user_id;
    
    -- Create second test user for payment
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('unittest2@example.com', 'Unit Test User 2', 'USD', 'en')
    RETURNING id INTO test_user2_id;
    
    -- Create test group
    INSERT INTO groups (name, description, creator_id, primary_currency)
    VALUES ('Unit Test Group', 'Test group', test_user_id, 'USD')
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

-- Test 1: Soft delete operations
SELECT ok(soft_delete_user(current_setting('test.user_id')::UUID), 'Soft delete user succeeds');
SELECT ok(soft_delete_group(current_setting('test.group_id')::UUID), 'Soft delete group succeeds');
SELECT ok(soft_delete_expense(current_setting('test.expense_id')::UUID), 'Soft delete expense succeeds');
SELECT ok(soft_delete_payment(current_setting('test.payment_id')::UUID), 'Soft delete payment succeeds');

-- Test 2: Verify deleted_at timestamps are set
SELECT ok(
    (SELECT deleted_at FROM users WHERE id = current_setting('test.user_id')::UUID) IS NOT NULL,
    'User deleted_at timestamp is set'
);
SELECT ok(
    (SELECT deleted_at FROM groups WHERE id = current_setting('test.group_id')::UUID) IS NOT NULL,
    'Group deleted_at timestamp is set'
);
SELECT ok(
    (SELECT deleted_at FROM expenses WHERE id = current_setting('test.expense_id')::UUID) IS NOT NULL,
    'Expense deleted_at timestamp is set'
);
SELECT ok(
    (SELECT deleted_at FROM payments WHERE id = current_setting('test.payment_id')::UUID) IS NOT NULL,
    'Payment deleted_at timestamp is set'
);

-- Test 3: Restore operations
SELECT ok(restore_user(current_setting('test.user_id')::UUID), 'Restore user succeeds');
SELECT ok(restore_group(current_setting('test.group_id')::UUID), 'Restore group succeeds');
SELECT ok(restore_expense(current_setting('test.expense_id')::UUID), 'Restore expense succeeds');
SELECT ok(restore_payment(current_setting('test.payment_id')::UUID), 'Restore payment succeeds');

-- Test 4: Verify deleted_at timestamps are cleared
SELECT ok(
    (SELECT deleted_at FROM users WHERE id = current_setting('test.user_id')::UUID) IS NULL,
    'User deleted_at timestamp is cleared after restore'
);
SELECT ok(
    (SELECT deleted_at FROM groups WHERE id = current_setting('test.group_id')::UUID) IS NULL,
    'Group deleted_at timestamp is cleared after restore'
);
SELECT ok(
    (SELECT deleted_at FROM expenses WHERE id = current_setting('test.expense_id')::UUID) IS NULL,
    'Expense deleted_at timestamp is cleared after restore'
);
SELECT ok(
    (SELECT deleted_at FROM payments WHERE id = current_setting('test.payment_id')::UUID) IS NULL,
    'Payment deleted_at timestamp is cleared after restore'
);

-- Test 5: Active record queries exclude soft-deleted records
-- First soft delete again
SELECT ok(soft_delete_user(current_setting('test.user_id')::UUID), 'Re-soft delete user for active query test');

SELECT ok(
    NOT EXISTS (SELECT 1 FROM get_active_users() WHERE id = current_setting('test.user_id')::UUID),
    'Active users query excludes soft-deleted users'
);

-- Test 6: Hard delete operations (only work on soft-deleted records)
SELECT ok(hard_delete_user(current_setting('test.user_id')::UUID), 'Hard delete user succeeds');

-- Verify user is permanently deleted
SELECT ok(
    NOT EXISTS (SELECT 1 FROM users WHERE id = current_setting('test.user_id')::UUID),
    'User is permanently deleted after hard delete'
);

-- Test 7: Hard delete should fail on non-soft-deleted records
SELECT ok(
    NOT hard_delete_group(current_setting('test.group_id')::UUID),
    'Hard delete fails on non-soft-deleted group'
);

-- Cleanup remaining test data
DO $$
BEGIN
    DELETE FROM payments WHERE id = current_setting('test.payment_id')::UUID;
    DELETE FROM expenses WHERE id = current_setting('test.expense_id')::UUID;
    DELETE FROM groups WHERE id = current_setting('test.group_id')::UUID;
    DELETE FROM users WHERE email LIKE 'unittest%@example.com';
END;
$$;

SELECT * FROM finish();

ROLLBACK;