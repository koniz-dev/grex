-- ============================================================================
-- Migration: Allow group creator to self-insert as first member
-- Version: 00026
-- Description: createGroup runs as two statements — INSERT into groups, then
--              INSERT into group_members. The existing
--              `group_members_admin_add` policy only allows existing
--              administrators to add members, but the creator isn't an
--              administrator yet (they're about to become one). This
--              chicken-and-egg made the second INSERT fail with
--              "Insufficient permissions to Access denied".
--
-- Add a narrow policy: a user may INSERT into group_members iff
--   1. they're adding themselves (user_id = auth.uid()), AND
--   2. they're the creator of the target group.
-- The (group_id, user_id) UNIQUE constraint prevents duplicate inserts.
-- ============================================================================

DROP POLICY IF EXISTS "group_members_creator_add_self" ON group_members;

CREATE POLICY "group_members_creator_add_self" ON group_members
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM groups
      WHERE id = group_members.group_id
        AND creator_id = auth.uid()
    )
  );

COMMENT ON POLICY "group_members_creator_add_self" ON group_members IS
'Allow the user who created a group to insert their own initial administrator membership row.';
