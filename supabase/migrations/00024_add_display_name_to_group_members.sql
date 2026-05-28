-- ============================================================================
-- Migration: Add display_name to group_members
-- Version: 00024
-- Description: The data layer (GroupMemberModel, createGroup, inviteMember,
--              getUserGroups) reads and writes group_members.display_name —
--              a per-group display name that lets a group label a member
--              (including invitees without an account yet) independently of
--              their users.display_name. The original 00004 table creation
--              omitted this column, so getUserGroups failed with
--              "column group_members_1.display_name does not exist".
-- ============================================================================

-- Add the column nullable first so the statement succeeds regardless of any
-- existing rows.
ALTER TABLE group_members
  ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Backfill any existing memberships from the linked user's profile, falling
-- back to the email local-part so the NOT NULL constraint below always holds.
UPDATE group_members gm
SET display_name = COALESCE(
  NULLIF(u.display_name, ''),
  split_part(u.email, '@', 1),
  'Member'
)
FROM users u
WHERE gm.user_id = u.id
  AND (gm.display_name IS NULL OR gm.display_name = '');

-- Any rows still null (no matching user row) get a safe placeholder.
UPDATE group_members
SET display_name = 'Member'
WHERE display_name IS NULL OR display_name = '';

-- Enforce NOT NULL to match the application contract (display_name is always
-- provided on insert).
ALTER TABLE group_members
  ALTER COLUMN display_name SET NOT NULL;

COMMENT ON COLUMN group_members.display_name IS
'Per-group display name for the member; defaults from users.display_name but can be overridden per group.';
