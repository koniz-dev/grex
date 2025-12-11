-- Migration: Enable Real-time Publications
-- Description: Enable real-time subscriptions for all tables to support live updates
-- Requirements: 11.1, 11.2, 11.3

-- Enable real-time for all tables by adding them to the supabase_realtime publication
-- This allows clients to subscribe to real-time changes on these tables

-- Add users table to real-time publication
ALTER PUBLICATION supabase_realtime ADD TABLE users;

-- Add groups table to real-time publication
ALTER PUBLICATION supabase_realtime ADD TABLE groups;

-- Add group_members table to real-time publication
ALTER PUBLICATION supabase_realtime ADD TABLE group_members;

-- Add expenses table to real-time publication
ALTER PUBLICATION supabase_realtime ADD TABLE expenses;

-- Add expense_participants table to real-time publication
ALTER PUBLICATION supabase_realtime ADD TABLE expense_participants;

-- Add payments table to real-time publication
ALTER PUBLICATION supabase_realtime ADD TABLE payments;

-- Add audit_logs table to real-time publication
ALTER PUBLICATION supabase_realtime ADD TABLE audit_logs;

-- Verify real-time is enabled for all tables
-- This query can be used to check which tables are in the publication
-- SELECT schemaname, tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime';