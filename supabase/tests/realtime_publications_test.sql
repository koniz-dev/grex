-- Property Tests: Real-time Publications
-- Description: Test real-time publication functionality and RLS integration
-- Requirements: 11.1, 11.2, 11.3, 11.4, 11.5

BEGIN;

-- Test setup
SELECT plan(4);

-- Property 40: Expense changes are published
-- Validates: Requirements 11.1, 11.2
SELECT has_table('expenses', 'expenses table exists for real-time testing');

-- Verify expenses table is in supabase_realtime publication
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'expenses'
    ),
    'Property 40: Expenses table is in supabase_realtime publication'
);

-- Property 41: Payment changes are published
-- Validates: Requirements 11.1, 11.2
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'payments'
    ),
    'Property 41: Payments table is in supabase_realtime publication'
);

-- Property 42: Membership changes are published
-- Validates: Requirements 11.1, 11.2
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'group_members'
    ),
    'Property 42: Group members table is in supabase_realtime publication'
);

-- Note: Property 43 (Publications respect RLS policies) is tested in integration tests
-- as it requires actual subscription testing which cannot be done in SQL alone

SELECT * FROM finish();

ROLLBACK;