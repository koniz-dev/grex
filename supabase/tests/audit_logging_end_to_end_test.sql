-- Integration Tests: Audit Logging End-to-End
-- Description: Test comprehensive audit logging across all operations
-- Requirements: 7.1, 7.2, 7.4

BEGIN;

-- Test setup
SELECT plan(12);

-- Create test data for audit logging
DO $$
DECLARE
    test_user_id UUID;
    test_group_id UUID;
    test_expense_id UUID;
    test_payment_id UUID;
    initial_audit_count INTEGER;
BEGIN
    -- Get initial audit log count
    SELECT COUNT(*) INTO initial_audit_count FROM audit_logs;
    PERFORM set_config('test.initial_audit_count', initial_audit_count::text, true);
    
    -- Create test user
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('audit.test@example.com', 'Audit Test User', 'USD', 'en')
    RETURNING id INTO test_user_id;
    
    PERFORM set_config('test.user_id', test_user_id::text, true);
    
    -- Create test group
    INSERT INTO groups (name, description, creator_id, primary_currency)
    VALUES ('Audit Test Group', 'Group for audit testing', test_user_id, 'USD')
    RETURNING id INTO test_group_id;
    
    PERFORM set_config('test.group_id', test_group_id::text, true);
    
    -- Add group membership
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_id, test_user_id, 'administrator');
    
    -- Create test expense
    INSERT INTO expenses (group_id, payer_id, description, amount, currency, expense_date, split_method)
    VALUES (test_group_id, test_user_id, 'Audit Test Expense', 150.00, 'USD', CURRENT_DATE, 'equal')
    RETURNING id INTO test_expense_id;
    
    PERFORM set_config('test.expense_id', test_expense_id::text, true);
    
    -- Create second user for payment test
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('audit.test2@example.com', 'Audit Test User 2', 'USD', 'en');
    
    SELECT id INTO test_user_id FROM users WHERE email = 'audit.test2@example.com';
    PERFORM set_config('test.user2_id', test_user_id::text, true);
    
    -- Add second user to group
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_id, test_user_id, 'editor');
    
    -- Create test payment
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date)
    VALUES (test_group_id, current_setting('test.user2_id')::UUID, current_setting('test.user_id')::UUID, 75.00, 'USD', CURRENT_DATE)
    RETURNING id INTO test_payment_id;
    
    PERFORM set_config('test.payment_id', test_payment_id::text, true);
END;
$$;

-- Test 1: Expense creation generates audit log
SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'expense'
        AND entity_id = current_setting('test.expense_id')::UUID
        AND action = 'create'
        AND user_id = current_setting('test.user_id')::UUID
    ),
    'Expense creation generates audit log entry'
);

-- Test 2: Audit log contains complete before/after state
SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'expense'
        AND entity_id = current_setting('test.expense_id')::UUID
        AND action = 'create'
        AND before_state IS NULL
        AND after_state IS NOT NULL
        AND after_state::jsonb ? 'description'
        AND after_state::jsonb ? 'amount'
    ),
    'Audit log contains complete after-state for creation'
);

-- Test 3: Expense update generates audit log with before/after states
UPDATE expenses 
SET description = 'Updated Audit Test Expense', amount = 175.00
WHERE id = current_setting('test.expense_id')::UUID;

SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'expense'
        AND entity_id = current_setting('test.expense_id')::UUID
        AND action = 'update'
        AND before_state IS NOT NULL
        AND after_state IS NOT NULL
        AND before_state::jsonb ->> 'description' = 'Audit Test Expense'
        AND after_state::jsonb ->> 'description' = 'Updated Audit Test Expense'
    ),
    'Expense update generates audit log with before/after states'
);

-- Test 4: Payment creation generates audit log
SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'payment'
        AND entity_id = current_setting('test.payment_id')::UUID
        AND action = 'create'
        AND user_id = current_setting('test.user2_id')::UUID
    ),
    'Payment creation generates audit log entry'
);

-- Test 5: Group membership changes generate audit logs
UPDATE group_members 
SET role = 'viewer'
WHERE group_id = current_setting('test.group_id')::UUID
AND user_id = current_setting('test.user2_id')::UUID;

SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'group_member'
        AND action = 'update'
        AND group_id = current_setting('test.group_id')::UUID
        AND before_state::jsonb ->> 'role' = 'editor'
        AND after_state::jsonb ->> 'role' = 'viewer'
    ),
    'Group membership changes generate audit logs'
);

-- Test 6: Audit log immutability - UPDATE should fail
DO $$
DECLARE
    update_failed BOOLEAN := TRUE;
BEGIN
    BEGIN
        UPDATE audit_logs 
        SET action = 'modified'
        WHERE entity_type = 'expense'
        AND entity_id = current_setting('test.expense_id')::UUID;
        
        -- If we get here, the update succeeded (which shouldn't happen)
        update_failed := FALSE;
    EXCEPTION
        WHEN OTHERS THEN
            update_failed := TRUE;
    END;
    
    PERFORM set_config('test.audit_update_failed', update_failed::text, true);
END;
$$;

SELECT ok(
    current_setting('test.audit_update_failed')::BOOLEAN,
    'Audit logs are immutable - UPDATE operations fail'
);

-- Test 7: Audit logs table exists and is configured
SELECT ok(
    EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'audit_logs'
        AND table_schema = 'public'
    ),
    'Audit logs table is properly configured'
);

-- Test 8: Audit logs capture context information
SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'expense'
        AND entity_id = current_setting('test.expense_id')::UUID
        AND action = 'create'
        AND group_id = current_setting('test.group_id')::UUID
    ),
    'Audit logs capture group context'
);

-- Test 9: Audit logs have timestamps
SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'expense'
        AND entity_id = current_setting('test.expense_id')::UUID
        AND created_at IS NOT NULL
    ),
    'Audit logs have proper timestamps'
);

-- Test 10: Expense deletion generates audit log
DELETE FROM expenses WHERE id = current_setting('test.expense_id')::UUID;

SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'expense'
        AND entity_id = current_setting('test.expense_id')::UUID
        AND action = 'delete'
        AND before_state IS NOT NULL
        AND after_state IS NULL
    ),
    'Expense deletion generates audit log with before-state'
);

-- Test 11: Payment deletion generates audit log
DELETE FROM payments WHERE id = current_setting('test.payment_id')::UUID;

SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'payment'
        AND entity_id = current_setting('test.payment_id')::UUID
        AND action = 'delete'
        AND before_state IS NOT NULL
        AND after_state IS NULL
    ),
    'Payment deletion generates audit log'
);

-- Test 12: Comprehensive audit trail exists
-- Count all audit entries created during this test
SELECT ok(
    (SELECT COUNT(*) FROM audit_logs) > current_setting('test.initial_audit_count')::INTEGER + 5,
    'Comprehensive audit trail captures all operations'
);

-- Cleanup test data (this will generate more audit logs)
DELETE FROM group_members WHERE group_id = current_setting('test.group_id')::UUID;
DELETE FROM groups WHERE id = current_setting('test.group_id')::UUID;
DELETE FROM users WHERE email LIKE 'audit.test%@example.com';

SELECT * FROM finish();

ROLLBACK;