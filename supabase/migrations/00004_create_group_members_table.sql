-- ============================================================================
-- Migration: Create Group Members Table
-- Version: 00004
-- Description: Create group_members table with constraints, indexes, and foreign keys
-- ============================================================================

-- Create group_members table
CREATE TABLE group_members (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Relationships
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Member role and permissions
  role member_role NOT NULL DEFAULT 'editor',
  
  -- Timestamps
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- ========================================================================
  -- Constraints
  -- ========================================================================
  
  -- Ensure unique membership per user per group
  CONSTRAINT unique_group_user UNIQUE (group_id, user_id)
);

-- ============================================================================
-- Indexes for performance
-- ============================================================================

-- Foreign key indexes
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);

-- Composite index for efficient lookups
CREATE INDEX idx_group_members_composite ON group_members(group_id, user_id);

-- Role-based queries (find all admins, editors, etc.)
CREATE INDEX idx_group_members_role ON group_members(role);

-- Timestamp index for membership history
CREATE INDEX idx_group_members_joined_at ON group_members(joined_at);

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE group_members IS 'Membership relationships between users and groups with role-based permissions';
COMMENT ON COLUMN group_members.id IS 'Unique identifier for the membership record (UUID)';
COMMENT ON COLUMN group_members.group_id IS 'Reference to the group (foreign key to groups.id)';
COMMENT ON COLUMN group_members.user_id IS 'Reference to the user (foreign key to users.id)';
COMMENT ON COLUMN group_members.role IS 'Permission level for this user in this group';
COMMENT ON COLUMN group_members.joined_at IS 'Timestamp when user joined the group';
COMMENT ON COLUMN group_members.updated_at IS 'Timestamp when membership was last updated (e.g., role change)';

-- ============================================================================
-- Role hierarchy and permissions (for reference)
-- ============================================================================

-- administrator: Full permissions
--   - Manage group settings (name, description, currency)
--   - Add/remove members
--   - Change member roles
--   - Create/edit/delete any expense
--   - Create/edit/delete any payment
--   - View audit logs

-- editor: Standard member permissions
--   - Create expenses
--   - Edit their own expenses
--   - Add participants to expenses
--   - Create payments (as payer)
--   - View group data

-- viewer: Read-only permissions
--   - View group information
--   - View expenses and balances
--   - View payments
--   - Cannot create or modify data

-- ============================================================================
-- Triggers for automatic timestamp management
-- ============================================================================

-- Create specialized timestamp trigger function for group_members
CREATE OR REPLACE FUNCTION set_group_members_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.joined_at = NOW();
    NEW.updated_at = NOW();
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.updated_at = NOW();
    -- Prevent modification of joined_at
    NEW.joined_at = OLD.joined_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp trigger to group_members table
CREATE TRIGGER set_group_members_timestamps
  BEFORE INSERT OR UPDATE ON group_members
  FOR EACH ROW EXECUTE FUNCTION set_group_members_timestamps();

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify table was created
-- SELECT table_name, column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'group_members' 
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type 
-- FROM information_schema.table_constraints 
-- WHERE table_name = 'group_members';

-- Verify foreign keys
-- SELECT 
--   tc.constraint_name,
--   tc.table_name,
--   kcu.column_name,
--   ccu.table_name AS foreign_table_name,
--   ccu.column_name AS foreign_column_name
-- FROM information_schema.table_constraints AS tc
-- JOIN information_schema.key_column_usage AS kcu
--   ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.constraint_column_usage AS ccu
--   ON ccu.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'group_members';

-- Verify indexes
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'group_members';

-- ============================================================================
-- Sample membership scenarios (for reference)
-- ============================================================================

-- Typical group membership patterns:
-- 1. Group creator automatically becomes administrator
-- 2. New members start as editors by default
-- 3. Only administrators can promote/demote other members
-- 4. At least one administrator must remain in each group
-- 5. Removing the last member should trigger group deletion consideration