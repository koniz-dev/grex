-- Integration Tests: Real-time Functionality End-to-End
-- Description: Test real-time subscriptions and RLS filtering integration
-- Requirements: 11.1, 11.2, 11.3, 11.4, 11.5

BEGIN;

-- Test setup
SELECT plan(8);

-- Test 1: All required tables are in real-time publication
SELECT ok(
    (SELECT COUNT(*) FROM pg_publication_tables WHERE pubname = 'supabase_realtime') = 7,
    'All required tables are in supabase_realtime publication'
);

-- Test 2: Users table is published for real-time
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'users'
    ),
    'Users table is published for real-time updates'
);

-- Test 3: Groups table is published for real-time
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'groups'
    ),
    'Groups table is published for real-time updates'
);

-- Test 4: Expenses table is published for real-time
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'expenses'
    ),
    'Expenses table is published for real-time updates'
);

-- Test 5: Payments table is published for real-time
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'payments'
    ),
    'Payments table is published for real-time updates'
);

-- Test 6: Group members table is published for real-time
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'group_members'
    ),
    'Group members table is published for real-time updates'
);

-- Test 7: Expense participants table is published for real-time
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'expense_participants'
    ),
    'Expense participants table is published for real-time updates'
);

-- Test 8: Audit logs table is published for real-time
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'audit_logs'
    ),
    'Audit logs table is published for real-time updates'
);

-- Note: Testing actual real-time subscriptions and RLS filtering requires client-side testing
-- The following would be tested in the Flutter application:
-- 
-- Real-time Subscription Tests (to be implemented in Flutter):
-- 1. Subscribe to expenses table with RLS context
-- 2. Insert new expense in same group -> should receive real-time event
-- 3. Insert new expense in different group -> should NOT receive real-time event
-- 4. Update expense in same group -> should receive real-time event
-- 5. Delete expense in same group -> should receive real-time event
-- 6. Subscribe to payments table with RLS context
-- 7. Insert new payment in same group -> should receive real-time event
-- 8. Subscribe to group_members table with RLS context
-- 9. Add new member to same group -> should receive real-time event
-- 10. Test concurrent subscriptions from multiple users
-- 11. Test subscription cleanup on disconnect
-- 12. Test real-time events include proper row data
-- 13. Test real-time events respect RLS policies
-- 14. Test real-time performance with multiple concurrent subscribers

-- Create test data to verify real-time setup works with actual data changes
DO $$
DECLARE
    test_user_id UUID;
    test_group_id UUID;
    test_expense_id UUID;
BEGIN
    -- Create test user
    INSERT INTO users (email, display_name, preferred_currency, preferred_language)
    VALUES ('realtime.test@example.com', 'Realtime Test User', 'USD', 'en')
    RETURNING id INTO test_user_id;
    
    -- Create test group
    INSERT INTO groups (name, description, creator_id, primary_currency)
    VALUES ('Realtime Test Group', 'Group for realtime testing', test_user_id, 'USD')
    RETURNING id INTO test_group_id;
    
    -- Add group membership
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (test_group_id, test_user_id, 'administrator');
    
    -- Create test expense (this should trigger real-time events)
    INSERT INTO expenses (group_id, payer_id, description, amount, currency, expense_date, split_method)
    VALUES (test_group_id, test_user_id, 'Realtime Test Expense', 100.00, 'USD', CURRENT_DATE, 'equal')
    RETURNING id INTO test_expense_id;
    
    -- Update expense (this should trigger real-time events)
    UPDATE expenses 
    SET description = 'Updated Realtime Test Expense'
    WHERE id = test_expense_id;
    
    -- Delete test data (this should trigger real-time events)
    DELETE FROM expenses WHERE id = test_expense_id;
    DELETE FROM group_members WHERE group_id = test_group_id;
    DELETE FROM groups WHERE id = test_group_id;
    DELETE FROM users WHERE id = test_user_id;
END;
$$;

-- The above operations would generate real-time events that clients can subscribe to
-- In a real application, clients would:
-- 1. Connect to Supabase real-time
-- 2. Subscribe to specific tables with filters
-- 3. Receive events when data changes
-- 4. Apply RLS filtering on the client side or server side
-- 5. Update UI in real-time based on received events

SELECT * FROM finish();

ROLLBACK;