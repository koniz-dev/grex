-- Migration: Enable RLS for migration_history table
-- Description: Fix security warning by enabling Row Level Security for migration_history table
-- Author: System
-- Date: 2025-01-25

-- Enable Row Level Security for migration_history table
ALTER TABLE migration_history ENABLE ROW LEVEL SECURITY;

-- Create policy to allow service role to manage migration history
-- Only service role should be able to read/write migration history
CREATE POLICY "Service role can manage migration history" ON migration_history
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Create policy to deny access to authenticated users
-- Migration history should not be accessible to regular users
CREATE POLICY "Deny access to authenticated users" ON migration_history
    FOR ALL
    TO authenticated
    USING (false)
    WITH CHECK (false);

-- Create policy to deny access to anonymous users
-- Migration history should not be accessible to anonymous users
CREATE POLICY "Deny access to anonymous users" ON migration_history
    FOR ALL
    TO anon
    USING (false)
    WITH CHECK (false);

-- Add comment explaining the security model
COMMENT ON TABLE migration_history IS 'Tracks database migrations. Access restricted to service role only for security.';