-- Integration Tests: Complete User Workflows
-- Description: Test end-to-end user workflows for the expense splitting application
-- Requirements: All

BEGIN;

-- Test setup
SELECT plan(12);

-- Create test users
DO $$
DECLARE
    alice_id UUID;
    bob_id UUID;
    charlie_id UUID;
    group_id UUID;
    expense_id UUID;
    payment_id UUID;
BEGIN
    -- Test 1: User registration and profile creation
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('alice@example.com', 'Alice Smith', 'USD', 'en')
    RETURNING id INTO alice_id;
    
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('bob@example.com', 'Bob Johnson', 'USD', 'en')
    RETURNING id INTO bob_id;
    
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('charlie@example.com', 'Charlie Brown', 'USD', 'en')
    RETURNING id INTO charlie_id;
    
    -- Store user IDs for tests
    PERFORM set_config('test.alice_id', alice_id::text, true);
    PERFORM set_config('test.bob_id', bob_id::text, true);
    PERFORM set_config('test.charlie_id', charlie_id::text, true);
    
    -- Test 2: Group creation and membership management
    INSERT INTO groups (name, description, creator_id, primary_currency)
    VALUES ('Weekend Trip', 'Shared expenses for our weekend getaway', alice_id, 'USD')
    RETURNING id INTO group_id;
    
    PERFORM set_config('test.group_id', group_id::text, true);
    
    -- Add members to group
    INSERT INTO group_members (group_id, user_id, role, joined_at)
    VALUES 
        (group_id, alice_id, 'administrator', NOW()),
        (group_id, bob_id, 'editor', NOW()),
        (group_id, charlie_id, 'viewer', NOW());
    
    -- Test 3: Expense creation with various split methods
    -- Create equal split expense
    INSERT INTO expenses (group_id, payer_id, description, amount, currency, expense_date, split_method)
    VALUES (group_id, alice_id, 'Hotel booking', 300.00, 'USD', CURRENT_DATE, 'equal')
    RETURNING id INTO expense_id;
    
    PERFORM set_config('test.expense_id', expense_id::text, true);
    
    -- Add expense participants (equal split among 3 people = $100 each)
    INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
    VALUES 
        (expense_id, alice_id, 100.00, 33.33),
        (expense_id, bob_id, 100.00, 33.33),
        (expense_id, charlie_id, 100.00, 33.34);
    
    -- Test 4: Payment recording and balance updates
    INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date)
    VALUES (group_id, bob_id, alice_id, 100.00, 'USD', CURRENT_DATE)
    RETURNING id INTO payment_id;
    
    PERFORM set_config('test.payment_id', payment_id::text, true);
    
    -- Test 5: Settlement plan generation
    -- This will be tested through function calls
END;
$$;

-- Test 1: User registration creates valid profiles
SELECT ok(
    EXISTS (
        SELECT 1 FROM users 
        WHERE email = 'alice@example.com' 
        AND display_name = 'Alice Smith'
        AND preferred_currency = 'USD'
    ),
    'User registration creates complete profile'
);

-- Test 2: Group creation with proper ownership
SELECT ok(
    EXISTS (
        SELECT 1 FROM groups g
        JOIN users u ON g.creator_id = u.id
        WHERE g.name = 'Weekend Trip'
        AND u.email = 'alice@example.com'
    ),
    'Group creation establishes proper ownership'
);

-- Test 3: Group membership management
SELECT ok(
    (SELECT COUNT(*) FROM group_members WHERE group_id = current_setting('test.group_id')::UUID) = 3,
    'Group membership includes all added users'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM group_members 
        WHERE group_id = current_setting('test.group_id')::UUID
        AND user_id = current_setting('test.alice_id')::UUID
        AND role = 'administrator'
    ),
    'Group creator has administrator role'
);

-- Test 4: Expense creation with split calculation
SELECT ok(
    EXISTS (
        SELECT 1 FROM expenses 
        WHERE id = current_setting('test.expense_id')::UUID
        AND description = 'Hotel booking'
        AND amount = 300.00
        AND split_method = 'equal'
    ),
    'Expense creation stores all details correctly'
);

SELECT ok(
    (SELECT COUNT(*) FROM expense_participants WHERE expense_id = current_setting('test.expense_id')::UUID) = 3,
    'Expense participants include all group members'
);

-- Test 5: Split amounts sum to total expense
SELECT ok(
    (SELECT SUM(share_amount) FROM expense_participants WHERE expense_id = current_setting('test.expense_id')::UUID) = 300.00,
    'Split amounts sum to total expense amount'
);

-- Test 6: Payment recording
SELECT ok(
    EXISTS (
        SELECT 1 FROM payments 
        WHERE id = current_setting('test.payment_id')::UUID
        AND payer_id = current_setting('test.bob_id')::UUID
        AND recipient_id = current_setting('test.alice_id')::UUID
        AND amount = 100.00
    ),
    'Payment recording captures all transaction details'
);

-- Test 7: Balance calculation functionality
SELECT ok(
    EXISTS (
        SELECT 1 FROM calculate_group_balances(current_setting('test.group_id')::UUID)
        WHERE user_id = current_setting('test.alice_id')::UUID
    ),
    'Balance calculation returns data for Alice'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM calculate_group_balances(current_setting('test.group_id')::UUID)
        WHERE user_id = current_setting('test.bob_id')::UUID
    ),
    'Balance calculation returns data for Bob'
);

-- Test 8: Settlement plan generation
SELECT ok(
    EXISTS (
        SELECT 1 FROM generate_settlement_plan(current_setting('test.group_id')::UUID)
        WHERE payer_id = current_setting('test.charlie_id')::UUID
        AND recipient_id = current_setting('test.alice_id')::UUID
        AND amount = 100.00  -- Charlie owes $100 to Alice
    ),
    'Settlement plan generates correct transactions'
);

-- Test 9: Audit trail creation
SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_logs 
        WHERE entity_type = 'expense'
        AND entity_id = current_setting('test.expense_id')::UUID
        AND action = 'create'
        AND user_id = current_setting('test.alice_id')::UUID
    ),
    'Audit trail captures expense creation'
);

-- Cleanup test data
DELETE FROM payments WHERE id = current_setting('test.payment_id')::UUID;
DELETE FROM expense_participants WHERE expense_id = current_setting('test.expense_id')::UUID;
DELETE FROM expenses WHERE id = current_setting('test.expense_id')::UUID;
DELETE FROM group_members WHERE group_id = current_setting('test.group_id')::UUID;
DELETE FROM groups WHERE id = current_setting('test.group_id')::UUID;
DELETE FROM users WHERE email LIKE '%@example.com';

SELECT * FROM finish();

ROLLBACK;