-- Integration Tests: Real-time Publications
-- Description: Test real-time subscriptions with RLS policies
-- Requirements: 11.1, 11.2, 11.3, 11.4, 11.5

BEGIN;

-- Test setup
SELECT plan(7);

-- Verify all tables are in supabase_realtime publication
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'users'
    ),
    'Users table is in supabase_realtime publication'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'groups'
    ),
    'Groups table is in supabase_realtime publication'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'group_members'
    ),
    'Group members table is in supabase_realtime publication'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'expenses'
    ),
    'Expenses table is in supabase_realtime publication'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'expense_participants'
    ),
    'Expense participants table is in supabase_realtime publication'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'payments'
    ),
    'Payments table is in supabase_realtime publication'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'audit_logs'
    ),
    'Audit logs table is in supabase_realtime publication'
);

-- Note: Testing actual real-time subscriptions and RLS filtering requires client-side testing
-- These tests verify that the publication setup is correct
-- Property 43 (Publications respect RLS policies) would be tested in the Flutter app
-- where actual subscriptions can be created and RLS policies can be verified

SELECT * FROM finish();

ROLLBACK;