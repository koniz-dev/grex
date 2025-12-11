-- ============================================================================
-- Migration: Enable Row Level Security
-- Version: 00011
-- Description: Enable RLS on all tables and create security policies
-- ============================================================================

-- ============================================================================
-- Enable RLS on all tables
-- Requirements: 8.5
-- ============================================================================

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Enable RLS on groups table
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- Enable RLS on group_members table
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Enable RLS on expenses table
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Enable RLS on expense_participants table
ALTER TABLE expense_participants ENABLE ROW LEVEL SECURITY;

-- Enable RLS on payments table
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Enable RLS on audit_logs table
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE users IS 'Users table with RLS enabled - users can only access their own data and group member data';
COMMENT ON TABLE groups IS 'Groups table with RLS enabled - users can only access groups they are members of';
COMMENT ON TABLE group_members IS 'Group members table with RLS enabled - users can only see members of their groups';
COMMENT ON TABLE expenses IS 'Expenses table with RLS enabled - users can only access expenses from their groups';
COMMENT ON TABLE expense_participants IS 'Expense participants table with RLS enabled - users can only access participants from their group expenses';
COMMENT ON TABLE payments IS 'Payments table with RLS enabled - users can only access payments from their groups';
COMMENT ON TABLE audit_logs IS 'Audit logs table with RLS enabled - only administrators can view audit logs for their groups';

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify RLS is enabled on all tables
-- SELECT schemaname, tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
--   AND tablename IN ('users', 'groups', 'group_members', 'expenses', 'expense_participants', 'payments', 'audit_logs')
-- ORDER BY tablename;
-- ============================================================================
-- RLS Policies for users table
-- Requirements: 8.1
-- ============================================================================

-- Policy 1: Users can view their own profile
CREATE POLICY "users_view_own_profile" ON users
  FOR SELECT
  USING (auth.uid() = id);

-- Policy 2: Users can update their own profile
CREATE POLICY "users_update_own_profile" ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Policy 3: Users can view profiles of other group members
CREATE POLICY "users_view_group_members" ON users
  FOR SELECT
  USING (
    id IN (
      SELECT gm.user_id
      FROM group_members gm
      WHERE gm.group_id IN (
        SELECT gm2.group_id
        FROM group_members gm2
        WHERE gm2.user_id = auth.uid()
      )
    )
  );

-- Policy 4: Users can insert their own profile (registration)
CREATE POLICY "users_insert_own_profile" ON users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- Comments for users policies
-- ============================================================================

COMMENT ON POLICY "users_view_own_profile" ON users IS 
'Allow users to view their own profile data';

COMMENT ON POLICY "users_update_own_profile" ON users IS 
'Allow users to update their own profile data only';

COMMENT ON POLICY "users_view_group_members" ON users IS 
'Allow users to view profiles of other members in their groups';

COMMENT ON POLICY "users_insert_own_profile" ON users IS 
'Allow users to create their own profile during registration';
-- ============================================================================
-- RLS Policies for groups table
-- Requirements: 8.1, 8.3
-- ============================================================================

-- Policy 1: Users can view groups they are members of
CREATE POLICY "groups_view_member_groups" ON groups
  FOR SELECT
  USING (
    id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
    )
  );

-- Policy 2: Users can create groups (they become the creator)
CREATE POLICY "groups_create_own_groups" ON groups
  FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

