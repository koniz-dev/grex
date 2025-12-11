-- ============================================================================
-- Migration: Create Audit Logs Table
-- Version: 00008
-- Description: Create audit_logs table for tracking all data modifications
-- ============================================================================

-- Create audit_logs table
CREATE TABLE audit_logs (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Entity information
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  action action_type NOT NULL,
  
  -- User and group context (with snapshot data for forensics)
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  user_email TEXT NOT NULL, -- Snapshot of user email at time of action
  user_display_name TEXT NOT NULL, -- Snapshot of user display name at time of action
  group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
  group_name TEXT, -- Snapshot of group name at time of action (NULL for user-level actions)
  
  -- State tracking (JSONB for flexible storage)
  before_state JSONB,
  after_state JSONB,
  
  -- Timestamp
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- ========================================================================
  -- Constraints
  -- ========================================================================
  
  -- Entity type must not be empty
  CONSTRAINT entity_type_not_empty CHECK (LENGTH(TRIM(entity_type)) > 0),
  
  -- User context must not be empty (for forensics)
  CONSTRAINT user_email_not_empty CHECK (LENGTH(TRIM(user_email)) > 0),
  CONSTRAINT user_display_name_not_empty CHECK (LENGTH(TRIM(user_display_name)) > 0),
  
  -- Entity type validation (must be one of our known types)
  CONSTRAINT entity_type_valid CHECK (
    entity_type IN ('user', 'group', 'group_member', 'expense', 'expense_participant', 'payment')
  ),
  
  -- Action must be valid for the entity type
  CONSTRAINT action_valid CHECK (
    (entity_type = 'user' AND action IN ('create', 'update', 'delete')) OR
    (entity_type = 'group' AND action IN ('create', 'update', 'delete')) OR
    (entity_type = 'group_member' AND action IN ('create', 'update', 'delete')) OR
    (entity_type = 'expense' AND action IN ('create', 'update', 'delete')) OR
    (entity_type = 'expense_participant' AND action IN ('create', 'delete')) OR
    (entity_type = 'payment' AND action IN ('create', 'delete'))
  ),
  
  -- State validation: create actions should have after_state, delete actions should have before_state
  CONSTRAINT state_consistency CHECK (
    (action = 'create' AND after_state IS NOT NULL) OR
    (action = 'update' AND before_state IS NOT NULL AND after_state IS NOT NULL) OR
    (action = 'delete' AND before_state IS NOT NULL)
  )
);

-- ============================================================================
-- Indexes for performance
-- ============================================================================

-- Entity-based queries
CREATE INDEX idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX idx_audit_logs_entity_id ON audit_logs(entity_id);

-- User and group context queries
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_user_email ON audit_logs(user_email);
CREATE INDEX idx_audit_logs_group_id ON audit_logs(group_id);
CREATE INDEX idx_audit_logs_group_name ON audit_logs(group_name);

-- Time-based queries
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Composite indexes for common query patterns
CREATE INDEX idx_audit_logs_composite ON audit_logs(entity_type, entity_id, created_at);
CREATE INDEX idx_audit_logs_user_time ON audit_logs(user_id, created_at);
CREATE INDEX idx_audit_logs_group_time ON audit_logs(group_id, created_at) WHERE group_id IS NOT NULL;

-- Action-based queries
CREATE INDEX idx_audit_logs_action ON audit_logs(action);

-- Entity type and action combination
CREATE INDEX idx_audit_logs_type_action ON audit_logs(entity_type, action);

-- ============================================================================
-- Immutability enforcement
-- ============================================================================

