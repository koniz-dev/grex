-- ============================================================================
-- Migration: Rename groups.primary_currency -> groups.currency
-- Version: 00025
-- Description: The Flutter data layer (GroupModel, createGroup, updateGroup)
--              reads and writes `groups.currency`. The original table in
--              00003 named the column `primary_currency`, which caused
--              "Could not find the 'currency' column of 'groups' in the
--              schema cache" on group creation. Align the schema with the
--              app contract.
--
-- Constraints (`currency_code_length`, `currency_code_format`) auto-track
-- the renamed column. CHECK constraint expressions are rewritten by Postgres
-- on RENAME COLUMN. Function bodies and RETURNS TABLE signatures are NOT
-- rewritten, so we recreate the two callers below.
-- ============================================================================

ALTER TABLE groups RENAME COLUMN primary_currency TO currency;

-- ----------------------------------------------------------------------------
-- Recreate calculate_group_balances with the new column name in its body.
-- Signature unchanged, so CREATE OR REPLACE is safe.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION calculate_group_balances(p_group_id UUID)
RETURNS TABLE (
  user_id UUID,
  user_name TEXT,
  balance DECIMAL(10,2)
) AS $$
DECLARE
  group_currency TEXT;
BEGIN
  SELECT currency INTO group_currency
  FROM groups
  WHERE id = p_group_id AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Group not found or has been deleted';
  END IF;

  RETURN QUERY
  WITH expense_totals AS (
    SELECT
      e.payer_id AS user_id,
      COALESCE(SUM(e.amount), 0) AS total_paid
    FROM expenses e
    WHERE e.group_id = p_group_id
      AND e.deleted_at IS NULL
      AND e.currency = group_currency
    GROUP BY e.payer_id
  ),
  participant_totals AS (
    SELECT
      ep.user_id,
      COALESCE(SUM(ep.share_amount), 0) AS total_owed
    FROM expense_participants ep
    JOIN expenses e ON ep.expense_id = e.id
    WHERE e.group_id = p_group_id
      AND e.deleted_at IS NULL
      AND e.currency = group_currency
    GROUP BY ep.user_id
  ),
  payments_sent AS (
    SELECT
      p.payer_id AS user_id,
      COALESCE(SUM(p.amount), 0) AS total_sent
    FROM payments p
    WHERE p.group_id = p_group_id
      AND p.deleted_at IS NULL
      AND p.currency = group_currency
    GROUP BY p.payer_id
  ),
  payments_received AS (
    SELECT
      p.recipient_id AS user_id,
      COALESCE(SUM(p.amount), 0) AS total_received
    FROM payments p
    WHERE p.group_id = p_group_id
      AND p.deleted_at IS NULL
      AND p.currency = group_currency
    GROUP BY p.recipient_id
  ),
  all_members AS (
    SELECT
      gm.user_id,
      u.display_name AS user_name
    FROM group_members gm
    JOIN users u ON gm.user_id = u.id
    WHERE gm.group_id = p_group_id
      AND u.deleted_at IS NULL
  )
  SELECT
    am.user_id,
    am.user_name,
    COALESCE(et.total_paid, 0) + COALESCE(pr.total_received, 0)
      - COALESCE(pt.total_owed, 0) - COALESCE(ps.total_sent, 0) AS balance
  FROM all_members am
  LEFT JOIN expense_totals et ON am.user_id = et.user_id
  LEFT JOIN participant_totals pt ON am.user_id = pt.user_id
  LEFT JOIN payments_sent ps ON am.user_id = ps.user_id
  LEFT JOIN payments_received pr ON am.user_id = pr.user_id
  ORDER BY am.user_name;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- Recreate get_active_groups — its RETURNS TABLE declared a column named
-- `primary_currency`, so the signature changes; DROP then CREATE.
-- ----------------------------------------------------------------------------

DROP FUNCTION IF EXISTS get_active_groups();

CREATE FUNCTION get_active_groups()
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    creator_id UUID,
    currency TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT id, name, description, creator_id, currency, created_at, updated_at
    FROM groups
    WHERE deleted_at IS NULL;
$$;

COMMENT ON COLUMN groups.currency IS
'Default currency for expenses in this group (ISO 4217 code). Renamed from primary_currency in 00025 to match the Flutter data layer.';