-- Policy 3: Administrators can update groups
CREATE POLICY "groups_admin_update" ON groups
  FOR UPDATE
  USING (
    id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  )
  WITH CHECK (
    id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- Policy 4: Administrators can delete groups (soft delete)
CREATE POLICY "groups_admin_delete" ON groups
  FOR UPDATE
  USING (
    id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
    AND deleted_at IS NULL  -- Can only soft-delete active groups
  )
  WITH CHECK (
    id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- ============================================================================
-- Comments for groups policies
-- ============================================================================

COMMENT ON POLICY "groups_view_member_groups" ON groups IS 
'Allow users to view groups they are members of';

COMMENT ON POLICY "groups_create_own_groups" ON groups IS 
'Allow users to create new groups (they become the creator/administrator)';

COMMENT ON POLICY "groups_admin_update" ON groups IS 
'Allow group administrators to update group settings';

COMMENT ON POLICY "groups_admin_delete" ON groups IS 
'Allow group administrators to soft-delete groups';
-- ============================================================================
-- RLS Policies for group_members table
-- Requirements: 8.1, 8.3
-- ============================================================================

-- Policy 1: Users can view members of their groups
CREATE POLICY "group_members_view_own_groups" ON group_members
  FOR SELECT
  USING (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
    )
  );

-- Policy 2: Administrators can add members
CREATE POLICY "group_members_admin_add" ON group_members
  FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- Policy 3: Administrators can update member roles
CREATE POLICY "group_members_admin_update_roles" ON group_members
  FOR UPDATE
  USING (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  )
  WITH CHECK (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- Policy 4: Administrators can remove members
CREATE POLICY "group_members_admin_remove" ON group_members
  FOR DELETE
  USING (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- Policy 5: Users can leave groups themselves
CREATE POLICY "group_members_self_leave" ON group_members
  FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- Comments for group_members policies
-- ============================================================================

COMMENT ON POLICY "group_members_view_own_groups" ON group_members IS 
'Allow users to view members of groups they belong to';

COMMENT ON POLICY "group_members_admin_add" ON group_members IS 
'Allow group administrators to add new members to their groups';

COMMENT ON POLICY "group_members_admin_update_roles" ON group_members IS 
'Allow group administrators to update member roles in their groups';

COMMENT ON POLICY "group_members_admin_remove" ON group_members IS 
'Allow group administrators to remove members from their groups';

COMMENT ON POLICY "group_members_self_leave" ON group_members IS 
'Allow users to leave groups by removing their own membership';
-- ============================================================================
-- RLS Policies for expenses table
-- Requirements: 8.2, 8.3
-- ============================================================================

-- Policy 1: Users can view expenses from their groups
CREATE POLICY "expenses_view_group_expenses" ON expenses
  FOR SELECT
  USING (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
    )
  );

-- Policy 2: Editors can create expenses
CREATE POLICY "expenses_editor_create" ON expenses
  FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role IN ('editor', 'administrator')
    )
    AND payer_id = auth.uid()  -- Can only create expenses as themselves
  );

-- Policy 3: Editors can update their own expenses
CREATE POLICY "expenses_editor_update_own" ON expenses
  FOR UPDATE
  USING (
    payer_id = auth.uid()
    AND group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role IN ('editor', 'administrator')
    )
  )
  WITH CHECK (
    payer_id = auth.uid()
    AND group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role IN ('editor', 'administrator')
    )
  );