-- Note: Audit logs immutability will be enforced through RLS policies in a later migration
-- rather than rules to allow proper foreign key SET NULL behavior.
-- Rules interfere with foreign key operations, preventing SET NULL from working correctly.
-- 
-- The immutability will be enforced by:
-- 1. RLS policies that prevent direct UPDATE/DELETE by users  
-- 2. Application-level controls
-- 3. Database permissions (only triggers can modify audit_logs)
--
-- Rules are disabled to allow proper foreign key SET NULL behavior:
-- CREATE RULE audit_logs_no_update AS ON UPDATE TO audit_logs DO INSTEAD NOTHING;
-- CREATE RULE audit_logs_no_delete AS ON DELETE TO audit_logs DO INSTEAD NOTHING;

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE audit_logs IS 'Immutable audit trail of all data modifications in the system';
COMMENT ON COLUMN audit_logs.id IS 'Unique identifier for the audit log entry (UUID)';
COMMENT ON COLUMN audit_logs.entity_type IS 'Type of entity that was modified (user, group, expense, etc.)';
COMMENT ON COLUMN audit_logs.entity_id IS 'ID of the specific entity that was modified';
COMMENT ON COLUMN audit_logs.action IS 'Type of action performed (create, update, delete)';
COMMENT ON COLUMN audit_logs.user_id IS 'User who performed the action (NULL if user deleted)';
COMMENT ON COLUMN audit_logs.user_email IS 'Snapshot of user email at time of action (for forensics)';
COMMENT ON COLUMN audit_logs.user_display_name IS 'Snapshot of user display name at time of action (for forensics)';
COMMENT ON COLUMN audit_logs.group_id IS 'Group context for the action (NULL if not applicable or group deleted)';
COMMENT ON COLUMN audit_logs.group_name IS 'Snapshot of group name at time of action (for forensics)';
COMMENT ON COLUMN audit_logs.before_state IS 'State of the entity before the modification (JSONB)';
COMMENT ON COLUMN audit_logs.after_state IS 'State of the entity after the modification (JSONB)';
COMMENT ON COLUMN audit_logs.created_at IS 'Timestamp when the audit log was created';

-- ============================================================================
-- Audit logging scenarios (for reference)
-- ============================================================================

-- Audit logs are created automatically by triggers on other tables:
-- 1. User actions: registration, profile updates, account deletion
-- 2. Group actions: creation, settings changes, deletion
-- 3. Membership actions: joining groups, role changes, leaving groups
-- 4. Expense actions: creating expenses, editing amounts/descriptions, deletion
-- 5. Participant actions: adding/removing participants from expenses
-- 6. Payment actions: recording payments, payment deletion

-- Audit log queries:
-- 1. View all actions by a user: WHERE user_id = ? OR user_email = ?
-- 2. View all actions in a group: WHERE group_id = ? OR group_name = ?
-- 3. View history of an entity: WHERE entity_type = ? AND entity_id = ?
-- 4. View recent actions: ORDER BY created_at DESC LIMIT ?
-- 5. View actions by type: WHERE entity_type = ? AND action = ?
-- 6. View actions by deleted users: WHERE user_id IS NULL AND user_email = ?
-- 7. View actions in deleted groups: WHERE group_id IS NULL AND group_name = ?

-- ============================================================================
-- Triggers for automatic timestamp management
-- ============================================================================

-- Create specialized timestamp trigger function for audit_logs
CREATE OR REPLACE FUNCTION set_audit_logs_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp trigger to audit_logs table
-- Note: Only created_at is managed since audit logs are immutable
CREATE TRIGGER set_audit_logs_timestamps
  BEFORE INSERT ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION set_audit_logs_timestamps();

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify table was created
-- SELECT table_name, column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'audit_logs' 
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type 
-- FROM information_schema.table_constraints 
-- WHERE table_name = 'audit_logs';

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
-- WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'audit_logs';

-- Verify indexes
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'audit_logs';

-- Verify rules (immutability)
-- SELECT rulename, definition 
-- FROM pg_rules 
-- WHERE tablename = 'audit_logs';

-- ============================================================================
-- Sample audit log entries (for reference)
-- ============================================================================

-- Example 1: User creation
-- INSERT INTO audit_logs (entity_type, entity_id, action, user_id, user_email, user_display_name, after_state)
-- VALUES ('user', new_user_id, 'create', new_user_id, 'user@example.com', 'New User', 
--   '{"email": "user@example.com", "display_name": "New User"}');

-- Example 2: Expense update
-- INSERT INTO audit_logs (entity_type, entity_id, action, user_id, user_email, user_display_name, 
--   group_id, group_name, before_state, after_state)
-- VALUES ('expense', expense_id, 'update', user_id, 'user@example.com', 'John Doe',
--   group_id, 'Trip to Paris',
--   '{"amount": 100.00, "description": "Old description"}',
--   '{"amount": 120.00, "description": "Updated description"}');

-- Example 3: Payment deletion
-- INSERT INTO audit_logs (entity_type, entity_id, action, user_id, user_email, user_display_name,
--   group_id, group_name, before_state)
-- VALUES ('payment', payment_id, 'delete', user_id, 'user@example.com', 'John Doe',
--   group_id, 'Trip to Paris',
--   '{"amount": 50.00, "payer_id": "uuid", "recipient_id": "uuid"}');