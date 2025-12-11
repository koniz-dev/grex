-- ============================================================================
-- Migration: Create Enum Types
-- Version: 00001
-- Description: Create custom enum types for the expense splitting application
-- ============================================================================

-- Member roles in a group
-- Defines the permission levels for group members
CREATE TYPE member_role AS ENUM (
  'administrator',  -- Full permissions: manage group, members, all expenses
  'editor',        -- Can create and edit expenses they are involved in
  'viewer'         -- Read-only access to group information
);

-- Methods for splitting expenses
-- Defines how an expense should be divided among participants
CREATE TYPE split_method AS ENUM (
  'equal',      -- Split equally among all participants
  'percentage', -- Split by specified percentages (must sum to 100%)
  'exact',      -- Split by exact amounts (must sum to total)
  'shares'      -- Split by shares/ratios (proportional)
);

-- Types of actions for audit logging
-- Used to track what type of operation was performed
CREATE TYPE action_type AS ENUM (
  'create',  -- Record was created
  'update',  -- Record was modified
  'delete'   -- Record was deleted (or soft-deleted)
);

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TYPE member_role IS 'Permission levels for group members';
COMMENT ON TYPE split_method IS 'Methods for dividing expenses among participants';
COMMENT ON TYPE action_type IS 'Types of operations for audit logging';

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify enum types were created
-- SELECT typname, typtype FROM pg_type WHERE typname IN ('member_role', 'split_method', 'action_type');

-- View enum values
-- SELECT enumlabel FROM pg_enum WHERE enumtypid = 'member_role'::regtype ORDER BY enumsortorder;
-- SELECT enumlabel FROM pg_enum WHERE enumtypid = 'split_method'::regtype ORDER BY enumsortorder;
-- SELECT enumlabel FROM pg_enum WHERE enumtypid = 'action_type'::regtype ORDER BY enumsortorder;