-- Policy 4: Administrators can update any expense in their groups
CREATE POLICY "expenses_admin_update_any" ON expenses
  FOR UPDATE
  USING (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  )
  WITH CHECK (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- Policy 5: Administrators can delete expenses (soft delete)
CREATE POLICY "expenses_admin_delete" ON expenses
  FOR UPDATE
  USING (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
    AND deleted_at IS NULL  -- Can only soft-delete active expenses
  )
  WITH CHECK (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- ============================================================================
-- Comments for expenses policies
-- ============================================================================

COMMENT ON POLICY "expenses_view_group_expenses" ON expenses IS 
'Allow users to view expenses from groups they are members of';

COMMENT ON POLICY "expenses_editor_create" ON expenses IS 
'Allow editors and administrators to create expenses as themselves';

COMMENT ON POLICY "expenses_editor_update_own" ON expenses IS 
'Allow editors and administrators to update their own expenses';

COMMENT ON POLICY "expenses_admin_update_any" ON expenses IS 
'Allow administrators to update any expense in their groups';

COMMENT ON POLICY "expenses_admin_delete" ON expenses IS 
'Allow administrators to soft-delete expenses in their groups';
-- ============================================================================
-- RLS Policies for expense_participants table
-- Requirements: 8.2, 8.3
-- ============================================================================

-- Policy 1: Users can view participants from their group expenses
CREATE POLICY "expense_participants_view_group_expenses" ON expense_participants
  FOR SELECT
  USING (
    expense_id IN (
      SELECT e.id
      FROM expenses e
      JOIN group_members gm ON e.group_id = gm.group_id
      WHERE gm.user_id = auth.uid()
    )
  );

-- Policy 2: Editors can add participants to their expenses
CREATE POLICY "expense_participants_editor_add_to_own" ON expense_participants
  FOR INSERT
  WITH CHECK (
    expense_id IN (
      SELECT e.id
      FROM expenses e
      JOIN group_members gm ON e.group_id = gm.group_id
      WHERE gm.user_id = auth.uid()
        AND gm.role IN ('editor', 'administrator')
        AND e.payer_id = auth.uid()  -- Can only add participants to own expenses
    )
  );

-- Policy 3: Administrators can add participants to any expense in their groups
CREATE POLICY "expense_participants_admin_add_any" ON expense_participants
  FOR INSERT
  WITH CHECK (
    expense_id IN (
      SELECT e.id
      FROM expenses e
      JOIN group_members gm ON e.group_id = gm.group_id
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- Policy 4: Editors can update participants in their expenses
CREATE POLICY "expense_participants_editor_update_own" ON expense_participants
  FOR UPDATE
  USING (
    expense_id IN (
      SELECT e.id
      FROM expenses e
      JOIN group_members gm ON e.group_id = gm.group_id
      WHERE gm.user_id = auth.uid()
        AND gm.role IN ('editor', 'administrator')
        AND e.payer_id = auth.uid()
    )
  )
  WITH CHECK (
    expense_id IN (
      SELECT e.id
      FROM expenses e
      JOIN group_members gm ON e.group_id = gm.group_id
      WHERE gm.user_id = auth.uid()
        AND gm.role IN ('editor', 'administrator')
        AND e.payer_id = auth.uid()
    )
  );

-- Policy 5: Administrators can update participants in any expense in their groups
CREATE POLICY "expense_participants_admin_update_any" ON expense_participants
  FOR UPDATE
  USING (
    expense_id IN (
      SELECT e.id
      FROM expenses e
      JOIN group_members gm ON e.group_id = gm.group_id
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  )
  WITH CHECK (
    expense_id IN (
      SELECT e.id
      FROM expenses e
      JOIN group_members gm ON e.group_id = gm.group_id
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- Policy 6: Editors can delete participants from their expenses
CREATE POLICY "expense_participants_editor_delete_own" ON expense_participants
  FOR DELETE
  USING (
    expense_id IN (
      SELECT e.id
      FROM expenses e
      JOIN group_members gm ON e.group_id = gm.group_id
      WHERE gm.user_id = auth.uid()
        AND gm.role IN ('editor', 'administrator')
        AND e.payer_id = auth.uid()
    )
  );

-- Policy 7: Administrators can delete participants from any expense in their groups
CREATE POLICY "expense_participants_admin_delete_any" ON expense_participants
  FOR DELETE
  USING (
    expense_id IN (
      SELECT e.id
      FROM expenses e
      JOIN group_members gm ON e.group_id = gm.group_id
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- ============================================================================
-- Comments for expense_participants policies
-- ============================================================================

COMMENT ON POLICY "expense_participants_view_group_expenses" ON expense_participants IS 
'Allow users to view participants from expenses in their groups';

COMMENT ON POLICY "expense_participants_editor_add_to_own" ON expense_participants IS 
'Allow editors to add participants to their own expenses';

COMMENT ON POLICY "expense_participants_admin_add_any" ON expense_participants IS 
'Allow administrators to add participants to any expense in their groups';

COMMENT ON POLICY "expense_participants_editor_update_own" ON expense_participants IS 
'Allow editors to update participants in their own expenses';

COMMENT ON POLICY "expense_participants_admin_update_any" ON expense_participants IS 
'Allow administrators to update participants in any expense in their groups';

COMMENT ON POLICY "expense_participants_editor_delete_own" ON expense_participants IS 
'Allow editors to delete participants from their own expenses';

COMMENT ON POLICY "expense_participants_admin_delete_any" ON expense_participants IS 
'Allow administrators to delete participants from any expense in their groups';
-- ============================================================================
-- RLS Policies for payments table
-- Requirements: 8.2, 8.3
-- ============================================================================

-- Policy 1: Users can view payments from their groups
CREATE POLICY "payments_view_group_payments" ON payments
  FOR SELECT
  USING (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
    )
  );

-- Policy 2: Editors can create payments (as payer)
CREATE POLICY "payments_editor_create_as_payer" ON payments
  FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role IN ('editor', 'administrator')
    )
    AND payer_id = auth.uid()  -- Can only create payments as themselves
    AND recipient_id IN (
      SELECT gm.user_id
      FROM group_members gm
      WHERE gm.group_id = payments.group_id  -- Recipient must be in same group
    )
  );

-- Policy 3: Users can delete their own payments
CREATE POLICY "payments_delete_own_payments" ON payments
  FOR DELETE
  USING (
    payer_id = auth.uid()
    AND group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
    )
  );

-- Policy 4: Administrators can delete any payment in their groups
CREATE POLICY "payments_admin_delete_any" ON payments
  FOR DELETE
  USING (
    group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    )
  );

-- ============================================================================
-- Comments for payments policies
-- ============================================================================

COMMENT ON POLICY "payments_view_group_payments" ON payments IS 
'Allow users to view payments from groups they are members of';

COMMENT ON POLICY "payments_editor_create_as_payer" ON payments IS 
'Allow editors and administrators to create payments as themselves to other group members';

COMMENT ON POLICY "payments_delete_own_payments" ON payments IS 
'Allow users to delete their own payments';

COMMENT ON POLICY "payments_admin_delete_any" ON payments IS 
'Allow administrators to delete any payment in their groups';
-- ============================================================================
-- RLS Policies for audit_logs table
-- Requirements: 8.4
-- ============================================================================

-- Policy 1: Administrators can view audit logs for their groups
CREATE POLICY "audit_logs_admin_view_group_logs" ON audit_logs
  FOR SELECT
  USING (
    -- Allow viewing audit logs for groups where user is administrator
    (group_id IN (
      SELECT gm.group_id
      FROM group_members gm
      WHERE gm.user_id = auth.uid()
        AND gm.role = 'administrator'
    ))
    OR
    -- Allow viewing audit logs for user's own actions (user-level logs)
    (group_id IS NULL AND user_id = auth.uid())
  );

-- Policy 2: Prevent INSERT operations (only triggers can insert)
CREATE POLICY "audit_logs_no_manual_insert" ON audit_logs
  FOR INSERT
  WITH CHECK (false);  -- Always deny manual inserts

-- Policy 3: Prevent UPDATE operations (audit logs are immutable)
CREATE POLICY "audit_logs_no_updates" ON audit_logs
  FOR UPDATE
  USING (false);  -- Always deny updates

-- Policy 4: Prevent DELETE operations (audit logs are immutable)
CREATE POLICY "audit_logs_no_deletes" ON audit_logs
  FOR DELETE
  USING (false);  -- Always deny deletes

-- ============================================================================
-- Comments for audit_logs policies
-- ============================================================================

COMMENT ON POLICY "audit_logs_admin_view_group_logs" ON audit_logs IS 
'Allow administrators to view audit logs for their groups and users to view their own user-level audit logs';

COMMENT ON POLICY "audit_logs_no_manual_insert" ON audit_logs IS 
'Prevent manual INSERT operations - only database triggers can create audit logs';

COMMENT ON POLICY "audit_logs_no_updates" ON audit_logs IS 
'Prevent UPDATE operations to maintain audit log immutability';

COMMENT ON POLICY "audit_logs_no_deletes" ON audit_logs IS 
'Prevent DELETE operations to maintain audit log immutability';